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