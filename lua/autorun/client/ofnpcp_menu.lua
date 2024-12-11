AddCSLuaFile()

local function ofnpcp(pnl)
    local ln, lg = GetConVar("gmod_language"):GetString(), "en"
    if ln != nil and lang[ln] then
        lg = ln
    end

    pnl:ControlHelp(lang[lg].title)

    local Default = {
        ["ofnpcp_player"] = 1,
        ["ofnpcp_npc"] = 1,
        ["ofnpcp_realname"] = 0,
        ["ofnpcp_detail"] = 0
    }

    pnl:AddControl("ComboBox", {["MenuButton"] = 1, ["Folder"] = "ofnpcp", ["Options"] = {["#preset.default"] = Default}, ["CVars"] = table.GetKeys(Default)})

    pnl:CheckBox(lang[lg].enabled, "ofnpcp_enabled")
    pnl:Help(lang[lg].enabled_help)

end

hook.Add( "PopulateToolMenu", "ofnpcpMenus", function( )
	if ( GetConVarNumber( "of_populatetoolmenu" ) == nil or GetConVarNumber( "of_populatetoolmenu" ) == 0 ) then
		spawnmenu.AddToolMenuOption( "Options" , "Obscurefreeman's mod" , "ofnpcp" , " NPC Rank System" , "" , "" , ofnpcp )
	else
		spawnmenu.AddToolMenuOption( "OFmod" , "Tools" , "ofnpcp" , " NPC Rank System" , "" , "" , ofnpcp )
		
	end
end )