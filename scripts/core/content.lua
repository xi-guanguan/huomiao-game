--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
____exports.DESIGN_WIDTH = 192
____exports.HERO_SCREEN_X = 55
____exports.WALK_SPEED = 32
____exports.RUN_SPEED = 20
____exports.SKILLS = {
    {
        id = "spark",
        name = "火拳",
        command = "huoquan",
        lifeCost = 6,
        description = "燃掉一截身体，把火压进拳骨。",
        cost = 10,
        unlockAt = 0,
        cooldown = 8,
        branch = "pain",
        fx = "melee/uppercut",
        environment = "拳骨击碎焦木。",
        levels = {"消耗6生命力与10怒火，造成24伤害。", "伤害提高，伤口灼烧4秒。", "追加第二拳；仍需靠火盾完成防反。"}
    },
    {
        id = "headthrow",
        name = "掷首",
        command = "zhishou",
        lifeCost = 22,
        description = "把头掷向敌人，用连续敲键接回身躯。",
        cost = 22,
        unlockAt = 6,
        cooldown = 16,
        branch = "hatred",
        fx = "projectiles/cannonball",
        environment = "头颅先越过裂隙，身体在落点重组。",
        levels = {"消耗22生命力与22怒火，落点穿甲38伤。", "重组追加10穿甲伤害。", "残影在落点追加12穿甲伤害。"}
    },
    {
        id = "rebirth",
        name = "重铸",
        command = "chongzhu",
        lifeCost = 0,
        description = "烧掉怒火，让敲键接回更旺盛的身体。",
        cost = 24,
        unlockAt = 0,
        cooldown = 20,
        branch = "adaptation",
        fx = "holy/resurrection",
        environment = "重铸的皮肤接住灼地。",
        levels = {"消耗24怒火，恢复18生命力，4秒击键恢复×1.35。", "立即恢复增加3生命力。", "立即恢复再增加3生命力；没有免死。"}
    },
    {
        id = "lash",
        name = "炎鞭",
        command = "yanbian",
        lifeCost = 10,
        description = "付出臂骨，连续撕开眼前的敌人。",
        cost = 16,
        unlockAt = 3,
        cooldown = 13,
        branch = "pain",
        fx = "melee/whip-crack",
        environment = "骨鞭拉开围栏与绳结。",
        levels = {"消耗10生命力与16怒火，三击各10伤并剥盾。", "三段伤害各提高到11，仍会剥盾。", "增加第四击；不会自动取消敌招。"}
    },
    {
        id = "nova",
        name = "自爆",
        command = "zibao",
        lifeCost = 34,
        description = "燃尽胸口，连草木与灰土一起点着。",
        cost = 32,
        unlockAt = 10,
        cooldown = 22,
        branch = "hatred",
        fx = "fire/fire-ring",
        environment = "坍爆点燃周围草木、地面与余烬。",
        levels = {"消耗34生命力与32怒火，穿甲64伤，可燃尽自己。", "爆发增加5穿甲伤害。", "再增加5穿甲伤害；生命成本不会被免除。"}
    },
    {
        id = "oath",
        name = "不灭",
        command = "bumie",
        lifeCost = 8,
        description = "付出身体，记住让你继续生长的声音。",
        cost = 20,
        unlockAt = 7,
        cooldown = 28,
        branch = "adaptation",
        fx = "holy/halo",
        environment = "在旧祭石前记住声音，挣开影缚。",
        levels = {"消耗8生命力与20怒火，6秒击键恢复×1.35并解除束缚。", "6秒击键恢复提高至×1.45。", "6秒击键恢复提高至×1.55，仍需持续输入。"}
    }
}
____exports.BRANCHES = {{id = "pain", name = "疼痛", description = "把伤口变成下一次进攻的分量。", levels = {"技能伤害提高12%。", "技能伤害提高24%。", "技能伤害提高36%。"}}, {id = "hatred", name = "仇恨", description = "不能忘记的东西推动了拳头。", levels = {"普通拳伤害提高14%。", "普通拳伤害提高28%。", "普通拳伤害提高42%。"}}, {id = "adaptation", name = "再生", description = "身体学会更快地接回每一次敲键。", levels = {"生命力上限+12，每键恢复+0.35。", "生命力上限+24，每键恢复+0.70。", "生命力上限+36，每键恢复+1.05。"}}}
____exports.MEMORIES = {
    {text = "别睡", category = "声音", pinyin = "bie shui"},
    {text = "我还记得你的名字", category = "名字", pinyin = "wo hai ji de ni de ming zi"},
    {text = "你说天亮就回家", category = "家", pinyin = "ni shuo tian liang jiu hui jia"},
    {text = "草原还在脚下", category = "草原", pinyin = "cao yuan hai zai jiao xia"},
    {text = "这一步也算活着", category = "行走", pinyin = "zhe yi bu ye suan huo zhe"},
    {text = "把我的名字带回去", category = "名字", pinyin = "ba wo de ming zi dai hui qu"}
}
--- Finite, original themes. The decoded final text chooses one longest phrase.
____exports.SEMANTIC_THEMES = {
    {
        id = "sisters-name",
        phrase = "我还记得你的名字",
        category = "memory",
        resolve = 3,
        rage = 1,
        memory = 5
    },
    {
        id = "bring-name-home",
        phrase = "把我的名字带回去",
        category = "memory",
        resolve = 3,
        rage = 1,
        memory = 5
    },
    {
        id = "come-home",
        phrase = "天亮就回家",
        category = "memory",
        resolve = 2.5,
        rage = 0.5,
        memory = 4
    },
    {
        id = "sister",
        phrase = "妹妹",
        category = "memory",
        resolve = 2,
        rage = 0.5,
        memory = 3
    },
    {
        id = "stay-awake",
        phrase = "别睡",
        category = "memory",
        resolve = 2,
        rage = 0.5,
        memory = 3
    },
    {
        id = "painful-wound",
        phrase = "疼痛的伤口",
        category = "pain",
        resolve = 0.5,
        rage = 2,
        memory = 0
    },
    {
        id = "pain",
        phrase = "疼痛",
        category = "pain",
        resolve = 0.3,
        rage = 1.8,
        memory = 0
    },
    {
        id = "wound",
        phrase = "伤口",
        category = "pain",
        resolve = 0.3,
        rage = 1.5,
        memory = 0
    },
    {
        id = "revenge",
        phrase = "完成复仇",
        category = "hatred",
        resolve = 0,
        rage = 2.5,
        memory = 0
    },
    {
        id = "hatred",
        phrase = "仇恨",
        category = "hatred",
        resolve = 0,
        rage = 2,
        memory = 0
    },
    {
        id = "pyre",
        phrase = "执火人",
        category = "hatred",
        resolve = 0,
        rage = 2,
        memory = 0
    },
    {
        id = "still-walking",
        phrase = "还在向前",
        category = "resolve",
        resolve = 2.5,
        rage = 0.5,
        memory = 0
    },
    {
        id = "keep-walking",
        phrase = "继续向前",
        category = "resolve",
        resolve = 2.5,
        rage = 0.5,
        memory = 0
    },
    {
        id = "still-living",
        phrase = "还活着",
        category = "resolve",
        resolve = 2,
        rage = 0.5,
        memory = 0
    }
}
____exports.STORIES = {
    {title = "别睡", text = "长生天给草原人留下不朽，也留下各自的诅咒。执火人的火烧过帐群，你从焦骨里醒来。妹妹的最后一句话还在耳边：别睡。"},
    {title = "第一步", text = "手掌撑住灰土，膝盖接住重量。火仍贴在身上，身体却记住了前行。火一弱，指尖就不由自主地攥紧。"},
    {title = "旧围栏", text = "这里曾拴着家里的马。焦黑的绳子缠住臂骨，你把它拉开，身后留下能容一个人走过的缺口。"},
    {title = "身躯皆是路", text = "头颅越过裂隙时，肩背在另一边长出。你开始知道，不必等身体完整才继续走。祭石旁还有她刻下的小名。"},
    {title = "旗影前", text = "当夜的旗就在前方。仇恨撑住了这些路，但你记得的并不只有那场火。"},
    {title = "仍有一簇", text = "执火人倒下，旗也塌在灰里。你拾起妹妹系过的骨珠，把她的名字带回掌心。火没有停，但你终于能坐下来。"}
}
____exports.ENEMIES = {
    {
        id = "bone",
        name = "猎骨者",
        kind = "melee",
        ability = "bone",
        hp = 150,
        damage = 12,
        interval = 1.05,
        telegraph = 0.84,
        armor = 0.08,
        fx = "melee/claw-swipe",
        attackRange = 32,
        heavyDamage = 34,
        heavyEvery = 7,
        heavyWindup = 0.84
    },
    {
        id = "archer",
        name = "逐火弓奴",
        kind = "ranged",
        ability = "arrow",
        hp = 145,
        damage = 11,
        interval = 1.1,
        telegraph = 0.88,
        armor = 0,
        fx = "projectiles/arrow",
        attackRange = 58,
        heavyDamage = 30,
        heavyEvery = 7,
        heavyWindup = 0.88
    },
    {
        id = "binder",
        name = "缚骨徒",
        kind = "binder",
        ability = "binding",
        hp = 180,
        damage = 11,
        interval = 1.15,
        telegraph = 0.9,
        armor = 0.12,
        fx = "shadow/grasping-hands",
        attackRange = 46,
        heavyDamage = 24,
        heavyEvery = 6,
        heavyWindup = 0.9
    },
    {
        id = "stone",
        name = "石壳放逐者",
        kind = "elite",
        ability = "stone",
        hp = 280,
        damage = 16,
        interval = 1.4,
        telegraph = 1.1,
        armor = 0.3,
        fx = "nature/earth-spike",
        attackRange = 37,
        heavyDamage = 40,
        heavyEvery = 6,
        heavyWindup = 1.1
    },
    {
        id = "thunder",
        name = "雷脉牧者",
        kind = "elite",
        ability = "thunder",
        hp = 245,
        damage = 13,
        interval = 1.15,
        telegraph = 0.95,
        armor = 0.15,
        fx = "lightning/chain-lightning",
        attackRange = 52,
        heavyDamage = 38,
        heavyEvery = 6,
        heavyWindup = 0.95
    },
    {
        id = "pyre",
        name = "执火人",
        kind = "boss",
        ability = "pyre",
        hp = 520,
        damage = 14,
        interval = 1.05,
        telegraph = 0.9,
        armor = 0.2,
        fx = "fire/flame-pillar",
        attackRange = 44,
        heavyDamage = 32,
        heavyEvery = 7,
        heavyWindup = 0.9
    }
}
--- Fixed world layout: encounter index is GLOBAL (0..14), not chapter-local.
---@type table<number,table<string,any>>
____exports.ENCOUNTERS = {
    {
        id = "e01",
        enemyId = "bone",
        chapter = 1,
        style = "hold",
        spawnAt = 210,
        enemyX = 390,
        chaseEndX = 542,
        reward = 1,
        label = "焦木后的猎骨者"
    },
    {
        id = "e02",
        enemyId = "archer",
        chapter = 1,
        style = "chase",
        spawnAt = 472,
        enemyX = 652,
        chaseEndX = 1272,
        reward = 1,
        label = "草丛里的退射者"
    },
    {
        id = "e03",
        enemyId = "bone",
        chapter = 1,
        style = "hold",
        spawnAt = 1300,
        enemyX = 1480,
        chaseEndX = 1620,
        reward = 1,
        label = "断栏前的骨刃"
    },
    {
        id = "e04",
        enemyId = "binder",
        chapter = 1,
        style = "hold",
        spawnAt = 1700,
        enemyX = 1880,
        chaseEndX = 1930,
        reward = 1,
        label = "围栏上的影子"
    },
    {
        id = "e05",
        enemyId = "archer",
        chapter = 2,
        style = "chase",
        spawnAt = 2080,
        enemyX = 2260,
        chaseEndX = 2698,
        reward = 1,
        label = "陷足灰地"
    },
    {
        id = "e06",
        enemyId = "stone",
        chapter = 2,
        style = "hold",
        spawnAt = 2698,
        enemyX = 2878,
        chaseEndX = 3038,
        reward = 1,
        label = "会呼吸的石壳"
    },
    {
        id = "e07",
        enemyId = "binder",
        chapter = 2,
        style = "hold",
        spawnAt = 3148,
        enemyX = 3328,
        chaseEndX = 3418,
        reward = 1,
        label = "裂隙另一边"
    },
    {
        id = "e08",
        enemyId = "thunder",
        chapter = 2,
        style = "chase",
        spawnAt = 3558,
        enemyX = 3738,
        chaseEndX = 4248,
        reward = 1,
        label = "雷在追赶脚步"
    },
    {
        id = "e09",
        enemyId = "bone",
        chapter = 2,
        style = "chase",
        spawnAt = 4398,
        enemyX = 4578,
        chaseEndX = 4918,
        reward = 1,
        label = "余火里的骨刃"
    },
    {
        id = "e10",
        enemyId = "binder",
        chapter = 3,
        style = "hold",
        spawnAt = 5118,
        enemyX = 5298,
        chaseEndX = 5368,
        reward = 1,
        label = "旗影缠身"
    },
    {
        id = "e11",
        enemyId = "thunder",
        chapter = 3,
        style = "chase",
        spawnAt = 5518,
        enemyX = 5698,
        chaseEndX = 6208,
        reward = 1,
        label = "裂地雷脉"
    },
    {
        id = "e12",
        enemyId = "archer",
        chapter = 3,
        style = "chase",
        spawnAt = 6368,
        enemyX = 6548,
        chaseEndX = 7008,
        reward = 1,
        label = "燃烧的远处"
    },
    {
        id = "e13",
        enemyId = "stone",
        chapter = 3,
        style = "hold",
        spawnAt = 7178,
        enemyX = 7358,
        chaseEndX = 7448,
        reward = 1,
        label = "最后的石墙"
    },
    {
        id = "e14",
        enemyId = "bone",
        chapter = 3,
        style = "chase",
        spawnAt = 7448,
        enemyX = 7628,
        chaseEndX = 7988,
        reward = 1,
        label = "追上那面旗"
    },
    {
        id = "e15",
        enemyId = "pyre",
        chapter = 4,
        style = "hold",
        spawnAt = 8348,
        enemyX = 8528,
        chaseEndX = 9948,
        reward = 2,
        label = "执火人"
    }
}
____exports.ENVIRONMENTS = {
    {
        id = "charred-log",
        kind = "deadwood",
        x = 128,
        width = 25,
        chapter = 1,
        skill = "spark",
        label = "焦木挡住了路。让拳骨里的火出去。",
        target = "火",
        pinyin = "huo",
        blocking = true
    },
    {
        id = "old-fence",
        kind = "fence",
        x = 1575,
        width = 35,
        chapter = 1,
        skill = "lash",
        label = "臂骨缠上围栏。把它拉开。",
        target = "拉开",
        pinyin = "la kai",
        blocking = true
    },
    {
        id = "ash-lowland",
        kind = "ash",
        x = 2410,
        width = 115,
        chapter = 2,
        label = "灰地没过脚踝。每一步都留下印子。",
        target = "脚下",
        pinyin = "jiao xia",
        blocking = false
    },
    {
        id = "first-fissure",
        kind = "fissure",
        x = 2980,
        width = 47,
        chapter = 2,
        skill = "headthrow",
        label = "裂隙截断了路。头颅先走，身体随后。",
        target = "过去",
        pinyin = "guo qu",
        blocking = true
    },
    {
        id = "old-shrine",
        kind = "shrine",
        x = 3418,
        width = 26,
        chapter = 2,
        skill = "oath",
        label = "祭石上还有她刻下的小名。",
        target = "别睡",
        pinyin = "bie shui",
        blocking = true
    },
    {
        id = "ember-strip",
        kind = "embers",
        x = 4788,
        width = 95,
        chapter = 2,
        skill = "rebirth",
        label = "脚底在燃烧。重铸的皮肤接住下一步。",
        target = "还在",
        pinyin = "hai zai",
        blocking = false
    },
    {
        id = "pyre-debris",
        kind = "deadwood",
        x = 5368,
        width = 38,
        chapter = 3,
        skill = "nova",
        label = "焦木压住了余火。把胸口的热释放出去。",
        target = "出去",
        pinyin = "chu qu",
        blocking = true
    },
    {
        id = "thunder-ash",
        kind = "ash",
        x = 5928,
        width = 105,
        chapter = 3,
        label = "裂地抓住脚踝，雷光沿着脚印追来。",
        target = "向前",
        pinyin = "xiang qian",
        blocking = false
    },
    {
        id = "last-fence",
        kind = "fence",
        x = 7068,
        width = 36,
        chapter = 3,
        skill = "lash",
        label = "骨鞭拉开最后一道围栏。",
        target = "让开",
        pinyin = "rang kai",
        blocking = true
    },
    {
        id = "last-fissure",
        kind = "fissure",
        x = 8088,
        width = 52,
        chapter = 3,
        skill = "headthrow",
        label = "身体已经记得怎样越过裂隙。",
        target = "继续",
        pinyin = "ji xu",
        blocking = true
    },
    {
        id = "fallen-banner",
        kind = "banner",
        x = 8258,
        width = 18,
        chapter = 4,
        label = "当夜的旗就在前方。",
        target = "我记得",
        pinyin = "wo ji de",
        blocking = true
    },
    {
        id = "boss-embers",
        kind = "embers",
        x = 9138,
        width = 110,
        chapter = 4,
        label = "火线漫过脚底。",
        target = "还活着",
        pinyin = "hai huo zhe",
        blocking = false
    },
    {
        id = "sisters-bead",
        kind = "bonebead",
        x = 10008,
        width = 8,
        chapter = 4,
        label = "她系过的骨珠留在灰里。",
        target = "我还记得你的名字",
        pinyin = "wo hai ji de ni de ming zi",
        blocking = true
    }
}
____exports.CHAPTERS = {
    {
        name = "焦土",
        terrain = "焦灰",
        startX = 0,
        endX = 75,
        encounters = {},
        storyIndex = 0
    },
    {
        name = "灰径",
        terrain = "烧焦的草原",
        startX = 75,
        endX = 1930,
        encounters = {"e01", "e02", "e03", "e04"},
        storyIndex = 1
    },
    {
        name = "旧围栏",
        terrain = "陷足灰地",
        startX = 1930,
        endX = 5028,
        encounters = {
            "e05",
            "e06",
            "e07",
            "e08",
            "e09"
        },
        storyIndex = 2
    },
    {
        name = "旗影前",
        terrain = "烫裂的地面",
        startX = 5028,
        endX = 8208,
        encounters = {
            "e10",
            "e11",
            "e12",
            "e13",
            "e14"
        },
        storyIndex = 3
    },
    {
        name = "执火旗",
        terrain = "焦黑的营地",
        startX = 8208,
        endX = 10048,
        encounters = {"e15"},
        storyIndex = 4
    }
}
return ____exports
