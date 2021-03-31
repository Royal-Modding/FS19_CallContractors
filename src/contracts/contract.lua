--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class Contract : Class
Contract = {}
Contract_mt = Class(Contract)

--- Contract base class
---@param contractType ContractType
---@param mt? table custom meta table
---@return Contract
function Contract.new(contractType, mt)
    ---@type Contract
    local self = setmetatable({}, mt or Contract_mt)

    ---@type ContractType
    self.contractType = contractType

    ---@type integer
    self.farmId = 0

    ---@type integer
    self.fieldId = 0

    ---@type integer
    self.fruitId = 0

    ---@type number
    self.callPrice = 0 -- price to pay at contract sign

    ---@type number
    self.workPrice = 0 -- price to pay at job finished

    ---@type number
    self.waitTime = 24 -- hours

    ---@type NPCEntry
    self.npc = nil

    return self
end

---@param farmId integer
---@param fieldId integer
---@param fruitId integer
---@return boolean
function Contract.checkPrerequisites(farmId, fieldId, fruitId)
    return false
end

---@return boolean
function Contract:hasPrerequisites()
    return self.checkPrerequisites(self.farmId, self.fieldId, self.fruitId)
end

---@param farmId integer
---@param fieldId integer
---@param fruitId integer
function Contract:load(farmId, fieldId, fruitId)
    self.farmId = farmId
    self.fieldId = fieldId
    self.fruitId = fruitId
end

---@param otherContractProposals ContractProposal[]
function Contract:randomize(otherContractProposals)
end

---@return Field
function Contract:getField()
    return g_fieldManager:getFieldByIndex(self.fieldId)
end

---@return FruitTypeEntry
function Contract:getFruit()
    return g_fruitTypeManager:getFruitTypeByIndex(self.fruitId)
end

---@return Farm
function Contract:getFarm()
    return g_farmManager:getFarmById(self.farmId)
end

---@param streamId integer
function Contract:writeToStream(streamId)
    streamWriteUInt8(streamId, self.fruitId)
    streamWriteUInt8(streamId, self.farmId)
    streamWriteUInt8(streamId, self.waitTime)
    streamWriteUInt16(streamId, self.npc.index)
    streamWriteUInt16(streamId, self.fieldId)
    streamWriteFloat32(streamId, self.callPrice)
    streamWriteFloat32(streamId, self.workPrice)
end

---@param streamId integer
function Contract:readFromStream(streamId)
    self.fruitId = streamReadUInt8(streamId)
    self.farmId = streamReadUInt8(streamId)
    self.waitTime = streamReadUInt8(streamId)
    local npcIndex = streamReadUInt16(streamId)
    self.npc = g_npcManager:getNPCByIndex(npcIndex) or g_npcManager:getRandomNPC()
    self.fieldId = streamReadUInt16(streamId)
    self.callPrice = streamReadFloat32(streamId)
    self.workPrice = streamReadFloat32(streamId)
end
