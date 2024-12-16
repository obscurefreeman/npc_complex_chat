-- 当NPC杀死其他NPC或玩家时触发
hook.Add("OnNPCKilled", "NPCTalkKill", function(npc, attacker, inflictor)
    if not (IsValid(attacker) and attacker:IsNPC()) then return end
    
    -- 检查是否正在对话
    if NPCTalkManager:IsNPCTalking(attacker) then return end
    
    -- 获取NPC身份信息
    local identity = _G.npcs and _G.npcs[attacker:EntIndex()]
    if not identity then return end
    
    -- 从JSON文件获取击杀语音
    local killPhrases
    if identity.type then
        local dialogData = file.Read("data/of_npcp/citizen_talk.json", "GAME")
        if dialogData then
            local success, data = pcall(util.JSONToTable, dialogData)
            if success and data then
                killPhrases = data.kill[identity.type]
            end
        end
    end
    
    -- 如果成功获取击杀语音，随机选择一个
    if killPhrases and #killPhrases > 0 then
        local randomKillPhrase = killPhrases[math.random(#killPhrases)]
        NPCTalkManager:StartDialog(attacker, randomKillPhrase)
    end
end)