AddCSLuaFile()

if CLIENT then
	
	Subtitles_Table = {}

	CreateClientConVar("subtitles_height", "40", true, false, "Distance from bottom of screen")
	
	local Subtitles_CurTable = {}
	
	function Subtitles_Create(tbl2)
		for _,v in pairs(Subtitles_CurTable) do
			if v.text == tbl2.text then return end
		end
		
		if table.Count(Subtitles_CurTable) < 15 then
			table.insert(Subtitles_CurTable,tbl2)
			timer.Simple( 5 ,function()
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
			local oursubject = tostring(tbl.npc)
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
			local textw2, texth2 = surface.GetTextSize(tostring(tbl.npc).." ")
			
			surface.SetTextColor( tbl.npccol )
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
			surface.SetTextColor( tbl.npccol )
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