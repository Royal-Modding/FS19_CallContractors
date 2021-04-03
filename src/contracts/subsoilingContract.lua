--- ${title}

---@author ${author}
---@version r_version_r
---@date 03/04/2021

---@class SubsoilingContract : Contract
SubsoilingContract = {}
SubsoilingContract_mt = Class(SubsoilingContract, Contract)

--- SubsoilingContract class
---@param contractType ContractType
---@param mt? table custom meta table
---@return SubsoilingContract
function SubsoilingContract.new(contractType, mt)
    ---@type SubsoilingContract
    local self = Contract.new(contractType, mt or SubsoilingContract_mt)
    return self
end

---@param farmId integer
---@param fieldId integer
---@param fruitId integer
---@return boolean
function SubsoilingContract.checkPrerequisites(farmId, fieldId, fruitId)
    local field = g_fieldManager:getFieldByIndex(fieldId)
    return g_farmlandManager:getFarmlandOwner(field.farmland.id) == farmId
end

---@param otherContractProposals ContractProposal[]
function SubsoilingContract:randomize(otherContractProposals)
    local economicDifficulty = g_currentMission.missionInfo.economicDifficulty

    local minWaitTime = 2
    local maxWaitTime = 48

    ---@type RandomInterval[]
    local waitTimeBatches = {{min = 2, max = 6}, {min = 4, max = 8}, {min = 7, max = 16}, {min = 17, max = 35}, {min = 17, max = 35}, {min = 36, max = 48}}

    local minWaitTimePriceMultiplier = 4
    local maxWaitTimePriceMultiplier = 1

    local callPrice = 80 * economicDifficulty
    local pricePerHa = 175 * economicDifficulty

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
            return cp.contract.npc == self.npc
        end
    ) == 0)
end

---@return boolean runResult
function SubsoilingContract:run()
    local field = self:getField()
    if field ~= nil then
        for _, partition in ipairs(field.maxFieldStatusPartitions) do
            local sx, sz, wx, wz, hx, hz = Utility.getPPP(partition)
            FSDensityMapUtil.updateCultivatorArea(sx, sz, wx, wz, hx, hz, false, false, field.fieldAngle, nil, true)
            FSDensityMapUtil.updateSubsoilerArea(sx, sz, wx, wz, hx, hz, false)
            FSDensityMapUtil.eraseTireTrack(sx, sz, wx, wz, hx, hz)
        end
        return true
    end
    return false
end
