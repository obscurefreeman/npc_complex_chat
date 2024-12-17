hook.Add("OnNPCKilled", "NPCTalkKill", function(victim, attacker, inflictor)
    if not (IsValid(attacker) and attacker:IsNPC()) then return end
    local identity = OFNPCS and OFNPCS[attacker:EntIndex()]
    if not identity then return end

    if identity.rank and identity.exp and identity.exp_per_rank ~= 0 then
        if identity.type == "metropolice" then
            if identity.rank < 5 then
                identity.exp = identity.exp + 1000
                local nextLevelExp = CalculateExpNeeded(identity.rank)

                if identity.exp >= nextLevelExp then
                    identity.rank = identity.rank + 1
                    identity.exp = identity.exp - nextLevelExp
                end
            end
        else
            if identity.rank < 39 then
                identity.exp = identity.exp + 1000
                local nextLevelExp = CalculateExpNeeded(identity.rank)

                if identity.exp >= nextLevelExp then
                    identity.rank = identity.rank + 1
                    identity.exp = identity.exp - nextLevelExp
                end
            end
        end
    end
end)


-- 计算升级所需经验的函数
function CalculateExpNeeded(level)
    if level >= 1 and level <= 10 then
        return 120 + (level - 1) * 20
    elseif level >= 11 and level <= 20 then
        return 300 + (level - 11) * 40
    elseif level >= 21 and level <= 30 then
        return 660 + (level - 21) * 60
    elseif level >= 31 and level <= 39 then
        return 1200 + (level - 31) * 80
    else
        return 0  -- 超出范围的等级
    end
end