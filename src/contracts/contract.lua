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
    self.ttl = math.random(18, 54) * 100000 -- between 30 minutes and 1.5 hours
    ---@type number
    self.callPrice = 0 -- price to pay at contract sign
    ---@type number
    self.workPrice = 0 -- price to pay at job finished
    ---@type number
    self.waitTime = 24 -- hours
    ---@type NPC
    self.npc = nil
    ---@type number
    self.fieldId = 0
    ---@type number
    self.fruitId = 0
    ---@type string
    self.tffKey = ""
    ---@type bool
    self.signed = false
    ---@type number
    self.jobTypeId = 0
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

---@param tffKey string
---@param field any
---@param fruit any
---@param otherContractProposals Contract[]
function Contract:randomizeData(tffKey, field, fruit, otherContractProposals)
end

---@param tffKey string
---@param jobType JobType
---@param fieldId number
---@param fruitId number
function Contract:setData(tffKey, jobType, fieldId, fruitId)
    self.fieldId = fieldId
    self.fruitId = fruitId
    self.tffKey = tffKey
    self.jobTypeId = jobType.id
end
