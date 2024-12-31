-- 当NPC攻击其他NPC或玩家时触发
hook.Add("OnNPCAttack", "NPCTalkAttack", function(attacker, target)
    -- 添加调试信息
    print("钩子 OnNPCAttack 被触发")
    
    if not (IsValid(attacker) and attacker:IsNPC()) then return end

    -- 检查是否正在对话
    if NPCTalkManager:IsNPCTalking(attacker) then return end

    -- 获取NPC身份信息
    local identity = OFNPCS and OFNPCS[attacker:EntIndex()]
    if not identity then return end

    -- 从JSON文件获取攻击语音
    local attackPhrases
    if identity.type then
        local dialogData = file.Read("data/of_npcp/citizen_talk.json", "GAME")
        if dialogData then
            local success, data = pcall(util.JSONToTable, dialogData)
            if success and data then
                attackPhrases = data.attack[identity.type]
            end
        end
    end

    -- 如果成功获取攻击语音，随机选择一个
    if attackPhrases and #attackPhrases > 0 then
        local randomAttackPhrase = attackPhrases[math.random(#attackPhrases)]
        NPCTalkManager:StartDialog(attacker, randomAttackPhrase, "attack", target)
    end
end)
