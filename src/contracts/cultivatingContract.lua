--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class CultivatingContract : Contract
CultivatingContract = {}
CultivatingContract_mt = Class(CultivatingContract, Contract)

--- CultivatingContract class
---@param mt? table custom meta table
---@return CultivatingContract
function CultivatingContract:new(mt)
    ---@type CultivatingContract
    local c = Contract:new(mt or CultivatingContract_mt)
    return c
end
