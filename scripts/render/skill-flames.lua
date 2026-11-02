local Native = require("platform.native")
local ____lualib = require("render.lualib_bundle")
local __TS__NumberIsFinite = ____lualib.__TS__NumberIsFinite
local __TS__ArrayForEach = ____lualib.__TS__ArrayForEach
local __TS__ArrayReverse = ____lualib.__TS__ArrayReverse
local __TS__SparseArrayNew = ____lualib.__TS__SparseArrayNew
local __TS__SparseArrayPush = ____lualib.__TS__SparseArrayPush
local __TS__SparseArraySpread = ____lualib.__TS__SparseArraySpread
local __TS__ArraySlice = ____lualib.__TS__ArraySlice
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local ____exports = {}
local C = {
    coal = "#231d1a",
    soot = "#3b2b24",
    rust = "#873820",
    red = "#bd4a23",
    fire = "#ee792a",
    hot = "#f4bc63",
    bone = "#efdab0"
}
local function clamp(v, low, high)
    if low == nil then
        low = 0
    end
    if high == nil then
        high = 1
    end
    return math.min(
        high,
        math.max(low, v)
    )
end
local function hash(seed, i)
    return Native:hash(seed, i)
end
local function mix(a, b, p)
    return a + (b - a) * p
end
--- No assets, retained state, timers, particles, rules, damage, or actor duplicates.
function ____exports.drawSkillFlame(g, p)
    if p.age < 0 or p.life <= 0 or p.age >= p.life or not __TS__NumberIsFinite(p.age + p.life + p.x + p.y) then
        return
    end
    local t = p.age
    local body = clamp(p.body)
    local level = clamp(p.level, 1, 3)
    local reduced = p.reduced
    local dir = p.direction < 0 and -1 or 1
    local baseAlpha = g.globalAlpha
    local ____p_form_0
    if p.form then
        ____p_form_0 = p.form == "ember"
    else
        ____p_form_0 = body <= 67 / 12167
    end
    local ember = ____p_form_0
    local ____p_form_1
    if p.form then
        ____p_form_1 = p.form == "wraith"
    else
        ____p_form_1 = not ember and body < 10115 / 12167
    end
    local half = ____p_form_1
    local height = ember and 9 or (half and 23 or 46)
    local hand = p.origin and ({(p.origin.x - p.x) * dir, p.origin.y - p.y}) or (ember and ({3, -7}) or (half and ({13, -12}) or ({10, -25})))
    local ____opt_2 = p.wind
    local ____opt_4 = p.wind
    local windX = (____opt_2 and ____opt_2.x or 0.35) * dir
    local windY = ____opt_4 and ____opt_4.y or -0.1
    local target = clamp(p.targetX == nil and 57 or (p.targetX - p.x) * dir, 23, 115)
    local function paint(points, color, alpha)
        if alpha <= 0 or #points < 3 then
            return
        end
        g.globalAlpha = baseAlpha * clamp(alpha)
        g.fillStyle = color
        g:beginPath()
        __TS__ArrayForEach(
            points,
            function(____, ____bindingPattern0, i)
                local y
                local x
                x = ____bindingPattern0[1]
                y = ____bindingPattern0[2]
                local ____temp_6
                if i ~= 0 then
                    ____temp_6 = g:lineTo(
                        math.floor(x + 0.5),
                        math.floor(y + 0.5)
                    )
                else
                    ____temp_6 = g:moveTo(
                        math.floor(x + 0.5),
                        math.floor(y + 0.5)
                    )
                end
                return ____temp_6
            end
        )
        g:closePath()
        g:fill()
    end
    local function stroke(points, color, width, alpha)
        if alpha <= 0 or #points < 2 then
            return
        end
        g.globalAlpha = baseAlpha * clamp(alpha)
        g.strokeStyle = color
        g.lineWidth = width
        g:beginPath()
        __TS__ArrayForEach(
            points,
            function(____, ____bindingPattern0, i)
                local y
                local x
                x = ____bindingPattern0[1]
                y = ____bindingPattern0[2]
                local ____temp_7
                if i ~= 0 then
                    ____temp_7 = g:lineTo(
                        math.floor(x + 0.5),
                        math.floor(y + 0.5)
                    )
                else
                    ____temp_7 = g:moveTo(
                        math.floor(x + 0.5),
                        math.floor(y + 0.5)
                    )
                end
                return ____temp_7
            end
        )
        g:stroke()
    end
    local function ribbon(path, width, alpha, hot)
        if hot == nil then
            hot = true
        end
        local upper = {}
        local lower = {}
        __TS__ArrayForEach(
            path,
            function(____, ____bindingPattern0, i)
                local y
                local x
                x = ____bindingPattern0[1]
                y = ____bindingPattern0[2]
                local shape = math.sin(math.pi * (i + 0.25) / #path)
                local w = width * shape * (0.72 + hash(p.seed, i + 41) * 0.45)
                upper[#upper + 1] = {x, y - w}
                lower[#lower + 1] = {x - 1, y + w * 0.65}
            end
        )
        local ____array_8 = __TS__SparseArrayNew(table.unpack(upper))
        __TS__SparseArrayPush(
            ____array_8,
            table.unpack(__TS__ArrayReverse(lower))
        )
        paint(
            {__TS__SparseArraySpread(____array_8)},
            C.rust,
            alpha * 0.72
        )
        stroke(
            path,
            C.fire,
            math.max(1, width * 0.65),
            alpha * 0.92
        )
        if hot then
            stroke(
                __TS__ArraySlice(path, 1, -1),
                C.hot,
                1,
                alpha * 0.72
            )
        end
    end
    g:save()
    g:translate(p.x, p.y)
    g:scale(dir, 1)
    g.globalCompositeOperation = p.skill == "oath" and p.clipToAlpha and "source-atop" or "source-over"
    g.lineJoin = "bevel"
    g.lineCap = "butt"
    do
        local ____try, ____hasReturned, ____returnValue = pcall(function()
            if p.skill == "spark" then
                if t > 0.65 then
                    return true
                end
                local a = (1 - t / 0.65) ^ 1.5 * (reduced and 0.68 or 1)
                local hx, hy = table.unpack(hand, 1, 2)
                local stretch = clamp(t / 0.18)
                local reach = (ember and 19 or 29) + level * 2
                local tip = hx + reach + stretch * 7
                local lean = windX * t * 4
                paint({
                    {hx - 3, hy + 2},
                    {hx + 5, hy - 6},
                    {tip - 8, hy - 5 + lean},
                    {tip, hy - 1},
                    {tip - 7, hy + 3},
                    {hx + 4, hy + 5}
                }, C.coal, a * 0.55)
                local count = reduced and 1 or 3
                do
                    local i = 0
                    while i < count do
                        local offset = (i - (count - 1) / 2) * 3
                        local curl = reduced and 0 or math.sin(t * 27 + i * 2.7) * 1.7
                        local path = {{hx, hy + offset * 0.25}, {hx + reach * 0.3, hy + offset - 1 + curl}, {hx + reach * 0.65 + stretch * 3, hy + offset * 0.7 - 2 - curl * 0.5}, {tip - i * 3, hy + offset + lean + curl}}
                        ribbon(path, i ~= 0 and 2 or 3.4, a * (i ~= 0 and 0.65 or 1), t < 0.16)
                        i = i + 1
                    end
                end
                if not reduced and t > 0.045 then
                    do
                        local i = 0
                        while i < 4 do
                            local xx = hx + 5 + hash(p.seed, i) * reach + t * 8
                            local yy = hy + (hash(p.seed, i + 6) - 0.5) * 15 - t * 6
                            stroke({{xx - 5, yy + 1}, {xx - 2, yy}, {xx + 1, yy - 2}}, i % 2 ~= 0 and C.soot or C.red, 1, a * 0.7)
                            i = i + 1
                        end
                    end
                end
                return true
            end
            if p.skill == "headthrow" then
                if t > 0.85 then
                    return true
                end
                local u = clamp(t / 0.62)
                local a = (t <= 0.62 and 1 or 1 - (t - 0.62) / 0.23) * (reduced and 0.6 or 1)
                local ____end = p.targetX == nil and 64 or (p.targetX - p.x) * dir
                local function pathAt(v)
                    return {
                        ____end * v,
                        -36 - math.sin(math.pi * v) * 24
                    }
                end
                local current = pathAt(u)
                local dx = p.origin and hand[1] - current[1] or 0
                local dy = p.origin and hand[2] - current[2] or 0
                do
                    local i = 0
                    while i < (reduced and 3 or 9) do
                        do
                            local lag = 0.035 + i * 0.017
                            local v1 = u - lag
                            local v0 = v1 - 0.015 - hash(p.seed, i) * 0.015
                            if v0 < 0 then
                                goto __continue28
                            end
                            local b = pathAt(v1)
                            local c = pathAt(v0)
                            local drift = i / 9
                            stroke({{c[1] + dx + windX * drift * 3, c[2] + dy - drift * 2}, {b[1] + dx, b[2] + dy + (i % 3 - 1)}}, i < 2 and C.hot or (i < 5 and C.fire or C.soot), i < 2 and 1 or 1.4, a * (1 - drift) * 0.8)
                        end
                        ::__continue28::
                        i = i + 1
                    end
                end
                return true
            end
            if p.skill == "rebirth" then
                if t > 1.05 then
                    return true
                end
                local fade = 1 - clamp((t - 0.58) / 0.47)
                local inward = 1 - (1 - clamp(t / 0.62)) ^ 2
                local count = reduced and 5 or 15
                do
                    local i = 0
                    while i < count do
                        local angle = hash(p.seed, i + 10) * math.pi * 2
                        local side = i % 2 ~= 0 and -1 or 1
                        local start = {
                            side * (12 + hash(p.seed, i + 2) * 19),
                            -2 - hash(p.seed, i + 13) * (height + 7)
                        }
                        local ____end = ember and ({
                            (hash(p.seed, i + 21) - 0.5) * 6,
                            -5
                        }) or (half and ({5 - i % 5 * 3, -4 - i % 3 * 5}) or ({(i % 3 - 1) * 5, -5 - i % 6 * 6}))
                        local travel = clamp(inward - i % 4 * 0.045)
                        local x = mix(start[1], ____end[1], travel) + math.sin(angle + travel * 2) * (1 - travel) * 3
                        local y = mix(start[2], ____end[2], travel)
                        local size = (1.5 + hash(p.seed, i + 7) * 2) * (1 - travel * 0.45)
                        if not reduced and travel < 0.88 then
                            stroke({{x + side * 3, y - 2}, {x + side, y - 1}, {x, y}}, C.red, 1, fade * 0.35)
                        end
                        paint({{x - size, y}, {x, y - size}, {x + size, y - 0.5}, {x + size * 0.4, y + size}}, C.coal, fade * 0.9)
                        stroke({{x - size, y}, {x, y - size}, {x + size * 0.5, y - size * 0.25}}, i % 4 ~= 0 and C.red or C.hot, 1, fade * (0.8 - travel * 0.35))
                        i = i + 1
                    end
                end
                local seam = ember and ({{-3, -3}, {-1, -7}, {2, -8}, {4, -5}}) or (half and ({{-12, -4}, {-4, -10}, {4, -11}, {8, -18}}) or ({
                    {-5, -3},
                    {-4, -12},
                    {1, -20},
                    {-1, -29},
                    {2, -37}
                }))
                stroke(seam, C.red, reduced and 1 or 2.5, fade * 0.65)
                stroke(seam, C.hot, 1, fade * (t < 0.12 and 0.85 or 0.48))
                return true
            end
            if p.skill == "lash" then
                local beats = level >= 3 and 4 or 3
                local last = (beats - 1) * 0.18
                if t > last + 0.25 then
                    return true
                end
                do
                    local previous = reduced and 0 or 1
                    while previous >= 0 do
                        do
                            local beat = math.min(
                                beats - 1,
                                math.floor(t / 0.18)
                            ) - previous
                            if beat < 0 then
                                goto __continue38
                            end
                            local since = t - beat * 0.18
                            if since < 0 or since > 0.25 then
                                goto __continue38
                            end
                            local a = (1 - since / 0.25) ^ 1.3 * (previous ~= 0 and 0.22 or (reduced and 0.65 or 1))
                            local hx, hy = table.unpack(hand, 1, 2)
                            local reach = math.max(hx + 18, target - 3)
                            local sign = beat % 2 ~= 0 and 1 or -1
                            local bend = sign * (ember and 9 or 15) * (1 - since * 1.6)
                            local path = {}
                            do
                                local j = 0
                                while j < 10 do
                                    local q = j / 9
                                    path[#path + 1] = {
                                        mix(hx, reach, q),
                                        mix(hy, ember and -8 or -24, q) + math.sin(q * math.pi) * bend + math.sin(q * math.pi * 2 + beat) * 2
                                    }
                                    j = j + 1
                                end
                            end
                            ribbon(path, 2.4, a, since < 0.08)
                            if not reduced then
                                do
                                    local j = 1
                                    while j < 8 do
                                        local x, y = table.unpack(path[j + 1], 1, 2)
                                        paint({{x - 2, y - 1}, {x + 1, y - 2}, {x + 3, y}, {x, y + 1}}, C.coal, a * 0.72)
                                        stroke({{x - 1, y - 1}, {x + 1, y - 1}}, C.hot, 1, a * 0.8)
                                        j = j + 2
                                    end
                                end
                            end
                        end
                        ::__continue38::
                        previous = previous - 1
                    end
                end
                return true
            end
            if p.skill == "nova" then
                if t > 0.9 then
                    return true
                end
                local expand = 1 - (1 - clamp(t / 0.35)) ^ 2
                local radius = 18 + expand * (reduced and 45 or 74)
                local a = (1 - t / 0.9) ^ 1.1 * (reduced and 0.62 or 1)
                for ____, side in ipairs({-1, 1}) do
                    local upper = {}
                    local lower = {}
                    do
                        local i = 0
                        while i < 11 do
                            local u = i / 10
                            local x = side * (4 + radius * u)
                            local h = math.sin(u * math.pi) * (3 + hash(p.seed, i + side * 11) * 8) * (1 - t * 0.55)
                            upper[#upper + 1] = {x, -2 - h}
                            lower[#lower + 1] = {
                                x,
                                1 + math.sin(u * math.pi) * 2
                            }
                            i = i + 1
                        end
                    end
                    local ____array_9 = __TS__SparseArrayNew(table.unpack(upper))
                    __TS__SparseArrayPush(
                        ____array_9,
                        table.unpack(__TS__ArrayReverse(lower))
                    )
                    paint(
                        {__TS__SparseArraySpread(____array_9)},
                        C.coal,
                        a * 0.64
                    )
                    local seam = __TS__ArrayMap(
                        upper,
                        function(____, ____bindingPattern0, i)
                            local y
                            local x
                            x = ____bindingPattern0[1]
                            y = ____bindingPattern0[2]
                            return {
                                x,
                                mix(y, -1, 0.6) + (i % 2 ~= 0 and 1 or 0)
                            }
                        end
                    )
                    stroke(seam, C.rust, 3, a * 0.8)
                    do
                        local i = 1
                        while i < #seam - 2 do
                            stroke(
                                __TS__ArraySlice(seam, i, i + 3),
                                t < 0.1 and C.hot or C.fire,
                                1,
                                a * 0.9
                            )
                            i = i + 3
                        end
                    end
                    if not reduced then
                        do
                            local i = 0
                            while i < 5 do
                                local q = 0.22 + i * 0.16
                                local x = side * radius * q
                                local y = -3 - (3 + i % 3 * 3) * math.sin(clamp(t / 0.6) * math.pi)
                                stroke({{x - side * 5, y + 2}, {x - side * 2, y}, {x, y + windY}}, i % 3 ~= 0 and C.soot or C.red, 1, a * 0.8)
                                i = i + 1
                            end
                        end
                    end
                end
                if t < 0.12 then
                    local chest = ember and -6 or (half and -12 or -26)
                    stroke({{-7, chest - 6}, {-3, chest - 3}, {0, chest}}, C.fire, 1, (1 - t / 0.12) * 0.7)
                    stroke({{6, chest - 4}, {3, chest - 2}, {0, chest}}, C.hot, 1, (1 - t / 0.12) * 0.65)
                end
                return true
            end
            if p.skill == "oath" then
                local pulse = clamp(p.pulse or 0)
                local start = math.max(0, 1 - t / 0.32)
                local ____end = clamp((p.life - t) / 0.45)
                local a = (0.2 + start * 0.5 + pulse * 0.7) * ____end * (reduced and 0.7 or 1)
                local paths = ember and ({{{-3, -5}, {-1, -8}, {2, -8}}, {{0, -3}, {2, -5}, {4, -4}}}) or (half and ({{{-12, -5}, {-5, -8}, {1, -12}, {6, -15}}, {{1, -12}, {8, -10}, {12, -5}}, {{4, -17}, {7, -19}, {9, -17}}}) or ({{
                    {-5, -3},
                    {-4, -10},
                    {-1, -17},
                    {1, -23},
                    {-1, -30},
                    {1, -35}
                }, {{1, -23}, {4, -18}, {5, -10}, {8, -3}}, {{0, -29}, {5, -31}, {10, -28}, {12, -24}}, {{-1, -29}, {-6, -30}, {-10, -25}}}))
                do
                    local i = 0
                    while i < #paths do
                        stroke(paths[i + 1], C.rust, 2, a * 0.8)
                        stroke(paths[i + 1], C.fire, 1, a * 0.65)
                        if pulse > 0.05 or start > 0.5 then
                            local path = paths[i + 1]
                            local segment = math.floor(clamp(1 - pulse) * (#path - 2))
                            stroke(
                                __TS__ArraySlice(path, segment, segment + 2),
                                C.bone,
                                1,
                                (pulse * 0.75 + start * 0.25) * ____end
                            )
                        end
                        i = i + 1
                    end
                end
            end
        end)
        do
            g:restore()
        end
        if not ____try then
            error(____hasReturned, 0)
        end
        if ____try and ____hasReturned then
            return ____returnValue
        end
    end
end
return ____exports
