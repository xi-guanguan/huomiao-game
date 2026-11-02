local ____lualib = require("core.lualib_bundle")
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ArrayIncludes = ____lualib.__TS__ArrayIncludes
local ____exports = {}
____exports.GROWTH_ROUTE = {
    {id = "wake", name = "续燃", detail = "敲键续身，三键出拳。"},
    {id = "guard", name = "反击", detail = "重击将至时，空格架盾。"},
    {id = "spark", name = "用火", detail = "连续输入 huoquan，燃身反击。"},
    {id = "grow", name = "生长", detail = "战胜敌人后，用生长点强化。"},
    {id = "journey", name = "领悟", detail = "前行跨越障碍，身体会记住新的本领。"}
}
function ____exports.visibleSkills(s)
    local experienced = s.kills > 0 or s.chapter > 0 or s.totalSkillPointsEarned > 0
    return __TS__ArrayFilter(
        s.equipped,
        function(____, id) return experienced or id == "spark" and s.metrics.strokes >= 12 or id == "rebirth" and s.resolve <= s.maxResolve * 0.48 and s.phase == "combat" end
    )
end
function ____exports.journeyGuide(s)
    if __TS__ArrayIncludes({"title", "rest", "ending", "fallen"}, s.phase) then
        return nil
    end
    if s.qte then
        return {id = "pinyin", text = "照着拼音敲下去，故事会继续。", target = "keys"}
    end
    if s.skillPoints > 0 and s.totalSkillPointsEarned == s.skillPoints then
        return {id = "grow", text = s.kills > 0 and "身体记住了这场胜利。打开生长，先让续身更有力。" or "你已重新站起来。打开生长，先让续身更有力。", target = "growth"}
    end
    local ____temp_2 = s.phase == "combat"
    if ____temp_2 then
        local ____opt_0 = s.enemy
        ____temp_2 = (____opt_0 and ____opt_0.heavyIntentRemaining or 0) > 0
    end
    local ____temp_2_5 = ____temp_2
    if ____temp_2_5 then
        local ____opt_3 = s.combat
        ____temp_2_5 = (____opt_3 and ____opt_3.guardCooldown) == 0
    end
    if ____temp_2_5 then
        return {id = "guard", text = "重击将至。空格架盾，刚好接住就能防反。", target = "guard"}
    end
    local ____temp_8 = s.phase == "combat" and s.resolve <= s.maxResolve * 0.48
    if ____temp_8 then
        local ____opt_6 = s.combat
        ____temp_8 = (____opt_6 and ____opt_6.surgeRemaining or 0) > 0
    end
    if ____temp_8 then
        return {id = "surge", text = "身体正在续生。继续敲键，把炭躯长回来。", target = "keys"}
    end
    if s.phase == "combat" and s.rage >= 10 and s.cooldowns.spark == 0 and __TS__ArrayIncludes(s.equipped, "spark") then
        return {id = "spark", text = "连续敲 huoquan 就能出火拳，命令容错一次。", target = "skills"}
    end
    if s.kills == 0 then
        return {id = "wake", text = s.phase == "combat" and "继续敲键续身，每三键打出一拳。" or "敲键，身体会重新长回来。", target = "keys"}
    end
    return nil
end
return ____exports
