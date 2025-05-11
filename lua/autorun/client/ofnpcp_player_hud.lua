if CLIENT then
	-- 颜色与字体风格统一
	local BGColor = Color(20, 20, 20, 100)
    local HealthColor = Color(255, 0, 0, 225)
	local AmmoColor = Color(255, 165, 0, 225)
	local ArmorColor = Color(18, 149, 241, 225)
	local InactiveColor = Color(112, 94, 77, 225)

	-- HUD绘制
	local currentHealth = 0
	local currentArmor = 0
	local currentAmmo = 0

	hook.Add("HUDPaint", "ofnpcp_simple_playerhud", function()
		if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end
		if GetConVar("cl_drawhud"):GetInt() == 0 then return end

		local ply = LocalPlayer()
		local health = math.max(0, ply:Health())
		local armor = math.max(0, ply:Armor())
		local maxHealth = math.max(1, ply:GetMaxHealth())

		local w, h = ScrW(), ScrH()
		local width = 320 * OFGUI.ScreenScale
		local height = 80 * OFGUI.ScreenScale
		local x = 16 * OFGUI.ScreenScale
		local y = h - height - 16 * OFGUI.ScreenScale

		local barcount = 3

		local padding = 8 * OFGUI.ScreenScale
		local barHeight = (height - (barcount + 1) * padding) / barcount
		local avatarSize = height - 2 * padding

		-- 平滑动画
		if not currentHealth then currentHealth = health end
		if not currentArmor then currentArmor = armor end
		currentHealth = Lerp(FrameTime() * 10, currentHealth, health)
		currentArmor = Lerp(FrameTime() * 10, currentArmor, armor)

		-- 子弹平滑动画
		local weapon = ply:GetActiveWeapon()
		local ammo = 0
		local maxAmmo = 1
		if IsValid(weapon) then
			ammo = weapon:Clip1() or 0
			maxAmmo = weapon:GetMaxClip1() or 1
		end
		if not currentAmmo then currentAmmo = ammo end
		currentAmmo = Lerp(FrameTime() * 10, currentAmmo, ammo)

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

		-- 计算可用宽度
		local availableWidth = width - 3 * padding - avatarSize
		
		-- 血量条
		local healthRatio = math.Clamp(currentHealth / maxHealth, 0, 1)
		local healthBarW = math.floor(availableWidth * healthRatio)
		draw.RoundedBox(4, x + padding * 2 + avatarSize, y + 2 * padding + barHeight, healthBarW, barHeight, HealthColor)

		-- 玩家名称
		local name = ply:Nick()
		draw.SimpleText(name, "ofgui_tiny", x + padding * 2 + avatarSize, y + padding, Color(255, 255, 255, 255))

		-- 子弹条和护甲条位置
		local ammoArmorY = y + 3 * padding + 2 * barHeight
		local halfWidth = availableWidth / 2

		-- 子弹条
		local ammoRatio = math.Clamp(currentAmmo / maxAmmo, 0, 1)
		local ammoBarW = math.floor(halfWidth * ammoRatio)
		draw.RoundedBox(4, x + padding * 2 + avatarSize, ammoArmorY, ammoBarW, barHeight, AmmoColor)

		-- 护甲条
		local armorRatio = math.Clamp(currentArmor / 100, 0, 1)
		local armorBarW = math.floor(halfWidth * armorRatio)
		draw.RoundedBox(4, x + padding * 2 + avatarSize + ammoBarW, ammoArmorY, armorBarW, barHeight, ArmorColor)
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