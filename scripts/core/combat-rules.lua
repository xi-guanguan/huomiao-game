--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
--- Initial, user-approved tuning; passing rule tests does not establish feel or difficulty.
____exports.COMBAT_RULES = {
    version = 3,
    drain = 3,
    rewardRate = 4,
    strokeHeal = 3.4,
    regenerationPerRank = 0.35,
    strokesPerPunch = 3,
    punchDamage = 4.2,
    punchInterval = 0.75,
    strokeRage = 0.2,
    damageRage = 0.3,
    commandGap = 1,
    surge = {threshold = 0.48, duration = 3, multiplier = 2, cooldown = 12},
    guard = {
        command = "huodun",
        lifeCost = 2,
        cooldown = 12,
        duration = 0.55,
        perfect = 0.22,
        reduction = 0.5,
        counterDamage = 12,
        rage = 18
    },
    rebuild = {heal = 18, duration = 4, multiplier = 1.35},
    oath = {duration = 6, multiplier = 1.35}
}
function ____exports.createCombatState()
    return {
        rulesVersion = 3,
        strokeCharge = 0,
        lastPunch = -10,
        command = "",
        commandAt = -10,
        guardCooldown = 0,
        guardRemaining = 0,
        guardPerfectRemaining = 0,
        surgeRemaining = 0,
        surgeCooldown = 0,
        rebuildRemaining = 0,
        attackSerial = 0
    }
end
function ____exports.combatState(s)
    local ____s_0, ____combat_1 = s, "combat"
    if ____s_0[____combat_1] == nil then
        ____s_0[____combat_1] = ____exports.createCombatState()
    end
    return s.combat
end
function ____exports.strokeRecovery(s)
    local combat = ____exports.combatState(s)
    local multiplier = math.max(
        1,
        combat.surgeRemaining > 0 and ____exports.COMBAT_RULES.surge.multiplier or 1,
        combat.rebuildRemaining > 0 and ____exports.COMBAT_RULES.rebuild.multiplier or 1,
        s.buffs.oath > 0 and ____exports.COMBAT_RULES.oath.multiplier + math.max(0, s.skills.oath - 1) * 0.1 or 1
    )
    return (____exports.COMBAT_RULES.strokeHeal + s.upgrades.adaptation * ____exports.COMBAT_RULES.regenerationPerRank) * multiplier
end
function ____exports.refreshInferno(s)
    local life = s.resolve / s.maxResolve
    local ____s_5 = s
    local ____temp_4
    if s.phase == "fallen" or s.resolve <= 0 then
        ____temp_4 = false
    else
        local ____s_infernoActive_3
        if s.infernoActive then
            ____s_infernoActive_3 = life >= 0.52 and s.rage >= 48
        else
            ____s_infernoActive_3 = life >= 0.6 and s.rage >= 65
        end
        ____temp_4 = ____s_infernoActive_3
    end
    ____s_5.infernoActive = ____temp_4
end
return ____exports
