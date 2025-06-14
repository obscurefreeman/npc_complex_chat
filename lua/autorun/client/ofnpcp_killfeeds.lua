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

    -- 共享函数：获取NPC击杀信息
    local function OFNPC_GetNPCKILLINFO(npc, class, classify)
        local npcName
        local npcColor
        -- 如果NPC不存在，返回默认值
        if not IsValid(npc) then
            if classify == 2 or classify == 3 or classify == 7 or classify == 8 or classify == 18 or classify == 24 then
                npcColor = Color(255, 141, 23)
            elseif classify == 4 or classify == 5 then
                npcColor = Color(0, 100, 0)
            elseif classify == 9 or classify == 10 or (classify >= 13 and classify <= 17) or classify == 20 or classify == 25 then
                npcColor = Color(0, 149, 223)
            elseif classify == 12 or classify == 19 then
                npcColor = Color(144, 238, 144)
            elseif classify == 23 then
                npcColor = Color(135, 223, 214)
            end
            return npcColor, language.GetPhrase(class), nil
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
            if classify == 2 or classify == 3 or classify == 7 or classify == 8 or classify == 18 or classify == 24 then
                npcColor = Color(255, 141, 23)
            elseif classify == 4 or classify == 5 then
                npcColor = Color(0, 100, 0)
            elseif classify == 9 or classify == 10 or (classify >= 13 and classify <= 17) or classify == 20 or classify == 25 then
                npcColor = Color(0, 149, 223)
            elseif classify == 12 or classify == 19 then
                npcColor = Color(144, 238, 144)
            elseif classify == 23 then
                npcColor = Color(135, 223, 214)
            end
            return npcColor, language.GetPhrase(class), nil
        end

        npcColor = GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp].color
        
        if npcIdentity.name == npcIdentity.gamename then
            npcName = language.GetPhrase(npcIdentity.gamename)
        else
            npcName = ofTranslate(npcIdentity.name) .. " “" .. ofTranslate(npcIdentity.nickname) .. "”"
        end
        local rank = npcIdentity.rank

        return npcColor, npcName, rank
    end

    local attackercolor, attackername, attackerrank = OFNPC_GetNPCKILLINFO(attacker, attackerclass, attackerClassify)
    local victimcolor, victimname, victimrank = OFNPC_GetNPCKILLINFO(victim, victimclass, victimClassify)

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
        height = 23 * OFGUI.ScreenScale,
        attackerrank = attackerrank,
        victimrank = victimrank
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

        local spacingX = 2 * OFGUI.ScreenScale

        -- 绘制受害者名称
        local victimnameX = w - 32 * OFGUI.ScreenScale
        victimnameshadowMarkup:Draw(victimnameX + 1 * OFGUI.ScreenScale, tbl.currentY + 1 * OFGUI.ScreenScale, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_RIGHT)
        victimnameMarkup:Draw(victimnameX, tbl.currentY, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_RIGHT)
        local victimrankimageX = victimnameX - victimnameMarkup:GetWidth()

        local victimrankimage = tbl.victimrank and "ofnpcp/usrankicons/rank_" .. tbl.victimrank .. ".png" or nil
        if victimrankimage then
            surface.SetMaterial(Material(victimrankimage))
            surface.SetDrawColor(255, 255, 255, alpha)
            victimrankimageX = victimnameX - victimnameMarkup:GetWidth() - spacingX - 23 * OFGUI.ScreenScale
            surface.DrawTexturedRect(victimrankimageX, tbl.currentY, 23 * OFGUI.ScreenScale, 23 * OFGUI.ScreenScale)
        end

        -- 绘制武器标志
        local killiconX = victimrankimageX - killiconW - spacingX
        killicon.Render(killiconX, tbl.currentY, tbl.inflictorname, alpha)

        -- 绘制攻击者名称
        local attackernameX = killiconX - spacingX
        attackernameshadowMarkup:Draw(attackernameX + 1 * OFGUI.ScreenScale, tbl.currentY + 1 * OFGUI.ScreenScale, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_RIGHT)
        attackernameMarkup:Draw(attackernameX, tbl.currentY, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_RIGHT)
        local attackerrankimageX = attackernameX - attackernameMarkup:GetWidth()

        local attackerrankimage = tbl.attackerrank and "ofnpcp/usrankicons/rank_" .. tbl.attackerrank .. ".png" or nil
        if attackerrankimage then
            surface.SetMaterial(Material(attackerrankimage))
            surface.SetDrawColor(255, 255, 255, alpha)
            attackerrankimageX = attackernameX - attackernameMarkup:GetWidth() - spacingX - 23 * OFGUI.ScreenScale
            surface.DrawTexturedRect(attackerrankimageX, tbl.currentY, 23 * OFGUI.ScreenScale, 23 * OFGUI.ScreenScale)
        end
    end
end)

  -- 覆写默认
  hook.Add("DrawDeathNotice", "killfeed_log", function(x, y)
    if GetConVar("of_garrylord_killfeeds"):GetInt() == 0 then return end
    return false;
  end);