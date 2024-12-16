AddCSLuaFile()

local function RefreshNPCButtons(left_panel, right_panel)
	-- 清除现有按钮
	left_panel:Clear()
	
	-- 获取所有NPC数据
	local npcs = GetAllNPCsList()
	
	-- 为每个NPC创建按钮
	for entIndex, npcData in pairs(npcs) do
		-- 创建新的NPC按钮
		local button = vgui.Create("OFNPCButton", left_panel)
		button:Dock(TOP)
		button:DockMargin(0, 0, 0, 2)
		button:SetTall(ScrW()/ 24)
		button:SetModel(npcData.model or "models/error.mdl")
		button:SetTitle(L(npcData.name) .. " “" .. L(npcData.nickname) .. "”")
		
		-- 设置描述文字
		local description = ""
		if npcData.job then
			description = L(npcData.job)
			if npcData.specialization then
				description = description .. " - " .. L(npcData.specialization)
			end
		elseif npcData.rank then
			description = L(npcData.rank)
		end
		button:SetDescription(description)
		
		-- 按钮点击事件
		button.DoClick = function()
			right_panel:Clear()
			
			local nameEntry = vgui.Create("OFTextEntry", right_panel)
			nameEntry:Dock(TOP)
			nameEntry:DockMargin(4, 4, 4, 4)
			nameEntry:SetTall(32)
			nameEntry:SetValue(L(npcData.name) or "")
			
			local submitButton = vgui.Create("OFButton", right_panel)
			submitButton:Dock(TOP)
			submitButton:DockMargin(4, 4, 4, 4)
			submitButton:SetText("确认修改")
			submitButton.DoClick = function()
				local newName = nameEntry:GetValue()
				if newName and newName ~= "" then
					-- 发送更新请求到服务器
					net.Start("UpdateNPCName")
						net.WriteInt(entIndex, 32)
						net.WriteString(newName)
					net.SendToServer()
				end
			end
			
			-- 添加分隔线
			local divider = vgui.Create("DPanel", right_panel)
			divider:Dock(TOP)
			divider:DockMargin(4, 8, 4, 8)
			divider:SetTall(2)
			divider.Paint = function(self, w, h)
				surface.SetDrawColor(100, 100, 100, 255)
				surface.DrawRect(0, 0, w, h)
			end

			-- 添加水平滚动条
			local horizontal_scroll = vgui.Create("OFHorizontalScroller", right_panel)
			horizontal_scroll:Dock(TOP)
			horizontal_scroll:SetTall(ScrW() / 6)
			horizontal_scroll:SetOverlap(-3)
			-- horizontal_scroll:SetUseLiveDrag(true)

			if npcData.ability_tag then
				local abilityButton = vgui.Create("OFCard", horizontal_scroll)
				abilityButton:SetWide(ScrW() / 9)
				abilityButton:Dock(LEFT)
				abilityButton:SetIcon("ofnpcp/roleicons/verified.png")
				abilityButton:SetTitle(L(npcData.ability_tag))
				abilityButton:SetDescription(L(npcData.ability_desc))
				abilityButton:SetBorderColor(Color(100, 255, 100))
				horizontal_scroll:AddPanel(abilityButton)
			end
			
			if npcData.trade_tag then
				local tradeButton = vgui.Create("OFCard", horizontal_scroll)
				tradeButton:SetWide(ScrW() / 9)
				tradeButton:Dock(LEFT)
				tradeButton:SetIcon("ofnpcp/roleicons/owner.png")
				tradeButton:SetTitle(L(npcData.trade_tag))
				tradeButton:SetDescription(L(npcData.trade_desc))
				tradeButton:SetBorderColor(Color(255, 200, 100))
				horizontal_scroll:AddPanel(tradeButton)
			end
			
			if npcData.social_tag then
				local socialButton = vgui.Create("OFCard", horizontal_scroll)
				socialButton:SetWide(ScrW() / 9)
				socialButton:Dock(LEFT)
				socialButton:SetIcon("ofnpcp/roleicons/partner.png")
				socialButton:SetTitle(L(npcData.social_tag))
				socialButton:SetDescription(L(npcData.social_desc))
				socialButton:SetBorderColor(Color(100, 200, 255))
				horizontal_scroll:AddPanel(socialButton)
			end
			-- 添加tag显示
			if npcData.ability_tag then
				local abilityButton = vgui.Create("OFSkillButton", right_panel)
				abilityButton:Dock(TOP)
				abilityButton:DockMargin(4, 4, 4, 4)
				abilityButton:SetTall(64)
				abilityButton:SetIcon("ofnpcp/roleicons/verified.png")
				abilityButton:SetTitle(L(npcData.ability_tag))
				abilityButton:SetDescription(L(npcData.ability_desc))
				abilityButton:SetBorderColor(Color(100, 255, 100))
			end
			
			if npcData.trade_tag then
				local tradeButton = vgui.Create("OFSkillButton", right_panel)
				tradeButton:Dock(TOP)
				tradeButton:DockMargin(4, 4, 4, 4)
				tradeButton:SetTall(64)
				tradeButton:SetIcon("ofnpcp/roleicons/owner.png")
				tradeButton:SetTitle(L(npcData.trade_tag))
				tradeButton:SetDescription(L(npcData.trade_desc))
				tradeButton:SetBorderColor(Color(255, 200, 100))
			end
			
			if npcData.social_tag then
				local socialButton = vgui.Create("OFSkillButton", right_panel)
				socialButton:Dock(TOP)
				socialButton:DockMargin(4, 4, 4, 4)
				socialButton:SetTall(64)
				socialButton:SetIcon("ofnpcp/roleicons/partner.png")
				socialButton:SetTitle(L(npcData.social_tag))
				socialButton:SetDescription(L(npcData.social_desc))
				socialButton:SetBorderColor(Color(100, 200, 255))
			end

			-- 显示评论
			if npcData.comments then
				for _, commentData in ipairs(npcData.comments) do
					local commentLabel = vgui.Create("OFNPCButton", right_panel)
					commentLabel:Dock(TOP)
					commentLabel:DockMargin(4, 4, 4, 4)
					commentLabel:SetModel(commentData.model or "models/error.mdl")
					commentLabel:SetTitle(commentData.player)
					commentLabel:SetDescription(commentData.comment)
				end
			end

			-- 添加评论输入框
			local commentEntry = vgui.Create("OFTextEntry", right_panel)
			commentEntry:Dock(TOP)
			commentEntry:DockMargin(4, 4, 4, 4)
			commentEntry:SetTall(32)
			commentEntry:SetPlaceholderText("在此输入评论...")

			-- 添加提交评论按钮
			local submitCommentButton = vgui.Create("OFButton", right_panel)
			submitCommentButton:Dock(TOP)
			submitCommentButton:DockMargin(4, 4, 4, 4)
			submitCommentButton:SetText("提交评论")
			submitCommentButton.DoClick = function()
				local comment = commentEntry:GetValue()
				if comment and comment ~= "" then
					-- 发送评论到服务器
					net.Start("SubmitNPCComment")
						net.WriteInt(entIndex, 32)
						net.WriteString(comment)
					net.SendToServer()

					-- 刷新右侧栏
					RefreshNPCButtons(left_panel, right_panel)  -- 刷新右侧栏以显示最新评论

					-- 清空评论输入框
					commentEntry:SetValue("")  -- 清空聊天框
				end
			end
		end

		button.DoRightClick = function()
			local menu = vgui.Create("OFMenu")
			menu:AddOption("治疗 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(entIndex, 32)
					net.WriteString("heal")
				net.SendToServer()
			end)
			
			menu:AddOption("杀死 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(entIndex, 32)
					net.WriteString("kill")
				net.SendToServer()
				
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
			
			menu:AddOption("删除 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(entIndex, 32)
					net.WriteString("remove")
				net.SendToServer()
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
						
			menu:AddOption("治疗所有 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(-1, 32)
					net.WriteString("healall")
				net.SendToServer()
				
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
			
			menu:AddOption("杀死所有 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(-1, 32)
					net.WriteString("killall")
				net.SendToServer()
				
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
			
			menu:AddOption("删除所有 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(-1, 32)
					net.WriteString("removeall")
				net.SendToServer()
				
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
			
			menu:AddOption("刷新列表", function()
				RefreshNPCButtons(left_panel, right_panel)
			end)
			
			menu:Open()
		end
	end
end

local function AddOFFrame()
	local frame = vgui.Create("OFFrame")
	frame:SetTitle("NPC性格控制")

	local sheet = vgui.Create("OFPropertySheet", frame)
	sheet:DockMargin(4, 4, 4, 4)
	sheet:Dock(FILL)

	local pan1 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet("图鉴", pan1)

	local pan2 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet("空白标签页", pan2)

	-- 创建一个水平分割面板
	local horizontalDivider = vgui.Create("DHorizontalDivider", pan1)
	horizontalDivider:Dock(FILL)
	horizontalDivider:DockMargin(6, 6, 6, 6)
	horizontalDivider:SetLeftWidth(ScrW()/ 3) -- 设置左侧面板的初始宽度
	horizontalDivider:SetDividerWidth(8) -- 设置分割线宽度

	local left_panel = vgui.Create("OFScrollPanel")
	horizontalDivider:SetLeft(left_panel)

	local right_panel = vgui.Create("OFScrollPanel")
	horizontalDivider:SetRight(right_panel)

	-- 初始加载NPC列表
	RefreshNPCButtons(left_panel, right_panel)
	
	-- 添加更新钩子
	hook.Add("RefreshNPCMenu", "UpdateNPCButtonList", function()
		if IsValid(left_panel) then
			RefreshNPCButtons(left_panel, right_panel)
		end
	end)
	
	-- 当面板关闭时移除钩子
	frame.OnRemove = function()
		hook.Remove("RefreshNPCMenu", "UpdateNPCButtonList")
	end
end

list.Set("DesktopWindows", "ofnpcp", {
    title = "NPC 性格",
    icon = "oftoollogo/ofnpcplogo.png",
    init = function()
        AddOFFrame()
    end
})