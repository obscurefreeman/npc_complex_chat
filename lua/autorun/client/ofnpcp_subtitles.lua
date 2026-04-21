-- 创建客户端ConVar
CreateClientConVar("of_garrylord_subtitles", "1", true, true, "", 0, 1)
CreateClientConVar("of_garrylord_subtitles_position", "160", true, true, "", 0, 500)
CreateClientConVar("of_garrylord_subtitles_maxlines", "3", true, true, "", 1, 10)
CreateClientConVar("of_garrylord_subtitles_showname", "1", true, true, "", 0, 1)
CreateClientConVar("of_garrylord_subtitles_cc", "1", true, true, "", 0, 1)
CreateClientConVar("of_garrylord_subtitles_cc_duration", "1", true, true, "", 1, 7)

local activeSubtitles = {}
local transitionTime = 0.3


-- 共享函数：获取NPC信息
function OFNPC_GetNPCHUD(npc, class)
    -- 如果NPC不存在，返回默认值
    if not npc then
        return Color(255, 255, 255), language.GetPhrase(class), nil
    end

    -- 如果是玩家
    if npc:IsPlayer() then
        local playerColor = GLOBAL_OFNPC_DATA.setting.camp_setting[OFPLAYERS[npc:SteamID()] and OFPLAYERS[npc:SteamID()].deck or "resistance"].color
        local playerName = npc:Nick()
        return playerColor, playerName, nil
    end

    local npcs = GetAllNPCsList()
    local npcIdentity = npcs[npc:EntIndex()]

    -- 如果是NPC但没有身份信息，返回默认值
    if not npcIdentity then
        return Color(255, 255, 255), language.GetPhrase(class), nil
    end

    local npcColor = GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp].color
    local npcName
    if npcIdentity.name == npcIdentity.gamename then
        npcName = language.GetPhrase(npcIdentity.gamename)
    else
        npcName = ofTranslate(npcIdentity.name) .. " “" .. ofTranslate(npcIdentity.nickname) .. "”"
    end
    local description = ofTranslate(GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp].name) .. " " .. ofTranslate("rank.".. npcIdentity.rank) .. " - " .. ofTranslate(npcIdentity.specialization)

    return npcColor, npcName, description
end

local function OFNPC_CreateCCSubtitles(tbl)
    if GetConVar("of_garrylord_subtitles"):GetInt() == 0 or GetConVar("of_garrylord_subtitles_cc"):GetInt() == 0 or GetConVar("closecaption"):GetInt() == 0 then return end
    -- 一定要自动原生字幕和字幕同时开启，否则不显示
    local ccsubcolor = (tbl.color and tbl.color.r or 255) .. "," .. (tbl.color and tbl.color.g or 255) .. "," .. (tbl.color and tbl.color.b or 255)
    local ccsubtext = "<clr:" .. ccsubcolor .. "><B>" .. tbl.name .. "<B><clr:255,255,255>" .. tbl.text
    local ccsubduration = GetConVar("of_garrylord_subtitles_cc_duration"):GetInt()

    if GetConVar("of_garrylord_subtitles_showname"):GetInt() == 0 then
        ccsubtext = "<clr:" .. ccsubcolor .. ">" .. tbl.text
    end

    gui.AddCaption( ccsubtext, ccsubduration )
    -- print(ccsubtext)
end

-- 创建字幕
hook.Add("OnNPCTalkStart", "CreateNPCDialogSubtitles", function(npc, text)
    if GetConVar("of_garrylord_subtitles"):GetInt() == 0 then return end

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

    for _, v in pairs(activeSubtitles) do
        if v.text == dialog.text then return end
    end
    
    local maxLines = GetConVar("of_garrylord_subtitles_maxlines"):GetInt()
    if table.Count(activeSubtitles) >= maxLines then
        table.remove(activeSubtitles, 1)
    end
    
    table.insert(activeSubtitles, dialog)

    OFNPC_CreateCCSubtitles(dialog)
    
    timer.Simple(8, function()
        dialog.removeTime = RealTime()
    end)
end)

-- HUD绘制钩子
hook.Add("HUDPaint", "DrawNPCDialogSubtitles", function()
    if GetConVar("of_garrylord_subtitles"):GetInt() == 0 then return end
    if GetConVar("of_garrylord_subtitles_cc"):GetInt() == 1 and GetConVar("closecaption"):GetInt() == 1 then return end
    if GetConVar("cl_drawhud"):GetInt() ~= 1 then return end

    local w = ScrW()
    local h = ScrH()
    
    local position = GetConVar("of_garrylord_subtitles_position"):GetInt()
    local bottomMargin = position * OFGUI.ScreenScale
    local maxWidth = 1500 * OFGUI.ScreenScale
    local spacing = 10 * OFGUI.ScreenScale
    local showName = GetConVar("of_garrylord_subtitles_showname"):GetInt() ~= 0

    -- 优化字幕高度计算，确保名字显示状态切换无误并避免重复定义变量
    for i, tbl in ipairs(activeSubtitles) do
        local colorString = (tbl.color and tbl.color.r or 255) .. "," .. (tbl.color and tbl.color.g or 255) .. "," .. (tbl.color and tbl.color.b or 255) .. ",255"
        local textMarkup
        if showName then
            textMarkup = "<color=" .. colorString .. ">" ..
                         "<font=ofgui_medium>" .. (tbl.name or "") .. "</font></color>" ..
                         "<font=ofgui_medium>" .. (tbl.text or "") .. "</font>"
        else
            textMarkup = "<color=" .. colorString .. ">" ..
                         "<font=ofgui_medium>" .. (tbl.text or "") .. "</font></color>"
        end

        local markupObj = markup.Parse(textMarkup, maxWidth)
        tbl.height = markupObj:GetHeight()
    end

    -- 从下往上计算每个字幕的目标位置
    local currentTargetY = h - bottomMargin
    for i = #activeSubtitles, 1, -1 do
        local tbl = activeSubtitles[i]
        
        if not tbl.targetY then
            tbl.targetY = currentTargetY - tbl.height
            tbl.currentY = tbl.targetY
        else
            tbl.targetY = currentTargetY - tbl.height
        end
        
        currentTargetY = tbl.targetY - spacing
    end

    -- 绘制字幕并处理动画
    for i = #activeSubtitles, 1, -1 do
        local tbl = activeSubtitles[i]

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
                table.remove(activeSubtitles, i)
                break
            end
        end

		local color = tbl.color or Color(255, 255, 255)
        local alpha = math.floor(tbl.alpha)

        -- 平滑移动
        tbl.currentY = Lerp(FrameTime() * 10, tbl.currentY or h, tbl.targetY)

        -- 绘制文字相关，考虑是否显示名字
        local shadowTextMarkup, mainTextMarkup
        if showName then
            shadowTextMarkup = 
                "<color=0,0,0," .. math.floor(alpha * 0.5) .. ">" ..
                "<font=ofgui_medium>" .. (tbl.name or "") .. "</font>" ..
                "<font=ofgui_medium>" .. (tbl.text or "") .. "</font></color>"
            mainTextMarkup =
                "<color=" .. color.r .. "," .. color.g .. "," .. color.b .. "," .. alpha .. ">" ..
                "<font=ofgui_medium>" .. (tbl.name or "") .. "</font></color>" ..
                "<font=ofgui_medium>" .. (tbl.text or "") .. "</font>"
        else
            shadowTextMarkup = 
                "<color=0,0,0," .. math.floor(alpha * 0.5) .. ">" ..
                "<font=ofgui_medium>" .. (tbl.text or "") .. "</font></color>"
            mainTextMarkup =
                "<color=" .. color.r .. "," .. color.g .. "," .. color.b .. "," .. alpha .. ">" ..
                "<font=ofgui_medium>" .. (tbl.text or "") .. "</font></color>"
        end

        local shadowMarkup = markup.Parse(shadowTextMarkup, maxWidth)
        shadowMarkup:Draw(w / 2 + 1 * OFGUI.ScreenScale, tbl.currentY + 1 * OFGUI.ScreenScale, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_CENTER)

        local markupObj = markup.Parse(mainTextMarkup, maxWidth)
        markupObj:Draw(w / 2, tbl.currentY, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_CENTER)

    end
end)