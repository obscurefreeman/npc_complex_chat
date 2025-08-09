CreateClientConVar("of_garrylord_player_hud", "0", true, true, "", 0, 1)

-- 颜色与字体风格统一
local BGColor = Color(20, 20, 20, 100)
local HealthColor = Color(255, 0, 0, 225)
local AmmoColor = Color(255, 165, 0, 225)
local ArmorColor = Color(18, 149, 241, 225)
local InactiveColor = Color(112, 94, 77, 225)

-- 添加颜色过渡参数
local colorLerpSpeed = 5  -- 颜色过渡速度
local highlightDuration = 0.2  -- 高亮持续时间（秒）
local healthColor = Color(255,255,255)
local armorColor = Color(255,255,255)
local ammoColor = Color(255,255,255)

-- 修改数值变化检测为时间记录
local lastHealthChange = 0
local lastArmorChange = 0
local lastAmmoChange = 0

-- HUD绘制
local currentHealth = 0
local currentArmor = 0
local currentAmmo = 0

hook.Add("HUDPaint", "ofnpcp_simple_playerhud", function()
	if GetConVar("of_garrylord_player_hud"):GetInt() ~= 1 or GetConVar("cl_drawhud"):GetInt() ~= 1 then return end
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

	-- 数值变化时间记录
	if health ~= lastHealth then
		lastHealthChange = CurTime()
		lastHealth = health
	end
	if armor ~= lastArmor then
		lastArmorChange = CurTime()
		lastArmor = armor
	end
	if ammo ~= lastAmmo then
		lastAmmoChange = CurTime()
		lastAmmo = ammo
	end

	-- 带持续时间的颜色过渡
	local now = CurTime()
	healthColor = LerpColor(FrameTime() * colorLerpSpeed, healthColor,
		(now - lastHealthChange) < highlightDuration and HealthColor or Color(255,255,255))
	
	armorColor = LerpColor(FrameTime() * colorLerpSpeed, armorColor,
		(now - lastArmorChange) < highlightDuration and ArmorColor or Color(255,255,255))
	
	ammoColor = LerpColor(FrameTime() * colorLerpSpeed, ammoColor,
		(now - lastAmmoChange) < highlightDuration and AmmoColor or Color(255,255,255))

	-- 背景
	draw.RoundedBox(8 * OFGUI.ScreenScale, x, y, width, height, BGColor)

	-- 右侧HUD框
	local rightX = w - width - 16 * OFGUI.ScreenScale
	draw.RoundedBox(8 * OFGUI.ScreenScale, rightX, y + padding + barHeight, width, height - padding - barHeight, BGColor)

	-- 玩家头像背景
	draw.RoundedBox(6 * OFGUI.ScreenScale, x + padding, y + padding, avatarSize, avatarSize, InactiveColor)

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
	draw.RoundedBox(4 * OFGUI.ScreenScale, x + padding * 2 + avatarSize + nameWidth + padding, y + padding, armorBarW, barHeight, armorColor)
	
	-- 血量条
	local healthRatio = math.Clamp(currentHealth / maxHealth, 0, 1)
	local healthBarW = math.floor(availableWidth * healthRatio)
	draw.RoundedBox(4 * OFGUI.ScreenScale, x + padding * 2 + avatarSize, y + 2 * padding + barHeight, healthBarW, barHeight, healthColor)

	-- 子弹条
	local ammoRatio = math.Clamp(currentAmmo / maxAmmo, 0, 1)
	local weaponName = IsValid(weapon) and weapon:GetPrintName() or ""
	local weaponNameWidth = surface.GetTextSize(weaponName, "ofgui_tiny")
	local ammoBarW = math.floor((width - 3 * padding - weaponNameWidth) * ammoRatio)
	
	-- 绘制武器名称
	draw.SimpleText(weaponName, "ofgui_tiny", rightX + padding, y + 2 * padding + barHeight, Color(255, 255, 255, 255))
	
	-- 绘制子弹条
	draw.RoundedBox(4 * OFGUI.ScreenScale, rightX + padding + weaponNameWidth + padding, y + 2 * padding + barHeight, ammoBarW, barHeight, ammoColor)
end)

-- 添加颜色插值函数
function LerpColor(t, from, to)
	return Color(
		Lerp(t, from.r, to.r),
		Lerp(t, from.g, to.g),
		Lerp(t, from.b, to.b),
		Lerp(t, from.a, to.a)
	)
end

-- 隐藏原版HUD
local hidden = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true
}
hook.Add("HUDShouldDraw", "ofnpcp_hide_default_hud", function(name)
	if GetConVar("of_garrylord_player_hud"):GetInt() ~= 1 then return end
	if hidden[name] then return false end
end)