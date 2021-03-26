--- ${title}

---@author ${author}
---@version r_version_r
---@date 25/03/2021

---@class ContractProposal
ContractProposal = {}
ContractProposal_mt = Class(ContractProposal)

--- encapsulation class for contract proposals
---@param key string
---@param contract Contract
---@param mt? table custom meta table
---@return ContractProposal
function ContractProposal.new(key, contract, mt)
    ---@type ContractProposal
    local self = setmetatable({}, mt or ContractProposal_mt)

    ---@type string
    self.key = key

    ---@type number
    self.ttl = math.random(18, 54) * 100000 -- between 30 minutes and 1.5 hours

    ---@type Contract
    self.contract = contract

    return self
end
