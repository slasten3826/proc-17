local digest = require("core.digest")

local SOURCE = "third_party/lua-5.4.8/lua-5.4.8.tar.gz"
local ARCHIVE = "native/build/deps/lua-5.4.8/src/liblua.a"
local EXPECTED_SIZE = 374332
local EXPECTED_SHA256 = "4f18ddae154e793e46eeab727c59ef1c0c0c2b744e7b94219710d76f530629ae"

local function read_file(path)
    local handle = assert(io.open(path, "rb"))
    local content = assert(handle:read("*a"))
    assert(handle:close())
    return content
end

local source = read_file(SOURCE)
assert(#source == EXPECTED_SIZE)
assert(digest.sha256(source) == EXPECTED_SHA256)

assert(os.execute("make -C native qa-lua-static") == true)
assert(os.execute("make -C native qa-lua-static-verify") == true)

local archive = read_file(ARCHIVE)
assert(#archive > 0)
assert(not ARCHIVE:match("^/usr/"))

print("test_qa_pinned_lua_static ok")
