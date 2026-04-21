CreateClientConVar("of_garrylord_npcinfo_hud", "1", true, true, "", 0, 1)
CreateClientConVar("of_garrylord_player_interaction", "1", true, true, "", 0, 1)

local lastLookedAtNPC = nil
local lookStartTime = 0
local alpha = 0
local displayDelay = 0.1 -- 显示延迟时间
local fadeSpeed = 8 -- 淡入淡出速度
local holdStartTime = 0
local holdDuration = 1.0 -- 长按触发时长
local holdTriggered = false
local openCooldownUntil = 0

hook.Add("HUDPaint", "ofnpcp_npcinfo_hud", function()
    if GetConVar("of_garrylord_npcinfo_hud"):GetInt() ~= 1 or GetConVar("cl_drawhud"):GetInt() ~= 1 then return end
    
    local tr = util.GetPlayerTrace(LocalPlayer())
    local trace = util.TraceLine(tr)
    
    -- 检查是否在看NPC
    if trace.Hit and trace.HitNonWorld and trace.Entity:IsNPC() then
        local dist = LocalPlayer():GetPos():Distance(trace.Entity:GetPos())
        if dist <= 500 then
            if trace.Entity ~= lastLookedAtNPC then
                lastLookedAtNPC = trace.Entity
                lookStartTime = CurTime()
                alpha = 0
                holdStartTime = 0
                holdTriggered = false
            end
        else
            lastLookedAtNPC = nil
            lookStartTime = 0
            alpha = math.max(0, alpha - FrameTime() * fadeSpeed)
            holdStartTime = 0
            holdTriggered = false
        end
    else
        lastLookedAtNPC = nil
        lookStartTime = 0
        alpha = math.max(0, alpha - FrameTime() * fadeSpeed)
        holdStartTime = 0
        holdTriggered = false
    end
    -- 如果看的时间不够，不显示
    if not lastLookedAtNPC or (CurTime() - lookStartTime) < displayDelay then
        alpha = math.max(0, alpha - FrameTime() * fadeSpeed)
        return
    end
    
    -- 淡入效果
    alpha = math.min(1, alpha + FrameTime() * fadeSpeed)
    
    local npcColor, name, description = OFNPC_GetNPCHUD(lastLookedAtNPC, lastLookedAtNPC:GetClass())
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

    if GetConVar("of_garrylord_player_interaction"):GetInt() ~= 1 then return end

    local instructionY = subY + subH + padding
    local now = CurTime()
    local isHoldingUse = LocalPlayer():KeyDown(IN_USE)
    local barhight = 5 * OFGUI.ScreenScale

    if not IsValid(lastLookedAtNPC) then
        holdStartTime = 0
        holdTriggered = false
        return
    end

    -- 新增状态：进度满后等待松开
    if not holdTriggered then
        if isHoldingUse and now >= openCooldownUntil then
            if holdStartTime == 0 then
                holdStartTime = now
            end

            local progress = math.Clamp((now - holdStartTime) / holdDuration, 0, 1)
            local barW = 180 * OFGUI.ScreenScale
            local barH = barhight
            local barX = centerX - barW / 2
            local barY = instructionY

            surface.SetDrawColor(20, 20, 20, math.Round(180 * alpha))
            surface.DrawRect(barX, barY, barW, barH)
            surface.SetDrawColor(npcColor.r, npcColor.g, npcColor.b, math.Round(230 * alpha))
            local innerBarW = (barW - 2) * progress
            local midX = centerX
            local halfInnerBarW = innerBarW / 2

            if innerBarW > 0 then
                local leftX = midX - halfInnerBarW
                surface.DrawRect(leftX, barY + 1, innerBarW, barH - 2)
            end

            -- 进度满后进入等待松开发动阶段
            if progress >= 1 then
                holdTriggered = true
                holdTriggeredMenuFired = false -- 新标记，确保菜单只开一次
            end
        else
            holdStartTime = 0
            draw.SimpleText(ofTranslate("ui.hud.npcinfo_hold_use"), "ofgui_tiny", centerX, instructionY, Color(220, 220, 220, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    else
        -- 等待松开发动
        local barW = 180 * OFGUI.ScreenScale
        local barH = barhight
        local barX = centerX - barW / 2
        local barY = instructionY

        surface.SetDrawColor(20, 20, 20, math.Round(180 * alpha))
        surface.DrawRect(barX, barY, barW, barH)
        surface.SetDrawColor(npcColor.r, npcColor.g, npcColor.b, math.Round(230 * alpha))
        local innerBarW = (barW - 2)
        local midX = centerX
        local halfInnerBarW = innerBarW / 2

        local leftX = midX - halfInnerBarW
        surface.DrawRect(leftX, barY + 1, innerBarW, barH - 2)

        draw.SimpleText(ofTranslate("ui.hud.npcinfo_release_use"), "ofgui_tiny", centerX, barY + barH + padding, Color(220, 220, 220, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- 必须加一个menu已开标记，否则GMod可能会多次触发或者误触发
        if not isHoldingUse then
            if (not holdTriggeredMenuFired) and IsValid(lastLookedAtNPC) then
                net.Start("OFNPCP_NS_PreOpenNPCDialogMenu")
                    net.WriteEntity(lastLookedAtNPC)
                    net.WriteEntity(LocalPlayer())
                net.SendToServer()

                holdTriggeredMenuFired = true
            end
            openCooldownUntil = now + 0.4
            holdTriggered = false
            holdStartTime = 0
        end
    end
end)