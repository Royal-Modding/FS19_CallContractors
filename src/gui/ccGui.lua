--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

---@class CCGui
---@field registerControls function
---@field superClass function
---@field listItemTemplate any
---@field ccList any
---@field fieldSelector any
---@field jobTypeSelector any
---@field fruitSelector any
CCGui = {}
CCGui.CONTROLS = {"listItemTemplate", "ccList", "fieldSelector", "jobTypeSelector", "fruitSelector"}

local CCGui_mt = Class(CCGui, ScreenElement)

---comment
---@param target any
---@return CCGui
function CCGui:new(target)
    ---@type CCGui
    local o = ScreenElement:new(target, CCGui_mt)
    o.returnScreenName = ""
    o.fields = {}
    o.fieldsMap = {}
    o.fruits = {}
    o.fruitsMap = {}
    ---@type JobType
    o.currentJobType = nil
    o:registerControls(CCGui.CONTROLS)
    return o
end

function CCGui:onCreate()
    self.jobTypeSelector:setTexts(
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

    self.listItemTemplate:unlinkElement()
    self.listItemTemplate:setVisible(false)
end

function CCGui:onOpen()
    -- preload texts to ensure that there's always something to show
    self:updateFieldSelectorTexts(
        self.fields,
        function()
            return true
        end
    )

    self:updateFruitsSelectorTexts(
        self.fruits,
        function()
            return true
        end
    )

    CCGui:superClass().onOpen(self)

    self:onJobTypeSelectionChanged()
end

function CCGui:refreshItems()
    --self.routes = ADRoutesManager:getRoutes(AutoDrive.loadedMap)
    --self.ccList:deleteListItems()
    --for _, r in pairs(self.routes) do
    --    local new = self.listItemTemplate:clone(self.ccList)
    --    new:setVisible(true)
    --    new.elements[1]:setText(r.name)
    --    new.elements[2]:setText(r.date)
    --    new:updateAbsolutePosition()
    --end
end

function CCGui:onListSelectionChanged(rowIndex)
end

function CCGui:onDoubleClick(rowIndex)
    --self.textInputElement:setText(self.routes[rowIndex].name)
end

function CCGui:onClickOk()
    CCGui:superClass().onClickOk(self)
    --local newName = self.textInputElement.text
    --if
    --    table.f_contains(
    --        self.routes,
    --        function(v)
    --            return v.name == newName
    --        end
    --    )
    -- then
    --    g_gui:showYesNoDialog({text = g_i18n:getText("gui_ad_routeExportWarn_text"), title = g_i18n:getText("gui_ad_routeExportWarn_title"), callback = self.onExportDialogCallback, target = self})
    --else
    --    self:onExportDialogCallback(true)
    --end
end

function CCGui:onExportDialogCallback(yes)
    if yes then
    --ADRoutesManager:export(self.textInputElement.text)
    --self:refreshItems()
    end
end

function CCGui:onClickCancel()
    --if #self.routes > 0 then
    --    ADRoutesManager:import(self.routes[self.ccList:getSelectedElementIndex()].name)
    --    self:onClickBack()
    --end
    CCGui:superClass().onClickCancel(self)
end

function CCGui:onClickBack()
    CCGui:superClass().onClickBack(self)
end

function CCGui:onClickActivate()
    --if #self.routes > 0 then
    --    g_gui:showYesNoDialog({text = g_i18n:getText("gui_ad_routeDeleteWarn_text"):format(self.routes[self.ccList:getSelectedElementIndex()].name), title = g_i18n:getText("gui_ad_routeDeleteWarn_title"), callback = self.onDeleteDialogCallback, target = self})
    --end
    CCGui:superClass().onClickActivate(self)
end

function CCGui:onDeleteDialogCallback(yes)
    if yes then
    --ADRoutesManager:remove(self.routes[self.ccList:getSelectedElementIndex()].name)
    --self:refreshItems()
    end
end

function CCGui:onEnterPressed(_, isClick)
    if not isClick then
    --self:onClickOk()
    end
end

function CCGui:onEscPressed()
    self:onClickBack()
end

---@param fields table
---@param filter function
function CCGui:updateFieldSelectorTexts(fields, filter)
    local texts = {}
    self.fieldsMap = {}
    for key, field in pairs(fields) do
        if filter(field) then
            table.insert(texts, field.fieldId)
            table.insert(self.fieldsMap, key)
        end
    end
    self.fieldSelector:setTexts(texts)
end

---@param fruits table
---@param filter function
function CCGui:updateFruitsSelectorTexts(fruits, filter)
    local texts = {}
    self.fruitsMap = {}
    for key, fruit in pairs(fruits) do
        if filter(fruit) then
            table.insert(texts, fruit.fillType.title)
            table.insert(self.fruitsMap, key)
        end
    end
    self.fruitSelector:setTexts(texts)
end

---@param state number
---@param element any
function CCGui:onJobTypeSelectionChange(state, element)
    self:onJobTypeSelectionChanged()
end

function CCGui:onJobTypeSelectionChanged()
    self.currentJobType = CallContractors.JOB_TYPES[self.jobTypeSelector:getState()]

    self.fieldSelector:setDisabled(not self.currentJobType.requireFieldParam)
    if self.currentJobType.requireFieldParam then
        self:updateFieldSelectorTexts(self.fields, self.currentJobType.contractClass.fieldsFilter)
    end

    self.fruitSelector:setDisabled(not self.currentJobType.requireFruitParam)
    if self.currentJobType.requireFruitParam then
        self:updateFruitsSelectorTexts(self.fruits, self.currentJobType.contractClass.fruitsFilter)
    end
end

---@param state number
---@param element any
function CCGui:onFieldSelectionChange(state, element)
    print("Field: " .. tostring(state))
end
