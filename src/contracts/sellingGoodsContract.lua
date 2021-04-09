--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class SellingGoodsContract : Contract
SellingGoodsContract = {}
local SellingGoodsContract_mt = Class(SellingGoodsContract, Contract)

--- SellingGoodsContract class
---@param contractType ContractType
---@param mt? table custom meta table
---@return SellingGoodsContract
function SellingGoodsContract.new(contractType, mt)
    ---@type SellingGoodsContract
    local self = Contract.new(contractType, mt or SellingGoodsContract_mt)
    return self
end

---@param farmId integer
---@param fieldId integer
---@param fruitId integer
---@return boolean
function SellingGoodsContract.checkPrerequisites(farmId, fieldId, fruitId)
    local fruit = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
    for _, storage in pairs(g_currentMission.storageSystem.storages) do
        if g_currentMission.accessHandler:canFarmAccess(farmId, storage) and not storage.foreignSilo then
            for fillTypeIndex, _ in pairs(storage.fillTypes) do
                if fruit.fillType.index == fillTypeIndex and storage.fillLevels[fillTypeIndex] > 0 then
                    return true
                end
            end
        end
    end
    return false
end

---@return integer
function SellingGoodsContract:getTotalSilosAmount()
    local fruit = self:getFruit()
    local totalAmount = 0
    for _, storage in pairs(g_currentMission.storageSystem.storages) do
        if g_currentMission.accessHandler:canFarmAccess(self.farmId, storage) and not storage.foreignSilo then
            for fillTypeIndex, _ in pairs(storage.fillTypes) do
                if fruit.fillType.index == fillTypeIndex then
                    totalAmount = totalAmount + storage.fillLevels[fillTypeIndex]
                end
            end
        end
    end
    return totalAmount
end

function SellingGoodsContract:getPrices(economicDifficulty, silosAmount)
    economicDifficulty = economicDifficulty or g_currentMission.missionInfo.economicDifficulty

    local minWaitTime = 2
    local maxWaitTime = 48

    local minWaitTimePriceMultiplier = 4
    local maxWaitTimePriceMultiplier = 1

    local callPrice = 175 * economicDifficulty
    local pricePerLiter = 0.015

    local callPriceMultiplier = MathUtil.lerp(minWaitTimePriceMultiplier, maxWaitTimePriceMultiplier, Utility.normalize(minWaitTime, self.waitTime, maxWaitTime))
    local workPriceMultiplier = MathUtil.lerp(maxWaitTimePriceMultiplier, callPriceMultiplier, 0.5) -- workPriceMultiplier is 50% of callPriceMultiplier
    return (callPrice * callPriceMultiplier), (pricePerLiter * silosAmount * workPriceMultiplier)
end

---@param otherContractProposals ContractProposal[]
function SellingGoodsContract:randomize(otherContractProposals)
    local economicDifficulty = g_currentMission.missionInfo.economicDifficulty

    ---@type RandomInterval[]
    local waitTimeBatches = {{min = 2, max = 6}, {min = 4, max = 8}, {min = 7, max = 16}, {min = 17, max = 35}, {min = 17, max = 35}, {min = 36, max = 48}}

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

    self.callPrice, self.workPrice = self:getPrices(economicDifficulty, self:getTotalSilosAmount())

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

function SellingGoodsContract.getBestPriceForFillType(fillType)
    local maxPrice = 0
    for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
        if unloadingStation.getEffectiveFillTypePrice ~= nil then
            if unloadingStation:getIsFillTypeAllowed(fillType.index) then
                if unloadingStation.getAppearsOnStats == nil or unloadingStation:getAppearsOnStats() then
                    maxPrice = math.max(maxPrice, unloadingStation:getEffectiveFillTypePrice(fillType.index, ToolType.UNDEFINED))
                end
            end
        end
    end
    if maxPrice == 0 then
        maxPrice = fillType.pricePerLiter or 0
    end
    return maxPrice
end

---@return boolean runResult
function SellingGoodsContract:run()
    local fruit = self:getFruit()
    local fill = fruit.fillType
    if fruit ~= nil and fill ~= nil then
        local totalSold = 0
        ---@type Storage
        for _, storage in pairs(g_currentMission.storageSystem.storages) do
            if g_currentMission.accessHandler:canFarmAccess(self.farmId, storage) and not storage.foreignSilo then
                if storage:getIsFillTypeSupported(fill.index) then
                    totalSold = totalSold + storage:getFillLevel(fill.index)
                    storage:setFillLevel(0, fill.index)
                end
            end
        end
        -- recalculate work price since the silos amount may have changed since the contract sign
        _, self.workPrice = self:getPrices(nil, totalSold)

        g_currentMission:addMoney(self.getBestPriceForFillType(fill) * totalSold, self.farmId, MoneyType.HARVEST_INCOME, true, true)

        return true
    end
    return false
end
