--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class CultivatingContract : Contract
CultivatingContract = {}
local CultivatingContract_mt = Class(CultivatingContract, Contract)

--- CultivatingContract class
---@param contractType ContractType
---@param mt? table custom meta table
---@return CultivatingContract
function CultivatingContract.new(contractType, mt)
    ---@type CultivatingContract
    local self = Contract.new(contractType, mt or CultivatingContract_mt)
    return self
end

---@param farmId integer
---@param fieldId integer
---@param fruitId integer
---@return boolean
function CultivatingContract.checkPrerequisites(farmId, fieldId, fruitId)
    local field = g_fieldManager:getFieldByIndex(fieldId)
    return g_farmlandManager:getFarmlandOwner(field.farmland.id) == farmId
end

---@param otherContractProposals ContractProposal[]
function CultivatingContract:randomize(otherContractProposals)
    local economicDifficulty = g_currentMission.missionInfo.economicDifficulty

    local minWaitTime = 2
    local maxWaitTime = 48

    ---@type RandomInterval[]
    local waitTimeBatches = {{min = 2, max = 6}, {min = 4, max = 8}, {min = 7, max = 16}, {min = 17, max = 35}, {min = 17, max = 35}, {min = 36, max = 48}}

    local minWaitTimePriceMultiplier = 4
    local maxWaitTimePriceMultiplier = 1

    local callPrice = 70 * economicDifficulty
    local pricePerHa = 90 * economicDifficulty

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
    local workPriceMultiplier = MathUtil.lerp(maxWaitTimePriceMultiplier, callPriceMultiplier, 0.15) -- workPriceMultiplier is 15% of callPriceMultiplier

    self.callPrice = callPrice * callPriceMultiplier
    self.workPrice = pricePerHa * self:getField().fieldArea * workPriceMultiplier

    -- prevents multiple contracts from a single npc
    repeat
        self.npc = g_npcManager:getRandomNPC()
    until (TableUtility.f_count(
        otherContractProposals,
        ---@type ContractProposal
        function(cp)
            return cp.contract.npc.imageFilename == self.npc.imageFilename
        end
    ) == 0)
end

---@return boolean runResult
function CultivatingContract:run()
    local field = self:getField()
    if field ~= nil then
        for _, partition in ipairs(field.maxFieldStatusPartitions) do
            local sx, sz, wx, wz, hx, hz = Utility.getPPP(partition)
            FSDensityMapUtil.updateCultivatorArea(sx, sz, wx, wz, hx, hz, false, false, field.fieldAngle, nil, true)
            FSDensityMapUtil.eraseTireTrack(sx, sz, wx, wz, hx, hz)
        end
        return true
    end
    return false
end
