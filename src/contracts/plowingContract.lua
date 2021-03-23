--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class PlowingContract : Contract
PlowingContract = {}
PlowingContract_mt = Class(PlowingContract, Contract)

--- PlowingContract class
---@param mt? table custom meta table
---@return PlowingContract
function PlowingContract.new(mt)
    ---@type PlowingContract
    local self = Contract.new(mt or PlowingContract_mt)
    return self
end

---@param field any
---@param fruit any
---@return boolean
function PlowingContract.canBePerformed(field, fruit)
    return true
end

---@param field any
---@param fruit any
---@param otherContractProposals Contract[]
function PlowingContract:randomizeData(field, fruit, otherContractProposals)
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
    self.workPrice = pricePerHa * field.fieldArea * priceMultiplier

    -- prevents multiple contracts a single npc
    repeat
        self.npc = g_npcManager:getRandomNPC()
    until (TableUtility.f_count(
        otherContractProposals,
        ---@type Contract
        function(c)
            return c.npc.imageFilename == self.npc.imageFilename
        end
    ) == 0)
end
