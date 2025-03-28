hook.Add("HUDPaint", "ofnpcp_npcinfo_hud", function()
    local tr = util.GetPlayerTrace(LocalPlayer())
    local trace = util.TraceLine(tr)

    if not trace.Hit then return end
    if not trace.HitNonWorld then return end

    local npcColor, name, description

    if trace.Entity:IsNPC() then
        local npcs = GetAllNPCsList()
        local npcIdentity = npcs[trace.Entity:EntIndex()]

        if npcIdentity then
            npcColor = GLOBAL_OFNPC_DATA.cards.info[npcIdentity.camp].color
            local npcName
            if npcIdentity.name == npcIdentity.gamename then
                npcName = language.GetPhrase(npcIdentity.gamename)
            else
                npcName = ofTranslate(npcIdentity.name) .. " “" .. ofTranslate(npcIdentity.nickname) .. "” "
            end
            name = npcName
            description =  ofTranslate("camp."..tostring(npcIdentity.camp)) .. " " .. ofTranslate("rank.".. npcIdentity.rank) .. " - " .. ofTranslate(npcIdentity.specialization)
        end
    end

    if not name or not description then return end

    surface.SetFont("ofgui_medium")
    local w, h = surface.GetTextSize(name)

    -- 获取屏幕中心位置
    local centerX, centerY = ScrW() / 2, ScrH() / 2
    
    -- 设置文本位置
    local x = centerX - w / 2
    local y = centerY + 150 * OFGUI.ScreenScale
    local padding = 5 * OFGUI.ScreenScale

    draw.SimpleText(name, "ofgui_medium", centerX + 1 * OFGUI.ScreenScale, y + padding / 2 + 1 * OFGUI.ScreenScale, Color(0, 0, 0, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(name, "ofgui_medium", centerX, y + padding / 2, npcColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    surface.SetFont("ofgui_tiny")
    local subW, subH = surface.GetTextSize(description)
    local subY = y + h + padding
    draw.SimpleText(description, "ofgui_tiny", centerX, subY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)