--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class CultivatingContract : Contract
CultivatingContract = {}
CultivatingContract_mt = Class(CultivatingContract, Contract)

--- CultivatingContract class
---@param contractType ContractType
---@param mt? table custom meta table
---@return CultivatingContract
function CultivatingContract.new(contractType, mt)
    ---@type CultivatingContract
    local self = Contract.new(contractType, mt or CultivatingContract_mt)
    return self
end
