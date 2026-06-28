local fake = {}

function fake.ask(call)
    call = call or {}
    local mode = call.mode or "natural"
    local operator = call.operator or "☴"

    return {
        mode = mode,
        operator = operator,
        text = "fake substrate response",
        proposal = {
            kind = "semantic_proposal",
            summary = "fake substrate observed task shape",
        },
    }
end

return fake
