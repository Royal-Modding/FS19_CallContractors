--- ${title}

---@author ${author}
---@version r_version_r
---@date 25/03/2021

---@class SignedContract : Class
SignedContract = {}
SignedContract_mt = Class(SignedContract)

--- encapsulation class for signed contracts
---@param key string
---@param contract Contract
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
    self.ttl = contract.waitTime * 60 * 60 * 1000 -- hours to ms

    return self
end
