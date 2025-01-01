AddCSLuaFile()

Subtitles_Path = "subtitles/"
Subtitles_Table = {}

if SERVER then
	util.AddNetworkString("subtitle_msg")
end

local function SendSubtitle(tbl,sndtbl)
	if SERVER then	
		local pos = sndtbl.Pos
		if IsValid(sndtbl.Entity) then
			pos = sndtbl.Entity:WorldSpaceCenter()
		end
		if pos == nil then return end

		for _,ply in pairs(ents.FindInSphere(pos,tbl.range)) do
			if ply:IsPlayer() then
				net.Start("subtitle_msg")
				net.WriteTable(tbl)
				net.Send(ply)
			end
		end
	else
		if sndtbl.Pos ~= nil then
			if sndtbl.Pos:Distance(LocalPlayer():WorldSpaceCenter()) < tbl.range then
				Subtitles_Create(tbl)
			end
		else
			Subtitles_Create(tbl)
		end
	end
end

function CreateSubtitleFromTable(tbl)
	if tbl == nil then return true end
	
	local snd = string.lower(tbl.SoundName) -- garry didnt add client support :/

	for _,vtbl in pairs(Subtitles_Table) do
		--local tbl2 = vtbl[k]
		
		for k,v in pairs(vtbl) do
			local tbl2 = v[k]
			
			if v ~= nil and v.snd ~= nil then
				if string.lower(v.snd) == snd then -- just in case
					SendSubtitle(v,tbl)
					return
				end
			end
		end
	end

	local cc_string = ""
	local cc_col = Color(255,255,255,255)
	local cc_dur = 3
	local cc_range = 350
	local cc_toggle = true
	if snd:find("explosion") or snd:find("explode") then
		cc_string = "*EXPLOSION*"
		cc_col = Color(255,25,25,255)
		cc_dur = 5
		cc_range = 2048
	elseif snd:find("ignite") then
		cc_string = "*Fire Ignition*"
		cc_col = Color(255,150,25,255)
		cc_dur = 2
	elseif snd:find("splash") then
		cc_string = "*Splash*"
		cc_dur = 2
	elseif snd:find("steamburst") or snd:find("steam_release") then
		cc_string = "[Steam burst]"
		cc_dur = 2
		cc_range = 300
	--elseif snd:find("button2") or snd:find("button8") or snd:find("button10") or snd:find("button11") then
		--cc_string = "[Button Denied]"
	elseif snd:find("button") then
		cc_string = "[Button Press]"
	elseif snd:find("latchlocked") then
		cc_string = "*Locked*"
		cc_range = 300
	elseif snd:find("lever") then
		cc_string = "[Lever Noise]"
	elseif snd:find("latch") or snd:find("pushbar") or snd:find("medium_open") or snd:find("medium_close") then
		cc_string = "[Door Noise]"
	elseif snd:find("ammo_close") then
		cc_string = "[Crate Noise]"
	elseif snd:find("medshot") or snd:find("medkit") then
		cc_string = "*Medkit Used*"
		cc_col = Color(25,255,25,255)
		cc_dur = 2
	elseif snd:find("battery_pickup") then
		cc_string = "*Battery picked up*"
		cc_col = Color(25,255,255,255)
		cc_dur = 2
	elseif snd:find("ammo_pickup") then
		cc_string = "*Ammo picked up*"
		cc_dur = 2
	elseif snd:find("grenade/tick") then
		cc_string = "*Grenade ticking*"
		cc_col = Color(255,25,25,255)
		cc_dur = 2
	elseif snd:find("mega_mob_incoming") then
		cc_string = "[Incoming attack!]"
		cc_col = Color(255,200,100,255)
		cc_dur = 4
		cc_toggle = false
	else
		return
	end
	
	SendSubtitle({
		snd = "common/null.wav", 
		subject = "", 
		text = cc_string, 
		range = cc_range, 
		duration = cc_dur, 
		closedcaption = cc_toggle, 
		subjectcol = Color(255,255,255,255), 
		textcol = cc_col
	},tbl)
end

hook.Add( "EntityEmitSound", "Subtitles", function( tbl )
	CreateSubtitleFromTable(tbl)
end )

local function Subtitles_Initialize()
	local files, folders = file.Find(Subtitles_Path.."*","LUA")
	for k, v in pairs(files) do

		if SERVER then
			include(Subtitles_Path..v)
			AddCSLuaFile(Subtitles_Path..v)
		elseif CLIENT then
			include(Subtitles_Path..v)
		end
	end

	--if CLIENT then PrintTable(Subtitles_Table) end
end
Subtitles_Initialize()
hook.Add("InitPostEntity","Subtitles_Initialize",Subtitles_Initialize)

concommand.Add( "subtitles_reload", function( ply, cmd, args )
	Subtitles_Table = {}
	Subtitles_Initialize()
end )

if CLIENT then
	CreateClientConVar("subtitles_height", "40", true, false, "Distance from bottom of screen")
	CreateClientConVar("subtitles_closedcaptions", "0", true, false, "Display world sound effects in text")
	concommand.Add( "subtitles_test", function( ply, cmd, args )
		Subtitles_Create({
			snd = "common/null.wav", 
			subject = "Unknown creature", 
			text = "*distant howling*", 
			range = 512, 
			duration = 3, 
			closedcaption = false, 
			subjectcol = Color(255,255,255,255), 
			textcol = Color(255,255,255,255)
		})
		
		Subtitles_Create({
			snd = "common/null.wav", 
			subject = "World", 
			text = "Null", 
			range = 512, 
			duration = 3, 
			closedcaption = false, 
			subjectcol = Color(255,255,255,255), 
			textcol = Color(255,255,255,255)
		})
		Subtitles_Create({
			snd = "common/null.wav", 
			subject = "", 
			text = "*EXPLOSION*", 
			range = 512, 
			duration = 4, 
			closedcaption = true, 
			subjectcol = Color(255,255,255,255), 
			textcol = Color(255,25,25,255)
		})
		Subtitles_Create({
			snd = "common/null.wav", 
			subject = "G-Man:", 
			text = "Doctorrr freeeemaaaan \nSeems like you only just arrived", 
			range = 512, 
			duration = 5, 
			closedcaption = false, 
			subjectcol = Color(25,25,255,255), 
			textcol = Color(255,255,255,255)
		})
		Subtitles_Create({
			snd = "common/null.wav", 
			subject = "M4-Sopmod II:", 
			text = "*japanese talk* Shkikan *japanese talk*", 
			range = 512, 
			duration = 5, 
			closedcaption = false, 
			subjectcol = Color(25,255,25,255), 
			textcol = Color(255,255,255,255)
		})
	end )

	net.Receive("subtitle_msg", function(len, ply)
		local tbl = net.ReadTable()
		
		Subtitles_Create(tbl)
	end)
	
	local Subtitles_CurTable = {}
	
	function Subtitles_Create(tbl2)
		if tbl2.closedcaption == true and !tobool(GetConVar("subtitles_closedcaptions"):GetInt()) then return end
		for _,v in pairs(Subtitles_CurTable) do
			if v.text == tbl2.text then return end
		end
		
		if table.Count(Subtitles_CurTable) < 15 then
			table.insert(Subtitles_CurTable,tbl2)
			timer.Simple(tbl2.duration,function()
				table.RemoveByValue( Subtitles_CurTable, tbl2)
			end)
		else
			table.remove(Subtitles_CurTable, 15 )
		end
	end
	
	hook.Add("HUDPaint", "Subtitles_Hud", function()
		local w = ScrW()
		local h = ScrH()
		
		local derp = -GetConVar("subtitles_height"):GetInt()
		local spacing
		
		for k,tbl in pairs(table.Reverse(Subtitles_CurTable)) do
			k = k - 1
			local oursubject = tostring(tbl.subject)
			local ourtext = tostring(tbl.text)
			local textheight = 35
			local newline = ""
			
			if k == 1 then
				spacing = 0
			end
			
			--bootleg line break support
			if ourtext:find("\n") then
				for k,v in pairs(string.Split(ourtext,"\n")) do
					if k == 1 then
						ourtext = v
					elseif k == 2 then
						newline = v
						spacing = 1
					end
				end
			end

			if spacing ~= 0 then
				textheight = 60
			end
			
			surface.SetFont( "CloseCaption_Normal" )
			local textw, texth = surface.GetTextSize(tostring(tbl.text))
			
			surface.SetFont( "CloseCaption_Bold" )
			local textw2, texth2 = surface.GetTextSize(tostring(tbl.subject).." ")
			
			surface.SetTextColor( tbl.subjectcol )
			surface.SetTextPos( w/2 - (textw + textw2)/2, h/1.1 + derp - k*textheight ) 
			surface.DrawText(oursubject.." ")
			
			surface.SetFont( "CloseCaption_Normal" )
			surface.SetTextColor( tbl.textcol )
			surface.SetTextPos( w/2 - (textw + textw2)/2 + textw2, h/1.1 + derp - k*textheight ) 
			surface.DrawText(ourtext)
			
			local boxposw = w/2 - 5 - (textw + textw2)/2
			local boxposh = h/1.1 + derp - k*textheight - 5
			local boxw = textw + 10 + textw2
			local boxh = texth + 10
				
			surface.SetDrawColor( 25, 25, 25, 200 )
			surface.DrawRect( boxposw, boxposh, boxw, boxh )
			
			--draw this crap again
			surface.SetFont( "CloseCaption_Bold" )
			surface.SetTextColor( tbl.subjectcol )
			surface.SetTextPos( w/2 - (textw + textw2)/2, h/1.1 + derp - k*textheight ) 
			surface.DrawText(oursubject.." ")
			
			surface.SetFont( "CloseCaption_Normal" )
			surface.SetTextColor( tbl.textcol )
			surface.SetTextPos( w/2 - (textw + textw2)/2 + textw2, h/1.1 + derp - k*textheight ) 
			surface.DrawText(ourtext)

			--repeat this for line break
			if newline then
				--textheight = 35
				surface.SetFont( "CloseCaption_Normal" )
				surface.SetTextColor( tbl.textcol )
				surface.SetTextPos( w/2 - (textw + textw2)/2 + textw2, h/1.1 + derp - k*textheight+25 ) 
				surface.DrawText(newline)
			end

			surface.SetDrawColor( 255, 255, 255, 200 )
			surface.DrawOutlinedRect( boxposw, boxposh, boxw, boxh )
		end
	end )
end