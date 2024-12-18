net.Receive("OFNPCRankUp", function()

	local metropoliceData = file.Read("data/of_npcp/metropolice_ranks.json", "GAME")
	local combineData = file.Read("data/of_npcp/combine_ranks.json", "GAME")
	if metropoliceData then
		metropoliceRanks = util.JSONToTable(metropoliceData).ranks
	end
	if combineData then
		combineRanks = util.JSONToTable(combineData).ranks
	end

    local ent = net.ReadEntity()
    local identity = net.ReadTable()
    local rankname = ""
    local rankimage = ""

    if identity.type == "metropolice" then
        local rank = metropoliceRanks["i" .. identity.rank]
        rankimage = "ofnpcp/rankicons/rank_".. identity.rank .. ".tga"
        rankname = L(rank)
    else
        local rank = combineRanks["i" .. identity.rank]
        rankimage = "ofnpcp/rankicons/rank_".. identity.rank .. ".tga"
        rankname = L(rank)
    end

    -- 创建一个文本标签来显示晋级信息
    local levelUpText = rankname
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
        -- 计算文本宽度
        local textWidth, textHeight = surface.GetTextSize(levelUpText)  -- 获取文本的宽度和高度
        -- 绘制等级图片
        local rankImagePath = rankimage  -- 使用等级图片路径
        surface.SetMaterial(Material(rankImagePath))  -- 设置图片材质
        surface.SetDrawColor(255, 255, 255, alpha)  -- 设置图片透明度
        surface.DrawTexturedRect(screenPos.x - textHeight * 44 / 63 / 2 - textWidth / 2, screenPos.y - textHeight / 2, textHeight * 44 / 63, textHeight)  -- 绘制图片

        -- 绘制文本
        draw.SimpleText(levelUpText, "ofgui_big", screenPos.x + textHeight * 44 / 63 / 2, screenPos.y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
