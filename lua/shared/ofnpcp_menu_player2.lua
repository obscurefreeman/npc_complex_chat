CreateClientConVar("of_garrylord_player2_device", "", true, true)
CreateClientConVar("of_garrylord_player2_tts", "0", true, true, "", 0, 1)

local PLAYER2API
local userLang_voices = {}

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

	local player2Label = OFNPCPCreateControl(player2Menu, "OFTextLabel", {
		SetText = GetConVar("of_garrylord_player2_device"):GetString() == "" 
			and ofTranslate("ui.player2.login_status_disconnected")
			or ofTranslate("ui.player2.login_status_connected")
	})

	-- 创建设备码输入框
	local deviceCodeEntry = OFNPCPCreateControl(player2Menu, "OFTextEntry", {
		SetValue = GetConVar("of_garrylord_player2_device"):GetString() or "",
		SetPlaceholderText = ofTranslate("ui.player2.get_device_key_entry")
	})

	local getDeviceKeyButton = OFNPCPCreateControl(player2Menu, "OFButton", {
		SetText = GetConVar("of_garrylord_player2_device"):GetString() == "" 
			and ofTranslate("ui.player2.get_device_key")
			or ofTranslate("ui.player2.get_device_key_re")
	})

	-- 创建API输入框
	local apiCodeEntry = OFNPCPCreateControl(player2Menu, "OFTextEntry", {
		SetValue = aiSettings.player2 and aiSettings.player2.key or "",
		SetPlaceholderText = ofTranslate("ui.player2.get_api_entry")
	})

	local getapiButton = OFNPCPCreateControl(player2Menu, "OFButton", {
		SetText = (aiSettings.player2 and aiSettings.player2.key and aiSettings.player2.key ~= "") and ofTranslate("ui.player2.get_api_re") or ofTranslate("ui.player2.get_api"),
		SetEnabled = not (aiSettings.player2 and aiSettings.player2.key and aiSettings.player2.key ~= "")
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
					if IsValid(getDeviceKeyButton) then
						getDeviceKeyButton:SetText(ofTranslate("ui.player2.get_device_key_re"))
					end
					-- 清空API设置
					aiSettings.player2.key = ""
					if IsValid(apiCodeEntry) then
						apiCodeEntry:SetValue("")
					end
					if IsValid(getapiButton) then
						getapiButton:SetEnabled(true)
						getapiButton:SetText(ofTranslate("ui.player2.get_api"))
					end
					save_settings()
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
					if IsValid(getapiButton) then
						getapiButton:SetEnabled(false)
						getapiButton:SetText(ofTranslate("ui.player2.get_api_re"))
					end
					
					aiSettings.player2.key = responseData.p2Key
					save_settings()
					PLAYER2API = responseData.p2Key
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

	getDeviceKeyButton.DoClick = function()
		OFNPCP_Player2AuthDevice()
	end

	getapiButton.DoClick = function()
		OFNPCP_Player2AuthAPI()
	end

	local voiceCheckPanel = vgui.Create("EditablePanel", player2Menu)
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
end


hook.Add("OnNPCTalkStart", "PlayNPCDialogTTSPlayer2", function(npc, text)
    if not IsValid(npc) or GetConVar("of_garrylord_player2_tts"):GetInt() == 0 then return end

    -- 获取NPC列表并检查NPC身份信息是否存在
    local gender = "male"
    
    if npc:IsNPC() then
        local npcs = GetAllNPCsList()
        local npcIdentity = npcs and npcs[npc:EntIndex()] or {}
        if npcIdentity.gender then
            gender = npcIdentity.gender
        end
    end

    if not PLAYER2API or PLAYER2API == "" then
        PLAYER2API = OFNPCP_Player2GetAPI()
        if not PLAYER2API or PLAYER2API == "" then return end
    end

    if not userLang_voices or #userLang_voices == 0 then
        OFNPCP_Player2InitializeTTS()
        return
    end
    -- 获取符合性别的语音ID
    local voiceIds = {}
    for _, voice in ipairs(userLang_voices) do
        if voice.gender == gender and #voiceIds < 2 then
            table.insert(voiceIds, voice.id)
        end
    end

    -- 在客户端处理HTTP请求
    local requestBody = {
        text = text,
        speed = 1,
        audio_format = "mp3",
        voice_ids = voiceIds,
        voice_gender = gender
    }

    HTTP({
        url = "https://api.player2.game/v1/tts/speak",
        type = "application/json",
        method = "post",
        headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. PLAYER2API
        },
        body = util.TableToJSON(requestBody),
        
        success = function(code, body, headers)
            local response = util.JSONToTable(body)
            -- print("[Player2 TTS] Voices:")
            -- PrintTable(userLang_voices)
            -- print("[Player2 TTS] RequestBody:")
            -- PrintTable(requestBody)
            -- print("[Player2 TTS] Response:")
            -- PrintTable(response)

            if response and response.data then
                -- 去除data:audio/mp3;base64,前缀
                local base64Data = string.sub(response.data, string.len("data:audio/mp3;base64,") + 1)
                local binaryData = util.Base64Decode(base64Data)

                -- print("[Player2 TTS] Response") 
                -- print(base64Data)
                
                -- 将二进制数据保存为临时mp3文件
                local tempFileName = "of_npcp_tts/tts_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".mp3"
                file.Write(tempFileName, binaryData)
                
                -- 播放音频文件
                sound.PlayFile("data/"..tempFileName, "3d noplay", function(station, err, errName)
                    if IsValid(station) then
                        if IsValid(npc) then
                            -- 将声音绑定到NPC位置
                            station:SetPos(npc:GetPos())
                            station:Play()
                            
                            -- 删除临时文件
                            timer.Simple(60, function()
                                if IsValid(station) then
                                    station:Stop()
                                end
                                file.Delete(tempFileName)
                            end)
                        else
                            station:Stop()
                            file.Delete(tempFileName)
                        end
                    else
                        file.Delete(tempFileName)
                    end
                end)
            end
        end
    })
end)

-- 根据用户语言筛选语音
local function FilterVoicesByLanguage(voicesTable)
    if not voicesTable then return {} end

    local userLang = GetConVar("of_garrylord_language"):GetString()
    userLang = userLang ~= "" and userLang or GetConVar("gmod_language"):GetString()
    
    -- 语言映射表
    local langMap = {
        ["zh-CN"] = "mandarin_chinese",
        ["zh-TW"] = "mandarin_chinese",
    }
    
    local targetLang = langMap[userLang] or "american_english"
    local filteredVoices = {}
    
    for _, voice in ipairs(voicesTable) do
        if voice.language == targetLang then
            table.insert(filteredVoices, voice)
        end
    end
    
    return filteredVoices
end

-- 定义一个独立的函数来初始化TTS系统
function OFNPCP_Player2InitializeTTS()
    -- 检查并创建必要的目录
    if not file.IsDir("of_npcp_tts", "DATA") then
        file.CreateDir("of_npcp_tts")
    end
    
    -- 清理旧的临时文件
    local files, _ = file.Find("of_npcp_tts/*.mp3", "DATA")
    for _, filename in ipairs(files) do
        file.Delete("of_npcp_tts/" .. filename)
    end

    HTTP({
        url = "https://api.player2.game/v1/tts/voices",
        type = "application/json",
        method = "get",
        headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. PLAYER2API
        },
        
        success = function(code, body, headers)
            local response = util.JSONToTable(body)
            if response and response.voices then
                userLang_voices = FilterVoicesByLanguage(response.voices)
            end
        end
    })
end

-- 获取Player2 API的函数
function OFNPCP_Player2GetAPI()
    -- 确保文件存在
    if not file.Exists("of_npcp/ai_settings.txt", "DATA") then return "" end

    local aiSettings = file.Read("of_npcp/ai_settings.txt", "DATA")
    if aiSettings then
        aiSettings = util.JSONToTable(aiSettings)
        if aiSettings and aiSettings.player2 then
            return aiSettings.player2.key or ""
        end
    end
    return ""
end

-- 健康查询放这里啦

timer.Create("OFNPCP_Player2_HealthCheck", 60, 0, function()
    if GetConVar("of_garrylord_provider"):GetString() ~= "player2" then return end
    
    -- 如果没有PLAYER2API，则尝试获取
    if not PLAYER2API or PLAYER2API == "" then
        PLAYER2API = OFNPCP_Player2GetAPI()
        if not PLAYER2API or PLAYER2API == "" then return end
    end

    HTTP({
        url = "https://api.player2.game/v1/health",
        type = "application/json",
        method = "get",
        headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["Authorization"] = "Bearer " .. PLAYER2API
        }
    })
end)
