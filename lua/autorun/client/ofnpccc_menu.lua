AddCSLuaFile()

local lang = {
    ["zh-CN"] = {
        title = "NPC 等级系统设置",
        enabled = "开启模组",
        enabled_help = "是否启用NPC等级系统。",
        random_level = "NPC随机等级",
        random_level_help = "设置NPC是否随机等级，若不勾选，所有 NPC 初始均为列兵。",
        text_mode = "NPC 信息显示在头顶",
        text_mode_help = "设置NPC文字显示模式，开启后NPC头顶会显示信息，关闭后只有准心对准NPC时才会显示信息。",
        levelup_effect = "晋级特效",
        levelup_effect_help = "是否启用晋级特效。",
        levelup_message = "晋级播报",
        levelup_message_help = "是否启用晋级播报。",
        kill_message = "击杀播报", 
        kill_message_help = "是否启用击杀播报。",
        friendly_fire = "友伤无惩罚",
        friendly_fire_help = "击杀同类型 NPC 击杀是否获得经验。",
        levelup_heal = "晋级增益",
        levelup_heal_help = "晋级时是否刷新血量。",
        taunt = "NPC 文字嘲讽",
        taunt_help = "是否启用NPC嘲讽。",
        idle_chat = "NPC 文字闲聊",
        idle_chat_help = "是否启用NPC闲聊。",
        levelup_chat = "NPC 晋级文字",
        levelup_chat_help = "NPC晋级时是否讲话。"
    },
    ["en"] = {
        title = "NPC Rank System Settings",
        enabled = "Enable Mod",
        enabled_help = "Enable or disable the NPC Rank System.",
        random_level = "Random NPC Rank",
        random_level_help = "Set whether NPCs have random ranks. If disabled, all NPCs start as Private.",
        text_mode = "Show NPC Info Above Head",
        text_mode_help = "Set NPC text display mode. When enabled, info shows above NPC heads. When disabled, only shows when aiming at NPCs.",
        levelup_effect = "Rank Up Effects",
        levelup_effect_help = "Enable rank up effects.",
        levelup_message = "Rank Up Messages",
        levelup_message_help = "Enable rank up messages.",
        kill_message = "Kill Messages",
        kill_message_help = "Enable kill messages.",
        friendly_fire = "No Friendly Fire Penalty",
        friendly_fire_help = "Whether killing same-type NPCs grants experience.",
        levelup_heal = "Rank Up Healing",
        levelup_heal_help = "Restore health on rank up.",
        taunt = "NPC Taunts",
        taunt_help = "Enable NPC taunts.",
        idle_chat = "NPC Idle Chat",
        idle_chat_help = "Enable NPC idle chat.",
        levelup_chat = "NPC Rank Up Chat",
        levelup_chat_help = "Enable NPC rank up messages."
    }
}

local function ofkc(pnl)
    local ln, lg = GetConVar("gmod_language"):GetString(), "en"
    if ln != nil and lang[ln] then
        lg = ln
    end

    pnl:ControlHelp(lang[lg].title)

    local Default = {
        ["ofkc_player"] = 1,
        ["ofkc_npc"] = 1,
        ["ofkc_realname"] = 0,
        ["ofkc_detail"] = 0
    }

    pnl:AddControl("ComboBox", {["MenuButton"] = 1, ["Folder"] = "ofkc", ["Options"] = {["#preset.default"] = Default}, ["CVars"] = table.GetKeys(Default)})

    pnl:CheckBox(lang[lg].enabled, "ofkc_enabled")
    pnl:Help(lang[lg].enabled_help)

    pnl:CheckBox(lang[lg].random_level, "ofkc_npc_random_level")
    pnl:Help(lang[lg].random_level_help)

    pnl:CheckBox(lang[lg].text_mode, "ofkc_npc_text_mode")
    pnl:Help(lang[lg].text_mode_help)

    pnl:CheckBox(lang[lg].levelup_effect, "ofkc_npc_levelup_effect")
    pnl:Help(lang[lg].levelup_effect_help)

    pnl:CheckBox(lang[lg].levelup_message, "ofkc_npc_levelup_message")
    pnl:Help(lang[lg].levelup_message_help)

    pnl:CheckBox(lang[lg].kill_message, "ofkc_npc_kill_message")
    pnl:Help(lang[lg].kill_message_help)

    pnl:CheckBox(lang[lg].friendly_fire, "ofkc_npc_friendly_fire")
    pnl:Help(lang[lg].friendly_fire_help)

    pnl:CheckBox(lang[lg].levelup_heal, "ofkc_npc_levelup_heal")
    pnl:Help(lang[lg].levelup_heal_help)

    pnl:CheckBox(lang[lg].taunt, "ofkc_npc_taunt")
    pnl:Help(lang[lg].taunt_help)

    pnl:CheckBox(lang[lg].idle_chat, "ofkc_npc_idle_chat")
    pnl:Help(lang[lg].idle_chat_help)

    pnl:CheckBox(lang[lg].levelup_chat, "ofkc_npc_levelup_chat")
    pnl:Help(lang[lg].levelup_chat_help)
end

hook.Add( "PopulateToolMenu", "OFKCMenus", function( )
	if ( GetConVarNumber( "of_populatetoolmenu" ) == nil or GetConVarNumber( "of_populatetoolmenu" ) == 0 ) then
		spawnmenu.AddToolMenuOption( "Options" , "Obscurefreeman's mod" , "ofkc" , " NPC Rank System" , "" , "" , ofkc )
	else
		spawnmenu.AddToolMenuOption( "OFmod" , "Tools" , "ofkc" , " NPC Rank System" , "" , "" , ofkc )
		
	end
end )