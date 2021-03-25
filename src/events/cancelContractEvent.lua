--- ${title}

---@author ${author}
---@version r_version_r
---@date 24/03/2021

---@class CancelContractEvent
CancelContractEvent = {}
CancelContractEvent_mt = Class(CancelContractEvent, Event)

InitEventClass(CancelContractEvent, "CancelContractEvent")

function CancelContractEvent:emptyNew()
    local e = Event:new(CancelContractEvent_mt)
    e.className = "CancelContractEvent"
    return e
end

---@param contract Contract
---@return CancelContractEvent
function CancelContractEvent:new(contract)
    ---@type CancelContractEvent
    local e = CancelContractEvent:emptyNew()
    ---@type number
    e.contractId = contract.id
    return e
end

---@param streamId number
function CancelContractEvent:writeStream(streamId, _)
    streamWriteUInt16(streamId, self.contractId)
end

---@param streamId number
---@param connection any
function CancelContractEvent:readStream(streamId, connection)
    self.contractId = streamReadUInt16(streamId)
    self:run(connection)
end

---@param connection any
function CancelContractEvent:run(connection)
    if g_server ~= nil then
        if CallContractors.contractsManager:getContractById(self.contractId) ~= nil then
            RemoveContractEvent.sendEvent(self.contractId, RemoveContractEvent.REASONS.CANCELLED)
        else
            g_debugManager:devError("[%s] Can't find contract with id = %d", CallContractors.name, self.contractId)
        end
    else
        g_debugManager:devError("[%s] CancelContractEvent can only run server-side", CallContractors.name)
    end
end

---@param contract Contract
function CancelContractEvent.sendEvent(contract)
    g_client:getServerConnection():sendEvent(CancelContractEvent:new(contract))
end
