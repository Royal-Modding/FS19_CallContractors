--- ${title}

---@author ${author}
---@version r_version_r
---@date 23/03/2021

---@class SignContractEvent : Event
SignContractEvent = {}
local SignContractEvent_mt = Class(SignContractEvent, Event)

InitEventClass(SignContractEvent, "SignContractEvent")

function SignContractEvent:emptyNew()
    local e = Event:new(SignContractEvent_mt)
    e.className = "SignContractEvent"
    return e
end

---@param contractProposal ContractProposal
---@return SignContractEvent
function SignContractEvent:new(contractProposal)
    ---@type SignContractEvent
    local e = SignContractEvent:emptyNew()
    ---@type ContractProposal
    e.contractProposal = contractProposal
    return e
end

---@param streamId number
function SignContractEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.contractProposal.key)
    streamWriteUInt8(streamId, self.contractProposal.contract.type.id)
    self.contractProposal.contract:writeToStream(streamId)
end

---@param streamId number
---@param connection Connection
function SignContractEvent:readStream(streamId, connection)
    local pKey = streamReadString(streamId)
    local contractTypeId = streamReadUInt8(streamId)
    local contractType = g_callContractors.CONTRACT_TYPES[contractTypeId]
    local contract = contractType:getContractInstance()
    contract:readFromStream(streamId)
    self.contractProposal = ContractProposal.new(pKey, contract)

    self:run(connection)
end

---@param connection Connection
function SignContractEvent:run(connection)
    if g_server ~= nil then
        local success, errorOrSignedContract = g_contractsManager:signContract(self.contractProposal)
        if success then
            g_server:broadcastEvent(SignContractSuccessEvent:new(errorOrSignedContract), true)
        else
            connection:sendEvent(SignContractErrorEvent:new(self.contractProposal, errorOrSignedContract))
        end
    else
        g_logManager:devError("[%s] SignContractEvent can only run server-side", g_callContractors.name)
    end
end

---@param contractProposal ContractProposal
function SignContractEvent.sendEvent(contractProposal)
    g_client:getServerConnection():sendEvent(SignContractEvent:new(contractProposal))
end
