--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class CCGui
---@field onClickBack function
---@field registerControls function
---@field superClass function
---@field ccProposalItemTemplate any
---@field ccContractItemTemplate any
---@field ccList any
---@field ccFieldSelector any
---@field ccJobTypeSelector any
---@field ccFruitSelector any
---@field ccNoContractsBox any
---@field ccActivateButton any
---@field ccCancelButton any
---@field ccContractSigningImageBg any
CCGui = {}
CCGui.CONTROLS = {"ccProposalItemTemplate", "ccContractItemTemplate", "ccList", "ccFieldSelector", "ccJobTypeSelector", "ccFruitSelector", "ccNoContractsBox", "ccActivateButton", "ccCancelButton", "ccContractSigningImageBg"}

local CCGui_mt = Class(CCGui, ScreenElement)

---@param target any
---@return CCGui
function CCGui:new(target)
    ---@type CCGui
    local o = ScreenElement:new(target, CCGui_mt)
    o.returnScreenName = ""

    o.fields = {}
    o.fieldsMapping = {}
    o.selectedField = nil

    o.fruits = {}
    o.fruitsMapping = {}
    o.selectedFruit = nil

    ---@type JobType
    o.selectedJobType = nil

    o.currentTffKey = "nil"

    o.signingContractTffKeys = {}

    ---@type DelayedCallBack
    o.removeSigningContractDCB = DelayedCallBack:new(CCGui.onRemoveSigningContractDCB, o)

    o:registerControls(CCGui.CONTROLS)

    return o
end

function CCGui:onCreate()
    self.ccJobTypeSelector:setTexts(
        TableUtility.map(
            CallContractors.JOB_TYPES,
            ---@param ct JobType
            ---@return string
            function(ct)
                return ct.title
            end
        )
    )

    self.fields = g_fieldManager:getFields()
    self.fruits = g_fruitTypeManager:getFruitTypes()

    self.ccProposalItemTemplate:unlinkElement()
    self.ccProposalItemTemplate:setVisible(false)

    self.ccContractItemTemplate:unlinkElement()
    self.ccContractItemTemplate:setVisible(false)

    self.ccContractSigningImageBg.elements[1]:setImageFilename(Utils.getFilename("img/cs_icon.dds", CallContractors.guiDirectory))
end

function CCGui:onOpen()
    self.signingContractTffKeys = {}

    CallContractors.contractsManager:addEventListener(ContractsManager.EVENT_TYPES.PROPOSAL_EXPIRED, self, "onProposalExpired")
    CallContractors.contractsManager:addEventListener(ContractsManager.EVENT_TYPES.CONTRACT_SIGNED, self, "onContractSigned")
    CallContractors.contractsManager:addEventListener(ContractsManager.EVENT_TYPES.CONTRACT_SIGN_ERROR, self, "onContractSignError")
    CallContractors.contractsManager:addEventListener(ContractsManager.EVENT_TYPES.CONTRACT_CANCELLED, self, "onContractRemoved")

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
    CallContractors.contractsManager:removeEventListeners(self)
    CCGui:superClass().onClose(self)
end

function CCGui:refreshList()
    self.currentTffKey = CallContractors.contractsManager:getTffKey(self.selectedJobType, self.selectedField, self.selectedFruit)
    ---@type Contract
    local runningContract = CallContractors.contractsManager:getRunningContractByTffKey(self.currentTffKey)
    if runningContract ~= nil then
        self.ccList:deleteListItems()
        local new = self.ccContractItemTemplate:clone(self.ccList)
        new:setVisible(true)
        new.elements[1].elements[1]:setImageFilename(runningContract.npc.imageFilename)
        new.elements[2]:setText(runningContract.npc.title)
        new.elements[3]:setText(string.format(g_i18n:getText("gui_cc_job_time_text"), math.ceil(runningContract.runTimer / 60 / 60 / 1000))) -- ms to hours
        new.elements[4]:setText(g_i18n:formatMoney(runningContract.workPrice))
        new:updateAbsolutePosition()
        new.contract = runningContract
    else
        ---@type Contract[]
        local contractProposals = CallContractors.contractsManager:getContractProposals(self.selectedJobType, self.selectedField, self.selectedFruit)
        table.sort(
            contractProposals,
            ---@param a Contract
            ---@param b Contract
            ---@return bool
            function(a, b)
                return a.waitTime < b.waitTime
            end
        )
        self.ccNoContractsBox:setVisible(#contractProposals <= 0)
        self.ccList:deleteListItems()
        ---@type Contract
        for _, c in pairs(contractProposals) do
            local new = self.ccProposalItemTemplate:clone(self.ccList)
            new:setVisible(true)
            new.elements[1].elements[1]:setImageFilename(c.npc.imageFilename)
            new.elements[2]:setText(c.npc.title)
            new.elements[3]:setText(string.format(g_i18n:getText("gui_cc_job_time_text"), c.waitTime))
            new.elements[4]:setText(g_i18n:formatMoney(c.callPrice))
            new.elements[5]:setText(g_i18n:formatMoney(c.workPrice))
            new.elements[6]:setText(g_i18n:formatMoney(c.callPrice + c.workPrice))
            new:updateAbsolutePosition()
            new.contract = c
        end
    end
    self:refreshButtons()
    self:refreshSigningOverlay()
end

function CCGui:refreshButtons()
    local activate = false
    local cancel = false
    local element = self.ccList:getSelectedElement()
    if self.ccList:getItemCount() > 0 and element ~= nil then
        if element.contract.signed then
            cancel = true
        else
            activate = true
        end
    end
    self.ccActivateButton:setVisible(activate)
    self.ccActivateButton:setDisabled(not activate)
    self.ccCancelButton:setVisible(cancel)
    self.ccCancelButton:setDisabled(not cancel)
end

function CCGui:refreshSigningOverlay()
    self.ccContractSigningImageBg:setVisible(self.signingContractTffKeys[self.currentTffKey])
    self.ccList:setVisible(not self.signingContractTffKeys[self.currentTffKey])
end

---@param fields table
---@param filter function
function CCGui:updateFieldSelectorTexts(fields, filter)
    local texts = {}
    self.fieldsMapping = {}
    for _, field in pairs(fields) do
        if filter(field) then
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
        if filter(fruit) then
            table.insert(texts, fruit.fillType.title)
            table.insert(self.fruitsMapping, fruit)
        end
    end
    self.ccFruitSelector:setTexts(texts)
    self.selectedFruit = self.fruitsMapping[self.ccFruitSelector:getState()]
end

function CCGui:update(dt)
    CCGui:superClass().update(self, dt)
    self.removeSigningContractDCB:update(dt)
end

function CCGui:onListSelectionChanged(rowIndex)
    self:refreshButtons()
end

function CCGui:onClickCancel()
    if not self.signingContractTffKeys[self.currentTffKey] then
        local element = self.ccList:getSelectedElement()
        if element ~= nil and element.contract.signed then
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
        if element ~= nil and element.contract.signed then
            ---@type Contract
            local contract = element.contract
            CallContractors.contractsManager:requestContractCancel(contract)
        end
    end
end

function CCGui:onClickActivate()
    if not self.signingContractTffKeys[self.currentTffKey] then
        local element = self.ccList:getSelectedElement()
        if element ~= nil and not element.contract.signed then
            ---@type Contract
            local contract = element.contract
            g_gui:showYesNoDialog(
                {
                    text = g_i18n:getText("dialog_cc_signing_confirm_text"):format(g_i18n:formatMoney(contract.callPrice), g_i18n:formatMoney(contract.workPrice)),
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
        if element ~= nil and not element.contract.signed then
            ---@type Contract
            local contract = element.contract
            self.signingContractTffKeys[contract.tffKey] = true
            self:refreshSigningOverlay()
            CallContractors.contractsManager:requestContractSign(contract)
        end
    end
end

function CCGui:onEscPressed()
    self:onClickBack()
end

---@param tffKey string
function CCGui:onProposalExpired(tffKey)
    if tffKey == self.currentTffKey then
        self:refreshList()
    end
end

---@param contract Contract
function CCGui:onContractRemoved(contract)
    if contract.tffKey == self.currentTffKey then
        self:refreshList()
    end
end

---@param contract Contract
function CCGui:onContractSigned(contract)
    self.removeSigningContractDCB:call(500, contract.tffKey)
end

---@param tffKey string
---@param errorType number
function CCGui:onContractSignError(tffKey, errorType)
    self.removeSigningContractDCB:call(1000, tffKey, errorType)
end

---@param tffKey string
---@param errorType number
function CCGui:onRemoveSigningContractDCB(tffKey, errorType)
    self.signingContractTffKeys[tffKey] = nil
    if tffKey == self.currentTffKey then
        self:refreshList()
    end

    if errorType == SignContractErrorEvent.ERROR_TYPES.CANNOT_BE_PERFORMED then
        g_gui:showInfoDialog({text = g_i18n:getText("dialog_cc_cannot_be_performed")})
    end

    if errorType == SignContractErrorEvent.ERROR_TYPES.ALREADY_ACTIVE then
        g_gui:showInfoDialog({text = g_i18n:getText("dialog_cc_already_active")})
    end
end

---@param state number
---@param element any
function CCGui:onJobTypeSelectionChange(state, element)
    self:onJobTypeSelectionChanged()
end

function CCGui:onJobTypeSelectionChanged()
    self.selectedJobType = CallContractors.JOB_TYPES[self.ccJobTypeSelector:getState()]

    self.ccFieldSelector:setDisabled(not self.selectedJobType.requireFieldParam)
    if self.selectedJobType.requireFieldParam then
        self:updateFieldSelectorTexts(self.fields, self.selectedJobType.contractClass.fieldsFilter)
    end

    self.ccFruitSelector:setDisabled(not self.selectedJobType.requireFruitParam)
    if self.selectedJobType.requireFruitParam then
        self:updateFruitSelectorTexts(self.fruits, self.selectedJobType.contractClass.fruitsFilter)
    end

    self:refreshList()
end

---@param state number
---@param element any
function CCGui:onFieldSelectionChange(state, element)
    self.selectedField = self.fieldsMapping[state]
    self:refreshList()
end

---@param state number
---@param element any
function CCGui:onFruitSelectionChange(state, element)
    self.selectedFruit = self.fruitsMapping[state]
    self:refreshList()
end
