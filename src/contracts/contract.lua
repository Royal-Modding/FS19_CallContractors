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
function Contract.new(mt)
    ---@type Contract
    local self = setmetatable({}, mt or Contract_mt)
    ---@type number
    self.ttl = 3600000 -- 1 hour
    ---@type number
    self.expiration = g_time + 3600000
    ---@type number
    self.basePrice = 0 -- price to pay at contract sign
    ---@type number
    self.price = 0 -- price to pay at job finished
    ---@type number
    self.waitTime = 24 -- hours
    ---@type NPC
    self.npc = nil
    return self
end

---@param field any
---@param fruit any
---@return boolean
function Contract.canBePerformed(field, fruit)
    return false
end

---@param field table
---@return boolean
function Contract.fieldsFilter(field)
    -- only owned fields
    return g_farmlandManager:getFarmlandOwner(field.farmland.id) == g_currentMission.player.farmId
end

---@param fruit any
---@return boolean
function Contract.fruitsFilter(fruit)
    return true
end

---@param field any
---@param fruit any
function Contract:randomizeData(field, fruit)
end

function Contract:setData()
end
