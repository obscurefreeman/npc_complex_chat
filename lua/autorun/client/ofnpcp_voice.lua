-- 添加客户端ConVar
CreateClientConVar("of_garrylord_voice", "0", true, true, "", 0, 1)
CreateClientConVar("of_garrylord_player2_tts", "0", true, true, "", 0, 1)

local PLAYER2API
local userLang_voices = {}

-- 自定义URL编码函数
local function UrlEncode(str)
    if (str) then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w%-%_%.%~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

hook.Add("OnNPCTalkStart", "PlayNPCDialogVoice", function(npc, text)
    if not IsValid(npc) or GetConVar("of_garrylord_voice"):GetInt() == 0 then return end

    -- 获取NPC列表并检查NPC身份信息是否存在
    local npcs = GetAllNPCsList()
    local npcIdentity = npcs and npcs[npc:EntIndex()] or {}

    -- 使用默认语音编码作为后备
    local voiceCode = "zh-CN-XiaoyiNeural"
    
    -- 如果是玩家，使用玩家的配音设置
    if npc:IsPlayer() then
        local playerVoice = OFPLAYERS[npc:SteamID()] and OFPLAYERS[npc:SteamID()].voice
        if playerVoice then
            voiceCode = playerVoice
        end
    elseif npcIdentity and npcIdentity.voice then
        voiceCode = npcIdentity.voice
    end

    -- 读取本地保存的配音设置
    local voiceSettings = file.Read("of_npcp/personalization_settings.txt", "DATA")
    if voiceSettings then
        voiceSettings = util.JSONToTable(voiceSettings)
    else return end

    local encodedText = UrlEncode(text)
    local url = voiceSettings.api_url .. "?text=" .. encodedText .. "&voiceName=" .. voiceCode ..
                "&contentType=" .. UrlEncode("text/plain") ..
                "&format=" .. UrlEncode("audio-24khz-48kbitrate-mono-mp3")


    sound.PlayURL(url, "3d", function(station, err, errName)
        if IsValid(station) then
            -- 调试信息：显示音频播放信息
            if IsValid(npc) then
                station:SetVolume(voiceSettings.volume)  -- 使用保存的音量设置
                station:Play()

                hook.Add("Think", "FollowNPCSound", function()
                    if IsValid(station) and IsValid(npc) then
                        station:SetPos(npc:GetPos())
                    end
                end)

                timer.Simple(station:GetLength(), function()
                    hook.Remove("Think", "FollowNPCSound")
                end)
            -- else
            --     print("[ERROR] NPC entity is invalid, cannot play audio")
            end
        -- else
        --     print("[GarryLord] Failed to play URL: " .. (err or "unknown error") .. " (" .. (errName or "unknown") .. ")")
        end
    end)
end)

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
        
        -- success = function(code, body, headers)
        --     local response = util.JSONToTable(body)
        --     if response then
        --         print(PLAYER2API)
        --     end
        -- end
    })
end)
