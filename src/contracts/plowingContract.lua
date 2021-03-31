--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class PlowingContract : Contract
PlowingContract = {}
PlowingContract_mt = Class(PlowingContract, Contract)

--- PlowingContract class
---@param contractType ContractType
---@param mt? table custom meta table
---@return PlowingContract
function PlowingContract.new(contractType, mt)
    ---@type PlowingContract
    local self = Contract.new(contractType, mt or PlowingContract_mt)
    return self
end

---@param farmId integer
---@param fieldId integer
---@param fruitId integer
---@return boolean
function PlowingContract.checkPrerequisites(farmId, fieldId, fruitId)
    local field = g_fieldManager:getFieldByIndex(fieldId)
    return g_farmlandManager:getFarmlandOwner(field.farmland.id) == farmId
end

---@param otherContractProposals ContractProposal[]
function PlowingContract:randomize(otherContractProposals)
    local economicDifficulty = g_currentMission.missionInfo.economicDifficulty

    local minWaitTime = 2
    local maxWaitTime = 48

    local minWaitTimePriceMultiplier = 3
    local maxWaitTimePriceMultiplier = 1

    local callPrice = 75 * economicDifficulty
    local pricePerHa = 125 * economicDifficulty

    -- TODO: invece che semplicmente randomizzare tra min e max wait time, creare 3 (o magari 4) "fascie di velocità", randomizzare prima la fascia e poi il tempo interno alla fascia ex. ( 2 >= veloce <= 6 ) ( 6>= medio <= 12 ) ( 12 >= lento <= 48) questo permetterebbe di, più o meno, garantire la varietà dei contratti in base all'esigenza e disponibilità economica
    self.waitTime = math.random(minWaitTime, maxWaitTime)

    local basePriceMultiplier = MathUtil.lerp(minWaitTimePriceMultiplier, maxWaitTimePriceMultiplier, Utility.normalize(minWaitTime, self.waitTime, maxWaitTime))
    local priceMultiplier = MathUtil.lerp(1, basePriceMultiplier, 0.1) -- priceMultiplier is 10% of basePriceMultiplier

    self.callPrice = callPrice * basePriceMultiplier
    self.workPrice = pricePerHa * self:getField().fieldArea * priceMultiplier

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
