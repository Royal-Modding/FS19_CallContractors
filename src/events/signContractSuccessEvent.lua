--- ${title}

---@author ${author}
---@version r_version_r
---@date 24/03/2021

---@class SignContractSuccessEvent
SignContractSuccessEvent = {}
SignContractSuccessEvent_mt = Class(SignContractSuccessEvent, Event)

InitEventClass(SignContractSuccessEvent, "SignContractSuccessEvent")

function SignContractSuccessEvent:emptyNew()
    local e = Event:new(SignContractSuccessEvent_mt)
    e.className = "SignContractSuccessEvent"
    return e
end

---@param contract Contract
---@return SignContractSuccessEvent
function SignContractSuccessEvent:new(contract)
    ---@type SignContractSuccessEvent
    local e = SignContractSuccessEvent:emptyNew()
    ---@type Contract
    e.contract = contract
    return e
end

---@param streamId number
function SignContractSuccessEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.contract.tffKey)
    streamWriteUInt8(streamId, self.contract.fruitId)
    streamWriteUInt8(streamId, self.contract.waitTime)
    streamWriteUInt8(streamId, self.contract.jobTypeId)
    streamWriteUInt16(streamId, self.contract.id)
    streamWriteUInt16(streamId, self.contract.npc.index)
    streamWriteUInt16(streamId, self.contract.fieldId)
    streamWriteFloat32(streamId, self.contract.callPrice)
    streamWriteFloat32(streamId, self.contract.workPrice)

end

---@param streamId number
---@param connection any
function SignContractSuccessEvent:readStream(streamId, connection)
    local tffKey = streamReadString(streamId)
    local fruitId = streamReadUInt8(streamId)
    local waitTime = streamReadUInt8(streamId)
    local jobTypeId = streamReadUInt8(streamId)
    local id = streamReadUInt16(streamId)
    local npcIndex = streamReadUInt16(streamId)
    local fieldId = streamReadUInt16(streamId)
    local callPrice = streamReadFloat32(streamId)
    local workPrice = streamReadFloat32(streamId)
    local runTimer = streamReadUIntN(streamId, 32)

    local jobType = CallContractors.JOB_TYPES[jobTypeId]
    self.contract = jobType.contractClass.new()
    self.contract:setData(tffKey, jobType, fieldId, fruitId)
    self.contract.id = id
    self.contract.waitTime = waitTime
    self.contract.runTimer = runTimer
    self.contract.callPrice = callPrice
    self.contract.workPrice = workPrice
    self.contract.npc = g_npcManager:getNPCByIndex(npcIndex) or g_npcManager:getRandomNPC()

    self:run(connection)
end

function SignContractSuccessEvent:run(_)
    CallContractors.contractsManager:onContractSigned(self.contract)
end
