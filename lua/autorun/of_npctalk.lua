-- 共享变量
local TALK_COOLDOWN = 5    -- NPC对话冷却时间（秒）
local DIALOG_DURATION = 4  -- 对话持续时间
local CHAR_DELAY = 0.05   -- 每个字符的延迟

if SERVER then
    util.AddNetworkString("NPCTalkStart")
    
    local npcCooldowns = {}
    
    -- 当玩家按E键与NPC互动时触发
    hook.Add("PlayerUse", "NPCTalkSystem", function(ply, ent)
        -- 基础检查
        if not (IsValid(ent) and ent:IsNPC()) then return end
        
        local entIndex = ent:EntIndex()
        local currentTime = CurTime()
        
        -- 检查冷却时间
        if npcCooldowns[entIndex] and currentTime - npcCooldowns[entIndex] < TALK_COOLDOWN then
            return
        end
        
        -- 更新冷却时间
        npcCooldowns[entIndex] = currentTime
        
        -- 获取NPC身份信息
        local identity = _G.npcs and _G.npcs[entIndex]  -- 从全局变量获取npcs
        if not identity then return end
        
        -- 向客户端发送对话请求
        net.Start("NPCTalkStart")
        net.WriteEntity(ent)
        net.WriteTable(identity)
        net.Send(ply)
    end)
end

if CLIENT then
    -- 字体设置
    surface.CreateFont("NPCTalkFont", {
        font = "Arial",
        size = 40,
        weight = 500,
        antialias = true
    })
    
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
        local identity = net.ReadTable()
        
        if not IsValid(npc) then return end
        
        -- 获取适当的问候语
        local greetings
        if identity.type then
            local greetingsData = file.Read("data/of_npcp/citizen_talk.json", "GAME")
            if greetingsData then
                local success, data = pcall(util.JSONToTable, greetingsData)
                if success and data then
                    greetings = data.greetings[identity.type]
                end
            end
        end
        
        if not greetings or #greetings == 0 then return end
        
        -- 随机选择一个问候语
        local greeting = L(greetings[math.random(#greetings)])
        
        -- 创建新的对话
        local dialog = {
            npc = npc,
            text = greeting,
            currentText = "",
            startTime = CurTime(),
            nextCharTime = CurTime(),
            charIndex = 0
        }
        
        table.insert(activeDialogs, dialog)
    end)
    
    -- 移除原来的 HUDPaint 钩子
    hook.Remove("HUDPaint", "DrawNPCDialog")
    
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
                -- 启用穿墙显示
                -- cam.IgnoreZ(true)
                
                -- 计算文本尺寸
                surface.SetFont("NPCTalkFont")
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
                    "NPCTalkFont",
                    0,
                    boxY + padding,
                    Color(255, 255, 255, 255),
                    TEXT_ALIGN_CENTER
                )
                
                -- 恢复正常Z缓冲
                -- cam.IgnoreZ(false)
            cam.End3D2D()
        end
    end)
end