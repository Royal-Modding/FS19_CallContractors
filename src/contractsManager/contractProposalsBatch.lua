--- ${title}

---@author ${author}
---@version r_version_r
---@date 25/03/2021

---@class ContractProposalsBatch
ContractProposalsBatch = {}
local ContractProposalsBatch_mt = Class(ContractProposalsBatch)

---@param contractProposalKey string
---@param mt? table custom meta table
---@return ContractProposalsBatch
function ContractProposalsBatch.new(contractProposalKey, mt)
    ---@type ContractProposalsBatch
    local self = setmetatable({}, mt or ContractProposalsBatch_mt)

    self.contractProposalKey = contractProposalKey

    self.maxContractProposals = 0

    self:randomizeMaxContractProposals()

    ---@type ContractProposal[]
    self.contractProposals = {}
    return self
end

---@return integer
function ContractProposalsBatch:getMaxContractProposals()
    return self.maxContractProposals
end

function ContractProposalsBatch:randomizeMaxContractProposals()
    self.maxContractProposals = math.random(3, 7)
end

---@return ContractProposal[]
function ContractProposalsBatch:getContractProposals()
    return self.contractProposals
end

---@return boolean
function ContractProposalsBatch:isMissingContractProposals()
    return #self.contractProposals < self.maxContractProposals
end

---@param contractProposal ContractProposal
function ContractProposalsBatch:addContractProposal(contractProposal)
    table.insert(self.contractProposals, contractProposal)
end

---@param contractProposal ContractProposal
function ContractProposalsBatch:removeContractProposal(contractProposal)
    ArrayUtility.remove(
        self.contractProposals,
        function(array, index, _)
            return array[index] == contractProposal
        end
    )
end
