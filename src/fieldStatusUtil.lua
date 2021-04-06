--- ${title}

---@author ${author}
---@version r_version_r
---@date 03/04/2021

FieldStatusUtil = {}

---@param field Field
---@return number
function FieldStatusUtil.getSowableIndex(field)
    local modifiers = g_currentMission.densityMapModifiers.updateSowingArea
    local modifier = modifiers.modifier
    local filter2 = modifiers.filter2
    filter2:setValueCompareParams("between", g_currentMission.firstSowableValue, g_currentMission.lastSowableValue)

    local totalArea = 0
    local sowableArea = 0
    for _, partition in ipairs(field.maxFieldStatusPartitions) do
        modifier:setParallelogramWorldCoords(partition.x0, partition.z0, partition.widthX, partition.widthZ, partition.heightX, partition.heightZ, "pvv")
        local _, pixelArea, totalPixelArea = modifier:executeGet(filter2)
        sowableArea = sowableArea + pixelArea
        totalArea = totalArea + totalPixelArea
    end
    return sowableArea / totalArea
end

---@param field Field
---@return number
function FieldStatusUtil.getLimeableIndex(field)
    local modifiers = g_currentMission.densityMapModifiers.updateLimeArea
    local modifier = modifiers.modifier
    local filter1 = modifiers.filter1
    local filter2 = modifiers.filter2

    local detailId = g_currentMission.terrainDetailId
    local terrainDetailTypeFirstChannel = g_currentMission.terrainDetailTypeFirstChannel
    local terrainDetailTypeNumChannels = g_currentMission.terrainDetailTypeNumChannels

    filter2:setValueCompareParams("between", 0, g_currentMission.limeCounterMaxValue - 1)

    local totalArea = 0
    local limeableArea = 0

    for _, partition in ipairs(field.maxFieldStatusPartitions) do
        modifier:setParallelogramWorldCoords(partition.x0, partition.z0, partition.widthX, partition.widthZ, partition.heightX, partition.heightZ, "pvv")
        modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
        for index, entry in pairs(g_currentMission.fruits) do
            local desc = g_fruitTypeManager:getFruitTypeByIndex(index)
            if desc.weed == nil then
                filter1:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
                filter1:setValueCompareParams("between", 1, desc.minHarvestingGrowthState)
                local _, pixelArea, _ = modifier:executeGet(filter1, filter2)
                limeableArea = limeableArea + pixelArea

                filter1:setValueCompareParams("equal", desc.cutState + 1)
                _, pixelArea, _ = modifier:executeGet(filter1, filter2)
                limeableArea = limeableArea + pixelArea
            end
        end
        filter1:resetDensityMapAndChannels(detailId, terrainDetailTypeFirstChannel, terrainDetailTypeNumChannels)
        filter1:setValueCompareParams("between", g_currentMission.cultivatorValue, g_currentMission.plowValue)
        local _, pixelArea, totalPixelArea = modifier:executeGet(filter1, filter2)
        totalArea = totalArea + totalPixelArea
        limeableArea = limeableArea + pixelArea
    end
    return limeableArea / totalArea
end
