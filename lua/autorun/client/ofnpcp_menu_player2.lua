-- CreateClientConVar("of_garrylord_player2_enable", "0", true, true, "", 0, 1)

function OFNPCP_SetUpPlayer2Menu(player2Menu)
	local player2Panel = vgui.Create("OFScrollPanel", player2Menu)
	player2Panel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	player2Panel:Dock(FILL)

	local function device_flow()
		-- 常量定义
		local CLIENT_ID = "0198804b-941a-71e0-8b49-37e15b1b2dd8"
		local API_BASE_URL = "https://api.player2.game/v1"

		-- 显示进度通知
		notification.AddProgress("Player2AuthDevice", "正在获取设备码")

		-- 辅助函数：处理错误
		local function handle_error(err, msg)
			notification.AddLegacy(msg .. (err or ""), NOTIFY_ERROR, 5)
			notification.Kill("Player2AuthDevice")
			notification.Kill("Player2AuthAPI")
		end

		-- 辅助函数：保存API设置
		local function save_api_settings(p2Key)
			-- 确保目录存在
			if not file.IsDir("of_npcp", "DATA") then
				file.CreateDir("of_npcp")
			end

			-- 读取现有设置
			local aiSettings = {}
			local rawSettings = file.Read("of_npcp/ai_settings.txt", "DATA")
			if rawSettings then
				aiSettings = util.JSONToTable(rawSettings) or {}
			end

			-- 更新Player2设置
			aiSettings["player2"] = {
				url = API_BASE_URL,
				key = p2Key,
				model = "player2",
				temperature = 1,
				max_tokens = 500
			}

			-- 保存设置
			file.Write("of_npcp/ai_settings.txt", util.TableToJSON(aiSettings))
			RunConsoleCommand("of_garrylord_provider", "player2")
		end

		-- 第一步：获取设备码
		HTTP({
			url = API_BASE_URL .. "/login/device/new",
			type = "application/json",
			method = "post",
			body = util.TableToJSON({client_id = CLIENT_ID}),
			
			success = function(code, body, headers)
				notification.Kill("Player2AuthDevice")
				local responseData = util.JSONToTable(body)
				
				if responseData.error_description then
					notification.AddLegacy("获取设备码失败：" .. responseData.error_description, NOTIFY_ERROR, 5)
				elseif responseData.deviceCode then
					notification.AddLegacy("获取设备码成功", NOTIFY_GENERIC, 5)

					notification.AddProgress("Player2AuthAPI", "正在获取免费Player2 API")

					-- 第二步：使用设备码获取API Key
					HTTP({
						url = API_BASE_URL .. "/login/device/token",
						type = "application/json",
						method = "post",
						body = util.TableToJSON({
							client_id = CLIENT_ID,
							device_code = responseData.deviceCode,
							grant_type = 'urn:ietf:params:oauth:grant-type:device_code'
						}),
						
						success = function(code, body, headers)
							notification.Kill("Player2AuthAPI")
							local responseData = util.JSONToTable(body)
							
							if responseData.error_description then
								notification.AddLegacy("获取API失败：" .. responseData.error_description, NOTIFY_ERROR, 5)
							elseif responseData.p2Key then
								notification.AddLegacy("获取API成功，PLAYER2API已保存到本地，您现在可以使用它了", NOTIFY_GENERIC, 5)
								save_api_settings(responseData.p2Key)
							else
								notification.AddLegacy("获取API失败，未知错误", NOTIFY_ERROR, 5)
							end
						end,
						
						failed = function(err)
							notification.AddLegacy("获取API失败：" .. err, NOTIFY_ERROR, 5)
							notification.Kill("Player2AuthAPI")
						end
					})
				else
					notification.AddLegacy("获取设备码失败，未知错误", NOTIFY_ERROR, 5)
					notification.Kill("Player2AuthAPI")
				end
			end,
			
			failed = function(err)
				notification.AddLegacy("获取API失败：" .. err, NOTIFY_ERROR, 5)
				notification.Kill("Player2AuthDevice")
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