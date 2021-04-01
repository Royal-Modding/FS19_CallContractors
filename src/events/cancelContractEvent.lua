--- ${title}

---@author ${author}
---@version r_version_r
---@date 24/03/2021

---@class CancelContractEvent : Event
CancelContractEvent = {}
CancelContractEvent_mt = Class(CancelContractEvent, Event)

InitEventClass(CancelContractEvent, "CancelContractEvent")

function CancelContractEvent:emptyNew()
    local e = Event:new(CancelContractEvent_mt)
    e.className = "CancelContractEvent"
    return e
end

---@param signedContract SignedContract
---@return CancelContractEvent
function CancelContractEvent:new(signedContract)
    ---@type CancelContractEvent
    local e = CancelContractEvent:emptyNew()
    ---@type number
    e.signedContractId = signedContract.id
    return e
end

---@param streamId number
function CancelContractEvent:writeStream(streamId, _)
    streamWriteUInt16(streamId, self.signedContractId)
end

---@param streamId number
---@param connection Connection
function CancelContractEvent:readStream(streamId, connection)
    self.signedContractId = streamReadUInt16(streamId)
    self:run(connection)
end

function CancelContractEvent:run(_)
    if g_server ~= nil then
        if g_contractsManager:getSignedContractById(self.signedContractId) ~= nil then
            RemoveContractEvent.sendEvent(self.signedContractId, RemoveContractEvent.REASONS.CANCELLED)
        else
            g_debugManager:devError("[%s] Can't find contract with id = %d", g_callContractors.name, self.signedContractId)
        end
    else
        g_debugManager:devError("[%s] CancelContractEvent can only run server-side", g_callContractors.name)
    end
end

---@param signedContract SignContractEvent
function CancelContractEvent.sendEvent(signedContract)
    g_client:getServerConnection():sendEvent(CancelContractEvent:new(signedContract))
end
