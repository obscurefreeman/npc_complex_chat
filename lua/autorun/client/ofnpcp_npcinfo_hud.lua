CreateClientConVar("of_garrylord_npcinfo_hud", "1", true, true, "", 0, 1)

local lastLookedAtNPC = nil
local lookStartTime = 0
local alpha = 0
local displayDelay = 0.1 -- 显示延迟时间
local fadeSpeed = 10 -- 淡入淡出速度

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
    
    local npcColor, name, description
    local npcs = GetAllNPCsList()
    local npcIdentity = npcs[lastLookedAtNPC:EntIndex()]
    
    if npcIdentity then
        npcColor = GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp].color
        local npcName
        if npcIdentity.name == npcIdentity.gamename then
            npcName = language.GetPhrase(npcIdentity.gamename)
        else
            npcName = ofTranslate(npcIdentity.name) .. " “" .. ofTranslate(npcIdentity.nickname) .. "”"
        end
        name = npcName
        description =  ofTranslate(GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp].name) .. " " .. ofTranslate("rank.".. npcIdentity.rank) .. " - " .. ofTranslate(npcIdentity.specialization)
    end
    
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

    local npcs = GetAllNPCsList()
    local npcIdentity = npcs[npc:EntIndex()]

    -- 定义伤害数字颜色
    local damageColor = color_white
    local outlineColor = Color(0, 0, 0, 200)
    
    if npcIdentity and GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp] then
        damageColor = GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp].color
        -- outlineColor = (damageColor.r + damageColor.g + damageColor.b) / 3 > 127.5 and Color(0, 0, 0, 200) or Color(255, 255, 255, 200)
    end
    
    hook.Add("PostDrawTranslucentRenderables", "DrawDamage_"..entIndex, function()
        local ent = Entity(entIndex)
        if not IsValid(ent) then return end
        
        local pos = ent:GetPos()
        local ang = ent:GetAngles()
        
        -- 正常方向显示
        cam.Start3D2D(pos, ang, 0.2)
            -- 绘制描边
            draw.SimpleTextOutlined(
                damage,
                "ofgui_eva",
                0, 0,
                outlineColor,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                outlineColor
            )
            -- 绘制主文本
            draw.SimpleTextOutlined(
                damage,
                "ofgui_eva",
                0, 0,
                damageColor,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                0,
                outlineColor
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
                outlineColor,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                outlineColor
            )
            -- 使用描边颜色绘制镜像文本
            draw.SimpleTextOutlined(
                damage,
                "ofgui_eva",
                0, 0,
                damageColor,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                0,
                outlineColor
            )
        cam.End3D2D()
    end)
    
    timer.Simple(3, function()
        hook.Remove("PostDrawTranslucentRenderables", "DrawDamage_"..entIndex)
    end)
end)