﻿-- 字幕表
Subtitles_Table = {}

local Subtitles_CurTable = {}

-- 创建字幕
function Subtitles_Create(tbl2)
	for _, v in pairs(Subtitles_CurTable) do
		if v.text == tbl2.text then return end
	end
	
	if table.Count(Subtitles_CurTable) < 15 then
		table.insert(Subtitles_CurTable, tbl2)
		timer.Simple(5, function()
			table.RemoveByValue(Subtitles_CurTable, tbl2)
		end)
	else
		table.remove(Subtitles_CurTable, 15)
	end
end

-- HUD绘制钩子
hook.Add("HUDPaint", "Subtitles_Hud", function()
	local w = ScrW()
	local h = ScrH()
	
	local derp = -40 * OFGUI.ScreenScale
	local spacing
	
	for k, tbl in pairs(table.Reverse(Subtitles_CurTable)) do
		k = k - 1
		local oursubject = tostring(tbl.npc)
		local ourtext = tostring(tbl.text)
		local textheight = 35
		local newline = ""
		
		if k == 1 then
			spacing = 0
		end
		
		-- 支持换行
		if ourtext:find("\n") then
			for k, v in pairs(string.Split(ourtext, "\n")) do
				if k == 1 then
					ourtext = v
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
		local textw2, texth2 = surface.GetTextSize(tostring(tbl.npc) .. ": ")

		-- 绘制阴影效果
		surface.SetTextColor(Color(0, 0, 0, 150)) -- 设置阴影颜色
		surface.SetTextPos(w / 2 - (textw + textw2) / 2 + 1 * OFGUI.ScreenScale, h / 1.1 + derp - k * textheight + 1 * OFGUI.ScreenScale) -- 调整位置
		surface.DrawText(oursubject .. ": ")
		
		surface.SetTextColor(Color(0, 0, 0, 150)) -- 设置阴影颜色
		surface.SetTextPos(w / 2 - (textw + textw2) / 2 + textw2 + 1 * OFGUI.ScreenScale, h / 1.1 + derp - k * textheight + 1 * OFGUI.ScreenScale) -- 调整位置
		surface.DrawText(ourtext)

		-- 绘制实际文本
		local textColor = tbl.npccol or Color(255, 255, 255)  -- 如果 tbl.npccol 无效，则使用白色
		surface.SetTextColor(textColor)
		surface.SetTextPos(w / 2 - (textw + textw2) / 2, h / 1.1 + derp - k * textheight)
		surface.DrawText(oursubject .. ": ")

		surface.SetTextColor(Color(255, 255, 255, 255))
		surface.SetTextPos(w / 2 - (textw + textw2) / 2 + textw2, h / 1.1 + derp - k * textheight)
		surface.DrawText(ourtext)

		-- 处理换行
		if newline then
			surface.SetFont("ofgui_medium")
			surface.SetTextColor(Color(255, 255, 255, 255))
			surface.SetTextPos(w / 2 - (textw + textw2) / 2 + textw2, h / 1.1 + derp - k * textheight + 25)
			surface.DrawText(newline)
		end

		surface.SetDrawColor(255, 255, 255, 200)
	end
end)