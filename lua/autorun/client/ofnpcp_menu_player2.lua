-- CreateClientConVar("of_garrylord_player2_enable", "0", true, true, "", 0, 1)

function OFNPCP_SetUpPlayer2Menu(player2Menu)
	local player2Panel = vgui.Create("OFScrollPanel", player2Menu)
	player2Panel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	player2Panel:Dock(FILL)

	-- OFNPCPCreateCheckBoxPanel(player2Panel, "of_garrylord_player2_enable", ofTranslate("ui.player2.enable"))
end