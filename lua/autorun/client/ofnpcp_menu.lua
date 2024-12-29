AddCSLuaFile()

local frame  -- 添加一个变量来跟踪打开的菜单

local function RefreshNPCButtons(left_panel, right_panel)
	local metropoliceData = file.Read("data/of_npcp/metropolice_ranks.json", "GAME")
	local combineData = file.Read("data/of_npcp/combine_ranks.json", "GAME")
	if metropoliceData then
		metropoliceRanks = util.JSONToTable(metropoliceData).ranks
	end
	if combineData then
		combineRanks = util.JSONToTable(combineData).ranks
	end

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
		button:SetTall(80 * OFGUI.ScreenScale)
		button:SetModel(npcData.model or "models/error.mdl")
		button:SetTitle(L(npcData.name) .. " “" .. L(npcData.nickname) .. "”")
		
		-- 设置描述文字
		local description = ""
		if npcData.rank then
			if npcData.type == "metropolice" then
				local rank = metropoliceRanks["i" .. npcData.rank]
				button:SetBadge("ofnpcp/rankicons/rank_".. npcData.rank .. ".tga")
				description = L(rank)
			else
				local rank = combineRanks["i" .. npcData.rank]
				button:SetBadge("ofnpcp/rankicons/rank_".. npcData.rank .. ".tga")
				description = L(rank)
			end
		elseif npcData.job then
			description = L(npcData.job)
			if npcData.specialization then
				description = description .. " - " .. L(npcData.specialization)
			end
		elseif npcData.gamename then
			description = npcData.gamename
		end
		button:SetDescription(description)
		
		-- 按钮点击事件
		button.DoClick = function()
			right_panel:Clear()
			
			local nameEntry = vgui.Create("OFTextEntry", right_panel)
			nameEntry:Dock(TOP)
			nameEntry:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
			nameEntry:SetTall(32 * OFGUI.ScreenScale)
			nameEntry:SetValue(L(npcData.name) or "")
			
			local submitButton = vgui.Create("OFButton", right_panel)
			submitButton:Dock(TOP)
			submitButton:SetTall(32 * OFGUI.ScreenScale)
			submitButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
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
			divider:DockMargin(4 * OFGUI.ScreenScale, 8 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 8 * OFGUI.ScreenScale)
			divider:SetTall(2 * OFGUI.ScreenScale)
			divider.Paint = function(self, w, h)
				surface.SetDrawColor(100, 100, 100, 255)
				surface.DrawRect(0, 0, w, h)
			end

			-- 添加tag显示
			if npcData.tag_ability then
				local abilityButton = vgui.Create("OFSkillButton", right_panel)
				abilityButton:Dock(TOP)
				abilityButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
				abilityButton:SetTall(80 * OFGUI.ScreenScale)
				abilityButton:SetIcon("ofnpcp/roleicons/verified.png")
				abilityButton:SetTitle(L(npcData.tag_ability))
				abilityButton:SetDescription(L(npcData.tag_ability_desc))
				abilityButton:SetHoveredColor(Color(100, 255, 100))
			end
			
			if npcData.tag_trade then
				local tradeButton = vgui.Create("OFSkillButton", right_panel)
				tradeButton:Dock(TOP)
				tradeButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
				tradeButton:SetTall(80 * OFGUI.ScreenScale)
				tradeButton:SetIcon("ofnpcp/roleicons/owner.png")
				tradeButton:SetTitle(L(npcData.tag_trade))
				tradeButton:SetDescription(L(npcData.tag_trade_desc))
				tradeButton:SetHoveredColor(Color(255, 200, 100))
			end
			
			if npcData.tag_social then
				local socialButton = vgui.Create("OFSkillButton", right_panel)
				socialButton:Dock(TOP)
				socialButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
				socialButton:SetTall(80 * OFGUI.ScreenScale)
				socialButton:SetIcon("ofnpcp/roleicons/partner.png")
				socialButton:SetTitle(L(npcData.tag_social))
				socialButton:SetDescription(L(npcData.tag_social_desc))
				socialButton:SetHoveredColor(Color(100, 200, 255))
			end

			-- 显示评论
			if npcData.comments then
				for _, commentData in ipairs(npcData.comments) do
					local commentLabel = vgui.Create("OFNPCButton", right_panel)
					commentLabel:Dock(TOP)
					commentLabel:SetTall(80 * OFGUI.ScreenScale)
					commentLabel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
					commentLabel:SetModel(commentData.model or "models/error.mdl")
					commentLabel:SetTitle(commentData.player)
					commentLabel:SetDescription(commentData.comment)
				end
			end

			-- 添加评论输入框
			local commentEntry = vgui.Create("OFTextEntry", right_panel)
			commentEntry:Dock(TOP)
			commentEntry:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
			commentEntry:SetTall(32 * OFGUI.ScreenScale)
			commentEntry:SetPlaceholderText("在此输入评论...")

			-- 添加提交评论按钮
			local submitCommentButton = vgui.Create("OFButton", right_panel)
			submitCommentButton:Dock(TOP)
			submitCommentButton:SetTall(32 * OFGUI.ScreenScale)
			submitCommentButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
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
	if IsValid(frame) then  -- 检查是否已经有一个打开的菜单
		frame:Close()  -- 关闭已打开的菜单
	end

	frame = vgui.Create("OFFrame")  -- 创建新的菜单
	frame:SetTitle("NPC性格控制")

	local sheet = vgui.Create("OFPropertySheet", frame)
	sheet:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	sheet:Dock(FILL)

	local pan1 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet("图鉴", pan1)

	local pan2 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet("空白标签页", pan2)

	-- 创建一个水平分割面板
	local horizontalDivider = vgui.Create("DHorizontalDivider", pan1)
	horizontalDivider:Dock(FILL)
	horizontalDivider:DockMargin(6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale)
	horizontalDivider:SetLeftWidth(ScrW()/ 3) -- 设置左侧面板的初始宽度
	horizontalDivider:SetDividerWidth(8 * OFGUI.ScreenScale) -- 设置分割线宽度

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
    title = "Gmod Legend",
    icon = "oftoollogo/ofnpcplogo.png",
    init = function()
        AddOFFrame()
    end
})