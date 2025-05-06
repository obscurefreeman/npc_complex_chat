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