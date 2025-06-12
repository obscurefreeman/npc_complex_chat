if ( SERVER ) then
  hook.Add("OnNPCKilled", "NPCTalkKillfeed", function(victim, attacker, inflictor)
    if !IsValid( attacker ) then return end

    local attackerWep = attacker.GetActiveWeapon
    local inflictorname = ( victim == attacker and "suicide" or ( IsValid( inflictor ) and ( inflictor.l_killiconname or ( ( inflictor == attacker and attackerWep and IsValid( attackerWep( attacker ) ) ) and attackerWep( attacker ):GetClass() or inflictor:GetClass() ) ) or attackerclass ) )
    
    net.Start( "OFNPCP_test_AddtoKillfeed" )
        net.WriteEntity( attacker )
        net.WriteEntity( victim )
        net.WriteString( inflictorname )
    net.Broadcast()
  end)
end
