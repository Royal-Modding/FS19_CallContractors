--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class Contract
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

    ---@type number
    self.farmId = 0

    ---@type number
    self.fieldId = 0

    ---@type number
    self.fruitId = 0

    ---@type number
    self.callPrice = 0 -- price to pay at contract sign

    ---@type number
    self.workPrice = 0 -- price to pay at job finished

    ---@type number
    self.waitTime = 24 -- hours

    ---@type NPC
    self.npc = nil

    return self
end

---@param farmId number
---@param fieldId number
---@param fruitId number
---@return boolean
function Contract.checkPrerequisites(farmId, fieldId, fruitId)
    return false
end

---@return boolean
function Contract:hasPrerequisites()
    return self.checkPrerequisites(self.farmId, self.fieldId, self.fruitId)
end

---@param farmId number
---@param fieldId number
---@param fruitId number
function Contract:load(farmId, fieldId, fruitId)
    self.farmId = farmId
    self.fieldId = fieldId
    self.fruitId = fruitId
end

---@param otherContractProposals ContractProposal[]
function Contract:randomize(otherContractProposals)
end

function Contract:getField()
    return g_fieldManager:getFieldByIndex(self.fieldId)
end

function Contract:getFruit()
    return g_fruitTypeManager:getFruitTypeByIndex(self.fruitId)
end

function Contract:getFarm()
    return g_farmManager:getFarmById(self.farmId)
end

function Contract:writeToStream(streamId)
    streamWriteUInt8(streamId, self.fruitId)
    streamWriteUInt8(streamId, self.farmId)
    streamWriteUInt8(streamId, self.waitTime)
    streamWriteUInt16(streamId, self.npc.index)
    streamWriteUInt16(streamId, self.fieldId)
    streamWriteFloat32(streamId, self.callPrice)
    streamWriteFloat32(streamId, self.workPrice)
end

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
