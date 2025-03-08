if SERVER then
    -- 添加服务器端处理玩家对话选择的逻辑
    net.Receive("PlayerDialog", function(len, ply)
        local npc = net.ReadEntity()
        local translatedOption = net.ReadString()
        local optionType = net.ReadString()
        local aidetail = net.ReadTable()
        
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
                    end
                end
            end)
        end
    end)
    net.Receive("NPCAIDialog", function(len, ply)
        local npc = net.ReadEntity()
        local responseContent = net.ReadString()
        local aidetail = net.ReadTable()
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
        
        local dialogOptions = {
            "greeting",
            "negotiate",
            "trade",
            "leave"
        }

        -- 从全局变量获取对话文本
        local playerTalkOptions = {}
        local optionTypes = {} -- 存储每个选项对应的类型
        if GLOBAL_OFNPC_DATA.playerTalks then
            for i, optionType in ipairs(dialogOptions) do
                local phrases = GLOBAL_OFNPC_DATA.playerTalks[optionType]
                if phrases then
                    local randomPhrase = phrases[math.random(#phrases)]
                    table.insert(playerTalkOptions, randomPhrase)
                    optionTypes[randomPhrase] = optionType -- 记录每个短语对应的选项类型
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
                -- 要嘴巴阿巴阿巴的话也是SetFlexWeight，但是市民好说玩家模型的张嘴表情号不一样就不好弄了，反正跟上面这段思路是差不多的
                
                -- 视线移动控制
                if !ent.NextEyeMove or ent.NextEyeMove <= CurTime() then
                    if ent.NextEyeMove then
                        -- 设置新的目标位置
                        local randomOffset = Vector(
                            math.Rand(-10, 10),
                            i == 1 and math.Rand(5, 15) or math.Rand(-15, -5),
                            0  -- 固定Z轴为0，保持视线高度不变
                        )
                        ent.CurrentEyeTarget = cpos + move + randomOffset
                    end
                    ent.NextEyeMove = CurTime() + math.Rand(2, 4)
                end

                -- 设置眼睛目标
                if ent.CurrentEyeTarget then
                    ent:SetEyeTarget(ent.CurrentEyeTarget)
                else
                    -- 初始化眼睛目标
                    ent.CurrentEyeTarget = cpos + move + Vector(0, i == 1 and 10 or -10, 0)
                    ent:SetEyeTarget(ent.CurrentEyeTarget)
                end
            end
        end

        -- 下方中间区域存放对话选项
        local scrollPanel = vgui.Create("OFScrollPanel", frame)
        scrollPanel:SetHeight(300 * OFGUI.ScreenScale)
        scrollPanel:Dock(BOTTOM)

        local messagePanel = vgui.Create("OFScrollPanel", frame)
        messagePanel:Dock(FILL)

        -- 添加对话历史更新监听
        local playerDeck = OFPLAYERS[LocalPlayer():SteamID()] and OFPLAYERS[LocalPlayer():SteamID()].deck or "resistance"
        local deckColor = GLOBAL_OFNPC_DATA.cards.info[playerDeck].color
        local npcColor = GLOBAL_OFNPC_DATA.cards.info[npcIdentity.camp].color

        local function TranslateDialogHistory(ent, updatedData, ai)
            if ent == npc then
                npcIdentity = updatedData

                local translatedDialogs = {}
                local speakerName
                local promptcontent = L("prompt." .. tostring(npcIdentity.camp))
                if npcIdentity.type == "maincharacter" then
                    promptcontent = L("prompt.maincharacter")
                end
                local npcName = L(npcIdentity.name)
                if npcIdentity.name == npcIdentity.gamename then
                    npcName = language.GetPhrase(npcIdentity.gamename)
                end
                promptcontent = promptcontent:gsub("/name/", npcName)
                promptcontent = promptcontent:gsub("/nickname/", L(npcIdentity.nickname))
                promptcontent = promptcontent:gsub("/job/", L(npcIdentity.job))
                promptcontent = promptcontent:gsub("/camp/", L("camp."..tostring(npcIdentity.camp)))
                promptcontent = promptcontent:gsub("/map/", game.GetMap())
                local aiDialogs = { { role = "system", content = promptcontent } }
                for _, dialog in ipairs(updatedData.dialogHistory) do
                    local translatedText = L(dialog.text)
                    if dialog.speakerType == "npc" then
                        local npcData = GetAllNPCsList()[dialog.speaker]
                        local npcName
                        if npcData.name == npcData.gamename then
                            npcName = language.GetPhrase(npcData.gamename)
                        else
                            npcName = L(npcData.name) .. " “" .. L(npcData.nickname) .. "”"
                        end
                        speakerName = npcData and (npcName) or "NPC"
                        translatedText = translatedText:gsub("/player/", dialog.target)
                    else
                        speakerName = dialog.speaker
                    end
                    translatedText = translatedText:gsub("/map/", game.GetMap())
                    translatedText = translatedText:gsub("/name/", npcName)
                    translatedText = translatedText:gsub("/nickname/", L(npcIdentity.nickname))

                    -- 定义对话类型与提示信息的映射表
                    local dialogFootnotes = {
                        ["playerchat.greeting"] = "正在开启AI聊天。请注意，每个NPC都具有独特的身份背景和性格特征，并能访问部分游戏数据。在多人游戏中，当多名玩家同时与同一NPC互动时，系统将自动隔离对话上下文，确保每位玩家获得独立的交互体验，从而优化资源利用。程序性对话不会被AI读取，当您再次与该NPC互动时，可以继续之前的对话内容",
                        ["response.greeting"] = "AI聊天已开启。在多人游戏环境中，每位玩家需独立配置API密钥，相关数据将安全存储于本地设备，不会上传至服务器。为保障数据安全，建议避免在不可信的服务器环境中使用此功能，以防API密钥泄露风险。", 
                        ["playerchat.negotiate"] = "正在开启协商。",
                        ["response.negotiate"] = "协商模式正在开发中，敬请期待。",
                        ["playerchat.trade"] = "正在开启交易。",
                        ["response.trade"] = "交易功能正在开发中，敬请期待。"
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
                            footnoteText = string.format("模型：%s | 响应时间：%s | 消耗tokens：%d",
                                dialog.aidetail.model or "Unknown",
                                dialog.aidetail.created or "Unknown",
                                dialog.aidetail.usage and dialog.aidetail.usage.total_tokens or 0)
                        else
                            footnoteText = string.format("模型：%s | 服务平台：%s",
                            dialog.aidetail.model or "Unknown",
                            dialog.aidetail.provider or "Unknown")
                        end
                    end

                    local translatedDialogsInfo = {
                        speaker = speakerName,
                        speakerType = dialog.speakerType,
                        target = dialog.target,
                        text = translatedText,
                        time = dialog.time
                    }

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
                    local messageColor = dialog.speakerType == "npc" and npcColor or deckColor
                    message:SetColor(messageColor)

                    if dialog.footnoteText then
                        message:SetFootnote(dialog.footnoteText)
                    end
                    message:SetName(dialog.speaker or "Unknown")
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
            if not GLOBAL_OFNPC_DATA.cards.info[playerDeck] then return end

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
                local cardButton = vgui.Create("OFSkillButton", playercardPanel)
                cardButton:Dock(TOP)
                cardButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                cardButton:SetTall(80 * OFGUI.ScreenScale)
                cardButton:SetTitle(cardInfo.data.name)
                cardButton:SetDescription(cardInfo.data.d[math.random(#cardInfo.data.d)])
                cardButton:SetIcon("ofnpcp/cards/preview/" .. cardInfo.key .. ".png")
                cardButton:SetCardIcon("ofnpcp/cards/large/" .. cardInfo.key .. ".png")
            end
        end

        local npccardPanel = vgui.Create("OFScrollPanel", rightPanel)
        npccardPanel:Dock(FILL)
        npccardPanel:DockMargin(0, 4 * OFGUI.ScreenScale, 8 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)

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

        CreateSkillButton(npccardPanel, npcIdentity.tag_ability, npcIdentity.tag_ability_desc, npcIdentity.tag_ability, Color(100, 255, 100))
        CreateSkillButton(npccardPanel, npcIdentity.tag_trade, npcIdentity.tag_trade_desc, npcIdentity.tag_trade, Color(255, 200, 100))
        CreateSkillButton(npccardPanel, npcIdentity.tag_social, npcIdentity.tag_social_desc, npcIdentity.tag_social, Color(100, 200, 255))

        if npcIdentity.comments then
            for _, commentData in ipairs(npcIdentity.comments) do
                local commentLabel = vgui.Create("OFNPCButton", npccardPanel)
                commentLabel:Dock(TOP)
                commentLabel:SetTall(80 * OFGUI.ScreenScale)
                commentLabel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                commentLabel:SetModel(commentData.model or "models/error.mdl")
                commentLabel:SetTitle(commentData.player)
                commentLabel:SetDescription(commentData.comment)
            end
        end

        for _, option in ipairs(playerTalkOptions) do
            local npcName = L(npcIdentity.name)
            if npcIdentity.name == npcIdentity.gamename then
                npcName = language.GetPhrase(npcIdentity.gamename)
            end
            local translatedOption = L(option):gsub("/name/", npcName)

            -- 创建按钮并添加到ScrollPanel
            local button = vgui.Create("OFChatButton", scrollPanel)
            button:SetChatText(translatedOption)
            button:Dock(TOP)
            button:DockMargin(4, 4, 4, 4)
            button:SetIcon("ofnpcp/chaticons/chat.png")
            button:SetHoveredColor(Color(100, 255, 100))
            button:SetTall(50 * OFGUI.ScreenScale) -- 设置按钮的高度

            -- 处理按钮点击事件
            button.DoClick = function()
                if optionTypes[option] == "greeting" then
                    -- 清空scrollPanel
                    scrollPanel:Clear()
                    
                    -- 创建文本输入框
                    local textEntry = vgui.Create("OFTextEntry", scrollPanel)
                    textEntry:Dock(TOP)
                    textEntry:DockMargin(4, 4, 4, 4)
                    textEntry:SetFont("ofgui_huge")
                    textEntry:SetTall(100 * OFGUI.ScreenScale)

                    -- 处理回车事件
                    textEntry.OnEnter = function(self)
                        local inputText = self:GetValue()
                        if inputText and inputText ~= "" then

                            local aiDialogs = TranslateDialogHistory(npc, npcIdentity, true)

                            table.insert(aiDialogs, {
                                role = "user",
                                content = inputText
                            })

                            local aiSettings = util.JSONToTable(file.Read("of_npcp/ai_settings.txt", "DATA") or "{}")
                            local aidetail = aiSettings and {
                                model = aiSettings.model,
                                provider = aiSettings.provider
                            } or {}

                            net.Start("PlayerDialog")
                            net.WriteEntity(npc)
                            net.WriteString(inputText)
                            net.WriteString("ai")
                            net.WriteTable(aidetail)
                            net.SendToServer()
                            
                            -- 调用新的函数处理AI对话请求
                            SendAIDialogRequest(npc, aiDialogs)

                            -- 重置父级面板
                            local parent = self:GetParent()
                            parent:Clear()

                            -- 重新创建文本输入框
                            local newTextEntry = vgui.Create("OFTextEntry", parent)
                            newTextEntry:Dock(TOP)
                            newTextEntry:DockMargin(4, 4, 4, 4)
                            newTextEntry:SetFont("ofgui_huge")
                            newTextEntry:SetTall(100 * OFGUI.ScreenScale)
                            newTextEntry.OnEnter = self.OnEnter  -- 保持相同的事件处理
                        end
                    end
                elseif optionTypes[option] == "leave" then
                    frame:Close()
                end

                net.Start("PlayerDialog")
                net.WriteEntity(npc)
                net.WriteString(option)
                net.WriteString(optionTypes[option])
                net.SendToServer()
            end
        end

        -- 在关闭菜单时通知服务器对话结束
        frame.OnClose = function()
            net.Start("NPCDialogMenuClosed")
            net.WriteEntity(npc)
            net.SendToServer()
            hook.Remove("OnNPCIdentityUpdated", "UpdateDialogHistory_"..npc:EntIndex())
        end
    end)

    function SendAIDialogRequest(npc, aiDialogs)
        -- 读取本地AI设置
        local aiSettings = file.Read("of_npcp/ai_settings.txt", "DATA")
        if aiSettings then
            aiSettings = util.JSONToTable(aiSettings)

            local function correctFloatToInt(jsonString)
                return string.gsub(jsonString, '(%d+)%.0', '%1')
            end
            
            -- 在客户端处理HTTP请求
            local requestBody = {
                model = aiSettings.model,
                messages = aiDialogs,
                max_tokens = aiSettings.max_tokens or 500,
                temperature = aiSettings.temperature or 0.7
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
                    -- 重要debug代码
                    PrintTable(aiDialogs)
                    PrintTable(response)
                    
                    if response and response.choices and #response.choices > 0 and response.choices[1].message then
                        local responseContent = response.choices[1].message.content
                        
                        -- 将AI回复发送到服务器
                        net.Start("NPCAIDialog")
                        net.WriteEntity(npc)
                        net.WriteString(responseContent)
                        net.WriteTable(response)
                        net.SendToServer()
                    else
                        -- 处理无效的响应
                        net.Start("NPCAIDialog")
                        net.WriteEntity(npc)
                        net.WriteString("Invalid AI response: Missing required fields.")
                        net.SendToServer()
                    end
                end,
                
                failed = function(err)
                    -- 处理错误
                    net.Start("NPCAIDialog")
                    net.WriteEntity(npc)
                    net.WriteString("HTTP Error: " .. (err or "Unknown Error"))
                    net.SendToServer()
                end
            })
        else
            -- 如果没有找到AI设置文件
            net.Start("NPCAIDialog")
            net.WriteEntity(npc)
            net.WriteString("未找到AI设置，请先在AI设置面板中配置")
            net.SendToServer()
        end
    end
end