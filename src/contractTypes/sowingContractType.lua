--- ${title}

---@author ${author}
---@version r_version_r
---@date 25/03/2021

---@class SowingContractType : ContractType
SowingContractType = {}
SowingContractType_mt = Class(SowingContractType, ContractType)

--- SowingContractType base class
---@param id number
---@param contractClass Contract
---@param name string
---@param title string
---@param mt? table custom meta table
---@return SowingContractType
function SowingContractType.new(id, contractClass, name, title, mt)
    ---@type SowingContractType
    local self = ContractType.new(id, contractClass, name, title, mt or SowingContractType_mt)
    self.requireFieldParam = true
    self.requireFruitParam = true
    return self
end

---@param farmId number
---@param fruit any
---@return boolean
function SowingContractType.fruitsFilter(farmId, fruit)
    return fruit.index ~= FruitType.WEED and fruit.index ~= FruitType.POPLAR and fruit.index ~= FruitType.DRYGRASS
end
