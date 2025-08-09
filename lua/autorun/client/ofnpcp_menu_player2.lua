-- CreateClientConVar("of_garrylord_player2_enable", "0", true, true, "", 0, 1)

function OFNPCP_SetUpPlayer2Menu(player2Menu)
	local player2Panel = vgui.Create("OFScrollPanel", player2Menu)
	player2Panel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	player2Panel:Dock(FILL)

	local function device_flow()
		notification.AddProgress("Player2Auth", "正在获取免费Player2 API")
		local CLIENT_ID = "0198804b-941a-71e0-8b49-37e15b1b2dd8"
		
		HTTP({
			url = 'https://api.player2.game/v1/login/device/new',
			type = "application/json",
			method = "post",
			body = util.TableToJSON({client_id = CLIENT_ID}),
			
			success = function(code, body, headers)
				
				notification.Kill("Player2Auth")
				local responseData = util.JSONToTable(body)
				PrintTable(responseData)
				if responseData.error_description then
					notification.AddLegacy("获取失败：" .. responseData.error_description, NOTIFY_ERROR, 5)
				else	
					notification.AddLegacy("获取成功，PLAYER2API已保存到本地，您现在可以使用它了", NOTIFY_GENERIC, 5)

					-- 创建文件夹，防止小白第一次上来就搞这个
					if not file.IsDir("of_npcp", "DATA") then
						file.CreateDir("of_npcp")
					end

					local aiSettings = {}
					local rawSettings = file.Read("of_npcp/ai_settings.txt", "DATA")
					if rawSettings then
						aiSettings = util.JSONToTable(rawSettings) or {}
					end

					aiSettings["player2"] = {
						url = "https://api.player2.game/v1",
						key = "2222222222",
						model = "player2",
						temperature = 1,
						max_tokens = 500
					}

					-- 保存设置
					file.Write("of_npcp/ai_settings.txt", util.TableToJSON(aiSettings))
					RunConsoleCommand("of_garrylord_provider", "player2")
				end
			end,
			
			failed = function(err)
				notification.AddLegacy("获取失败：" .. err, NOTIFY_ERROR, 5)
				notification.Kill("Player2Auth")
			end
		})
	end

	-- 创建获取API Key的按钮
	local getKeyButton = vgui.Create("OFButton", player2Panel)
	getKeyButton:Dock(TOP)
	getKeyButton:SetTall(40 * OFGUI.ScreenScale)
	getKeyButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	getKeyButton:SetText(ofTranslate("ui.player2.get_key"))
	getKeyButton.DoClick = function()
		device_flow()
	end
end