AddCSLuaFile()

local frame  -- 添加一个变量来跟踪打开的菜单

local function RefreshNPCButtons(left_panel, right_panel)
	-- 清除现有按钮
	left_panel:Clear()
	
	-- 获取所有NPC数据
	local npcs = GetAllNPCsList()
	
	-- 创建一个本地函数来处理右侧面板的刷新
	local function RefreshRightPanel(npcData, entIndex)
		right_panel:Clear()
		
		-- 创建名称输入和提交按钮
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

		local function CreateSkillButton(parent, tag, tagDesc, iconPath, hoveredColor)
			if tag then
				local button = vgui.Create("OFSkillButton", parent)
				button:Dock(TOP)
				button:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
				button:SetTall(80 * OFGUI.ScreenScale)
				button:SetIcon("ofnpcp/" .. string.gsub(iconPath, "%.", "/") .. ".png")
				button:SetTitle(L(tag))
				button:SetDescription(L(tagDesc))
				button:SetHoveredColor(hoveredColor)
			end
		end
		-- 优化技能按钮创建
		local skillButtons = {
			{tag = npcData.tag_ability, desc = npcData.tag_ability_desc, icon = npcData.tag_ability, color = Color(100, 255, 100)},
			{tag = npcData.tag_trade, desc = npcData.tag_trade_desc, icon = npcData.tag_trade, color = Color(255, 200, 100)},
			{tag = npcData.tag_social, desc = npcData.tag_social_desc, icon = npcData.tag_social, color = Color(100, 200, 255)}
		}
		
		for _, buttonData in ipairs(skillButtons) do
			CreateSkillButton(right_panel, buttonData.tag, buttonData.desc, buttonData.icon, buttonData.color)
		end

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

				-- 仅刷新当前NPC的右侧面板
				timer.Simple(0.1, function()
					RefreshRightPanel(npcData, entIndex)
				end)

				-- 清空评论输入框
				commentEntry:SetValue("")
			end
		end
	end
	
	-- 优化右键菜单选项
	local function CreateContextMenu(entIndex)
		local menu = vgui.Create("OFMenu")
		local actions = {
			{name = "治疗 NPC", cmd = "heal"},
			{name = "杀死 NPC", cmd = "kill"},
			{name = "删除 NPC", cmd = "remove"},
			{name = "治疗所有 NPC", cmd = "healall", global = true},
			{name = "杀死所有 NPC", cmd = "killall", global = true},
			{name = "删除所有 NPC", cmd = "removeall", global = true}
		}
		
		for _, action in ipairs(actions) do
			menu:AddOption(action.name, function()
				net.Start("NPCAction")
					net.WriteInt(action.global and -1 or entIndex, 32)
					net.WriteString(action.cmd)
				net.SendToServer()
				
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
		end
		
		menu:AddOption("刷新列表", function()
			RefreshNPCButtons(left_panel, right_panel)
		end)
		
		return menu
	end

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
			local rank = GLOBAL_OFNPC_DATA.rankData.ranks["i" .. npcData.rank]
			button:SetBadge("ofnpcp/rankicons/rank_".. npcData.rank .. ".tga")
			description = L(rank)
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
			RefreshRightPanel(npcData, entIndex)
		end

		button.DoRightClick = function()
			CreateContextMenu(entIndex):Open()
		end
	end
end

local function RefreshCardButtons(left_panel, right_panel)
    -- 清除现有按钮
    left_panel:Clear()
    right_panel:Clear()

    -- 从全局数据中获取牌组信息
    local cardGroups = GLOBAL_OFNPC_DATA.cards.info

    -- 创建左侧牌组选择按钮
    for groupKey, groupData in pairs(cardGroups) do
        local groupButton = vgui.Create("OFSkillButton", left_panel)
        groupButton:Dock(TOP)
        groupButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
        groupButton:SetTall(80 * OFGUI.ScreenScale)
        groupButton:SetTitle(groupData.name)
        groupButton:SetDescription(groupData.desc)
		groupButton:SetIcon("ofnpcp/camps/preview/" .. groupKey .. ".png")
		groupButton:SetCardIcon("ofnpcp/camps/large/" .. groupKey .. ".png")

        -- 按钮点击事件
        groupButton.DoClick = function()
            -- 清除右侧面板
            right_panel:Clear()

            local right_card_panel = vgui.Create("OFScrollPanel",right_panel)
            right_card_panel:Dock(RIGHT)
			right_card_panel:SetWidth(ScrW()/ 5)

            local left_card_panel = vgui.Create("OFScrollPanel",right_panel)
            left_card_panel:Dock(FILL)

            -- 获取该牌组的卡牌和所有的general卡牌
            local cards = GLOBAL_OFNPC_DATA.cards[groupKey] or {}
            local generalCards = GLOBAL_OFNPC_DATA.cards.general or {}

            -- 对卡牌进行排序
            local sortedCards = {}
            local function addCards(cardTable, cardType)
                for cardKey, cardData in pairs(cardTable) do
                    table.insert(sortedCards, {key = cardKey, data = cardData})
                end
            end
            addCards(cards, groupKey)
            addCards(generalCards, "general")
            table.sort(sortedCards, function(a, b) return a.data.cost < b.data.cost end)

            -- 使用DIconLayout实现自动换行布局
            local cardLayout = vgui.Create("OFIconLayout", left_card_panel)
            cardLayout:Dock(FILL)
            cardLayout:SetSpaceX(8 * OFGUI.ScreenScale)
            cardLayout:SetSpaceY(8 * OFGUI.ScreenScale)
			cardLayout:SetStretchWidth(true)
            
            -- 列出该牌组的所有卡牌
            for _, cardInfo in ipairs(sortedCards) do
                -- 左侧使用 OFCard
                local card = cardLayout:Add("OFCard")
                card:SetSize(213 * OFGUI.ScreenScale, 296 * OFGUI.ScreenScale)
                card:SetTitle(cardInfo.data.name)
                card:SetDescription(cardInfo.data.d[math.random(#cardInfo.data.d)])
                card:SetIcon("ofnpcp/cards/large/" .. cardInfo.key .. ".png")

                -- 右侧使用 OFSkillButton
                local cardButton = vgui.Create("OFSkillButton", right_card_panel)
                cardButton:Dock(TOP)
                cardButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                cardButton:SetTall(80 * OFGUI.ScreenScale)
                cardButton:SetTitle(cardInfo.data.name)
                cardButton:SetDescription(cardInfo.data.d[math.random(#cardInfo.data.d)])
                cardButton:SetIcon("ofnpcp/cards/preview/" .. cardInfo.key .. ".png")
                cardButton:SetCardIcon("ofnpcp/cards/large/" .. cardInfo.key .. ".png")
            end
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
	sheet:AddSheet("卡牌", pan2)

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

	local left_panel_cards = vgui.Create("OFScrollPanel", pan2)
	left_panel_cards:Dock(LEFT)
	left_panel_cards:SetWidth(ScrW()/ 4)

	local right_panel_cards = vgui.Create("DPanel", pan2)  -- 创建一个透明不可见的元素作为容器
	right_panel_cards.Paint = function(self, w, h)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, w, h)
	end
	right_panel_cards:Dock(FILL)

	-- 初始加载NPC列表
	RefreshNPCButtons(left_panel, right_panel)
	RefreshCardButtons(left_panel_cards, right_panel_cards)
	
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