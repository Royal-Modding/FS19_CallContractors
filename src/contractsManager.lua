--- ${title}

---@author ${author}
---@version r_version_r
---@date 22/03/2021

---@class ContractsManager
ContractsManager = {}
---@type JobType[]
ContractsManager.JOB_TYPES = {}

---@param jobTypes JobType[]
---@return ContractsManager
function ContractsManager:load(jobTypes)
    self.JOB_TYPES = jobTypes
    self.generatedContracts = {}
    self.maxContractsMin = 3
    self.maxContractsMax = 7
    return self
end

---@param jobType JobType
---@param field any
---@param fruit any
---@return Contract[] contracts
function ContractsManager:getContracts(jobType, field, fruit)
    local memoryKey = self:getMemoryKey(jobType, field, fruit)
    if self.generatedContracts[memoryKey] == nil then
        self.generatedContracts[memoryKey] = {}
        self.generatedContracts[memoryKey].settings = {}
        self.generatedContracts[memoryKey].settings.maxContracts = math.random(self.maxContractsMin, self.maxContractsMax)
        self.generatedContracts[memoryKey].contracts = {}
    end
    if jobType.contractClass.canBePerformed(field, fruit) then
        if #self.generatedContracts[memoryKey].contracts < self.generatedContracts[memoryKey].settings.maxContracts then
            self:generateNewContracts(memoryKey, jobType, field, fruit)
        end
        return self.generatedContracts[memoryKey].contracts
    else
        return {}
    end
end

---@param memoryKey string
---@param jobType JobType
---@param field any
---@param fruit any
function ContractsManager:generateNewContracts(memoryKey, jobType, field, fruit)
    self.generatedContracts[memoryKey].settings.maxContracts = math.random(self.maxContractsMin, self.maxContractsMax)
    while #self.generatedContracts[memoryKey].contracts < self.generatedContracts[memoryKey].settings.maxContracts do
        table.insert(self.generatedContracts[memoryKey].contracts, self:generateNewContract(jobType, field, fruit))
    end
end

---@param jobType JobType
---@param field any
---@param fruit any
---@return Contract contract
function ContractsManager:generateNewContract(jobType, field, fruit)
    local contract = jobType.contractClass.new()
    contract:randomizeData(field, fruit)
    return contract
end

---@param jobType JobType
---@param field any
---@param fruit any
---@return string memoryKey
function ContractsManager:getMemoryKey(jobType, field, fruit)
    local memoryKey = jobType.name
    if jobType.requireFieldParam then
        memoryKey = string.format("%s_%d", memoryKey, field.fieldId)
    end
    if jobType.requireFruitParam then
        memoryKey = string.format("%s_%s", memoryKey, fruit.name)
    end
    return memoryKey
end
