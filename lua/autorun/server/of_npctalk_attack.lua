-- 当NPC攻击其他NPC或玩家时触发
hook.Add("Think", "NPCTalkAttack", function()
    for _, npc in pairs(ents.FindByClass("npc_*")) do
        if IsValid(npc) and npc:IsNPC() then
            local target = npc:GetEnemy()  -- 获取当前攻击目标
            if target and not npc.lastTarget then
                -- 如果目标从无到有，触发对话
                local identity = OFNPCS and OFNPCS[npc:EntIndex()]
                if identity then
                    local attackPhrases
                    local dialogData = file.Read("data/of_npcp/citizen_talk.json", "GAME")
                    if dialogData then
                        local success, data = pcall(util.JSONToTable, dialogData)
                        if success and data then
                            attackPhrases = data.attack[identity.type]
                        end
                    end

                    if attackPhrases and #attackPhrases > 0 then
                        if math.random() <= 0.3 then
                            timer.Simple(math.random() * 1.5, function()  -- 随机延迟0到1.5秒
                                if not IsValid(target) then return end  -- 检查目标是否有效且存活
                                local randomAttackPhrase = attackPhrases[math.random(#attackPhrases)]
                                NPCTalkManager:StartDialog(npc, randomAttackPhrase, "attack", target)
                            end)
                        end
                        npc.lastTarget = target  -- 记录当前目标
                        npc.lastAttackTime = CurTime()  -- 更新最后攻击时间
                    end
                end
            elseif target and (npc.lastTarget ~= target or (CurTime() - (npc.lastAttackTime or 0)) >= 50) then
                -- 如果目标更换或目标在50秒后再次出现，触发对话
                npc.lastAttackTime = CurTime()  -- 更新最后攻击时间
                npc.lastTarget = target  -- 更新最后目标
                -- 触发对话逻辑（与上面相同）
            else
                npc.lastTarget = target  -- 更新最后目标
            end
        end
    end
end)
