--- ${title}

---@author ${author}
---@version r_version_r
---@date 24/03/2021

---@class RemoveContractEvent
RemoveContractEvent = {}
RemoveContractEvent.REASONS = {}
RemoveContractEvent.REASONS.CANCELLED = 1
RemoveContractEvent_mt = Class(RemoveContractEvent, Event)

InitEventClass(RemoveContractEvent, "RemoveContractEvent")

function RemoveContractEvent:emptyNew()
    local e = Event:new(RemoveContractEvent_mt)
    e.className = "RemoveContractEvent"
    return e
end

---@param signedContractId number
---@param reason number
---@return RemoveContractEvent
function RemoveContractEvent:new(signedContractId, reason)
    ---@type RemoveContractEvent
    local e = RemoveContractEvent:emptyNew()
    ---@type number
    e.contractId = signedContractId
    e.reason = reason
    return e
end

---@param streamId number
function RemoveContractEvent:writeStream(streamId, _)
    streamWriteUInt16(streamId, self.contractId)
    streamWriteUInt8(streamId, self.reason)
end

---@param streamId number
---@param connection any
function RemoveContractEvent:readStream(streamId, connection)
    self.contractId = streamReadUInt16(streamId)
    self.reason = streamReadUInt8(streamId)
    self:run(connection)
end

function RemoveContractEvent:run(_)
    g_contractsManager:onContractRemoved(self.contractId, self.reason)
end

---@param signedContractId number
---@param reason number
function RemoveContractEvent.sendEvent(signedContractId, reason)
    if g_server ~= nil then
        g_server:broadcastEvent(RemoveContractEvent:new(signedContractId, reason), true)
    else
        g_debugManager:devError("[%s] RemoveContractEvent can only be sent from server", CallContractors.name)
    end
end
