-- 共享变量
local CHAR_DELAY = 0.05   -- 每个字符的延迟

if SERVER then
    -- 对话管理器
    NPCTalkManager = NPCTalkManager or {}
    NPCTalkManager.ActiveDialogs = {}
    NPCTalkManager.ChattingNPCs = {} -- 新增：记录正在对话的NPC
    
    -- 检查NPC是否正在对话
    function NPCTalkManager:IsNPCTalking(npc)
        local entIndex = npc:EntIndex()
        return self.ActiveDialogs[entIndex] and 
               CurTime() - self.ActiveDialogs[entIndex].startTime < self.ActiveDialogs[entIndex].duration
    end
    
    -- 检查NPC是否正在和玩家聊天（打开对话菜单）
    function NPCTalkManager:IsNPCChating(npc)
        local entIndex = npc:EntIndex()
        return self.ChattingNPCs[entIndex] ~= nil
    end
    
    -- 设置NPC的对话状态
    function NPCTalkManager:SetNPCChating(npc, player, isChating)
        local entIndex = npc:EntIndex()
        if isChating then
            self.ChattingNPCs[entIndex] = player
        else
            self.ChattingNPCs[entIndex] = nil
        end
    end
    
    -- 开始新对话
    function NPCTalkManager:StartDialog(speaker, dialogKey, dialogtype, target, forceDialog, aidetail)
        if not IsValid(speaker) or not dialogKey or not dialogtype then 
            return 
        end
        
        local entIndex = speaker:EntIndex()
        
        -- 检查是否已经在对话中，如果是强制对话则忽略此检查
        if not forceDialog and self:IsNPCTalking(speaker) then
            return
        end
        
        -- 计算对话持续时间
        local textLength = utf8.len(L(dialogKey))
        local duration = (textLength * CHAR_DELAY) + 2
        
        self.ActiveDialogs[entIndex] = {
            startTime = CurTime(),
            duration = duration
        }

        if forceDialog then
            local npcData = OFNPCS[speaker:IsNPC() and speaker:EntIndex() or IsValid(target) and target:IsNPC() and target:EntIndex()]

            if npcData then
                npcData.dialogHistory = npcData.dialogHistory or {}
                local speakerInfo = {
                    speaker = speaker:IsPlayer() and speaker:Nick() or speaker:EntIndex(),
                    speakerType = speaker:IsPlayer() and "player" or "npc",
                    target = speaker:IsPlayer() and target:EntIndex() or target:Nick(),
                    text = dialogKey,
                    time = os.date("%H:%M"),
                    color = speaker:IsPlayer() and OFPLAYERS[speaker:SteamID()] and OFPLAYERS[speaker:SteamID()].deck and GLOBAL_OFNPC_DATA.cards.info[OFPLAYERS[speaker:SteamID()].deck] and GLOBAL_OFNPC_DATA.cards.info[OFPLAYERS[speaker:SteamID()].deck].color or GLOBAL_OFNPC_DATA.cards.info[npcData.camp] and GLOBAL_OFNPC_DATA.cards.info[npcData.camp].color or color_white,
                }
                -- 仅在aidetail存在时添加
                if aidetail and istable(aidetail) then
                    speakerInfo.aidetail = aidetail
                end
                table.insert(npcData.dialogHistory, speakerInfo)
                net.Start("NPCIdentityUpdate")
                net.WriteEntity(speaker:IsNPC() and speaker or target)
                net.WriteTable(npcData)
                net.Broadcast()
            end
        end
        -- 向客户端发送对话请求
        net.Start("TalkStart")
        net.WriteEntity(speaker)
        net.WriteString(dialogKey)
        net.WriteString(dialogtype)
        local ent = IsValid(target) and target or Entity(0)
        net.WriteEntity(ent)
        -- 添加是否在聊天的状态
        net.WriteBool(speaker:IsNPC() and self:IsNPCChating(speaker) or false)
        if speaker:IsNPC() and self:IsNPCChating(speaker) then
            net.WriteEntity(self:GetChattingPlayer(speaker))
        end
        net.Send(player.GetAll())
    end
    
    -- 获取正在与NPC对话的玩家
    function NPCTalkManager:GetChattingPlayer(npc)
        local entIndex = npc:EntIndex()
        return self.ChattingNPCs[entIndex]
    end
end

if CLIENT then
    
    -- 对话框设置
    local activeDialogs = {}
    
    -- 添加一个UTF8字符串截取的辅助函数
    local function utf8sub(str, startChar, endChar)
        if not str then return "" end
        
        local chars = utf8.codes(str)
        local result = {}
        local count = 0
        
        for p, c in chars do
            count = count + 1
            if count >= startChar then
                table.insert(result, utf8.char(c))
            end
            if endChar and count >= endChar then
                break
            end
        end
        
        return table.concat(result)
    end
    
    -- 接收服务器的对话请求
    net.Receive("TalkStart", function()
        local npc = net.ReadEntity()
        local dialogKey = net.ReadString()
        local dialogtype = net.ReadString()
        local target = net.ReadEntity()
        local isChating = net.ReadBool()
        local chattingPlayer = isChating and net.ReadEntity() or nil
        
        if IsValid(npc) then
            -- 防止出现/victim/没有被替换的情况
            if (dialogtype == "kill" or dialogtype == "attack") and not IsValid(target) then return end
            -- 计算对话持续时间
            local textLength = utf8.len(L(dialogKey))
            local duration = (textLength * CHAR_DELAY) + 2

            local npcs = GetAllNPCsList() or {}

            -- 检查NPC是否有效且未注册身份信息，如果客户端不认识说话NPC，说明客户端和服务器不同步，现在就同步！
            if not npc:IsPlayer() and not npcs[npc:EntIndex()] then
                -- 向服务器请求更新NPC身份信息
                net.Start("NPCIdentityUpdate")
                    net.WriteEntity(npc)
                net.SendToServer()
                return
            end
            
            -- 获取翻译后的文本
            local translatedText = L(dialogKey)
            if not translatedText then 
                return 
            end

            if (dialogtype == "kill" or dialogtype == "attack") and IsValid(target) then
                if target:IsPlayer() then
                    local playerNick = target:Nick()
                    if playerNick then
                        translatedText = translatedText:gsub("/victim/", playerNick)
                    end
                else
                    local victimIdentity = npcs[target:EntIndex()]
                    if victimIdentity and victimIdentity.name then
                        local npcName = L(victimIdentity.name)
                        if victimIdentity.name == victimIdentity.gamename then
                            npcName = language.GetPhrase(victimIdentity.gamename)
                        end
                        translatedText = translatedText:gsub("/victim/", npcName)
                    elseif list.Get("NPC")[target:GetClass()] and list.Get("NPC")[target:GetClass()].Name then
                        local victimgamename = language. GetPhrase(list.Get("NPC")[target:GetClass()].Name)

                        translatedText = translatedText:gsub("/victim/", victimgamename)
                    else
                        return
                    end
                end
            elseif dialogtype == "dialogue" and IsValid(target) then
                local playerNick = target:Nick()
                if playerNick then
                    translatedText = translatedText:gsub("/player/", playerNick)
                end
            elseif dialogtype == "player" and IsValid(target) then
                local playerNick = npc:Nick()
                local targetIdentity = npcs[target:EntIndex()]
                local npcName = L(targetIdentity.name)
                if targetIdentity.name == targetIdentity.gamename then
                    npcName = language.GetPhrase(targetIdentity.gamename)
                end
                if playerNick and targetIdentity then
                    translatedText = translatedText:gsub("/player/", playerNick)
                    translatedText = translatedText:gsub("/name/", npcName)
                    translatedText = translatedText:gsub("/nickname/", L(targetIdentity.nickname))
                end
            elseif dialogtype == "idle" and npc:IsNPC() then
                local npcIdentity = npcs[npc:EntIndex()]
                if npcIdentity then
                    local npcName = L(npcIdentity.name)
                    if npcIdentity.name == npcIdentity.gamename then
                        npcName = language.GetPhrase(npcIdentity.gamename)
                    end
                    translatedText = translatedText:gsub("/name/", npcName)
                end
            end

            translatedText = translatedText:gsub("/map/", game.GetMap())
            translatedText = translatedText:gsub("/time/", os.date("%H:%M"))
            
            -- 如果是强制对话，清除当前NPC的所有对话
            for i = #activeDialogs, 1, -1 do
                if activeDialogs[i].npc == npc then
                    table.remove(activeDialogs, i)
                end
            end
            
            -- 创建新的对话
            local dialog = {
                npc = npc,
                text = translatedText,
                currentText = "",
                startTime = CurTime(),
                nextCharTime = CurTime(),
                charIndex = 0,
                duration = duration
            }
            
            table.insert(activeDialogs, dialog)

            CreateNPCDialogSubtitles(npc, translatedText)
            PlayNPCDialogVoice(npc, translatedText)
        end
    end)
    
    -- 添加新的 PostDrawTranslucentRenderables 钩子
    hook.Add("PostDrawTranslucentRenderables", "DrawNPCDialog3D", function()
        local currentTime = CurTime()
        
        for i = #activeDialogs, 1, -1 do
            local dialog = activeDialogs[i]
            
            -- 检查说话者是否有效
            if not IsValid(dialog.npc) then
                table.remove(activeDialogs, i)
                continue
            end
            
            -- 检查对话是否已过期
            if currentTime - dialog.startTime > dialog.duration then
                table.remove(activeDialogs, i)
                continue
            end
            
            -- 修改逐字显示文本的逻辑
            if dialog.charIndex < utf8.len(dialog.text) and currentTime >= dialog.nextCharTime then
                dialog.charIndex = dialog.charIndex + 1
                dialog.currentText = utf8sub(dialog.text, 1, dialog.charIndex)
                dialog.nextCharTime = currentTime + CHAR_DELAY
                
                dialog.npc:EmitSound("ofnpcp/type/type" .. math.random(1, 32) .. ".wav")
            end
            
            -- 获取说话者的位置和角度
            local speakerPos = dialog.npc:GetPos()
            local speakerAngles = LocalPlayer():EyeAngles()
            speakerAngles:RotateAroundAxis(speakerAngles:Up(), -90)
            speakerAngles:RotateAroundAxis(speakerAngles:Forward(), 90)

            local headBoneIndex = dialog.npc:LookupBone("ValveBiped.Bip01_Head1")
            local headPos = dialog.npc:GetBonePosition(headBoneIndex)
            
            local finalPos = Vector(speakerPos.x, speakerPos.y, headPos.z + 10)
            
            -- 开始3D2D渲染
            cam.Start3D2D(finalPos, speakerAngles, 0.1)
                local maxWidth = 1000 * OFGUI.ScreenScale
                
                -- 使用markup解析文本
                local markup = markup.Parse("<font=ofgui_huge>" .. dialog.currentText .. "</font>", maxWidth)
                
                -- 获取文本尺寸
                local textWidth, textHeight = markup:GetWidth(), markup:GetHeight()
                
                -- 绘制背景
                local padding = 15 * OFGUI.ScreenScale
                local boxWidth = textWidth + padding * 2
                local boxHeight = textHeight + padding * 2
                local boxX = -boxWidth/2
                local boxY = -boxHeight
                
                draw.RoundedBox(8, boxX, boxY, boxWidth, boxHeight, Color(0, 0, 0, 200))
                
                -- 绘制文本
                markup:Draw(0, boxY + padding, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, nil, TEXT_ALIGN_CENTER )
            cam.End3D2D()
        end
    end)
    
    -- 在客户端创建相同的函数以保持一致性
    NPCTalkManager = NPCTalkManager or {}
    function NPCTalkManager:GetChattingPlayer(npc)
        return LocalPlayer()
    end
end