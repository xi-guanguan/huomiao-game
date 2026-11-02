local Native = require("platform.native")
local ____lualib = require("render.lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local __TS__ObjectAssign = ____lualib.__TS__ObjectAssign
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__NumberIsFinite = ____lualib.__TS__NumberIsFinite
local __TS__ArrayIncludes = ____lualib.__TS__ArrayIncludes
local __TS__ArraySplice = ____lualib.__TS__ArraySplice
local __TS__MathSign = ____lualib.__TS__MathSign
local __TS__SetDescriptor = ____lualib.__TS__SetDescriptor
local ____exports = {}
local function clamp(v, a, b)
    if a == nil then
        a = 0
    end
    if b == nil then
        b = 1
    end
    return math.max(
        a,
        math.min(b, v)
    )
end
local function fract(v)
    return v - math.floor(v)
end
local function hash(v)
    return fract(math.sin(v * 127.1 + 311.7) * 43758.5453)
end
local function smooth(v)
    local t = clamp(v)
    return t * t * (3 - 2 * t)
end
local function wrap(v, span)
    return (v % span + span) % span
end
local cold = "#82918d"
local ash = "#6f7466"
local coal = "#3b3229"
local ember = "#b56435"
local fire = "#edac58"
local bone = "#f0d6a3"
--- Atmospheric and contact presentation only. A game-owned clock drives all effects.
-- Uses original Fluxy principles (shared advection, density detail, warm→soot cooling),
-- while leaving the mature fluid solver, rules and save data untouched.
____exports.Atmosphere = __TS__Class()
local Atmosphere = ____exports.Atmosphere
Atmosphere.name = "Atmosphere"
function Atmosphere.prototype.____constructor(self, seed)
    if seed == nil then
        seed = 1102
    end
    self.seed = seed
    self.view = {
        dt = 0,
        chapter = 0,
        cameraX = 0,
        ground = 0,
        width = 1,
        height = 1,
        hero = {
            x = 0,
            y = 0,
            body = 1,
            breath = 0,
            fury = 0
        },
        burns = {}
    }
    self.time = 0
    self.cues = {}
    self.lastEvent = -1
    self.disposed = false
    self.smoke = {}
    self.lit = Native:newCanvas()
    self.light = self.lit:getContext("2d")
    self._wind = {x = 5, y = 0.5}
    self.draws = 0
    self.lights = 0
    do
        local j = 0
        while j < 3 do
            local c = Native:newCanvas()
            c.width = 32
            c.height = 22
            local g = c:getContext("2d")
            local d = g:createImageData(32, 22)
            do
                local y = 0
                while y < 22 do
                    do
                        local x = 0
                        while x < 32 do
                            local density = 0
                            do
                                local b = 0
                                while b < 5 do
                                    local cx = 8 + b * 4 + (hash(seed + j * 71 + b) - 0.5) * 7
                                    local cy = 11 + (hash(b + seed + j) - 0.5) * 7
                                    local dx = (x - cx) / (7 + hash(b + 8) * 4)
                                    local dy = (y - cy) / (5 + hash(b + 9) * 3)
                                    density = math.max(
                                        density,
                                        clamp(1 - dx * dx - dy * dy)
                                    )
                                    b = b + 1
                                end
                            end
                            local grain = hash(x * 37 + y * 811 + j * 71 + seed)
                            local a = math.floor(clamp(density * (0.7 + grain * 0.4)) * 5) / 5
                            local i = (y * 32 + x) * 4
                            d.data[i] = ({84, 56, 120})[j + 1]
                            d.data[i + 1] = ({96, 48, 126})[j + 1]
                            d.data[i + 2] = ({91, 39, 115})[j + 1]
                            d.data[i + 3] = a * (grain > 0.92 and 110 or 190)
                            x = x + 1
                        end
                    end
                    y = y + 1
                end
            end
            g:putImageData(d, 0, 0)
            local ____self_smoke_0 = self.smoke
            ____self_smoke_0[#____self_smoke_0 + 1] = c
            j = j + 1
        end
    end
end
function Atmosphere.prototype.update(self, input)
    if self.disposed then
        return
    end
    self.view = __TS__ObjectAssign(
        {},
        input,
        {
            hero = __TS__ObjectAssign({}, input.hero),
            burns = __TS__ArrayMap(
                __TS__ArrayFilter(
                    input.burns,
                    function(____, b) return b.chapter == input.chapter end
                ),
                function(____, b) return __TS__ObjectAssign({}, b) end
            )
        }
    )
    if input.paused then
        return
    end
    local dt = __TS__NumberIsFinite(input.dt) and clamp(input.dt, 0, 0.1) or 0
    self.time = self.time + dt
    self._wind = {
        x = 5 + math.sin(self.time * 0.19 + self.seed) * 1.4 + math.sin(self.time * 0.071) * 1,
        y = 0.35 + math.sin(self.time * 0.13) * 0.2
    }
    for ____, cue in ipairs(self.cues) do
        cue.age = cue.age + dt
    end
    self.cues = __TS__ArrayFilter(
        self.cues,
        function(____, cue) return cue.age < cue.life end
    )
end
function Atmosphere.prototype.event(self, event)
    if self.disposed or event.id <= self.lastEvent then
        return
    end
    self.lastEvent = event.id
    if not __TS__ArrayIncludes({
        "stroke",
        "attack",
        "hit",
        "player-hit",
        "skill",
        "guard",
        "parry",
        "kill",
        "enemy-attack"
    }, event.type) then
        return
    end
    local life = event.type == "skill" and (event.skill == "rebirth" and 1.2 or (event.skill == "nova" and 1.5 or 0.8)) or (event.type == "kill" and 1.1 or (event.type == "stroke" and 0.18 or 0.45))
    local ____self_cues_1 = self.cues
    ____self_cues_1[#____self_cues_1 + 1] = __TS__ObjectAssign({}, event, {x = event.x or self.view.hero.x, y = event.y or self.view.hero.y, age = 0, life = life})
    if #self.cues > 40 then
        __TS__ArraySplice(self.cues, 0, #self.cues - 40)
    end
end
function Atmosphere.prototype.drawBack(self, ctx)
    if self.disposed then
        return
    end
    local v = self.view
    local t = v.reduced and 0 or self.time
    ctx:save()
    ctx.imageSmoothingEnabled = false
    do
        local i = 0
        while i < 8 do
            local span = v.width + 110
            local x = wrap(
                hash(i + self.seed) * span - v.cameraX * 0.16 + t * self._wind.x * 0.19,
                span
            ) - 65
            local y = v.ground * (0.49 + hash(i + 40) * 0.32)
            local w = 38 + hash(i + 5) * 75
            local h = 9 + hash(i + 19) * 15
            ctx.globalAlpha = 0.075 + hash(i + 31) * 0.055
            ctx:drawImage(
                self.smoke[1],
                math.floor(x + 0.5),
                math.floor(y + 0.5),
                math.floor(w + 0.5),
                math.floor(h + 0.5)
            )
            i = i + 1
        end
    end
    ctx.fillStyle = cold
    do
        local i = 0
        while i < 24 do
            local span = v.width + 20
            local x = wrap(
                hash(i + self.seed + 61) * span - v.cameraX * 0.28 + t * self._wind.x * 0.3,
                span
            ) - 10
            local y = wrap(
                hash(i + 95) * math.max(1, v.ground) + t * (1 + hash(i + 11)),
                math.max(1, v.ground - 8)
            )
            ctx.globalAlpha = 0.09 + hash(i + 8) * 0.15
            ctx:fillRect(
                math.floor(x + 0.5),
                math.floor(y + 0.5),
                1,
                1
            )
            i = i + 1
        end
    end
    ctx:restore()
    self.draws = self.draws + 1
end
function Atmosphere.prototype.drawGround(self, ctx)
    if self.disposed then
        return
    end
    local v = self.view
    local t = v.reduced and 0 or self.time
    ctx:save()
    ctx.imageSmoothingEnabled = false
    for ____, b in ipairs(v.burns) do
        do
            if b.x + b.width < v.cameraX - 30 or b.x > v.cameraX + v.width + 30 or b.age > 65 then
                goto __continue36
            end
            local hot = clamp(1 - b.age / 18) * clamp(b.strength)
            local cool = smooth((b.age - 6) / 10) * (1 - smooth((b.age - 28) / 35))
            local x0 = b.x - v.cameraX
            local top = v.ground - b.y - b.height
            do
                local i = 0
                while i < 5 do
                    local h = hash(i + b.seed)
                    local phase = fract(t * (0.16 + h * 0.06) + h)
                    local rise = phase * (22 + h * 26)
                    local x = x0 + b.width * (0.08 + h * 0.84) + self._wind.x * phase * 1.4
                    local y = v.ground - rise - 10
                    local alpha = (hot * 0.1 + cool * 0.12) * (1 - phase) * (0.6 + h * 0.4)
                    if alpha > 0.003 then
                        ctx.globalAlpha = alpha
                        ctx:drawImage(
                            self.smoke[(cool > 0.5 and 0 or 1) + 1],
                            math.floor(x - 12 + 0.5),
                            math.floor(math.max(top, y) + 0.5),
                            math.floor(21 + rise * 0.55 + 0.5),
                            math.floor(12 + rise * 0.3 + 0.5)
                        )
                    end
                    i = i + 1
                end
            end
            do
                local i = 0
                while i < math.min(
                    40,
                    math.ceil(b.width / 7)
                ) do
                    local n = hash(i * 13 + b.seed)
                    local wx = b.x + b.width * n
                    local wy = -2 - hash(i + b.seed + 7) * math.min(
                        11,
                        math.max(0, -b.y)
                    )
                    local flicker = v.reduced and 0.7 or 0.65 + math.sin(t * 3 + n * 19) * 0.18
                    local fade = (hot * 0.5 + cool * 0.27) * flicker
                    ctx.globalAlpha = fade
                    ctx.fillStyle = b.age < 14 and ember or ash
                    ctx:fillRect(
                        math.floor(wx - v.cameraX + 0.5),
                        math.floor(v.ground - wy + 0.5),
                        i % 7 == 0 and 2 or 1,
                        1
                    )
                    i = i + 1
                end
            end
        end
        ::__continue36::
    end
    for ____, c in ipairs(self.cues) do
        if __TS__ArrayIncludes({"kill", "enemy-attack"}, c.type) then
            self:dust(ctx, c)
        end
    end
    ctx:restore()
    self.draws = self.draws + 1
end
function Atmosphere.prototype.drawFront(self, ctx)
    if self.disposed then
        return
    end
    local v = self.view
    local t = v.reduced and 0 or self.time
    ctx:save()
    ctx.imageSmoothingEnabled = false
    if not v.reduced then
        do
            local i = 0
            while i < 9 do
                local span = v.width + 32
                local x = wrap(
                    hash(i + self.seed + 404) * span - v.cameraX * 0.94 + t * self._wind.x * 0.8,
                    span
                ) - 16
                local y = v.ground + 9 + hash(i + 44) * math.max(1, v.height - v.ground - 14) + math.sin(t * 0.4 + i) * 2
                ctx.globalAlpha = 0.11 + hash(i + 7) * 0.12
                ctx.fillStyle = i % 4 ~= 0 and ash or coal
                ctx:fillRect(
                    math.floor(x + 0.5),
                    math.floor(y + 0.5),
                    i % 5 ~= 0 and 1 or 2,
                    1
                )
                i = i + 1
            end
        end
    end
    for ____, cue in ipairs(self.cues) do
        self:drawCue(ctx, cue)
    end
    ctx:restore()
    self.draws = self.draws + 1
end
function Atmosphere.prototype.dust(self, ctx, c)
    local p = clamp(c.age / c.life)
    local x = (c.x or 0) - self.view.cameraX
    local y = self.view.ground - (c.y or 0)
    local count = self.view.reduced and 3 or (c.heavy and 11 or 7)
    do
        local i = 0
        while i < count do
            local n = hash(i + c.id)
            local side = i % 2 ~= 0 and 1 or -1
            local r = p * (9 + n * 18) * (c.heavy and 1.25 or 1)
            ctx.globalAlpha = (1 - p) * (0.14 + n * 0.09)
            ctx:drawImage(
                self.smoke[2],
                math.floor(x + side * r - 5 + 0.5),
                math.floor(y - 4 - math.sin(p * math.pi) * (2 + n * 4) + 0.5),
                10 + math.floor(p * 8 + 0.5),
                6 + math.floor(p * 4 + 0.5)
            )
            i = i + 1
        end
    end
end
function Atmosphere.prototype.stroke(self, ctx, points, color, width, alpha)
    ctx.globalAlpha = clamp(alpha)
    ctx.strokeStyle = color
    ctx.lineWidth = width
    ctx:beginPath()
    ctx:moveTo(
        math.floor(points[1] + 0.5),
        math.floor(points[2] + 0.5)
    )
    do
        local i = 2
        while i < #points do
            ctx:lineTo(
                math.floor(points[i + 1] + 0.5),
                math.floor(points[i + 1 + 1] + 0.5)
            )
            i = i + 2
        end
    end
    ctx:stroke()
end
function Atmosphere.prototype.drawCue(self, ctx, c)
    local p = clamp(c.age / c.life)
    local x = (c.x or 0) - self.view.cameraX
    local root = self.view.ground - (c.y or 0)
    local d = c.direction or 1
    local reduced = self.view.reduced
    local body = self.view.hero.body
    local handY = root - (body < 0.05 and 7 or (body < 0.9 and 16 or 28))
    local a = (1 - p) * (reduced and 0.4 or 1)
    if c.type == "stroke" then
        return
    end
    if c.type == "attack" then
        self:stroke(
            ctx,
            {x + d * 5, handY + 1, x + d * (8 + p * 10), handY - 2},
            ember,
            1,
            a * 0.5
        )
        return
    end
    if c.type == "hit" or c.type == "player-hit" then
        local y = c.y and root or root - 24
        do
            local i = 0
            while i < (reduced and 2 or 5) do
                local n = hash(c.id + i * 7)
                local side = i % 2 ~= 0 and 1 or -1
                local xx = x + side * (2 + p * (8 + n * 8))
                local yy = y + (n - 0.5) * 12 + p * p * 7
                self:stroke(
                    ctx,
                    {xx - side * 3, yy - 1, xx, yy},
                    c.type == "hit" and (i % 3 ~= 0 and ember or bone) or coal,
                    1,
                    a * 0.5
                )
                i = i + 1
            end
        end
        return
    end
    if c.type == "guard" or c.type == "parry" then
        if c.type == "guard" then
            return
        end
        local width = (1 - p) * 6
        self:stroke(
            ctx,
            {
                x + 9 - width,
                handY - 9,
                x + 12,
                handY - 4,
                x + 8 + width,
                handY + 3
            },
            bone,
            1,
            a * 0.65
        )
        return
    end
    if c.type == "kill" or c.type == "enemy-attack" then
        return
    end
    if c.type ~= "skill" then
        return
    end
    local skill = c.skill
    local prep = 1 - smooth(p / 0.16)
    local tail = 1 - smooth((p - 0.2) / 0.8)
    if skill == "rebirth" then
        do
            local i = 0
            while i < (reduced and 4 or 15) do
                local n = hash(c.id + i)
                local angle = n * math.pi * 2
                local r = (1 - smooth(p / 0.72)) * (13 + n * 18)
                local xx = x + math.cos(angle) * r
                local yy = root - 16 + math.sin(angle) * r * 0.7
                ctx.globalAlpha = math.sin(p * math.pi) * 0.65
                ctx.fillStyle = p < 0.45 and coal or (i % 3 ~= 0 and ember or bone)
                ctx:fillRect(
                    math.floor(xx + 0.5),
                    math.floor(yy + 0.5),
                    1 + i % 2,
                    1
                )
                i = i + 1
            end
        end
        return
    end
    if skill == "nova" then
        local travel = smooth(p / 0.5)
        local span = 8 + travel * 55
        do
            local i = 0
            while i < (reduced and 4 or 13) do
                local n = hash(c.id + i * 4)
                local side = i % 2 ~= 0 and 1 or -1
                ctx.globalAlpha = tail * (0.16 + n * 0.08)
                ctx:drawImage(
                    self.smoke[2],
                    math.floor(x + side * span * (0.5 + n * 0.5) - 8 + 0.5),
                    math.floor(root - 8 - n * 5 + 0.5),
                    16 + math.floor(p * 12 + 0.5),
                    10
                )
                i = i + 1
            end
        end
        return
    end
    if skill == "oath" then
        do
            local i = 0
            while i < (reduced and 3 or 7) do
                local n = hash(c.id + i)
                local xx = x + (n - 0.5) * 22
                local yy = root - 5 - p * (14 + n * 21)
                self:stroke(
                    ctx,
                    {xx, yy + 3, xx + d * 2, yy},
                    i % 3 ~= 0 and ember or bone,
                    1,
                    a * 0.55
                )
                i = i + 1
            end
        end
        return
    end
    local target = (c.targetX or (c.x or 0) + d * (skill == "lash" and 48 or 26)) - self.view.cameraX
    if prep > 0.01 then
        self:stroke(
            ctx,
            {
                x + d * 5,
                handY + 2,
                x + d * 8,
                handY - 4,
                x + d * 4,
                handY - 5
            },
            fire,
            1,
            prep * 0.8
        )
    end
    if p > 0.1 and p < 0.55 then
        local q = smooth((p - 0.1) / 0.45)
        local ____end = x + (target - x) * q
        local bend = skill == "lash" and math.sin(q * math.pi) * 12 or 3
        self:stroke(
            ctx,
            {
                x + d * 7,
                handY + 2,
                x + (____end - x) * 0.48,
                handY - bend,
                ____end,
                handY - 1
            },
            ember,
            reduced and 1 or 3,
            tail * 0.55
        )
        self:stroke(
            ctx,
            {
                x + d * 9,
                handY,
                x + (____end - x) * 0.48,
                handY - bend + 1,
                ____end,
                handY
            },
            fire,
            1,
            tail * 0.8
        )
    end
    if not reduced then
        do
            local i = 0
            while i < 6 do
                local n = hash(c.id + i * 13)
                local q = clamp((p - 0.2) / 0.8)
                local xx = x + (target - x) * (n * 0.7 + 0.3) + self._wind.x * q
                local yy = handY - (2 + n * 8) * q + q * q * 5
                ctx.globalAlpha = q * tail * 0.65
                ctx.fillStyle = i % 4 ~= 0 and ember or bone
                ctx:fillRect(
                    math.floor(xx + 0.5),
                    math.floor(yy + 0.5),
                    1,
                    1
                )
                i = i + 1
            end
        end
    end
end
function Atmosphere.prototype.lightActor(self, source, p)
    if self.disposed then
        return source
    end
    local w = source.width
    local h = source.height
    local g = self.light
    if self.lit.width ~= w or self.lit.height ~= h then
        self.lit.width = w
        self.lit.height = h
    end
    g:clearRect(0, 0, w, h)
    g.imageSmoothingEnabled = false
    g:drawImage(source, 0, 0)
    local warm = 0
    local worldSide = 1
    local v = self.view
    local hero = v.hero
    if p.enemy then
        local distance = Native:hypot(p.x - hero.x, (p.y - hero.y) * 0.7)
        warm = clamp(1 - distance / 95) * (0.035 + hero.breath * 0.09 + hero.fury * 0.08)
        worldSide = __TS__MathSign(hero.x - p.x) or -1
    end
    for ____, b in ipairs(v.burns) do
        local edge = math.max(b.x - p.x, 0, p.x - (b.x + b.width))
        local strength = clamp(1 - edge / 85) * clamp(1 - b.age / 23) * b.strength * 0.12
        if strength > warm then
            warm = strength
            worldSide = __TS__MathSign(b.x + b.width * 0.5 - p.x) or -1
        end
    end
    g:save()
    g.globalCompositeOperation = "source-atop"
    local side = worldSide * p.facing
    local mid = p.anchor[1]
    local radius = math.max(12, w * 0.32)
    do
        local i = 0
        while i < 6 do
            local t = (i + 0.5) / 6
            local xx = mid - radius + i * radius / 3
            local illum = (side > 0 and t or 1 - t) * warm
            g.fillStyle = ("rgba(239,142,61," .. tostring(illum)) .. ")"
            g:fillRect(
                math.floor(xx),
                0,
                math.ceil(radius / 3) + 1,
                h
            )
            i = i + 1
        end
    end
    local top = p.anchor[2] - 48
    g.fillStyle = "rgba(129,153,151,.028)"
    g:fillRect(
        0,
        math.max(0, top),
        w,
        15
    )
    g:restore()
    self.lights = self.lights + 1
    return self.lit
end
function Atmosphere.prototype.enemyPose(self, ____bindingPattern0)
    local telegraphTotal
    local telegraph
    local stage
    local ability
    local facing
    local heavy
    local actionTime
    local motion
    motion = ____bindingPattern0.motion
    actionTime = ____bindingPattern0.actionTime
    heavy = ____bindingPattern0.heavy
    if heavy == nil then
        heavy = false
    end
    facing = ____bindingPattern0.facing
    if facing == nil then
        facing = 1
    end
    ability = ____bindingPattern0.ability
    if ability == nil then
        ability = ""
    end
    stage = ____bindingPattern0.stage
    if stage == nil then
        stage = ""
    end
    telegraph = ____bindingPattern0.telegraph
    if telegraph == nil then
        telegraph = 0
    end
    telegraphTotal = ____bindingPattern0.telegraphTotal
    if telegraphTotal == nil then
        telegraphTotal = 1
    end
    if self.view.reduced then
        return {x = 0, y = 0, scaleX = 1, scaleY = 1}
    end
    local t = math.max(0, actionTime)
    local squash = 0
    local x = 0
    local stone = ability == "stone"
    local pyre = ability == "pyre-combo" or ability == "pyre"
    local archer = ability == "arrow" or ability == "ranged"
    local binding = ability == "binding"
    local thunder = ability == "thunder"
    if telegraph > 0 then
        local progress = 1 - clamp(telegraph / math.max(0.001, telegraphTotal))
        local tension = smooth(progress)
        squash = tension * (stone and 0.027 or (pyre and 0.018 or (binding and 0.007 or (thunder and 0 or 0.01))))
        x = facing * tension * (archer and -1.2 or (stone and -0.8 or (binding and 0.6 or 0)))
    elseif __TS__ArrayIncludes({"attack", "attack2", "strike"}, motion) then
        squash = math.sin(clamp(t / (stone and 0.34 or 0.25)) * math.pi) * (stone and 0.029 or (heavy and 0.024 or (pyre and 0.02 or 0.012)))
        x = facing * math.sin(clamp(t / (stone and 0.3 or 0.2)) * math.pi) * (stone and 1.2 or (pyre and 1.4 or (archer and 0.4 or (binding and 0.6 or (heavy and 1.2 or 0.6)))))
    elseif __TS__ArrayIncludes({"walk", "run"}, motion) then
        squash = math.abs(math.sin(t * 8)) * 0.008
    end
    if stage == "thunder-hold" then
        squash = 0
        x = 0
    end
    return {
        x = math.floor(x + 0.5),
        y = 0,
        scaleX = 1 + squash,
        scaleY = 1 - squash
    }
end
function Atmosphere.prototype.diagnostics(self)
    return {
        clock = self.time,
        wind = self.wind,
        cues = #self.cues,
        draws = self.draws,
        lights = self.lights,
        mode = "canvas2d",
        ownsRules = false
    }
end
function Atmosphere.prototype.reset(self)
    self.time = 0
    self.cues = {}
    self.lastEvent = -1
end
function Atmosphere.prototype.dispose(self)
    self.disposed = true
    self.cues = {}
    self.smoke = {}
end
__TS__SetDescriptor(
    Atmosphere.prototype,
    "wind",
    {get = function(self)
        return __TS__ObjectAssign({}, self._wind)
    end},
    true
)
return ____exports
