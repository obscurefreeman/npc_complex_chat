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

    -- 计算背景框的尺寸和位置
    local padding = 10
    local cornerRadius = 8
    local bgWidth = w + padding * 2
    local bgHeight = h + padding * 2
    local bgX = x - padding
    local bgY = y - padding / 2

    -- 确定文字颜色（根据背景亮度选择黑色或白色）
    local bgBrightness = (npcColor.r * 0.299 + npcColor.g * 0.587 + npcColor.b * 0.114)
    local textColor = bgBrightness > 160 and Color(0, 0, 0, 255) or Color(255, 255, 255, 255)

    -- 绘制背景阴影（向下和向右偏移）
    draw.RoundedBox(cornerRadius, bgX + 2, bgY + 2, bgWidth, bgHeight, Color(0, 0, 0, 150))

    -- 绘制圆角背景
    draw.RoundedBox(cornerRadius, bgX, bgY, bgWidth, bgHeight, npcColor)

    -- 绘制文本（居中在背景框内）
    draw.SimpleText(name, "ofgui_medium", centerX, y + padding / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)