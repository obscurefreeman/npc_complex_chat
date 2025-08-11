CreateClientConVar("of_garrylord_player2_device", "", true, true)

function OFNPCP_SetUpPlayer2Menu(player2Menu)

	local CLIENT_ID = "0198804b-941a-71e0-8b49-37e15b1b2dd8"
	local API_BASE_URL = "https://api.player2.game/v1"

	-- 读取现有设置
	local aiSettings = {}
	local rawSettings = file.Read("of_npcp/ai_settings.txt", "DATA")
	if rawSettings then
		aiSettings = util.JSONToTable(rawSettings) or {}
	end
	-- 如果不存在Player2设置，则初始化默认设置，暂时不保存，只是呆在这里
	if not aiSettings["player2"] then
		aiSettings["player2"] = {
			url = API_BASE_URL,
			key = "",
			model = "elefant-ai-200b-fp8",
			temperature = 1,
			max_tokens = 500
		}
	end

	-- 辅助函数：保存API设置
	local function save_settings()
		-- 确保目录存在
		if not file.IsDir("of_npcp", "DATA") then
			file.CreateDir("of_npcp")
		end

		-- 保存设置
		file.Write("of_npcp/ai_settings.txt", util.TableToJSON(aiSettings))
		RunConsoleCommand("of_garrylord_provider", "player2")
	end

	local player2Panel = vgui.Create("OFScrollPanel", player2Menu)
	player2Panel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	player2Panel:Dock(FILL)

	local player2Label = OFNPCPCreateControl(player2Panel, "OFTextLabel", {
		SetText = GetConVar("of_garrylord_player2_device"):GetString() == "" 
			and ofTranslate("ui.player2.login_status_disconnected")
			or ofTranslate("ui.player2.login_status_connected")
	})

	-- 创建设备码输入框
	local deviceCodeEntry = OFNPCPCreateControl(player2Panel, "OFTextEntry", {
		SetValue = GetConVar("of_garrylord_player2_device"):GetString() or "",
		SetPlaceholderText = ofTranslate("ui.player2.login_status_disconnected")
	})

	local function OFNPCP_Player2AuthDevice()
		-- 显示进度通知
		notification.AddProgress("Player2AuthDevice", ofTranslate("ui.player2.get_device_key_loading"))

		HTTP({
			url = API_BASE_URL .. "/login/device/new",
			type = "application/json",
			method = "post",
			body = util.TableToJSON({client_id = CLIENT_ID}),
			
			success = function(code, body, headers)
				notification.Kill("Player2AuthDevice")
				local responseData = util.JSONToTable(body)
				
				if responseData.deviceCode then
					notification.AddLegacy(ofTranslate("ui.player2.get_device_key_success"), NOTIFY_GENERIC, 5)
					if IsValid(deviceCodeEntry) then
						deviceCodeEntry:SetValue(responseData.deviceCode)  -- 将设备码显示在输入框中
					end
					gui.OpenURL(responseData.verificationUriComplete)
					RunConsoleCommand("of_garrylord_player2_device", responseData.deviceCode)
				else
					notification.AddLegacy(ofTranslate("ui.player2.get_device_key_fail") .. responseData.error_description or "Unknown", NOTIFY_ERROR, 5)
				end
			end,
			
			failed = function(err)
				notification.AddLegacy(ofTranslate("ui.player2.get_device_key_fail") .. err, NOTIFY_ERROR, 5)
				notification.Kill("Player2AuthDevice")
			end
		})
	end

	local getDeviceKeyButton = OFNPCPCreateControl(player2Panel, "OFButton", {
		SetText = (ofTranslate("ui.player2.get_device_key"))
	})
	getDeviceKeyButton.DoClick = function()
		OFNPCP_Player2AuthDevice()
	end

	-- 创建API输入框
	local apiCodeEntry = OFNPCPCreateControl(player2Panel, "OFTextEntry", {
		SetValue = aiSettings.player2 and aiSettings.player2.key or "",
		SetPlaceholderText = "Player2 API"
	})

	local function OFNPCP_Player2AuthAPI()
		-- 显示进度通知
		notification.AddProgress("Player2AuthAPI", ofTranslate("ui.player2.get_api_loading"))

		HTTP({
			url = API_BASE_URL .. "/login/device/token",
			type = "application/json",
			method = "post",
			body = util.TableToJSON({
				client_id = CLIENT_ID,
				device_code = GetConVar("of_garrylord_player2_device"):GetString() or "",
				grant_type = 'urn:ietf:params:oauth:grant-type:device_code'
			}),
			
			success = function(code, body, headers)
				notification.Kill("Player2AuthAPI")
				local responseData = util.JSONToTable(body)

				-- print("Response Table:")
				-- PrintTable(responseData)
				-- PrintTable(aiSettings.player2)
				
				if responseData.p2Key then
					notification.AddLegacy(ofTranslate("ui.player2.get_api_success"), NOTIFY_GENERIC, 5)
					if IsValid(apiCodeEntry) then
						apiCodeEntry:SetValue(responseData.p2Key)
					end
					
					aiSettings.player2.key = responseData.p2Key
					save_settings()
				else
					notification.AddLegacy(ofTranslate("ui.player2.get_api_fail") .. responseData.error or "Unknown", NOTIFY_ERROR, 5)
				end
			end,
			
			failed = function(err)
				notification.AddLegacy(ofTranslate("ui.player2.get_api_fail") .. err, NOTIFY_ERROR, 5)
				notification.Kill("Player2AuthAPI")
			end
		})
	end

	local getapiButton = OFNPCPCreateControl(player2Panel, "OFButton", {
		SetText = (ofTranslate("ui.player2.get_api"))
	})
	getapiButton.DoClick = function()
		OFNPCP_Player2AuthAPI()
	end

	local voiceCheckPanel = vgui.Create("EditablePanel", player2Panel)
	voiceCheckPanel:Dock(TOP)
	voiceCheckPanel:SetTall(21 * OFGUI.ScreenScale)
	voiceCheckPanel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)

	local voiceCheckBox = vgui.Create("OFCheckBox", voiceCheckPanel)
	voiceCheckBox:Dock(LEFT)
	voiceCheckBox:SetSize(21 * OFGUI.ScreenScale, 21 * OFGUI.ScreenScale)
	voiceCheckBox:DockMargin(0, 0, 8 * OFGUI.ScreenScale, 0)
	voiceCheckBox:SetConVar("of_garrylord_player2_tts")

	local voiceCheckLabel = vgui.Create("OFTextLabel", voiceCheckPanel)
	voiceCheckLabel:SetFont("ofgui_small")
	voiceCheckLabel:Dock(FILL)
	voiceCheckLabel:SetText(ofTranslate("ui.player2.enable_tts"))

	-- local player2VoiceListPanel = vgui.Create("OFListView", player2Panel)
	-- player2VoiceListPanel:AddColumn( "ID" )
	-- player2VoiceListPanel:AddColumn( "Name" )
	-- player2VoiceListPanel:AddColumn( "Language" )
	-- player2VoiceListPanel:AddColumn( "Gender" )
	-- player2VoiceListPanel:Dock(TOP)
	-- player2VoiceListPanel:DockMargin(6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale)
	-- player2VoiceListPanel:SetTall(400 * OFGUI.ScreenScale)

	-- -- 创建获取语音按钮
	-- local getVoicesButton = OFNPCPCreateControl(player2Panel, "OFButton", {
	-- 	SetText = ("获取语音列表")
	-- })
	-- getVoicesButton.DoClick = function()
		
	-- 	-- 发送HTTP请求获取可用语音
	-- 	HTTP({
	-- 		url = "https://api.player2.game/v1/tts/voices",
	-- 		type = "application/json",
	-- 		method = "get",
	-- 		headers = {
	-- 			["Content-Type"] = "application/json",
	-- 			["Authorization"] = "Bearer *********"
	-- 		},
			
	-- 		success = function(code, body, headers)
	-- 			local response = util.JSONToTable(body)
	-- 			if response and response.voices then
	-- 				PrintTable(response.voices)
	-- 				-- 清空列表
	-- 				player2VoiceListPanel:Clear()
					
	-- 				-- 遍历语音列表并添加到面板
	-- 				for _, voice in ipairs(response.voices) do
	-- 					player2VoiceListPanel:AddLine(
	-- 						voice.id,
	-- 						voice.name,
	-- 						voice.language,
	-- 						voice.gender
	-- 					)
	-- 				end
	-- 				notification.AddLegacy("成功获取语音列表", NOTIFY_GENERIC, 5)
	-- 			else
	-- 				notification.AddLegacy("获取语音列表失败", NOTIFY_ERROR, 5)
	-- 			end
	-- 		end,
			
	-- 		failed = function(err)
	-- 			notification.AddLegacy("获取语音列表失败：" .. err, NOTIFY_ERROR, 5)
	-- 		end
	-- 	})
	-- end
end