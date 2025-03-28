hook.Add("HUDPaint", "ofnpcp_npcinfo_hud", function()
    local tr = util.GetPlayerTrace(LocalPlayer())
    local trace = util.TraceLine(tr)

    if not trace.Hit then return end
    if not trace.HitNonWorld then return end

    local npcColor, name

    if trace.Entity:IsNPC() then
        local npcs = GetAllNPCsList()
        local npcIdentity = npcs[trace.Entity:EntIndex()]

        if npcIdentity then
            npcColor = GLOBAL_OFNPC_DATA.cards.info[npcIdentity.camp].color
            local npcName
            if npcIdentity.name == npcIdentity.gamename then
                npcName = language.GetPhrase(npcIdentity.gamename)
            else
                npcName = L(npcIdentity.name) .. " “" .. L(npcIdentity.nickname) .. "” "
            end
            name = npcName
        end
    end

    if not name then return end

    surface.SetFont("ofgui_medium")
    local w, h = surface.GetTextSize(name)

    -- 获取屏幕中心位置
    local centerX, centerY = ScrW() / 2, ScrH() / 2
    
    -- 设置文本位置
    local x = centerX - w / 2
    local y = centerY + ScrH() * 0.15  -- 从中心向下偏移15%屏幕高度

    -- 绘制文本阴影
    draw.SimpleText(name, "ofgui_medium", x + 1, y + 1, Color(0, 0, 0, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- 绘制主文本
    draw.SimpleText(name, "ofgui_medium", x, y, npcColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    surface.SetDrawColor(npcColor)
    surface.DrawLine(x, y + h + 2, x + w, y + h + 2)
end)