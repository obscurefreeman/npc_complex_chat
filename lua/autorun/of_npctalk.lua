-- 共享变量
local DIALOG_DURATION = 4  -- 对话持续时间
local CHAR_DELAY = 0.05   -- 每个字符的延迟

if SERVER then
    util.AddNetworkString("NPCTalkStart")
    
    -- 对话管理器
    NPCTalkManager = NPCTalkManager or {}
    NPCTalkManager.ActiveDialogs = {}
    
    -- 检查NPC是否正在对话
    function NPCTalkManager:IsNPCTalking(npc)
        local entIndex = npc:EntIndex()
        return self.ActiveDialogs[entIndex] and 
               CurTime() - self.ActiveDialogs[entIndex] < DIALOG_DURATION
    end
    
    -- 开始新对话
    function NPCTalkManager:StartDialog(npc, dialogKey, target)
        if not IsValid(npc) then 
            return 
        end
        
        local entIndex = npc:EntIndex()
        
        -- 检查是否已经在对话中
        if self:IsNPCTalking(npc) then
            return
        end
        
        self.ActiveDialogs[entIndex] = CurTime()
        
        -- 向客户端发送对话请求
        net.Start("NPCTalkStart")
        net.WriteEntity(npc)
        net.WriteString(dialogKey)
        net.Send(target or player.GetAll())
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
    net.Receive("NPCTalkStart", function()
        local npc = net.ReadEntity()
        local dialogKey = net.ReadString()
        
        if not IsValid(npc) then 
            return 
        end
        
        -- 获取翻译后的文本
        local translatedText = L(dialogKey)
        if not translatedText then 
            return 
        end
        
        -- 检查是否已存在相同NPC的对话
        for i, dialog in ipairs(activeDialogs) do
            if dialog.npc == npc then
                return
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
    end)
    
    -- 添加新的 PostDrawTranslucentRenderables 钩子
    hook.Add("PostDrawTranslucentRenderables", "DrawNPCDialog3D", function()
        local currentTime = CurTime()
        
        for i = #activeDialogs, 1, -1 do
            local dialog = activeDialogs[i]
            
            -- 检查NPC是否有效
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
            end
            
            -- 获取NPC的位置和角度
            local npcPos = dialog.npc:GetPos()
            local npcAngles = LocalPlayer():EyeAngles()
            npcAngles:RotateAroundAxis(npcAngles:Up(), -90)
            npcAngles:RotateAroundAxis(npcAngles:Forward(), 90)
            
            -- 计算显示位置（NPC头顶上方）
            local pos = npcPos + Vector(0, 0, dialog.npc:OBBMaxs().z + 5)
            
            -- 开始3D2D渲染
            cam.Start3D2D(pos, npcAngles, 0.1)
                -- 计算文本尺寸
                surface.SetFont("ofgui_huge")
                local textWidth, textHeight = surface.GetTextSize(dialog.currentText)
                
                -- 绘制背景
                local padding = 10
                local boxWidth = textWidth + padding * 2
                local boxHeight = textHeight + padding * 2
                local boxX = -boxWidth/2
                local boxY = -boxHeight/2
                
                draw.RoundedBox(8, boxX, boxY, boxWidth, boxHeight, Color(0, 0, 0, 200))
                
                -- 绘制文本
                draw.DrawText(
                    dialog.currentText,
                    "ofgui_huge",
                    0,
                    boxY + padding,
                    Color(255, 255, 255, 255),
                    TEXT_ALIGN_CENTER
                )
            cam.End3D2D()
        end
    end)
end