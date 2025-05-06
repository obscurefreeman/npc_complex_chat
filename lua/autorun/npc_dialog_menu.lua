if SERVER then
    -- 添加服务器端处理玩家对话选择的逻辑
    net.Receive("PlayerDialog", function(len, ply)
        local npc = net.ReadEntity()
        local translatedOption = net.ReadString()
        local optionType = net.ReadString()
        local aidetail = net.BytesLeft() > 0 and net.ReadTable() or {}
        
        if not (IsValid(npc) and IsValid(ply)) then return end
        
        if aidetail and next(aidetail) ~= nil then
            NPCTalkManager:StartDialog(ply, translatedOption, "player", npc, true, aidetail)
        else
            NPCTalkManager:StartDialog(ply, translatedOption, "player", npc, true)
        end

        if optionType and optionType ~= "ai" then
            timer.Simple(0.5, function()
                local npcIdentity = OFNPCS[npc:EntIndex()]
                if npcIdentity then
                    local responsePhrases = GLOBAL_OFNPC_DATA.npcTalks.response[optionType]
                    if responsePhrases and #responsePhrases > 0 then
                        local randomResponse = responsePhrases[math.random(#responsePhrases)]
                        NPCTalkManager:StartDialog(npc, randomResponse, "dialogue", ply, true)
                    else
                        NPCTalkManager:StartDialog(npc, optionType, "dialogue", ply, true)
                    end
                end
            end)
        end
    end)
    net.Receive("NPCAIDialog", function(len, ply)
        local npc = net.ReadEntity()
        local responseContent = net.ReadString()
        local aidetail = net.BytesLeft() > 0 and net.ReadTable() or {}
        if not IsValid(npc) or not IsValid(ply) then return end

        NPCTalkManager:StartDialog(npc, responseContent, "dialogue", ply, true, aidetail)
    end)
end

if CLIENT then

    -- 显示对话选项菜单
    net.Receive("OpenNPCDialogMenu", function()
        local npc = net.ReadEntity()

        local npcs = GetAllNPCsList()
        local npcIdentity = npcs[npc:EntIndex()]

        if not npcIdentity then
            net.Start("NPCIdentityUpdate")
            net.WriteEntity(npc)
            net.SendToServer()
            return
        end
        
        -- 通知服务器对话开始
        net.Start("NPCDialogMenuOpened")
        net.WriteEntity(npc)
        net.SendToServer()
        
        -- 从player_talk.json中获取对话选项
        local dialogOptions = GLOBAL_OFNPC_DATA.playerTalks.option
        -- 获取玩家卡组
        local playerDeck = OFPLAYERS[LocalPlayer():SteamID()] and OFPLAYERS[LocalPlayer():SteamID()].deck or "resistance"
        local deckColor = GLOBAL_OFNPC_DATA.setting.camp_setting[playerDeck].color

        -- 从全局变量获取对话文本
        local playerTalkOptions = {}
        local optionTypes = {} -- 存储每个选项对应的类型
        if GLOBAL_OFNPC_DATA.playerTalks then
            -- 创建一个包含选项类型和顺序的表
            local sortedOptions = {}
            for optionType, data in pairs(dialogOptions) do
                table.insert(sortedOptions, {type = optionType, index = data.index})
            end
            
            -- 按index字段排序
            table.sort(sortedOptions, function(a, b) return a.index < b.index end)
            
            -- 按排序后的顺序获取短语
            for _, option in ipairs(sortedOptions) do
                local phrases = GLOBAL_OFNPC_DATA.playerTalks[option.type]
                if phrases then
                    local randomPhrase = phrases[math.random(#phrases)]
                    table.insert(playerTalkOptions, randomPhrase)
                    optionTypes[randomPhrase] = option.type -- 记录每个短语对应的选项类型
                end
            end
        end

        -- 创建全屏菜单
        local frame = vgui.Create("OFFrame")
        frame:SetSize(ScrW(), ScrH())
        frame:SetPos(0, 0)
        frame:SetNoRounded(true)
        frame:ShowCloseButton(false)
        frame:ShowMaximizeButton(false)
        frame:SetDraggable(false)

        -- 创建布局面板
        local leftPanel = vgui.Create("DPanel", frame)
        leftPanel:Dock(LEFT)
        leftPanel:SetWidth(400 * OFGUI.ScreenScale)
        leftPanel.Paint = function(self, w, h)
            surface.SetDrawColor(0, 0, 0, 0)
            surface.DrawRect(0, 0, w, h)
        end
        local rightPanel = vgui.Create("DPanel", frame)
        rightPanel:Dock(RIGHT)
        rightPanel:SetWidth(400 * OFGUI.ScreenScale)
        rightPanel.Paint = function(self, w, h)
            surface.SetDrawColor(0, 0, 0, 0)
            surface.DrawRect(0, 0, w, h)
        end

        for i=1, 2 do -- 左右两个部分
            local pax = vgui.Create("DPanel", i == 1 and leftPanel or rightPanel) -- 将DPanel放入对应的面板
            pax:Dock(TOP)
            pax:SetHeight(600 * OFGUI.ScreenScale)
            pax:SetMouseInputEnabled( false ) -- 阻止鼠标互动，不然把叉挡着了
            function pax:Paint( w, h ) end -- 隐藏这个DPanel
    
            local mdl = pax:Add( "DModelPanel" )
            mdl:Dock( FILL )
            mdl:SetMouseInputEnabled( false ) -- 禁止玩家触碰这个模型块
            mdl:SetModel( i == 1 and LocalPlayer():GetModel() or npc:GetModel() )
            mdl:SetAnimated( true )
    
            local ent, ply = mdl.Entity, LocalPlayer() -- 这样写可不大好啊
            local head = ent:LookupBone( "ValveBiped.Bip01_Head1" ) -- 检测模型是否有头部
            local cpos = head and ent:GetBonePosition( head ) or ( mdl:GetPos() +mdl:OBBCenter() ) -- 这个在外头只用一次，检测一下头的位置存不存在
            local move = Vector( 24, 0, 0 ) -- 摄像头到瞄准点的偏移量，这个24可以随便改改
    
            mdl:SetFOV( 40 ) -- FOV调个喜欢的
            mdl:SetCamPos( cpos +move ) -- 相机位置
            mdl:SetLookAt( cpos ) -- 相机朝向位置
    
            mdl:SetDirectionalLight( BOX_TOP, Color( 0, 0, 0 ) ) -- 这两个调光我不懂，不过可以稍微调的柔和点
            mdl:SetAmbientLight( Color( 128, 128, 128, 128 ) )
    
            mdl:SetAnimSpeed( 1 ) -- 虽然说后头还是用SetPlaybackRate调的好像不是很需要
            ent:SetAngles( Angle( 0, i == 1 and 15 or -15, 0 ) ) -- 左边朝右30度,右边朝左30度
            local animation = "idle_all_01" -- 默认动画
            if i == 2 then
                animation = npcIdentity.anim
            end
            ent:ResetSequence(animation) -- 左边右边两个动作,按需求调
            ent:SetEyeTarget( i == 1 and cpos + move + Vector( 0, 10, 0 ) or cpos + move + Vector( 0, -10, 0 ) )
    
            if i == 1 then local col = ply:GetPlayerColor() -- 如果是玩家模型可以添上玩家的一些个性化
                if ply:GetSkin() != nil then ent:SetSkin( ply:GetSkin() ) end
                if ply:GetNumBodyGroups() != nil then
                    for i=0, ply:GetNumBodyGroups() -1 do ent:SetBodygroup( i, ply:GetBodygroup( i ) ) end
                end
                for n, m in pairs( ply:GetMaterials() ) do ent:SetSubMaterial( n-1 , m ) end
                ent:SetColor( ply:GetColor() ) ent:SetMaterial( ply:GetMaterial() )
                function ent:GetPlayerColor() -- 玩家颜色
                    return col
                end
            else -- NPC模型设置
                -- 同步皮肤
                if npc:GetSkin() != nil then 
                    ent:SetSkin(npc:GetSkin()) 
                end
                
                -- 同步bodygroups
                if npc:GetNumBodyGroups() != nil then
                    for i = 0, npc:GetNumBodyGroups() - 1 do 
                        ent:SetBodygroup(i, npc:GetBodygroup(i)) 
                    end
                end
            end
    
            function mdl:LayoutEntity( ent )
                if head then -- 这里持续调整摄像头位置矫正，不然位置会有点偏，比如说右侧反抗军会有点往下错位
                    local cpos = ent:GetBonePosition( head )
                    mdl:SetCamPos( cpos +move )
                    mdl:SetLookAt( cpos )
                end
                ent:SetPlaybackRate( mdl:GetAnimSpeed() ) -- 直接填1也行好像
                ent:FrameAdvance()
    
                -- 这边下面是一串我做床写的眨眼代码，需要就留着吧
                local blk = ent:GetFlexIDByName( "blink" ) -- 听说眨眼表情查询是分大小写的
                if !blk then blk = ent:GetFlexIDByName( "Blink" ) end -- 那就一起呗
                if blk then
                    if !ent.NextBlink or ent.NextBlink <= CurTime() then
                        if ent.NextBlink then ent.TimeBlink = CurTime() +0.2 end -- 闭眼到睁眼一共0.2秒
                        ent.NextBlink = CurTime() +math.Rand( 1.5, 4.5 ) -- 随机化下一次眨眼时间
                    end
                    if ent.TimeBlink then
                        local per = math.Clamp( ( ent.TimeBlink -CurTime() )/0.2, 0, 1 )
                        if per >= 0.5 then per = 1 -( per -0.5 )/0.5 else per = per*2 end -- 闭眼0.1睁眼0.1
                        ent:SetFlexWeight( blk, per )
                    end
                end
                
                -- 获取鼠标位置
                local mouseX, mouseY = gui.MousePos()
                local modelX, modelY = mdl:LocalToScreen(0, 0)
                local modelW, modelH = mdl:GetSize()
                
                -- 判断鼠标是否在模型显示器内
                if mouseX >= modelX and mouseX <= modelX + modelW and
                   mouseY >= modelY and mouseY <= modelY + modelH then
                   
                    -- 计算相对鼠标位置
                    local relX = (mouseX - modelX) / modelW
                    local relY = (mouseY - modelY) / modelH
                    
                    -- 根据模型朝向调整视线范围
                    local eyeOffsetX = Lerp(relX, -15, 15)
                    local eyeOffsetY = - Lerp(relY, -30, 30)
                    
                    -- 设置眼睛目标
                    ent:SetEyeTarget(cpos + move + Vector(eyeOffsetY, eyeOffsetX, 0))
                else
                    -- 鼠标不在模型内时保持原有随机视线移动
                    if !ent.NextEyeMove or ent.NextEyeMove <= CurTime() then
                        if ent.NextEyeMove then
                            local randomOffset = Vector(
                                math.Rand(-10, 10),
                                i == 1 and math.Rand(5, 15) or math.Rand(-15, -5),
                                0
                            )
                            ent.CurrentEyeTarget = cpos + move + randomOffset
                        end
                        ent.NextEyeMove = CurTime() + math.Rand(2, 4)
                    end

                    if ent.CurrentEyeTarget then
                        -- 设置眼睛目标
                        ent:SetEyeTarget(ent.CurrentEyeTarget)
                    else
                        -- 初始化眼睛目标
                        ent.CurrentEyeTarget = cpos + move + Vector(0, i == 1 and 10 or -10, 0)
                        ent:SetEyeTarget(ent.CurrentEyeTarget)
                    end
                end
            end
        end

        -- 下方中间区域存放对话选项
        local scrollPanel = vgui.Create("OFScrollPanel", frame)
        scrollPanel:SetHeight(300 * OFGUI.ScreenScale)
        scrollPanel:Dock(BOTTOM)

        local messagePanel = vgui.Create("OFScrollPanel", frame)
        messagePanel:Dock(FILL)

        local function TranslateDialogHistory(ent, updatedData, ai)
            if ent == npc then
                npcIdentity = updatedData

                local translatedDialogs = {}
                local speakerName
                local promptcontent = ofTranslate(npcIdentity.prompt)
                promptcontent = ReplacePlaceholders(promptcontent, npcIdentity)
                local aiDialogs = { { role = "system", content = promptcontent } }
                for _, dialog in ipairs(updatedData.dialogHistory) do
                    local translatedText = ofTranslate(dialog.text)
                    if dialog.speakerType == "npc" then
                        local npcData = GetAllNPCsList()[dialog.speaker]
                        local npcName
                        if npcData.name == npcData.gamename then
                            npcName = language.GetPhrase(npcData.gamename)
                        else
                            npcName = ofTranslate(npcData.name) .. " “" .. ofTranslate(npcData.nickname) .. "”"
                        end
                        speakerName = npcData and (npcName) or "NPC"
                        translatedText = translatedText:gsub("/player/", dialog.target)
                    else
                        speakerName = dialog.speaker
                    end
                    translatedText = ReplacePlaceholders(translatedText, npcIdentity)

                    -- 定义对话类型与提示信息的映射表
                    local dialogFootnotes = {
                        ["playerchat.greeting"] = ofTranslate("ui.dialog.ai_chat_notice"),
                        ["response.greeting"] = ofTranslate("ui.dialog.ai_chat_warning"), 
                        ["playerchat.negotiate"] = ofTranslate("ui.dialog.negotiate_notice"),
                        ["response.negotiate"] = ofTranslate("ui.dialog.negotiate_warning"),
                        ["playerchat.trade"] = ofTranslate("ui.dialog.trade_notice"),
                        ["response.trade"] = ofTranslate("ui.dialog.trade_warning")
                    }

                    -- 初始化脚注文本
                    local footnoteText

                    -- 遍历映射表设置对应的脚注
                    if dialog.text then
                        for pattern, footnote in pairs(dialogFootnotes) do
                            if string.find(dialog.text, pattern) then
                                footnoteText = footnote
                                break
                            end
                        end
                    end

                    if dialog.aidetail and istable(dialog.aidetail) then
                        if dialog.speakerType == "npc" then
                            footnoteText = string.format(ofTranslate("ui.dialog.footnote_npc"),
                            dialog.aidetail.model or ofTranslate("ui.dialog.unknown"),
                            dialog.aidetail.created or ofTranslate("ui.dialog.unknown"),
                            dialog.aidetail.usage and dialog.aidetail.usage.total_tokens or 0)
                        else
                            footnoteText = string.format(ofTranslate("ui.dialog.footnote_player"),
                            dialog.aidetail.model or ofTranslate("ui.dialog.unknown"),
                            dialog.aidetail.provider or ofTranslate("ui.dialog.unknown"))
                        end
                    end

                    local translatedDialogsInfo = {
                        speaker = speakerName,
                        speakerType = dialog.speakerType,
                        target = dialog.target,
                        text = translatedText,
                        time = dialog.time,
                        color = dialog.color
                    }

                    -- 如果有推理内容则记录
                    if dialog.aidetail and dialog.aidetail.choices and dialog.aidetail.choices[1] and dialog.aidetail.choices[1].message and dialog.aidetail.choices[1].message.reasoning_content then
                        translatedDialogsInfo.reasoning = dialog.aidetail.choices[1].message.reasoning_content
                    end

                    if footnoteText then
                        translatedDialogsInfo.footnoteText = footnoteText
                    end

                    table.insert(translatedDialogs, translatedDialogsInfo)

                    -- 只有在dialog.aidetail存在时才放入aiDialogs
                    if dialog.aidetail then
                        table.insert(aiDialogs, {
                            role = dialog.speakerType == "npc" and "assistant" or "user",
                            content = translatedText
                        })
                    end
                end
                if ai then
                    return aiDialogs
                else
                    return translatedDialogs
                end
            end
        end

        local function UpdateDialogHistory(ent, updatedData)
            if ent == npc then
                messagePanel:Clear()
                
                -- 调用TranslateDialogHistory函数
                local translatedDialogs = TranslateDialogHistory(ent, updatedData, false)
                
                -- 显示翻译后的对话
                for _, dialog in ipairs(translatedDialogs) do
                    local message = vgui.Create("OFMessage", messagePanel)
                    message:SetHeight(80 * OFGUI.ScreenScale)
                    message:Dock(TOP)
                    message:DockMargin(4, 4, 4, 4)
                    
                    -- 设置消息颜色
                    local messageColor = dialog.color
                    message:SetColor(messageColor)

                    if dialog.footnoteText then
                        message:SetFootnote(dialog.footnoteText)
                    end
                    message:SetName(dialog.speaker or ofTranslate("ui.dialog.unknown"))
                    message:SetText(dialog.text or "")
                end
            end
        end

        hook.Add("OnNPCIdentityUpdated", "UpdateDialogHistory_"..npc:EntIndex(), UpdateDialogHistory)

        local playercardPanel = vgui.Create("OFScrollPanel", leftPanel)
        playercardPanel:Dock(FILL)
        playercardPanel:DockMargin(8 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 0, 4 * OFGUI.ScreenScale)

        -- 在 playercardPanel 中显示玩家卡组
        if playerDeck then
            if not GLOBAL_OFNPC_DATA.setting.camp_setting[playerDeck] then return end

            -- 获取该牌组的卡牌
            local cards = GLOBAL_OFNPC_DATA.cards[playerDeck] or {}
            local generalCards = GLOBAL_OFNPC_DATA.cards.general or {}

            -- 对卡牌进行排序
            local sortedCards = {}
            local function addCards(cardTable, cardType)
                for cardKey, cardData in pairs(cardTable) do
                    table.insert(sortedCards, {key = cardKey, data = cardData})
                end
            end
            addCards(cards, playerDeck)
            addCards(generalCards, "general")
            table.sort(sortedCards, function(a, b) return a.data.cost < b.data.cost end)

            -- 列出该牌组的所有卡牌
            for _, cardInfo in ipairs(sortedCards) do
                local cardButton = vgui.Create("OFAdvancedButton", playercardPanel)
                cardButton:Dock(TOP)
                cardButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                cardButton:SetTall(80 * OFGUI.ScreenScale)
                cardButton:SetTitle(ofTranslate(cardInfo.data.name))
                cardButton:SetDescription(ReplacePlaceholders(ofTranslate(cardInfo.data.d[math.random(#cardInfo.data.d)]), npcIdentity))
                cardButton:SetIcon("ofnpcp/cards/preview/" .. cardInfo.key .. ".png")
                cardButton:SetCardIcon("ofnpcp/cards/large/" .. cardInfo.key .. ".png")
            end
        end

        local npccardPanel = vgui.Create("OFScrollPanel", rightPanel)
        npccardPanel:Dock(FILL)
        npccardPanel:DockMargin(0, 4 * OFGUI.ScreenScale, 8 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)

        -- 增加了npc按钮

        local npcName
		if npcIdentity.name == npcIdentity.gamename then
			npcName = language.GetPhrase(npcIdentity.gamename)
		else
			npcName = ofTranslate(npcIdentity.name) .. " “" .. ofTranslate(npcIdentity.nickname) .. "”"
		end

        local npcButton = vgui.Create("OFNPCButton", npccardPanel)
		npcButton:Dock(TOP)
		npcButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
		npcButton:SetTall(80 * OFGUI.ScreenScale)
		npcButton:SetModel(npcIdentity.model or "models/error.mdl")
		npcButton:SetTitle(npcName)

        local description = ""
		if npcIdentity.rank and npcIdentity.job and npcIdentity.specialization and npcIdentity.camp then
			npcButton:SetBadge("ofnpcp/usrankicons/rank_".. npcIdentity.rank .. ".png")
			description =  ofTranslate(GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp].name) .. " " .. ofTranslate("rank.".. npcIdentity.rank) .. " - " .. ofTranslate(npcIdentity.specialization)
            npcButton:SetHoveredColor(GLOBAL_OFNPC_DATA.setting.camp_setting[npcIdentity.camp].color)
		elseif npcIdentity.gamename then
			description = npcIdentity.gamename
		end
		npcButton:SetDescription(description)

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

        CreateSkillButton(npccardPanel, npcIdentity.tag_ability, Color(100, 255, 100))
        CreateSkillButton(npccardPanel, npcIdentity.tag_trade, Color(255, 200, 100))
        CreateSkillButton(npccardPanel, npcIdentity.tag_social, Color(100, 200, 255))

		if npcIdentity.comments then
            local commentLabel = vgui.Create("OFTextLabel", npccardPanel)
            commentLabel:Dock(TOP)
            commentLabel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
            commentLabel:SetText(ofTranslate("ui.npclist.comment"))
            for _, commentData in ipairs(npcIdentity.comments) do
                local commentMessage = vgui.Create("OFMessage", npccardPanel)
                commentMessage:Dock(TOP)
                commentMessage:SetHeight(80 * OFGUI.ScreenScale)
                commentMessage:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                commentMessage:SetName(commentData.player)
                commentMessage:SetText(commentData.comment)
				commentMessage:SetColor(commentData.color)
            end
        end

        for _, option in ipairs(playerTalkOptions) do
            local translatedOption = ReplacePlaceholders(ofTranslate(option), npcIdentity)  -- 使用新函数替换

            -- 创建按钮并添加到ScrollPanel
            local button = vgui.Create("OFChatButton", scrollPanel)
            button:SetChatText(translatedOption)
            button:SetTitle(ofTranslate("ui.dialog." .. optionTypes[option]))
            button:Dock(TOP)
            button:DockMargin(4, 4, 4, 4)
            button:SetIcon("ofnpcp/chaticons/preview/" .. optionTypes[option] .. ".png")
            button:SetCardIcon("ofnpcp/chaticons/large/" .. optionTypes[option] .. ".png")
            button:SetTall(50 * OFGUI.ScreenScale)

            -- 获取选项类型对应的颜色
            local optionColor = dialogOptions[optionTypes[option]].color
            button:SetHoveredColor(Color(optionColor.r, optionColor.g, optionColor.b))

            -- 处理按钮点击事件
            button.DoClick = function()
                if optionTypes[option] == "greeting" then
                    -- 清空面板并创建新的文本输入框
                    local function CreateChatInput()
                        scrollPanel:Clear()
                        
                        local textEntry = vgui.Create("OFTextEntry", scrollPanel)
                        textEntry:Dock(TOP)
                        textEntry:DockMargin(4, 4, 4, 4)
                        textEntry:SetFont("ofgui_huge")
                        textEntry:SetTall(100 * OFGUI.ScreenScale)

                        local randomLeave = GLOBAL_OFNPC_DATA.playerTalks.leave[math.random(#GLOBAL_OFNPC_DATA.playerTalks.leave)]
                        local translatedOption = ReplacePlaceholders(ofTranslate(randomLeave), npcIdentity)

                        local button = vgui.Create("OFChatButton", scrollPanel)
                        button:SetChatText(translatedOption)
                        button:SetTitle(ofTranslate("ui.dialog.leave"))
                        button:Dock(TOP)
                        button:DockMargin(4, 4, 4, 4)
                        button:SetIcon("ofnpcp/chaticons/preview/leave.png")
                        button:SetCardIcon("ofnpcp/chaticons/large/leave.png")
                        button:SetTall(50 * OFGUI.ScreenScale)

                        local optionColor = dialogOptions["leave"].color
                        button:SetHoveredColor(Color(optionColor.r, optionColor.g, optionColor.b))

                        -- 添加点击事件关闭frame
                        button.DoClick = function()
                            if IsValid(frame) then
                                frame:Close()
                            end
                        end

                        -- 处理用户输入
                        textEntry.OnEnter = function(self)
                            local inputText = self:GetValue()
                            if inputText and inputText ~= "" then
                                -- 准备AI对话数据
                                local aiDialogs = TranslateDialogHistory(npc, npcIdentity, true)
                                table.insert(aiDialogs, {
                                    role = "user",
                                    content = inputText
                                })

                                -- 读取AI设置
                                local aiSettings = util.JSONToTable(file.Read("of_npcp/ai_settings.txt", "DATA") or "{}")
                                local aidetail = aiSettings and {
                                    model = aiSettings.model,
                                    provider = aiSettings.provider
                                } or {}

                                -- 发送网络消息
                                net.Start("PlayerDialog")
                                    net.WriteEntity(npc)
                                    net.WriteString(inputText)
                                    net.WriteString("ai")
                                    net.WriteTable(aidetail)
                                net.SendToServer()
                                
                                -- 处理AI对话请求
                                SendAIDialogRequest(npc, aiDialogs)

                                -- 重置输入框
                                CreateChatInput()
                            end
                        end
                    end

                    -- 初始化聊天输入框
                    CreateChatInput()
                elseif optionTypes[option] == "negotiate" then
                    -- 清空面板
                    scrollPanel:Clear()
                    
                    -- 获取所有可用卡牌
                    local function GetAllCards()
                        local cards = {}
                        -- 添加阵营专属卡牌
                        for cardKey, cardData in pairs(GLOBAL_OFNPC_DATA.cards[playerDeck] or {}) do
                            table.insert(cards, {key = cardKey, data = cardData})
                        end
                        -- 添加通用卡牌
                        for cardKey, cardData in pairs(GLOBAL_OFNPC_DATA.cards.general or {}) do
                            table.insert(cards, {key = cardKey, data = cardData})
                        end
                        return cards
                    end

                    -- 随机选择卡牌
                    local function SelectRandomCards(cardList, count)
                        local selected = {}
                        while #selected < count and #cardList > 0 do
                            table.insert(selected, table.remove(cardList, math.random(#cardList)))
                        end
                        return selected
                    end

                    -- 创建卡牌按钮
                    local function CreateNegotiateButton(cardInfo)
                        -- 随机选择对话内容
                        local playerText = ReplacePlaceholders(ofTranslate(cardInfo.data.d[math.random(#cardInfo.data.d)]), npcIdentity)
                        local npcText = ofTranslate(cardInfo.data.a[math.random(#cardInfo.data.a)])
                        
                        -- 创建按钮
                        local button = vgui.Create("OFChatButton", scrollPanel)
                        button:SetChatText(playerText)
                        button:SetTitle(ofTranslate(cardInfo.data.name))
                        button:Dock(TOP)
                        button:DockMargin(4, 4, 4, 4)
                        button:SetIcon("ofnpcp/cards/preview/" .. cardInfo.key .. ".png")
                        button:SetCardIcon("ofnpcp/cards/large/" .. cardInfo.key .. ".png")
                        button:SetHoveredColor(deckColor)
                        button:SetTall(50 * OFGUI.ScreenScale)

                        -- 处理点击事件
                        button.DoClick = function()
                            -- 发送对话请求
                            net.Start("PlayerDialog")
                                net.WriteEntity(npc)
                                net.WriteString(playerText)
                                net.WriteString(npcText)
                                net.WriteTable({})
                            net.SendToServer()

                            -- 刷新卡牌
                            ShowRandomCards()
                        end
                    end

                    -- 显示随机卡牌
                    function ShowRandomCards()
                        scrollPanel:Clear()
                        local cards = SelectRandomCards(GetAllCards(), 3)
                        for _, card in ipairs(cards) do
                            CreateNegotiateButton(card)
                        end

                        local randomLeave = GLOBAL_OFNPC_DATA.playerTalks.leave[math.random(#GLOBAL_OFNPC_DATA.playerTalks.leave)]
                        local translatedOption = ReplacePlaceholders(ofTranslate(randomLeave), npcIdentity)

                        local leavebutton = vgui.Create("OFChatButton", scrollPanel)
                        leavebutton:SetChatText(translatedOption)
                        leavebutton:SetTitle(ofTranslate("ui.dialog.leave"))
                        leavebutton:Dock(TOP)
                        leavebutton:DockMargin(4, 4, 4, 4)
                        leavebutton:SetIcon("ofnpcp/chaticons/preview/leave.png")
                        leavebutton:SetCardIcon("ofnpcp/chaticons/large/leave.png")
                        leavebutton:SetTall(50 * OFGUI.ScreenScale)

                        local optionColor = dialogOptions["leave"].color
                        leavebutton:SetHoveredColor(Color(optionColor.r, optionColor.g, optionColor.b))

                        -- 添加点击事件关闭frame
                        leavebutton.DoClick = function()
                            if IsValid(frame) then
                                frame:Close()
                            end
                        end
                    end

                    -- 初始化显示3张随机卡牌
                    ShowRandomCards()
                elseif optionTypes[option] == "leave" then
                    frame:Close()
                end

                net.Start("PlayerDialog")
                net.WriteEntity(npc)
                net.WriteString(option)
                net.WriteString(optionTypes[option])
                net.WriteTable({})
                net.SendToServer()
            end
        end

        -- 在关闭菜单时通知服务器对话结束
        frame.OnClose = function()
            net.Start("NPCDialogMenuClosed")
            net.WriteEntity(npc)
            net.SendToServer()
            hook.Remove("OnNPCIdentityUpdated", "UpdateDialogHistory_"..npc:EntIndex())
            hook.Remove("EntityRemoved", "CloseDialogOnNPCDeath_"..npc:EntIndex())  -- 移除hook
        end

        -- 添加NPC死亡检测hook
        hook.Add("EntityRemoved", "CloseDialogOnNPCDeath_"..npc:EntIndex(), function(ent)
            if ent == npc then
                frame:Close()
            end
        end)
    end)

    function SendAIDialogRequest(npc, aiDialogs)
        -- 读取本地AI设置
        local aiSettings = file.Read("of_npcp/ai_settings.txt", "DATA")
        
        -- 添加检查
        if not aiSettings or aiSettings == "" or aiSettings == nil then
            net.Start("NPCAIDialog")
            net.WriteEntity(npc)
            net.WriteString(ofTranslate("ui.dialog.no_ai_settings"))
            net.WriteTable({})
            net.SendToServer()
        end
        aiSettings = util.JSONToTable(aiSettings)
        if aiSettings then

            local requiredFields = {"max_tokens", "temperature", "provider", "model", "key", "url"}
            local isValid = true
            for _, field in ipairs(requiredFields) do
                if not aiSettings[field] then
                    isValid = false
                    break
                end
            end
            
            if not isValid then
                -- 如果缺少必要字段
                net.Start("NPCAIDialog")
                net.WriteEntity(npc)
                net.WriteString(ofTranslate("ui.dialog.no_ai_settings"))
                net.WriteTable({})
                net.SendToServer()
                return
            end

            local function correctFloatToInt(jsonString)
                return string.gsub(jsonString, '(%d+)%.0', '%1')
            end
            
            -- 在客户端处理HTTP请求
            local requestBody = {
                model = aiSettings.model,
                messages = aiDialogs,
                max_tokens = aiSettings.max_tokens or 500,
                temperature = aiSettings.temperature or 1
            }
            
            HTTP({
                url = aiSettings.url,
                type = "application/json",
                method = "post",
                headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer " .. aiSettings.key
                },
                body = correctFloatToInt(util.TableToJSON(requestBody)),
                
                success = function(code, body, headers)
                    local response = util.JSONToTable(body)
                    -- 重要debug代码，如果获得了回应，就会立即将上下文和回复打在控制台里
                    if aiDialogs and response then
                        PrintTable(aiDialogs)
                        PrintTable(response)
                    end
                    
                    if response and response.choices and #response.choices > 0 and response.choices[1].message then
                        local responseContent = response.choices[1].message.content
                        
                        -- 将AI回复发送到服务器
                        net.Start("NPCAIDialog")
                        net.WriteEntity(npc)
                        net.WriteString(responseContent)
                        net.WriteTable(response or {})
                        net.SendToServer()
                    elseif response and response.error and response.error.message then
                        -- 成功了，但报错
                        net.Start("NPCAIDialog")
                        net.WriteEntity(npc)
                        net.WriteString(ofTranslate("ui.dialog.error") .. response.error.message)
                        net.WriteTable({})
                        net.SendToServer()
                    else
                        -- 成功了，但是回答格式是错误的
                        net.Start("NPCAIDialog")
                        net.WriteEntity(npc)
                        net.WriteString(ofTranslate("ui.dialog.invalid_response"))
                        net.WriteTable({})
                        net.SendToServer()
                    end
                end,
                
                failed = function(err)
                    -- 没有成功，有可能api填错了，也有可能没连上网
                    net.Start("NPCAIDialog")
                    net.WriteEntity(npc)
                    net.WriteString(ofTranslate("ui.dialog.http_error") .. (err or ofTranslate("ui.dialog.unknown")))
                    net.WriteTable({})
                    net.SendToServer()
                end
            })
        else
            -- 如果没有找到AI设置文件
            net.Start("NPCAIDialog")
            net.WriteEntity(npc)
            net.WriteString(ofTranslate("ui.dialog.no_ai_settings"))
            net.WriteTable({})
            net.SendToServer()
        end
    end
end