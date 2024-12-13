if SERVER then
    local IDLE_CHECK_INTERVAL = 15  -- 空闲检查间隔（秒）
    local IDLE_TALK_CHANCE = 15     -- 空闲说话几率（百分比）
    
    -- 定时检查空闲NPC
    timer.Create("NPCIdleTalkCheck", IDLE_CHECK_INTERVAL, 0, function()
        -- 获取所有NPC
        for _, npc in ipairs(ents.FindByClass("npc_*")) do
            -- 随机判断是否说话
            if math.random(1, 100) > IDLE_TALK_CHANCE then continue end
            
            -- 检查是否正在对话
            if NPCTalkManager:IsNPCTalking(npc) then continue end
            
            -- 获取NPC身份信息
            local identity = _G.npcs and _G.npcs[npc:EntIndex()]
            if not identity then continue end
            
            -- 从JSON文件获取空闲对话
            local idlePhrases
            if identity.type then
                local dialogData = file.Read("data/of_npcp/citizen_talk.json", "GAME")
                if dialogData then
                    local success, data = pcall(util.JSONToTable, dialogData)
                    if success and data then
                        idlePhrases = data.idle[identity.type]
                    end
                end
            end
            
            -- 如果成功获取空闲对话，随机选择一个
            if idlePhrases and #idlePhrases > 0 then
                local randomIdlePhrase = idlePhrases[math.random(#idlePhrases)]
                NPCTalkManager:StartDialog(npc, randomIdlePhrase)
            end
        end
    end)
end 