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
		local height = 56 * OFGUI.ScreenScale
		local x = 16 * OFGUI.ScreenScale
		local y = h - height - 16 * OFGUI.ScreenScale

		local barcount = 2

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

		-- 右侧HUD框
		local rightX = w - width - 16 * OFGUI.ScreenScale
		draw.RoundedBox(8, rightX, y, width, height, BGColor)

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
		
		-- 玩家名称
		local name = ply:Nick()
		draw.SimpleText(name, "ofgui_tiny", x + padding * 2 + avatarSize, y + padding, Color(255, 255, 255, 255))
		local nameWidth = surface.GetTextSize(name, "ofgui_tiny")

		-- 护甲条
		local armorRatio = math.Clamp(currentArmor / 100, 0, 1)
		local armorBarW = math.floor((availableWidth - nameWidth - padding) * armorRatio)
		draw.RoundedBox(4, x + padding * 2 + avatarSize + nameWidth + padding, y + padding, armorBarW, barHeight, ArmorColor)
		
		-- 血量条
		local healthRatio = math.Clamp(currentHealth / maxHealth, 0, 1)
		local healthBarW = math.floor(availableWidth * healthRatio)
		draw.RoundedBox(4, x + padding * 2 + avatarSize, y + 2 * padding + barHeight, healthBarW, barHeight, HealthColor)

		-- 子弹条
		local ammoRatio = math.Clamp(currentAmmo / maxAmmo, 0, 1)
		local weaponName = IsValid(weapon) and weapon:GetPrintName() or ""
		local weaponNameWidth = surface.GetTextSize(weaponName, "ofgui_tiny")
		local ammoBarW = math.floor((width - 3 * padding - weaponNameWidth) * ammoRatio)
		
		-- 绘制武器名称
		draw.SimpleText(weaponName, "ofgui_tiny", rightX + padding, y + 2 * padding + barHeight, Color(255, 255, 255, 255))
		
		-- 绘制子弹条
		draw.RoundedBox(4, rightX + padding + weaponNameWidth + padding, y + 2 * padding + barHeight, ammoBarW, barHeight, AmmoColor)

		-- 绘制敌人名称
		local tr = util.GetPlayerTrace(ply)
		local trace = util.TraceLine(tr)
		local npc = trace.Entity
		local npcColor, name, description

		-- 初始化或更新当前目标NPC
		if trace.Hit and trace.HitNonWorld and npc:IsNPC() then
			ply.CurrentTargetNPC = npc
			ply.CurrentTargetNPCData = {}  -- 存储NPC数据
			
			local npcColor, name, description = OFNPC_GetNPCHUD(npc)
			if npcColor and name and description then
				ply.CurrentTargetNPCData.color = npcColor
				ply.CurrentTargetNPCData.name = name
				ply.CurrentTargetNPCData.description = description
			end
		end

		-- 如果存在当前目标NPC数据
		if ply.CurrentTargetNPCData then
			npcColor = ply.CurrentTargetNPCData.color
			name = ply.CurrentTargetNPCData.name
			description = ply.CurrentTargetNPCData.description

			if name and description then
				draw.SimpleText(name, "ofgui_tiny", rightX + padding, y + padding, Color(npcColor.r, npcColor.g, npcColor.b, 255))
				local npcNameWidth = surface.GetTextSize(name, "ofgui_tiny")

				surface.SetFont("ofgui_tiny")
				draw.SimpleText(description, "ofgui_tiny", rightX + 2 * padding + npcNameWidth, y + padding, Color(255, 255, 255, 255))
			end
		end
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