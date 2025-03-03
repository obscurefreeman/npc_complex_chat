-- 定义全局变量
local playerCooldowns = {}
local PLAYER_COOLDOWN = 0.5
local npcCooldowns = {}
local IDLE_CHECK_INTERVAL = math.random(5, 15)
local TALK_DISTANCE = 500

-- 函数：显示死亡对话
local function ShowDeathDialog(npc)
    if not IsValid(npc) then return end
    if NPCTalkManager:IsNPCTalking(npc) or NPCTalkManager:IsNPCChating(npc) then return end
    local identity = OFNPCS[npc:EntIndex()]
    if not identity then return end
    local deathPhrases = GLOBAL_OFNPC_DATA.npcTalks.death[identity.type]
    if deathPhrases and #deathPhrases > 0 then
        local randomDeathPhrase = deathPhrases[math.random(#deathPhrases)]
        NPCTalkManager:StartDialog(npc, randomDeathPhrase)
    end
end

-- 钩子：NPC死亡事件
hook.Add("EntityRemoved", "NPCDeathDialog", function(ent)
    if IsValid(ent) and ent:IsNPC() then
        ShowDeathDialog(ent)
    end
end)

-- 钩子：NPC攻击事件
hook.Add("Think", "NPCTalkAttack", function()
    for _, npc in pairs(ents.FindByClass("npc_*")) do
        if IsValid(npc) and npc:IsNPC() then
            if NPCTalkManager:IsNPCTalking(npc) or NPCTalkManager:IsNPCChating(npc) then return end
            local target = npc:GetEnemy()
            if target and not npc.lastTarget then
                local identity = OFNPCS and OFNPCS[npc:EntIndex()]
                if identity then
                    local attackPhrases = GLOBAL_OFNPC_DATA.npcTalks.attack[identity.type]
                    if attackPhrases and #attackPhrases > 0 and math.random() <= 0.3 then
                        timer.Simple(math.random() * 1.5, function()
                            if not IsValid(target) then return end
                            if not IsValid(npc) or NPCTalkManager:IsNPCTalking(npc) or NPCTalkManager:IsNPCChating(npc) then return end
                            local randomAttackPhrase = attackPhrases[math.random(#attackPhrases)]
                            NPCTalkManager:StartDialog(npc, randomAttackPhrase, "attack", target)
                        end)
                    end
                    npc.lastTarget = target
                    npc.lastAttackTime = CurTime()
                end
            elseif target and (npc.lastTarget ~= target or (CurTime() - (npc.lastAttackTime or 0)) >= 50) then
                npc.lastAttackTime = CurTime()
                npc.lastTarget = target
            else
                npc.lastTarget = target
            end
        end
    end
end)

-- 钩子：NPC击杀事件
hook.Add("OnNPCKilled", "NPCTalkKill", function(victim, attacker, inflictor)
    if not (IsValid(attacker) and attacker:IsNPC()) then return end
    if NPCTalkManager:IsNPCTalking(attacker) or NPCTalkManager:IsNPCChating(attacker) then return end
    local identity = OFNPCS and OFNPCS[attacker:EntIndex()]
    if not identity then return end
    local killPhrases = GLOBAL_OFNPC_DATA.npcTalks.kill[identity.type]
    if killPhrases and #killPhrases > 0 then
        local randomKillPhrase = killPhrases[math.random(#killPhrases)]
        NPCTalkManager:StartDialog(attacker, randomKillPhrase, "kill", victim)
    end
end)

-- 钩子：玩家使用NPC事件
hook.Add("PlayerUse", "NPCTalkGreeting", function(ply, ent)
    local steamID = ply:SteamID()
    if playerCooldowns[steamID] and (CurTime() - playerCooldowns[steamID] < PLAYER_COOLDOWN) then
        return
    end
    if not (IsValid(ent) and ent:IsNPC()) then return end
    local npcIndex = ent:EntIndex()
    if NPCTalkManager:IsNPCChating(ent) then
        return
    end
    playerCooldowns[steamID] = CurTime()
    local identity = OFNPCS and OFNPCS[npcIndex]
    if not identity then return end
    local greetings = GLOBAL_OFNPC_DATA.npcTalks.greetings[identity.type]
    if greetings and #greetings > 0 then
        local randomGreeting = greetings[math.random(#greetings)]
        timer.Simple(0.1, function()
            NPCTalkManager:StartDialog(ent, randomGreeting, "dialogue", ply, true)
        end)
    end
    net.Start("OpenNPCDialogMenu")
    net.WriteEntity(ent)
    net.Send(ply)
end)

-- 钩子：玩家断开连接事件
hook.Add("PlayerDisconnected", "CleanupNPCTalkCooldowns", function(ply)
    playerCooldowns[ply:SteamID()] = nil
    for npcIndex, chattingPlayer in pairs(NPCTalkManager.ChattingNPCs) do
        if chattingPlayer == ply then
            NPCTalkManager.ChattingNPCs[npcIndex] = nil
        end
    end
end)

-- 定时检查空闲NPC
timer.Create("NPCIdleTalkCheck", IDLE_CHECK_INTERVAL, 0, function()
    local players = player.GetAll()
    if #players == 0 then return end
    local validNPCs = {}
    for entIndex, identity in pairs(OFNPCS) do
        local npc = Entity(entIndex)
        if IsValid(npc) and npc:IsNPC() then
            table.insert(validNPCs, npc)
        end
    end
    if #validNPCs == 0 then return end
    table.Shuffle(validNPCs)
    for _, npc in ipairs(validNPCs) do
        if NPCTalkManager:IsNPCTalking(npc) or NPCTalkManager:IsNPCChating(npc) then continue end
        local hasNearbyPlayer = false
        local npcPos = npc:GetPos()
        for _, ply in ipairs(players) do
            if ply:GetPos():Distance(npcPos) <= TALK_DISTANCE then
                local trace = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = npcPos + Vector(0, 0, 50),
                    filter = function(ent) 
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
        local identity = OFNPCS[npc:EntIndex()]
        local idlePhrases = GLOBAL_OFNPC_DATA.npcTalks.idle[identity.type]
        if idlePhrases and #idlePhrases > 0 then
            local randomIdlePhrase = idlePhrases[math.random(#idlePhrases)]
            NPCTalkManager:StartDialog(npc, randomIdlePhrase, "idle", ply)
            break
        end
    end
end)