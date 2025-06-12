-- 暂时用创意工坊里偷的

local NET_STRING = "killfeed_log";

if CLIENT then
  HUDKillfeed = {}
  killfeed = {};

  local TIME = 10;

  function HUDKillfeed:Drawkillfeed(i, x, y)
    if (killfeed[i] == nil) then return; end;
    if (killfeed[i].time < CurTime()) then table.remove(killfeed, i); return; end;
    local feed = killfeed[i];
    surface.SetFont("ofgui_extratiny");
    local size = surface.GetTextSize(feed.victim);
    local killerSize = surface.GetTextSize(feed.attacker)
    local iconWidth, iconHeight = (killicon.GetSize(feed.weapon) * 0.95);

    backgroundWidth = size + killerSize + iconWidth + 60 * OFGUI.ScreenScale

    -- Draw the background rectangle
    if (feed.attacker == LocalPlayer():GetName()) then
      surface.SetDrawColor(110, 110, 110, 150);
    elseif (feed.victim == LocalPlayer():GetName()) then
      surface.SetDrawColor(120, 0, 0, 150);
    else
      surface.SetDrawColor(36, 36, 36, 150);
    end
    
    surface.DrawRect(x - backgroundWidth, y - 10 * OFGUI.ScreenScale, backgroundWidth, 35 * OFGUI.ScreenScale);
 

    -- Draw the victim's name
    draw.SimpleText(feed.victim, "ofgui_extratiny", x - 10 * OFGUI.ScreenScale, y, feed.vCol, 2);

    -- Draw the killicon
    local icon = (killicon.GetSize(feed.weapon) * 0.6);
    local kOffset = (size + icon); -- Killicon offset
    if (killicon.Exists(feed.weapon)) then
      killicon.Draw(x - kOffset - 10, y, feed.weapon, 255);
    end

    -- Draw the attacker's name
    draw.SimpleText(feed.attacker, "ofgui_extratiny", x - kOffset - (icon * 0.9) - 20 * OFGUI.ScreenScale, y, feed.aCol, 2);
  end

  function HUDKillfeed:Getkillfeed()
    return killfeed;
  end

  net.Receive(NET_STRING, function(len)
    table.insert(killfeed, {victim = language.GetPhrase(net.ReadString()),
                            vCol = net.ReadColor(),
                            attacker = language.GetPhrase(net.ReadString()),
                            aCol = net.ReadColor(),
                            weapon = net.ReadString() or nil,
                            time = CurTime() + TIME});
  end);

  local H = ScrH() * 0.107;


  function HUDKillfeed:killfeedPanel()
    for k,v in pairs(HUDKillfeed:Getkillfeed()) do
      HUDKillfeed:Drawkillfeed(k, ScrW() - 40 * OFGUI.ScreenScale, H + 32 * OFGUI.ScreenScale + ((k - 1) * 36 * OFGUI.ScreenScale));
    end
  end
 
  hook.Add("HUDPaint", "killfeedPanel", function()
    HUDKillfeed:killfeedPanel()
  end)

  -- Override default killfeed
  hook.Add("DrawDeathNotice", "killfeed_log", function(x, y)
    return false;
  end);
end

if SERVER then
  util.AddNetworkString(NET_STRING);
  local function SendDeathNotice(victim, inflictor, attacker)
    net.Start(NET_STRING)

    -- Victim data
    if (victim:IsPlayer()) then
      net.WriteString(victim:Name())
      net.WriteColor(team.GetColor(victim:Team()))
    elseif (victim:IsNPC() or victim:IsNextBot() and !victim.IsLambdaPlayer) then
      net.WriteString(victim:GetClass())
      net.WriteColor(Color(255, 0, 0))
    elseif (victim.IsLambdaPlayer) then
      net.WriteString(victim:GetLambdaName())
      net.WriteColor(team.GetColor(victim:Team()))
    end

    -- Inflictor class
    local inflClass = ""
    if (IsValid(inflictor)) then inflClass = inflictor:GetClass(); end

    -- Attacker data
    if (IsValid(attacker) and attacker:GetClass() != nil and attacker != victim) then
      if (attacker:IsPlayer() or attacker:IsNPC() or attacker:IsNextBot()) then
        -- Name
        if (attacker:IsPlayer()) then
          net.WriteString(attacker:Name())
          net.WriteColor(team.GetColor(attacker:Team()))
        elseif (attacker:IsNPC() or attacker:IsNextBot() and !attacker.IsLambdaPlayer) then
          net.WriteString(attacker:GetClass())
          net.WriteColor(Color(255, 0, 0))
        elseif (attacker.IsLambdaPlayer) then
          net.WriteString(attacker:GetLambdaName())
          net.WriteColor(team.GetColor(attacker:Team()))
        end

        -- Weapon
        if (attacker.IsLambdaPlayer) then
          if (attacker:GetWeaponENT().l_killiconname == nil) then
            net.WriteString(inflClass);
          else
            net.WriteString(attacker:GetWeaponENT().l_killiconname)
          end 
        elseif (inflictor == attacker and IsValid(attacker:GetActiveWeapon())) then
          net.WriteString(attacker:GetActiveWeapon():GetClass())
        else
          net.WriteString(inflClass);
        end
      else
        net.WriteString(inflClass);
        net.WriteColor(Color(255, 0, 0));
      end
    else
      net.WriteString("");
      net.WriteColor(Color(255, 0, 0));
      net.WriteString("");
    end

    -- Send to everyone
    net.Broadcast();
  end

  -- Send death notice
  hook.Add("PlayerDeath", "killfeed_death", function(player, infl, attacker)
    SendDeathNotice(player, infl, attacker);
  end);

  hook.Add("OnNPCKilled", "killfeed_death_npc", function(npc, attacker, infl)
    SendDeathNotice(npc, infl, attacker);
  end);
end
