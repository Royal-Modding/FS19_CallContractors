--- ${title}

---@author ${author}
---@version r_version_r
---@date 25/03/2021

---@class ContractType : Class
ContractType = {}
ContractType_mt = Class(ContractType)

--- ContractType base class
---@param id number
---@param contractClass Contract
---@param name string
---@param title string
---@param mt? table custom meta table
---@return ContractType
function ContractType.new(id, contractClass, name, title, mt)
    ---@type ContractType
    local self = setmetatable({}, mt or ContractType_mt)
    self.id = id
    ---@type Contract
    self.contractClass = contractClass
    self.name = name
    self.title = title
    self.requireFieldParam = true
    self.requireFruitParam = false
    return self
end

---@return Contract
function ContractType:getContractInstance()
    return self.contractClass.new(self)
end

---@param farmId integer
---@return boolean
function ContractType.checkPrerequisites(farmId)
    -- needs at least one field
    return TableUtility.f_count(
        g_fieldManager:getFields(),
        function(f)
            return g_farmlandManager:getFarmlandOwner(f.farmland.id) == farmId
        end
    ) > 0
end

---@param farmId integer
---@param field Field
---@return boolean
function ContractType.fieldsFilter(farmId, field)
    -- only owned fields
    return g_farmlandManager:getFarmlandOwner(field.farmland.id) == farmId
end

---@param farmId integer
---@param fruit FruitTypeEntry
---@return boolean
function ContractType.fruitsFilter(farmId, fruit)
    return true
end

---@param farmId integer
---@param fieldId integer
---@param fruitId integer
---@return string
function ContractType:getContractProposalKey(farmId, fieldId, fruitId)
    local contractProposalKey = string.format("%s_%d", self.name, farmId)
    if self.requireFieldParam then
        contractProposalKey = string.format("%s_%d", contractProposalKey, fieldId)
    end
    if self.requireFruitParam then
        contractProposalKey = string.format("%s_%d", contractProposalKey, fruitId)
    end
    return contractProposalKey
end

---@param farmId integer
---@param fieldId integer
---@param fruitId integer
---@return string
function ContractType:getSignedContractKey(farmId, fieldId, fruitId)
    -- signed contract keys doesn't need to take into account the fruitId and contract type cause only one contract per field is allowed, regardless of fruit and contract type
    return string.format("%d_%d", farmId, fieldId)
end

---@param contract Contract
---@return string
function ContractType:getSignedContractKeyByContract(contract)
    return self:getSignedContractKey(contract.farmId, contract.fieldId, contract.fruitId)
end
