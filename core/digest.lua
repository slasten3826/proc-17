local json = require("core.json")

local digest = {}

local MASK = 0xffffffff

local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

local function rotr(value, amount)
    return ((value >> amount) | (value << (32 - amount))) & MASK
end

local function add(...)
    local value = 0
    for index = 1, select("#", ...) do
        value = (value + select(index, ...)) & MASK
    end
    return value
end

function digest.sha256(text)
    if type(text) ~= "string" then
        return nil, "sha256 input must be string"
    end

    local bit_length = #text * 8
    local pad_length = (56 - ((#text + 1) % 64)) % 64
    local message = text .. "\128" .. string.rep("\0", pad_length)
        .. string.pack(">I8", bit_length)

    local h0 = 0x6a09e667
    local h1 = 0xbb67ae85
    local h2 = 0x3c6ef372
    local h3 = 0xa54ff53a
    local h4 = 0x510e527f
    local h5 = 0x9b05688c
    local h6 = 0x1f83d9ab
    local h7 = 0x5be0cd19

    for chunk_start = 1, #message, 64 do
        local words = {}
        for index = 0, 15 do
            words[index] = string.unpack(">I4", message, chunk_start + index * 4)
        end
        for index = 16, 63 do
            local s0 = rotr(words[index - 15], 7)
                ~ rotr(words[index - 15], 18)
                ~ (words[index - 15] >> 3)
            local s1 = rotr(words[index - 2], 17)
                ~ rotr(words[index - 2], 19)
                ~ (words[index - 2] >> 10)
            words[index] = add(words[index - 16], s0, words[index - 7], s1)
        end

        local a, b, c, d = h0, h1, h2, h3
        local e, f, g, h = h4, h5, h6, h7

        for index = 0, 63 do
            local sum1 = rotr(e, 6) ~ rotr(e, 11) ~ rotr(e, 25)
            local choose = (e & f) ~ ((~e) & g)
            local temp1 = add(h, sum1, choose, K[index + 1], words[index])
            local sum0 = rotr(a, 2) ~ rotr(a, 13) ~ rotr(a, 22)
            local majority = (a & b) ~ (a & c) ~ (b & c)
            local temp2 = add(sum0, majority)

            h = g
            g = f
            f = e
            e = add(d, temp1)
            d = c
            c = b
            b = a
            a = add(temp1, temp2)
        end

        h0 = add(h0, a)
        h1 = add(h1, b)
        h2 = add(h2, c)
        h3 = add(h3, d)
        h4 = add(h4, e)
        h5 = add(h5, f)
        h6 = add(h6, g)
        h7 = add(h7, h)
    end

    return string.format(
        "%08x%08x%08x%08x%08x%08x%08x%08x",
        h0, h1, h2, h3, h4, h5, h6, h7
    )
end

function digest.record(value)
    local encoded_ok, encoded = pcall(json.encode, value)
    if not encoded_ok then
        return nil, "record encoding failed: " .. tostring(encoded)
    end
    return digest.sha256(encoded)
end

return digest
