-- 创建客户端ConVar
CreateClientConVar("of_garrylord_killfeeds", "1", true, true, "", 0, 1)
CreateClientConVar("of_garrylord_killfeeds_position", "160", true, true, "", 0, 500)
CreateClientConVar("of_garrylord_killfeeds_maxlines", "3", true, true, "", 1, 10)

local activeKillfeeds = {}
local transitionTime = 0.3

-- 创建字幕
net.Receive( "OFNPCP_test_AddtoKillfeed", function()
    if GetConVar("of_garrylord_killfeeds"):GetInt() == 0 then return end

    local attacker = net.ReadEntity()
    local victim = net.ReadEntity()
    local inflictorname = net.ReadString()

    local attackercolor, attackername = OFNPC_GetNPCHUD(attacker)
    local victimcolor, victimname = OFNPC_GetNPCHUD(victim)

    -- 创建新的对话
    local killfeeds = {
        attackername = attackername,
        attackercolor = attackercolor,
        victimname = victimname,
        victimcolor = victimcolor,
        alpha = 0,
        createTime = RealTime(),
        targetY = 0,
        currentY = ScrH(),
        height = 23 * OFGUI.ScreenScale
    }
    
    local maxLines = GetConVar("of_garrylord_killfeeds_maxlines"):GetInt()
    if table.Count(activeKillfeeds) >= maxLines then
        table.remove(activeKillfeeds, 1)
    end
    
    table.insert(activeKillfeeds, killfeeds)
    
    timer.Simple(8, function()
        killfeeds.removeTime = RealTime()
    end)
end)

-- HUD绘制钩子
hook.Add("HUDPaint", "DrawNPCKillFeeds", function()
    if GetConVar("of_garrylord_killfeeds"):GetInt() == 0 then return end

    local w = ScrW()
    local h = ScrH()
    
    local position = GetConVar("of_garrylord_killfeeds_position"):GetInt()
    local topMargin = position * OFGUI.ScreenScale
    local spacing = 10 * OFGUI.ScreenScale

    local currentTargetY = topMargin
    for i = 1, #activeKillfeeds do
        local tbl = activeKillfeeds[i]
        
        if not tbl.targetY then
            tbl.targetY = currentTargetY
            tbl.currentY = tbl.targetY
        else
            tbl.targetY = currentTargetY
        end
        
        currentTargetY = tbl.targetY + tbl.height + spacing
    end

    for i = 1, #activeKillfeeds do
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
                break
            end
        end

        local attackercolor = tbl.attackercolor or Color(255, 255, 255)
        local victimcolor = tbl.victimcolor or Color(255, 255, 255)
        local alpha = math.floor(tbl.alpha)

        -- 平滑移动
        tbl.currentY = Lerp(FrameTime() * 10, tbl.currentY or tbl.targetY, tbl.targetY)

        -- 绘制投影
        local shadowMarkup = markup.Parse(
            "<color=0,0,0," .. math.floor(alpha * 0.5) .. ">" .. 
            "<font=ofgui_medium>" .. (tbl.attackername or "") .. "</font>" .. 
            "<font=ofgui_medium>" .. (tbl.victimname or "") .. "</font></color>", 
        )
        shadowMarkup:Draw(w / 2 + 1 * OFGUI.ScreenScale, tbl.currentY + 1 * OFGUI.ScreenScale, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_CENTER)

        -- 绘制原文字
        local markup = markup.Parse(
            "<color=" .. attackercolor.r .. "," .. attackercolor.g .. "," .. attackercolor.b .. "," .. alpha .. ">" .. 
            "<font=ofgui_medium>" .. (tbl.attackername or "") .. "</font></color>" .. 
            "<color=" .. victimcolor.r .. "," .. victimcolor.g .. "," .. victimcolor.b .. "," .. alpha .. ">" .. 
            "<font=ofgui_medium>" .. (tbl.victimname or "") .. "</font></color>", 
        )
        
        markup:Draw(w / 2, tbl.currentY, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_CENTER)
    end
end)