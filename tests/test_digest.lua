local digest = require("core.digest")

assert(digest.sha256("") == "e3b0c44298fc1c149afbf4c8996fb924"
    .. "27ae41e4649b934ca495991b7852b855")
assert(digest.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223"
    .. "b00361a396177a9cb410ff61f20015ad")
assert(digest.sha256(string.rep("a", 1000000))
    == "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")

local first = assert(digest.record({b = 2, a = 1, nested = {z = 3, y = 4}}))
local second = assert(digest.record({nested = {y = 4, z = 3}, a = 1, b = 2}))
assert(first == second)
assert(digest.record({1, 2, 3}) ~= digest.record({3, 2, 1}))

local missing, missing_err = digest.sha256({})
assert(missing == nil)
assert(missing_err:match("must be string"))

local cyclic = {}
cyclic.self = cyclic
local rejected, rejected_err = digest.record(cyclic)
assert(rejected == nil)
assert(rejected_err:match("record encoding failed"))

print("test_digest ok")
