-- 创建客户端ConVar
CreateClientConVar("of_garrylord_killfeeds", "1", true, true, "", 0, 1)
CreateClientConVar("of_garrylord_killfeeds_position", "160", true, true, "", 0, 500)
CreateClientConVar("of_garrylord_killfeeds_maxlines", "3", true, true, "", 1, 10)

local activeKillfeeds = {}
local transitionTime = 0.3

-- 创建字幕
hook.Add("OnNPCTalkStart", "CreateNPCKillFeeds", function(npc, text)
    if GetConVar("of_garrylord_killfeeds"):GetInt() == 0 then return end

    local npcColor, name = OFNPC_GetNPCHUD(npc)
    if not name then return end

    -- 创建新的对话
    local dialog = {
        name = name .. ": ",
        text = text,
        color = npcColor,
        alpha = 0,
        createTime = RealTime(),
        targetY = 0,
        currentY = ScrH(),
        height = 0
    }

    for _, v in pairs(activeKillfeeds) do
        if v.text == dialog.text then return end
    end
    
    local maxLines = GetConVar("of_garrylord_killfeeds_maxlines"):GetInt()
    if table.Count(activeKillfeeds) >= maxLines then
        table.remove(activeKillfeeds, 1)
    end
    
    table.insert(activeKillfeeds, dialog)
    
    timer.Simple(8, function()
        dialog.removeTime = RealTime()
    end)
end)

-- HUD绘制钩子
hook.Add("HUDPaint", "DrawNPCKillFeeds", function()
    if GetConVar("of_garrylord_killfeeds"):GetInt() == 0 then return end

    local w = ScrW()
    local h = ScrH()
    
    local position = GetConVar("of_garrylord_killfeeds_position"):GetInt()
    local bottomMargin = position * OFGUI.ScreenScale
    local maxWidth = 1500 * OFGUI.ScreenScale
    local spacing = 10 * OFGUI.ScreenScale

    -- 先计算所有字幕的高度
    for i, tbl in ipairs(activeKillfeeds) do
        local markup = markup.Parse(
            "<color=" .. (tbl.color and tbl.color.r or 255) .. "," .. (tbl.color and tbl.color.g or 255) .. "," .. (tbl.color and tbl.color.b or 255) .. ",255>" .. 
            "<font=ofgui_medium>" .. (tbl.name or "") .. "</font></color>" .. 
            "<font=ofgui_medium>" .. (tbl.text or "") .. "</font>", 
            maxWidth
        )
        tbl.height = markup:GetHeight()
    end

    -- 从下往上计算每个字幕的目标位置
    local currentTargetY = h - bottomMargin
    for i = #activeKillfeeds, 1, -1 do
        local tbl = activeKillfeeds[i]
        
        if not tbl.targetY then
            tbl.targetY = currentTargetY - tbl.height
            tbl.currentY = tbl.targetY
        else
            tbl.targetY = currentTargetY - tbl.height
        end
        
        currentTargetY = tbl.targetY - spacing
    end

    -- 绘制字幕并处理动画
    for i = #activeKillfeeds, 1, -1 do
        local tbl = activeKillfeeds[i]

        local currentTime = RealTime()

        if not tbl.createTime then
            tbl.createTime = currentTime
            tbl.alpha = 0
        end

        -- 计算透明度（入场渐变）
        if not tbl.removeTime then
            tbl.alpha = math.min(255, (currentTime - tbl.createTime) / transitionTime * 255)
        else
            tbl.alpha = math.max(0, 255 - (currentTime - tbl.removeTime) / transitionTime * 255)
            if tbl.alpha <= 0 then
                table.remove(activeKillfeeds, i)
                continue
            end
        end

		local color = tbl.color or Color(255, 255, 255)
        local alpha = math.floor(tbl.alpha)

        -- 平滑移动
        tbl.currentY = Lerp(FrameTime() * 10, tbl.currentY or h, tbl.targetY)

        -- 绘制投影
        local shadowMarkup = markup.Parse(
            "<color=0,0,0," .. math.floor(alpha * 0.5) .. ">" .. 
            "<font=ofgui_medium>" .. (tbl.name or "") .. "</font>" .. 
            "<font=ofgui_medium>" .. (tbl.text or "") .. "</font></color>", 
            maxWidth
        )
        shadowMarkup:Draw(w / 2 + 1 * OFGUI.ScreenScale, tbl.currentY + 1 * OFGUI.ScreenScale, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_CENTER)

        -- 绘制原文字
        local markup = markup.Parse(
            "<color=" .. color.r .. "," .. color.g .. "," .. color.b .. "," .. alpha .. ">" .. 
            "<font=ofgui_medium>" .. (tbl.name or "") .. "</font></color>" .. 
            "<font=ofgui_medium>" .. (tbl.text or "") .. "</font>", 
            maxWidth
        )
        
        markup:Draw(w / 2, tbl.currentY, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_CENTER)
    end
end)