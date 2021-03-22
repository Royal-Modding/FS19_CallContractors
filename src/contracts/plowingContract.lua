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
function PlowingContract:randomizeData(field, fruit)
    local economicDifficulty = g_currentMission.missionInfo.economicDifficulty

    local minWaitTime = 2
    local maxWaitTime = 48

    local minWaitTimePriceMultiplier = 3
    local maxWaitTimePriceMultiplier = 1

    local callPrice = 75 * economicDifficulty
    local pricePerHa = 125 * economicDifficulty

    self.waitTime = math.random(minWaitTime, maxWaitTime)

    local basePriceMultiplier = MathUtil.lerp(minWaitTimePriceMultiplier, maxWaitTimePriceMultiplier, Utility.normalize(minWaitTime, self.waitTime, maxWaitTime))
    local priceMultiplier = MathUtil.lerp(1, basePriceMultiplier, 0.1) -- priceMultiplier is 10% of basePriceMultiplier

    self.basePrice = callPrice * basePriceMultiplier
    self.price = pricePerHa * field.fieldArea * priceMultiplier

    self.npc = g_npcManager:getRandomNPC()
end
