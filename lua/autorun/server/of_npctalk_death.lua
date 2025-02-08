-- 定义死亡对话
local function ShowDeathDialog(npc)
    if not IsValid(npc) then return end

    if NPCTalkManager:IsNPCTalking(npc) or NPCTalkManager:IsNPCChating(npc) then return end
    local identity = OFNPCS[npc:EntIndex()]
    if not identity then return end

    -- 从JSON文件获取死亡对话
    local deathPhrases = GLOBAL_OFNPC_DATA.npcTalks.death[identity.type]

    -- 如果成功获取死亡对话，随机选择一个
    if deathPhrases and #deathPhrases > 0 then
        local randomDeathPhrase = deathPhrases[math.random(#deathPhrases)]
        NPCTalkManager:StartDialog(npc, randomDeathPhrase)
    end
end

-- 监听 NPC 死亡事件
hook.Add("EntityRemoved", "NPCDeathDialog", function(ent)
    if IsValid(ent) and ent:IsNPC() then
        ShowDeathDialog(ent)
    end
end) 