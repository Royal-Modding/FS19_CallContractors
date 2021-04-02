--- ${title}

---@author ${author}
---@version r_version_r
---@date 24/03/2021

---@class RemoveContractEvent : Event
RemoveContractEvent = {}
RemoveContractEvent.REASONS = {}
RemoveContractEvent.REASONS.CANCELLED = 1
RemoveContractEvent.REASONS.CANCELLED_BY_CONTRACTOR = 2
RemoveContractEvent.REASONS.PREREQUISITES_NO_LONGER_MET = 3
RemoveContractEvent.REASONS.RUN_FAILED = 4
RemoveContractEvent.REASONS.COMPLETED = 5
RemoveContractEvent.REASONS.FARMLAND_SOLD = 6
RemoveContractEvent.REASONS.FARM_DESTROYED = 7
RemoveContractEvent_mt = Class(RemoveContractEvent, Event)

InitEventClass(RemoveContractEvent, "RemoveContractEvent")

function RemoveContractEvent:emptyNew()
    local e = Event:new(RemoveContractEvent_mt)
    e.className = "RemoveContractEvent"
    return e
end

---@param signedContractId integer
---@param reason integer
---@return RemoveContractEvent
function RemoveContractEvent:new(signedContractId, reason)
    ---@type RemoveContractEvent
    local e = RemoveContractEvent:emptyNew()
    ---@type integer
    e.contractId = signedContractId
    e.reason = reason
    return e
end

---@param streamId integer
function RemoveContractEvent:writeStream(streamId, _)
    streamWriteUInt16(streamId, self.contractId)
    streamWriteUInt8(streamId, self.reason)
end

---@param streamId integer
---@param connection Connection
function RemoveContractEvent:readStream(streamId, connection)
    self.contractId = streamReadUInt16(streamId)
    self.reason = streamReadUInt8(streamId)
    self:run(connection)
end

function RemoveContractEvent:run(_)
    g_contractsManager:onContractRemoved(self.contractId, self.reason)
end

---@param signedContractId integer
---@param reason integer
function RemoveContractEvent.sendEvent(signedContractId, reason)
    if g_server ~= nil then
        g_server:broadcastEvent(RemoveContractEvent:new(signedContractId, reason), true)
    else
        g_debugManager:devError("[%s] RemoveContractEvent can only be sent from server", g_callContractors.name)
    end
end
