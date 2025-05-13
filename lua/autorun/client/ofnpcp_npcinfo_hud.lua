CreateClientConVar("of_garrylord_npcinfo_hud", "1", true, true, "", 0, 1)

local lastLookedAtNPC = nil
local lookStartTime = 0
local alpha = 0
local displayDelay = 0.1 -- 显示延迟时间
local fadeSpeed = 10 -- 淡入淡出速度

local damageNumbers = {}  -- 用于存储当前显示的伤害数字

hook.Add("HUDPaint", "ofnpcp_npcinfo_hud", function()
    if GetConVar("of_garrylord_npcinfo_hud"):GetInt() == 0 then return end
    
    local tr = util.GetPlayerTrace(LocalPlayer())
    local trace = util.TraceLine(tr)
    
    -- 检查是否在看NPC
    if trace.Hit and trace.HitNonWorld and trace.Entity:IsNPC() then
        if trace.Entity ~= lastLookedAtNPC then
            lastLookedAtNPC = trace.Entity
            lookStartTime = CurTime()
            alpha = 0
        end
    else
        lastLookedAtNPC = nil
        lookStartTime = 0
        alpha = math.max(0, alpha - FrameTime() * fadeSpeed)
    end
    
    -- 如果看的时间不够，不显示
    if not lastLookedAtNPC or (CurTime() - lookStartTime) < displayDelay then
        alpha = math.max(0, alpha - FrameTime() * fadeSpeed)
        return
    end
    
    -- 淡入效果
    alpha = math.min(1, alpha + FrameTime() * fadeSpeed)
    
    local npcColor, name, description = OFNPC_GetNPCHUD(lastLookedAtNPC)
    if not name or not description then return end
    
    surface.SetFont("ofgui_medium")
    local w, h = surface.GetTextSize(name)
    
    -- 获取屏幕中心位置
    local centerX, centerY = ScrW() / 2, ScrH() / 2
    
    -- 设置文本位置
    local y = centerY + 150 * OFGUI.ScreenScale
    local padding = 5 * OFGUI.ScreenScale
    
    -- 应用透明度
    local textAlpha = math.Round(255 * alpha)
    local shadowAlpha = math.Round(100 * alpha)
    
    draw.SimpleText(name, "ofgui_medium", centerX + 1 * OFGUI.ScreenScale, y + padding / 2 + 1 * OFGUI.ScreenScale, Color(0, 0, 0, shadowAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(name, "ofgui_medium", centerX, y + padding / 2, Color(npcColor.r, npcColor.g, npcColor.b, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    surface.SetFont("ofgui_tiny")
    local subW, subH = surface.GetTextSize(description)
    local subY = y + h + padding
    draw.SimpleText(description, "ofgui_tiny", centerX, subY, Color(255, 255, 255, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)

net.Receive("OFDamageNumber", function()
    local entIndex = net.ReadUInt(16)
    local damage = net.ReadString()
    local npc = net.ReadEntity()

    -- 定义伤害数字颜色
    local damageColor = color_white
    local outlineColor = Color(0, 0, 0, 200)

    if npc:IsNPC() then
        local npcs = GetAllNPCsList()
        local npcIdentity = npcs[npc:EntIndex()]
        if npcIdentity and GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp] then
            damageColor = GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp].color
        end
    elseif npc:IsPlayer() then
        damageColor = GLOBAL_OFNPC_DATA.setting.camp_setting[OFPLAYERS[LocalPlayer():SteamID()] and OFPLAYERS[LocalPlayer():SteamID()].deck or "resistance"].color
    end
    
    local startTime = CurTime()
    local fadeStartTime = startTime + 2 -- 2秒后开始变透明
    local fadeEndTime = startTime + 3 -- 3秒后完全消失
    
    -- 将新创建的伤害数字添加到列表中
    local damageInfo = {
        entIndex = entIndex,
        damage = damage,
        npc = npc,
        startTime = startTime,
        fadeStartTime = fadeStartTime,
        fadeEndTime = fadeEndTime,
        damageColor = damageColor,
        outlineColor = outlineColor
    }
    table.insert(damageNumbers, damageInfo)

    if #damageNumbers > 25 then
        local oldestDamageInfo = table.remove(damageNumbers, 1)
        oldestDamageInfo.fadeStartTime = CurTime()  -- 立即开始渐变
        oldestDamageInfo.fadeEndTime = CurTime() + 1  -- 1秒内完全消失
    end

    hook.Add("PostDrawTranslucentRenderables", "DrawDamage_"..entIndex, function()
        local ent = Entity(entIndex)
        if not IsValid(ent) then return end
        
        local pos = ent:GetPos()
        local ang = ent:GetAngles()
        
        -- 计算透明度
        local currentTime = CurTime()
        local alpha = 255
        if currentTime > damageInfo.fadeStartTime then
            alpha = 255 - (currentTime - damageInfo.fadeStartTime) * 255
        end
        alpha = math.Clamp(alpha, 0, 255)
        
        -- 正常方向显示
        cam.Start3D2D(pos, ang, 0.2)
            -- 绘制描边
            draw.SimpleTextOutlined(
                damage,
                "ofgui_eva",
                0, 0,
                Color(outlineColor.r, outlineColor.g, outlineColor.b, alpha),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(outlineColor.r, outlineColor.g, outlineColor.b, alpha)
            )
            -- 绘制主文本
            draw.SimpleTextOutlined(
                damage,
                "ofgui_eva",
                0, 0,
                Color(damageColor.r, damageColor.g, damageColor.b, alpha),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                0,
                Color(outlineColor.r, outlineColor.g, outlineColor.b, alpha)
            )
        cam.End3D2D()

        -- 镜像方向显示
        local reversedAng = Angle(ang.p, ang.y, ang.r + 180)
        cam.Start3D2D(pos, reversedAng, -0.2)  -- 使用负比例进行镜像
            -- 绘制描边
            draw.SimpleTextOutlined(
                damage,
                "ofgui_eva",
                0, 0,
                Color(outlineColor.r, outlineColor.g, outlineColor.b, alpha),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(outlineColor.r, outlineColor.g, outlineColor.b, alpha)
            )
            -- 使用描边颜色绘制镜像文本
            draw.SimpleTextOutlined(
                damage,
                "ofgui_eva",
                0, 0,
                Color(damageColor.r, damageColor.g, damageColor.b, alpha),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                0,
                Color(outlineColor.r, outlineColor.g, outlineColor.b, alpha)
            )
        cam.End3D2D()
    end)
    
    timer.Simple(3, function()
        hook.Remove("PostDrawTranslucentRenderables", "DrawDamage_"..entIndex)
        -- 从列表中移除已删除的伤害数字
        for i, v in ipairs(damageNumbers) do
            if v.entIndex == entIndex then
                table.remove(damageNumbers, i)
                break
            end
        end
    end)
end)