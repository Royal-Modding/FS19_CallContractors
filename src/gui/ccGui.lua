--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class CCGui : Class
---@field onClickBack function
---@field registerControls function
---@field ccProposalItemTemplate any
---@field ccContractItemTemplate any
---@field ccList any
---@field ccFieldSelector any
---@field ccContractTypeSelector any
---@field ccFruitSelector any
---@field ccNoContractsBox any
---@field ccActivateButton any
---@field ccCancelButton any
---@field ccContractSigningImageBg any
CCGui = {}
CCGui.CONTROLS = {"ccProposalItemTemplate", "ccContractItemTemplate", "ccList", "ccFieldSelector", "ccContractTypeSelector", "ccFruitSelector", "ccNoContractsBox", "ccActivateButton", "ccCancelButton", "ccContractSigningImageBg"}

local CCGui_mt = Class(CCGui, ScreenElement)

---@param target table
---@return CCGui
function CCGui:new(target)
    ---@type CCGui
    local o = ScreenElement:new(target, CCGui_mt)
    o.returnScreenName = ""

    ---@type ContractType[]
    o.contractTypes = {}
    ---@type ContractType[]
    o.contractTypesMapping = {}
    ---@type ContractType
    o.selectedContractType = nil

    o.fields = {}
    o.fieldsMapping = {}
    o.selectedField = nil

    o.fruits = {}
    o.fruitsMapping = {}
    o.selectedFruit = nil

    o.currentContractProposalKey = "nil"
    o.currentSignedContractKey = "nil"

    ---@type DelayedCallBack
    o.removeSigningContractDCB = DelayedCallBack:new(CCGui.onRemoveSigningContractDCB, o)

    o.currentFarmId = 0

    ---@type CCGuiSigningContractsLocker
    o.locker = CCGuiSigningContractsLocker:new()

    o.slowUpdateTimer = 0
    o.slowUpdateEvery = 3000

    o:registerControls(CCGui.CONTROLS)

    return o
end

function CCGui:onCreate()
    self.contractTypes = g_callContractors.CONTRACT_TYPES
    self.fields = g_fieldManager:getFields()
    self.fruits = g_fruitTypeManager:getFruitTypes()

    self.ccProposalItemTemplate:unlinkElement()
    self.ccProposalItemTemplate:setVisible(false)

    self.ccContractItemTemplate:unlinkElement()
    self.ccContractItemTemplate:setVisible(false)

    self.ccContractSigningImageBg.elements[1]:setImageFilename(Utils.getFilename("img/cs_icon.dds", CallContractors.guiDirectory))
end

---@param farmId number
---@return number
function CCGui:onPreOpen(farmId)
    self.currentFarmId = farmId
    local texts = {}
    self.contractTypesMapping = {}
    for _, contractType in pairs(self.contractTypes) do
        if contractType.checkPrerequisites(farmId) then
            table.insert(texts, contractType.title)
            table.insert(self.contractTypesMapping, contractType)
        end
    end
    -- don't setTexts if there's nothing to insert, otherwise the "multi text option state" is set to a wrong state (probably nil or -1)
    if #texts > 0 then
        self.ccContractTypeSelector:setTexts(texts)
        self.selectedContractType = self.contractTypesMapping[self.ccContractTypeSelector:getState()]
    end
    return #texts
end

function CCGui:onOpen()
    self.locker:clear()

    g_contractsManager:addEventListener(ContractsManager.EVENT_TYPES.PROPOSAL_EXPIRED, self, "onProposalExpired")
    g_contractsManager:addEventListener(ContractsManager.EVENT_TYPES.CONTRACT_SIGNED, self, "onContractSigned")
    g_contractsManager:addEventListener(ContractsManager.EVENT_TYPES.CONTRACT_SIGN_ERROR, self, "onContractSignError")
    g_contractsManager:addEventListener(ContractsManager.EVENT_TYPES.CONTRACT_CANCELLED, self, "onContractCancelled")
    g_contractsManager:addEventListener(ContractsManager.EVENT_TYPES.CONTRACT_REMOVED, self, "onContractRemoved")

    -- preload texts to ensure that there's always something to show
    self:updateFieldSelectorTexts(
        self.fields,
        function()
            return true
        end
    )

    self:updateFruitSelectorTexts(
        self.fruits,
        function()
            return true
        end
    )

    CCGui:superClass().onOpen(self)

    self:onJobTypeSelectionChanged()
end

function CCGui:onClose()
    g_contractsManager:removeEventListeners(self)
    CCGui:superClass().onClose(self)
end

function CCGui:refreshList()
    self.currentContractProposalKey = self.selectedContractType:getContractProposalKey(self.currentFarmId, self.selectedField.fieldId, self.selectedFruit.index)
    self.currentSignedContractKey = self.selectedContractType:getSignedContractKey(self.currentFarmId, self.selectedField.fieldId, self.selectedFruit.index)

    self.ccList:deleteListItems()

    local signedContract = g_contractsManager:getSignedContractByKey(self.currentSignedContractKey)
    if signedContract ~= nil then
        local contract = signedContract.contract
        local new = self.ccContractItemTemplate:clone(self.ccList)
        new:setVisible(true)
        new.elements[1].elements[1]:setImageFilename(contract.npc.imageFilename)
        new.elements[2]:setText(contract.npc.title)
        new.elements[3]:setText(string.format(g_i18n:getText("gui_cc_job_time_text"), math.ceil(signedContract.ttl / 60 / 60 / 1000))) -- ms to hours
        new.elements[4]:setText(g_i18n:formatMoney(contract.workPrice))
        new.elements[7]:setText(contract.type.title)
        new:updateAbsolutePosition()
        new.signedContract = signedContract

        self.ccNoContractsBox:setVisible(false)
    else
        ---@type ContractProposal[]
        local contractProposals = g_contractsManager:getProposals(self.selectedContractType, self.currentFarmId, self.selectedField.fieldId, self.selectedFruit.index)
        table.sort(
            contractProposals,
            ---@param a ContractProposal
            ---@param b ContractProposal
            ---@return boolean
            function(a, b)
                return a.contract.waitTime < b.contract.waitTime
            end
        )

        for _, cp in pairs(contractProposals) do
            local contract = cp.contract
            local new = self.ccProposalItemTemplate:clone(self.ccList)
            new:setVisible(true)
            new.elements[1].elements[1]:setImageFilename(contract.npc.imageFilename)
            new.elements[2]:setText(contract.npc.title)
            new.elements[3]:setText(string.format(g_i18n:getText("gui_cc_job_time_text"), contract.waitTime))
            new.elements[4]:setText(g_i18n:formatMoney(contract.callPrice))
            new.elements[5]:setText(g_i18n:formatMoney(contract.workPrice))
            new.elements[6]:setText(g_i18n:formatMoney(contract.callPrice + contract.workPrice))
            new:updateAbsolutePosition()
            new.contractProposal = cp
        end

        self.ccNoContractsBox:setVisible(#contractProposals <= 0)
    end

    self:refreshButtons()
    self:refreshSigningOverlay()
end

function CCGui:refreshButtons()
    local activate = false
    local cancel = false
    local element = self.ccList:getSelectedElement()
    if self.ccList:getItemCount() > 0 and element ~= nil then
        if element.contractProposal ~= nil then
            activate = true
        else
            cancel = true
        end
    end
    self.ccActivateButton:setVisible(activate)
    self.ccActivateButton:setDisabled(not activate)
    self.ccCancelButton:setVisible(cancel)
    self.ccCancelButton:setDisabled(not cancel)
end

function CCGui:refreshSigningOverlay()
    local isLocked = self.locker:getIsLocked(self.currentSignedContractKey)
    self.ccContractSigningImageBg:setVisible(isLocked)
    self.ccList:setVisible(not isLocked)
    if isLocked then
        self.ccNoContractsBox:setVisible(false)
    end
end

---@param fields table
---@param filter function
function CCGui:updateFieldSelectorTexts(fields, filter)
    local texts = {}
    self.fieldsMapping = {}
    for _, field in pairs(fields) do
        if filter(self.currentFarmId, field) then
            table.insert(texts, field.fieldId)
            table.insert(self.fieldsMapping, field)
        end
    end
    self.ccFieldSelector:setTexts(texts)
    self.selectedField = self.fieldsMapping[self.ccFieldSelector:getState()]
end

---@param fruits table
---@param filter function
function CCGui:updateFruitSelectorTexts(fruits, filter)
    local texts = {}
    self.fruitsMapping = {}
    for _, fruit in pairs(fruits) do
        if filter(self.currentFarmId, fruit) then
            table.insert(texts, fruit.fillType.title)
            table.insert(self.fruitsMapping, fruit)
        end
    end
    self.ccFruitSelector:setTexts(texts)
    self.selectedFruit = self.fruitsMapping[self.ccFruitSelector:getState()]
end

---@param dt number
function CCGui:update(dt)
    CCGui:superClass().update(self, dt)
    self.removeSigningContractDCB:update(dt)
    self.slowUpdateTimer = self.slowUpdateTimer + dt
    if self.slowUpdateTimer >= self.slowUpdateEvery then
        self.slowUpdateTimer = 0

        -- slow update (once every self.slowUpdateEvery)
        local element = self.ccList:getSelectedElement()
        if self.ccList:getItemCount() > 0 and element ~= nil then
            if element.signedContract ~= nil then
                ---@type SignedContract
                local signedContract = element.signedContract
                element.elements[3]:setText(string.format(g_i18n:getText("gui_cc_job_time_text"), math.ceil(signedContract.ttl / 60 / 60 / 1000))) -- ms to hours
            end
        end
    end
end

function CCGui:onListSelectionChanged()
    self:refreshButtons()
end

function CCGui:onClickCancel()
    if not self.locker:getIsLocked(self.currentSignedContractKey) then
        local element = self.ccList:getSelectedElement()
        if element ~= nil and element.signedContract ~= nil then
            g_gui:showYesNoDialog(
                {
                    text = g_i18n:getText("dialog_cc_cancel_confirm_text"),
                    title = g_i18n:getText("dialog_cc_cancel_confirm_title"),
                    callback = self.onClickCancelDialogCallback,
                    target = self
                }
            )
        end
    end
    CCGui:superClass().onClickCancel(self)
end

function CCGui:onClickCancelDialogCallback(yes)
    if yes then
        local element = self.ccList:getSelectedElement()
        if element ~= nil and element.signedContract ~= nil then
            ---@type SignedContract
            local sContract = element.signedContract
            g_contractsManager:requestContractCancel(sContract)
        end
    end
end

function CCGui:onClickActivate()
    if not self.locker:getIsLocked(self.currentSignedContractKey) then
        local element = self.ccList:getSelectedElement()
        if element ~= nil and element.contractProposal ~= nil then
            ---@type ContractProposal
            local cProposal = element.contractProposal
            g_gui:showYesNoDialog(
                {
                    text = g_i18n:getText("dialog_cc_signing_confirm_text"):format(g_i18n:formatMoney(cProposal.contract.callPrice), g_i18n:formatMoney(cProposal.contract.workPrice)),
                    title = g_i18n:getText("dialog_cc_signing_confirm_title"),
                    callback = self.onClickActivateDialogCallback,
                    target = self
                }
            )
        end
    end
    CCGui:superClass().onClickActivate(self)
end

function CCGui:onClickActivateDialogCallback(yes)
    if yes then
        local element = self.ccList:getSelectedElement()
        if element ~= nil and element.contractProposal ~= nil then
            ---@type ContractProposal
            local cProposal = element.contractProposal
            self.locker:addLock(self.currentContractProposalKey, self.currentSignedContractKey)
            self:refreshSigningOverlay()
            g_contractsManager:requestContractSign(cProposal)
        end
    end
end

function CCGui:onEscPressed()
    self:onClickBack()
end

---@param contractProposalKey string
function CCGui:onProposalExpired(contractProposalKey)
    if contractProposalKey == self.currentContractProposalKey then
        self:refreshList()
    end
end

---@param signedContract SignedContract
function CCGui:onContractSigned(signedContract)
    self.removeSigningContractDCB:call(250, signedContract.key)
end

---@param contractProposalKey string
---@param errorType number
function CCGui:onContractSignError(contractProposalKey, errorType)
    self.removeSigningContractDCB:call(750, contractProposalKey, errorType)
end

---@param key string
---@param errorType number
function CCGui:onRemoveSigningContractDCB(key, errorType)
    self.locker:removeLock(key)
    if key == self.currentContractProposalKey or key == self.currentSignedContractKey then
        self:refreshList()
    end

    if errorType == SignContractErrorEvent.ERROR_TYPES.PREREQUISITES_NO_LONGER_MET then
        g_gui:showInfoDialog({text = g_i18n:getText("dialog_cc_cannot_be_performed")})
    end

    if errorType == SignContractErrorEvent.ERROR_TYPES.ALREADY_ACTIVE then
        g_gui:showInfoDialog({text = g_i18n:getText("dialog_cc_already_active")})
    end
end

---@param signedContract SignedContract
---@param reason integer
function CCGui:onContractRemoved(signedContract, reason)
    if signedContract.key == self.currentSignedContractKey then
        self:refreshList()
    end
end

---@param signedContract SignedContract
function CCGui:onContractCancelled(signedContract)
    if signedContract.key == self.currentSignedContractKey then
        self:refreshList()
    end
end

---@param state integer
function CCGui:onFieldSelectionChange(state)
    self.selectedField = self.fieldsMapping[state]
    self:refreshList()
end

---@param state integer
function CCGui:onFruitSelectionChange(state)
    self.selectedFruit = self.fruitsMapping[state]
    self:refreshList()
end

---@param state integer
function CCGui:onJobTypeSelectionChange(state)
    self.selectedContractType = self.contractTypesMapping[state]
    self:onJobTypeSelectionChanged()
end

function CCGui:onJobTypeSelectionChanged()
    self.ccFieldSelector:setDisabled(not self.selectedContractType.requireFieldParam)
    if self.selectedContractType.requireFieldParam then
        self:updateFieldSelectorTexts(self.fields, self.selectedContractType.fieldsFilter)
    end

    self.ccFruitSelector:setDisabled(not self.selectedContractType.requireFruitParam)
    if self.selectedContractType.requireFruitParam then
        self:updateFruitSelectorTexts(self.fruits, self.selectedContractType.fruitsFilter)
    end

    self:refreshList()
end
