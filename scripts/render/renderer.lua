local Native = require("platform.native")
local ____lualib = require("render.lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local __TS__New = ____lualib.__TS__New
local Map = ____lualib.Map
local __TS__ObjectEntries = ____lualib.__TS__ObjectEntries
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__ObjectAssign = ____lualib.__TS__ObjectAssign
local __TS__SparseArrayNew = ____lualib.__TS__SparseArrayNew
local __TS__SparseArrayPush = ____lualib.__TS__SparseArrayPush
local __TS__SparseArraySpread = ____lualib.__TS__SparseArraySpread
local __TS__StringIncludes = ____lualib.__TS__StringIncludes
local __TS__Iterator = ____lualib.__TS__Iterator
local __TS__ArrayPush = ____lualib.__TS__ArrayPush
local __TS__ArrayIncludes = ____lualib.__TS__ArrayIncludes
local __TS__ArrayReduce = ____lualib.__TS__ArrayReduce
local __TS__NumberIsFinite = ____lualib.__TS__NumberIsFinite
local __TS__Delete = ____lualib.__TS__Delete
local __TS__ObjectKeys = ____lualib.__TS__ObjectKeys
local __TS__StringStartsWith = ____lualib.__TS__StringStartsWith
local __TS__MathSign = ____lualib.__TS__MathSign
local __TS__Number = ____lualib.__TS__Number
local __TS__SetDescriptor = ____lualib.__TS__SetDescriptor
local ____exports = {}
local ____hero_2Dform = require("render.hero-form")
local heroForm = ____hero_2Dform.heroForm
local ____atmosphere = require("render.atmosphere")
local Atmosphere = ____atmosphere.Atmosphere
local ____skill_2Dflames = require("render.skill-flames")
local drawSkillFlame = ____skill_2Dflames.drawSkillFlame
local P = {
    sky = "#293940",
    far = "#34474b",
    hill = "#253b3d",
    earth = "#182724",
    black = "#101c1b",
    bone = "#d1c9ac",
    fire = "#ffbc62",
    hot = "#ffe3a1",
    rust = "#a05839"
}
local function hash(n)
    local v = math.sin(n * 127.1 + 311.7) * 43758.5453
    return v - math.floor(v)
end
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
function ____exports.fireResponse(s)
    local fuel = clamp(s.resolve / math.max(1, s.maxResolve))
    return s.phase == "fallen" and 0 or clamp(fuel * 0.65 + math.min(1, s.heat / 65) * 0.35)
end
____exports.locomotionPhase = function(worldX, facing, stride) return (worldX * facing % stride + stride) % stride / stride end
____exports.GameRenderer = __TS__Class()
local GameRenderer = ____exports.GameRenderer
GameRenderer.name = "GameRenderer"
function GameRenderer.prototype.____constructor(self, canvas)
    self.canvas = canvas
    self.back = Native:newCanvas()
    self.width = 192
    self.height = 224
    self.scale = 2
    self.dpr = 1
    self.time = 0
    self.lastEvent = 0
    self.techArt = nil
    self.actorBurning = nil
    self.inferno = nil
    self.atmosphere = __TS__New(Atmosphere, 1102)
    self.actorSurface = Native:newCanvas()
    self.disposed = false
    self.assetGeneration = 0
    self.surfaceMask = Native:newCanvas()
    self.mask = self.surfaceMask:getContext("2d")
    self.flameLayer = true
    self.lastRenderMs = 0
    self.attachment = {x = 0, y = 0}
    self.lastEnemy = nil
    self.dissolving = {}
    self.images = __TS__New(Map)
    self.atlases = __TS__New(Map)
    self.fx = {}
    self.reduced = false
    self.shake = 0
    self.keyPulse = 0
    self.stop = 0
    self.poses = __TS__New(Map)
    self.propsMeta = {}
    self.sceneMeta = nil
    self.ctx = canvas:getContext("2d", {alpha = false})
    self.g = self.back:getContext("2d", {alpha = false})
    self.observer = {disconnect = function(self)
    end}
    self:resize()
end
function GameRenderer.prototype.setAssets(self, manifest)
    local ____manifest_props_0 = manifest.props
    if ____manifest_props_0 == nil then
        ____manifest_props_0 = {}
    end
    self.propsMeta = ____manifest_props_0
    local ____manifest_scene_1 = manifest.scene
    if ____manifest_scene_1 == nil then
        ____manifest_scene_1 = nil
    end
    self.sceneMeta = ____manifest_scene_1
    local ____manifest_images_2 = manifest.images
    if ____manifest_images_2 == nil then
        ____manifest_images_2 = manifest
    end
    for ____, ____value in ipairs(__TS__ObjectEntries(____manifest_images_2)) do
        local name = ____value[1]
        local url = ____value[2]
        if type(url) == "string" then
            self.images:set(
                name,
                Native:loadImage(url)
            )
        end
    end
    local ____manifest_atlases_4 = manifest.atlases
    if ____manifest_atlases_4 == nil then
        ____manifest_atlases_4 = {}
    end
    for ____, ____value in ipairs(__TS__ObjectEntries(____manifest_atlases_4)) do
        local name = ____value[1]
        local value = ____value[2]
        local ____temp_3
        if type(value) == "string" then
            ____temp_3 = Native:json(value)
        else
            ____temp_3 = value
        end
        local data = ____temp_3
        self.atlases:set(name, data)
        if data.image and not self.images:has(name) then
            self.images:set(
                name,
                Native:loadImage(data.image)
            )
        end
    end
    self.techArt = Native.techart:load("nocturnal-ta/")
    self.actorBurning = Native.techart:actorCreate({base = "round4/techart/"})
    self.inferno = Native.techart:worldCreate({base = "round4/techart/mist/"})
end
function GameRenderer.prototype.reset(self)
    self.stop = 0
    self.keyPulse = 0
    self.poses:clear()
    self.lastEnemy = nil
    self.dissolving = {}
    self.fx = {}
    self.lastEvent = 0
    self.shake = 0
    local ____opt_5 = self.inferno
    if ____opt_5 ~= nil then
        ____opt_5:reset()
    end
    self.atmosphere:reset()
end
function GameRenderer.prototype.dispose(self)
    self.disposed = true
    self.assetGeneration = self.assetGeneration + 1
    local ____opt_7 = self.techArt
    if ____opt_7 ~= nil then
        ____opt_7:dispose()
    end
    local ____opt_9 = self.actorBurning
    if ____opt_9 ~= nil then
        ____opt_9:dispose()
    end
    local ____opt_11 = self.inferno
    if ____opt_11 ~= nil then
        ____opt_11:dispose()
    end
    self.atmosphere:dispose()
    self.observer:disconnect()
    self.fx = {}
    self.images:clear()
    self.atlases:clear()
end
function GameRenderer.prototype.setReducedMotion(self, value)
    self.reduced = value
end
function GameRenderer.prototype.setFlameLayer(self, enabled)
    self.flameLayer = enabled
end
function GameRenderer.prototype.resize(self)
    local r = self.canvas:getBoundingClientRect()
    if not r.width or not r.height then
        return
    end
    self.dpr = 1
    self.scale = math.max(
        1,
        math.floor(r.width * self.dpr / 192 + 0.5)
    )
    self.width = math.ceil(r.width * self.dpr / self.scale)
    self.height = math.ceil(r.height * self.dpr / self.scale)
    local ____self_back_14 = self.back
    local ____self_width_13 = self.width
    self.surfaceMask.width = ____self_width_13
    ____self_back_14.width = ____self_width_13
    local ____self_back_16 = self.back
    local ____self_height_15 = self.height
    self.surfaceMask.height = ____self_height_15
    ____self_back_16.height = ____self_height_15
    self.canvas.width = math.floor(r.width * self.dpr + 0.5)
    self.canvas.height = math.floor(r.height * self.dpr + 0.5)
    self.ctx.imageSmoothingEnabled = false
    self.g.imageSmoothingEnabled = false
end
function GameRenderer.prototype.render(self, s, dt)
    local started = Native:now()
    if not s.paused then
        self.time = self.time + dt
        self.stop = math.max(0, self.stop - dt)
        self.keyPulse = math.max(0, self.keyPulse - dt)
        self.shake = math.max(0, self.shake - dt * 12)
        for ____, f in ipairs(self.fx) do
            f.age = f.age + dt
        end
        self.fx = __TS__ArrayFilter(
            self.fx,
            function(____, f) return f.age < f.life end
        )
        for ____, body in ipairs(self.dissolving) do
            body.age = body.age + dt
        end
        self.dissolving = __TS__ArrayFilter(
            self.dissolving,
            function(____, body) return body.age < 0.6 end
        )
    end
    for ____, e in ipairs(s.events) do
        if e.id > self.lastEvent then
            self.lastEvent = e.id
            self:event(e, s)
        end
    end
    local ____opt_17 = s.world
    local w = self.width
    local h = self.height
    local ground = math.floor(h * 0.69 + 0.5)
    local camera = ____opt_17 and ____opt_17.cameraX or 0
    local g = self.g
    local shape = heroForm(s)
    self.atmosphere:update({
        dt = dt,
        paused = s.paused,
        reduced = self.reduced,
        chapter = s.chapter,
        cameraX = camera,
        ground = ground,
        width = w,
        height = h,
        hero = {
            x = s.world.hero.x,
            y = s.world.hero.y,
            body = shape.body,
            breath = shape.breath,
            fury = shape.fury
        },
        burns = s.world.burns or ({})
    })
    self.mask:clearRect(0, 0, w, h)
    g.globalAlpha = 1
    g.fillStyle = P.sky
    g:fillRect(0, 0, w, h)
    self:background(camera, ground, s)
    self.atmosphere:drawBack(g)
    g:save()
    self:terrain(camera, ground, s)
    self:props(s, camera, ground, false)
    self:foreground(camera, ground)
    self.mask.fillStyle = "#fff"
    self.mask:fillRect(0, ground - 2, w, h - ground + 2)
    local worldView = {
        dt = dt,
        chapter = s.chapter,
        cameraX = camera,
        ground = ground,
        width = w,
        height = h,
        paused = s.paused,
        reduced = self.reduced
    }
    local ____opt_19 = self.inferno
    if ____opt_19 ~= nil then
        ____opt_19:update(s.world.burns or ({}), worldView)
    end
    if self.inferno then
        local scorched = self.inferno:scorch(self.back, worldView, self.surfaceMask)
        if scorched ~= self.back then
            g:drawImage(scorched, 0, 0)
        end
    end
    if self.flameLayer then
        local ____opt_21 = self.inferno
        if ____opt_21 ~= nil then
            ____opt_21:drawFire(g, worldView)
        end
        self:worldFlameFeet(s, camera, ground)
    end
    self.atmosphere:drawGround(g)
    local ____opt_23 = s.world
    local hero = ____opt_23 and ____opt_23.hero
    local hx = (hero and hero.x or 55) - camera
    local evade = __TS__ArrayFind(
        self.fx,
        function(____, f) return f.type == "defense" and f.stage == "evade" and f.age < 0.55 end
    )
    local hop = (evade and evade.ability) == "pyre-combo" and math.sin(evade.age / 0.55 * math.pi) * 12 or 0
    local hy = ground - (hero and hero.y or 0) - hop
    if s.enemy then
        local e = s.enemy
        self:actor(
            e.id,
            e.motion or "idle",
            e.actionTime or 0,
            e.x - camera,
            ground - e.y,
            e.x < (hero and hero.x or 0) and 1 or -1,
            e.hp / e.maxHp,
            e,
            s
        )
        self.lastEnemy = __TS__ObjectAssign({}, e)
    end
    for ____, body in ipairs(self.dissolving) do
        local e = body.enemy
        local ____self_actor_36 = self.actor
        local ____array_35 = __TS__SparseArrayNew(
            e.id,
            "fallen",
            body.age,
            e.x - camera,
            ground - e.y,
            e.facing,
            0,
            e,
            s
        )
        local ____opt_33 = self.techArt
        __TS__SparseArrayPush(____array_35, ____opt_33 and ____opt_33.materials and 1 or 1 - body.age / 0.6)
        ____self_actor_36(
            self,
            __TS__SparseArraySpread(____array_35)
        )
    end
    local ht = s.headthrow
    if s.buffs.shadow > 0 and not ht then
        self.g:save()
        self.g.globalAlpha = 0.23
        self:actor(
            "hero",
            "attack2",
            s.elapsed * 0.9,
            hx - 13,
            hy,
            hero and hero.facing or 1,
            0,
            nil,
            s,
            0.23
        )
        self.g:restore()
    end
    if not ht then
        self:actor(
            "hero",
            (evade and evade.ability) == "arrow" and "crawl" or (hero and hero.motion or "idle"),
            evade and evade.age or hero and hero.actionTime or 0,
            hx,
            hy,
            hero and hero.facing or 1,
            s.resolve / s.maxResolve,
            nil,
            s
        )
    elseif ht.stage == "flight" then
        if (ht.bodyAlpha or 0) > 0.05 and heroForm(s).form ~= "ember" then
            self:actor(
                "hero",
                "headless",
                ht.elapsed,
                hx,
                hy,
                1,
                0,
                nil,
                s,
                ht.bodyAlpha
            )
        end
        local headX = ht.headX - camera
        local headY = ground - ht.headY
        self:glow(
            headX,
            headY,
            14,
            P.fire,
            0.2
        )
        local head = self.images:get("head")
        if head then
            g:drawImage(
                head,
                math.floor(headX + 0.5) - 8,
                math.floor(headY + 0.5) - 8
            )
        else
            self:rect(
                headX - 3,
                headY - 4,
                6,
                7,
                P.bone
            )
        end
        self:flame(headX, headY - 4, 9, 1)
    else
        self:actor(
            "hero",
            "rebirth",
            ht.elapsed,
            hx,
            hy,
            1,
            1,
            nil,
            s,
            ht.bodyAlpha
        )
    end
    self:statusEffects(s, hx, hy)
    self:props(s, camera, ground, true)
    self:fireLight(s, hx, hy)
    self:effects(camera, ground, s)
    self.atmosphere:drawFront(g)
    if s.enemy then
        self:telegraph(s.enemy.x - camera, ground, s.enemy, s)
    end
    self:committedAttacks(s, camera, ground)
    g:restore()
    local attachmentHeight = heroForm(s).form == "ember" and 7 or (heroForm(s).form == "wraith" and 18 or 29)
    self.attachment = {x = hx, y = hy - attachmentHeight}
    self:embers(ground)
    local shade = g:createLinearGradient(0, h * 0.87, 0, h)
    shade:addColorStop(0, "#101c1b00")
    shade:addColorStop(1, "#0d171bdd")
    g.fillStyle = shade
    g:fillRect(0, h * 0.87, w, h * 0.13)
    self.ctx.fillStyle = P.black
    self.ctx:fillRect(0, 0, self.canvas.width, self.canvas.height)
    self.ctx.imageSmoothingEnabled = false
    self.ctx:save()
    if not self.reduced and self.shake > 0 then
        self.ctx:translate(
            math.floor(math.sin(self.time * 91) * self.shake + 0.5) * self.scale,
            math.floor(math.cos(self.time * 119) * self.shake * 0.5 + 0.5) * self.scale
        )
    end
    self.ctx:drawImage(
        self.back,
        0,
        0,
        w * self.scale,
        h * self.scale
    )
    self.ctx:restore()
    self.lastRenderMs = Native:now() - started
end
function GameRenderer.prototype.fireLight(self, s, x, y)
    local strength = ____exports.fireResponse(s)
    local g = self.g
    if strength > 0 then
        g:save()
        g.globalCompositeOperation = "screen"
        self:glow(
            x,
            y - 15,
            18 + strength * 24,
            "#d96e28",
            0.025 + strength * 0.1
        )
        self:glow(
            x,
            y + 1,
            12 + strength * 22,
            "#dca457",
            strength * 0.12
        )
        g:restore()
    end
end
function GameRenderer.prototype.worldFlameFeet(self, s, camera, ground)
    local ____opt_49 = self.inferno
    local ____opt_51 = s.world.burns
    local id = ____opt_49 and ____opt_49:diagnostics().activeId
    local b = ____opt_51 and __TS__ArrayFind(
        s.world.burns,
        function(____, b) return b.id == id end
    )
    if not self.techArt or not b then
        return
    end
    local fuel = clamp(1 - b.age / 11) * clamp(b.strength) * clamp(b.age / 0.25)
    if fuel <= 0 then
        return
    end
    local x = b.x - camera
    local y = ground - math.max(0, b.y)
    local top = ground - b.y - b.height
    local g = self.g
    g:save()
    g:beginPath()
    g:rect(
        math.floor(x + 0.5),
        math.floor(top + 0.5),
        math.ceil(b.width),
        math.max(
            0,
            math.min(
                math.ceil(b.height),
                ground + 6 - top
            )
        )
    )
    g:clip()
    do
        local i = 0
        while i < 6 do
            local n = hash(b.seed + i * 13)
            local px = x + b.width * (0.065 + i * 0.174 + (n - 0.5) * 0.035)
            self.techArt.fire:draw(
                g,
                px,
                y,
                (12 + n * 18) * fuel,
                self.time,
                b.seed + i * 71,
                self.reduced
            )
            i = i + 1
        end
    end
    g:restore()
end
function GameRenderer.prototype.rect(self, x, y, w, h, c, a)
    if a == nil then
        a = 1
    end
    self.g.globalAlpha = a
    self.g.fillStyle = c
    self.g:fillRect(
        math.floor(x + 0.5),
        math.floor(y + 0.5),
        math.ceil(w),
        math.ceil(h)
    )
    self.g.globalAlpha = 1
end
function GameRenderer.prototype.line(self, points, c, width, a)
    if width == nil then
        width = 1
    end
    if a == nil then
        a = 1
    end
    local g = self.g
    g.globalAlpha = a
    g.strokeStyle = c
    g.lineWidth = width
    g:beginPath()
    g:moveTo(
        math.floor(points[1] + 0.5),
        math.floor(points[2] + 0.5)
    )
    do
        local i = 2
        while i < #points do
            g:lineTo(
                math.floor(points[i + 1] + 0.5),
                math.floor(points[i + 1 + 1] + 0.5)
            )
            i = i + 2
        end
    end
    g:stroke()
    g.globalAlpha = 1
end
function GameRenderer.prototype.poly(self, points, c, a)
    if a == nil then
        a = 1
    end
    local g = self.g
    g.globalAlpha = a
    g.fillStyle = c
    g:beginPath()
    g:moveTo(points[1], points[2])
    do
        local i = 2
        while i < #points do
            g:lineTo(points[i + 1], points[i + 1 + 1])
            i = i + 2
        end
    end
    g:closePath()
    g:fill()
    g.globalAlpha = 1
end
function GameRenderer.prototype.glow(self, x, y, r, c, a)
    local g = self.g
    local grad = g:createRadialGradient(
        x,
        y,
        0,
        x,
        y,
        r
    )
    grad:addColorStop(0, c)
    grad:addColorStop(1, c .. "00")
    g.globalAlpha = a
    g.fillStyle = grad
    g:fillRect(x - r, y - r, r * 2, r * 2)
    g.globalAlpha = 1
end
function GameRenderer.prototype.markSurface(self, image, x, y)
    local m = self.mask
    m:drawImage(
        image,
        math.floor(x + 0.5),
        math.floor(y + 0.5)
    )
    m.globalCompositeOperation = "source-in"
    m.fillStyle = "#fff"
    m:fillRect(0, 0, self.width, self.height)
    m.globalCompositeOperation = "source-over"
end
function GameRenderer.prototype.background(self, camera, ground, s)
    if self.sceneMeta then
        local sky = self.g:createLinearGradient(0, 0, 0, ground)
        sky:addColorStop(0, self.sceneMeta.sky[1])
        sky:addColorStop(1, self.sceneMeta.sky[2])
        self.g.fillStyle = sky
        self.g:fillRect(0, 0, self.width, ground)
        for ____, layer in __TS__Iterator(self.sceneMeta.layers) do
            if not (__TS__StringIncludes(layer.image, "ground") or __TS__StringIncludes(layer.image, "near")) then
                self:sceneLayer(layer, camera, ground)
            end
        end
        self:campBackdrop(camera, ground, s)
        self:scenery(camera, ground, s)
        if s.chapter == 3 then
            self:rect(
                0,
                0,
                self.width,
                ground,
                "#102331",
                0.18
            )
        end
        if s.chapter == 4 then
            self:rect(
                0,
                0,
                self.width,
                ground,
                "#2f241f",
                0.14
            )
        end
        return
    end
    local w = self.width
    local horizon = ground * 0.52
    local sky = self.g:createLinearGradient(0, 0, 0, ground)
    sky:addColorStop(0, s.chapter > 2 and "#232f37" or "#24343f")
    sky:addColorStop(0.65, s.chapter > 2 and "#67716b" or "#6b7774")
    sky:addColorStop(1, "#626e5e")
    self.g.fillStyle = sky
    self.g:fillRect(0, 0, w, ground)
    self:glow(
        w * 0.7,
        horizon * 0.7,
        36,
        "#c0c1a1",
        0.12
    )
    self:rect(
        w * 0.7,
        horizon * 0.7,
        3,
        3,
        "#c4c6af",
        0.55
    )
    do
        local layer = 0
        while layer < 3 do
            local ratio = ({0.08, 0.18, 0.35})[layer + 1]
            local base = horizon + layer * ground * 0.09
            local size = 48 + layer * 18
            local start = math.floor(camera * ratio / size) - 1
            local pts = {-20, ground}
            do
                local n = start
                while n < start + math.ceil(w / size) + 4 do
                    local x = n * size - camera * ratio
                    __TS__ArrayPush(
                        pts,
                        x,
                        base - hash(n + layer * 51) * ({30, 19, 12})[layer + 1],
                        x + size * 0.45,
                        base - 7 - hash(n + 7) * 12
                    )
                    n = n + 1
                end
            end
            __TS__ArrayPush(pts, w + 50, ground)
            self:poly(pts, ({P.far, P.hill, "#2c4039"})[layer + 1])
            layer = layer + 1
        end
    end
    local step = 220
    do
        local i = math.floor(camera * 0.46 / step) - 1
        while i <= math.ceil((camera * 0.46 + w) / step) + 1 do
            local x = i * step - camera * 0.46 + 60
            local y = ground * 0.77
            self:poly({
                x - 19,
                y,
                x - 14,
                y - 12,
                x,
                y - 17,
                x + 15,
                y - 11,
                x + 21,
                y
            }, "#26352f")
            self:rect(
                x + 1,
                y - 11,
                5,
                11,
                "#182b27"
            )
            self:line({x - 1, y - 18, x - 1, y - 24}, "#273b32")
            if i % 2 == 0 then
                self:line({x + 35, y + 2, x + 35, y - 27}, "#27352e", 2)
                self:poly({
                    x + 35,
                    y - 27,
                    x + 51,
                    y - 24,
                    x + 46,
                    y - 13,
                    x + 35,
                    y - 17
                }, "#39443a")
            end
            i = i + 1
        end
    end
    do
        local i = 0
        while i < 18 do
            local x = ((i * 23 - camera * 0.45) % (w + 25) + (w + 25)) % (w + 25) - 10
            self:rect(
                x,
                ground * 0.82 + hash(i + 89) * 11,
                10 + hash(i) * 15,
                1,
                "#53614c",
                0.3
            )
            i = i + 1
        end
    end
end
function GameRenderer.prototype.terrain(self, camera, ground, s)
    if self.sceneMeta then
        for ____, layer in __TS__Iterator(self.sceneMeta.layers) do
            if __TS__StringIncludes(layer.image, "ground") then
                self:sceneLayer(layer, camera, ground)
            end
        end
        if s.phase == "crawl" then
            do
                local i = 0
                while i < 7 do
                    self:flame(
                        i * 38 - camera * 0.2,
                        ground + 3,
                        12 + hash(i) * 13,
                        i
                    )
                    i = i + 1
                end
            end
        end
        return
    end
    self:rect(
        0,
        ground,
        self.width,
        self.height - ground,
        P.earth
    )
    self:rect(
        0,
        ground,
        self.width,
        2,
        "#53604b"
    )
    self:rect(
        0,
        ground + 2,
        self.width,
        3,
        "#354738"
    )
    local tile = self.images:get("tiles")
    do
        local x = math.floor(camera / 16) * 16 - 16
        while x < camera + self.width + 16 do
            local px = x - camera
            local n = math.floor(x / 16)
            if tile then
                self.g:drawImage(
                    tile,
                    math.abs(n) % 8 * 16,
                    0,
                    16,
                    16,
                    math.floor(px + 0.5),
                    ground,
                    16,
                    16
                )
            else
                self:rect(
                    px,
                    ground,
                    16,
                    2,
                    n % 3 == 0 and "#677054" or "#44573f"
                )
                do
                    local j = 0
                    while j < 4 do
                        self:rect(
                            px + hash(n * 3 + j) * 16,
                            ground + 6 + hash(n + j) * 20,
                            2 + hash(n + j) * 4,
                            1,
                            j % 2 ~= 0 and "#364436" or "#111e1c"
                        )
                        j = j + 1
                    end
                end
            end
            do
                local j = 0
                while j < 3 do
                    local gx = px + j * 5 + hash(n + j) * 3
                    local hh = 2 + hash(n * 7 + j) * 5
                    self:line({
                        gx - 2,
                        ground,
                        gx - 3,
                        ground - hh,
                        gx,
                        ground - 1,
                        gx + 2,
                        ground - hh - 2
                    }, n % 3 ~= 0 and "#4b5c40" or "#75805b")
                    j = j + 1
                end
            end
            x = x + 16
        end
    end
    if s.phase == "crawl" then
        do
            local i = 0
            while i < 7 do
                self:flame(
                    i * 38 - camera * 0.2,
                    ground + 3,
                    12 + hash(i) * 13,
                    i
                )
                i = i + 1
            end
        end
    end
end
function GameRenderer.prototype.props(self, s, camera, ground, front)
    local ____opt_61 = s.world
    for ____, p in ipairs(____opt_61 and ____opt_61.props or ({})) do
        do
            local x = p.x - camera
            if x < -90 or x > self.width + 90 then
                goto __continue101
            end
            local y = ground - p.y
            local broken = __TS__ArrayIncludes({
                "broken",
                "open",
                "spent",
                "crossed",
                "cleared",
                "collected",
                "passed"
            }, p.state)
            local kind = p.kind
            kind = ({
                fissure = "gap",
                ash = "heat",
                embers = "heat",
                bonebead = "relic",
                shrine = "relic",
                totem = "thunder"
            })[kind] or kind
            local ____broken_57
            if broken then
                local ____opt_53 = self.propsMeta.clearedMapping
                if ____opt_53 ~= nil then
                    ____opt_53 = ____opt_53[p.kind]
                end
                ____broken_57 = ____opt_53
            else
                local ____opt_55 = self.propsMeta.gameplayMapping
                if ____opt_55 ~= nil then
                    ____opt_55 = ____opt_55[p.kind]
                end
                ____broken_57 = ____opt_55
            end
            local mapped = ____broken_57
            local ____mapped_58 = mapped
            if ____mapped_58 == nil then
                ____mapped_58 = ({
                    deadwood = "log",
                    fence = broken and "fence-broken" or "fence-bound",
                    fissure = "fissure",
                    ash = "ash",
                    embers = "embers",
                    totem = "totem",
                    banner = "banner",
                    shrine = "shrine",
                    bonebead = "bonebead"
                })[p.kind]
            end
            local propName = ____mapped_58
            local ____opt_59 = self.propsMeta.props
            if ____opt_59 ~= nil then
                ____opt_59 = ____opt_59[propName]
            end
            local prop = ____opt_59
            local img = self.images:get("prop." .. tostring(propName))
            if img and prop and kind == "relic" == front then
                self.g:drawImage(
                    img,
                    math.floor(x - prop.root[1] + 0.5),
                    math.floor(y - prop.root[2] + 0.5)
                )
                if not front then
                    self:markSurface(img, x - prop.root[1], y - prop.root[2])
                end
                if kind == "relic" and not broken then
                    self:glow(
                        x,
                        y - 5,
                        15,
                        P.hot,
                        0.12
                    )
                end
                goto __continue101
            end
            if front then
                if kind == "relic" then
                    self:rect(
                        x - 2,
                        y - 3,
                        5,
                        3,
                        P.bone
                    )
                    self:line({
                        x - 5,
                        y - 1,
                        x,
                        y - 5,
                        x + 6,
                        y - 2
                    }, P.rust)
                    if not broken then
                        self:glow(
                            x,
                            y - 4,
                            18,
                            P.hot,
                            0.15
                        )
                    end
                end
                goto __continue101
            end
            if kind == "fence" or kind == "binding" then
                for ____, sign in ipairs({-1, 1}) do
                    self:rect(
                        x + sign * 13,
                        y - 27,
                        3,
                        27,
                        "#45483a"
                    )
                    self:rect(
                        x + sign * 13,
                        y - 27,
                        2,
                        3,
                        P.bone
                    )
                end
                if broken then
                    self:line({
                        x - 12,
                        y - 3,
                        x - 4,
                        y - 1,
                        x + 3,
                        y - 5,
                        x + 11,
                        y - 1
                    }, "#807c60", 2)
                else
                    self:line({
                        x - 13,
                        y - 22,
                        x + 13,
                        y - 11,
                        x - 13,
                        y - 8,
                        x + 13,
                        y - 23
                    }, "#9b9275", 2)
                    self:line({x - 13, y - 17, x + 13, y - 17}, P.rust, 2)
                end
            elseif kind == "gap" or kind == "rift" then
                self:poly({
                    x - 18,
                    y,
                    x - 8,
                    y + 6,
                    x + 4,
                    y + 3,
                    x + 17,
                    y,
                    x + 12,
                    y + 21,
                    x - 10,
                    y + 28
                }, P.black)
                self:line({
                    x - 18,
                    y,
                    x - 8,
                    y + 5,
                    x + 3,
                    y + 2
                }, P.rust)
                if not broken then
                    self:rect(
                        x + 26,
                        y - 2,
                        6,
                        2,
                        P.bone
                    )
                    self:glow(
                        x + 28,
                        y - 3,
                        12,
                        P.hot,
                        0.1
                    )
                end
            elseif kind == "heat" or kind == "scorch" then
                do
                    local i = 0
                    while i < 8 do
                        self:rect(
                            x - 18 + i * 5,
                            y + 2,
                            4,
                            1,
                            P.rust,
                            0.8
                        )
                        if not broken then
                            self:flame(
                                x - 15 + i * 5,
                                y,
                                3 + hash(i) * 5,
                                i
                            )
                        end
                        i = i + 1
                    end
                end
            elseif kind == "lightning" or kind == "thunder" then
                self:rect(
                    x - 15,
                    y,
                    30,
                    2,
                    "#657f79"
                )
                for ____, sign in ipairs({-1, 1}) do
                    self:poly({
                        x + sign * 19,
                        y,
                        x + sign * 18 - 3,
                        y - 9,
                        x + sign * 18 + 4,
                        y - 7
                    }, "#59695d")
                end
            elseif kind ~= "relic" then
                if broken then
                    self:rect(
                        x - 16,
                        y - 4,
                        13,
                        4,
                        "#34382d"
                    )
                    self:poly({
                        x + 5,
                        y,
                        x + 8,
                        y - 9,
                        x + 16,
                        y - 4,
                        x + 17,
                        y
                    }, "#444334")
                else
                    self:poly({
                        x - 15,
                        y,
                        x - 9,
                        y - 15,
                        x - 18,
                        y - 29,
                        x - 13,
                        y - 30,
                        x - 4,
                        y - 20,
                        x + 8,
                        y - 34,
                        x + 11,
                        y - 32,
                        x + 5,
                        y - 15,
                        x + 16,
                        y - 5,
                        x + 14,
                        y
                    }, "#32392d")
                    self:line({
                        x - 9,
                        y - 2,
                        x - 4,
                        y - 16,
                        x + 8,
                        y - 30
                    }, "#6b634a", 2)
                end
            end
        end
        ::__continue101::
    end
end
function GameRenderer.prototype.actor(self, name, motion, t, x, y, facing, health, enemy, s, opacity)
    if opacity == nil then
        opacity = 1
    end
    local g = self.g
    local hitAge = math.huge
    for ____, fx in ipairs(self.fx) do
        local ____temp_63
        if name == "hero" then
            ____temp_63 = fx.type == "player-hit"
        else
            ____temp_63 = fx.type == "hit" and fx.enemyId == name
        end
        if ____temp_63 then
            hitAge = math.min(hitAge, fx.age)
        end
    end
    if not self.reduced then
        if hitAge < 0.12 then
            x = x - facing * math.sin(hitAge / 0.12 * math.pi) * (enemy and 1 or 2)
        end
        if (motion == "attack" or motion == "attack2") and t < 0.22 then
            x = x + facing * math.sin(t / 0.22 * math.pi) * 2
        end
    end
    local form = name == "hero" and heroForm(s) or nil
    self:rect(
        x - (form and 4 + form.body * 5 or 9),
        y,
        form and 8 + form.body * 10 or 18,
        2,
        "#0d1917",
        (form and form.body) == 0 and 0.25 or 0.55
    )
    local poseKey = name .. motion
    if self.stop > 0 and self.poses:has(poseKey) then
        t = self.poses:get(poseKey)
    else
        self.poses:set(poseKey, t)
    end
    local ____opt_result_68
    if enemy ~= nil then
        ____opt_result_68 = enemy.definitionId
    end
    local ____opt_result_68_69 = ____opt_result_68
    if ____opt_result_68_69 == nil then
        ____opt_result_68_69 = name
    end
    local definition = ____opt_result_68_69
    local formKey = (form and form.form) == "ember" and "hero-ember" or ((form and form.form) == "wraith" and "hero-half" or ((form and form.form) == "ifrit" and "hero-ifrit" or "hero"))
    ---@type string?
    local ____temp_80
    if name == "hero" and self.atlases:has(formKey) then
        ____temp_80 = formKey
    else
        local ____temp_79
        if name == "hero" then
            ____temp_79 = "hero"
        else
            local ____opt_result_78
            if enemy ~= nil then
                ____opt_result_78 = enemy.kind
            end
            ____temp_79 = ____opt_result_78 == "boss" and enemy.phase == 2 and "boss-phase2" or (({bone = "melee", archer = "ranged", pyre = "boss"})[definition] or definition)
        end
        ____temp_80 = ____temp_79
    end
    local key = ____temp_80
    local ____temp_86 = self.atlases:get(key)
    if ____temp_86 == nil then
        local ____self_84 = self.atlases
        local ____self_84_get_85 = ____self_84.get
        local ____opt_result_83
        if enemy ~= nil then
            ____opt_result_83 = enemy.ability
        end
        ____temp_86 = ____self_84_get_85(____self_84, ____opt_result_83)
    end
    local ____temp_86_92 = ____temp_86
    if ____temp_86_92 == nil then
        local ____self_90 = self.atlases
        local ____self_90_get_91 = ____self_90.get
        local ____opt_result_89
        if enemy ~= nil then
            ____opt_result_89 = enemy.kind
        end
        ____temp_86_92 = ____self_90_get_91(____self_90, ____opt_result_89)
    end
    local ____temp_98 = self.images:get(key)
    if ____temp_98 == nil then
        local ____self_96 = self.images
        local ____self_96_get_97 = ____self_96.get
        local ____opt_result_95
        if enemy ~= nil then
            ____opt_result_95 = enemy.ability
        end
        ____temp_98 = ____self_96_get_97(____self_96, ____opt_result_95)
    end
    local ____temp_98_104 = ____temp_98
    if ____temp_98_104 == nil then
        local ____self_102 = self.images
        local ____self_102_get_103 = ____self_102.get
        local ____opt_result_101
        if enemy ~= nil then
            ____opt_result_101 = enemy.kind
        end
        ____temp_98_104 = ____self_102_get_103(____self_102, ____opt_result_101)
    end
    local atlas = ____temp_86_92
    local image = ____temp_98_104
    local clip = motion
    if clip == "dead" then
        clip = "fallen"
    end
    if clip == "standup" then
        clip = "stand"
    end
    if clip == "reassemble" then
        clip = "rebirth"
    end
    if motion == "rebirth" and not s.headthrow and s.buffs.shield > 3.3 then
        clip = "skill.rebirth"
    end
    if __TS__ArrayIncludes({
        "spark",
        "headthrow",
        "rebirth",
        "lash",
        "nova",
        "oath"
    }, motion) and motion ~= "rebirth" then
        clip = "skill." .. motion
    end
    if atlas and image then
        local raw = atlas.clips[clip] or atlas.clips.idle
        local ____Native_isArray_result_108
        if Native:isArray(raw) then
            ____Native_isArray_result_108 = raw
        else
            local ____opt_result_107
            if raw ~= nil then
                ____opt_result_107 = raw.frames
            end
            ____Native_isArray_result_108 = ____opt_result_107
        end
        local frames = ____Native_isArray_result_108
        if frames and #frames then
            local total = __TS__ArrayReduce(
                frames,
                function(____, a, f) return a + (f.duration > 10 and f.duration / 1000 or f.duration) end,
                0
            )
            local pos = t
            if __TS__ArrayIncludes({"walk", "run", "crawl"}, clip) then
                local ____raw_stride_111 = raw.stride
                if ____raw_stride_111 == nil then
                    ____raw_stride_111 = clip == "run" and 36 or (clip == "crawl" and 12 or 24)
                end
                local stride = ____raw_stride_111
                pos = ____exports.locomotionPhase(name == "hero" and s.world.hero.x or enemy.x, facing, stride) * total
            else
                pos = raw and not Native:isArray(raw) and raw.loop == false and math.min(t, total - 0.0001) or t % total
            end
            local frame = frames[#frames]
            for ____, f in ipairs(frames) do
                pos = pos - (f.duration > 10 and f.duration / 1000 or f.duration)
                if pos < 0 then
                    frame = f
                    break
                end
            end
            local anchor = frame.anchor or atlas.anchor or ({32, 60})
            if name == "hero" then
                local ____temp_124
                if (form and form.form) == "ember" then
                    local ____opt_114 = frame.mounts
                    ____temp_124 = ____opt_114 and ____opt_114.head
                else
                    local ____opt_116 = frame.mounts
                    local ____temp_120 = ____opt_116 and ____opt_116.frontHand
                    if ____temp_120 == nil then
                        local ____opt_118 = frame.mounts
                        ____temp_120 = ____opt_118 and ____opt_118.rightHand
                    end
                    local ____temp_120_123 = ____temp_120
                    if ____temp_120_123 == nil then
                        local ____opt_121 = frame.mounts
                        ____temp_120_123 = ____opt_121 and ____opt_121.head
                    end
                    ____temp_124 = ____temp_120_123
                end
                local point = ____temp_124
                self.strikeMount = point and ({x = x + (point.x - anchor[1]) * facing, y = y + point.y - anchor[2]}) or nil
            end
            local material = nil
            if self.techArt then
                if enemy and enemy.hp <= 0 and motion == "fallen" then
                    material = self.techArt:sprite(
                        image,
                        frame,
                        "death",
                        math.min(1, t / 0.6)
                    )
                elseif not enemy and hitAge < 0.085 or motion == "hurt" then
                    material = self.techArt:sprite(
                        image,
                        frame,
                        "hurt",
                        self.reduced and 0.4 or math.min(
                            1,
                            (__TS__NumberIsFinite(hitAge) and hitAge or t) / self.techArt.settings.statuses.hurt.duration
                        )
                    )
                else
                    local ____opt_result_127
                    if enemy ~= nil then
                        ____opt_result_127 = enemy.burn
                    end
                    local ____opt_result_127_128 = ____opt_result_127
                    if ____opt_result_127_128 == nil then
                        ____opt_result_127_128 = 0
                    end
                    if ____opt_result_127_128 > 0 then
                        material = self.techArt:sprite(image, frame, "burning", self.reduced and 0.5 or self.time / self.techArt.settings.statuses.burning.duration % 1)
                    else
                        local ____opt_result_131
                        if enemy ~= nil then
                            ____opt_result_131 = enemy.telegraph
                        end
                        local ____opt_result_131_132 = ____opt_result_131
                        if ____opt_result_131_132 == nil then
                            ____opt_result_131_132 = 0
                        end
                        if ____opt_result_131_132 > 0 then
                            material = self.techArt:sprite(
                                image,
                                frame,
                                "ready",
                                self.reduced and 0.15 or 1 - enemy.telegraph / math.max(0.001, enemy.telegraphTotal)
                            )
                        end
                    end
                end
            end
            local pose = enemy and self.atmosphere:enemyPose({
                motion = motion,
                actionTime = t,
                heavy = enemy.attackHeavy,
                facing = facing,
                ability = enemy.ability,
                stage = enemy.attackStage,
                telegraph = enemy.telegraph,
                telegraphTotal = enemy.telegraphTotal
            }) or ({x = 0, y = 0, scaleX = 1, scaleY = 1})
            g:save()
            g.globalAlpha = opacity
            g:translate(
                math.floor(x + pose.x + 0.5),
                math.floor(y + pose.y + 0.5)
            )
            g:scale(facing * pose.scaleX, pose.scaleY)
            if name == "hero" and self.actorBurning then
                local shape = form
                local preserveBody = key ~= "hero" or __TS__ArrayIncludes({"crawl", "fallen", "headless", "rebirth"}, clip)
                local mounts = __TS__ObjectAssign({}, frame.mounts)
                if shape.form == "ember" then
                    for ____, k in ipairs(__TS__ObjectKeys(mounts)) do
                        if k ~= "head" then
                            __TS__Delete(mounts, k)
                        end
                    end
                else
                    if mounts.frontHand and not mounts.rightHand then
                        mounts.rightHand = mounts.frontHand
                    end
                    if mounts.backHand and not mounts.leftHand then
                        mounts.leftHand = mounts.backHand
                    end
                end
                local composed = self.actorBurning:render(
                    image,
                    frame,
                    {
                        anchor = anchor,
                        mounts = mounts,
                        motion = clip,
                        time = self.time,
                        body = shape.body,
                        breath = shape.breath,
                        fury = shape.fury,
                        light = shape.light,
                        pulse = clamp(self.keyPulse / 0.16),
                        reduced = self.reduced,
                        preserveBody = preserveBody
                    }
                )
                local lit = self.atmosphere:lightActor(composed.canvas, {x = s.world.hero.x, y = s.world.hero.y, anchor = composed.anchor, facing = facing})
                if s.buffs.oath > 0 then
                    drawSkillFlame(
                        lit:getContext("2d"),
                        {
                            skill = "oath",
                            age = 6 - s.buffs.oath,
                            life = 6,
                            level = s.skills.oath or 1,
                            seed = s.seed,
                            x = composed.anchor[1],
                            y = composed.anchor[2],
                            direction = 1,
                            body = shape.body,
                            form = shape.form,
                            reduced = self.reduced,
                            pulse = clamp(self.keyPulse / 0.16),
                            clipToAlpha = true
                        }
                    )
                end
                g:drawImage(lit, -composed.anchor[1], -composed.anchor[2])
            else
                if self.actorSurface.width ~= frame.w or self.actorSurface.height ~= frame.h then
                    self.actorSurface.width = frame.w
                    self.actorSurface.height = frame.h
                end
                local surface = self.actorSurface:getContext("2d")
                surface:clearRect(0, 0, frame.w, frame.h)
                surface.imageSmoothingEnabled = false
                if material then
                    surface:drawImage(
                        material,
                        0,
                        0,
                        frame.w,
                        frame.h
                    )
                else
                    surface:drawImage(
                        image,
                        frame.x,
                        frame.y,
                        frame.w,
                        frame.h,
                        0,
                        0,
                        frame.w,
                        frame.h
                    )
                end
                local ____self_142 = self.atmosphere
                local ____self_142_lightActor_143 = ____self_142.lightActor
                local ____self_actorSurface_141 = self.actorSurface
                local ____opt_result_135
                if enemy ~= nil then
                    ____opt_result_135 = enemy.x
                end
                local ____opt_result_135_136 = ____opt_result_135
                if ____opt_result_135_136 == nil then
                    ____opt_result_135_136 = s.world.hero.x
                end
                local ____opt_result_139
                if enemy ~= nil then
                    ____opt_result_139 = enemy.y
                end
                local ____opt_result_139_140 = ____opt_result_139
                if ____opt_result_139_140 == nil then
                    ____opt_result_139_140 = 0
                end
                local lit = ____self_142_lightActor_143(____self_142, ____self_actorSurface_141, {
                    x = ____opt_result_135_136,
                    y = ____opt_result_139_140,
                    anchor = anchor,
                    facing = facing,
                    enemy = not not enemy
                })
                g:drawImage(lit, -anchor[1], -anchor[2])
            end
            g:restore()
        end
    else
        self:placeholder(
            x,
            y,
            motion,
            t,
            facing,
            not not enemy
        )
    end
    local ____opt_result_146
    if enemy ~= nil then
        ____opt_result_146 = enemy.ability
    end
    if ____opt_result_146 == "thunder" then
        do
            local i = 0
            while i < 3 do
                self:rect(
                    x - 9 + i * 8,
                    y - 30 + math.sin(self.time * 8 + i) * 8,
                    2,
                    3,
                    "#a9d5ca",
                    0.6
                )
                i = i + 1
            end
        end
    else
        local ____opt_result_149
        if enemy ~= nil then
            ____opt_result_149 = enemy.ability
        end
        if ____opt_result_149 == "binding" then
            self:line({
                x - 13,
                y,
                x - 18,
                y - 17,
                x - 12,
                y - 26
            }, P.bone, 1, 0.5)
        end
    end
    local ____opt_result_152
    if enemy ~= nil then
        ____opt_result_152 = enemy.armor
    end
    local ____opt_result_152_153 = ____opt_result_152
    if ____opt_result_152_153 == nil then
        ____opt_result_152_153 = 0
    end
    if ____opt_result_152_153 > 0 and enemy.broken <= 0 then
        self:rect(
            x - 10,
            y - 43,
            20 * clamp(enemy.armor / 0.45),
            1,
            "#a4a78c",
            0.7
        )
    end
    local ____opt_result_156
    if enemy ~= nil then
        ____opt_result_156 = enemy.burn
    end
    local ____opt_result_156_157 = ____opt_result_156
    if ____opt_result_156_157 == nil then
        ____opt_result_156_157 = 0
    end
    if ____opt_result_156_157 > 0 then
        do
            local i = 0
            while i < 3 do
                self:flame(x - 5 + i * 5, y - 19 + i % 2 * 6, 6, i + 1)
                i = i + 1
            end
        end
    end
    local ____opt_result_160
    if enemy ~= nil then
        ____opt_result_160 = enemy.broken
    end
    local ____opt_result_160_161 = ____opt_result_160
    if ____opt_result_160_161 == nil then
        ____opt_result_160_161 = 0
    end
    if ____opt_result_160_161 > 0 then
        self:line({
            x - 9,
            y - 31,
            x - 4,
            y - 27,
            x - 8,
            y - 22
        }, "#e1d6af", 1, 0.8)
        self:rect(
            x - 4,
            y - 47,
            8,
            1,
            P.hot,
            0.85
        )
    end
    local ____opt_result_164
    if enemy ~= nil then
        ____opt_result_164 = enemy.shield
    end
    local ____opt_result_164_165 = ____opt_result_164
    if ____opt_result_164_165 == nil then
        ____opt_result_164_165 = 0
    end
    if ____opt_result_164_165 > 0 then
        self:line({
            x - 13,
            y - 7,
            x - 15,
            y - 27,
            x - 8,
            y - 38
        }, P.bone, 2, 0.75)
    end
    local ____opt_result_168
    if enemy ~= nil then
        ____opt_result_168 = enemy.ability
    end
    if ____opt_result_168 == "stone" and enemy.broken <= 0 then
        local open = enemy.attackStage == "stone-open"
        local offset = open and 7 or 0
        for ____, side in ipairs({-1, 1}) do
            local sx = x + side * offset
            self:poly({
                sx + side * 5,
                y - 44,
                sx + side * 14,
                y - 33,
                sx + side * 15,
                y - 10,
                sx + side * 7,
                y - 6,
                sx + side * 3,
                y - 26
            }, side < 0 and "#505d58" or "#7b8170", 0.86)
            self:line({
                sx + side * 5,
                y - 39,
                sx + side * 9,
                y - 29,
                sx + side * 6,
                y - 20
            }, open and P.fire or "#abb29a", 1, open and 0.9 or 0.45)
        end
    end
end
function GameRenderer.prototype.statusEffects(self, s, x, y)
    local b = s.buffs
    if b.bound > 0 then
        do
            local i = 0
            while i < 3 do
                self:line({
                    x - 15,
                    y - 2 - i * 3,
                    x - 6,
                    y - 7 - i * 2,
                    x + 6,
                    y - 2 - i * 3,
                    x + 14,
                    y - 9
                }, P.bone, 1, 0.7)
                i = i + 1
            end
        end
    end
    if b.shield > 0 then
        self:line({
            x - 12,
            y - 3,
            x - 16,
            y - 20,
            x - 11,
            y - 39,
            x - 6,
            y - 43
        }, P.fire, 1, 0.65)
    end
    if b.reflect > 0 then
        self:line({
            x + 10,
            y - 3,
            x + 15,
            y - 17,
            x + 13,
            y - 32,
            x + 8,
            y - 40
        }, P.bone, 2, 0.8)
        self:rect(
            x + 15,
            y - 22,
            2,
            4,
            P.hot,
            0.8
        )
    end
    if b.deathguard > 0 then
        self:line({
            x - 9,
            y - 47,
            x - 7,
            y - 50,
            x - 3,
            y - 48,
            x + 1,
            y - 50,
            x + 6,
            y - 47
        }, P.hot, 1, 0.8)
        self:glow(
            x,
            y - 45,
            10,
            P.hot,
            0.1
        )
    end
end
function GameRenderer.prototype.placeholder(self, x, y, m, t, f, enemy)
    local g = self.g
    g:save()
    g:translate(
        math.floor(x + 0.5),
        math.floor(y + 0.5)
    )
    g:scale(f, 1)
    local body = enemy and "#686e59" or "#292b25"
    local lit = enemy and "#a3a084" or "#6f5942"
    if m == "crawl" or m == "fallen" then
        self:rect(
            -18,
            -11,
            22,
            8,
            body
        )
        self:rect(
            3,
            -14,
            8,
            8,
            lit
        )
        self:line({
            -14,
            -7,
            -24,
            -4,
            -28,
            -1
        }, body, 4)
        self:line({
            -1,
            -8,
            10,
            -5,
            14,
            -1
        }, lit, 3)
    else
        local stride = __TS__ArrayIncludes({"walk", "run"}, m) and math.sin(t * 12) * 7 or 0
        self:line({
            -3,
            -20,
            -4 + stride,
            -10,
            -6 + stride,
            0
        }, body, 5)
        self:line({
            4,
            -20,
            5 - stride,
            -10,
            7 - stride,
            0
        }, lit, 4)
        self:rect(
            -7,
            -35,
            14,
            18,
            body
        )
        if m ~= "headless" then
            self:rect(
                -5,
                -43,
                10,
                10,
                lit
            )
        end
        local punch = __TS__StringStartsWith(m, "attack") and 15 or 0
        self:line({
            5,
            -32,
            10 + punch,
            -24,
            10 + punch,
            -19
        }, lit, 4)
        self:line({
            -5,
            -31,
            -10,
            -24,
            -8,
            -18
        }, body, 4)
        self:rect(
            -6,
            -22,
            12,
            3,
            P.rust
        )
    end
    g:restore()
end
function GameRenderer.prototype.flame(self, x, y, size, seed)
    if self.techArt then
        self.techArt.fire:draw(
            self.g,
            x,
            y,
            size,
            self.time,
            seed,
            self.reduced
        )
        return
    end
    if size < 1 then
        return
    end
    local f = math.floor(self.time * 10 + seed)
    local sway = self.reduced and 0 or math.sin(f * 1.7 + seed) * 2
    self:poly({
        x - 3,
        y,
        x - 4,
        y - size * 0.5,
        x + sway - 1,
        y - size,
        x + 2,
        y - size * 0.6,
        x + 4,
        y - 2
    }, P.rust, 0.75)
    self:poly({
        x - 2,
        y,
        x - 1,
        y - size * 0.65,
        x + 1 + sway,
        y - size * 0.85,
        x + 2,
        y - 1
    }, P.fire, 0.9)
    self:rect(
        x - 1,
        y - 3,
        2,
        3,
        P.hot
    )
end
function GameRenderer.prototype.telegraph(self, x, ground, e, s)
    local ____e_heavyIntentRemaining_170 = e.heavyIntentRemaining
    if ____e_heavyIntentRemaining_170 == nil then
        local ____e_attackHeavy_169
        if e.attackHeavy then
            ____e_attackHeavy_169 = e.telegraph
        else
            ____e_attackHeavy_169 = 0
        end
        ____e_heavyIntentRemaining_170 = ____e_attackHeavy_169
    end
    local remaining = ____e_heavyIntentRemaining_170
    if not (remaining > 0) then
        return
    end
    local p = clamp(1 - remaining / 2)
    local hx = s.world.hero.x - s.world.cameraX
    local target = hx
    if e.attackStage == "arrow-flight" then
        local px = x + (hx - x) * p
        self:line({
            px + 8,
            ground - 29,
            px - 3,
            ground - 27,
            px,
            ground - 30
        }, P.bone, 1, 0.95)
        self:line({px + 12, ground - 30, px + 17, ground - 30}, P.bone, 1, 0.3)
        return
    end
    if e.attackStage == "draw" then
        self:line({
            x - 5,
            ground - 37,
            x - 12,
            ground - 27,
            x - 5,
            ground - 16
        }, P.bone, 1, 0.85)
        self:line({
            x - 5,
            ground - 37,
            x - 1 + p * 3,
            ground - 27,
            x - 5,
            ground - 16
        }, P.rust, 1, 0.8)
        return
    end
    if e.attackStage == "binding" then
        local q = s.qte
        local loosen = (q and q.action) == "unbind" and q.progress / #q.pinyin or 0
        self:line({
            x - 8,
            ground - 26,
            (x + hx) / 2,
            ground - 12,
            hx + 4,
            ground - 19
        }, P.bone, q and q.mistakes and 2 or 1, 0.7)
        do
            local i = 0
            while i < 7 do
                if i / 7 >= loosen then
                    local nx = hx + 2 + i % 2 * 4
                    local ny = ground - 6 - i * 3
                    self:line({
                        nx - 5,
                        ny,
                        nx,
                        ny - 3,
                        nx + 5,
                        ny
                    }, P.bone, 1, 0.9)
                end
                i = i + 1
            end
        end
        return
    end
    if e.attackStage == "pyre-line" then
        do
            local i = 0
            while i < 8 do
                local lx = x + (hx - x) * i / 7
                self:rect(
                    lx,
                    ground + 1,
                    4,
                    1,
                    P.fire,
                    0.3 + p * 0.6
                )
                self:flame(lx, ground, 2 + p * 8, i + 41)
                i = i + 1
            end
        end
        return
    end
    if e.attackStage == "thunder-hold" then
        local quiet = clamp((s.elapsed - s.lastStrokeTime) / 0.7)
        local radius = 5 + (1 - quiet) * 10
        self:line({
            hx - radius,
            ground - 2,
            hx,
            ground - 5,
            hx + radius,
            ground - 2
        }, "#a9d5ca", 1, 0.8)
        self:glow(
            hx,
            ground - 23,
            4 + quiet * 4,
            "#9bc9c6",
            0.18
        )
        return
    end
    self:rect(
        target - 17,
        ground - 2,
        34,
        4,
        "#171b19",
        0.9
    )
    self:rect(
        target - 16,
        ground - 1,
        32,
        2,
        "#efad73",
        0.5 + p * 0.5
    )
    do
        local i = 0
        while i < 5 do
            self:rect(
                target - 16 + i * 8,
                ground - 5,
                2,
                3,
                "#f9ca91",
                p
            )
            i = i + 1
        end
    end
    if e.ability == "thunder" then
        self:line({
            target - 3,
            ground - 70,
            target + 2,
            ground - 50,
            target - 2,
            ground - 36
        }, "#afd0c6", 1, p * 0.6)
    elseif e.ability == "stone" then
        self:line({
            target - 15,
            ground + 2,
            target - 3,
            ground - 2,
            target + 4,
            ground + 3,
            target + 16,
            ground
        }, "#dfba84", 1, 0.7)
    end
end
function GameRenderer.prototype.committedAttacks(self, s, camera, ground)
    for ____, hit in ipairs(s.pendingEnemyHits) do
        do
            if not hit.committed then
                goto __continue213
            end
            local ____hit_sourceX_177 = hit.sourceX
            if ____hit_sourceX_177 == nil then
                local ____opt_175 = s.enemy
                ____hit_sourceX_177 = ____opt_175 and ____opt_175.x
            end
            local source = (____hit_sourceX_177 or s.world.hero.x + 30) - camera
            local target = (hit.targetX or s.world.hero.x) - camera
            if hit.ability == "arrow" or hit.ability == "ranged" then
                local p = clamp(1 - hit.remaining / 0.5)
                local x = source + (target - source) * p
                local d = __TS__MathSign(target - source) or -1
                self:line({
                    x - d * 10,
                    ground - 25,
                    x + d * 3,
                    ground - 25,
                    x,
                    ground - 28
                }, "#171b19", hit.heavy and 4 or 3, 0.95)
                self:line({
                    x - d * 10,
                    ground - 25,
                    x + d * 3,
                    ground - 25,
                    x,
                    ground - 28
                }, P.bone, hit.heavy and 2 or 1, 0.95)
            elseif hit.ability == "thunder" then
                self:line({
                    target - 13,
                    ground - 2,
                    target,
                    ground - 5,
                    target + 13,
                    ground - 2
                }, "#171b19", 4, 0.95)
                self:line({
                    target - 13,
                    ground - 2,
                    target,
                    ground - 5,
                    target + 13,
                    ground - 2
                }, "#d8e5cf", 2, 0.9)
                self:line({
                    target - 3,
                    ground - 73,
                    target + 4,
                    ground - 58,
                    target,
                    ground - 43
                }, "#9dc5c1", 1, 0.7)
            elseif hit.ability == "pyre-combo" or hit.ability == "ground-fire" or hit.ability == "pyre-line" then
                self:rect(
                    target - 21,
                    ground - 3,
                    42,
                    4,
                    "#171b19",
                    0.95
                )
                self:rect(
                    target - 20,
                    ground - 2,
                    40,
                    2,
                    P.bone,
                    0.9
                )
                do
                    local j = 0
                    while j < 5 do
                        self:rect(
                            target - 17 + j * 8,
                            ground - 5,
                            2,
                            2,
                            P.rust,
                            0.9
                        )
                        j = j + 1
                    end
                end
            end
        end
        ::__continue213::
    end
end
function GameRenderer.prototype.event(self, e, s)
    local ____e_x_180 = e.x
    if ____e_x_180 == nil then
        local ____opt_178 = s.enemy
        ____e_x_180 = ____opt_178 and ____opt_178.x
    end
    local ____e_x_180_183 = ____e_x_180
    if ____e_x_180_183 == nil then
        local ____opt_181 = s.world
        ____e_x_180_183 = ____opt_181 and ____opt_181.hero.x
    end
    local x = ____e_x_180_183 or 55
    local y = e.y or 0
    if __TS__ArrayIncludes({"kill", "enemy-attack", "parry"}, e.type) then
        self.atmosphere:event({
            id = e.id,
            type = e.type,
            x = x,
            y = y,
            skill = e.skill,
            direction = s.world.hero.facing,
            enemyId = e.enemyId,
            heavy = e.heavy == true
        })
    end
    if e.type == "kill" and self.lastEnemy and self.lastEnemy.id == e.enemyId then
        local ____self_dissolving_184 = self.dissolving
        ____self_dissolving_184[#____self_dissolving_184 + 1] = {
            enemy = __TS__ObjectAssign({}, self.lastEnemy, {
                x = x,
                hp = 0,
                burn = 0,
                telegraph = 0,
                armor = 0,
                shield = 0,
                broken = 0
            }),
            age = 0
        }
        self.lastEnemy = nil
    end
    if (e.type == "stroke" or e.type == "input") and e.rewarded ~= false then
        self.keyPulse = 0.16
        local shape = heroForm(s)
        local height = shape.form == "ember" and 8 or (shape.form == "wraith" and 17 or 28)
        local ____self_fx_188 = self.fx
        local ____s_world_hero_x_186 = s.world.hero.x
        local ____e_id_187 = e.id
        local ____e_combo_185 = e.combo
        if ____e_combo_185 == nil then
            ____e_combo_185 = s.beat.combo
        end
        ____self_fx_188[#____self_fx_188 + 1] = {
            type = "stroke",
            x = ____s_world_hero_x_186,
            y = height,
            age = 0,
            life = 0.27,
            seed = ____e_id_187,
            level = 1,
            combo = __TS__Number(____e_combo_185)
        }
    end
    if e.type == "attack" and e.source == "stroke" then
        local shape = heroForm(s)
        local ____self_fx_193 = self.fx
        local ____x_190 = x
        local ____temp_191 = shape.form == "ember" and 7 or (shape.form == "wraith" and 17 or 28)
        local ____e_id_192 = e.id
        local ____e_targetX_189 = e.targetX
        if ____e_targetX_189 == nil then
            ____e_targetX_189 = x + 25
        end
        ____self_fx_193[#____self_fx_193 + 1] = {
            type = "attack",
            x = ____x_190,
            y = ____temp_191,
            age = 0,
            life = 0.23,
            seed = ____e_id_192,
            level = 1,
            targetX = __TS__Number(____e_targetX_189),
            combo = s.beat.combo,
            direction = s.world.hero.facing,
            body = shape.body
        }
    end
    if e.type == "impact" and e.enemyId and type(e.amount) == "number" then
        return
    end
    if e.type == "hit" and __TS__Number(e.amount or 0) <= 0 then
        return
    end
    if e.type == "qte" and e.stage ~= "success" then
        return
    end
    if e.type == "enemy-attack" and e.ability == "arrow" then
        return
    end
    if __TS__ArrayIncludes({
        "hit",
        "impact",
        "skill",
        "environment",
        "qte",
        "semantic",
        "fall",
        "respawn",
        "frenzy",
        "break",
        "enemy-attack",
        "player-hit",
        "deathguard",
        "boss-phase",
        "defense",
        "guard",
        "parry",
        "surge",
        "self-cost",
        "interrupt"
    }, e.type) then
        local ____self_fx_209 = self.fx
        local ____e_type_198 = e.type
        local ____e_enemyId_199 = e.enemyId
        local ____x_200 = x
        local ____y_201 = y
        local ____temp_202 = e.type == "hit" and (e.skill and 0.4 or 0.28) or (e.type == "skill" and 1.15 or ((e.type == "environment" or e.type == "deathguard") and 1 or (e.type == "enemy-attack" and 0.6 or 0.55)))
        local ____e_skill_203 = e.skill
        local ____e_id_204 = e.id
        local ____e_level_194 = e.level
        if ____e_level_194 == nil then
            ____e_level_194 = e.skill and s.skills[e.skill] or 1
        end
        local ____TS__Number_result_205 = __TS__Number(____e_level_194)
        local ____e_ability_195 = e.ability
        if ____e_ability_195 == nil then
            ____e_ability_195 = ""
        end
        local ____tostring_result_206 = tostring(____e_ability_195)
        local ____temp_207 = type(e.targetX) == "number" and e.targetX or nil
        local ____e_source_196 = e.source
        if ____e_source_196 == nil then
            ____e_source_196 = ""
        end
        local ____tostring_result_208 = tostring(____e_source_196)
        local ____e_stage_197 = e.stage
        if ____e_stage_197 == nil then
            ____e_stage_197 = ""
        end
        ____self_fx_209[#____self_fx_209 + 1] = {
            type = ____e_type_198,
            enemyId = ____e_enemyId_199,
            x = ____x_200,
            y = ____y_201,
            age = 0,
            life = ____temp_202,
            skill = ____e_skill_203,
            seed = ____e_id_204,
            level = ____TS__Number_result_205,
            ability = ____tostring_result_206,
            targetX = ____temp_207,
            source = ____tostring_result_208,
            stage = tostring(____e_stage_197),
            combo = s.beat.combo,
            direction = s.world.hero.facing,
            body = heroForm(s).body,
            amount = __TS__Number(e.amount or 1)
        }
        -- Native feedback tuning: only damage receipts create a contact kick.
        if e.type == "hit" and (e.amount or 0) > 0 then
            self.keyPulse = math.max(self.keyPulse, 0.16)
            self.shake = math.max(self.shake, self.reduced and 0 or (e.skill and 1.25 or 0.75))
        end
        if e.type == "skill" then self.keyPulse = math.max(self.keyPulse, 0.24) end
        if e.type == "parry" or e.type == "interrupt" or e.type == "skill" and e.skill == "nova" then
            self.stop = math.max(self.stop, self.reduced and 0 or 0.065)
            self.shake = math.max(self.shake, self.reduced and 0 or (e.skill == "nova" and 2.4 or 1.8))
        end
    end
end
function GameRenderer.prototype.effects(self, camera, ground, s)
    local wind = self.atmosphere.wind
    for ____, f in ipairs(self.fx) do
        do
            local x = f.x - camera
            local y = ground - f.y
            local p = f.age / f.life
            if f.type == "skill" then
                if f.skill ~= "oath" then
                    local shape = heroForm(s)
                    local head = s.headthrow
                    local ____drawSkillFlame_220 = drawSkillFlame
                    local ____self_g_219 = self.g
                    local ____temp_212 = f.skill or ""
                    local ____f_age_213 = f.age
                    local ____f_life_214 = f.life
                    local ____f_level_215 = f.level
                    local ____f_seed_216 = f.seed
                    local ____x_217 = x
                    local ____ground_218 = ground
                    local ____temp_211
                    if f.skill == "headthrow" and head then
                        ____temp_211 = head.targetX - camera
                    else
                        local ____temp_210
                        if f.targetX == nil then
                            ____temp_210 = nil
                        else
                            ____temp_210 = f.targetX - camera
                        end
                        ____temp_211 = ____temp_210
                    end
                    ____drawSkillFlame_220(
                        ____self_g_219,
                        {
                            skill = ____temp_212,
                            age = ____f_age_213,
                            life = ____f_life_214,
                            level = ____f_level_215,
                            seed = ____f_seed_216,
                            x = ____x_217,
                            y = ____ground_218,
                            targetX = ____temp_211,
                            direction = f.direction or 1,
                            body = shape.body,
                            form = shape.form,
                            reduced = self.reduced,
                            wind = {x = wind.x * 0.1, y = wind.y * 0.1},
                            origin = f.skill == "headthrow" and head and ({x = head.headX - camera, y = ground - head.headY}) or self.strikeMount,
                            pulse = clamp(self.keyPulse / 0.16)
                        }
                    )
                end
                goto __continue233
            end
            if f.type == "stroke" then
                local vigor = 1 + math.min(1, (f.combo or 0) / 18)
                local count = self.reduced and 2 or 5
                do
                    local i = 0
                    while i < count do
                        local side = i % 2 ~= 0 and 1 or -1
                        local spread = (3 + i * 1.8) * p * vigor
                        self:rect(
                            x + side * spread,
                            y - 2 - p * (7 + i * 2),
                            i % 3 ~= 0 and 1 or 2,
                            2,
                            P.hot,
                            (1 - p) * 0.85
                        )
                        i = i + 1
                    end
                end
                goto __continue233
            end
            if f.type == "attack" then
                local target = (f.targetX or f.x + 25) - camera
                local direction = f.direction or 1
                local vigor = math.min(1, (f.combo or 0) / 20)
                local a = (1 - p) * (self.reduced and 0.35 or 0.9)
                local cy = ground - f.y
                if (f.body or 1) <= 67 / 12167 then
                    self:flame(
                        x + direction * 5,
                        cy + 1,
                        4 + math.sin(p * math.pi) * 8,
                        f.seed
                    )
                    self:line({x + direction * 3, cy, x + direction * (7 + p * 9), cy - 2}, P.hot, 1, a)
                    goto __continue233
                end
                local hand = x + direction * 7
                local reach = target - direction * 4
                local lift = (f.seed % 2 ~= 0 and 1 or -1) * (3 + vigor * 4)
                self:poly({
                    hand,
                    cy + 4,
                    hand + direction * 8,
                    cy - 3 - lift,
                    reach,
                    cy - 3,
                    reach + direction * 4,
                    cy + 1,
                    hand + direction * 9,
                    cy + 3 + lift
                }, P.rust, a * 0.8)
                self:line({
                    hand,
                    cy + 1,
                    hand + (reach - hand) * 0.45,
                    cy - lift,
                    reach,
                    cy
                }, P.fire, 2, a)
                self:line({hand + direction * 5, cy + 1, reach - direction * 3, cy - 1}, P.hot, 1, a * 0.9)
                goto __continue233
            end
            if f.type == "hit" then
                local strong = not not f.skill or f.source == "reflect"
                local vigor = math.min(1, (f.combo or 0) / 20)
                local a = 1 - p
                local core = strong and 8 or 4 + vigor * 2
                local burst = core + p * (strong and 32 or 19)
                local cy = f.y ~= 0 and y or y - 23
                if p < 0.38 then
                    self:poly({
                        x - core * 2,
                        cy,
                        x - core * 0.35,
                        cy - core * 0.5,
                        x,
                        cy - core * 2.4,
                        x + core * 0.4,
                        cy - core * 0.4,
                        x + core * 2,
                        cy,
                        x + core * 0.4,
                        cy + core * 0.45,
                        x,
                        cy + core * 1.8,
                        x - core * 0.4,
                        cy + core * 0.4
                    }, P.hot, a)
                    self:glow(
                        x,
                        cy,
                        core * 4,
                        P.fire,
                        a * 0.17
                    )
                end
                local count = self.reduced and 4 or (strong and 12 or 8)
                do
                    local i = 0
                    while i < count do
                        local angle = hash(i + f.seed) * math.pi * 2
                        local dx = math.cos(angle)
                        local dy = math.sin(angle)
                        local r = burst * (0.55 + hash(i + 79) * 0.65)
                        self:line({x + dx * r * 0.45, cy + dy * r * 0.45, x + dx * r, cy + dy * r}, i % 3 ~= 0 and P.fire or P.hot, i % 4 ~= 0 and 1 or 2, a)
                        i = i + 1
                    end
                end
                if strong and not self.reduced then
                    self.g:save()
                    self.g.globalAlpha = a * 0.45
                    self.g.strokeStyle = P.hot
                    self.g.lineWidth = 1
                    self.g:beginPath()
                    self.g:ellipse(
                        x,
                        cy,
                        burst,
                        burst * 0.5,
                        0,
                        0,
                        math.pi * 2
                    )
                    self.g:stroke()
                    self.g:restore()
                end
                goto __continue233
            end
            if f.type == "enemy-attack" then
                local target = (f.targetX or f.x) - camera
                local a = 1 - p
                if f.ability == "thunder" then
                    local phase = math.floor(p * 5)
                    self:line({
                        target - 3,
                        ground - 90,
                        target + 6,
                        ground - 67,
                        target - 3 + phase,
                        ground - 49,
                        target + 5,
                        ground - 30,
                        target,
                        ground
                    }, P.hot, 2, a)
                    self:line({
                        target - 2,
                        ground - 86,
                        target + 9,
                        ground - 60,
                        target - 5,
                        ground - 36,
                        target,
                        ground
                    }, "#91c9c5", 1, a)
                    self:glow(
                        target,
                        ground - 7,
                        21,
                        "#92c6c7",
                        a * 0.16
                    )
                elseif f.ability == "stone" then
                    do
                        local i = 0
                        while i < 5 do
                            local px = target - 22 + i * 11
                            local hh = math.sin(math.min(1, p * 2) * math.pi) * (8 + i % 3 * 6)
                            self:poly({
                                px - 5,
                                ground,
                                px - 2,
                                ground - hh,
                                px + 2,
                                ground - hh - 3,
                                px + 6,
                                ground
                            }, i % 2 ~= 0 and "#778780" or "#a4ab94", a)
                            i = i + 1
                        end
                    end
                elseif f.ability == "binding" then
                    do
                        local i = 0
                        while i < 3 do
                            self:line({
                                x,
                                ground - 25,
                                target - 12,
                                ground - 4 - i * 6,
                                target + 8,
                                ground - 14 - i * 5,
                                target - 9,
                                ground - 22 - i * 4
                            }, P.bone, 1, a)
                            i = i + 1
                        end
                    end
                elseif f.ability == "ranged" or f.ability == "arrow" then
                    local px = x + (target - x) * math.min(1, p * 2.5)
                    self:line({
                        px + 10,
                        ground - 27,
                        px,
                        ground - 24,
                        px + 3,
                        ground - 27
                    }, P.bone, 1, a)
                elseif f.ability == "pyre" or f.ability == "pyre-combo" then
                    do
                        local i = 0
                        while i < 7 do
                            self:flame(
                                target - 20 + i * 7,
                                ground,
                                math.max(0, (1 - p) * 24 - i % 3 * 4),
                                i
                            )
                            i = i + 1
                        end
                    end
                else
                    self:line({
                        x - 7,
                        ground - 35,
                        target + 3,
                        ground - 20,
                        target - 5,
                        ground - 12
                    }, P.bone, 2, a)
                    self:line({target + 7, ground - 30, target - 5, ground - 21}, P.rust, 1, a)
                end
                goto __continue233
            end
            if f.type == "deathguard" then
                do
                    local i = 0
                    while i < 10 do
                        local r = (1 - p) * 22
                        local a = i / 10 * math.pi * 2
                        self:rect(
                            x + math.cos(a) * r,
                            y - 24 + math.sin(a) * r * 1.6,
                            2,
                            2,
                            P.hot,
                            1 - p * 0.6
                        )
                        i = i + 1
                    end
                end
                self:line({
                    x - 12,
                    y - 4,
                    x - 5,
                    y - 22,
                    x + 6,
                    y - 29,
                    x + 2,
                    y - 43
                }, P.hot, 2, 1 - p)
                self:glow(
                    x,
                    y - 22,
                    30,
                    P.hot,
                    (1 - p) * 0.18
                )
                goto __continue233
            end
            if f.type == "player-hit" then
                local cy = ground - ((f.body or 1) <= 67 / 12167 and 7 or ((f.body or 1) < 10115 / 12167 and 17 or 24))
                self:line({x - 5, cy - 3, x + 6, cy + 4}, P.rust, 2, 1 - p)
                do
                    local i = 0
                    while i < 4 do
                        self:rect(
                            x - 5 + hash(i + f.seed) * 11,
                            cy + p * (9 + i),
                            2,
                            2,
                            i % 2 ~= 0 and P.rust or "#2c211d",
                            1 - p
                        )
                        i = i + 1
                    end
                end
                goto __continue233
            end
            if f.type == "guard" or f.type == "parry" then
                local shape = f.type == "parry" and 1.5 or 1
                local xx = x + 9
                local cy = ground - ((f.body or 1) <= 67 / 12167 and 7 or ((f.body or 1) < 10115 / 12167 and 17 or 25))
                local size = (f.body or 1) <= 67 / 12167 and 0.42 or ((f.body or 1) < 10115 / 12167 and 0.7 or 1)
                self:line({
                    xx - 1,
                    cy + 15 * size,
                    xx + 4,
                    cy + 3 * size,
                    xx + 3,
                    cy - 12 * size,
                    xx - 2,
                    cy - 19 * size
                }, f.type == "parry" and P.bone or P.fire, shape * (1 - p) + 1, 1 - p)
                if f.type == "parry" then
                    self:line({xx - 8, cy + 4, xx + 18 + p * 11, cy - 3}, P.hot, 2, 1 - p)
                    self:glow(
                        xx,
                        cy + 2,
                        22,
                        P.fire,
                        (1 - p) * 0.18
                    )
                end
                goto __continue233
            end
            if f.type == "self-cost" then
                local cy = ground - ((f.body or 1) <= 67 / 12167 and 7 or ((f.body or 1) < 10115 / 12167 and 17 or 24))
                do
                    local i = 0
                    while i < 6 do
                        self:rect(
                            x - 9 + hash(f.seed + i) * 18,
                            cy + p * 18,
                            1,
                            2,
                            P.rust,
                            1 - p
                        )
                        i = i + 1
                    end
                end
                goto __continue233
            end
            if f.type == "surge" then
                self:line({
                    x - 9,
                    y - 1,
                    x - 6,
                    y - 12,
                    x - 3,
                    y - 23
                }, P.hot, 1, 1 - p)
                goto __continue233
            end
            if f.type == "hit" and f.source == "reflect" then
                self:line({
                    x - 8,
                    y + 4,
                    x + 4,
                    y - 9,
                    x + 12,
                    y - 3
                }, P.bone, 2, 1 - p)
            end
            do
                local i = 0
                while i < 9 do
                    local angle = hash(i + f.seed) * math.pi * 2
                    local r = (5 + hash(i + 81) * 20) * p
                    self:rect(
                        x + math.cos(angle) * r,
                        (f.y ~= 0 and y or y - 20) + math.sin(angle) * r + p * p * 7,
                        i % 4 ~= 0 and 1 or 2,
                        i % 3 ~= 0 and 2 or 1,
                        i % 3 ~= 0 and P.fire or P.hot,
                        1 - p
                    )
                    i = i + 1
                end
            end
            if f.type == "environment" then
                do
                    local i = 0
                    while i < 7 do
                        self:rect(
                            x + (hash(i) * 2 - 1) * p * 28,
                            y - 3 - math.sin(p * math.pi) * (4 + hash(i + 4) * 15),
                            3,
                            2,
                            "#8a7955",
                            1 - p
                        )
                        i = i + 1
                    end
                end
            end
        end
        ::__continue233::
    end
end
function GameRenderer.prototype.foreground(self, camera, ground)
    if self.sceneMeta then
        for ____, layer in __TS__Iterator(self.sceneMeta.layers) do
            if __TS__StringIncludes(layer.image, "near") then
                self:sceneLayer(layer, camera, ground)
            end
        end
        return
    end
    do
        local i = math.floor(camera * 0.95 / 29) - 1
        while i < (camera * 0.95 + self.width) / 29 + 1 do
            local x = i * 29 - camera * 0.95
            local y = ground + 15 + hash(i + 4) * 11
            self:line({
                x - 6,
                y,
                x - 9,
                y - 15,
                x - 3,
                y - 4,
                x,
                y - 21,
                x + 2,
                y,
                x + 7,
                y - 13
            }, "#101e1b", 2)
            i = i + 1
        end
    end
end
function GameRenderer.prototype.sceneLayer(self, layer, camera, ground)
    local image = self.images:get("scene." .. tostring(layer.image))
    if not image then
        return
    end
    local width = image.width
    local offset = camera * layer.parallax
    local start = math.floor(offset / width) - 1
    do
        local i = start
        while i * width - offset < self.width do
            local x = math.floor(i * width - offset + 0.5)
            local y = math.floor(ground + layer.baselineOffset + 0.5)
            self.g:drawImage(image, x, y)
            if __TS__StringIncludes(layer.image, "ground") or __TS__StringIncludes(layer.image, "near") then
                self:markSurface(image, x, y)
            end
            i = i + 1
        end
    end
end
function GameRenderer.prototype.scenery(self, camera, ground, s)
    ---@type any[][][]
    local groups = {{{24, "shrub", -4}, {53, "grass-small", -3}, {163, "lowrock", -3}}, {{45, "tent", -14}, {92, "grass-medium", -4}, {220, "charred-tree", -5}}, {{11, "grass-large", -4}, {139, "tent-burned", -9}, {237, "shrub", -4}}, {{65, "lowrock", -4}, {100, "grass-medium", -3}, {242, "charred-tree", -7}}}
    local spacing = 312
    local offset = camera
    do
        local chunk = math.floor(offset / spacing) - 1
        while chunk * spacing - offset < self.width do
            for ____, ____value in ipairs(groups[(chunk % 4 + 4) % 4 + 1] --[[@as any[][] ]]) do
                local dx = ____value[1]
                local kind = ____value[2]
                local dy = ____value[3]
                do
                    local name = s.chapter == 1 and kind == "tent" and "tent-burned" or kind
                    local ____opt_221 = self.propsMeta.props
                    if ____opt_221 ~= nil then
                        ____opt_221 = ____opt_221[name]
                    end
                    local meta = ____opt_221
                    local image = self.images:get("prop." .. name)
                    local x = chunk * spacing + dx - offset
                    if not image or not meta or x < -90 or x > self.width + 90 then
                        goto __continue293
                    end
                    self.g:drawImage(
                        image,
                        math.floor(x - meta.root[1] + 0.5),
                        math.floor(ground + dy - meta.root[2] + 0.5)
                    )
                    self:markSurface(image, x - meta.root[1], ground + dy - meta.root[2])
                end
                ::__continue293::
            end
            chunk = chunk + 1
        end
    end
end
function GameRenderer.prototype.campBackdrop(self, camera, ground, s)
    local spacing = 245
    local offset = camera * 0.28
    local y = ground - 17
    local color = s.chapter > 2 and "#202c2c" or "#2b3838"
    do
        local chunk = math.floor(offset / spacing) - 1
        while chunk * spacing - offset < self.width + 100 do
            local x = chunk * spacing - offset + 115
            local kind = (chunk % 4 + 4) % 4
            if kind == 0 or s.chapter == 4 then
                local h = 57 + hash(chunk + 11) * 13
                self:line({
                    x - 13,
                    y,
                    x - 10,
                    y - h,
                    x + 12,
                    y - h - 3,
                    x + 15,
                    y
                }, color, 3, 0.8)
                self:line({
                    x - 12,
                    y - 13,
                    x + 13,
                    y - 31,
                    x - 10,
                    y - 45,
                    x + 12,
                    y - h + 7
                }, color, 2, 0.72)
                self:poly({
                    x - 18,
                    y - h - 3,
                    x + 16,
                    y - h - 8,
                    x + 21,
                    y - h - 1,
                    x - 20,
                    y - h + 3
                }, color, 0.9)
                self:line({x + 4, y - h, x + 5, y - h - 19}, color, 2, 0.8)
                self:poly({
                    x + 5,
                    y - h - 19,
                    x + 30,
                    y - h - 15,
                    x + 22,
                    y - h - 9,
                    x + 26,
                    y - h - 6,
                    x + 5,
                    y - h - 10
                }, color, 0.7)
            elseif kind == 1 then
                do
                    local i = 0
                    while i < 5 do
                        local bx = x - 27 + i * 14
                        self:line({
                            bx,
                            y,
                            bx + 2,
                            y - 27 - i % 2 * 9,
                            bx + 9,
                            y - 43 - i % 3 * 3
                        }, color, 2, 0.7)
                        i = i + 1
                    end
                end
                self:line({
                    x - 35,
                    y - 8,
                    x - 20,
                    y - 22,
                    x + 15,
                    y - 16,
                    x + 36,
                    y - 6
                }, color, 2, 0.7)
            else
                self:poly({
                    x - 37,
                    y,
                    x - 23,
                    y - 20,
                    x - 9,
                    y - 25,
                    x + 22,
                    y - 16,
                    x + 34,
                    y
                }, color, 0.65)
                self:line({
                    x - 12,
                    y - 24,
                    x - 10,
                    y - 35,
                    x - 2,
                    y - 36
                }, color, 1, 0.7)
                self:poly({
                    x - 11,
                    y - 27,
                    x + 18,
                    y - 18,
                    x + 13,
                    y - 13,
                    x - 8,
                    y - 19
                }, "#47514b", 0.35)
            end
            chunk = chunk + 1
        end
    end
end
function GameRenderer.prototype.embers(self, ground)
    do
        local i = 0
        while i < 16 do
            local x = (hash(i) * self.width + self.time * (2 + hash(i + 2) * 4)) % (self.width + 6) - 3
            local y = ((hash(i + 3) * ground - self.time * (1 + hash(i + 8) * 3)) % ground + ground) % ground
            self:rect(
                x,
                y,
                1,
                i % 3 ~= 0 and 1 or 2,
                i % 4 ~= 0 and P.bone or P.fire,
                i % 4 ~= 0 and 0.14 or 0.5
            )
            i = i + 1
        end
    end
end
__TS__SetDescriptor(
    GameRenderer.prototype,
    "hitStopped",
    {get = function(self)
        return self.stop > 0
    end},
    true
)
__TS__SetDescriptor(
    GameRenderer.prototype,
    "heroAttachment",
    {get = function(self)
        return self.attachment
    end},
    true
)
__TS__SetDescriptor(
    GameRenderer.prototype,
    "diagnostics",
    {get = function(self)
        local ____self_lastRenderMs_227 = self.lastRenderMs
        local ____opt_223 = self.inferno
        local ____temp_228 = ____opt_223 and ____opt_223:diagnostics()
        local ____opt_225 = self.actorBurning
        return {
            renderMs = ____self_lastRenderMs_227,
            world = ____temp_228,
            actor = ____opt_225 and ____opt_225:diagnostics(),
            atmosphere = self.atmosphere:diagnostics()
        }
    end},
    true
)
__TS__SetDescriptor(
    GameRenderer.prototype,
    "geometry",
    {get = function(self)
        return {
            width = self.width,
            height = self.height,
            scale = self.scale,
            dpr = self.dpr,
            ground = math.floor(self.height * 0.69 + 0.5)
        }
    end},
    true
)
return ____exports
