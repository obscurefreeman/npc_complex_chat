-- 共享变量
local DIALOG_DURATION = 4  -- 对话持续时间
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
               CurTime() - self.ActiveDialogs[entIndex] < DIALOG_DURATION
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
        
        self.ActiveDialogs[entIndex] = CurTime()

        if forceDialog then
            local npcData = OFNPCS[speaker:IsNPC() and speaker:EntIndex() or IsValid(target) and target:IsNPC() and target:EntIndex()]

            if npcData then
                npcData.dialogHistory = npcData.dialogHistory or {}
                local speakerInfo = {
                    speaker = speaker:IsPlayer() and speaker:Nick() or speaker:EntIndex(),
                    speakerType = speaker:IsPlayer() and "player" or "npc",
                    target = speaker:IsPlayer() and target:EntIndex() or target:Nick(),
                    text = dialogKey,
                    time = os.date("%H:%M")
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

            local npcs = GetAllNPCsList()

            if not npcs[npc:EntIndex()] then
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
                        translatedText = translatedText:gsub("/victim/", L(victimIdentity.name))
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
                if playerNick and targetIdentity then
                    translatedText = translatedText:gsub("/player/", playerNick)
                    translatedText = translatedText:gsub("/name/", L(targetIdentity.name))
                    translatedText = translatedText:gsub("/nickname/", L(targetIdentity.nickname))
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
                charIndex = 0
            }
            
            table.insert(activeDialogs, dialog)

            CreateNPCDialogSubtitles(npc, translatedText)
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
            if currentTime - dialog.startTime > DIALOG_DURATION then
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
            
            local finalPos = Vector(speakerPos.x, speakerPos.y, headPos.z + 13)
            
            -- 开始3D2D渲染
            cam.Start3D2D(finalPos, speakerAngles, 0.1)
                local screenScale = ScrH() / 1080
                -- 计算文本尺寸
                surface.SetFont("ofgui_eva")
                local textWidth, textHeight = surface.GetTextSize(dialog.currentText)
                
                -- 绘制背景
                local padding = 15 * screenScale
                local boxWidth = textWidth + padding * 2
                local boxHeight = textHeight + padding * 2
                local boxX = -boxWidth/2
                local boxY = -boxHeight/2
                
                draw.RoundedBox(8, boxX, boxY, boxWidth, boxHeight, Color(0, 0, 0, 200))
                
                -- 绘制文本
                draw.DrawText(
                    dialog.currentText,
                    "ofgui_eva",
                    0,
                    boxY + padding,
                    Color(255, 255, 255, 255),
                    TEXT_ALIGN_CENTER
                )
            cam.End3D2D()
        end
    end)
    
    -- 在客户端创建相同的函数以保持一致性
    NPCTalkManager = NPCTalkManager or {}
    function NPCTalkManager:GetChattingPlayer(npc)
        return LocalPlayer()
    end
end