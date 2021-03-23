--- ${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

InitRoyalMod(Utils.getFilename("rmod/", g_currentModDirectory))
InitRoyalUtility(Utils.getFilename("utility/", g_currentModDirectory))

---@class CallContractors : RoyalMod
CallContractors = RoyalMod.new(r_debug_r, false)

function CallContractors:initialize()
    self.guiDirectory = Utils.getFilename("gui/", self.directory)

    Utility.overwrittenFunction(Player, "new", PlayerExtension.new)
    if Player.showCallContractorsActionEvent == nil then
        Player.showCallContractorsActionEvent = PlayerExtension.showCallContractorsActionEvent
    end

    source(Utils.getFilename("contracts/contract.lua", self.directory))
    source(Utils.getFilename("contracts/cultivatingContract.lua", self.directory))
    source(Utils.getFilename("contracts/plowingContract.lua", self.directory))
    source(Utils.getFilename("contracts/sowingContract.lua", self.directory))
    source(Utils.getFilename("contracts/sellingGoodsContract.lua", self.directory))

    ---@type JobType[]
    self.JOB_TYPES = {}
    self.JOB_TYPES[1] = {id = 1, contractClass = CultivatingContract, name = "cultivating", title = g_i18n:getText("cc_job_type_cultivating"), requireFieldParam = true, requireFruitParam = false}
    self.JOB_TYPES[2] = {id = 2, contractClass = PlowingContract, name = "plowing", title = g_i18n:getText("cc_job_type_plowing"), requireFieldParam = true, requireFruitParam = false}
    self.JOB_TYPES[3] = {id = 3, contractClass = SowingContract, name = "sowing", title = g_i18n:getText("cc_job_type_sowing"), requireFieldParam = true, requireFruitParam = true}
    self.JOB_TYPES[4] = {id = 4, contractClass = SellingGoodsContract, name = "sellingGoods", title = g_i18n:getText("cc_job_type_selling_goods"), requireFieldParam = false, requireFruitParam = true}

    self.contractsManager = ContractsManager:load(self.JOB_TYPES)

    g_gui:loadProfiles(self.guiDirectory .. "guiProfiles.xml")

    self.gui = g_gui:loadGui(self.guiDirectory .. "ccGui.xml", "CallContractorsGui", CCGui:new())
end

function CallContractors:onMissionInitialize(baseDirectory, missionCollaborators)
end

function CallContractors:onSetMissionInfo(missionInfo, missionDynamicInfo)
end

function CallContractors:onLoad()
end

function CallContractors:onPreLoadMap(mapFile)
end

function CallContractors:onCreateStartPoint(startPointNode)
end

function CallContractors:onLoadMap(mapNode, mapFile)
end

function CallContractors:onPostLoadMap(mapNode, mapFile)
end

function CallContractors:onLoadSavegame(savegameDirectory, savegameIndex)
end

function CallContractors:onPreLoadVehicles(xmlFile, resetVehicles)
end

function CallContractors:onPreLoadItems(xmlFile)
end

function CallContractors:onPreLoadOnCreateLoadedObjects(xmlFile)
end

function CallContractors:onLoadFinished()
end

function CallContractors:onStartMission()
end

function CallContractors:onMissionStarted()
end

function CallContractors:onWriteStream(streamId)
end

function CallContractors:onReadStream(streamId)
end

function CallContractors:onUpdate(dt)
    self.contractsManager:update(dt)
end

function CallContractors:onUpdateTick(dt)
end

function CallContractors:onWriteUpdateStream(streamId, connection, dirtyMask)
end

function CallContractors:onReadUpdateStream(streamId, timestamp, connection)
end

function CallContractors:onMouseEvent(posX, posY, isDown, isUp, button)
end

function CallContractors:onKeyEvent(unicode, sym, modifier, isDown)
end

function CallContractors:onDraw()
end

function CallContractors:onPreSaveSavegame(savegameDirectory, savegameIndex)
end

function CallContractors:onPostSaveSavegame(savegameDirectory, savegameIndex)
end

function CallContractors:onPreDeleteMap()
end

function CallContractors:onDeleteMap()
end

function CallContractors:onLoadHelpLine()
    --return self.directory .. "gui/helpLine.xml"
end

function CallContractors:openGui()
    if not self.gui.target:getIsOpen() then
        g_gui:showGui(self.gui.name)
    end
end
