--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class SellingGoodsContract : Contract
SellingGoodsContract = {}
SellingGoodsContract_mt = Class(SellingGoodsContract, Contract)

--- SellingGoodsContract class
---@param mt? table custom meta table
---@return SellingGoodsContract
function SellingGoodsContract:new(mt)
    ---@type SellingGoodsContract
    local c = Contract:new(mt or SellingGoodsContract_mt)
    return c
end
