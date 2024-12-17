-- 定义全局变量
NPC_EXP = {}
local MAX_LEVEL = 10  -- 最大等级
local EXP_PER_LEVEL = {0, 100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 5500}  -- 每个等级所需的经验值

-- 初始化NPC经验
function InitializeNPCExp(ent)
    if IsValid(ent) and ent:IsNPC() then
        NPC_EXP[ent:EntIndex()] = {level = 1, exp = 0}
    end
end

-- NPC击杀敌人时调用的函数
function OnNPCKillEnemy(npc, enemy)
    if IsValid(npc) and IsValid(enemy) then
        local npcExpData = NPC_EXP[npc:EntIndex()]
        if npcExpData and npcExpData.level < MAX_LEVEL then
            npcExpData.exp = npcExpData.exp + 50  -- 击杀敌人获得50经验
            CheckLevelUp(npc)
        end
    end
end

-- 检查是否升级
function CheckLevelUp(npc)
    local npcExpData = NPC_EXP[npc:EntIndex()]
    while npcExpData.exp >= EXP_PER_LEVEL[npcExpData.level] do
        npcExpData.exp = npcExpData.exp - EXP_PER_LEVEL[npcExpData.level]
        npcExpData.level = npcExpData.level + 1
        if npcExpData.level >= MAX_LEVEL then
            npcExpData.exp = 0  -- 达到满级后经验清零
            break
        end
    end
end

-- 在NPC创建时初始化经验
hook.Add("OnEntityCreated", "InitializeNPCExpOnCreate", function(ent)
    timer.Simple(0, function()
        InitializeNPCExp(ent)
    end)
end)

-- 处理NPC击杀敌人的事件
hook.Add("EntityTakeDamage", "NPCGainExpOnKill", function(ent, dmginfo)
    if IsValid(ent) and ent:IsNPC() and IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():IsPlayer() then
        local victim = dmginfo:GetInflictor()
        if victim and victim:IsNPC() and victim:Health() <= 0 then
            OnNPCKillEnemy(ent, victim)
        end
    end
end) 