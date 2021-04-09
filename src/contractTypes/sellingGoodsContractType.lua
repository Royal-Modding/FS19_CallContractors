--- ${title}

---@author ${author}
---@version r_version_r
---@date 06/04/2021

---@class SellingGoodsContractType : ContractType
SellingGoodsContractType = {}
local SellingGoodsContractType_mt = Class(SellingGoodsContractType, ContractType)

--- SellingGoodsContractType base class
---@param id number
---@param contractClass Contract
---@param name string
---@param title string
---@param mt? table custom meta table
---@return SellingGoodsContractType
function SellingGoodsContractType.new(id, contractClass, name, title, mt)
    ---@type SellingGoodsContractType
    local self = ContractType.new(id, contractClass, name, title, mt or SellingGoodsContractType_mt)
    self.requireFieldParam = false
    self.requireFruitParam = true
    return self
end

---@param farmId integer
---@return boolean
function SellingGoodsContractType.checkPrerequisites(farmId)
    -- needs at least one silo
    local numSilos = 0
    for _, storage in pairs(g_currentMission.storageSystem.storages) do
        if g_currentMission.accessHandler:canFarmAccess(farmId, storage) and not storage.foreignSilo then
            numSilos = numSilos + 1
        end
    end
    return numSilos > 0
end

---@param farmId integer
---@param fruit FruitTypeEntry
---@return boolean
function SellingGoodsContractType.fruitsFilter(farmId, fruit)
    -- only fruits/filltypes accepted by silos
    for _, storage in pairs(g_currentMission.storageSystem.storages) do
        if g_currentMission.accessHandler:canFarmAccess(farmId, storage) and not storage.foreignSilo then
            for fillTypeIndex, _ in pairs(storage.fillTypes) do
                if fruit.fillType.index == fillTypeIndex then
                    return true
                end
            end
        end
    end
    return false
end

---@param farmId integer
---@param fieldId integer
---@param fruitId integer
---@return string
function SellingGoodsContractType:getSignedContractKey(farmId, fieldId, fruitId)
    -- only one contract per fruit at the same time
    return string.format("%s_%d_%d", self.name, farmId, fruitId)
end
