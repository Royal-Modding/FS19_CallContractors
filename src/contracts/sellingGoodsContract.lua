--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class SellingGoodsContract : Contract
SellingGoodsContract = {}
SellingGoodsContract_mt = Class(SellingGoodsContract, Contract)

--- SellingGoodsContract class
---@param contractType ContractType
---@param mt? table custom meta table
---@return SellingGoodsContract
function SellingGoodsContract.new(contractType, mt)
    ---@type SellingGoodsContract
    local self = Contract.new(contractType, mt or SellingGoodsContract_mt)
    return self
end
