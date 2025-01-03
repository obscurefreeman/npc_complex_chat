local playerCooldowns = {}
local PLAYER_COOLDOWN = 0.5
local npcCooldowns = {}

util.AddNetworkString("OpenNPCDialogMenu")
util.AddNetworkString("NPCDialogOptionSelected")

hook.Add("PlayerUse", "NPCTalkGreeting", function(ply, ent)
    -- 检查玩家冷却时间
    local steamID = ply:SteamID()
    if playerCooldowns[steamID] and (CurTime() - playerCooldowns[steamID] < PLAYER_COOLDOWN) then
        return
    end
    
    if not (IsValid(ent) and ent:IsNPC()) then return end
    
    -- 检查NPC是否在对话中
    local npcIndex = ent:EntIndex()
    if NPCTalkManager:IsNPCTalking(ent) then
        return
    end
    
    -- 更新玩家冷却时间
    playerCooldowns[steamID] = CurTime()
    
    -- 获取NPC身份信息
    local identity = OFNPCS and OFNPCS[npcIndex]
    if not identity then return end
    
    -- 从JSON文件获取问候语
    local greetings = GLOBAL_OFNPC_DATA.npcTalks.greetings[identity.type]
    
    -- 如果成功获取问候语，随机选择一个
    if greetings and #greetings > 0 then
        local randomGreeting = greetings[math.random(#greetings)]
        NPCTalkManager:StartDialog(ent, randomGreeting, "greeting", ply)
    end
    
    net.Start("OpenNPCDialogMenu")
    net.WriteEntity(ent)
    net.Send(ply)
end)

-- 清理冷却时间数据
hook.Add("PlayerDisconnected", "CleanupNPCTalkCooldowns", function(ply)
    playerCooldowns[ply:SteamID()] = nil
end)