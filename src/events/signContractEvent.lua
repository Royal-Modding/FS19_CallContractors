--- ${title}

---@author ${author}
---@version r_version_r
---@date 23/03/2021

---@class SignContractEvent
SignContractEvent = {}
SignContractEvent_mt = Class(SignContractEvent, Event)

InitEventClass(SignContractEvent, "SignContractEvent")

function SignContractEvent:emptyNew()
    local e = Event:new(SignContractEvent_mt)
    e.className = "SignContractEvent"
    return e
end

---@param contract Contract
---@return SignContractEvent
function SignContractEvent:new(contract)
    ---@type SignContractEvent
    local e = SignContractEvent:emptyNew()
    ---@type Contract
    e.contract = contract
    return e
end

function SignContractEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.contract.tffKey)
    streamWriteUInt8(streamId, self.contract.fruitId)
    streamWriteUInt8(streamId, self.contract.waitTime)
    streamWriteUInt8(streamId, self.contract.jobTypeId)
    streamWriteUInt16(streamId, self.contract.npc.index)
    streamWriteUInt16(streamId, self.contract.fieldId)
    streamWriteFloat32(streamId, self.contract.callPrice)
    streamWriteFloat32(streamId, self.contract.workPrice)
end

function SignContractEvent:readStream(streamId, connection)
    local tffKey = streamReadString(streamId)
    local fruitId = streamReadUInt8(streamId)
    local waitTime = streamReadUInt8(streamId)
    local jobTypeId = streamReadUInt8(streamId)
    local npcIndex = streamReadUInt16(streamId)
    local fieldId = streamReadUInt16(streamId)
    local callPrice = streamReadFloat32(streamId)
    local workPrice = streamReadFloat32(streamId)

    local jobType = CallContractors.JOB_TYPES[jobTypeId]
    self.contract = jobType.contractClass.new()
    self.contract:setData(tffKey, jobType, fieldId, fruitId)
    self.contract.waitTime = waitTime
    self.contract.callPrice = callPrice
    self.contract.workPrice = workPrice
    self.contract.npc = g_npcManager:getNPCByIndex(npcIndex)

    self:run(connection)
end

---@param connection any
function SignContractEvent:run(connection)
    if g_server ~= nil then
        local success, error = CallContractors.contractsManager:signContract(self.contract)
        if success then
            -- mandare a server e clients evento "SignedContractEvent"
        else
            connection:sendEvent(SignContractErrorEvent:new(self.contract, error))
        end
    else
        g_debugManager:devError("[%s] SignContractEvent can only run server-side", CallContractors.name)
    end
end

---@param contract Contract
function SignContractEvent.sendEvent(contract)
    g_client:getServerConnection():sendEvent(SignContractEvent:new(contract))
end
