if CLIENT then
	-- 颜色与字体风格统一
	local BGColor = Color(20, 20, 20, 100)
    local HealthColor = Color(255, 0, 0, 225)
	local ArmorColor = Color(18, 149, 241, 225)
	local InactiveColor = Color(112, 94, 77, 225)

	-- 字体（需在cl_init或其他地方提前CreateFont）
	local healthFont = "ofgui_medium"
	local armorFont = "ofgui_medium"
	local valueFont = "ofgui_tiny"

	-- HUD绘制
	local currentHealth = 0
	local currentArmor = 0
	local currentAmmo = 0
	local avatarSize = 40 * OFGUI.ScreenScale

	local ply = LocalPlayer()

	hook.Add("HUDPaint", "ofnpcp_simple_playerhud", function()
		if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end
		if GetConVar("cl_drawhud"):GetInt() == 0 then return end

		local health = math.max(0, ply:Health())
		local armor = math.max(0, ply:Armor())
		local maxHealth = math.max(1, ply:GetMaxHealth())

		local w, h = ScrW(), ScrH()
		local width = math.floor(320 * OFGUI.ScreenScale)
		local height = 56 * OFGUI.ScreenScale
		local x = 16 * OFGUI.ScreenScale
		local y = math.floor(h - height - 16 * OFGUI.ScreenScale)
        
		local barHeight = 16 * OFGUI.ScreenScale
		local padding = 8 * OFGUI.ScreenScale

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

		-- 血量条
		local healthBarW = math.floor((width - 3 * padding - avatarSize) * math.Clamp(currentHealth / maxHealth, 0, 1))
		draw.RoundedBox(4, x + padding + avatarSize + padding, y + padding, healthBarW, barHeight, HealthColor)

		-- 子弹条
		local ammoBarW = math.floor((width - 3 * padding - avatarSize) / 2 * math.Clamp(currentAmmo / maxAmmo, 0, 1))
		draw.RoundedBox(4, x + padding + avatarSize + padding, y + padding + barHeight + padding, ammoBarW, barHeight, Color(255, 165, 0, 225))

		-- 护甲条
		local armorBarW = math.floor((width - 3 * padding - avatarSize) / 2 * math.Clamp(currentArmor / 100, 0, 1))
		draw.RoundedBox(4, x + padding + avatarSize + padding + ammoBarW, y + padding + barHeight + padding, armorBarW, barHeight, ArmorColor)
	
		-- 模型查看器显示与更新
		if not ply.ModelPanel then
			ply.ModelPanel = vgui.Create("DModelPanel")
			ply.ModelPanel:SetSize(400 * OFGUI.ScreenScale, 400 * OFGUI.ScreenScale)
			ply.ModelPanel:SetPos(w - 400 * OFGUI.ScreenScale, h - 400 * OFGUI.ScreenScale - 16 * OFGUI.ScreenScale)
			ply.ModelPanel:SetAnimated(true)
		end
	
		if IsValid(ply.ModelPanel) then
			-- 添加模型变化检测
			if not ply.CurrentModel or ply.CurrentModel != ply:GetModel() then
				ply.ModelPanel:SetModel(ply:GetModel())
				ply.CurrentModel = ply:GetModel()  -- 记录当前模型
			end
			
			local ent = ply.ModelPanel.Entity
			if IsValid(ent) then
				local head = ent:LookupBone("ValveBiped.Bip01_Head1")
				local cpos = head and ent:GetBonePosition(head) or (ply.ModelPanel:GetPos() + ply.ModelPanel:OBBCenter())
				local move = Vector(50, 0, 0)

				ply.ModelPanel:SetFOV(40)
				ply.ModelPanel:SetCamPos(cpos + move)
				ply.ModelPanel:SetLookAt(cpos)

				ply.ModelPanel:SetDirectionalLight(BOX_TOP, Color(0, 0, 0))
				ply.ModelPanel:SetAmbientLight(Color(128, 128, 128, 128))
		
				ent:ResetSequence("idle_all_01")
				ent:SetPlaybackRate(1)
				ent:FrameAdvance()
				ent:SetAngles(Angle(0, 0, 0))
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