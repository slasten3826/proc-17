local flow_domain = require("runtime.flow_domain")
local tension_runner = require("runtime.tension_runner")

local function domain(label)
    return assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = label,
        source_ref = "test:" .. label,
    }))
end

local substrate = {
    ask = function()
        return {text = "inspect change verify"}
    end,
}

local inspected = false
local packet, result = assert(tension_runner.run("hook ordering", substrate, {
    work_mode = "plan",
    max_ticks = 1,
    packet_life = {
        protocol_version = "vertical_packet_life.v0",
        flow_domain = domain("hook-order"),
        projection_adapter = "vertical_single.v0",
    },
    on_packet_birth = function(instance, receipt)
        inspected = true
        assert(instance.status == "born")
        assert(instance.operator == "▽")
        assert(instance.runtime.budget ~= nil)
        assert(instance.tension.loss_max ~= nil)
        assert(#instance.trace == 1)
        assert(#instance.chaos.fragments == 0)
        assert(receipt.packet_id == instance.id)
        return true
    end,
}))
assert(inspected == true)
assert(result.stop_reason == "tick_limit")
assert(packet.status ~= "dead")

local mutated, mutated_err = tension_runner.run("hook mutation", substrate, {
    max_ticks = 1,
    packet_life = {
        protocol_version = "vertical_packet_life.v0",
        flow_domain = domain("hook-mutation"),
        projection_adapter = "vertical_single.v0",
    },
    on_packet_birth = function(instance)
        instance.metadata.illegal = true
        return true
    end,
})
assert(mutated == nil)
assert(mutated_err:match("birth_hook:birth hook mutated Packet"))

local exploded, exploded_err = tension_runner.run("hook explosion", substrate, {
    max_ticks = 1,
    packet_life = {
        protocol_version = "vertical_packet_life.v0",
        flow_domain = domain("hook-explosion"),
        projection_adapter = "vertical_single.v0",
    },
    on_packet_birth = function()
        error("broken lineage ledger")
    end,
})
assert(exploded == nil)
assert(exploded_err:match("birth_hook:"))
assert(exploded_err:match("broken lineage ledger"))

local horizontal, horizontal_err = tension_runner.run("horizontal hook", substrate, {
    max_ticks = 1,
    on_packet_birth = function()
        return true
    end,
})
assert(horizontal == nil)
assert(horizontal_err:match("requires vertical Packet life"))

print("test_lineage_birth_hook ok")
