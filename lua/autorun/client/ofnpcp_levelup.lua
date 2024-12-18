net.Receive("OFNPCRankUp", function()
    local ent = net.ReadEntity()
    local identity = net.ReadTable()

    -- 创建一个文本标签来显示晋级信息
    local levelUpText = "晋级到 " .. identity.rank .. " 级！"
    local textDuration = 2  -- 持续时间为2秒
    local startTime = CurTime()  -- 记录开始时间

    -- 在NPC上方显示文本
    local function DrawLevelUpText()
        local elapsed = CurTime() - startTime  -- 计算经过的时间
        local pos = ent:GetPos() + Vector(0, 0, ent:OBBCenter().z + (elapsed * 10))
        
        -- 计算透明度，随着时间的推移逐渐变浅，先慢后快
        local alpha = math.max(255 * (1 - (elapsed / textDuration)), 0)  -- 计算透明度，最大255，最小0
        -- 调整透明度变化速度，使其先慢后快
        alpha = 255 * (1 - (elapsed / textDuration) ^ 2)
        
        local screenPos = pos:ToScreen()  -- 将世界坐标转换为屏幕坐标
        draw.SimpleText(levelUpText, "ofgui_big", screenPos.x, screenPos.y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- 在HUD中绘制文本
    hook.Add("HUDPaint", "DrawLevelUpText", function()
        DrawLevelUpText()
        -- 在持续时间后移除钩子
        if CurTime() - startTime >= textDuration then
            hook.Remove("HUDPaint", "DrawLevelUpText")
        end
    end)
end)
