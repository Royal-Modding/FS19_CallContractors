--- ${title}

---@author ${author}
---@version r_version_r
---@date 23/03/2021

---@class SignContractErrorEvent : Event
SignContractErrorEvent = {}
SignContractErrorEvent.ERROR_TYPES = {}
SignContractErrorEvent.ERROR_TYPES.TEST = 1
SignContractErrorEvent.ERROR_TYPES.NOT_ON_SERVER = 2
SignContractErrorEvent.ERROR_TYPES.PREREQUISITES_NO_LONGER_MET = 3
SignContractErrorEvent.ERROR_TYPES.ALREADY_ACTIVE = 4
local SignContractError_mt = Class(SignContractErrorEvent, Event)

InitEventClass(SignContractErrorEvent, "SignContractErrorEvent")

function SignContractErrorEvent:emptyNew()
    local e = Event:new(SignContractError_mt)
    e.className = "SignContractErrorEvent"
    return e
end

---@param contractProposal ContractProposal
---@param errorType number
---@return SignContractErrorEvent
function SignContractErrorEvent:new(contractProposal, errorType)
    ---@type SignContractErrorEvent
    local e = SignContractErrorEvent:emptyNew()
    ---@type Contract
    e.contractProposalKey = contractProposal.key
    e.errorType = errorType
    return e
end

---@param streamId number
function SignContractErrorEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.contractProposalKey)
    streamWriteUInt8(streamId, self.errorType)
end

---@param streamId number
---@param connection Connection
function SignContractErrorEvent:readStream(streamId, connection)
    self.contractProposalKey = streamReadString(streamId)
    self.errorType = streamReadUInt8(streamId)
    self:run(connection)
end

function SignContractErrorEvent:run(_)
    g_contractsManager:onContractSignError(self.contractProposalKey, self.errorType)
end
