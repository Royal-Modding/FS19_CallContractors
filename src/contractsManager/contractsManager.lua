--- ${title}

---@author ${author}
---@version r_version_r
---@date 22/03/2021

source(Utils.getFilename("contractsManager/contractProposalsBatch.lua", g_currentModDirectory))
source(Utils.getFilename("events/signContractEvent.lua", g_currentModDirectory))
source(Utils.getFilename("events/signContractErrorEvent.lua", g_currentModDirectory))
source(Utils.getFilename("events/signContractSuccessEvent.lua", g_currentModDirectory))
source(Utils.getFilename("events/cancelContractEvent.lua", g_currentModDirectory))
source(Utils.getFilename("events/removeContractEvent.lua", g_currentModDirectory))

---@class ContractsManager
ContractsManager = {}
ContractsManager.EVENT_TYPES = {}
ContractsManager.EVENT_TYPES.PROPOSAL_EXPIRED = 1
ContractsManager.EVENT_TYPES.CONTRACT_SIGNED = 2
ContractsManager.EVENT_TYPES.CONTRACT_SIGN_ERROR = 3
ContractsManager.EVENT_TYPES.CONTRACT_CANCELLED = 4

---@return ContractsManager
function ContractsManager:load()
    ---@type ContractProposalsBatch[]
    self.contractProposalsBatches = {}

    ---@type SignedContract[]
    self.signedContracts = {}

    self.nextSignedContractId = 0

    self.eventListeners = {}
    for _, eventId in pairs(self.EVENT_TYPES) do
        self.eventListeners[eventId] = {}
    end

    self.isServer = g_server ~= nil

    return self
end

---@param contractType ContractType
---@param farmId integer
---@param fieldId integer
---@param fruitId integer
---@return ContractProposal[]
function ContractsManager:getProposals(contractType, farmId, fieldId, fruitId)
    local contractProposalKey = contractType:getContractProposalKey(farmId, fieldId, fruitId)

    if self.contractProposalsBatches[contractProposalKey] == nil then
        self.contractProposalsBatches[contractProposalKey] = ContractProposalsBatch.new(contractProposalKey)
    end

    local batch = self.contractProposalsBatches[contractProposalKey]
    if contractType.contractClass.checkPrerequisites(farmId, fieldId, fruitId) then
        if batch:isMissingContractProposals() then
            batch:randomizeMaxContractProposals()
            while batch:isMissingContractProposals() do
                local contract = contractType:getContractInstance()
                contract:load(farmId, fieldId, fruitId)
                contract:randomize(batch:getContractProposals())
                batch:addContractProposal(ContractProposal.new(contractProposalKey, contract))
            end
        end
        return batch:getContractProposals()
    end
    return {}
end

---@return integer
function ContractsManager:getNextSignedContractId()
    self.nextSignedContractId = self.nextSignedContractId + 1
    return self.nextSignedContractId
end

---@param signedContractId integer
---@return SignedContract
function ContractsManager:getSignedContractById(signedContractId)
    return TableUtility.f_find(
        self.signedContracts,
        ---@type SignedContract
        function(sc)
            return sc.id == signedContractId
        end
    )
end

---@param signedContractKey string
---@return SignedContract
function ContractsManager:getSignedContractByKey(signedContractKey)
    return self.signedContracts[signedContractKey]
end

---@param contractProposal ContractProposal
function ContractsManager:requestContractSign(contractProposal)
    -- remove contract from proposals list
    local batch = self.contractProposalsBatches[contractProposal.key]
    batch:removeContractProposal(contractProposal)
    SignContractEvent.sendEvent(contractProposal)
end

---@param signedContract SignedContract
function ContractsManager:requestContractCancel(signedContract)
    CancelContractEvent.sendEvent(signedContract)
end

---@param contractProposal ContractProposal
---@return boolean
---@return integer | SignedContract errorOrSignedContract
function ContractsManager:signContract(contractProposal)
    if self.isServer then
        local contract = contractProposal.contract
        if not contract:hasPrerequisites() then
            return false, SignContractErrorEvent.ERROR_TYPES.CANNOT_BE_PERFORMED
        end

        local signedContractKey = contract.contractType:getSignedContractKeyByContract(contract)
        if self.signedContracts[signedContractKey] ~= nil then
            return false, SignContractErrorEvent.ERROR_TYPES.ALREADY_ACTIVE
        end

        g_currentMission:addMoney(contract.callPrice, contract.farmId, g_callContractors.moneyType, true, true)

        local signedContract = SignedContract.new(signedContractKey, contract)
        signedContract.id = self:getNextSignedContractId()

        return true, signedContract
    else
        g_debugManager:devError("[%s] ContractsManager:signContract can only run server-side", CallContractors.name)
        return false, SignContractErrorEvent.ERROR_TYPES.NOT_ON_SERVER
    end
end

---@param signedContract SignedContract
function ContractsManager:onContractSigned(signedContract)
    self.signedContracts[signedContract.key] = signedContract
    self:callEventListeners(self.EVENT_TYPES.CONTRACT_SIGNED, signedContract)
end

---@param contractProposalKey string
---@param errorType integer
function ContractsManager:onContractSignError(contractProposalKey, errorType)
    g_logManager:devError("[%s] onContractSignError(contractProposalKey: %s, errorType: %s)", CallContractors.name, contractProposalKey, TableUtility.indexOf(SignContractErrorEvent.ERROR_TYPES, errorType))
    self:callEventListeners(self.EVENT_TYPES.CONTRACT_SIGN_ERROR, contractProposalKey, errorType)
end

---@param signedContractId integer
---@param reason integer
function ContractsManager:onContractRemoved(signedContractId, reason)
    g_logManager:devInfo("[%s] onContractRemoved(contractId: %s, reason: %s)", CallContractors.name, signedContractId, TableUtility.indexOf(RemoveContractEvent.REASONS, reason))
    local signedContract = self:getSignedContractById(signedContractId)
    self.signedContracts[signedContract.key] = nil
    if reason == RemoveContractEvent.REASONS.CANCELLED then
        self:callEventListeners(self.EVENT_TYPES.CONTRACT_CANCELLED, signedContract)
    end
end

---@param dt number
function ContractsManager:update(dt)
    local scaledDt = dt * g_currentMission.missionInfo.timeScale

    -- update contract proposals ttl
    for _, batch in pairs(self.contractProposalsBatches) do
        local removedCount =
            ArrayUtility.remove(
            batch:getContractProposals(),
            ---@param array ContractProposal[]
            ---@param index integer
            ---@return boolean
            function(array, index, _)
                local proposal = array[index]
                proposal.ttl = proposal.ttl - scaledDt
                if proposal.ttl <= 0 then
                    return true
                end
                return false
            end
        )
        if removedCount > 0 then
            self:callEventListeners(self.EVENT_TYPES.PROPOSAL_EXPIRED, batch.contractProposalKey)
        end
    end

    -- update signed contracts ttl
    ---@type SignedContract
    for _, signedContract in pairs(self.signedContracts) do
        signedContract.ttl = math.max(signedContract.ttl - scaledDt, 0)
        if self.isServer and signedContract.ttl <= 0 then
        end
    end
end

---@param eventType integer
---@param object table
---@param callback string
function ContractsManager:addEventListener(eventType, object, callback)
    if self.eventListeners[eventType] ~= nil then
        self.eventListeners[eventType][object] = callback
    end
end

---@param object table
function ContractsManager:removeEventListeners(object)
    for _, typedListeners in pairs(self.eventListeners) do
        typedListeners[object] = nil
    end
end

---@param eventType integer
---@vararg any
function ContractsManager:callEventListeners(eventType, ...)
    if self.eventListeners[eventType] ~= nil then
        for callObject, callFunction in pairs(self.eventListeners[eventType]) do
            callObject[callFunction](callObject, ...)
        end
    end
end
