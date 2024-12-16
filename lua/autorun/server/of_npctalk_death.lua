-- 定义死亡对话
local function ShowDeathDialog(npc)
    if not IsValid(npc) then return end

    local identity = _G.npcs[npc:EntIndex()]
    if not identity then return end

    -- 从JSON文件获取死亡对话
    local deathPhrases
    local dialogData = file.Read("data/of_npcp/citizen_talk.json", "GAME")
    if dialogData then
        local success, data = pcall(util.JSONToTable, dialogData)
        if success and data then
            deathPhrases = data.death[identity.type]
        end
    end

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