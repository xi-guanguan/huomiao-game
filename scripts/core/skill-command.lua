local ____lualib = require("core.lualib_bundle")
local __TS__StringStartsWith = ____lualib.__TS__StringStartsWith
local __TS__ArraySome = ____lualib.__TS__ArraySome
local ____exports = {}
local ____compat = require("core.compat")
local jsLength = ____compat.jsLength
local jsSlice = ____compat.jsSlice
local jsCharAt = ____compat.jsCharAt
function ____exports.commandDistance(a, b)
    if math.abs(jsLength(a) - jsLength(b)) > 1 then
        return 2
    end
    local i = 0
    local j = 0
    local edits = 0
    while i < jsLength(a) and j < jsLength(b) do
        do
            if jsCharAt(a, i) == jsCharAt(b, j) then
                i = i + 1
                j = j + 1
                goto __continue4
            end
            edits = edits + 1
            if edits > 1 then
                return 2
            end
            if jsLength(a) > jsLength(b) then
                i = i + 1
            elseif jsLength(a) < jsLength(b) then
                j = j + 1
            else
                i = i + 1
                j = j + 1
            end
        end
        ::__continue4::
    end
    return edits + ((i < jsLength(a) or j < jsLength(b)) and 1 or 0)
end
function ____exports.matchCommand(stream, commands)
    local best = nil
    for ____, command in ipairs(commands) do
        do
            local length = math.max(
                2,
                jsLength(command) - 1
            )
            while length <= jsLength(command) + 1 do
                do
                    if jsLength(stream) < length then
                        goto __continue13
                    end
                    local tail = jsSlice(stream, -length)
                    local edits = ____exports.commandDistance(tail, command)
                    if edits > 1 then
                        goto __continue13
                    end
                    local deferred = edits == 1 and __TS__ArraySome(
                        commands,
                        function(____, c) return __TS__StringStartsWith(c, tail) and jsLength(c) > jsLength(tail) end
                    )
                    local candidate = {command = command, edits = edits, length = length, deferred = deferred}
                    if not best or edits < best.edits or edits == best.edits and length > best.length then
                        best = candidate
                    end
                end
                ::__continue13::
                length = length + 1
            end
        end
    end
    return best
end
function ____exports.commandHint(stream, commands)
    do
        local start = 0
        while start < jsLength(stream) do
            local tail = jsSlice(stream, start)
            if __TS__ArraySome(
                commands,
                function(____, command) return __TS__StringStartsWith(command, tail) end
            ) then
                return tail
            end
            start = start + 1
        end
    end
    return ""
end
return ____exports
