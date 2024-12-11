


if SERVER then
    hook.Add("OnEntityCreated", "NPCPersonality", function(ent)
        if not ofkc_enabled:GetBool() then return end
        if not IsValid(ent) or not ent:IsNPC() then return end
        if ent:GetClass() == "npc_bullseye" then return end
    end)

    hook.Add("EntityRemoved", "CleanupNPCData", function(ent)
        if IsValid(ent) and ent:IsNPC() then
            if ent:Health() > 0 then
                npcs[ent:EntIndex()] = nil
            end
        end
    end)
end