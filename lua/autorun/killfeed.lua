if CLIENT then
  net.Receive( "OFNPCP_test_AddtoKillfeed", function()
    local attackername = net.ReadString()
    local attackerteam = net.ReadInt( 8 )
    local victimname = net.ReadString()
    local victimteam = net.ReadInt( 8 )
    local inflictorname = net.ReadString()

    GAMEMODE:AddDeathNotice( attackername, attackerteam, inflictorname, victimname, victimteam )
  end )
end

if ( SERVER ) then

  hook.Add("OnNPCKilled", "NPCTalkKillfeed", function(victim, attacker, inflictor)
    if !IsValid( attacker ) then return end

    local function OFGetDeathNoticeEntityName( ent )
      if ent:GetClass() == "npc_citizen" then
        if ent:GetModel() == "models/odessa.mdl" then return "Odessa Cubbage" end
    
            local name = ent:GetName()
        if name == "griggs" then return "Griggs" end
        if name == "sheckley" then return "Sheckley" end
        if name == "tobias" then return "Laszlo" end
        if name == "stanley" then return "Sandy" end
      end
    
      if ent:IsVehicle() and ent.VehicleTable and ent.VehicleTable.Name then
        return ent.VehicleTable.Name
      end
      if ent:IsNPC() and ent.NPCTable and ent.NPCTable.Name then
        return ent.NPCTable.Name
      end
    
      return "#" .. ent:GetClass()
    end

    local function getName(ent)
        if ent:IsPlayer() then
            return ent:Nick()
        elseif OFNPCS[ent:EntIndex()] and OFNPCS[ent:EntIndex()].name then
            if OFNPCS[ent:EntIndex()].name == OFNPCS[ent:EntIndex()].gamename then
                return OFGetDeathNoticeEntityName(ent)
            else
                return ofTranslate(OFNPCS[ent:EntIndex()].name) .. " “" .. ofTranslate(OFNPCS[ent:EntIndex()].nickname) .. "”"
            end
        end
    end

    local victimname = getName(victim)
    local attackername = getName(attacker)

    local victimteam = ( victim:IsPlayer() and victim:Team() or -1 )
    local attackerteam = ( attacker:IsPlayer() and attacker:Team() or -1 )

    local attackerWep = attacker.GetActiveWeapon
    local inflictorname = ( victim == attacker and "suicide" or ( IsValid( inflictor ) and ( inflictor.l_killiconname or ( ( inflictor == attacker and attackerWep and IsValid( attackerWep( attacker ) ) ) and attackerWep( attacker ):GetClass() or inflictor:GetClass() ) ) or attackerclass ) )
    
    net.Start( "OFNPCP_test_AddtoKillfeed" )
        net.WriteString( attackername )
        net.WriteInt( attackerteam, 8 )
        net.WriteString( victimname )
        net.WriteInt( victimteam, 8 )
        net.WriteString( inflictorname )
    net.Broadcast()
  end)
end
