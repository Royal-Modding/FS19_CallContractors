--- ${title}

---@author ${author}
---@version r_version_r
---@date 22/03/2021

source(Utils.getFilename("events/signContractEvent.lua", g_currentModDirectory))
source(Utils.getFilename("events/signContractErrorEvent.lua", g_currentModDirectory))

---@class ContractsManager
ContractsManager = {}
---@type JobType[]
ContractsManager.JOB_TYPES = {}

ContractsManager.EVENT_TYPES = {}
ContractsManager.EVENT_TYPES.PROPOSAL_EXPIRED = 1
ContractsManager.EVENT_TYPES.CONTRACT_SIGNED = 2
ContractsManager.EVENT_TYPES.CONTRACT_SIGN_ERROR = 3

---@param jobTypes JobType[]
---@return ContractsManager
function ContractsManager:load(jobTypes)
    self.JOB_TYPES = jobTypes
    self.contractProposalsByTffKey = {}
    self.maxContractsMin = 3
    self.maxContractsMax = 7
    self.eventListeners = {}
    for _, eventId in pairs(self.EVENT_TYPES) do
        self.eventListeners[eventId] = {}
    end
    return self
end

---@param jobType JobType
---@param field any
---@param fruit any
---@return Contract[] contracts
function ContractsManager:getContractProposals(jobType, field, fruit)
    local tffKey = self:getTffKey(jobType, field, fruit)
    if self.contractProposalsByTffKey[tffKey] == nil then
        self.contractProposalsByTffKey[tffKey] = {}
        self.contractProposalsByTffKey[tffKey].settings = {}
        self.contractProposalsByTffKey[tffKey].settings.maxContracts = math.random(self.maxContractsMin, self.maxContractsMax)
        self.contractProposalsByTffKey[tffKey].contractProposals = {}
    end
    if jobType.contractClass.canBePerformed(field, fruit) then
        if #self.contractProposalsByTffKey[tffKey].contractProposals < self.contractProposalsByTffKey[tffKey].settings.maxContracts then
            self:generateNewContractProposals(tffKey, jobType, field, fruit)
        end
        return self.contractProposalsByTffKey[tffKey].contractProposals
    else
        return {}
    end
end

---@param tffKey string
---@param jobType JobType
---@param field any
---@param fruit any
function ContractsManager:generateNewContractProposals(tffKey, jobType, field, fruit)
    -- new random amount of contracts
    self.contractProposalsByTffKey[tffKey].settings.maxContracts = math.random(self.maxContractsMin, self.maxContractsMax)
    while #self.contractProposalsByTffKey[tffKey].contractProposals < self.contractProposalsByTffKey[tffKey].settings.maxContracts do
        table.insert(self.contractProposalsByTffKey[tffKey].contractProposals, self:generateNewContractProposal(jobType, field, fruit, self.contractProposalsByTffKey[tffKey].contractProposals, tffKey))
    end
end

---@param jobType JobType
---@param field any
---@param fruit any
---@param contractProposals Contract[]
---@param tffKey string
---@return Contract contract
function ContractsManager:generateNewContractProposal(jobType, field, fruit, contractProposals, tffKey)
    local contract = jobType.contractClass.new()
    contract:setData(tffKey, jobType, field.fieldId, fruit.index)
    contract:randomizeData(field, fruit, contractProposals)
    return contract
end

---@param jobType JobType
---@param field any
---@param fruit any
---@return string tffKey
function ContractsManager:getTffKey(jobType, field, fruit)
    local tffKey = jobType.name
    if jobType.requireFieldParam then
        tffKey = string.format("%s_%d", tffKey, field.fieldId)
    end
    if jobType.requireFruitParam then
        tffKey = string.format("%s_%s", tffKey, fruit.name)
    end
    return tffKey
end

---@param contract Contract
function ContractsManager:requestContractSign(contract)
    -- remove contract from proposals list
    ArrayUtility.remove(
        self.contractProposalsByTffKey[contract.tffKey].contractProposals,
        function(array, index, _)
            return array[index] == contract
        end
    )
    SignContractEvent.sendEvent(contract)
end

---@param contract Contract
function ContractsManager:signContract(contract)
    return false, SignContractErrorEvent.ERROR_TYPES.TEST

    --if g_server ~= nil then
    --    return true
    --else
    --    g_debugManager:devError("[%s] ContractsManager:signContract can only run server-side", CallContractors.name)
    --    return false, SignContractError.ERROR_TYPES.NOT_ON_SERVER
    --end
end

---@param tffKey string
---@param errorType number
function ContractsManager:onContractSignError(tffKey, errorType)
    g_logManager:devError("[%s] onContractSignError(tffKey: %s, errorType: %s)", CallContractors.name, tffKey, TableUtility.indexOf(SignContractErrorEvent.ERROR_TYPES, errorType))
    self:callEventListeners(self.EVENT_TYPES.CONTRACT_SIGN_ERROR, tffKey, errorType)
end

---@param contract Contract
function ContractsManager:onContractSigned(contract)
    self:callEventListeners(self.EVENT_TYPES.CONTRACT_SIGNED, contract)
end

---@param dt number
---@param gui any
function ContractsManager:update(dt, gui)
    local scaledDt = dt * g_currentMission.missionInfo.timeScale

    -- update contract proposals ttl
    for tffKey, contractProposals in pairs(self.contractProposalsByTffKey) do
        local removedCount =
            ArrayUtility.remove(
            contractProposals.contractProposals,
            function(array, index, _)
                ---@type Contract
                local contract = array[index]
                contract.ttl = contract.ttl - scaledDt
                if contract.ttl <= 0 then
                    return true
                end
                return false
            end
        )
        if removedCount > 0 then
            self:callEventListeners(self.EVENT_TYPES.PROPOSAL_EXPIRED, tffKey)
        end
    end
end

---@param eventType number
---@param object any
---@param callback string
function ContractsManager:addEventListener(eventType, object, callback)
    if self.eventListeners[eventType] ~= nil then
        self.eventListeners[eventType][object] = callback
    end
end

---@param object any
function ContractsManager:removeEventListeners(object)
    for _, typedListeners in pairs(self.eventListeners) do
        typedListeners[object] = nil
    end
end

---@param eventType number
function ContractsManager:callEventListeners(eventType, ...)
    if self.eventListeners[eventType] ~= nil then
        for callObject, callFunction in pairs(self.eventListeners[eventType]) do
            callObject[callFunction](callObject, ...)
        end
    end
end
