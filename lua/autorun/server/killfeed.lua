local function OFAddDeathNotice(victim, attacker, inflictor)
  if !IsValid( attacker ) then return end

  local attackerWep = attacker.GetActiveWeapon
  local inflictorname = ( victim == attacker and "suicide" or ( IsValid( inflictor ) and ( inflictor.l_killiconname or ( ( inflictor == attacker and attackerWep and IsValid( attackerWep( attacker ) ) ) and attackerWep( attacker ):GetClass() or inflictor:GetClass() ) ) or attackerclass ) )

  -- 添加安全检查
  if not IsValid(attacker) or not IsValid(victim) then return end

  -- 获取攻击者和受害者信息
  local attackerClass = attacker:IsPlayer() and "player" or (attacker.GetClass and attacker:GetClass() or "player")
  local victimClass = victim:IsPlayer() and "player" or (victim.GetClass and victim:GetClass() or "player")
  local attackerClassify = attacker:IsPlayer() and 1 or (attacker.Classify and attacker:Classify() or 0)
  local victimClassify = victim:IsPlayer() and 1 or (victim.Classify and victim:Classify() or 0)

  -- 发送网络消息
  net.Start("OFNPCP_test_AddtoKillfeed")
    net.WriteEntity(attacker)
    net.WriteEntity(victim)
    net.WriteString(inflictorname)
    -- 备用，以防找不到npc信息
    net.WriteString(attackerClass)
    net.WriteString(victimClass)
    -- npc阵营
    net.WriteUInt(attackerClassify, 8)
    net.WriteUInt(victimClassify, 8)
  net.Broadcast()
end

hook.Add("PlayerDeath", "OFKillfeedPlayer", function(victim, attacker, inflictor)
  OFAddDeathNotice(victim, attacker, inflictor)
end)

hook.Add("OnNPCKilled", "OFKillfeedNPC", function(victim, attacker, inflictor)
  OFAddDeathNotice(victim, attacker, inflictor)
end)