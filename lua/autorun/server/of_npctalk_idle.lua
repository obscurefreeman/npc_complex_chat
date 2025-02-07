local IDLE_CHECK_INTERVAL = math.random(5, 15)
local TALK_DISTANCE = 500

-- 定时检查空闲NPC
timer.Create("NPCIdleTalkCheck", IDLE_CHECK_INTERVAL, 0, function()
    -- 获取所有在线玩家
    local players = player.GetAll()
    if #players == 0 then return end
    
    -- 获取所有有身份的NPC
    local validNPCs = {}
    for entIndex, identity in pairs(OFNPCS) do
        local npc = Entity(entIndex)
        if IsValid(npc) and npc:IsNPC() then
            table.insert(validNPCs, npc)
        end
    end
    
    if #validNPCs == 0 then return end
    
    -- 随机打乱NPC列表顺序
    table.Shuffle(validNPCs)
    
    for _, npc in ipairs(validNPCs) do
        
        -- 检查是否正在对话或与玩家聊天
        if NPCTalkManager:IsNPCTalking(npc) or NPCTalkManager:IsNPCChating(npc) then continue end
        
        -- 检查是否有玩家在范围内且能看到这个NPC
        local hasNearbyPlayer = false
        local npcPos = npc:GetPos()
        
        for _, ply in ipairs(players) do
            if ply:GetPos():Distance(npcPos) <= TALK_DISTANCE then
                -- 检查玩家是否能看到NPC（视线检查）
                local trace = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = npcPos + Vector(0, 0, 50), -- 稍微向上偏移以便更好地检测
                    filter = function(ent) 
                        -- 忽略玩家和NPC本身
                        return ent ~= ply and ent ~= npc 
                    end,
                    mask = MASK_SOLID
                })
                
                if not trace.Hit then
                    hasNearbyPlayer = true
                    break
                end
            end
        end
        
        if not hasNearbyPlayer then continue end
        
        -- 获取NPC身份信息（这里我们已经确保NPC有身份信息）
        local identity = OFNPCS[npc:EntIndex()]
        
        -- 从JSON文件获取空闲对话
        local idlePhrases = GLOBAL_OFNPC_DATA.npcTalks.idle[identity.type]
        
        -- 如果成功获取空闲对话，随机选择一个
        if idlePhrases and #idlePhrases > 0 then
            local randomIdlePhrase = idlePhrases[math.random(#idlePhrases)]
            NPCTalkManager:StartDialog(npc, randomIdlePhrase, "idle", ply)
            break -- 只处理一个NPC后退出循环
        end
    end
end)