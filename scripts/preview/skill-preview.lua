local ____lualib = require("preview.lualib_bundle")
local __TS__NumberIsFinite = ____lualib.__TS__NumberIsFinite
local __TS__MathTrunc = ____lualib.__TS__MathTrunc
local __TS__ArrayIndexOf = ____lualib.__TS__ArrayIndexOf
local __TS__ArraySome = ____lualib.__TS__ArraySome
local Error = ____lualib.Error
local RangeError = ____lualib.RangeError
local ReferenceError = ____lualib.ReferenceError
local SyntaxError = ____lualib.SyntaxError
local TypeError = ____lualib.TypeError
local URIError = ____lualib.URIError
local __TS__New = ____lualib.__TS__New
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__ArrayPush = ____lualib.__TS__ArrayPush
local __TS__ObjectAssign = ____lualib.__TS__ObjectAssign
local __TS__Class = ____lualib.__TS__Class
local ____exports = {}
local ____compat = require("preview.compat")
local previewStrokeId = ____compat.previewStrokeId
local ____engine = require("core.engine")
local createGame = ____engine.createGame
local castSkill = ____engine.castSkill
local stroke = ____engine.stroke
local tick = ____engine.tick
local ENEMIES = ____engine.ENEMIES
local ENCOUNTERS = ____engine.ENCOUNTERS
local FIXED_STEP = ____engine.FIXED_STEP
local SKILLS = ____engine.SKILLS
local STAGE_WIDTH = 192
local STAGE_HEIGHT = 112
local CAST_AT = 0.45
local CYCLE_LENGTH = 5
local SKILL_ORDER = {
    "spark",
    "headthrow",
    "rebirth",
    "lash",
    "nova",
    "oath"
}
local function rankValue(value)
    return __TS__NumberIsFinite(value) and math.max(
        0,
        math.min(
            3,
            __TS__MathTrunc(value)
        )
    ) or 0
end
function ____exports.previewScenario(selected)
    if selected == "rebirth" then
        return "低生命 · 同样敲键，比较立即续身"
    end
    if selected == "oath" then
        return "受缚低生命 · 同样敲键，比较恢复速度"
    end
    if selected == "nova" then
        return "付出身体 · 点燃同一目标与地面"
    end
    if selected == "lash" then
        return "同一石壳与护盾"
    end
    if selected == "headthrow" then
        return "同一落点 · 重组后接续攻击"
    end
    return "同一目标 · 观察伤口与后续命中"
end
--- A controlled arena, deliberately independent of player progress and storage.
function ____exports.createPreviewState(selected, rank)
    local index = __TS__ArrayIndexOf(SKILL_ORDER, selected)
    if index < 0 or not __TS__ArraySome(
        SKILLS,
        function(____, skill) return skill.id == selected end
    ) then
        error(
            __TS__New(Error, "未知的预览技能。"),
            0
        )
    end
    local s = createGame(5351168 + index)
    local encounterIndex = selected == "lash" and 5 or 2
    local encounter = ENCOUNTERS[encounterIndex + 1]
    local definition = __TS__ArrayFind(
        ENEMIES,
        function(____, enemy) return enemy.id == encounter.enemyId end
    )
    local defensive = selected == "rebirth" or selected == "oath"
    s.phase = "combat"
    s.chapter = encounter.chapter
    s.encounterIndex = encounterIndex
    s.encounterStyle = "hold"
    s.encounterStage = "active"
    s.autoWalk = false
    s.paused = false
    s.inputContext = "free"
    s.qte = nil
    s.frenzyCooldown = 100
    s.rage = 100
    s.heat = selected == "nova" and 78 or 24
    s.combat.surgeCooldown = 100
    s.resolve = defensive and 32 or 70
    s.world.props = {}
    s.world.hero = {
        x = 55,
        y = 0,
        vx = 0,
        facing = 1,
        motion = "idle",
        actionTime = 0
    }
    s.world.cameraX = 0
    s.world.previousCameraX = 0
    s.world.checkpointX = 55
    s.skills[selected] = rank
    s.equipped = {selected}
    s.autoAttackTimer = selected == "headthrow" and 1.8 or 100
    __TS__ArrayPush(s.completedMilestones, ("combat-qte:" .. encounter.id) .. ":1", "first-shoulder-hit")
    local enemyX = selected == "headthrow" and 155 or (selected == "lash" and 128 or 96)
    s.enemy = __TS__ObjectAssign({}, definition, {
        id = encounter.id,
        definitionId = definition.id,
        maxHp = 520,
        hp = selected == "nova" and 520 * 0.22 or 520,
        phase = 1,
        x = enemyX,
        y = 0,
        vx = 0,
        facing = -1,
        motion = "idle",
        actionTime = 0,
        attackTimer = 100,
        attackInterval = 100,
        telegraph = 0,
        telegraphTotal = 0.65,
        breakProgress = 0,
        breakThreshold = 6,
        attackMercy = 1,
        shield = selected == "lash" and 12 or 0,
        broken = 0,
        burn = 0,
        burnTick = 0.8,
        fleeing = false
    })
    if selected == "oath" then
        s.buffs.bound = 2
    end
    if defensive then
        __TS__ArrayPush(s.pendingEnemyHits, {remaining = 1.2, amount = 12, ability = definition.ability, enemyId = encounter.id}, {remaining = 3.2, amount = 16, ability = definition.ability, enemyId = encounter.id})
    end
    return s
end
--- Simulation is separately usable by the preview harness; it never owns a player state.
____exports.SkillPreviewSimulation = __TS__Class()
local SkillPreviewSimulation = ____exports.SkillPreviewSimulation
SkillPreviewSimulation.name = "SkillPreviewSimulation"
function SkillPreviewSimulation.prototype.____constructor(self, selected, rank)
    self.selected = selected
    self.cycle = 0
    self.time = 0
    self.accumulator = 0
    self.cast = false
    self.nextStroke = 0.75
    self.rank = rankValue(rank)
    self.scenario = ____exports.previewScenario(selected)
    self.state = ____exports.createPreviewState(selected, self.rank)
end
function SkillPreviewSimulation.prototype.update(self, dt)
    if not __TS__NumberIsFinite(dt) or dt <= 0 then
        return false
    end
    self.accumulator = self.accumulator + math.min(0.1, dt)
    local reset = false
    while self.accumulator + 1e-9 >= FIXED_STEP do
        self.accumulator = math.max(0, self.accumulator - FIXED_STEP)
        self.time = self.time + FIXED_STEP
        if not self.cast and self.time + 1e-9 >= CAST_AT then
            self.cast = true
            if self.rank > 0 and not castSkill(self.state, self.selected) then
                error(
                    __TS__New(Error, "技能预览未能施放。"),
                    0
                )
            end
        end
        if (self.selected == "rebirth" or self.selected == "oath") and self.time + 1e-9 >= self.nextStroke then
            stroke(
                self.state,
                {
                    id = previewStrokeId(self.cycle, self.nextStroke),
                    key = "a",
                    source = "preview"
                }
            )
            self.nextStroke = self.nextStroke + 0.3
        end
        tick(self.state, FIXED_STEP)
        if self.time + 1e-9 >= CYCLE_LENGTH then
            self.state = ____exports.createPreviewState(self.selected, self.rank)
            self.time = 0
            self.cast = false
            self.nextStroke = 0.75
            self.cycle = self.cycle + 1
            reset = true
        end
    end
    return reset
end
return ____exports
