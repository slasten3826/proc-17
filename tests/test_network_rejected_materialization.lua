package.path = "./?.lua;./?/init.lua;" .. package.path

local flow_domain = require("runtime.flow_domain")
local json = require("core.json")
local network_ingress = require("runtime.network_ingress")
local packet_birth = require("runtime.packet_birth")
local fixture = require("tests.support.qa_hand")

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then return true end
    end
    return false
end

local forbidden_authority_keys = {
    repository_id = true,
    repository_path = true,
    root_authority_id = true,
    root_fingerprint = true,
    grant_id = true,
    handle = true,
    provider = true,
    provider_id = true,
}

local function find_forbidden(value, seen)
    if type(value) ~= "table" then return nil end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    for key, child in pairs(value) do
        if forbidden_authority_keys[key] then return key end
        local nested = find_forbidden(child, seen)
        if nested then return nested end
    end
    return nil
end

local observed = assert(fixture.grow_qa_descendant())
local projection = observed.network_projection
local ingress = observed.ingress
local packet = observed.descendant

assert_eq(ingress.protocol_version, "network.ingress.v1")
assert_eq(ingress.prompt, json.encode(projection.current_work))
assert(ingress.carrier == nil, "selected NETWORK ingress must not expose full carrier")
assert(ingress.packet_options.repository_id == nil,
    "NETWORK must not transport repository identity")
assert(find_forbidden(ingress.network_projection) == nil,
    "NETWORK projection leaked repository authority")

assert_eq(packet.chaos.raw_prompt, ingress.prompt)
assert_eq(packet.ingress.network_projection.projection_id, projection.projection_id)
assert_eq(packet.repository_id, observed.fresh_repository_id)
assert(packet.repository_id ~= observed.ancestor_repository_id,
    "rejected ancestor repository identity was reused")
assert(observed.fresh_root_identity.device ~= observed.ancestor_root_identity.device
    or observed.fresh_root_identity.inode ~= observed.ancestor_root_identity.inode,
    "rejected ancestor physical root was reused")

local birth = assert(packet.trace[1])
assert_eq(birth.type, "birth")
assert_eq(birth.payload.network_projection_id, projection.projection_id)
assert(birth.payload.network_projection == nil,
    "birth trace must name projection id, not copy projection payload")

assert_eq(#observed.flow.unit_ids, 2)
assert_eq(#packet.field.unit_order, 2)
local current = assert(packet.field.units[observed.flow.unit_ids[1]])
local rejected = assert(packet.field.units[observed.flow.unit_ids[2]])
assert_eq(current.kind, "network_current_work")
assert_eq(rejected.kind, "inherited_rejected_form")
assert_eq(current.generation, projection.target_generation)
assert_eq(rejected.generation, projection.target_generation)
assert_eq(current.activation, "live")
assert_eq(rejected.activation, "live")
assert_eq(current.version, 1)
assert_eq(rejected.version, 1)
assert_eq(current.carrier.original_task, projection.current_work.original_task)
assert_eq(rejected.carrier.projection_id, projection.rejected_form.projection_id)
assert(contains(current.source_refs, projection.projection_id))
assert(contains(current.source_refs, projection.carrier_id))
assert(contains(current.source_refs, projection.source_corpse_id))
for _, id in ipairs(packet.field.unit_order) do
    assert(packet.field.units[id].kind ~= "network_carrier",
        "selected NETWORK path materialized a carrier alias")
end
assert_eq(observed.descendant_current_check_count, 0)

local missing, missing_err = network_ingress.prepare(
    observed.lineage,
    observed.carrier,
    {
        source_corpse = observed.corpse,
        assessment_event = observed.assessment_event,
        max_bytes = 1048576,
    }
)
assert(missing == nil)
assert(tostring(missing_err):find("requires projection", 1, true))

local incomplete, incomplete_err = network_ingress.prepare(
    observed.lineage,
    observed.carrier,
    {network_projection = projection, max_bytes = 1048576}
)
assert(incomplete == nil)
assert(tostring(incomplete_err):find("exact source tuple", 1, true))

local domain = assert(flow_domain.new({1, 2, 3}, {
    stream_id = "untrusted-network-projection",
    source_ref = "test:untrusted-network-projection",
}))
local injected, injected_err = packet_birth.create(domain, "forbidden", {
    packet_options = {network_projection = {}},
})
assert(injected == nil)
assert_eq(injected_err, "NETWORK projection is owned by trusted packet life")
assert_eq(domain.birth_seq, 0)

ingress.network_projection.current_work.original_task = "mutated detached ingress"
projection.current_work.original_task = "mutated detached source"
assert(current.carrier.original_task ~= "mutated detached ingress")
assert(current.carrier.original_task ~= "mutated detached source")
assert(packet.ingress.network_projection.current_work.original_task
    ~= "mutated detached ingress")
assert(packet.ingress.network_projection.current_work.original_task
    ~= "mutated detached source")

print("test_network_rejected_materialization ok")
