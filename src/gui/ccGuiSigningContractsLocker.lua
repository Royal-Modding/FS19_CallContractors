--- ${title}

---@author ${author}
---@version r_version_r
---@date 26/03/2021

---@class CCGuiSigningContractsLocker
CCGuiSigningContractsLocker = {}

---@return CCGuiSigningContractsLocker
function CCGuiSigningContractsLocker:new()
    self.locks = {}
    return self
end

---@param contractProposalKey string
---@param signedContractKey string
function CCGuiSigningContractsLocker:addLock(contractProposalKey, signedContractKey)
    ---@type StringTuple
    local lockKey = {value1 = contractProposalKey, value2 = signedContractKey}
    self.locks[lockKey] = true
end

---@param key string
function CCGuiSigningContractsLocker:removeLock(key)
    ---@type StringTuple
    for lockKey, _ in pairs(self.locks) do
        if lockKey.value1 == key or lockKey.value2 == key then
            self.locks[lockKey] = nil
        end
    end
end

---@param key any
function CCGuiSigningContractsLocker:getIsLocked(key)
    ---@type StringTuple
    for lockKey, _ in pairs(self.locks) do
        if lockKey.value1 == key or lockKey.value2 == key then
            return true
        end
    end
    return false
end

function CCGuiSigningContractsLocker:clear()
    self.locks = {}
end
