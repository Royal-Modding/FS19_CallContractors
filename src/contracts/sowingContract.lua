--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class SowingContract : Contract
SowingContract = {}
SowingContract_mt = Class(SowingContract, Contract)

--- SowingContract class
---@param contractType ContractType
---@param mt? table custom meta table
---@return SowingContract
function SowingContract.new(contractType, mt)
    ---@type SowingContract
    local self = Contract.new(contractType, mt or SowingContract_mt)
    return self
end

---@param fruit any
---@return boolean
function SowingContract.fruitsFilter(fruit)
    return fruit.index ~= FruitType.WEED and fruit.index ~= FruitType.POPLAR and fruit.index ~= FruitType.DRYGRASS
end
