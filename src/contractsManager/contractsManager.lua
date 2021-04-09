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
source(Utils.getFilename("events/requestContractsEvent.lua", g_currentModDirectory))

---@class ContractsManager
ContractsManager = {}
ContractsManager.EVENT_TYPES = {}
ContractsManager.EVENT_TYPES.PROPOSAL_EXPIRED = 1
ContractsManager.EVENT_TYPES.CONTRACT_SIGNED = 2
ContractsManager.EVENT_TYPES.CONTRACT_SIGN_ERROR = 3
ContractsManager.EVENT_TYPES.CONTRACT_CANCELLED = 4
ContractsManager.EVENT_TYPES.CONTRACT_REMOVED = 5

---@return ContractsManager
function ContractsManager:load()
    ---@type ContractProposalsBatch[]
    self.contractProposalsBatches = {}

    ---@type SignedContract[]
    self.signedContracts = {}

    ---@type integer
    self.nextSignedContractId = 0

    ---@type table<table, string>[]
    self.eventListeners = {}
    for _, eventId in pairs(self.EVENT_TYPES) do
        self.eventListeners[eventId] = {}
    end

    self.isServer = g_server ~= nil

    if self.isServer then
        g_farmlandManager:addStateChangeListener(self)
        g_messageCenter:subscribe(MessageType.FARM_DELETED, self.farmDestroyed, self)
    end

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

---@return SignedContract[]
function ContractsManager:getSignedContracts()
    return self.signedContracts
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
            return false, SignContractErrorEvent.ERROR_TYPES.PREREQUISITES_NO_LONGER_MET
        end

        local signedContractKey = contract.type:getSignedContractKeyByContract(contract)
        if self.signedContracts[signedContractKey] ~= nil then
            return false, SignContractErrorEvent.ERROR_TYPES.ALREADY_ACTIVE
        end

        g_currentMission:addMoney(-(contract.callPrice), contract.farmId, g_callContractors.moneyType, true, true)

        local signedContract = SignedContract.new(signedContractKey, contract)
        signedContract.id = self:getNextSignedContractId()

        return true, signedContract
    else
        g_logManager:devError("[%s] ContractsManager:signContract can only run server-side", g_callContractors.name)
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
    g_logManager:devWarning("[%s] onContractSignError(contractProposalKey: %s, errorType: %s)", g_callContractors.name, contractProposalKey, TableUtility.indexOf(SignContractErrorEvent.ERROR_TYPES, errorType))
    self:callEventListeners(self.EVENT_TYPES.CONTRACT_SIGN_ERROR, contractProposalKey, errorType)
end

---@param signedContractId integer
---@param reason integer
function ContractsManager:onContractRemoved(signedContractId, reason)
    --g_logManager:devInfo("[%s] onContractRemoved(contractId: %s, reason: %s)", g_callContractors.name, signedContractId, TableUtility.indexOf(RemoveContractEvent.REASONS, reason))

    local signedContract = self:getSignedContractById(signedContractId)
    self.signedContracts[signedContract.key] = nil

    if reason == RemoveContractEvent.REASONS.CANCELLED then
        self:callEventListeners(self.EVENT_TYPES.CONTRACT_CANCELLED, signedContract)
    else
        self:callEventListeners(self.EVENT_TYPES.CONTRACT_REMOVED, signedContract, reason)
    end

    if reason == RemoveContractEvent.REASONS.CANCELLED_BY_CONTRACTOR then
        if signedContract.contract.farmId == g_currentMission:getFarmId() and g_dedicatedServerInfo == nil then
            g_gui:showInfoDialog({text = g_i18n:getText("dialog_cc_contract_cancelled_by_contractor"):format(signedContract.contract.npc.title)})
        end
    end

    if reason == RemoveContractEvent.REASONS.PREREQUISITES_NO_LONGER_MET then
        if signedContract.contract.farmId == g_currentMission:getFarmId() and g_dedicatedServerInfo == nil then
            g_gui:showInfoDialog({text = g_i18n:getText("dialog_cc_contract_prerequisites_no_longer_met"):format(signedContract.contract.npc.title)})
        end
    end
end

---@param farmlandId integer
---@param farmId integer
function ContractsManager:onFarmlandStateChanged(farmlandId, farmId)
    if farmId == FarmlandManager.NO_OWNER_FARM_ID then
        for _, signedContract in pairs(self.signedContracts) do
            if signedContract.contract.type.requireFieldParam then
                if signedContract.contract:getField().farmland.id == farmlandId then
                    RemoveContractEvent.sendEvent(signedContract.id, RemoveContractEvent.REASONS.FARMLAND_SOLD)
                end
            end
        end
    end
end

---@param farmId integer
function ContractsManager:farmDestroyed(farmId)
    for _, signedContract in pairs(self.signedContracts) do
        if signedContract.contract.farmId == farmId then
            RemoveContractEvent.sendEvent(signedContract.id, RemoveContractEvent.REASONS.FARM_DESTROYED)
        end
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
        if self.isServer then
            -- cancel one contract every ~15 (calculated on an avarage contract wait time of 23h)
            if math.random(1, math.ceil(77550000 / g_currentMission.missionInfo.timeScale)) == 500 then
                -- refund twice the amount of the deposit
                g_currentMission:addMoney(signedContract.contract.callPrice * 2, signedContract.contract.farmId, g_callContractors.moneyType, true, true)
                RemoveContractEvent.sendEvent(signedContract.id, RemoveContractEvent.REASONS.CANCELLED_BY_CONTRACTOR)
            elseif signedContract.ttl <= 0 then
                -- check if prerequisites are still met
                if signedContract.contract:hasPrerequisites() then
                    -- run the contract
                    if signedContract.contract:run() then
                        g_currentMission:addMoney(-(signedContract.contract.workPrice), signedContract.contract.farmId, g_callContractors.moneyType, true, true)
                        RemoveContractEvent.sendEvent(signedContract.id, RemoveContractEvent.REASONS.COMPLETED)
                    else
                        RemoveContractEvent.sendEvent(signedContract.id, RemoveContractEvent.REASONS.RUN_FAILED)
                    end
                else
                    RemoveContractEvent.sendEvent(signedContract.id, RemoveContractEvent.REASONS.PREREQUISITES_NO_LONGER_MET)
                end
            end
        end
    end
end

---@param xmlFile integer
---@param baseKey string
function ContractsManager:onSaveSavegame(xmlFile, baseKey)
    local i = 0
    for _, signedContract in pairs(self.signedContracts) do
        local key = string.format("%s.signedContracts.signedContract(%d)", baseKey, i)
        signedContract:saveToXMLFile(xmlFile, key)
        i = i + 1
    end
end

---@param xmlFile integer
---@param baseKey string
function ContractsManager:onLoadSavegame(xmlFile, baseKey)
    local i = 0
    while true do
        local key = string.format("%s.signedContracts.signedContract(%d)", baseKey, i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local signedContract = SignedContract.new()
        signedContract:loadFromXMLFile(xmlFile, key)
        signedContract.id = self:getNextSignedContractId()
        self.signedContracts[signedContract.key] = signedContract
        i = i + 1
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
