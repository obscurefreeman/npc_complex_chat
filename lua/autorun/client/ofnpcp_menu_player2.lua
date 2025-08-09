-- CreateClientConVar("of_garrylord_player2_enable", "0", true, true, "", 0, 1)

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
			model = "player2",
			temperature = 1,
			max_tokens = 500,
			device = ""
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

	-- 创建设备码输入框
	local deviceCodeEntry = OFNPCPCreateControl(player2Panel, "OFTextEntry", {
		SetValue = aiSettings.player2 and aiSettings.player2.device or "",
		SetPlaceholderText = "Player2 设备码"
	})

	local function OFNPCP_Player2AuthDevice()
		-- 显示进度通知
		notification.AddProgress("Player2AuthDevice", "正在获取设备码")

		HTTP({
			url = API_BASE_URL .. "/login/device/new",
			type = "application/json",
			method = "post",
			body = util.TableToJSON({client_id = CLIENT_ID}),
			
			success = function(code, body, headers)
				notification.Kill("Player2AuthDevice")
				local responseData = util.JSONToTable(body)
				
				if responseData.error_description then
					notification.AddLegacy("申请设备码失败：" .. responseData.error_description, NOTIFY_ERROR, 5)
				elseif responseData.deviceCode then
					notification.AddLegacy("申请设备码成功", NOTIFY_GENERIC, 5)
					deviceCodeEntry:SetValue(responseData.deviceCode)  -- 将设备码显示在输入框中
					aiSettings.player2.device = responseData.deviceCode
					save_settings()
				else
					notification.AddLegacy("申请设备码失败：" .. "Unknown", NOTIFY_ERROR, 5)
				end
			end,
			
			failed = function(err)
				notification.AddLegacy("申请设备码失败：" .. err, NOTIFY_ERROR, 5)
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
		notification.AddProgress("Player2AuthAPI", "正在获取API")

		HTTP({
			url = API_BASE_URL .. "/login/device/token",
			type = "application/json",
			method = "post",
			body = util.TableToJSON({
				client_id = CLIENT_ID,
				device_code = aiSettings.player2 and aiSettings.player2.device or "",
				grant_type = 'urn:ietf:params:oauth:grant-type:device_code'
			}),
			
			success = function(code, body, headers)
				notification.Kill("Player2AuthAPI")
				local responseData = util.JSONToTable(body)

				print("Response Table:")
				PrintTable(responseData)
				PrintTable(aiSettings.player2)
				
				if responseData.error_description then
					notification.AddLegacy("获取API失败：" .. responseData.error_description, NOTIFY_ERROR, 5)
				elseif responseData.p2Key then
					notification.AddLegacy("获取API成功，PLAYER2API已保存到本地，您现在可以使用它了", NOTIFY_GENERIC, 5)
					aiSettings.player2.device = responseData.p2Key
					save_settings()
				else
					notification.AddLegacy("获取API失败：" .. "Unknown", NOTIFY_ERROR, 5)
				end
			end,
			
			failed = function(err)
				notification.AddLegacy("获取API失败：" .. err, NOTIFY_ERROR, 5)
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
end