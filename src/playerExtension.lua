---${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

PlayerExtension = {}

---@param self Player
---@param superFunc function
---@param isServer boolean
---@param isClient boolean
---@return Player
function PlayerExtension.new(self, superFunc, isServer, isClient)
    self = superFunc(nil, isServer, isClient)
    self.inputInformation.registrationList[InputAction.CALL_CONTRACTORS_SHOW] = {
        eventId = "",
        callback = self.showCallContractorsActionEvent,
        triggerUp = false,
        triggerDown = true,
        triggerAlways = false,
        activeType = Player.INPUT_ACTIVE_TYPE.STARTS_ENABLED,
        callbackState = nil,
        text = "",
        textVisibility = false
    }
    return self
end

function PlayerExtension:showCallContractorsActionEvent()
    g_callContractors:openGui()
end
