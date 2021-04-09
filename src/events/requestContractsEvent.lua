--- ${title}

---@author ${author}
---@version r_version_r
---@date 01/04/2021

---@class RequestContractsEvent : Event
RequestContractsEvent = {}
local RequestContractsEvent_mt = Class(RequestContractsEvent, Event)

InitEventClass(RequestContractsEvent, "RequestContractsEvent")

function RequestContractsEvent:emptyNew()
    local e = Event:new(RequestContractsEvent_mt)
    e.className = "RequestContractsEvent"
    return e
end

---@return RequestContractsEvent
function RequestContractsEvent:new()
    ---@type RequestContractsEvent
    local e = RequestContractsEvent:emptyNew()
    return e
end

---@param streamId number
function RequestContractsEvent:writeStream(streamId, _)
end

---@param streamId number
---@param connection Connection
function RequestContractsEvent:readStream(streamId, connection)
    self:run(connection)
end

---@param connection Connection
function RequestContractsEvent:run(connection)
    if g_server ~= nil then
        for _, signedContract in pairs(g_contractsManager:getSignedContracts()) do
            connection:sendEvent(SignContractSuccessEvent:new(signedContract))
        end
    else
        g_logManager:devError("[%s] RequestContractsEvent can only run server-side", g_callContractors.name)
    end
end

function RequestContractsEvent.sendEvent()
    g_client:getServerConnection():sendEvent(RequestContractsEvent:new())
end
