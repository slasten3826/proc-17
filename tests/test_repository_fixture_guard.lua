package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local owned = require("tests.support.owned_temp_root")
local suite = H.new("repository-fixture-guard")

suite:check("TH-T01/TH-T02 native fixture guard self-test", function()
    assert(owned.self_test())
end)

suite:check("TH-T01 unique roots carry distinct filesystem identities", function()
    owned.with_root(function(first)
        owned.with_root(function(second)
            H.assert_false(first.path == second.path, "fixture names must be unique")
            H.assert_false(first.device == second.device and first.inode == second.inode,
                "fixture identities must be unique")
        end)
    end)
end)

suite:check("TH-T02 wrong identity cannot clean a live fixture", function()
    owned.with_root(function(root)
        local wrong_inode = root.inode == "0" and "1" or "0"
        local cleaned = owned.cleanup_as(root, root.device, wrong_inode, root.mount_id)
        H.assert_nil(cleaned, "wrong inode must not authorize cleanup")
        assert(owned.probe(root))
    end)
end)

suite:check("TH-T02 wrong mount identity cannot clean a live fixture", function()
    owned.with_root(function(root)
        local wrong_mount = root.mount_id == "0" and "1" or "0"
        local cleaned = owned.cleanup_as(root,
            root.device, root.inode, wrong_mount)
        H.assert_nil(cleaned, "wrong mount id must not authorize cleanup")
        assert(owned.probe(root))
    end)
end)

suite:check("TH-T04 fixture paths cannot widen outside their root", function()
    owned.with_root(function(root)
        H.assert_nil(owned.assert_owned_path(root, "/tmp/not-owned"),
            "outside path rejected")
        H.assert_eq(owned.assert_owned_path(root, root.repository .. "/src/main.lua"),
            root.repository .. "/src/main.lua", "inside path accepted")
    end)
end)

suite:finish()
print("test_repository_fixture_guard ok")
