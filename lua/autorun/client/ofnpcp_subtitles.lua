local activeSubtitles = {}

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
		color = npcColor
	}

	for _, v in pairs(activeSubtitles) do
		if v.text == dialog.text then return end
	end
	
	if table.Count(activeSubtitles) >= 3 then
		table.remove(activeSubtitles, 1)
	end
	
	table.insert(activeSubtitles, dialog)
	timer.Simple(5, function()
		for i, v in ipairs(activeSubtitles) do
			if v == dialog then
				table.remove(activeSubtitles, i)
				break
			end
		end
	end)
end

-- HUD绘制钩子
hook.Add("HUDPaint", "DrawNPCDialogSubtitles", function()
	local w = ScrW()
	local h = ScrH()
	
	local derp = -80 * OFGUI.ScreenScale
	local maxWidth = 1500 * OFGUI.ScreenScale
	
	-- 初始化当前绘制高度
	local currentY = h / 1.1 + derp
	
	-- 添加动效计时器
	local animTime = 0.1
	
	for k, tbl in pairs(table.Reverse(activeSubtitles)) do
		-- 初始化或更新目标位置
		if not tbl.targetY then
			tbl.targetY = currentY
		else
			tbl.targetY = Lerp(FrameTime() / animTime, tbl.targetY, currentY)
		end
		
		local subtitleName = tostring(tbl.name)
		local subtitleText = tostring(tbl.text)
		local color = tbl.color or Color(255, 255, 255)

		local markup = markup.Parse("<color=" .. color.r .. "," .. color.g .. "," .. color.b .. ",255><font=ofgui_medium>" .. subtitleName .. "</font></color><font=ofgui_medium>" .. subtitleText .. "</font>", maxWidth)
		
		-- 获取当前字幕高度
		local totalHeight = markup:GetHeight()

		local yPos = tbl.targetY - totalHeight
		
		-- 绘制实际文本
		markup:Draw(w / 2, yPos, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_CENTER )
		
		-- 更新当前绘制高度
		currentY = yPos - 10  -- 10是字幕间距
	end
end)