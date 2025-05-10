if CLIENT then
	-- 颜色与字体风格统一
	local BGColor = Color(20, 20, 20, 200)
	local ArmorColor = Color(18, 149, 241, 225)
	local InactiveColor = Color(112, 94, 77, 225)

	-- 字体（需在cl_init或其他地方提前CreateFont）
	local healthFont = "ofgui_medium"
	local armorFont = "ofgui_medium"
	local valueFont = "ofgui_tiny"

	-- HUD位置和大小自适应
	local function GetHUDRect()
		local w, h = ScrW(), ScrH()
		local width = math.floor(320 * OFGUI.ScreenScale)
		local height = 56 * OFGUI.ScreenScale
		local x = math.floor(w * 0.03)
		local y = math.floor(h - height - w * 0.03)
		return x, y, width, height
	end

	-- HUD绘制
	local currentHealth = 0
	local avatarSize = 40 * OFGUI.ScreenScale

	hook.Add("HUDPaint", "ofnpcp_simple_playerhud", function()
		if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end
		if GetConVar("cl_drawhud"):GetInt() == 0 then return end

		local ply = LocalPlayer()
		local health = math.max(0, ply:Health())
		local armor = math.max(0, ply:Armor())
		local maxHealth = math.max(1, ply:GetMaxHealth())

		local x, y, width, height = GetHUDRect()
		local barHeight = 16 * OFGUI.ScreenScale
		local padding = 8 * OFGUI.ScreenScale

		-- 平滑血量动画
		if not currentHealth then currentHealth = health end
		currentHealth = Lerp(FrameTime() * 10, currentHealth, health)

		-- 背景
		draw.RoundedBox(8, x, y, width, height, BGColor)

		-- 玩家头像背景
		draw.RoundedBox(6, x + padding, y + padding, avatarSize, avatarSize, InactiveColor)

		-- 玩家头像
		if not ply.AvatarImage then
			ply.AvatarImage = vgui.Create("AvatarImage")
			ply.AvatarImage:SetSize(avatarSize, avatarSize)
			ply.AvatarImage:SetPlayer(ply, 64)
			ply.AvatarImage:SetPaintedManually(true)
		end
		ply.AvatarImage:SetPos(x + padding, y + padding)
		ply.AvatarImage:SetSize(avatarSize, avatarSize)
		ply.AvatarImage:PaintManual()

		-- 血量条
		local healthBarW = math.floor((width - 3 * padding - avatarSize) * math.Clamp(currentHealth / maxHealth, 0, 1))
		draw.RoundedBox(4, x + padding + avatarSize + padding, y + padding, healthBarW, barHeight, GLOBAL_OFNPC_DATA.setting.camp_setting[OFPLAYERS[LocalPlayer():SteamID()] and OFPLAYERS[LocalPlayer():SteamID()].deck or "resistance"].color)

		-- 护甲条
		local armorBarW = math.floor((width - 3 * padding - avatarSize) * math.Clamp(armor / 100, 0, 1))
		draw.RoundedBox(4, x + padding + avatarSize + padding, y + padding + barHeight + padding, armorBarW, barHeight, ArmorColor)
	end)

	-- 隐藏原版HUD
	local hidden = {
		["CHudHealth"] = true,
		["CHudBattery"] = true,
		["CHudAmmo"] = true,
		["CHudSecondaryAmmo"] = true
	}
	hook.Add("HUDShouldDraw", "ofnpcp_hide_default_hud", function(name)
		if hidden[name] then return false end
	end)
end