local activeSubtitles = {}

-- 创建字幕
function CreateNPCDialogSubtitles(npc, text)
	local npcs = GetAllNPCsList()
	local npcIdentity = npcs[npc:EntIndex()]

	-- 这里不知道为什么npcIdentity报错，加个限制
	if not npcIdentity then return end

	local npcname = L(npcIdentity.name)
	local npcnickname = L(npcIdentity.nickname)

	-- 创建新的对话
	local dialog = {
		npcname = npcname,
		npcnickname = npcnickname,
		text = text,
		color = npcIdentity.color
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
	local spacing
	
	-- 修改为从上到下绘制字幕
	for k, tbl in ipairs(activeSubtitles) do
		local subtitleName = tostring(tbl.npcname) .. " “" .. tostring(tbl.npcnickname) .. "” " .. ": "
		local subtitleText = tostring(tbl.text)
		local textheight = 35
		local newline = ""
		
		if k == 1 then
			spacing = 0
		end
		
		-- 支持换行
		if subtitleText:find("\n") then
			for k, v in pairs(string.Split(subtitleText, "\n")) do
				if k == 1 then
					subtitleText = v
				elseif k == 2 then
					newline = v
					spacing = 1
				end
			end
		end

		if spacing ~= 0 then
			textheight = 60
		end
		
		-- 设置字体并获取文本宽度和高度
		surface.SetFont("ofgui_medium")
		local textw, texth = surface.GetTextSize(tostring(tbl.text))
		local textw2, texth2 = surface.GetTextSize(subtitleName)

		-- 绘制阴影效果
		surface.SetTextColor(Color(0, 0, 0, 150)) -- 设置阴影颜色
		surface.SetTextPos(w / 2 - (textw + textw2) / 2 + 1 * OFGUI.ScreenScale, h / 1.1 + derp + (k - 1) * textheight + 1 * OFGUI.ScreenScale) -- 调整位置
		surface.DrawText(subtitleName)
		
		surface.SetTextColor(Color(0, 0, 0, 150)) -- 设置阴影颜色
		surface.SetTextPos(w / 2 - (textw + textw2) / 2 + textw2 + 1 * OFGUI.ScreenScale, h / 1.1 + derp + (k - 1) * textheight + 1 * OFGUI.ScreenScale) -- 调整位置
		surface.DrawText(subtitleText)

		-- 绘制实际文本
		local textColor = tbl.color or Color(255, 255, 255)  -- 如果 tbl.color 无效，则使用白色
		surface.SetTextColor(textColor)
		surface.SetTextPos(w / 2 - (textw + textw2) / 2, h / 1.1 + derp + (k - 1) * textheight)
		surface.DrawText(subtitleName)

		surface.SetTextColor(Color(255, 255, 255, 255))
		
		surface.SetTextPos(w / 2 - (textw + textw2) / 2 + textw2, h / 1.1 + derp + (k - 1) * textheight)
		surface.DrawText(subtitleText)

		-- 处理换行
		if newline then
			surface.SetFont("ofgui_medium")
			surface.SetTextColor(Color(255, 255, 255, 255))
			surface.SetTextPos(w / 2 - (textw + textw2) / 2 + textw2, h / 1.1 + derp + (k - 1) * textheight + 25)
			surface.DrawText(newline)
		end

		surface.SetDrawColor(255, 255, 255, 200)
	end
end)