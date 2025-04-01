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

		local npcName = ofTranslate(npcData.name)
		if npcData.name == npcData.gamename then
			npcName = language.GetPhrase(npcData.gamename)
		end

		local nicknameLabel = vgui.Create("OFTextLabel", right_panel)
		nicknameLabel:Dock(TOP)
		nicknameLabel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		nicknameLabel:SetText(ofTranslate("ui.npclist.npc_name"))
		
		-- 创建名称输入和提交按钮
		local nameEntry = vgui.Create("OFTextEntry", right_panel)
		nameEntry:Dock(TOP)
		nameEntry:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		nameEntry:SetTall(32 * OFGUI.ScreenScale)
		nameEntry:SetValue(npcName or "")
		
		local nicknameEntry = vgui.Create("OFTextEntry", right_panel)
		nicknameEntry:Dock(TOP)
		nicknameEntry:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		nicknameEntry:SetTall(32 * OFGUI.ScreenScale)
		nicknameEntry:SetValue(ofTranslate(npcData.nickname) or "")
		
		local submitButton = vgui.Create("OFButton", right_panel)
		submitButton:Dock(TOP)
		submitButton:SetTall(32 * OFGUI.ScreenScale)
		submitButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		submitButton:SetText(ofTranslate("ui.npclist.confirm_edit"))
		submitButton.DoClick = function()
			local newName = nameEntry:GetValue()
			local newNickname = nicknameEntry:GetValue()
			if newName and newName ~= "" and newNickname and newNickname ~= "" then
				-- 发送更新请求到服务器
				net.Start("UpdateNPCName")
					net.WriteInt(entIndex, 32)
					net.WriteString(newName)
					net.WriteString(newNickname)
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

        local function CreateSkillButton(parent, tag, hoveredColor)
            if tag then
                local button = vgui.Create("OFAdvancedButton", parent)
                button:Dock(TOP)
                button:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                button:SetTall(80 * OFGUI.ScreenScale)
                button:SetIcon("ofnpcp/" .. string.gsub(tag, "%.", "/") .. ".png")
                button:SetTitle(ofTranslate(tag))
                button:SetDescription(ofTranslate(tag .. "desc"))
                button:SetHoveredColor(hoveredColor)
                button:SetShowHoverCard(false)
            end
        end

        CreateSkillButton(right_panel, npcData.tag_ability, Color(100, 255, 100))
        CreateSkillButton(right_panel, npcData.tag_trade, Color(255, 200, 100))
        CreateSkillButton(right_panel, npcData.tag_social, Color(100, 200, 255))

		local commentLabel = vgui.Create("OFTextLabel", right_panel)
		commentLabel:Dock(TOP)
		commentLabel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		commentLabel:SetText(ofTranslate("ui.npclist.comment"))

		if npcData.comments then
            for _, commentData in ipairs(npcData.comments) do
                local commentMessage = vgui.Create("OFMessage", right_panel)
                commentMessage:Dock(TOP)
                commentMessage:SetHeight(80 * OFGUI.ScreenScale)
                commentMessage:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                commentMessage:SetName(commentData.player)
                commentMessage:SetText(commentData.comment)
				commentMessage:SetColor(commentData.color)
            end
        end

		-- 添加评论输入框
		local commentEntry = vgui.Create("OFTextEntry", right_panel)
		commentEntry:Dock(TOP)
		commentEntry:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		commentEntry:SetTall(32 * OFGUI.ScreenScale)
		commentEntry:SetPlaceholderText(ofTranslate("ui.npclist.comment_placeholder"))

		-- 添加提交评论按钮
		local submitCommentButton = vgui.Create("OFButton", right_panel)
		submitCommentButton:Dock(TOP)
		submitCommentButton:SetTall(32 * OFGUI.ScreenScale)
		submitCommentButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		submitCommentButton:SetText(ofTranslate("ui.npclist.submit_comment"))
		submitCommentButton.DoClick = function()
			local comment = commentEntry:GetValue()
			if comment and comment ~= "" then
				-- 发送评论到服务器
				net.Start("SubmitNPCComment")
					net.WriteInt(entIndex, 32)
					net.WriteString(comment)
				net.SendToServer()

				-- 清空评论输入框
				commentEntry:SetValue("")
			end
		end

		local promptLabel = vgui.Create("OFTextLabel", right_panel)
		promptLabel:Dock(TOP)
		promptLabel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		promptLabel:SetText(ofTranslate("ui.npclist.ai_prompt"))

		local promptcontent = ofTranslate(npcData.prompt)
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
		updatePromptButton:SetText(ofTranslate("ui.ai_system.update_prompt"))
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

		local voiceLabel = vgui.Create("OFTextLabel", right_panel)
		voiceLabel:Dock(TOP)
		voiceLabel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		voiceLabel:SetText(ofTranslate("ui.npclist.voice"))
		
		local voiceComboBox = vgui.Create("OFComboBox", right_panel)
		voiceComboBox:Dock(TOP)
		voiceComboBox:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		voiceComboBox:SetTall(32 * OFGUI.ScreenScale)
		voiceComboBox:SetValue(ofTranslate("ui.npclist.select_voice"))
		
		-- 获取所有可用的配音
		local voices = {}
		local voiceMap = {}  -- 新增哈希表
        local clientLang = GetConVar("gmod_language"):GetString()
		local userLang = GetConVar("of_garrylord_language"):GetString()
		clientLang = userLang ~= "" and userLang or clientLang

        if not GLOBAL_OFNPC_DATA.lang.language[clientLang] then
            clientLang = "en"
        end

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
			voiceComboBox:AddChoice(voice.name, voice.code, false, "ofnpcp/lang/" .. clientLang .. ".png")
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
			{name = ofTranslate("ui.npclist.heal_npc"), cmd = "heal"},
			{name = ofTranslate("ui.npclist.kill_npc"), cmd = "kill"},
			{name = ofTranslate("ui.npclist.remove_npc"), cmd = "remove"},
			{name = ofTranslate("ui.npclist.heal_all"), cmd = "healall", global = true},
			{name = ofTranslate("ui.npclist.kill_all"), cmd = "killall", global = true},
			{name = ofTranslate("ui.npclist.remove_all"), cmd = "removeall", global = true}
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
		
		menu:AddOption(ofTranslate("ui.npclist.refresh_list"), function()
			RefreshNPCButtons(left_panel, right_panel)
		end)
		
		return menu
	end

	-- 为每个NPC创建按钮
	local firstNPC = nil
	for entIndex, npcData in pairs(npcs) do
		local npcName
		if npcData.name == npcData.gamename then
			npcName = language.GetPhrase(npcData.gamename)
		else
			npcName = ofTranslate(npcData.name) .. " " .. ofTranslate(npcData.nickname) .. ""
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
		if npcData.rank and npcData.job and npcData.specialization and npcData.camp then
			button:SetBadge("ofnpcp/usrankicons/rank_".. npcData.rank .. ".png")
			description =  ofTranslate("camp."..tostring(npcData.camp)) .. " " .. ofTranslate("rank.".. npcData.rank) .. " - " .. ofTranslate(npcData.specialization)
			button:SetHoveredColor(GLOBAL_OFNPC_DATA.cards.info[npcData.camp].color)
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

		-- 记录第一个NPC
		if not firstNPC then
			firstNPC = {npcData = npcData, entIndex = entIndex}
		end
	end

	-- 如果有NPC，默认打开第一个
	if firstNPC then
		RefreshRightPanel(firstNPC.npcData, firstNPC.entIndex)
	end
end

local function RefreshCardButtons(left_panel, right_panel)
    -- 清除现有按钮
    left_panel:Clear()
    right_panel:Clear()

    -- 从全局数据中获取牌组信息
    local cardGroups = GLOBAL_OFNPC_DATA.cards.info

    -- 获取玩家当前阵营
    local playerCamp = OFPLAYERS[LocalPlayer():SteamID()] and OFPLAYERS[LocalPlayer():SteamID()].deck or "resistance"

    -- 创建左侧牌组选择按钮
    for groupKey, groupData in pairs(cardGroups) do
        local groupButton = vgui.Create("OFAdvancedButton", left_panel)
        groupButton:Dock(TOP)
        groupButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
        groupButton:SetTall(80 * OFGUI.ScreenScale)
        groupButton:SetTitle(ofTranslate(groupData.name))
        groupButton:SetDescription(ofTranslate(groupData.desc))
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
			deckbutton:SetText(ofTranslate("ui.deck_system.select_deck"))
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
                card:SetTitle(ofTranslate(cardInfo.data.name))
                card:SetDescription(ofTranslate(cardInfo.data.d[math.random(#cardInfo.data.d)]))
                card:SetIcon("ofnpcp/cards/large/" .. cardInfo.key .. ".png")

                -- 右侧使用 OFAdvancedButton
                local cardButton = vgui.Create("OFAdvancedButton", right_card_panel)
                cardButton:Dock(TOP)
                cardButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                cardButton:SetTall(80 * OFGUI.ScreenScale)
                cardButton:SetTitle(ofTranslate(cardInfo.data.name))
                cardButton:SetDescription(ofTranslate(cardInfo.data.d[math.random(#cardInfo.data.d)]))
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

				notification.AddLegacy(ofTranslate("ui.deck_system.select_camp"), NOTIFY_GENERIC, 5)
            end
        end

        -- 如果这是玩家当前阵营，自动打开
        if groupKey == playerCamp then
            groupButton:DoClick()
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
            api_url = ""
        }
    end

	local voicelabel = CreateControl(personalizationLeftPanel, "OFTextLabel", {
        SetText = ofTranslate("ui.personalization.voice_service")
    })

	local voiceCheckPanel = vgui.Create("EditablePanel", personalizationLeftPanel)
	voiceCheckPanel:Dock(TOP)
	voiceCheckPanel:SetTall(21 * OFGUI.ScreenScale)
	voiceCheckPanel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)

	local voiceCheckBox = vgui.Create("OFCheckBox", voiceCheckPanel)
	voiceCheckBox:Dock(LEFT)
	voiceCheckBox:SetSize(21 * OFGUI.ScreenScale, 21 * OFGUI.ScreenScale)
	voiceCheckBox:DockMargin(0, 0, 8 * OFGUI.ScreenScale, 0)
	voiceCheckBox:SetValue(GetConVar("of_garrylord_voice"):GetInt() == 1)

	local voiceCheckLabel = vgui.Create("OFTextLabel", voiceCheckPanel)
	voiceCheckLabel:SetFont("ofgui_small")
	voiceCheckLabel:Dock(FILL)
	voiceCheckLabel:SetText(ofTranslate("ui.personalization.enable_voice"))

	voiceCheckBox.OnChange = function(panel, value)
		RunConsoleCommand("of_garrylord_voice", value and "1" or "0")
	end

    -- 创建API URL输入框
    local apiUrlEntry = CreateControl(personalizationLeftPanel, "OFTextEntry", {
        SetValue = personalizationSettings.api_url,
        SetPlaceholderText = "API URL"
    })

	-- 创建音量滑块
	local volumeSlider = CreateControl(personalizationLeftPanel, "OFNumSlider", {
		SetText = ofTranslate("ui.personalization.volume_setting"),
		SetMin = 0,
		SetMax = 10,
		SetDecimals = 1,
		SetValue = personalizationSettings.volume
	})

	local voicelabel = CreateControl(personalizationLeftPanel, "OFTextLabel", {
        SetText = ofTranslate("ui.personalization.voice_player")
    })

	local voiceComboBox = CreateControl(personalizationLeftPanel, "OFComboBox", {
		SetValue = ofTranslate("ui.npclist.select_voice")
	})

	local voices = {}
	local voiceMap = {}
	local clientLang = GetConVar("gmod_language"):GetString()
	local userLang = GetConVar("of_garrylord_language"):GetString()
	clientLang = userLang ~= "" and userLang or clientLang
	
	if not GLOBAL_OFNPC_DATA.lang.language[clientLang] then
		clientLang = "en"
	end

	for _, voiceGroup in ipairs(GLOBAL_OFNPC_DATA.voice.voices) do
		if voiceGroup.language == clientLang then
			for _, voice in ipairs(voiceGroup.voices) do
				table.insert(voices, {name = voice.name, code = voice.code})
				voiceMap[voice.name] = voice.code  -- 填充哈希表
			end
		end
	end
	
	for _, voice in ipairs(voices) do
		voiceComboBox:AddChoice(voice.name, voice.code, false, "ofnpcp/lang/" .. clientLang .. ".png")
	end
	
	if personalizationSettings.voice then
		for _, voice in ipairs(voices) do
			if voice.code == personalizationSettings.voice then
				voiceComboBox:SetValue(voice.name)
				break
			end
		end
	end

	local saveButton = CreateControl(personalizationLeftPanel, "OFButton", {
		SetText = ofTranslate("ui.personalization.save_settings")
	})

    saveButton.DoClick = function()
		if not file.IsDir("of_npcp", "DATA") then
            file.CreateDir("of_npcp")
        end
        local newSettings = {
            volume = tonumber(volumeSlider:GetValue()) or 1.0,
            api_url = apiUrlEntry:GetValue(),
            voice = voiceMap[voiceComboBox:GetValue()] or personalizationSettings.voice or "zh-CN-XiaoyiNeural"
        }
        file.Write("of_npcp/personalization_settings.txt", util.TableToJSON(newSettings))
        
        -- 发送配音设置到服务器
        net.Start("UpdatePlayerVoice")
            net.WriteString(newSettings.voice)
        net.SendToServer()
        
        notification.AddLegacy(ofTranslate("ui.personalization.player_voice_setting"), NOTIFY_GENERIC, 5)
    end

    -- 添加语言设置
    local langLabel = CreateControl(personalizationLeftPanel, "OFTextLabel", {
        SetText = ofTranslate("ui.personalization.language_setting")
    })

    -- 从language.json获取支持的语言列表
    local supportedLanguages = {
        {name = ofTranslate("ui.personalization.follow_system"), code = "", icon = "ofnpcp/lang/gm.png"}
    }
    
    -- 添加语言选项
    for langCode, langData in pairs(GLOBAL_OFNPC_DATA.lang.language) do
        table.insert(supportedLanguages, {
            name = langData.name,
            code = langCode,
            icon = langData.icon
        })
    end

    -- 获取当前语言设置
    local currentLang = GetConVar("of_garrylord_language"):GetString()
    local currentValue = ofTranslate("ui.personalization.follow_system")  -- 默认值

    -- 根据currentLang查找对应的语言名称
    for _, lang in ipairs(supportedLanguages) do
        if lang.code == currentLang then
            currentValue = lang.name
            break
        end
    end

    local langComboBox = CreateControl(personalizationLeftPanel, "OFComboBox", {
        SetValue = currentValue
    })

    -- 添加语言选项
    for _, lang in ipairs(supportedLanguages) do
        langComboBox:AddChoice(lang.name, lang.code, false, lang.icon)
    end

    langComboBox.OnSelect = function(panel, index, value, data)
        RunConsoleCommand("of_garrylord_language", data)
        notification.AddLegacy(ofTranslate("ui.personalization.language_changed"), NOTIFY_GENERIC, 5)
        
        -- 关闭当前菜单
        if IsValid(frame) then
            frame:Close()
        end

        timer.Simple(0.1, function()
            AddOFFrame()
        end)
    end

	local helpLabel = CreateControl(personalizationLeftPanel, "OFTextLabel", {
        SetText = ofTranslate("ui.personalization.guide")
    })

	local helpButton = CreateControl(personalizationLeftPanel, "OFButton", {
		SetText = "Steam Guide",
	})
	helpButton.DoClick = function()
		gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3456122462")
	end

end

function AddOFFrame()
	if IsValid(frame) then  -- 检查是否已经有一个打开的菜单
		frame:Close()  -- 关闭已打开的菜单
	end

	frame = vgui.Create("OFFrame")  -- 创建新的菜单
	frame:SetTitle(ofTranslate("ui.title"):gsub("/name/", LocalPlayer():Nick()))

	local sheet = vgui.Create("OFPropertySheet", frame)
	sheet:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	sheet:Dock(FILL)

	-- 新增pan1
	local pan1 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet(ofTranslate("ui.tab.home"), pan1, "icon16/house.png")

	local pan1LeftPanel = vgui.Create("OFScrollPanel", pan1)
	pan1LeftPanel:Dock(LEFT)
	pan1LeftPanel:SetWidth(400 * OFGUI.ScreenScale)

	local pan1RightPanel = vgui.Create("OFScrollPanel", pan1)
	pan1RightPanel:Dock(RIGHT)
	pan1RightPanel:SetWidth(350 * OFGUI.ScreenScale)

	local pan1MainPanel = vgui.Create("OFScrollPanel", pan1)
	pan1MainPanel:Dock(FILL)

	-- 添加赞助者按钮
	if GLOBAL_OFNPC_DATA.sponsors then
		-- 先按order排序，再按名称排序
		table.sort(GLOBAL_OFNPC_DATA.sponsors, function(a, b)
			if a.order == b.order then
				return a.name < b.name
			else
				return a.order < b.order
			end
		end)
		
		for _, sponsor in ipairs(GLOBAL_OFNPC_DATA.sponsors) do
			local button = vgui.Create("OFAdvancedButton", pan1RightPanel)
			button:Dock(TOP)
			button:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
			button:SetTall(80 * OFGUI.ScreenScale)
			button:SetTitle(sponsor.name)
			-- 将description改为显示徽章列表
			local badges = ""
			if sponsor.badges then
				for i, badge in ipairs(sponsor.badges) do
					if i > 1 then  -- 从第二个徽章开始添加分隔符
						badges = badges .. " "
					end
					badges = badges .. ofTranslate(badge)
				end
			end
			button:SetDescription(badges)
			button:SetIcon("ofnpcp/sponsors/" .. sponsor.image .. ".png")
			button:SetHoveredColor(Color(unpack(sponsor.color)))
			button:SetShowHoverCard(false)
		end
	end

	-- 添加日志文章
	if GLOBAL_OFNPC_DATA.article.log then
		table.sort(GLOBAL_OFNPC_DATA.article.log, function(a, b) 
			return (a.timestamp or 0) > (b.timestamp or 0)
		end)
		
		for _, logEntry in ipairs(GLOBAL_OFNPC_DATA.article.log) do
			local article = vgui.Create("OFArticle", pan1LeftPanel)
			article:Dock(TOP)
			article:DockMargin(8 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
			article:SetName(ofTranslate(logEntry.title))
			
			-- 计算发布时间
			local timeDiff = os.time() - (logEntry.timestamp or os.time())
			local timeStr
			if timeDiff < 60 then
				timeStr = ofTranslate("ui.time.just_now")
			elseif timeDiff < 3600 then
				timeStr = string.format(ofTranslate("ui.time.minutes_ago"), math.floor(timeDiff / 60))
			elseif timeDiff < 86400 then
				timeStr = string.format(ofTranslate("ui.time.hours_ago"), math.floor(timeDiff / 3600))
			elseif timeDiff < 604800 then
				timeStr = string.format(ofTranslate("ui.time.days_ago"), math.floor(timeDiff / 86400))
			elseif timeDiff < 2592000 then
				timeStr = string.format(ofTranslate("ui.time.weeks_ago"), math.floor(timeDiff / 604800))
			elseif timeDiff < 31536000 then
				timeStr = string.format(ofTranslate("ui.time.months_ago"), math.floor(timeDiff / 2592000))
			else
				timeStr = string.format(ofTranslate("ui.time.years_ago"), math.floor(timeDiff / 31536000))
			end
			
			article:SetSubtitle(string.format(ofTranslate("ui.time.published_at"), timeStr))
			article:SetText(ofTranslate(logEntry.content))
			if logEntry.image then
				article:SetImage("ofnpcp/article/" .. logEntry.image .. ".png")
			end
		end
	end

	if GLOBAL_OFNPC_DATA.article.event then
		table.sort(GLOBAL_OFNPC_DATA.article.event, function(a, b) 
			return (a.timestamp or 0) > (b.timestamp or 0)
		end)
		
		for _, logEntry in ipairs(GLOBAL_OFNPC_DATA.article.event) do
			local article = vgui.Create("OFArticle", pan1MainPanel)
			article:Dock(TOP)
			article:DockMargin(8 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
			article:SetName(ofTranslate(logEntry.title))
			
			-- 计算发布时间
			local timeDiff = os.time() - (logEntry.timestamp or os.time())
			local timeStr
			if timeDiff < 60 then
				timeStr = ofTranslate("ui.time.just_now")
			elseif timeDiff < 3600 then
				timeStr = string.format(ofTranslate("ui.time.minutes_ago"), math.floor(timeDiff / 60))
			elseif timeDiff < 86400 then
				timeStr = string.format(ofTranslate("ui.time.hours_ago"), math.floor(timeDiff / 3600))
			elseif timeDiff < 604800 then
				timeStr = string.format(ofTranslate("ui.time.days_ago"), math.floor(timeDiff / 86400))
			elseif timeDiff < 2592000 then
				timeStr = string.format(ofTranslate("ui.time.weeks_ago"), math.floor(timeDiff / 604800))
			elseif timeDiff < 31536000 then
				timeStr = string.format(ofTranslate("ui.time.months_ago"), math.floor(timeDiff / 2592000))
			else
				timeStr = string.format(ofTranslate("ui.time.years_ago"), math.floor(timeDiff / 31536000))
			end
			
			article:SetSubtitle(string.format(ofTranslate("ui.time.published_at"), timeStr))
			article:SetText(ofTranslate(logEntry.content))
			if logEntry.image then
				article:SetImage("ofnpcp/article/" .. logEntry.image .. ".png")
			end
		end
	end

	-- AI系统面板 (pan2)
	local pan2 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet(ofTranslate("ui.tab.ai_system"), pan2, "icon16/computer.png")

	local pan2HorizontalDivider = vgui.Create("DHorizontalDivider", pan2)
	pan2HorizontalDivider:Dock(FILL)
	pan2HorizontalDivider:DockMargin(6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale)
	pan2HorizontalDivider:SetLeftWidth(ScrW() / 4)

	local pan2LeftPanel = vgui.Create("OFScrollPanel")
	pan2HorizontalDivider:SetLeft(pan2LeftPanel)

	local pan2RightPanel = vgui.Create("OFScrollPanel")
	pan2HorizontalDivider:SetRight(pan2RightPanel)

	-- 牌组系统面板 (pan3)
	local pan3 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet(ofTranslate("ui.tab.deck_system"), pan3, "icon16/creditcards.png")

	local pan3LeftPanel = vgui.Create("OFScrollPanel", pan3)
	pan3LeftPanel:Dock(LEFT)
	pan3LeftPanel:SetWidth(450 * OFGUI.ScreenScale)

	local pan3RightPanel = vgui.Create("DPanel", pan3)
	pan3RightPanel.Paint = function(self, w, h)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, w, h)
	end
	pan3RightPanel:Dock(FILL)

	-- NPC列表面板 (pan4)
	local pan4 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet(ofTranslate("ui.tab.npclist"), pan4, "icon16/group.png")

	local pan4HorizontalDivider = vgui.Create("DHorizontalDivider", pan4)
	pan4HorizontalDivider:Dock(FILL)
	pan4HorizontalDivider:DockMargin(6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale)
	pan4HorizontalDivider:SetLeftWidth(ScrW()/ 3)
	pan4HorizontalDivider:SetDividerWidth(8 * OFGUI.ScreenScale)

	local pan4LeftPanel = vgui.Create("OFScrollPanel")
	pan4HorizontalDivider:SetLeft(pan4LeftPanel)

	local pan4RightPanel = vgui.Create("OFScrollPanel")
	pan4HorizontalDivider:SetRight(pan4RightPanel)

	-- 个性化设置面板 (pan5)
	local pan5 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet(ofTranslate("ui.personalization.title"), pan5, "icon16/user.png")

	local pan5HorizontalDivider = vgui.Create("DHorizontalDivider", pan5)
	pan5HorizontalDivider:Dock(FILL)
	pan5HorizontalDivider:DockMargin(6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale)
	pan5HorizontalDivider:SetLeftWidth(ScrW() / 4)

	local pan5LeftPanel = vgui.Create("OFScrollPanel")
	pan5HorizontalDivider:SetLeft(pan5LeftPanel)

	local pan5RightPanel = vgui.Create("OFScrollPanel")
	pan5HorizontalDivider:SetRight(pan5RightPanel)

	-- 创建AI设置面板布局
	local aiHorizontalDivider = vgui.Create("DHorizontalDivider", pan2)
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
			temperature = 1,
			max_tokens = 500
		}

		-- 创建设置控件
		local apiUrlEntry = CreateControl(aiRightPanel, "OFTextEntry", {
			SetValue = settings.url,
			SetPlaceholderText = "API URL"
		})

		local apiKeyEntry = CreateControl(aiRightPanel, "OFTextEntry", {
			SetValue = settings.key or "",
			SetPlaceholderText = ofTranslate(provider.name) .. " API"
		})

		local modelComboBox = CreateControl(aiRightPanel, "OFComboBox", {
			SetValue = settings.model or ofTranslate("ui.ai_system.model_select")
		})
		for _, model in ipairs(provider.model) do
			modelComboBox:AddChoice(model)
		end
		if settings.model then
			modelComboBox:SetValue(settings.model)
		else
			modelComboBox:SetValue(provider.model[1])
		end

		local tempSlider = CreateControl(aiRightPanel, "OFNumSlider", {
			SetText = ofTranslate("ui.ai_system.temperature"),
			SetMin = 0,
			SetMax = 2,
			SetDecimals = 1,
			SetValue = settings.temperature
		})

		local maxTokensSlider = CreateControl(aiRightPanel, "OFNumSlider", {
			SetText = ofTranslate("ui.ai_system.max_tokens"),
			SetMin = 100,
			SetMax = 2000,
			SetDecimals = 0,
			SetValue = settings.max_tokens
		})

		-- 保存按钮
		local saveButton = CreateControl(aiRightPanel, "OFButton", {
			SetText = ofTranslate("ui.ai_system.save_settings")
		})
		saveButton.DoClick = function()
			if not file.IsDir("of_npcp", "DATA") then
				file.CreateDir("of_npcp")
			end
			local newSettings = {
				provider = providerKey,
				url = apiUrlEntry:GetValue(),
				key = apiKeyEntry:GetValue(),
				model = modelComboBox:GetSelected(),
				temperature = tonumber(tempSlider:GetValue()) or 1,
				max_tokens = tonumber(maxTokensSlider:GetValue()) or 500
			}
			file.Write("of_npcp/ai_settings.txt", util.TableToJSON(newSettings))
			notification.AddLegacy(ofTranslate("ui.ai_system.save_success"), NOTIFY_GENERIC, 5)
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
			campButton:SetName(ofTranslate("ui.ai_system.system_prompt") .. ofTranslate("camp."..camp))
			campButton:SetText(ofTranslate("prompt."..camp))
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
			SetTitle = ofTranslate(provider.data.name),
			SetDescription = ofTranslate(provider.data.description),
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
	RefreshNPCButtons(pan4LeftPanel, pan4RightPanel)
	RefreshCardButtons(pan3LeftPanel, pan3RightPanel)
	
	-- 添加更新钩子
	hook.Add("RefreshNPCMenu", "UpdateNPCButtonList", function()
		if IsValid(pan4LeftPanel) then
			RefreshNPCButtons(pan4LeftPanel, pan4RightPanel)
		end
	end)
	
	-- 当面板关闭时移除钩子
	frame.OnRemove = function()
		hook.Remove("RefreshNPCMenu", "UpdateNPCButtonList")
	end

	-- 加载默认配音设置
	LoadpersonalizationSettings(pan5LeftPanel)

	if GLOBAL_OFNPC_DATA.article.document then
		table.sort(GLOBAL_OFNPC_DATA.article.document, function(a, b) 
			return (a.timestamp or 0) > (b.timestamp or 0)
		end)
		
		for _, logEntry in ipairs(GLOBAL_OFNPC_DATA.article.document) do
			local article = vgui.Create("OFArticle", pan5RightPanel)
			article:Dock(TOP)
			article:DockMargin(8 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
			article:SetName(ofTranslate(logEntry.title))
			
			-- 计算发布时间
			local timeDiff = os.time() - (logEntry.timestamp or os.time())
			local timeStr
			if timeDiff < 60 then
				timeStr = ofTranslate("ui.time.just_now")
			elseif timeDiff < 3600 then
				timeStr = string.format(ofTranslate("ui.time.minutes_ago"), math.floor(timeDiff / 60))
			elseif timeDiff < 86400 then
				timeStr = string.format(ofTranslate("ui.time.hours_ago"), math.floor(timeDiff / 3600))
			elseif timeDiff < 604800 then
				timeStr = string.format(ofTranslate("ui.time.days_ago"), math.floor(timeDiff / 86400))
			elseif timeDiff < 2592000 then
				timeStr = string.format(ofTranslate("ui.time.weeks_ago"), math.floor(timeDiff / 604800))
			elseif timeDiff < 31536000 then
				timeStr = string.format(ofTranslate("ui.time.months_ago"), math.floor(timeDiff / 2592000))
			else
				timeStr = string.format(ofTranslate("ui.time.years_ago"), math.floor(timeDiff / 31536000))
			end
			
			article:SetSubtitle(string.format(ofTranslate("ui.time.published_at"), timeStr))
			article:SetText(ofTranslate(logEntry.content))
			if logEntry.image then
				article:SetImage("ofnpcp/article/" .. logEntry.image .. ".png")
			end
		end
	end
end

list.Set("DesktopWindows", "ofnpcp", {
    title = "GarryLord",
    icon = "oftoollogo/ofnpcplogo.png",
    init = function()
        AddOFFrame()
    end
})