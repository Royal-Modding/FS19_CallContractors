--- ${title}

---@author ${author}
---@version r_version_r
---@date 23/03/2021

---@class SignContractErrorEvent
SignContractErrorEvent = {}
SignContractErrorEvent.ERROR_TYPES = {}
SignContractErrorEvent.ERROR_TYPES.TEST = 1
SignContractErrorEvent.ERROR_TYPES.NOT_ON_SERVER = 2
SignContractError_mt = Class(SignContractErrorEvent, Event)

InitEventClass(SignContractErrorEvent, "SignContractErrorEvent")

function SignContractErrorEvent:emptyNew()
    local e = Event:new(SignContractError_mt)
    e.className = "SignContractErrorEvent"
    return e
end

---@param contract Contract
---@param errorType number
---@return SignContractErrorEvent
function SignContractErrorEvent:new(contract, errorType)
    ---@type SignContractErrorEvent
    local e = SignContractErrorEvent:emptyNew()
    ---@type Contract
    e.tffKey = contract.tffKey
    e.errorType = errorType
    return e
end

function SignContractErrorEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.tffKey)
    streamWriteUInt8(streamId, self.errorType)
end

function SignContractErrorEvent:readStream(streamId, connection)
    self.tffKey = streamReadString(streamId)
    self.errorType = streamReadUInt8(streamId)
    self:run(connection)
end

function SignContractErrorEvent:run(connection)
    CallContractors.contractsManager:onContractSignError(self.tffKey, self.errorType)
end
