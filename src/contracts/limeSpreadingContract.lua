--- ${title}

---@author ${author}
---@version r_version_r
---@date 06/04/2021

---@class LimeSpreadingContract : Contract
LimeSpreadingContract = {}
LimeSpreadingContract_mt = Class(LimeSpreadingContract, Contract)

--- LimeSpreadingContract class
---@param contractType ContractType
---@param mt? table custom meta table
---@return LimeSpreadingContract
function LimeSpreadingContract.new(contractType, mt)
    ---@type LimeSpreadingContract
    local self = Contract.new(contractType, mt or LimeSpreadingContract_mt)
    return self
end

---@param farmId integer
---@param fieldId integer
---@param fruitId integer
---@return boolean
function LimeSpreadingContract.checkPrerequisites(farmId, fieldId, fruitId)
    local field = g_fieldManager:getFieldByIndex(fieldId)
    return g_farmlandManager:getFarmlandOwner(field.farmland.id) == farmId and FieldStatusUtil.getLimeableIndex(field) >= 0.70
end

---@param otherContractProposals ContractProposal[]
function LimeSpreadingContract:randomize(otherContractProposals)
    local economicDifficulty = g_currentMission.missionInfo.economicDifficulty

    local minWaitTime = 2
    local maxWaitTime = 48

    ---@type RandomInterval[]
    local waitTimeBatches = {{min = 2, max = 6}, {min = 4, max = 8}, {min = 7, max = 16}, {min = 17, max = 35}, {min = 17, max = 35}, {min = 36, max = 48}}

    local minWaitTimePriceMultiplier = 4
    local maxWaitTimePriceMultiplier = 1

    local callPrice = 80 * economicDifficulty
    local pricePerHa = 160 * economicDifficulty

    local limeUsage = 3250 -- litres per hectar
    pricePerHa = pricePerHa + (limeUsage * g_fillTypeManager:getFillTypeByIndex(FillType.LIME).pricePerLiter)

    -- prevents multiple contracts with the same waitTime
    repeat
        self.waitTime = Utility.randomFromBatches(waitTimeBatches)
    until (TableUtility.f_count(
        otherContractProposals,
        ---@type ContractProposal
        function(cp)
            return cp.contract.waitTime == self.waitTime
        end
    ) == 0)

    local callPriceMultiplier = MathUtil.lerp(minWaitTimePriceMultiplier, maxWaitTimePriceMultiplier, Utility.normalize(minWaitTime, self.waitTime, maxWaitTime))
    local workPriceMultiplier = MathUtil.lerp(maxWaitTimePriceMultiplier, callPriceMultiplier, 0.30) -- workPriceMultiplier is 30% of callPriceMultiplier

    self.callPrice = callPrice * callPriceMultiplier
    self.workPrice = pricePerHa * self:getField().fieldArea * workPriceMultiplier

    -- prevents multiple contracts from a single npc
    repeat
        self.npc = g_npcManager:getRandomNPC()
    until (TableUtility.f_count(
        otherContractProposals,
        ---@type ContractProposal
        function(cp)
            return cp.contract.npc == self.npc
        end
    ) == 0)
end

---@return boolean runResult
function Contract:run()
    local field = self:getField()
    local sprayType = g_sprayTypeManager:getSprayTypeByFillTypeIndex(FillType.LIME)
    if field ~= nil then
        for _, partition in ipairs(field.maxFieldStatusPartitions) do
            local sx, sz, wx, wz, hx, hz = Utility.getPPP(partition)
            FSDensityMapUtil.updateLimeArea(sx, sz, wx, wz, hx, hz, sprayType.groundType)
        end
        return true
    end
    return false
end
