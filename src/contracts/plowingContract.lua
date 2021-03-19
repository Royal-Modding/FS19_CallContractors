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
function PlowingContract:new(mt)
    ---@type PlowingContract
    local c = Contract:new(mt or PlowingContract_mt)
    return c
end
