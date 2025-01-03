-- 当NPC杀死其他NPC或玩家时触发
hook.Add("OnNPCKilled", "NPCTalkKill", function(victim, attacker, inflictor)
    if not (IsValid(attacker) and attacker:IsNPC()) then return end
    
    -- 检查是否正在对话
    if NPCTalkManager:IsNPCTalking(attacker) then return end
    
    -- 获取NPC身份信息
    local identity = OFNPCS and OFNPCS[attacker:EntIndex()]
    if not identity then return end
    
    -- 从JSON文件获取击杀语音
    local killPhrases = GLOBAL_OFNPC_DATA.npcTalks.kill[identity.type]
    
    -- 如果成功获取击杀语音，随机选择一个
    if killPhrases and #killPhrases > 0 then
        local randomKillPhrase = killPhrases[math.random(#killPhrases)]
        NPCTalkManager:StartDialog(attacker, randomKillPhrase, "kill", victim)
    end
end)