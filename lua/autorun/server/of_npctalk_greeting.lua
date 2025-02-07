local playerCooldowns = {}
local PLAYER_COOLDOWN = 0.5
local npcCooldowns = {}

util.AddNetworkString("OpenNPCDialogMenu")
util.AddNetworkString("NPCDialogOptionSelected")
util.AddNetworkString("NPCDialogMenuOpened")
util.AddNetworkString("NPCDialogMenuClosed")

-- 处理对话菜单打开事件
net.Receive("NPCDialogMenuOpened", function(len, ply)
    local npc = net.ReadEntity()
    if IsValid(npc) then
        NPCTalkManager:SetNPCChating(npc, ply, true)
    end
end)

-- 处理对话菜单关闭事件
net.Receive("NPCDialogMenuClosed", function(len, ply)
    local npc = net.ReadEntity()
    if IsValid(npc) then
        NPCTalkManager:SetNPCChating(npc, ply, false)
    end
end)

hook.Add("PlayerUse", "NPCTalkGreeting", function(ply, ent)
    -- 检查玩家冷却时间
    local steamID = ply:SteamID()
    if playerCooldowns[steamID] and (CurTime() - playerCooldowns[steamID] < PLAYER_COOLDOWN) then
        return
    end
    
    if not (IsValid(ent) and ent:IsNPC()) then return end
    
    local npcIndex = ent:EntIndex()
    
    -- 检查NPC是否正在和其他玩家对话
    if NPCTalkManager:IsNPCChating(ent) then
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
        NPCTalkManager:StartDialog(ent, randomGreeting, "greeting", ply, true)
    end
    
    net.Start("OpenNPCDialogMenu")
    net.WriteEntity(ent)
    net.Send(ply)
end)

-- 清理冷却时间数据
hook.Add("PlayerDisconnected", "CleanupNPCTalkCooldowns", function(ply)
    playerCooldowns[ply:SteamID()] = nil
    
    -- 清理该玩家相关的NPC对话状态
    for npcIndex, chattingPlayer in pairs(NPCTalkManager.ChattingNPCs) do
        if chattingPlayer == ply then
            NPCTalkManager.ChattingNPCs[npcIndex] = nil
        end
    end
end)