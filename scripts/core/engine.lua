local ____lualib = require("core.lualib_bundle")
local __TS__NumberIsFinite = ____lualib.__TS__NumberIsFinite
local __TS__ObjectAssign = ____lualib.__TS__ObjectAssign
local __TS__ArraySplice = ____lualib.__TS__ArraySplice
local __TS__ArrayIncludes = ____lualib.__TS__ArrayIncludes
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ObjectRest = ____lualib.__TS__ObjectRest
local __TS__SparseArrayNew = ____lualib.__TS__SparseArrayNew
local __TS__SparseArrayPush = ____lualib.__TS__SparseArrayPush
local __TS__SparseArraySpread = ____lualib.__TS__SparseArraySpread
local __TS__ObjectKeys = ____lualib.__TS__ObjectKeys
local __TS__StringEndsWith = ____lualib.__TS__StringEndsWith
local __TS__StringIncludes = ____lualib.__TS__StringIncludes
local __TS__NumberIsInteger = ____lualib.__TS__NumberIsInteger
local __TS__MathTrunc = ____lualib.__TS__MathTrunc
local Set = ____lualib.Set
local __TS__New = ____lualib.__TS__New
local __TS__Spread = ____lualib.__TS__Spread
local __TS__ArraySlice = ____lualib.__TS__ArraySlice
local __TS__ArrayReduce = ____lualib.__TS__ArrayReduce
local __TS__ArraySome = ____lualib.__TS__ArraySome
local ____exports = {}
local emit, rng, phase, motion, gainResolve, gainRage, remember, milestone, reward, context, clearQte, learn, completeProp, beginHeadthrow, performEnvironment, defeatEnemy, attackId, hurtEnemy, igniteWorld, fall, clamp
local ____compat = require("core.compat")
local asciiLetters = ____compat.asciiLetters
local isAsciiKey = ____compat.isAsciiKey
local isPrintableKey = ____compat.isPrintableKey
local isPinyin = ____compat.isPinyin
local hanText = ____compat.hanText
local jsLower = ____compat.jsLower
local jsLength = ____compat.jsLength
local jsSlice = ____compat.jsSlice
local jsCharAt = ____compat.jsCharAt
local jsXorshift = ____compat.jsXorshift
local jsSeed = ____compat.jsSeed
local jsIsArray = ____compat.jsIsArray
local jsNullProperty = ____compat.jsNullProperty
local stableSort = ____compat.stableSort
local jsTruthy = ____compat.jsTruthy
local jsAnd = ____compat.jsAnd
local jsOr = ____compat.jsOr
local ____content = require("core.content")
local BRANCHES = ____content.BRANCHES
local CHAPTERS = ____content.CHAPTERS
local DESIGN_WIDTH = ____content.DESIGN_WIDTH
local ENCOUNTERS = ____content.ENCOUNTERS
local ENEMIES = ____content.ENEMIES
local ENVIRONMENTS = ____content.ENVIRONMENTS
local HERO_SCREEN_X = ____content.HERO_SCREEN_X
local MEMORIES = ____content.MEMORIES
local RUN_SPEED = ____content.RUN_SPEED
local SEMANTIC_THEMES = ____content.SEMANTIC_THEMES
local SKILLS = ____content.SKILLS
local STORIES = ____content.STORIES
local WALK_SPEED = ____content.WALK_SPEED
local ____combat_2Drules = require("core.combat-rules")
local RULES = ____combat_2Drules.COMBAT_RULES
local combatState = ____combat_2Drules.combatState
local createCombatState = ____combat_2Drules.createCombatState
local refreshInferno = ____combat_2Drules.refreshInferno
local strokeRecovery = ____combat_2Drules.strokeRecovery
local ____skill_2Dcommand = require("core.skill-command")
local matchCommand = ____skill_2Dcommand.matchCommand
local commandHint = ____skill_2Dcommand.commandHint
function emit(s, ____type, fields)
    if fields == nil then
        fields = {}
    end
    local ____s_events_3 = s.events
    local ____s_0, ____eventSerial_1 = s, "eventSerial"
    local ____s_eventSerial_2 = ____s_0[____eventSerial_1] + 1
    ____s_0[____eventSerial_1] = ____s_eventSerial_2
    ____s_events_3[#____s_events_3 + 1] = __TS__ObjectAssign({id = ____s_eventSerial_2, type = ____type, t = s.elapsed}, fields)
    if #s.events > 160 then
        __TS__ArraySplice(s.events, 0, #s.events - 160)
    end
end
function rng(s)
    s.rng = jsXorshift(s.rng)
    return s.rng / 4294967296
end
function phase(s, next)
    if s.phase ~= next then
        s.phase = next
        emit(s, "phase", {phase = next, x = s.world.hero.x, y = 0})
    end
end
function motion(actor, next, force)
    if force == nil then
        force = false
    end
    if force or actor.motion ~= next then
        actor.motion = next
        actor.actionTime = 0
    end
end
function gainResolve(s, amount)
    s.resolve = clamp(s.resolve + amount * (s.buffs.bound > 0 and 0.7 or 1), 0, s.maxResolve)
    refreshInferno(s)
end
function gainRage(s, amount)
    s.rage = clamp(s.rage + amount, 0, 100)
    refreshInferno(s)
end
function remember(list, id, max)
    if max == nil then
        max = 256
    end
    if __TS__ArrayIncludes(list, id) then
        return false
    end
    list[#list + 1] = id
    if #list > max then
        __TS__ArraySplice(list, 0, #list - max)
    end
    return true
end
function milestone(s, id)
    return remember(s.completedMilestones, id, 100)
end
function reward(s, id, amount)
    if not remember(s.rewardedEncounters, id, 16) then
        return
    end
    s.skillPoints = s.skillPoints + amount
    s.totalSkillPointsEarned = s.totalSkillPointsEarned + amount
    emit(
        s,
        "reward",
        {
            rewardId = id,
            amount = amount,
            skillPoints = s.skillPoints,
            text = "身体记住了这一次。生长点 +" .. tostring(amount)
        }
    )
end
function context(s, next)
    if s.inputContext ~= next then
        s.inputContext = next
        emit(s, "context", {context = next})
    end
end
function clearQte(s, result)
    local q = s.qte
    if not q then
        return
    end
    if q.kind == "combat" then
        if result == "success" then
            s.combatQteMisses = 0
        elseif result == "miss" then
            s.combatQteMisses = math.min(2, s.combatQteMisses + 1)
        end
    end
    emit(s, "qte", {
        stage = result,
        qteId = q.id,
        kind = q.kind,
        text = q.target,
        x = s.world.hero.x,
        y = 0
    })
    if q.action == "release" and result == "miss" then
        s.rage = s.rage * 0.45
        s.beat.combo = 0
        emit(s, "release-miss", {skill = q.skill})
    end
    s.qte = nil
    context(s, "free")
end
function learn(s, id, reason)
    if s.skills[id] > 0 then
        return
    end
    s.skills[id] = 1
    if #s.equipped < 3 then
        local ____s_equipped_4 = s.equipped
        ____s_equipped_4[#____s_equipped_4 + 1] = id
    end
    milestone(s, "learn:" .. id)
    emit(s, "unlock", {skill = id, text = reason, x = s.world.hero.x, y = 0})
end
function completeProp(s, prop, id)
    if prop.state == "cleared" or prop.state == "passed" then
        return
    end
    prop.state = "cleared"
    prop.progress = 1
    milestone(s, "environment:" .. prop.id)
    local def = __TS__ArrayFind(
        ENVIRONMENTS,
        function(____, p) return p.id == prop.id end
    )
    emit(s, "environment", {
        stage = "clear",
        propId = prop.id,
        kind = prop.kind,
        skill = id,
        x = prop.x,
        y = 0,
        text = def.label
    })
    emit(s, "impact", {
        source = "environment",
        propId = prop.id,
        kind = prop.kind,
        skill = id,
        x = prop.x,
        y = 0,
        amount = 1
    })
    if prop.kind == "bonebead" then
        s.storyIndex = 5
        phase(s, "ending")
        motion(s.world.hero, "idle")
        s.world.hero.vx = 0
        emit(s, "story", {storyIndex = 5, text = STORIES[6].text, x = s.world.hero.x, y = 0})
    end
end
function beginHeadthrow(s, targetX, propId)
    local hero = s.world.hero
    s.headthrow = {
        stage = "flight",
        elapsed = 0,
        startX = hero.x,
        targetX = math.max(hero.x, targetX),
        headX = hero.x,
        headY = 36,
        heroVisible = true,
        headless = true,
        bodyAlpha = 1,
        propId = propId
    }
    hero.vx = 0
    motion(hero, "headthrow", true)
end
function performEnvironment(s, prop, id)
    learn(
        s,
        id,
        __TS__ArrayFind(
            SKILLS,
            function(____, d) return d.id == id end
        ).name .. "：身体记住了怎样通过这里。"
    )
    emit(s, "skill", {
        skill = id,
        level = s.skills[id],
        source = "environment",
        x = s.world.hero.x,
        y = 0,
        targetX = prop.x,
        targetY = 0,
        propId = prop.id
    })
    motion(s.world.hero, id, true)
    if id == "headthrow" then
        beginHeadthrow(s, prop.x + prop.width + 12, prop.id)
        return
    end
    if id == "oath" then
        s.buffs.oath = RULES.oath.duration
        s.buffs.bound = 0
    end
    if id == "rebirth" then
        combatState(s).rebuildRemaining = RULES.rebuild.duration
        gainResolve(s, 8)
    end
    if id == "nova" then
        igniteWorld(s, prop.x)
        s.heat = math.max(0, s.heat - 35)
        for ____, other in ipairs(s.world.props) do
            if other.id ~= prop.id and __TS__ArrayIncludes({"deadwood", "ash", "embers"}, other.kind) and math.abs(other.x - prop.x) < 100 then
                completeProp(s, other, id)
            end
        end
    end
    completeProp(s, prop, id)
end
function defeatEnemy(s)
    local enemy = s.enemy
    if not enemy then
        return
    end
    local encounter = __TS__ArrayFind(
        ENCOUNTERS,
        function(____, e) return e.id == enemy.id end
    )
    emit(s, "kill", {
        enemyId = enemy.id,
        kind = enemy.kind,
        ability = enemy.ability,
        x = enemy.x,
        y = 0,
        fx = "spawn/dissolve-burn"
    })
    if not __TS__ArrayIncludes(s.rewardedEncounters, enemy.id) then
        reward(s, enemy.id, encounter.reward)
        s.kills = s.kills + 1
        s.ember = s.ember + (enemy.kind == "boss" and 50 or (enemy.kind == "elite" and 20 or 8))
    end
    local dead = s.resolve <= 0 or s.phase == "fallen"
    if not dead then
        gainResolve(s, enemy.kind == "elite" and 12 or 6)
    end
    gainRage(s, 5)
    s.enemy = nil
    s.beat.arenaCamera = nil
    s.pendingHits = {}
    s.pendingEnemyHits = __TS__ArrayFilter(
        s.pendingEnemyHits,
        function(____, hit) return hit.committed end
    )
    local ____opt_13 = s.qte
    if (____opt_13 and ____opt_13.kind) == "combat" then
        clearQte(s, "cancel")
    end
    s.frenzyRemaining = 0
    context(s, "free")
    s.encounterIndex = s.encounterIndex + 1
    s.encounterStage = "exit"
    s.exitTime = 0.7
    s.chapterProgress = #__TS__ArrayFilter(
        CHAPTERS[s.chapter + 1].encounters,
        function(____, id) return __TS__ArrayIncludes(s.rewardedEncounters, id) end
    ) / #CHAPTERS[s.chapter + 1].encounters
    s.world.checkpointX = s.world.hero.x
    if enemy.kind == "boss" then
        local bead = __TS__ArrayFind(
            s.world.props,
            function(____, p) return p.id == "sisters-bead" end
        )
        bead.x = s.world.hero.x + 65
        bead.state = "intact"
        s.world.routeEndX = bead.x + 40
        emit(s, "environment", {
            stage = "reveal",
            propId = bead.id,
            kind = bead.kind,
            x = bead.x,
            y = 0,
            text = "灰里还有一样东西。"
        })
    end
    if not dead then
        phase(s, "journey")
    end
end
function attackId(s, source)
    local ____source_18 = source
    local ____combatState_result_15, ____attackSerial_16 = combatState(s), "attackSerial"
    local ____combatState_result_attackSerial_17 = ____combatState_result_15[____attackSerial_16] + 1
    ____combatState_result_15[____attackSerial_16] = ____combatState_result_attackSerial_17
    return (____source_18 .. ":") .. tostring(____combatState_result_attackSerial_17)
end
function hurtEnemy(s, raw, bypass, source, skill, id)
    if bypass == nil then
        bypass = false
    end
    if source == nil then
        source = "attack"
    end
    local e = s.enemy
    if not e or s.encounterStage ~= "active" or raw <= 0 then
        return 0
    end
    local closedShell = e.ability == "stone" and e.attackStage == "stone-closed" and e.broken <= 0
    local armor = (bypass or e.broken > 0 or e.attackStage == "stone-open") and 0 or (closedShell and 0.75 or e.armor)
    local amount = raw * (1 - armor)
    local absorbed = math.min(e.shield, amount)
    e.shield = e.shield - absorbed
    amount = amount - absorbed
    local actual = math.min(e.hp, amount)
    e.hp = math.max(0, e.hp - amount)
    local ____s_metrics_19, ____damage_20 = s.metrics, "damage"
    ____s_metrics_19[____damage_20] = ____s_metrics_19[____damage_20] + actual
    local contact = id or attackId(s, source)
    local fields = {
        attackId = contact,
        enemyId = e.id,
        amount = actual,
        absorbed = absorbed,
        source = source,
        skill = skill,
        x = e.x,
        y = 24
    }
    emit(s, "hit", fields)
    emit(s, "impact", fields)
    if e.kind == "boss" and e.phase == 1 and e.hp > 0 and e.hp <= e.maxHp * 0.5 then
        e.phase = 2
        emit(s, "boss-phase", {
            phase = 2,
            enemyId = e.id,
            x = e.x,
            y = 0,
            text = "旗杆折断，地火开始追随他的重击。"
        })
    end
    if e.hp <= 0 then
        defeatEnemy(s)
    end
    return actual
end
function igniteWorld(s, x)
    local burn = {
        id = attackId(s, "burn"),
        chapter = s.chapter,
        x = x - 100,
        y = -16,
        width = 220,
        height = 110,
        seed = math.floor(rng(s) * 4294967295),
        age = 0,
        strength = 1,
        kind = "nova"
    }
    local ____s_world_21, ____burns_22 = s.world, "burns"
    if ____s_world_21[____burns_22] == nil then
        ____s_world_21[____burns_22] = {}
    end
    local burns = s.world.burns
    burns[#burns + 1] = burn
    if #burns > 32 then
        __TS__ArraySplice(burns, 0, #burns - 32)
    end
    local id = burn.id
    local fields = __TS__ObjectRest(burn, {id = true})
    emit(
        s,
        "world-burn",
        __TS__ObjectAssign({}, fields, {burnId = id})
    )
end
function ____exports.clearCombatCommand(s)
    local c = combatState(s)
    c.command = ""
    c.commandAt = -10
    c.pendingCommand = nil
    c.commandStream = ""
    c.pendingBlockedReason = nil
end
function ____exports.castGuard(s)
    local c = combatState(s)
    if s.paused or s.phase ~= "combat" or s.encounterStage ~= "active" or s.qte or s.inputContext ~= "free" or c.guardCooldown > 1e-8 or s.resolve < RULES.guard.lifeCost then
        return false
    end
    s.resolve = math.max(0, s.resolve - RULES.guard.lifeCost)
    c.guardCooldown = RULES.guard.cooldown
    c.guardRemaining = RULES.guard.duration
    c.guardPerfectRemaining = RULES.guard.perfect
    emit(s, "self-cost", {
        action = "guard",
        amount = RULES.guard.lifeCost,
        rageCost = 0,
        x = s.world.hero.x,
        y = 24
    })
    emit(s, "guard", {
        action = "guard",
        stage = "start",
        duration = c.guardRemaining,
        x = s.world.hero.x,
        y = 0
    })
    if not s.headthrow then
        motion(s.world.hero, "guard", true)
    end
    refreshInferno(s)
    if s.resolve <= 0 then
        fall(s)
    end
    return true
end
function fall(s)
    if s.phase == "fallen" or s.phase == "ending" then
        return
    end
    s.deaths = s.deaths + 1
    s.beat.combo = 0
    s.beat.arenaCamera = nil
    s.resolve = 0
    s.fallenTime = 0
    if not jsTruthy(#s.pendingHits) then
        s.headthrow = nil
        s.enemy = nil
    end
    s.pendingEnemyHits = __TS__ArrayFilter(
        s.pendingEnemyHits,
        function(____, hit) return hit.committed end
    )
    if s.qte then
        clearQte(s, "cancel")
    end
    s.frenzyRemaining = 0
    context(s, "free")
    ____exports.clearCombatCommand(s)
    local c = combatState(s)
    c.guardRemaining = 0
    c.guardPerfectRemaining = 0
    c.surgeRemaining = 0
    c.rebuildRemaining = 0
    s.world.hero.vx = 0
    motion(s.world.hero, "fallen", true)
    phase(s, "fallen")
    refreshInferno(s)
    emit(s, "fall", {text = "身体散了。记得的路和领悟的生长仍在。", x = s.world.hero.x, y = 0, checkpointX = s.world.checkpointX})
end
function ____exports.castSkill(s, id)
    local def = __TS__ArrayFind(
        SKILLS,
        function(____, d) return d.id == id end
    )
    if not def or s.paused or s.skills[id] < 1 or not __TS__ArrayIncludes(s.equipped, id) or s.cooldowns[id] > 1e-8 or s.rage < def.cost or s.resolve <= 0 or __TS__ArrayIncludes({"title", "rest", "fallen", "ending"}, s.phase) then
        return false
    end
    local lifeCost = def.lifeCost or 0
    if id ~= "nova" and s.resolve < lifeCost then
        return false
    end
    local activeProp = __TS__ArrayFind(
        s.world.props,
        function(____, p)
            local ____temp_91 = p.state == "active"
            if ____temp_91 then
                local ____opt_89 = __TS__ArrayFind(
                    ENVIRONMENTS,
                    function(____, d) return d.id == p.id end
                )
                ____temp_91 = (____opt_89 and ____opt_89.skill) == id
            end
            return ____temp_91
        end
    )
    local ____activeProp_94 = activeProp
    if ____activeProp_94 then
        local ____opt_92 = s.qte
        ____activeProp_94 = (____opt_92 and ____opt_92.propId) == activeProp.id
    end
    local environment = ____activeProp_94
    local enemy = s.enemy
    if not environment and (not enemy or s.encounterStage ~= "active" or s.phase ~= "combat" or s.qte or s.inputContext ~= "free") then
        return false
    end
    if id == "headthrow" and s.headthrow then
        return false
    end
    local paidLife = math.min(s.resolve, lifeCost)
    s.resolve = math.max(0, s.resolve - lifeCost)
    s.rage = s.rage - def.cost
    s.cooldowns[id] = def.cooldown
    emit(s, "self-cost", {
        skill = id,
        action = id,
        amount = paidLife,
        requiredLife = lifeCost,
        rageCost = def.cost,
        x = s.world.hero.x,
        y = 24
    })
    if environment then
        clearQte(s, "success")
        performEnvironment(s, activeProp, id)
        if s.resolve <= 0 then
            fall(s)
        end
        refreshInferno(s)
        return true
    end
    local e = enemy
    local level = s.skills[id]
    local power = 1 + s.upgrades.pain * 0.12
    local idPrefix = attackId(s, id)
    if not s.headthrow then
        motion(s.world.hero, id, true)
    end
    emit(s, "skill", {
        attackId = idPrefix,
        skill = id,
        level = level,
        enemyId = e.id,
        x = s.world.hero.x,
        y = 0,
        targetX = e.x,
        targetY = 0,
        fx = def.fx
    })
    emit(s, "release", {
        attackId = idPrefix,
        skill = id,
        combo = s.beat.combo,
        x = s.world.hero.x,
        y = 0
    })
    local ____s_beat_95, ____releases_96 = s.beat, "releases"
    ____s_beat_95[____releases_96] = ____s_beat_95[____releases_96] + 1
    local function later(remaining, amount, bypass)
        if bypass == nil then
            bypass = false
        end
        local ____s_pendingHits_97 = s.pendingHits
        local ____temp_98 = #____s_pendingHits_97 + 1
        ____s_pendingHits_97[____temp_98] = {
            remaining = remaining,
            amount = amount * power,
            bypass = bypass,
            skill = id,
            enemyId = e.id,
            impactX = e.x
        }
        return ____temp_98
    end
    if id == "spark" then
        hurtEnemy(
            s,
            (24 + (level - 1) * 3) * power,
            false,
            "skill",
            id,
            idPrefix
        )
        if s.enemy == e and level >= 2 then
            e.burn = 4
            e.burnTick = 0.8
        end
        if s.enemy == e and level >= 3 then
            later(0.3, 8)
        end
    elseif id == "headthrow" then
        beginHeadthrow(
            s,
            e.x + math.max(0, e.vx) * 0.62 - 28
        )
        later(0.62, 38, true)
        if level >= 2 then
            later(0.92, 10, true)
        end
        if level >= 3 then
            s.buffs.shadow = 3
            later(1.1, 12, true)
        end
    elseif id == "rebirth" then
        if s.resolve > 0 then
            gainResolve(s, RULES.rebuild.heal + (level - 1) * 3)
        end
        combatState(s).rebuildRemaining = RULES.rebuild.duration
        for ____, prop in ipairs(s.world.props) do
            if prop.kind == "embers" and prop.state == "active" then
                completeProp(s, prop, id)
            end
        end
    elseif id == "lash" then
        local segment = level >= 2 and 11 or 10
        e.shield = 0
        hurtEnemy(
            s,
            segment * power,
            false,
            "skill",
            id,
            idPrefix
        )
        if s.enemy == e then
            later(0.18, segment)
            later(0.36, segment)
            if level >= 3 then
                later(0.54, segment)
            end
        end
    elseif id == "nova" then
        igniteWorld(s, s.world.hero.x)
        hurtEnemy(
            s,
            (64 + (level - 1) * 5) * power,
            true,
            "skill",
            id,
            idPrefix
        )
        for ____, prop in ipairs(s.world.props) do
            if __TS__ArrayIncludes({"deadwood", "ash", "embers"}, prop.kind) and math.abs(prop.x - s.world.hero.x) <= 90 then
                completeProp(s, prop, id)
            end
        end
    elseif id == "oath" then
        s.buffs.oath = RULES.oath.duration
        s.buffs.bound = 0
    end
    refreshInferno(s)
    if s.resolve <= 0 then
        fall(s)
    end
    return true
end
do
    local ____combat_2Drules = require("core.combat-rules")
    ____exports.COMBAT_RULES = ____combat_2Drules.COMBAT_RULES
end
____exports.BRANCHES = BRANCHES
____exports.CHAPTERS = CHAPTERS
____exports.DESIGN_WIDTH = DESIGN_WIDTH
____exports.ENCOUNTERS = ENCOUNTERS
____exports.ENEMIES = ENEMIES
____exports.ENVIRONMENTS = ENVIRONMENTS
____exports.HERO_SCREEN_X = HERO_SCREEN_X
____exports.MEMORIES = MEMORIES
____exports.RUN_SPEED = RUN_SPEED
____exports.SEMANTIC_THEMES = SEMANTIC_THEMES
____exports.SKILLS = SKILLS
____exports.STORIES = STORIES
____exports.WALK_SPEED = WALK_SPEED
do
    local ____export = require("core.types")
    for ____exportKey, ____exportValue in pairs(____export) do
        if ____exportKey ~= "default" then
            ____exports[____exportKey] = ____exportValue
        end
    end
end
____exports.FIXED_STEP = 1 / 30
____exports.TOTAL_REWARD_POINTS = 17
local SKILL_IDS = {
    "spark",
    "headthrow",
    "rebirth",
    "lash",
    "nova",
    "oath"
}
local BRANCH_IDS = {"pain", "hatred", "adaptation"}
local PHASES = {
    "title",
    "crawl",
    "journey",
    "combat",
    "rest",
    "fallen",
    "ending"
}
local MOTIONS = {
    "idle",
    "crawl",
    "stand",
    "walk",
    "run",
    "charge",
    "attack",
    "attack2",
    "hurt",
    "fallen",
    "rebirth",
    "guard",
    table.unpack(SKILL_IDS)
}
clamp = function(v, lo, hi) return math.max(
    lo,
    math.min(hi, v)
) end
local function finite(v, fallback, lo, hi)
    if fallback == nil then
        fallback = 0
    end
    if lo == nil then
        lo = 0
    end
    if hi == nil then
        hi = 10000000
    end
    return type(v) == "number" and __TS__NumberIsFinite(v) and clamp(v, lo, hi) or fallback
end
local function ranks()
    return {
        spark = 0,
        headthrow = 0,
        rebirth = 0,
        lash = 0,
        nova = 0,
        oath = 0
    }
end
local function code(text)
    return asciiLetters(text)
end
local function dataObject(value)
    return jsTruthy(jsAnd(
        jsAnd(
            value,
            function() return type(value) == "table" end
        ),
        function() return not jsIsArray(value) end
    )) and value or ({})
end
local function validReceipt(id)
    return type(id) == "string" and jsLength(id) > 0 and jsLength(id) <= 160
end
local function startQte(s, qte)
    if s.qte or s.inputContext == "frenzy" then
        return false
    end
    s.qte = __TS__ObjectAssign(
        {},
        qte,
        {
            pinyin = code(qte.pinyin),
            progress = 0,
            mistakes = 0
        }
    )
    context(s, qte.kind == "combat" and "combat-qte" or "story-qte")
    emit(s, "qte", {
        stage = "start",
        qteId = qte.id,
        kind = qte.kind,
        text = qte.label,
        target = qte.target,
        pinyin = s.qte.pinyin,
        remaining = qte.remaining,
        x = s.world.hero.x,
        y = 0
    })
    return true
end
function ____exports.createGame(seed)
    if seed == nil then
        seed = 831105
    end
    local normalized = jsSeed(seed)
    return {
        version = 2,
        seed = normalized,
        phase = "title",
        elapsed = 0,
        chapter = 0,
        encounterIndex = 0,
        encounterStyle = "hold",
        encounterStage = "exit",
        resolve = 78,
        maxResolve = 100,
        rage = 0,
        heat = 18,
        ember = 0,
        skillPoints = 0,
        totalSkillPointsEarned = 0,
        kills = 0,
        deaths = 0,
        autoWalk = false,
        paused = false,
        inputContext = "free",
        qte = nil,
        frenzyRemaining = 0,
        frenzyProgress = 0,
        frenzyReason = "",
        frenzyCooldown = 0,
        combatQteMisses = 0,
        beat = {
            combo = 0,
            best = 0,
            last = -10,
            interval = 0.5,
            releases = 0,
            arenaCamera = nil
        },
        world = {
            hero = {
                x = 0,
                y = 0,
                vx = 0,
                facing = 1,
                motion = "crawl",
                actionTime = 0
            },
            cameraX = -HERO_SCREEN_X,
            previousCameraX = -HERO_SCREEN_X,
            burns = {},
            props = __TS__ArrayMap(
                ENVIRONMENTS,
                function(____, p) return {
                    id = p.id,
                    kind = p.kind,
                    x = p.x,
                    y = 0,
                    state = "intact",
                    width = p.width,
                    progress = 0
                } end
            ),
            checkpointX = 0,
            routeEndX = CHAPTERS[5].endX
        },
        enemy = nil,
        headthrow = nil,
        skills = __TS__ObjectAssign(
            {},
            ranks(),
            {spark = 1, rebirth = 1}
        ),
        upgrades = {pain = 0, hatred = 0, adaptation = 0},
        cooldowns = ranks(),
        ---@type string[]
        equipped = {"spark", "rebirth"},
        events = {},
        eventSerial = 0,
        metrics = {
            strokes = 0,
            semantics = 0,
            words = 0,
            damage = 0,
            qtes = 0,
            frenzyEscapes = 0,
            footsteps = 0,
            pulses = 0,
            commits = 0
        },
        storyIndex = 0,
        chapterProgress = 0,
        distance = 0,
        terrain = "焦灰",
        buffs = {
            shield = 0,
            reflect = 0,
            oath = 0,
            deathguard = 0,
            memory = 0,
            flow = 0,
            shadow = 0,
            bound = 0
        },
        pendingHits = {},
        pendingEnemyHits = {},
        rewardedEncounters = {},
        completedMilestones = {},
        acceptedStrokeIds = {},
        acceptedSemanticIds = {},
        acceptedSegments = {},
        semanticCategoryCounts = {memory = 0, pain = 0, hatred = 0, resolve = 0},
        semanticCooldown = 0,
        strokeBudget = 4,
        strokeMomentum = 0,
        crawlStage = 0,
        fallenTime = 0,
        exitTime = 0,
        autoAttackTimer = 1.2,
        footstepDistance = 0,
        lastStrokeTime = -10,
        memoryIndex = 0,
        ticks = 0,
        accumulator = 0,
        rng = normalized,
        combat = createCombatState(),
        infernoActive = false
    }
end
function ____exports.advance(s)
    if s.paused then
        return false
    end
    if s.phase == "title" then
        phase(s, "crawl")
        emit(s, "story", {storyIndex = 0, text = STORIES[1].text})
        startQte(s, {
            id = "opening-wake",
            kind = "story",
            action = "wake",
            label = "她说：别睡。",
            target = "别睡",
            pinyin = "bie shui",
            remaining = nil
        })
        return true
    end
    if s.phase == "rest" then
        s.chapter = math.min(4, s.chapter + 1)
        s.storyIndex = s.chapter
        s.terrain = CHAPTERS[s.chapter + 1].terrain
        s.chapterProgress = 0
        phase(s, "journey")
        gainResolve(s, 12)
        local memory = MEMORIES[math.min(s.chapter, #MEMORIES - 1) + 1]
        startQte(
            s,
            {
                id = "chapter-" .. tostring(s.chapter),
                kind = "story",
                action = "memory",
                label = STORIES[s.chapter + 1].text,
                target = memory.text,
                pinyin = memory.pinyin,
                remaining = nil
            }
        )
        return true
    end
    return false
end
local function completeQte(s)
    local q = s.qte
    if not q then
        return
    end
    local ____s_metrics_5, ____qtes_6 = s.metrics, "qtes"
    ____s_metrics_5[____qtes_6] = ____s_metrics_5[____qtes_6] + 1
    clearQte(s, "success")
    if q.action == "release" and q.skill then
        local ____opt_7 = s.enemy
        if (____opt_7 and ____opt_7.id) == q.enemyId and ____exports.castSkill(s, q.skill) then
            local ____s_beat_9, ____releases_10 = s.beat, "releases"
            ____s_beat_9[____releases_10] = ____s_beat_9[____releases_10] + 1
            s.heat = math.min(100, s.heat + 24)
            emit(s, "release", {skill = q.skill, combo = s.beat.combo, x = s.world.hero.x, y = 0})
        end
        return
    end
    if q.kind == "combat" then
        return
    end
    gainResolve(s, 7)
    gainRage(s, 3)
    if q.action == "wake" then
        s.crawlStage = 1
        milestone(s, "opening-wake")
    elseif q.action == "stand" then
        s.crawlStage = 3
        motion(s.world.hero, "stand", true)
        milestone(s, "opening-stand")
    elseif q.id == "opening-hand" then
        s.crawlStage = 2
        milestone(s, "opening-hand")
    end
    if q.kind == "story" or q.target == "别睡" then
        emit(s, "memory", {
            text = q.target,
            pinyin = q.pinyin,
            category = "声音",
            curated = true,
            x = s.world.hero.x,
            y = 0
        })
        local ____s_metrics_11, ____words_12 = s.metrics, "words"
        ____s_metrics_11[____words_12] = ____s_metrics_11[____words_12] + 1
    end
    if jsTruthy(q.propId) then
        local prop = __TS__ArrayFind(
            s.world.props,
            function(____, p) return p.id == q.propId end
        )
        local def = __TS__ArrayFind(
            ENVIRONMENTS,
            function(____, p) return p.id == q.propId end
        )
        if prop and def then
            if def.skill then
                performEnvironment(s, prop, def.skill)
            else
                completeProp(s, prop)
            end
        end
    end
end
local function completeCrawl(s)
    if s.autoWalk then
        return
    end
    s.autoWalk = true
    s.chapter = 1
    s.storyIndex = 1
    s.terrain = CHAPTERS[2].terrain
    reward(s, "opening", 1)
    phase(s, "journey")
    gainResolve(s, 16)
    s.world.checkpointX = s.world.hero.x
    emit(s, "unlock", {text = "火种仍在。", autoWalk = true, x = s.world.hero.x, y = 0})
    emit(s, "story", {storyIndex = 1, text = STORIES[2].text})
end
local function makeEnemy(s)
    local encounter = ENCOUNTERS[s.encounterIndex + 1]
    if not encounter or encounter.chapter ~= s.chapter then
        return
    end
    local def = __TS__ArrayFind(
        ENEMIES,
        function(____, d) return d.id == encounter.enemyId end
    )
    local scale = 1 + (encounter.chapter - 1) * 0.13
    local maxHp = math.floor(def.hp * scale * (0.98 + rng(s) * 0.04) + 0.5)
    s.semanticCategoryCounts = {memory = 0, pain = 0, hatred = 0, resolve = 0}
    s.enemy = {
        id = encounter.id,
        definitionId = def.id,
        name = def.name,
        kind = def.kind,
        ability = def.ability,
        hp = maxHp,
        maxHp = maxHp,
        phase = 1,
        x = math.max(encounter.enemyX, s.world.hero.x + 170),
        y = 0,
        vx = 0,
        facing = -1,
        motion = encounter.style == "chase" and "run" or "walk",
        actionTime = 0,
        attackTimer = def.interval,
        attackBeat = 1,
        heavyAnnounced = false,
        telegraph = 0,
        telegraphTotal = def.telegraph,
        armor = def.armor,
        breakProgress = 0,
        breakThreshold = def.kind == "boss" and 6 or (def.kind == "elite" and 5 or 3.6),
        damage = def.damage * (1 + (encounter.chapter - 1) * 0.09),
        attackInterval = def.interval,
        attackMercy = 1,
        shield = 0,
        broken = 0,
        burn = 0,
        burnTick = 0.8,
        attackRange = def.attackRange,
        fx = def.fx,
        fleeing = false
    }
    s.encounterStyle = "hold"
    s.beat.arenaCamera = nil
    s.encounterStage = "approach"
    s.autoAttackTimer = 0.9
    combatState(s).strokeCharge = 0
    ____exports.clearCombatCommand(s)
    s.world.checkpointX = math.max(CHAPTERS[s.chapter + 1].startX, encounter.spawnAt - 80)
    phase(s, "combat")
    emit(s, "encounter", {
        stage = "approach",
        enemyId = encounter.id,
        kind = def.kind,
        ability = def.ability,
        style = encounter.style,
        x = s.enemy.x,
        y = 0,
        text = encounter.label
    })
end
local function commandBlocked(s, command)
    local c = combatState(s)
    local def = __TS__ArrayFind(
        SKILLS,
        function(____, item) return item.command == command end
    )
    if def then
        return s.skills[def.id] < 1 and "locked" or (not __TS__ArrayIncludes(s.equipped, def.id) and "unequipped" or (s.cooldowns[def.id] > 0 and "cooldown" or (s.rage < def.cost and "rage" or (def.id ~= "nova" and s.resolve < (def.lifeCost or 0) and "life" or nil))))
    end
    return c.guardCooldown > 0 and "cooldown" or (s.resolve < RULES.guard.lifeCost and "life" or nil)
end
local function releaseCommand(s, command, blockedReason)
    local c = combatState(s)
    local def = __TS__ArrayFind(
        SKILLS,
        function(____, item) return item.command == command end
    )
    local guard = command == RULES.guard.command
    ____exports.clearCombatCommand(s)
    local ____jsTruthy_result_26
    if jsTruthy(blockedReason) then
        ____jsTruthy_result_26 = false
    else
        local ____guard_25
        if guard then
            ____guard_25 = ____exports.castGuard(s)
        else
            local ____def_24
            if def then
                ____def_24 = ____exports.castSkill(s, def.id)
            else
                ____def_24 = false
            end
            ____guard_25 = ____def_24
        end
        ____jsTruthy_result_26 = ____guard_25
    end
    local cast = ____jsTruthy_result_26
    if not cast then
        emit(
            s,
            "cast-rejected",
            {
                action = guard and "guard" or def and def.id,
                reason = blockedReason or (def and s.skills[def.id] < 1 and "locked" or (def and not __TS__ArrayIncludes(s.equipped, def.id) and "unequipped" or (guard and (c.guardCooldown > 0 and "cooldown" or "life") or (def and s.cooldowns[def.id] > 0 and "cooldown" or (def and s.rage < def.cost and "rage" or "life")))))
            }
        )
    end
end
local function commandStroke(s, key)
    local c = combatState(s)
    if s.phase ~= "combat" or s.encounterStage ~= "active" or s.inputContext ~= "free" or s.qte then
        ____exports.clearCombatCommand(s)
        return
    end
    if s.elapsed - c.commandAt > RULES.commandGap then
        ____exports.clearCombatCommand(s)
    end
    c.commandAt = s.elapsed
    local ____array_29 = __TS__SparseArrayNew(table.unpack(__TS__ArrayFilter(
        __TS__ArrayMap(
            SKILLS,
            function(____, item) return item.command end
        ),
        function(____, value) return jsTruthy(value) end
    )))
    __TS__SparseArrayPush(____array_29, RULES.guard.command)
    local commands = {__TS__SparseArraySpread(____array_29)}
    if key == "Backspace" then
        c.commandStream = jsSlice(c.commandStream or c.command, 0, -1)
        c.command = commandHint(c.commandStream, commands)
        c.pendingCommand = nil
        c.pendingBlockedReason = nil
        return
    end
    if not isAsciiKey(key) then
        if jsTruthy(c.pendingCommand) then
            releaseCommand(s, c.pendingCommand, c.pendingBlockedReason)
        else
            ____exports.clearCombatCommand(s)
        end
        return
    end
    local pending = c.pendingCommand
    local blocked = c.pendingBlockedReason
    c.commandStream = jsSlice(
        (c.commandStream or c.command) .. string.lower(key),
        -16
    )
    c.command = commandHint(c.commandStream, commands)
    local match = matchCommand(c.commandStream, commands)
    if match and not match.deferred then
        releaseCommand(s, match.command)
        return
    end
    if jsTruthy(jsAnd(
        pending,
        function() return not match end
    )) then
        releaseCommand(s, pending, blocked)
        c.commandStream = jsLower(key)
        c.command = commandHint(c.commandStream, commands)
        c.commandAt = s.elapsed
        return
    end
    c.pendingCommand = match and match.deferred and match.command or nil
    c.pendingBlockedReason = jsTruthy(c.pendingCommand) and commandBlocked(s, c.pendingCommand) or nil
end
function ____exports.retry(s)
    if s.phase ~= "fallen" or s.paused then
        return false
    end
    local fromX = s.world.hero.x
    s.world.hero.x = s.world.checkpointX
    s.world.hero.y = 0
    s.world.hero.vx = 0
    s.world.hero.facing = 1
    s.world.cameraX = s.world.hero.x - HERO_SCREEN_X
    s.world.previousCameraX = s.world.cameraX
    s.beat.combo = 0
    s.beat.arenaCamera = nil
    s.beat.last = s.elapsed
    s.lastStrokeTime = s.elapsed
    s.resolve = s.maxResolve * 0.7
    s.heat = math.min(30, s.heat)
    s.rage = math.max(20, s.rage)
    for ____, id in ipairs(SKILL_IDS) do
        s.cooldowns[id] = 0
    end
    for ____, key in ipairs(__TS__ObjectKeys(s.buffs)) do
        s.buffs[key] = 0
    end
    local serial = combatState(s).attackSerial
    s.combat = createCombatState()
    s.combat.attackSerial = serial
    s.pendingHits = {}
    s.pendingEnemyHits = {}
    s.headthrow = nil
    s.qte = nil
    s.enemy = nil
    s.frenzyRemaining = 0
    s.frenzyCooldown = 0
    s.exitTime = 0
    s.encounterStage = "exit"
    context(s, "free")
    motion(s.world.hero, "rebirth", true)
    if s.autoWalk then
        phase(s, "journey")
    else
        phase(s, "crawl")
        s.crawlStage = math.max(
            1,
            math.min(2, s.crawlStage)
        )
    end
    s.distance = s.world.hero.x
    refreshInferno(s)
    emit(s, "respawn", {x = s.world.hero.x, y = 0, fromX = fromX, text = "从记得的地方，接回这段路。"})
    return true
end
local function hurtPlayer(s, raw, ability, id, enemyDamage)
    if enemyDamage == nil then
        enemyDamage = true
    end
    if s.phase == "fallen" or s.resolve <= 0 then
        return 0
    end
    local amount = math.min(
        s.resolve,
        math.max(0, raw) * (s.buffs.shield > 0 and 0.3 or 1)
    )
    s.resolve = math.max(0, s.resolve - amount)
    s.heat = clamp(s.heat + amount * 0.4, 0, 100)
    if enemyDamage then
        gainRage(s, amount * RULES.damageRage)
    end
    emit(
        s,
        "player-hit",
        {
            attackId = id or attackId(s, ability),
            amount = amount,
            ability = ability,
            x = s.world.hero.x,
            y = 24
        }
    )
    if not s.headthrow then
        motion(s.world.hero, "hurt", true)
    end
    local c = combatState(s)
    if enemyDamage and s.resolve > 0 and s.resolve / s.maxResolve <= RULES.surge.threshold and c.surgeCooldown <= 1e-8 then
        c.surgeRemaining = RULES.surge.duration
        c.surgeCooldown = RULES.surge.cooldown
        emit(s, "surge", {
            stage = "start",
            duration = c.surgeRemaining,
            multiplier = RULES.surge.multiplier,
            x = s.world.hero.x,
            y = 0
        })
    end
    refreshInferno(s)
    if s.resolve <= 0 then
        fall(s)
    end
    return amount
end
--- A committed projectile has its own lifetime, even after its source dies.
local function resolveEnemyHit(s, hit)
    if s.phase == "fallen" or s.resolve <= 0 then
        return false
    end
    local c = combatState(s)
    local e = s.enemy
    local canParry = hit.parryable == true and (hit.committed ~= true or hit.ability == "arrow")
    if c.guardRemaining > 0 and c.guardPerfectRemaining > 0 and canParry then
        c.guardPerfectRemaining = 0
        c.guardRemaining = 0
        gainRage(s, RULES.guard.rage)
        local deflected = hit.committed == true
        emit(s, "parry", {
            action = "guard",
            attackId = hit.attackId,
            enemyId = hit.enemyId,
            deflected = deflected,
            amount = deflected and 0 or RULES.guard.counterDamage,
            x = s.world.hero.x,
            y = 0
        })
        if deflected then
            emit(s, "guard", {
                action = "guard",
                stage = "deflect",
                attackId = hit.attackId,
                enemyId = hit.enemyId,
                x = s.world.hero.x,
                y = 24
            })
        else
            emit(s, "interrupt", {
                action = "guard",
                attackId = hit.attackId,
                enemyId = hit.enemyId,
                x = hit.sourceX or e and e.x,
                y = 0
            })
        end
        if not deflected and (e and e.id) == hit.enemyId then
            e.broken = 1.2
            e.shield = 0
            motion(e, "hurt", true)
            hurtEnemy(
                s,
                RULES.guard.counterDamage,
                true,
                "counter",
                nil,
                hit.attackId .. ":counter"
            )
        end
        return true
    end
    local guarded = c.guardRemaining > 0
    if guarded then
        c.guardPerfectRemaining = 0
        c.guardRemaining = 0
        emit(s, "guard", {
            action = "guard",
            stage = "block",
            attackId = hit.attackId,
            enemyId = hit.enemyId,
            x = s.world.hero.x,
            y = 0
        })
    end
    local damage = hurtPlayer(s, hit.amount * (guarded and RULES.guard.reduction or 1), hit.ability, hit.attackId)
    if damage > 0 and s.resolve > 0 and hit.heavy and hit.ability == "binding" then
        s.buffs.bound = 3
    end
    return false
end
local function advancePendingHits(s)
    local own = s.pendingHits
    s.pendingHits = {}
    for ____, hit in ipairs(own) do
        hit.remaining = hit.remaining - ____exports.FIXED_STEP
        if hit.remaining <= 1e-9 then
            local ____opt_36 = s.enemy
            if (____opt_36 and ____opt_36.id) == hit.enemyId then
                hurtEnemy(
                    s,
                    hit.amount,
                    hit.bypass,
                    "skill",
                    hit.skill
                )
            end
        else
            local ____opt_38 = s.enemy
            if (____opt_38 and ____opt_38.id) == hit.enemyId then
                local ____s_pendingHits_40 = s.pendingHits
                ____s_pendingHits_40[#____s_pendingHits_40 + 1] = hit
            end
        end
    end
    local incoming = s.pendingEnemyHits
    s.pendingEnemyHits = {}
    for ____, hit in ipairs(incoming) do
        hit.remaining = hit.remaining - ____exports.FIXED_STEP
        if hit.remaining <= 1e-9 then
            resolveEnemyHit(s, hit)
        else
            local ____hit_committed_43 = hit.committed
            if not ____hit_committed_43 then
                local ____opt_41 = s.enemy
                ____hit_committed_43 = (____opt_41 and ____opt_41.id) == hit.enemyId
            end
            if ____hit_committed_43 then
                local ____s_pendingEnemyHits_44 = s.pendingEnemyHits
                ____s_pendingEnemyHits_44[#____s_pendingEnemyHits_44 + 1] = hit
            end
        end
    end
end
local function advanceHeadthrow(s)
    local h = s.headthrow
    if not h then
        return
    end
    h.elapsed = h.elapsed + ____exports.FIXED_STEP
    if h.stage == "flight" then
        local u = math.min(1, h.elapsed / 0.62)
        h.headX = h.startX + (h.targetX - h.startX) * u
        h.headY = 36 + math.sin(math.pi * u) * 24
        h.bodyAlpha = 1 - math.min(1, u * 1.3)
        if u >= 1 then
            s.world.hero.x = h.targetX
            s.world.hero.y = 0
            h.stage = "rebuild"
            h.elapsed = 0
            h.headless = false
            h.heroVisible = true
            h.bodyAlpha = 0
            if s.phase ~= "fallen" then
                motion(s.world.hero, "rebirth", true)
            end
            local prop = jsTruthy(h.propId) and __TS__ArrayFind(
                s.world.props,
                function(____, p) return p.id == h.propId end
            ) or nil
            if prop then
                completeProp(s, prop, "headthrow")
            end
            local ____emit_49 = emit
            local ____s_48 = s
            local ____h_targetX_47 = h.targetX
            local ____opt_45 = s.enemy
            ____emit_49(____s_48, "impact", {
                skill = "headthrow",
                stage = "land",
                x = ____h_targetX_47,
                y = 0,
                enemyId = ____opt_45 and ____opt_45.id
            })
        end
    else
        h.bodyAlpha = s.phase == "fallen" and 0 or math.min(1, h.elapsed / 0.42)
        if h.elapsed >= 0.5 then
            s.headthrow = nil
        end
    end
end
local function updateEnvironment(s)
    if not s.autoWalk or s.qte or s.headthrow or s.phase == "fallen" then
        return
    end
    local hero = s.world.hero
    for ____, prop in ipairs(s.world.props) do
        do
            if prop.state == "cleared" or prop.state == "passed" then
                goto __continue167
            end
            local def = __TS__ArrayFind(
                ENVIRONMENTS,
                function(____, d) return d.id == prop.id end
            )
            if def.chapter > s.chapter or prop.id == "sisters-bead" and s.kills < 15 then
                goto __continue167
            end
            if not def.blocking then
                if hero.x < prop.x - 8 or hero.x > prop.x + prop.width then
                    if hero.x > prop.x + prop.width then
                        prop.state = "passed"
                    end
                    goto __continue167
                end
                if prop.state ~= "active" then
                    prop.state = "active"
                    emit(s, "environment", {
                        stage = "enter",
                        propId = prop.id,
                        kind = prop.kind,
                        x = prop.x,
                        y = 0,
                        text = def.label
                    })
                end
                prop.progress = prop.progress + ____exports.FIXED_STEP
                if prop.kind == "embers" and prop.progress >= 2 then
                    prop.progress = prop.progress - 2
                    hurtPlayer(
                        s,
                        s.upgrades.adaptation >= 2 and 0.5 or 1.8,
                        "terrain",
                        nil,
                        false
                    )
                end
            elseif s.phase == "journey" and s.exitTime <= 0 and hero.x >= prop.x - 24 then
                prop.state = "active"
                if def.skill then
                    learn(
                        s,
                        def.skill,
                        __TS__ArrayFind(
                            SKILLS,
                            function(____, d) return d.id == def.skill end
                        ).environment
                    )
                end
                startQte(s, {
                    id = "env:" .. prop.id,
                    kind = (prop.kind == "shrine" or prop.kind == "bonebead" or prop.kind == "banner") and "story" or "environment",
                    action = "environment",
                    label = def.label,
                    target = def.target,
                    pinyin = def.pinyin,
                    remaining = nil,
                    propId = prop.id
                })
                hero.vx = 0
                motion(hero, "idle")
                break
            end
        end
        ::__continue167::
    end
end
local function combatGap(e)
    return e.kind == "boss" and 44 or (e.kind == "ranged" and 40 or (e.kind == "elite" and 36 or 32))
end
local function moveWorld(s)
    local hero = s.world.hero
    local e = s.enemy
    hero.actionTime = hero.actionTime + ____exports.FIXED_STEP
    if e then
        e.actionTime = e.actionTime + ____exports.FIXED_STEP
    end
    local oldX = hero.x
    local blocked = not not s.headthrow or s.qte ~= nil and s.qte.kind ~= "combat"
    local heroSpeed = 0
    local enemySpeed = 0
    local nextMotion = s.phase == "crawl" and (s.crawlStage >= 3 and "stand" or "crawl") or "idle"
    if not blocked and s.phase == "crawl" then
        if s.crawlStage == 1 or s.crawlStage == 2 then
            heroSpeed = 2.7 + s.strokeMomentum * 0.8
            nextMotion = "crawl"
        elseif s.crawlStage == 3 then
            nextMotion = "stand"
        end
    elseif not blocked and s.phase == "journey" then
        local encounter = ENCOUNTERS[s.encounterIndex + 1]
        ---@type number
        local nextStop = (encounter and encounter.chapter) == s.chapter and encounter.spawnAt or CHAPTERS[s.chapter + 1].endX
        for ____, prop in ipairs(s.world.props) do
            local ____temp_54 = not __TS__ArrayIncludes({"cleared", "passed"}, prop.state) and prop.x >= hero.x
            if ____temp_54 then
                local ____opt_52 = __TS__ArrayFind(
                    ENVIRONMENTS,
                    function(____, d) return d.id == prop.id end
                )
                ____temp_54 = ____opt_52 and ____opt_52.blocking
            end
            if ____temp_54 then
                nextStop = math.min(nextStop, prop.x - 24)
            end
        end
        local targetSpeed = nextStop - hero.x > 120 and 74 or WALK_SPEED
        heroSpeed = targetSpeed
        nextMotion = heroSpeed > WALK_SPEED + 1 and "run" or "walk"
    elseif not blocked and s.phase == "combat" and e then
        local encounter = ENCOUNTERS[s.encounterIndex + 1]
        local gap = e.x - hero.x
        local desired = combatGap(e)
        if s.encounterStage == "approach" then
            heroSpeed = s.encounterStyle == "chase" and RUN_SPEED + 2 or WALK_SPEED
            enemySpeed = s.encounterStyle == "chase" and 9 or -8
            nextMotion = s.encounterStyle == "chase" and "run" or "walk"
            if gap <= desired + 2 then
                s.encounterStage = "active"
                s.autoAttackTimer = 0.8
                e.attackTimer = e.attackInterval
                e.attackBeat = 1
                emit(s, "encounter", {
                    stage = "active",
                    enemyId = e.id,
                    style = s.encounterStyle,
                    x = e.x,
                    y = 0
                })
            end
        end
        if s.encounterStage == "active" then
            heroSpeed = 0
            enemySpeed = 0
            nextMotion = "idle"
            if s.beat.arenaCamera == nil then
                s.beat.arenaCamera = s.world.cameraX
            end
        end
        local slow = s.buffs.bound > 0 and s.buffs.oath <= 0 and 0.65 or 1
        heroSpeed = heroSpeed * slow
        enemySpeed = enemySpeed * slow
    end
    local ash = __TS__ArrayFind(
        s.world.props,
        function(____, p) return p.kind == "ash" and p.state == "active" and hero.x >= p.x - 8 and hero.x <= p.x + p.width end
    )
    if ash and s.buffs.oath <= 0 then
        heroSpeed = heroSpeed * (0.66 + s.upgrades.adaptation * 0.09)
    end
    if e and s.encounterStyle == "chase" and ash then
        enemySpeed = enemySpeed * (0.66 + s.upgrades.adaptation * 0.09)
    end
    hero.vx = heroSpeed
    hero.x = hero.x + heroSpeed * ____exports.FIXED_STEP
    hero.y = 0
    if e then
        e.vx = enemySpeed
        e.x = e.x + enemySpeed * ____exports.FIXED_STEP
        e.y = 0
        e.facing = e.x >= hero.x and -1 or 1
        if e.broken > 0 then
            motion(e, "hurt")
        elseif e.telegraph > 0 then
            motion(e, "charge")
        elseif not (e.motion == "attack" or e.motion == "attack2") or e.actionTime > 0.5 then
            motion(
                e,
                math.abs(e.vx) > 14 and "run" or (math.abs(e.vx) > 0.1 and "walk" or "idle")
            )
        end
    end
    hero.facing = e and e.x < hero.x and -1 or 1
    local acting = __TS__ArrayIncludes(
        {
            "attack",
            "attack2",
            "hurt",
            "guard",
            "rebirth",
            "stand",
            table.unpack(SKILL_IDS)
        },
        hero.motion
    ) and hero.actionTime < (hero.motion == "hurt" and 0.18 or (hero.motion == "stand" and 0.7 or (hero.motion == "guard" and 0.55 or 0.4)))
    if not s.headthrow and not acting then
        motion(hero, nextMotion)
    end
    s.footstepDistance = s.footstepDistance + math.abs(hero.x - oldX)
    local stepLength = nextMotion == "crawl" and 6 or (nextMotion == "run" and 18 or 12)
    if s.footstepDistance >= stepLength and heroSpeed > 0 then
        s.footstepDistance = s.footstepDistance % stepLength
        local ____s_metrics_55, ____footsteps_56 = s.metrics, "footsteps"
        ____s_metrics_55[____footsteps_56] = ____s_metrics_55[____footsteps_56] + 1
        emit(s, "footstep", {x = hero.x, y = 0, terrain = ash and "ash" or s.terrain, motion = nextMotion})
    end
end
local function updateCamera(s)
    s.world.previousCameraX = s.world.cameraX
    if s.phase == "combat" and s.encounterStage == "active" and s.beat.arenaCamera ~= nil then
        s.world.cameraX = s.beat.arenaCamera
        s.distance = s.world.hero.x
        return
    end
    local target = s.world.hero.x - HERO_SCREEN_X
    local ____s_world_57, ____cameraX_58 = s.world, "cameraX"
    ____s_world_57[____cameraX_58] = ____s_world_57[____cameraX_58] + (target - s.world.cameraX) * (1 - math.exp(-6 * ____exports.FIXED_STEP))
    s.distance = s.world.hero.x
end
local function updateCombat(s)
    local e = s.enemy
    if not e or s.phase ~= "combat" or s.encounterStage ~= "active" then
        return
    end
    local def = __TS__ArrayFind(
        ENEMIES,
        function(____, item) return item.id == e.definitionId end
    )
    local recovering = e.broken > 0
    e.broken = math.max(0, e.broken - ____exports.FIXED_STEP)
    if e.burn > 0 then
        e.burn = e.burn - ____exports.FIXED_STEP
        e.burnTick = e.burnTick - ____exports.FIXED_STEP
        if e.burnTick <= 0 then
            e.burnTick = e.burnTick + 0.8
            hurtEnemy(
                s,
                2.5,
                true,
                "burn",
                "spark"
            )
        end
    end
    if s.enemy ~= e then
        return
    end
    if recovering then
        e.heavyIntentRemaining = 0
        return
    end
    if e.attackStage == "stone-open" and e.actionTime >= 0.45 then
        e.attackStage = nil
    end
    if e.attackBeat == nil then
        e.attackBeat = 1
    end
    e.attackTimer = e.attackTimer - ____exports.FIXED_STEP
    local every = def.heavyEvery or 7
    local heavy = e.attackBeat % every == 0
    local toHeavy = e.attackTimer + (every - e.attackBeat % every) % every * e.attackInterval
    e.heavyIntentRemaining = toHeavy > 0 and toHeavy <= 2 + 1e-8 and toHeavy or 0
    if not e.heavyAnnounced and toHeavy <= 2 + 1e-8 then
        e.heavyAnnounced = true
        emit(
            s,
            "telegraph",
            {
                stage = "intent",
                heavy = true,
                enemyId = e.id,
                ability = e.ability,
                duration = math.max(0, toHeavy),
                x = e.x,
                y = 0,
                targetX = s.world.hero.x
            }
        )
    end
    local windup = heavy and (def.heavyWindup or 0.84) or 0.18
    if e.attackTimer <= windup + 1e-8 and not jsTruthy(e.attackId) then
        e.attackId = attackId(s, e.id)
        e.attackHeavy = heavy
        e.telegraphTotal = windup
        e.attackStage = heavy and (e.ability == "arrow" and "draw" or (e.ability == "binding" and "binding-cast" or (e.ability == "stone" and "stone-closed" or (e.ability == "thunder" and "thunder-gather" or "windup")))) or "windup"
        motion(e, heavy and "attack2" or "attack", true)
        emit(
            s,
            "telegraph",
            {
                stage = "windup",
                attackId = e.attackId,
                heavy = heavy,
                enemyId = e.id,
                ability = e.ability,
                duration = math.max(0, e.attackTimer),
                x = e.x,
                y = 0,
                targetX = s.world.hero.x
            }
        )
    end
    e.telegraph = jsTruthy(e.attackId) and math.max(0, e.attackTimer) or 0
    if e.attackTimer > 1e-8 then
        return
    end
    local id = e.attackId or attackId(s, e.id)
    local scale = e.damage / def.damage
    local amount = (heavy and (def.heavyDamage or e.damage * 2.8) or def.damage) * scale
    local hit = {
        remaining = 0,
        amount = amount,
        ability = e.ability,
        enemyId = e.id,
        attackId = id,
        parryable = heavy,
        committed = false,
        sourceX = e.x,
        targetX = s.world.hero.x,
        heavy = heavy
    }
    emit(s, "enemy-attack", {
        attackId = id,
        enemyId = e.id,
        ability = e.ability,
        heavy = heavy,
        combo = 1,
        x = e.x,
        y = 0,
        targetX = s.world.hero.x,
        targetY = 0,
        fx = e.fx
    })
    local inRange = math.abs(e.x - s.world.hero.x) <= e.attackRange + 24
    local parried = false
    if not inRange then
        emit(s, "enemy-miss", {attackId = id, enemyId = e.id, x = e.x, y = 0})
    elseif e.ability == "arrow" or e.ability == "thunder" then
        local duration = e.ability == "arrow" and 0.42 or 0.35
        local ____s_pendingEnemyHits_59 = s.pendingEnemyHits
        ____s_pendingEnemyHits_59[#____s_pendingEnemyHits_59 + 1] = __TS__ObjectAssign({}, hit, {remaining = duration, committed = true, parryable = e.ability == "arrow"})
        emit(s, "projectile", {
            attackId = id,
            enemyId = e.id,
            ability = e.ability,
            heavy = heavy,
            duration = duration,
            x = e.x,
            y = 30,
            targetX = s.world.hero.x,
            targetY = 24
        })
    else
        parried = resolveEnemyHit(s, hit)
    end
    if heavy and e.ability == "pyre" and not parried and inRange and s.resolve > 0 then
        local follow = __TS__ObjectAssign({}, hit, {
            attackId = id .. ":fireline",
            remaining = 0.7,
            amount = 16 * scale,
            ability = "pyre-combo",
            parryable = false,
            committed = true
        })
        local ____s_pendingEnemyHits_60 = s.pendingEnemyHits
        ____s_pendingEnemyHits_60[#____s_pendingEnemyHits_60 + 1] = follow
        emit(s, "telegraph", {
            stage = "fireline",
            attackId = follow.attackId,
            enemyId = e.id,
            ability = follow.ability,
            duration = 0.7,
            heavy = true,
            x = s.world.hero.x,
            y = 0
        })
    end
    if s.enemy ~= e then
        return
    end
    e.attackTimer = e.attackTimer + e.attackInterval
    e.attackBeat = e.attackBeat + 1
    e.attackId = nil
    e.attackHeavy = false
    e.telegraph = 0
    e.attackStage = heavy and e.ability == "stone" and not parried and "stone-open" or nil
    if e.attackStage == "stone-open" then
        motion(e, "attack2", true)
    end
    if heavy then
        e.heavyAnnounced = false
    end
end
local function fixedUpdate(s)
    s.ticks = s.ticks + 1
    s.elapsed = s.ticks * ____exports.FIXED_STEP
    local c = combatState(s)
    s.strokeBudget = math.min(RULES.rewardRate, s.strokeBudget + ____exports.FIXED_STEP * RULES.rewardRate)
    s.strokeMomentum = math.max(0, s.strokeMomentum - ____exports.FIXED_STEP * 0.7)
    s.semanticCooldown = math.max(0, s.semanticCooldown - ____exports.FIXED_STEP)
    s.exitTime = math.max(0, s.exitTime - ____exports.FIXED_STEP)
    for ____, id in ipairs(SKILL_IDS) do
        s.cooldowns[id] = math.max(0, s.cooldowns[id] - ____exports.FIXED_STEP)
    end
    for ____, key in ipairs({
        "guardCooldown",
        "guardRemaining",
        "guardPerfectRemaining",
        "surgeRemaining",
        "surgeCooldown",
        "rebuildRemaining"
    }) do
        local previous = c[key]
        c[key] = math.max(0, previous - ____exports.FIXED_STEP)
        if key == "surgeRemaining" and previous > 0 and c[key] == 0 then
            emit(s, "surge", {stage = "end", x = s.world.hero.x, y = 0})
        end
    end
    if jsTruthy(jsAnd(
        c.pendingCommand,
        function() return s.elapsed - c.commandAt >= 0.28 end
    )) then
        releaseCommand(s, c.pendingCommand, c.pendingBlockedReason)
    end
    if jsTruthy(jsAnd(
        jsOr(
            c.commandStream,
            function() return c.command end
        ),
        function() return s.elapsed - c.commandAt > RULES.commandGap end
    )) then
        ____exports.clearCombatCommand(s)
    end
    for ____, burn in ipairs(s.world.burns or ({})) do
        burn.age = burn.age + ____exports.FIXED_STEP
    end
    for ____, id in ipairs(__TS__ObjectKeys(s.buffs)) do
        s.buffs[id] = math.max(0, s.buffs[id] - ____exports.FIXED_STEP)
    end
    advancePendingHits(s)
    if s.phase == "fallen" then
        advanceHeadthrow(s)
        local ____s_world_hero_61, ____actionTime_62 = s.world.hero, "actionTime"
        ____s_world_hero_61[____actionTime_62] = ____s_world_hero_61[____actionTime_62] + ____exports.FIXED_STEP
        s.fallenTime = s.fallenTime + ____exports.FIXED_STEP
        if s.fallenTime >= 4.8 - s.upgrades.adaptation * 0.45 then
            ____exports.retry(s)
        end
        refreshInferno(s)
        return
    end
    s.heat = math.max(0, s.heat - ____exports.FIXED_STEP * 7)
    local idle = math.max(0, s.elapsed - s.lastStrokeTime)
    if s.beat.combo > 0 and s.elapsed - s.beat.last > 2 then
        s.beat.combo = 0
        c.strokeCharge = 0
        emit(s, "combo-lost")
    end
    if s.autoWalk and (not s.qte or s.qte.kind == "combat") then
        local drain = s.phase == "combat" and s.encounterStage == "active" and RULES.drain or 0.62 + math.min(
            2.5,
            math.max(0, idle - 2) * 0.65
        )
        s.resolve = math.max(0, s.resolve - ____exports.FIXED_STEP * drain)
        if idle > 1.5 then
            s.rage = math.max(0, s.rage - ____exports.FIXED_STEP * 3)
        end
    end
    if s.resolve <= 0 then
        fall(s)
        return
    end
    if s.qte and s.qte.remaining ~= nil then
        s.qte.remaining = math.max(0, s.qte.remaining - ____exports.FIXED_STEP)
        if s.qte.remaining <= 1e-9 then
            clearQte(s, "miss")
        end
    end
    advanceHeadthrow(s)
    updateEnvironment(s)
    moveWorld(s)
    if s.phase == "crawl" then
        if s.crawlStage == 1 and s.world.hero.x >= 24 and not s.qte then
            startQte(s, {
                id = "opening-hand",
                kind = "story",
                action = "memory",
                label = "把手撑在灰上。",
                target = "伸出手",
                pinyin = "shen chu shou",
                remaining = nil
            })
        elseif s.crawlStage == 2 and s.world.hero.x >= 64 and not s.qte then
            startQte(s, {
                id = "opening-stand",
                kind = "story",
                action = "stand",
                label = "让膝盖接住身体。",
                target = "站起来",
                pinyin = "zhan qi lai",
                remaining = nil
            })
        elseif s.crawlStage == 3 and s.world.hero.actionTime >= 0.7 then
            completeCrawl(s)
        end
    elseif s.phase == "journey" and not s.qte and not s.headthrow and s.exitTime <= 0 then
        local encounter = ENCOUNTERS[s.encounterIndex + 1]
        if encounter and encounter.chapter == s.chapter and s.world.hero.x >= encounter.spawnAt then
            makeEnemy(s)
        elseif encounter and encounter.chapter > s.chapter and s.world.hero.x >= CHAPTERS[s.chapter + 1].endX then
            s.world.hero.vx = 0
            motion(s.world.hero, "idle")
            phase(s, "rest")
            emit(s, "story", {storyIndex = s.chapter + 1, text = STORIES[s.chapter + 1 + 1].text})
        end
    end
    updateCombat(s)
    updateCamera(s)
    refreshInferno(s)
end
--- Only processed fixed steps advance business time; suspended tabs never replay an unbounded queue.
function ____exports.tick(s, dt)
    if s.paused or not __TS__NumberIsFinite(dt) or dt <= 0 or __TS__ArrayIncludes({"title", "rest", "ending"}, s.phase) then
        return
    end
    s.accumulator = s.accumulator + math.min(dt, 5)
    while s.accumulator + 1e-9 >= ____exports.FIXED_STEP do
        s.accumulator = math.max(0, s.accumulator - ____exports.FIXED_STEP)
        fixedUpdate(s)
        if __TS__ArrayIncludes({"rest", "ending"}, s.phase) then
            s.accumulator = 0
            break
        end
    end
end
function ____exports.stroke(s, input)
    if s.paused or __TS__ArrayIncludes({"title", "rest", "ending"}, s.phase) or not validReceipt(input and input.id) or type(input.key) ~= "string" or not validReceipt(input.source) then
        return false
    end
    if input.key == "Backspace" then
        if not s.qte and not jsTruthy(s.phase == "combat" and combatState(s).command) then
            return false
        end
        if not remember(s.acceptedStrokeIds, input.id) then
            return false
        end
        if s.qte then
            s.qte.progress = math.max(0, s.qte.progress - 1)
            emit(
                s,
                "qte-progress",
                {
                    qteId = s.qte.id,
                    amount = s.qte.progress,
                    total = jsLength(s.qte.pinyin),
                    x = s.world.hero.x,
                    y = 0
                }
            )
        else
            commandStroke(s, input.key)
        end
        return true
    end
    if not isPrintableKey(input.key) or not remember(s.acceptedStrokeIds, input.id) then
        return false
    end
    local ____s_metrics_65, ____strokes_66 = s.metrics, "strokes"
    ____s_metrics_65[____strokes_66] = ____s_metrics_65[____strokes_66] + 1
    local originalContext = s.inputContext
    local q = s.qte
    local budgeted = s.strokeBudget >= 1 - 1e-8
    local correct = not q or jsLower(input.key) == jsCharAt(q.pinyin, q.progress)
    local ____temp_68 = s.phase ~= "fallen" and correct
    if ____temp_68 then
        local ____q_67
        if q then
            ____q_67 = q.kind ~= "combat" or budgeted
        else
            ____q_67 = budgeted
        end
        ____temp_68 = ____q_67
    end
    local effective = ____temp_68
    if effective then
        s.lastStrokeTime = s.elapsed
        local gap = s.elapsed - s.beat.last
        if gap > 0.02 then
            s.beat.interval = s.beat.interval * 0.65 + math.min(2, gap) * 0.35
        end
        s.beat.combo = gap <= 2 and s.beat.combo + 1 or 1
        s.beat.best = math.max(s.beat.best, s.beat.combo)
        s.beat.last = s.elapsed
    end
    emit(s, "stroke", {
        key = input.key,
        source = input.source,
        context = originalContext,
        rewarded = effective,
        combo = s.beat.combo,
        x = s.world.hero.x,
        y = 0
    })
    if q then
        if not correct then
            q.mistakes = q.mistakes + 1
            local typed = jsSlice(q.pinyin, 0, q.progress) .. jsLower(input.key)
            local matched = math.min(
                jsLength(typed),
                jsLength(q.pinyin)
            )
            while matched > 0 and not __TS__StringEndsWith(
                typed,
                jsSlice(q.pinyin, 0, matched)
            ) do
                matched = matched - 1
            end
            q.progress = matched
        else
            q.progress = q.progress + 1
        end
        emit(
            s,
            "qte-progress",
            {
                qteId = q.id,
                amount = q.progress,
                total = jsLength(q.pinyin),
                x = s.world.hero.x,
                y = 0
            }
        )
        if q.progress >= jsLength(q.pinyin) then
            completeQte(s)
        end
        return true
    end
    if s.phase == "fallen" then
        return true
    end
    if effective then
        s.strokeBudget = math.max(0, s.strokeBudget - 1)
        local ____s_metrics_69, ____pulses_70 = s.metrics, "pulses"
        ____s_metrics_69[____pulses_70] = ____s_metrics_69[____pulses_70] + 1
        s.strokeMomentum = math.min(2, s.strokeMomentum + 0.4)
        local active = s.phase == "combat" and s.encounterStage == "active" and not not s.enemy
        gainResolve(
            s,
            active and strokeRecovery(s) or 1.05
        )
        gainRage(s, active and RULES.strokeRage or 0.2)
        s.heat = math.min(100, s.heat + 6)
        if active then
            local c = combatState(s)
            c.strokeCharge = math.min(RULES.strokesPerPunch, c.strokeCharge + 1)
            if c.strokeCharge >= RULES.strokesPerPunch and s.elapsed - c.lastPunch >= RULES.punchInterval - 1e-8 and math.abs(s.enemy.x - s.world.hero.x) <= 65 then
                c.strokeCharge = c.strokeCharge - RULES.strokesPerPunch
                c.lastPunch = s.elapsed
                local id = attackId(s, "punch")
                if not s.headthrow then
                    motion(s.world.hero, s.beat.combo % 2 ~= 0 and "attack" or "attack2", true)
                end
                emit(s, "attack", {
                    attackId = id,
                    enemyId = s.enemy.id,
                    x = s.world.hero.x,
                    y = 0,
                    targetX = s.enemy.x,
                    source = "stroke"
                })
                hurtEnemy(
                    s,
                    RULES.punchDamage * (1 + s.upgrades.hatred * 0.14),
                    false,
                    "stroke",
                    nil,
                    id
                )
            end
        end
    end
    commandStroke(s, input.key)
    refreshInferno(s)
    return true
end
function ____exports.grantSemantic(s, input)
    if s.paused or __TS__ArrayIncludes({"title", "rest", "ending", "fallen"}, s.phase) or not validReceipt(input and input.id) or not validReceipt(input.segmentId) or type(input.text) ~= "string" or type(input.pinyin) ~= "string" then
        return false
    end
    if not remember(s.acceptedSemanticIds, input.id) then
        return false
    end
    if s.inputContext ~= "free" or not remember(s.acceptedSegments, input.segmentId, 128) then
        return false
    end
    local text = jsSlice(
        hanText(input.text),
        0,
        32
    )
    if not jsTruthy(text) or s.semanticCooldown > 0 then
        return false
    end
    s.semanticCooldown = 2.5
    local ____s_metrics_73, ____semantics_74 = s.metrics, "semantics"
    ____s_metrics_73[____semantics_74] = ____s_metrics_73[____semantics_74] + 1
    local ____s_metrics_75, ____commits_76 = s.metrics, "commits"
    ____s_metrics_75[____commits_76] = ____s_metrics_75[____commits_76] + 1
    local ____s_metrics_77, ____words_78 = s.metrics, "words"
    ____s_metrics_77[____words_78] = ____s_metrics_77[____words_78] + 1
    local theme = stableSort(
        __TS__ArrayFilter(
            SEMANTIC_THEMES,
            function(____, item) return __TS__StringIncludes(text, item.phrase) end
        ),
        function(a, b) return #b.phrase - #a.phrase end
    )[1]
    local ____theme_82
    if theme then
        local ____s_semanticCategoryCounts_79, ____theme_category_80 = s.semanticCategoryCounts, theme.category
        local ____s_semanticCategoryCounts_theme_category_81 = ____s_semanticCategoryCounts_79[____theme_category_80]
        ____s_semanticCategoryCounts_79[____theme_category_80] = ____s_semanticCategoryCounts_theme_category_81 + 1
        ____theme_82 = 1 / (1 + ____s_semanticCategoryCounts_theme_category_81 * 0.5)
    else
        ____theme_82 = 1
    end
    local factor = ____theme_82
    local resolveAmount = theme and theme.resolve * factor or math.min(
        0.6,
        jsLength(text) * 0.15
    )
    local rageAmount = theme and theme.rage * factor or 0.35
    gainResolve(s, resolveAmount)
    gainRage(s, rageAmount)
    if jsTruthy(theme and theme.memory) then
        s.buffs.memory = math.max(s.buffs.memory, theme.memory * factor)
    end
    emit(
        s,
        "semantic",
        {
            text = text,
            pinyin = jsSlice(input.pinyin, 0, 128),
            category = theme and theme.category or "ordinary",
            matchId = theme and theme.id,
            source = input.source or "pinyin",
            amount = resolveAmount + rageAmount,
            resolveAmount = resolveAmount,
            rageAmount = rageAmount,
            diminishing = factor,
            x = s.world.hero.x,
            y = 0
        }
    )
    local memory = __TS__ArrayFind(
        MEMORIES,
        function(____, m) return m.text == text end
    )
    if memory then
        emit(s, "memory", {
            text = memory.text,
            pinyin = memory.pinyin,
            category = memory.category,
            curated = true,
            x = s.world.hero.x,
            y = 0
        })
    end
    return true
end
function ____exports.buyUpgrade(s, branch)
    if s.paused and s.phase == "title" or not __TS__ArrayIncludes(BRANCH_IDS, branch) or s.skillPoints < 1 or s.upgrades[branch] >= 3 or __TS__ArrayIncludes({"title", "ending"}, s.phase) then
        return false
    end
    s.skillPoints = s.skillPoints - 1
    local ____s_upgrades_99, ____branch_100 = s.upgrades, branch
    ____s_upgrades_99[____branch_100] = ____s_upgrades_99[____branch_100] + 1
    if branch == "adaptation" then
        s.maxResolve = s.maxResolve + 12
        gainResolve(s, 12)
    end
    emit(
        s,
        "upgrade",
        {
            branch = branch,
            level = s.upgrades[branch],
            text = __TS__ArrayFind(
                BRANCHES,
                function(____, d) return d.id == branch end
            ).name,
            x = s.world.hero.x,
            y = 0
        }
    )
    return true
end
function ____exports.upgradeSkill(s, id)
    if not __TS__ArrayIncludes(SKILL_IDS, id) or __TS__ArrayIncludes({"title", "ending"}, s.phase) or s.skillPoints < 1 or s.skills[id] < 1 or s.skills[id] >= 3 then
        return false
    end
    s.skillPoints = s.skillPoints - 1
    local ____s_skills_101, ____id_102 = s.skills, id
    ____s_skills_101[____id_102] = ____s_skills_101[____id_102] + 1
    emit(
        s,
        "skill-upgrade",
        {
            skill = id,
            level = s.skills[id],
            text = __TS__ArrayFind(
                SKILLS,
                function(____, d) return d.id == id end
            ).levels[s.skills[id]],
            x = s.world.hero.x,
            y = 0
        }
    )
    return true
end
function ____exports.equipSkill(s, id, slot)
    if slot == nil then
        slot = 0
    end
    if not __TS__ArrayIncludes(SKILL_IDS, id) or s.skills[id] < 1 or not __TS__NumberIsInteger(slot) or slot < 0 or slot > math.min(2, #s.equipped) then
        return false
    end
    if __TS__ArrayIncludes(s.equipped, id) then
        return true
    end
    s.equipped[slot + 1] = id
    emit(s, "equip", {skill = id, slot = slot})
    return true
end
--- V1 is deliberately left in its original storage slot, never silently rewritten as V2.
function ____exports.restoreGame(value)
    local v = dataObject(value)
    if v.version ~= 2 or not __TS__ArrayIncludes(PHASES, v.phase) then
        return nil
    end
    local s = ____exports.createGame(finite(v.seed, 831105, 1, 4294967295))
    local savedCombat = dataObject(v.combat)
    local currentRules = savedCombat.rulesVersion == RULES.version
    s.phase = v.phase
    s.chapter = __TS__MathTrunc(finite(v.chapter, 0, 0, 4))
    s.encounterIndex = __TS__MathTrunc(finite(v.encounterIndex, 0, 0, 15))
    s.paused = v.paused == true
    s.autoWalk = v.autoWalk == true
    local numeric = {
        "rage",
        "heat",
        "ember",
        "deaths",
        "storyIndex",
        "chapterProgress",
        "frenzyRemaining",
        "frenzyProgress",
        "frenzyCooldown",
        "combatQteMisses",
        "semanticCooldown",
        "strokeBudget",
        "strokeMomentum",
        "crawlStage",
        "fallenTime",
        "exitTime",
        "autoAttackTimer",
        "footstepDistance",
        "lastStrokeTime",
        "memoryIndex",
        "eventSerial",
        "rng"
    }
    for ____, key in ipairs(numeric) do
        s[key] = finite(v[key], s[key], key == "lastStrokeTime" and -100 or 0)
    end
    s.ticks = __TS__MathTrunc(finite(
        v.ticks,
        finite(v.elapsed) / ____exports.FIXED_STEP,
        0,
        100000000
    ))
    s.elapsed = s.ticks * ____exports.FIXED_STEP
    s.accumulator = finite(v.accumulator, 0, 0, ____exports.FIXED_STEP)
    for ____, id in ipairs(SKILL_IDS) do
        s.skills[id] = __TS__MathTrunc(finite(
            dataObject(v.skills)[id],
            s.skills[id],
            0,
            3
        ))
        s.cooldowns[id] = finite(
            dataObject(v.cooldowns)[id],
            0,
            0,
            60
        )
    end
    for ____, id in ipairs(BRANCH_IDS) do
        s.upgrades[id] = __TS__MathTrunc(finite(
            dataObject(v.upgrades)[id],
            0,
            0,
            3
        ))
    end
    s.skills.spark = math.max(1, s.skills.spark)
    s.skills.rebirth = math.max(1, s.skills.rebirth)
    s.maxResolve = 100 + s.upgrades.adaptation * 12
    s.resolve = finite(v.resolve, 78, 0, s.maxResolve)
    s.rage = clamp(s.rage, 0, 100)
    s.heat = clamp(s.heat, 0, 100)
    s.strokeBudget = clamp(s.strokeBudget, 0, RULES.rewardRate)
    s.strokeMomentum = clamp(s.strokeMomentum, 0, 2)
    s.combatQteMisses = __TS__MathTrunc(clamp(s.combatQteMisses, 0, 2))
    s.frenzyRemaining = clamp(s.frenzyRemaining, 0, 6)
    s.frenzyCooldown = clamp(s.frenzyCooldown, 0, 60)
    s.crawlStage = __TS__MathTrunc(clamp(s.crawlStage, 0, 3))
    s.storyIndex = __TS__MathTrunc(clamp(s.storyIndex, 0, 5))
    s.chapterProgress = clamp(s.chapterProgress, 0, 1)
    s.frenzyRemaining = 0
    s.frenzyCooldown = 0
    local function receipts(raw, max)
        return jsIsArray(raw) and __TS__ArraySlice(
            {__TS__Spread(__TS__New(
                Set,
                __TS__ArrayFilter(
                    raw,
                    function(____, id) return validReceipt(id) end
                )
            ))},
            -max
        ) or ({})
    end
    s.acceptedStrokeIds = receipts(v.acceptedStrokeIds, 256)
    s.acceptedSemanticIds = receipts(v.acceptedSemanticIds, 256)
    s.acceptedSegments = receipts(v.acceptedSegments, 128)
    s.completedMilestones = receipts(v.completedMilestones, 100)
    local rewardIds = __TS__New(
        Set,
        {
            "opening",
            table.unpack(__TS__ArrayMap(
                ENCOUNTERS,
                function(____, e) return e.id end
            ))
        }
    )
    s.rewardedEncounters = __TS__ArrayFilter(
        receipts(v.rewardedEncounters, 16),
        function(____, id) return rewardIds:has(id) end
    )
    s.totalSkillPointsEarned = __TS__ArrayReduce(
        s.rewardedEncounters,
        function(____, sum, id) return sum + (id == "opening" and 1 or __TS__ArrayFind(
            ENCOUNTERS,
            function(____, e) return e.id == id end
        ).reward) end,
        0
    )
    local spent = __TS__ArrayReduce(
        BRANCH_IDS,
        function(____, sum, id) return sum + s.upgrades[id] end,
        0
    ) + __TS__ArrayReduce(
        SKILL_IDS,
        function(____, sum, id) return sum + math.max(0, s.skills[id] - 1) end,
        0
    )
    s.skillPoints = clamp(
        __TS__MathTrunc(finite(v.skillPoints)),
        0,
        math.max(0, s.totalSkillPointsEarned - spent)
    )
    s.kills = #__TS__ArrayFilter(
        s.rewardedEncounters,
        function(____, id) return id ~= "opening" end
    )
    s.equipped = (jsIsArray(v.equipped) and __TS__ArraySlice(
        {__TS__Spread(__TS__New(
            Set,
            __TS__ArrayFilter(
                v.equipped,
                function(____, id) return __TS__ArrayIncludes(SKILL_IDS, id) and s.skills[id] > 0 end
            )
        ))},
        0,
        3
    ) or ({"spark", "rebirth"})) --[[@as string[] ]]
    if not jsTruthy(#s.equipped) then
        s.equipped = {"spark", "rebirth"}
    end
    for ____, key in ipairs(__TS__ObjectKeys(s.buffs)) do
        s.buffs[key] = finite(
            dataObject(v.buffs)[key],
            0,
            0,
            30
        )
    end
    for ____, key in ipairs(__TS__ObjectKeys(s.metrics)) do
        s.metrics[key] = finite(dataObject(v.metrics)[key])
    end
    local w = dataObject(v.world)
    local hero = dataObject(w.hero)
    local ____s_world_107 = s.world
    local ____finite_result_104 = finite(hero.x)
    local ____finite_result_105 = finite(hero.vx, 0, 0, RUN_SPEED + 2)
    local ____temp_106 = hero.facing == -1 and -1 or 1
    local ____MOTIONS_includes_result_103
    if __TS__ArrayIncludes(MOTIONS, hero.motion) then
        ____MOTIONS_includes_result_103 = hero.motion
    else
        ____MOTIONS_includes_result_103 = "idle"
    end
    ____s_world_107.hero = {
        x = ____finite_result_104,
        y = 0,
        vx = ____finite_result_105,
        facing = ____temp_106,
        motion = ____MOTIONS_includes_result_103,
        actionTime = finite(hero.actionTime)
    }
    s.world.cameraX = finite(w.cameraX, s.world.hero.x - HERO_SCREEN_X, -10000000)
    s.world.previousCameraX = finite(w.previousCameraX, s.world.cameraX, -10000000)
    s.world.checkpointX = finite(w.checkpointX, CHAPTERS[s.chapter + 1].startX, 0, s.world.hero.x)
    s.world.routeEndX = finite(w.routeEndX, CHAPTERS[5].endX, s.world.hero.x, 1000000)
    for ____, prop in ipairs(s.world.props) do
        local ____jsIsArray_result_111
        if jsIsArray(w.props) then
            ____jsIsArray_result_111 = __TS__ArrayFind(
                w.props,
                function(____, p)
                    local ____opt_result_110
                    if p ~= nil then
                        ____opt_result_110 = p.id
                    end
                    return ____opt_result_110 == prop.id
                end
            )
        else
            ____jsIsArray_result_111 = nil
        end
        local saved = ____jsIsArray_result_111
        if jsTruthy(saved) then
            if __TS__ArrayIncludes({"intact", "active", "cleared", "passed"}, saved.state) then
                prop.state = saved.state
            end
            prop.progress = finite(saved.progress, 0, 0, 10)
            if prop.id == "sisters-bead" and s.kills == 15 then
                prop.x = finite(saved.x, prop.x)
            end
        end
    end
    s.distance = s.world.hero.x
    s.terrain = CHAPTERS[s.chapter + 1].terrain
    local e = dataObject(v.enemy)
    local encounter = ENCOUNTERS[s.encounterIndex + 1]
    if encounter and e.id == encounter.id and (s.phase == "combat" or s.phase == "fallen") then
        local def = __TS__ArrayFind(
            ENEMIES,
            function(____, d) return d.id == encounter.enemyId end
        )
        local maxHp = finite(e.maxHp, def.hp * (1 + (encounter.chapter - 1) * 0.13), 1, 10000)
        local ____encounter_id_113 = encounter.id
        local ____def_id_114 = def.id
        local ____def_name_115 = def.name
        local ____def_kind_116 = def.kind
        local ____def_ability_117 = def.ability
        local ____finite_result_118 = finite(e.x, encounter.enemyX)
        local ____finite_result_119 = finite(e.vx, 0, -30, 30)
        local ____temp_120 = e.facing == 1 and 1 or -1
        local ____MOTIONS_includes_result_112
        if __TS__ArrayIncludes(MOTIONS, e.motion) then
            ____MOTIONS_includes_result_112 = e.motion
        else
            ____MOTIONS_includes_result_112 = "idle"
        end
        s.enemy = {
            id = ____encounter_id_113,
            definitionId = ____def_id_114,
            name = ____def_name_115,
            kind = ____def_kind_116,
            ability = ____def_ability_117,
            x = ____finite_result_118,
            y = 0,
            vx = ____finite_result_119,
            facing = ____temp_120,
            motion = ____MOTIONS_includes_result_112,
            actionTime = finite(e.actionTime),
            hp = finite(e.hp, maxHp, 0.001, maxHp),
            maxHp = maxHp,
            phase = __TS__MathTrunc(finite(e.phase, 1, 1, def.kind == "boss" and 2 or 1)),
            attackTimer = finite(e.attackTimer, def.interval, 0, currentRules and def.interval or 30),
            telegraph = finite(e.telegraph, 0, 0, 8),
            telegraphTotal = finite(e.telegraphTotal, def.telegraph, 0.5, 8),
            armor = finite(e.armor, def.armor, 0, 0.8),
            breakProgress = finite(e.breakProgress, 0, 0, 20),
            breakThreshold = finite(e.breakThreshold, def.kind == "boss" and 6 or (def.kind == "elite" and 5 or 3.6), 1, 20),
            damage = finite(e.damage, def.damage, 1, 100),
            attackInterval = finite(e.attackInterval, def.interval, 1, 30),
            attackMercy = finite(e.attackMercy, 1, 0.7, 1),
            shield = finite(e.shield, 0, 0, 100),
            broken = finite(e.broken, 0, 0, 10),
            burn = finite(e.burn, 0, 0, 10),
            burnTick = finite(e.burnTick, 0.8, 0, 2),
            attackRange = def.attackRange,
            fx = def.fx,
            fleeing = e.fleeing == true
        }
    end
    s.encounterStyle = "hold"
    s.encounterStage = s.enemy and (v.encounterStage == "approach" and "approach" or "active") or "exit"
    if s.phase == "combat" and not s.enemy then
        s.phase = s.autoWalk and "journey" or "crawl"
    end
    local q = dataObject(v.qte)
    if type(q.id) == "string" and jsLength(q.id) <= 80 and __TS__ArrayIncludes({"story", "combat", "environment"}, q.kind) and type(q.pinyin) == "string" and isPinyin(q.pinyin) and type(q.target) == "string" and jsLength(q.target) <= 64 and type(q.label) == "string" and jsLength(q.label) <= 500 and __TS__ArrayIncludes({
        "wake",
        "stand",
        "memory",
        "environment",
        "interrupt",
        "evade",
        "unbind",
        "shatter",
        "still",
        "release"
    }, q.action) then
        local ____temp_124 = q.kind ~= "combat"
        if not ____temp_124 then
            local ____q_enemyId_123 = q.enemyId
            local ____opt_121 = s.enemy
            ____temp_124 = ____q_enemyId_123 == (____opt_121 and ____opt_121.id)
        end
        if ____temp_124 then
            local ____q_id_126 = q.id
            local ____q_kind_127 = q.kind
            local ____q_action_128 = q.action
            local ____q_label_129 = q.label
            local ____q_target_130 = q.target
            local ____q_pinyin_131 = q.pinyin
            local ____TS__MathTrunc_result_132 = __TS__MathTrunc(finite(
                q.progress,
                0,
                0,
                jsLength(q.pinyin) - 1
            ))
            local ____jsNullProperty_result_125
            if jsNullProperty(q, "remaining") then
                ____jsNullProperty_result_125 = nil
            else
                ____jsNullProperty_result_125 = finite(q.remaining, 3, 0.01, 10)
            end
            s.qte = __TS__ObjectAssign(
                {
                    id = ____q_id_126,
                    kind = ____q_kind_127,
                    action = ____q_action_128,
                    label = ____q_label_129,
                    target = ____q_target_130,
                    pinyin = ____q_pinyin_131,
                    progress = ____TS__MathTrunc_result_132,
                    remaining = ____jsNullProperty_result_125,
                    mistakes = __TS__MathTrunc(finite(q.mistakes))
                },
                __TS__ArrayIncludes(SKILL_IDS, q.skill) and ({skill = q.skill}) or ({}),
                __TS__ArraySome(
                    ENVIRONMENTS,
                    function(____, p) return p.id == q.propId end
                ) and ({propId = q.propId}) or ({}),
                s.enemy and q.enemyId == s.enemy.id and ({enemyId = q.enemyId}) or ({})
            )
        end
    end
    local head = dataObject(v.headthrow)
    if __TS__ArrayIncludes({"flight", "rebuild"}, head.stage) and type(head.startX) == "number" and type(head.targetX) == "number" and __TS__NumberIsFinite(head.startX) and __TS__NumberIsFinite(head.targetX) then
        s.headthrow = __TS__ObjectAssign(
            {
                stage = head.stage,
                elapsed = finite(head.elapsed, 0, 0, head.stage == "flight" and 0.62 or 0.5),
                startX = finite(head.startX),
                targetX = finite(head.targetX, s.world.hero.x, head.startX, head.startX + 300),
                headX = finite(head.headX, s.world.hero.x),
                headY = finite(head.headY, 36, 0, 70),
                heroVisible = true,
                headless = head.stage == "flight",
                bodyAlpha = finite(head.bodyAlpha, 1, 0, 1)
            },
            __TS__ArraySome(
                ENVIRONMENTS,
                function(____, p) return p.id == head.propId end
            ) and ({propId = head.propId}) or ({})
        )
    end
    if s.enemy then
        local def = __TS__ArrayFind(
            ENEMIES,
            function(____, item) return item.id == s.enemy.definitionId end
        )
        s.enemy.attackBeat = currentRules and __TS__MathTrunc(finite(e.attackBeat, 1, 1, 100000)) or 1
        s.enemy.attackTimer = currentRules and s.enemy.attackTimer or math.min(def.interval, s.enemy.attackTimer)
        s.enemy.attackInterval = currentRules and s.enemy.attackInterval or def.interval
        s.enemy.damage = currentRules and s.enemy.damage or def.damage * (1 + (s.chapter - 1) * 0.09)
        local ____s_enemy_134 = s.enemy
        local ____temp_133
        if currentRules and validReceipt(e.attackId) then
            ____temp_133 = e.attackId
        else
            ____temp_133 = nil
        end
        ____s_enemy_134.attackId = ____temp_133
        s.enemy.attackHeavy = currentRules and e.attackHeavy == true
        s.enemy.heavyAnnounced = currentRules and e.heavyAnnounced == true
        s.enemy.heavyIntentRemaining = currentRules and finite(e.heavyIntentRemaining, 0, 0, 2) or 0
        s.pendingHits = jsIsArray(v.pendingHits) and __TS__ArrayMap(
            __TS__ArraySlice(
                __TS__ArrayFilter(
                    v.pendingHits,
                    function(____, h) return jsAnd(
                        jsAnd(
                            h,
                            function() return h.enemyId == s.enemy.id end
                        ),
                        function() return __TS__ArrayIncludes(SKILL_IDS, h.skill) end
                    ) end
                ),
                0,
                16
            ),
            function(____, h) return {
                remaining = finite(h.remaining, 0, 0, 2),
                amount = finite(h.amount, 0, 0, 200),
                bypass = h.bypass == true,
                skill = h.skill,
                enemyId = s.enemy.id,
                impactX = finite(h.impactX, s.enemy.x)
            } end
        ) or ({})
        local stages = {
            "windup",
            "draw",
            "arrow-flight",
            "binding-cast",
            "binding",
            "stone-closed",
            "stone-open",
            "thunder-gather",
            "thunder-mark",
            "thunder-hold",
            "pyre-line"
        }
        if currentRules and __TS__ArrayIncludes(stages, e.attackStage) then
            s.enemy.attackStage = e.attackStage
        end
        if not currentRules then
            s.enemy.telegraph = 0
            s.enemy.broken = 0
            s.enemy.shield = 0
        end
    end
    s.pendingEnemyHits = jsIsArray(v.pendingEnemyHits) and __TS__ArrayMap(
        __TS__ArraySlice(
            __TS__ArrayFilter(
                v.pendingEnemyHits,
                function(____, h) return jsAnd(
                    jsAnd(
                        jsAnd(
                            h,
                            function() return validReceipt(h.enemyId) end
                        ),
                        function() return __TS__ArrayIncludes({
                            "bone",
                            "arrow",
                            "binding",
                            "stone",
                            "thunder",
                            "pyre",
                            "pyre-combo"
                        }, h.ability) end
                    ),
                    function()
                        local ____temp_148 = h.committed == true
                        if not ____temp_148 then
                            local ____h_enemyId_147 = h.enemyId
                            local ____opt_145 = s.enemy
                            ____temp_148 = ____h_enemyId_147 == (____opt_145 and ____opt_145.id)
                        end
                        return ____temp_148
                    end
                ) end
            ),
            0,
            16
        ),
        function(____, h)
            local ____finite_result_140 = finite(h.remaining, 0.42, 0, 6)
            local ____finite_result_141 = finite(h.amount, 0, 0, 200)
            local ____h_ability_142 = h.ability
            local ____h_enemyId_143 = h.enemyId
            local ____validReceipt_result_135
            if validReceipt(h.attackId) then
                ____validReceipt_result_135 = h.attackId
            else
                ____validReceipt_result_135 = (("legacy:" .. tostring(h.enemyId)) .. ":") .. tostring(h.ability)
            end
            local ____temp_144 = currentRules and h.parryable == true
            local ____currentRules_136
            if currentRules then
                ____currentRules_136 = h.committed == true
            else
                ____currentRules_136 = true
            end
            local ____h_sourceX_139 = h.sourceX
            local ____opt_137 = s.enemy
            return {
                remaining = ____finite_result_140,
                amount = ____finite_result_141,
                ability = ____h_ability_142,
                enemyId = ____h_enemyId_143,
                attackId = ____validReceipt_result_135,
                parryable = ____temp_144,
                committed = ____currentRules_136,
                sourceX = finite(____h_sourceX_139, ____opt_137 and ____opt_137.x or s.world.hero.x, -10000000),
                targetX = finite(h.targetX, s.world.hero.x, -10000000),
                heavy = h.heavy == true
            }
        end
    ) or ({})
    local ____temp_151 = not currentRules
    if ____temp_151 then
        local ____opt_149 = s.qte
        ____temp_151 = (____opt_149 and ____opt_149.kind) == "combat"
    end
    if ____temp_151 then
        s.qte = nil
    end
    s.combat = createCombatState()
    for ____, key in ipairs({
        "strokeCharge",
        "guardCooldown",
        "guardRemaining",
        "guardPerfectRemaining",
        "surgeRemaining",
        "surgeCooldown",
        "rebuildRemaining",
        "attackSerial"
    }) do
        s.combat[key] = currentRules and finite(savedCombat[key], s.combat[key]) or s.combat[key]
    end
    s.combat.strokeCharge = math.min(
        RULES.strokesPerPunch,
        __TS__MathTrunc(s.combat.strokeCharge)
    )
    s.combat.guardCooldown = math.min(RULES.guard.cooldown, s.combat.guardCooldown)
    s.combat.guardRemaining = math.min(RULES.guard.duration, s.combat.guardRemaining)
    s.combat.guardPerfectRemaining = math.min(RULES.guard.perfect, s.combat.guardRemaining, s.combat.guardPerfectRemaining)
    s.combat.surgeRemaining = math.min(RULES.surge.duration, s.combat.surgeRemaining)
    s.combat.surgeCooldown = math.min(RULES.surge.cooldown, s.combat.surgeCooldown)
    s.combat.rebuildRemaining = math.min(RULES.rebuild.duration, s.combat.rebuildRemaining)
    s.combat.lastPunch = currentRules and finite(savedCombat.lastPunch, -10, -100, s.elapsed) or -10
    s.combat.attackSerial = __TS__MathTrunc(s.combat.attackSerial)
    s.infernoActive = currentRules and v.infernoActive == true
    s.buffs.deathguard = 0
    s.world.burns = jsIsArray(w.burns) and __TS__ArrayMap(
        __TS__ArraySlice(
            __TS__ArrayFilter(
                w.burns,
                function(____, burn) return jsAnd(
                    jsAnd(
                        burn,
                        function() return validReceipt(burn.id) end
                    ),
                    function() return __TS__ArrayIncludes({"nova", "trail"}, burn.kind) end
                ) end
            ),
            -32
        ),
        function(____, burn) return {
            id = burn.id,
            chapter = __TS__MathTrunc(finite(burn.chapter, s.chapter, 0, 4)),
            x = finite(burn.x, 0, -10000000),
            y = finite(burn.y, 0, -10000000),
            width = finite(burn.width, 220, 1, 300),
            height = finite(burn.height, 110, 1, 200),
            seed = finite(burn.seed, 1, 0, 4294967295),
            age = finite(burn.age),
            strength = finite(burn.strength, 1, 0, 1),
            kind = burn.kind
        } end
    ) or ({})
    s.inputContext = s.frenzyRemaining > 0 and "frenzy" or (s.qte and (s.qte.kind == "combat" and "combat-qte" or "story-qte") or "free")
    local beat = dataObject(v.beat)
    s.beat = {
        combo = __TS__MathTrunc(finite(beat.combo, 0, 0, 999)),
        best = __TS__MathTrunc(finite(beat.best, 0, 0, 9999)),
        last = finite(beat.last, s.elapsed, -100, s.elapsed),
        interval = finite(beat.interval, 0.5, 0.05, 2),
        releases = __TS__MathTrunc(finite(beat.releases, 0, 0, 10000)),
        arenaCamera = s.enemy and s.encounterStage == "active" and finite(beat.arenaCamera, s.world.cameraX, -10000000) or nil
    }
    local ____opt_152 = s.qte
    if (____opt_152 and ____opt_152.action) == "release" and (not s.qte.skill or not __TS__ArrayIncludes(s.equipped, s.qte.skill) or not jsTruthy(s.skills[s.qte.skill])) then
        s.qte = nil
        s.inputContext = "free"
    end
    ____exports.clearCombatCommand(s)
    refreshInferno(s)
    s.events = {}
    return s
end
return ____exports
