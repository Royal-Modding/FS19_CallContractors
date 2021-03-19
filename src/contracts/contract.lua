--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class Contract
Contract = {}
Contract_mt = Class(Contract)

--- Contract base class
---@param mt? table custom meta table
---@return Contract
function Contract:new(mt)
    ---@type Contract
    local c = setmetatable({}, mt or Contract_mt)
    return c
end

function Contract.canBePerformed(field, fruit)
    return true
end

function Contract.fieldsFilter(field)
    -- only owned fields
    return g_farmlandManager:getFarmlandOwner(field.farmland.id) == g_currentMission.player.farmId
end

function Contract.fruitsFilter(fruit)
    return true
end
