local activeSubtitles = {}
local transitionTime = 0.3

-- 创建字幕
function CreateNPCDialogSubtitles(npc, text)
    local npcs = GetAllNPCsList()
    local npcIdentity = npcs[npc:EntIndex()]

    -- 这里不知道为什么npcIdentity报错，加个限制
    local npcColor, name
    if npcIdentity then
        npcColor = GLOBAL_OFNPC_DATA.cards.info[npcIdentity.camp].color
        local npcName
        if npcIdentity.name == npcIdentity.gamename then
            npcName = language.GetPhrase(npcIdentity.gamename) .. ": "
        else
            npcName = L(npcIdentity.name) .. " “" .. L(npcIdentity.nickname) .. "” " .. ": "
        end
        name = npcName
    elseif npc:IsPlayer() then
        npcColor = GLOBAL_OFNPC_DATA.cards.info[OFPLAYERS[LocalPlayer():SteamID()] and OFPLAYERS[LocalPlayer():SteamID()].deck or "resistance"].color
        name = npc:Nick() .. " : "
    end

    -- 创建新的对话
    local dialog = {
        name = name,
        text = text,
        color = npcColor,
        alpha = 0,
        createTime = RealTime(),
        targetY = 0,
        currentY = ScrH()
    }

    for _, v in pairs(activeSubtitles) do
        if v.text == dialog.text then return end
    end
    
    if table.Count(activeSubtitles) >= 3 then
        table.remove(activeSubtitles, 1)
    end
    
    table.insert(activeSubtitles, dialog)
    
    timer.Simple(5, function()
        if not IsValid(dialog) then return end
        dialog.removeTime = RealTime()
    end)
end

-- HUD绘制钩子
hook.Add("HUDPaint", "DrawNPCDialogSubtitles", function()
    local w = ScrW()
    local h = ScrH()
    
    local bottomMargin = 160 * OFGUI.ScreenScale
    local maxWidth = 1500 * OFGUI.ScreenScale
    local spacing = 10 * OFGUI.ScreenScale

    local currentTargetY = h - bottomMargin

    for i = #activeSubtitles, 1, -1 do
        local tbl = activeSubtitles[i]

        local currentTime = RealTime()

        if not tbl.createTime then
            tbl.createTime = currentTime
            tbl.alpha = 0
        elseif tbl.alpha < 255 then
            tbl.alpha = math.min(255, (currentTime - tbl.createTime) / transitionTime * 255)
        end

        if tbl.removeTime then
            tbl.alpha = math.max(0, 255 - (currentTime - tbl.removeTime) / transitionTime * 255)
            if tbl.alpha <= 0 then
                table.remove(activeSubtitles, i)
                continue
            end
        end

		local color = tbl.color or Color(255, 255, 255)
        local alpha = math.floor(tbl.alpha)

        local markup = markup.Parse(
            "<color=" .. color.r .. "," .. color.g .. "," .. color.b .. "," .. alpha .. ">" .. 
            "<font=ofgui_medium>" .. (tbl.name or "") .. "</font></color>" .. 
            "<font=ofgui_medium>" .. (tbl.text or "") .. "</font>", 
            maxWidth
        )
        local subtitleHeight = markup:GetHeight()
        
        tbl.targetY = currentTargetY - subtitleHeight
        tbl.currentY = Lerp(FrameTime() * 10, tbl.currentY or h, tbl.targetY)
        currentTargetY = tbl.currentY - spacing
        
        markup:Draw(w / 2, tbl.currentY, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_CENTER)
    end
end)