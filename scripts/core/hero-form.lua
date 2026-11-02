--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local function clamp(value)
    return math.max(
        0,
        math.min(1, value)
    )
end
local function smooth(value)
    local t = clamp(value)
    return t * t * (3 - 2 * t)
end
--- Gameplay owns the ifrit hysteresis. The renderer only observes it.
function ____exports.heroForm(state)
    local breath = state.phase == "fallen" and 0 or clamp(state.resolve / math.max(1, state.maxResolve))
    local body = smooth((breath - 0.14) / 0.46)
    local vigor = smooth((breath - 0.52) / 0.3)
    local ____state_infernoActive_0 = state.infernoActive
    if ____state_infernoActive_0 == nil then
        ____state_infernoActive_0 = breath >= 0.6 and state.rage >= 65
    end
    local active = ____state_infernoActive_0 and breath >= 0.52 and state.rage >= 48
    local fury = (active and math.max(
        0.58,
        smooth((state.rage - 48) / 35)
    ) or 0) * vigor
    local form = breath <= 0.16 and "ember" or (breath < 0.48 and "wraith" or (active and "ifrit" or "kindled"))
    return {
        form = form,
        breath = breath,
        body = body,
        fury = fury,
        light = state.phase == "fallen" and 0 or clamp(breath * 0.6 + clamp(state.heat / 70) * 0.4)
    }
end
return ____exports
