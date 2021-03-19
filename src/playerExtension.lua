---${title}

---@author ${author}
---@version r_version_r
---@date 18/03/2021

PlayerExtension = {}

function PlayerExtension:new(superFunc, isServer, isClient)
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
    CallContractors:openGui();
end
