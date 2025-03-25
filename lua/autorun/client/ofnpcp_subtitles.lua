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
	
	for k, tbl in ipairs(activeSubtitles) do
		local subtitleName = tostring(tbl.name)
		local subtitleText = tostring(tbl.text)
		
		-- 创建markup对象
		local color = tbl.color or Color(255, 255, 255)
		local markup = markup.Parse("<color=" .. color.r .. "," .. color.g .. "," .. color.b .. ",255><font=ofgui_medium>" .. subtitleName .. "</font></color><font=ofgui_medium>" .. subtitleText .. "</font>", maxWidth)
		
		-- 计算总高度
		local totalHeight = markup:GetHeight()
		
		-- 计算绘制位置
		local yPos = h / 1.1 + derp + (k - 1) * (totalHeight + 10)
		
		-- 绘制实际文本
		markup:Draw(w / 2, yPos, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
end)