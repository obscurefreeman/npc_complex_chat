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

		local npcName = L(npcData.name)
		if npcData.name == npcData.gamename then
			npcName = language.GetPhrase(npcData.gamename)
		end
		
		-- 创建名称输入和提交按钮
		local nameEntry = vgui.Create("OFTextEntry", right_panel)
		nameEntry:Dock(TOP)
		nameEntry:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		nameEntry:SetTall(32 * OFGUI.ScreenScale)
		nameEntry:SetValue(npcName or "")
		
		local submitButton = vgui.Create("OFButton", right_panel)
		submitButton:Dock(TOP)
		submitButton:SetTall(32 * OFGUI.ScreenScale)
		submitButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		submitButton:SetText(L("ui.npclist.confirm_edit"))
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
				local button = vgui.Create("OFAdvancedButton", parent)
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
		commentEntry:SetPlaceholderText(L("ui.npclist.comment_placeholder"))

		-- 添加提交评论按钮
		local submitCommentButton = vgui.Create("OFButton", right_panel)
		submitCommentButton:Dock(TOP)
		submitCommentButton:SetTall(32 * OFGUI.ScreenScale)
		submitCommentButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		submitCommentButton:SetText(L("ui.npclist.submit_comment"))
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
		local promptcontent = L(npcData.prompt)
		promptcontent = ReplacePlaceholders(promptcontent, npcData)
		local campTextEntry = vgui.Create("OFTextEntry", right_panel)
		campTextEntry:SetHeight(120 * OFGUI.ScreenScale)
		campTextEntry:Dock(TOP)
		campTextEntry:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		campTextEntry:SetValue(promptcontent)
		campTextEntry:SetMultiline( true )

		-- 添加更新提示词按钮
		local updatePromptButton = vgui.Create("OFButton", right_panel)
		updatePromptButton:Dock(TOP)
		updatePromptButton:SetTall(32 * OFGUI.ScreenScale)
		updatePromptButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		updatePromptButton:SetText(L("ui.ai_system.update_prompt"))
		updatePromptButton.DoClick = function()
			local newPrompt = campTextEntry:GetValue()
			if newPrompt and newPrompt ~= "" then
				-- 发送更新请求到服务器
				net.Start("UpdateNPCPrompt")
					net.WriteInt(entIndex, 32)
					net.WriteString(newPrompt)
				net.SendToServer()
			end
		end
		
		local voiceComboBox = vgui.Create("OFComboBox", right_panel)
		voiceComboBox:Dock(TOP)
		voiceComboBox:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		voiceComboBox:SetTall(32 * OFGUI.ScreenScale)
		voiceComboBox:SetValue(L("ui.npclist.select_voice"))
		
		-- 获取所有可用的配音
		local voices = {}
		local voiceMap = {}  -- 新增哈希表
		local clientLang = GetConVar("gmod_language"):GetString():match("^zh%-") and "zh" or "en"
		for _, voiceGroup in ipairs(GLOBAL_OFNPC_DATA.voice.voices) do
			if voiceGroup.language == clientLang then
				for _, voice in ipairs(voiceGroup.voices) do
					table.insert(voices, {name = voice.name, code = voice.code})
					voiceMap[voice.name] = voice.code  -- 填充哈希表
				end
			end
		end
		
		-- 添加配音选项
		for _, voice in ipairs(voices) do
			voiceComboBox:AddChoice(voice.name, voice.code)
		end
		
		-- 设置当前配音
		if npcData.voice then
			for _, voice in ipairs(voices) do
				if voice.code == npcData.voice then
					voiceComboBox:SetValue(voice.name)
					break
				end
			end
		end
		
		-- 当选择改变时立即发送网络请求
		voiceComboBox.OnSelect = function(panel, index, value, data)
			local selectedVoiceCode = voiceMap[value]
			if selectedVoiceCode then
				-- 发送更新请求到服务器
				net.Start("UpdateNPCVoice")
					net.WriteInt(entIndex, 32)
					net.WriteString(selectedVoiceCode)
				net.SendToServer()
			end
		end
	end
	
	-- 优化右键菜单选项
	local function CreateContextMenu(entIndex)
		local menu = vgui.Create("OFMenu")
		local actions = {
			{name = L("ui.npclist.heal_npc"), cmd = "heal"},
			{name = L("ui.npclist.kill_npc"), cmd = "kill"},
			{name = L("ui.npclist.remove_npc"), cmd = "remove"},
			{name = L("ui.npclist.heal_all"), cmd = "healall", global = true},
			{name = L("ui.npclist.kill_all"), cmd = "killall", global = true},
			{name = L("ui.npclist.remove_all"), cmd = "removeall", global = true}
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
		
		menu:AddOption(L("ui.npclist.refresh_list"), function()
			RefreshNPCButtons(left_panel, right_panel)
		end)
		
		return menu
	end

	-- 为每个NPC创建按钮
	for entIndex, npcData in pairs(npcs) do
		local npcName
		if npcData.name == npcData.gamename then
			npcName = language.GetPhrase(npcData.gamename)
		else
			npcName = L(npcData.name) .. " “" .. L(npcData.nickname) .. "”"
		end

		-- 创建新的NPC按钮
		local button = vgui.Create("OFNPCButton", left_panel)
		button:Dock(TOP)
		button:DockMargin(0, 0, 0, 2)
		button:SetTall(80 * OFGUI.ScreenScale)
		button:SetModel(npcData.model or "models/error.mdl")
		button:SetTitle(npcName)
		
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
        local groupButton = vgui.Create("OFAdvancedButton", left_panel)
        groupButton:Dock(TOP)
        groupButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
        groupButton:SetTall(80 * OFGUI.ScreenScale)
        groupButton:SetTitle(groupData.name)
        groupButton:SetDescription(groupData.desc)
		groupButton:SetIcon("ofnpcp/camps/preview/" .. groupKey .. ".png")
		groupButton:SetCardIcon("ofnpcp/camps/large/" .. groupKey .. ".png")
		groupButton:SetHoveredColor(GLOBAL_OFNPC_DATA.cards.info[groupKey].color)

        -- 按钮点击事件
        groupButton.DoClick = function()
            -- 清除右侧面板
            right_panel:Clear()

			local card_preview_panel = vgui.Create("DPanel", right_panel)
			card_preview_panel.Paint = function(self, w, h)
				surface.SetDrawColor(0, 0, 0, 0)
				surface.DrawRect(0, 0, w, h)
			end
			card_preview_panel:Dock(RIGHT)
			card_preview_panel:SetWidth(350 * OFGUI.ScreenScale)

			local deckbutton = vgui.Create("OFButton",card_preview_panel)
            deckbutton:Dock(BOTTOM)
			deckbutton:SetHeight(80 * OFGUI.ScreenScale)
			deckbutton:SetText(L("ui.deck_system.select_deck"))
			deckbutton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)

			local right_card_panel = vgui.Create("OFScrollPanel",card_preview_panel)
            right_card_panel:Dock(FILL)

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

                -- 右侧使用 OFAdvancedButton
                local cardButton = vgui.Create("OFAdvancedButton", right_card_panel)
                cardButton:Dock(TOP)
                cardButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                cardButton:SetTall(80 * OFGUI.ScreenScale)
                cardButton:SetTitle(cardInfo.data.name)
                cardButton:SetDescription(cardInfo.data.d[math.random(#cardInfo.data.d)])
                cardButton:SetIcon("ofnpcp/cards/preview/" .. cardInfo.key .. ".png")
                cardButton:SetCardIcon("ofnpcp/cards/large/" .. cardInfo.key .. ".png")
            end

            deckbutton.DoClick = function()
                -- 获取当前选择的牌组
                local selectedDeck = groupKey
                
                -- 发送牌组选择到服务器
                net.Start("SelectPlayerDeck")
                    net.WriteString(selectedDeck)
                net.SendToServer()
            end
        end
    end
end

-- 创建控件辅助函数
local function CreateControl(parent, controlType, options)
    local control = vgui.Create(controlType, parent)
    control:Dock(TOP)
    control:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
    control:SetTall(32 * OFGUI.ScreenScale)
    if options then
        for k, v in pairs(options) do
            control[k](control, v)
        end
    end
    return control
end

local function LoadpersonalizationSettings(personalizationLeftPanel)
    personalizationLeftPanel:Clear()

    -- 读取本地保存的配音设置
    local personalizationSettings = file.Read("of_npcp/personalization_settings.txt", "DATA")
    if personalizationSettings then
        personalizationSettings = util.JSONToTable(personalizationSettings)
    else
        -- 默认设置
        personalizationSettings = {
            volume = 5.0,
            api_url = "https://freetv-mocha.vercel.app/api/aiyue"
        }
    end

    -- 创建API URL输入框
    local apiUrlEntry = CreateControl(personalizationLeftPanel, "OFTextEntry", {
        SetValue = personalizationSettings.api_url,
        SetPlaceholderText = "API URL"
    })

	-- 创建音量滑块
	local volumeSlider = CreateControl(personalizationLeftPanel, "OFNumSlider", {
		SetText = "音量设置",
		SetMin = 0,
		SetMax = 10,
		SetDecimals = 1,
		SetValue = personalizationSettings.volume
	})

    -- 保存按钮
    local saveButton = CreateControl(personalizationLeftPanel, "OFButton", {
        SetText = "保存设置"
    })
    saveButton.DoClick = function()
        local newSettings = {
            volume = tonumber(volumeSlider:GetValue()) or 1.0,
            api_url = apiUrlEntry:GetValue()
        }
        file.Write("of_npcp/personalization_settings.txt", util.TableToJSON(newSettings))
        notification.AddLegacy("配音设置已保存", NOTIFY_GENERIC, 5)
    end

    local jsonUrlEntry = CreateControl(personalizationLeftPanel, "OFTextEntry", {
        SetPlaceholderText = "Discord JSON URL"
    })

    local saveButton2 = CreateControl(personalizationLeftPanel, "OFButton", {
        SetText = "设置NPC名称池"
    })
    saveButton2.DoClick = function()
        local newUrl = jsonUrlEntry:GetValue()
        if newUrl and newUrl ~= "" then
            net.Start("UpdateNPCNameAPI")
                net.WriteString(newUrl)
            net.SendToServer()
        end
        notification.AddLegacy("名称设置已发送至服务器", NOTIFY_GENERIC, 5)
    end
end

local function AddOFFrame()
	if IsValid(frame) then  -- 检查是否已经有一个打开的菜单
		frame:Close()  -- 关闭已打开的菜单
	end

	frame = vgui.Create("OFFrame")  -- 创建新的菜单
	frame:SetTitle(L("ui.title"))

	local sheet = vgui.Create("OFPropertySheet", frame)
	sheet:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	sheet:Dock(FILL)

	local pan1 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet(L("ui.tab.ai_system"), pan1, "icon16/computer.png")

	local pan2 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet(L("ui.tab.deck_system"), pan2, "icon16/creditcards.png")

	local pan3 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet(L("ui.tab.npclist"), pan3, "icon16/group.png")

	-- 创建一个水平分割面板
	local horizontalDivider = vgui.Create("DHorizontalDivider", pan3)
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
	left_panel_cards:SetWidth(450 * OFGUI.ScreenScale)

	local right_panel_cards = vgui.Create("DPanel", pan2)  -- 创建一个透明不可见的元素作为容器
	right_panel_cards.Paint = function(self, w, h)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, w, h)
	end
	right_panel_cards:Dock(FILL)

	-- 创建AI设置面板布局
	local aiHorizontalDivider = vgui.Create("DHorizontalDivider", pan1)
	aiHorizontalDivider:Dock(FILL)
	aiHorizontalDivider:DockMargin(6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale)
	aiHorizontalDivider:SetLeftWidth(ScrW() / 4)

	local aiLeftPanel = vgui.Create("OFScrollPanel")
	aiHorizontalDivider:SetLeft(aiLeftPanel)

	local aiRightPanel = vgui.Create("OFScrollPanel")
	aiHorizontalDivider:SetRight(aiRightPanel)

	-- 读取AI设置文件
	local aiSettings = file.Read("of_npcp/ai_settings.txt", "DATA")
	if aiSettings then
		aiSettings = util.JSONToTable(aiSettings)
	end

	-- 加载AI设置面板
	local function LoadAISettings(providerKey, aiRightPanel)
		aiRightPanel:Clear()

		-- 获取当前提供商的默认设置
		local provider = GLOBAL_OFNPC_DATA.aiProviders[providerKey]
		local settings = aiSettings and aiSettings.provider == providerKey and aiSettings or {
			url = provider.url,
			temperature = 0.7,
			max_tokens = 500
		}

		-- 创建设置控件
		local apiUrlEntry = CreateControl(aiRightPanel, "OFTextEntry", {
			SetValue = settings.url,
			SetPlaceholderText = "API URL"
		})

		local apiKeyEntry = CreateControl(aiRightPanel, "OFTextEntry", {
			SetValue = settings.key or "",
			SetPlaceholderText = L(provider.name) .. " API"
		})

		local modelComboBox = CreateControl(aiRightPanel, "OFComboBox", {
			SetValue = settings.model or L("ui.ai_system.model_select")
		})
		for _, model in ipairs(provider.model) do
			modelComboBox:AddChoice(model)
		end
		if settings.model then
			modelComboBox:SetValue(settings.model)
		end

		local tempSlider = CreateControl(aiRightPanel, "OFNumSlider", {
			SetText = L("ui.ai_system.temperature"),
			SetMin = 0,
			SetMax = 1,
			SetDecimals = 1,
			SetValue = settings.temperature
		})

		local maxTokensSlider = CreateControl(aiRightPanel, "OFNumSlider", {
			SetText = L("ui.ai_system.max_tokens"),
			SetMin = 100,
			SetMax = 2000,
			SetDecimals = 0,
			SetValue = settings.max_tokens
		})

		-- 保存按钮
		local saveButton = CreateControl(aiRightPanel, "OFButton", {
			SetText = L("ui.ai_system.save_settings")
		})
		saveButton.DoClick = function()
			local newSettings = {
				provider = providerKey,
				url = apiUrlEntry:GetValue(),
				key = apiKeyEntry:GetValue(),
				model = modelComboBox:GetSelected(),
				temperature = tonumber(tempSlider:GetValue()) or 0.7,
				max_tokens = tonumber(maxTokensSlider:GetValue()) or 500
			}
			file.Write("of_npcp/ai_settings.txt", util.TableToJSON(newSettings))
			notification.AddLegacy(L("ui.ai_system.save_success"), NOTIFY_GENERIC, 5)
		end
		-- 添加阵营提示词内容
		local camps = {
			"combine", "resistance", "union", "warlord", "church", "bandit", "other"
		}

		for _, camp in ipairs(camps) do
			local campButton = vgui.Create("OFMessage", aiRightPanel)
			campButton:SetHeight(80 * OFGUI.ScreenScale)
			campButton:Dock(TOP)
			campButton:DockMargin(4, 4, 4, 4)
			campButton:SetName(L("ui.ai_system.system_prompt") .. L("camp."..camp))
			campButton:SetText(L("prompt."..camp))
			campButton:SetColor(GLOBAL_OFNPC_DATA.cards.info[camp] and GLOBAL_OFNPC_DATA.cards.info[camp].color or color_white)
		end
	end

	-- 加载AI提供商列表
	local sortedProviders = {}
	for providerKey, providerData in pairs(GLOBAL_OFNPC_DATA.aiProviders) do
		table.insert(sortedProviders, {key = providerKey, data = providerData})
	end
	table.sort(sortedProviders, function(a, b) return a.data.index < b.data.index end)

	for _, provider in ipairs(sortedProviders) do
		local button = CreateControl(aiLeftPanel, "OFAdvancedButton", {
			SetTall = 80 * OFGUI.ScreenScale,
			SetTitle = L(provider.data.name),
			SetDescription = L(provider.data.description),
			SetIcon = "ofnpcp/ai/providers/" .. provider.key .. ".png",
			SetShowHoverCard = false
		})
		button.DoClick = function()
			LoadAISettings(provider.key, aiRightPanel)
		end
	end

	-- 加载默认设置
	if aiSettings then
		LoadAISettings(aiSettings.provider, aiRightPanel)
	end

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

	-- 添加配音设置面板
	local pan4 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet("个性化", pan4, "icon16/sound.png")

	-- 创建水平分割面板
	local personalizationHorizontalDivider = vgui.Create("DHorizontalDivider", pan4)
	personalizationHorizontalDivider:Dock(FILL)
	personalizationHorizontalDivider:DockMargin(6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale)
	personalizationHorizontalDivider:SetLeftWidth(ScrW() / 4)

	local personalizationLeftPanel = vgui.Create("OFScrollPanel")
	personalizationHorizontalDivider:SetLeft(personalizationLeftPanel)

	local personalizationRightPanel = vgui.Create("OFScrollPanel")
	personalizationHorizontalDivider:SetRight(personalizationRightPanel)

	-- 加载默认配音设置
	LoadpersonalizationSettings(personalizationLeftPanel)
end

list.Set("DesktopWindows", "ofnpcp", {
    title = "GarryLord",
    icon = "oftoollogo/ofnpcplogo.png",
    init = function()
        AddOFFrame()
    end
})