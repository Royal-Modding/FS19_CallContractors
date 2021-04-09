--- ${title}

---@author ${author}
---@version r_version_r
---@date 25/03/2021

---@class SignedContract : Class
SignedContract = {}
local SignedContract_mt = Class(SignedContract)

--- encapsulation class for signed contracts
---@param key? string
---@param contract? Contract
---@param mt? table custom meta table
---@return SignedContract
function SignedContract.new(key, contract, mt)
    ---@type SignedContract
    local self = setmetatable({}, mt or SignedContract_mt)

    ---@type string
    self.key = key

    ---@type Contract
    self.contract = contract

    ---@type integer
    self.id = 0

    ---@type number
    self.ttl = contract and MathUtil.hoursToMs(contract.waitTime) or 0

    return self
end

function SignedContract:saveToXMLFile(xmlFile, key)
    setXMLInt(xmlFile, key .. "#ttl", self.ttl)
    setXMLInt(xmlFile, key .. "#type", self.contract.type.id)
    setXMLString(xmlFile, key .. "#key", self.key)
    self.contract:saveToXMLFile(xmlFile, key .. ".contract")
end

function SignedContract:loadFromXMLFile(xmlFile, key)
    self.ttl = getXMLInt(xmlFile, key .. "#ttl")
    self.key = getXMLString(xmlFile, key .. "#key")
    self.contract = g_callContractors.CONTRACT_TYPES[getXMLInt(xmlFile, key .. "#type")]:getContractInstance()
    self.contract:loadFromXMLFile(xmlFile, key .. ".contract")
end
