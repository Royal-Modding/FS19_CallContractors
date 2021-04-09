--- ${title}

---@author ${author}
---@version r_version_r
---@date 24/03/2021

---@class SignContractSuccessEvent : Event
SignContractSuccessEvent = {}
SignContractSuccessEvent_mt = Class(SignContractSuccessEvent, Event)

InitEventClass(SignContractSuccessEvent, "SignContractSuccessEvent")

function SignContractSuccessEvent:emptyNew()
    local e = Event:new(SignContractSuccessEvent_mt)
    e.className = "SignContractSuccessEvent"
    return e
end

---@param signedContract SignedContract
---@return SignContractSuccessEvent
function SignContractSuccessEvent:new(signedContract)
    ---@type SignContractSuccessEvent
    local e = SignContractSuccessEvent:emptyNew()
    ---@type SignedContract
    e.signedContract = signedContract
    return e
end

---@param streamId number
function SignContractSuccessEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.signedContract.key)
    streamWriteUInt8(streamId, self.signedContract.contract.type.id)
    streamWriteUInt16(streamId, self.signedContract.id)
    streamWriteUIntN(streamId, self.signedContract.ttl, 28)
    self.signedContract.contract:writeToStream(streamId)
end

---@param streamId number
---@param connection Connection
function SignContractSuccessEvent:readStream(streamId, connection)
    local sKey = streamReadString(streamId)
    local contractTypeId = streamReadUInt8(streamId)
    local id = streamReadUInt16(streamId)
    local ttl = streamReadUIntN(streamId, 28)

    local contractType = g_callContractors.CONTRACT_TYPES[contractTypeId]
    local contract = contractType:getContractInstance()
    contract:readFromStream(streamId)

    self.signedContract = SignedContract.new(sKey, contract)
    self.signedContract.id = id
    self.signedContract.ttl = ttl

    self:run(connection)
end

function SignContractSuccessEvent:run(_)
    g_contractsManager:onContractSigned(self.signedContract)
end
