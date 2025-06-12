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
    local attackerclass = net.ReadString()
    local victimclass = net.ReadString()
    local attackerClassify = net.ReadUInt(8)
    local victimClassify = net.ReadUInt(8)

    local attackercolor, attackername = OFNPC_GetNPCHUD(attacker, attackerclass)
    if attackercolor == Color(255, 255, 255) then
        if attackerClassify == 2 or attackerClassify == 3 or attackerClassify == 7 or attackerClassify == 8 or attackerClassify == 18 or attackerClassify == 24 then
            attackercolor = Color(255, 141, 23)
        elseif attackerClassify == 4 or attackerClassify == 5 then
            attackercolor = Color(0, 100, 0)
        elseif attackerClassify == 9 or attackerClassify == 10 or (attackerClassify >= 13 and attackerClassify <= 17) or attackerClassify == 20 or attackerClassify == 25 then
            attackercolor = Color(0, 149, 223)
        elseif attackerClassify == 12 or attackerClassify == 19 then
            attackercolor = Color(144, 238, 144)
        elseif attackerClassify == 23 then
            attackercolor = Color(135, 223, 214)
        end
    end
    
    local victimcolor, victimname = OFNPC_GetNPCHUD(victim, victimclass)
    if victimcolor == Color(255, 255, 255) then
        if victimClassify == 2 or victimClassify == 3 or victimClassify == 7 or victimClassify == 8 or victimClassify == 18 or victimClassify == 24 then
            victimcolor = Color(255, 141, 23)
        elseif victimClassify == 4 or victimClassify == 5 then
            victimcolor = Color(0, 100, 0)
        elseif victimClassify == 9 or victimClassify == 10 or (victimClassify >= 13 and victimClassify <= 17) or victimClassify == 20 or victimClassify == 25 then
            victimcolor = Color(0, 149, 223)
        elseif victimClassify == 12 or victimClassify == 19 then
            victimcolor = Color(144, 238, 144)
        elseif victimClassify == 23 then
            victimcolor = Color(135, 223, 214)
        end
    end

    -- 创建新的对话
    local killfeeds = {
        attackername = attackername,
        attackercolor = attackercolor,
        victimname = victimname,
        victimcolor = victimcolor,
        inflictorname = inflictorname,
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

        -- 绘制原文字
        local attackernameMarkup = markup.Parse(
            "<color=" .. attackercolor.r .. "," .. attackercolor.g .. "," .. attackercolor.b .. "," .. alpha .. ">" .. 
            "<font=ofgui_medium>" .. (tbl.attackername or "") .. "</font></color>"
        )
        local victimnameMarkup = markup.Parse(
            "<color=" .. victimcolor.r .. "," .. victimcolor.g .. "," .. victimcolor.b .. "," .. alpha .. ">" .. 
            "<font=ofgui_medium>" .. (tbl.victimname or "") .. "</font></color>"
        )

        -- 阴影

        local attackernameshadowMarkup = markup.Parse(
            "<color=0,0,0," .. math.floor(alpha * 0.5) .. ">" .. 
            "<font=ofgui_medium>" .. (tbl.attackername or "") .. "</font></color>"
        )
        local victimnameshadowMarkup = markup.Parse(
            "<color=0,0,0," .. math.floor(alpha * 0.5) .. ">" .. 
            "<font=ofgui_medium>" .. (tbl.victimname or "") .. "</font></color>"
        )
        
        -- 计算武器标志的尺寸
        local killiconW, killiconH = killicon.GetSize(tbl.inflictorname)
        -- 修复判断条件，只有当killiconW和killiconH都为nil时才return
        if (not killiconW or not killiconH) then return end

        -- 绘制受害者名称
        victimnameMarkup:Draw(w - 32 * OFGUI.ScreenScale, tbl.currentY, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_RIGHT)

        -- 绘制武器标志
        killicon.Render(w - 32 * OFGUI.ScreenScale - killiconW - victimnameMarkup:GetWidth() - spacing, tbl.currentY, tbl.inflictorname, alpha)

        -- 绘制攻击者名称
        attackernameMarkup:Draw(w - 32 * OFGUI.ScreenScale - killiconW - victimnameMarkup:GetWidth() - spacing, tbl.currentY, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_RIGHT)

        -- 绘制受害者名称阴影
        victimnameshadowMarkup:Draw(w - 32 * OFGUI.ScreenScale + 1 * OFGUI.ScreenScale, tbl.currentY + 1 * OFGUI.ScreenScale, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_RIGHT)

        -- 绘制攻击者名称阴影
        attackernameshadowMarkup:Draw(w - 32 * OFGUI.ScreenScale - killiconW - victimnameMarkup:GetWidth() - spacing + 1 * OFGUI.ScreenScale, tbl.currentY + 1 * OFGUI.ScreenScale, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_RIGHT)
    end
end)

  -- 覆写默认
  hook.Add("DrawDeathNotice", "killfeed_log", function(x, y)
    if GetConVar("of_garrylord_killfeeds"):GetInt() == 0 then return end
    return false;
  end);