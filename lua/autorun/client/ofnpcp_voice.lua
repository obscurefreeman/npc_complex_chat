-- 添加客户端ConVar
CreateClientConVar("of_garrylord_voice", "0", true, true, "", 0, 1)
CreateClientConVar("of_garrylord_player2_tts", "0", true, true, "", 0, 1)

local PLAYER2API = "p2_APvDS1-2M-YVPS6Rovb48g"
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

    if not userLang_voices or #userLang_voices == 0 then
        OFPlayer2InitializeTTS()
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
function OFPlayer2InitializeTTS()
    -- 检查并创建必要的目录
    if not file.IsDir("of_npcp_tts", "DATA") then
        file.CreateDir("of_npcp_tts")
    end
    
    -- 清理旧的临时文件
    local files, _ = file.Find("of_npcp_tts/*.mp3", "DATA")
    for _, filename in ipairs(files) do
        file.Delete("of_npcp_tts/" .. filename)
    end

    local available_voices = {
        {gender = "female", id = "01955d76-ed5b-73e0-a88d-cbeb3c5b499d", language = "american_english", name = "Sophia"},
        {gender = "female", id = "01955d76-ed5b-7407-a03c-cdd993439ba4", language = "american_english", name = "Madison"},
        {gender = "female", id = "01955d76-ed5b-7416-82d8-5fc486e2f676", language = "american_english", name = "Harper"},
        {gender = "female", id = "01955d76-ed5b-7426-8748-4b0e5aea1974", language = "american_english", name = "Olivia"},
        {gender = "female", id = "01955d76-ed5b-7436-a182-c4d21aaca9fc", language = "american_english", name = "Ava"},
        {gender = "female", id = "01955d76-ed5b-7441-a184-5f5ee015e4fe", language = "american_english", name = "Amelia"},
        {gender = "female", id = "01955d76-ed5b-7451-92d6-5ef579d3ed28", language = "american_english", name = "Charlotte"},
        {gender = "female", id = "01955d76-ed5b-745d-add1-b755d440192d", language = "american_english", name = "Evelyn"},
        {gender = "female", id = "01955d76-ed5b-7468-83a7-bfc267cf4849", language = "american_english", name = "Abigail"},
        {gender = "female", id = "01955d76-ed5b-7474-86b2-a41b310c2a2d", language = "american_english", name = "Mia"},
        {gender = "female", id = "01955d76-ed5b-7480-951c-af1dd9873e34", language = "american_english", name = "Chloe"},
        {gender = "male", id = "01955d76-ed5b-748c-8d98-0fb708ef0fbd", language = "american_english", name = "Ethan"},
        {gender = "male", id = "01955d76-ed5b-7497-9f8e-0e7448515bf3", language = "american_english", name = "Noah"},
        {gender = "male", id = "01955d76-ed5b-74a3-9129-c3253d01f690", language = "american_english", name = "Mason"},
        {gender = "male", id = "01955d76-ed5b-74af-a2be-9302077075b8", language = "american_english", name = "Logan"},
        {gender = "male", id = "01955d76-ed5b-74ba-89e5-2b4b45e632cd", language = "american_english", name = "Benjamin"},
        {gender = "male", id = "01955d76-ed5b-74c6-ac15-ab68ee19d560", language = "american_english", name = "Lucas"},
        {gender = "male", id = "01955d76-ed5b-74d2-a33c-b2b8e998658f", language = "american_english", name = "Jackson"},
        {gender = "male", id = "01955d76-ed5b-74de-83e5-800a44fee0d1", language = "american_english", name = "Caleb"},
        {gender = "male", id = "01955d76-ed5b-74e9-9fea-1f8cad1cd9c5", language = "american_english", name = "Nicholas"},
        {gender = "female", id = "01955d76-ed5b-74f9-b54a-2d051890468d", language = "british_english", name = "Eleanor"},
        {gender = "female", id = "01955d76-ed5b-751c-b341-0ee85dbefd92", language = "british_english", name = "Poppy"},
        {gender = "female", id = "01955d76-ed5b-7528-86ee-3348a642af7e", language = "british_english", name = "Florence"},
        {gender = "female", id = "01955d76-ed5b-7534-b7a6-028adcfb4e7d", language = "british_english", name = "Amelia"},
        {gender = "male", id = "01955d76-ed5b-753f-9f74-c0674216f0f5", language = "british_english", name = "Oliver"},
        {gender = "male", id = "01955d76-ed5b-754f-a070-a570ddfed516", language = "british_english", name = "Harry"},
        {gender = "male", id = "01955d76-ed5b-755b-9b43-890d73586908", language = "british_english", name = "William"},
        {gender = "male", id = "01955d76-ed5b-7566-9c0e-bce4d88ceba0", language = "british_english", name = "Charles"},
        {gender = "female", id = "01955d76-ed5b-757a-9bdb-94fa0a2b7893", language = "japanese", name = "Sakura"},
        {gender = "female", id = "01955d76-ed5b-7591-9d3f-f919ac645bb6", language = "japanese", name = "Akari"},
        {gender = "female", id = "01955d76-ed5b-75a1-96f8-7a82e767e2c4", language = "japanese", name = "Yuki"},
        {gender = "female", id = "01955d76-ed5b-75ad-afe3-ac5eb3d0a16e", language = "japanese", name = "Hana"},
        {gender = "male", id = "01955d76-ed5b-75b8-b70f-dfaf400b7c42", language = "japanese", name = "Takashi"},
        {gender = "female", id = "01955d76-ed5b-75c8-8386-b83ff9c45856", language = "mandarin_chinese", name = "Mei"},
        {gender = "female", id = "01955d76-ed5b-75d4-8338-3d7108137cd1", language = "mandarin_chinese", name = "Ling"},
        {gender = "female", id = "01955d76-ed5b-75df-8ca5-a6f84acaff76", language = "mandarin_chinese", name = "Jingyi"},
        {gender = "female", id = "01955d76-ed5b-75eb-b509-e7bf29b3b530", language = "mandarin_chinese", name = "Qiuyue"},
        {gender = "male", id = "01955d76-ed5b-75fb-87dd-ebbed25d2585", language = "mandarin_chinese", name = "Wei"},
        {gender = "male", id = "01955d76-ed5b-7606-9e21-8b236fbe12a8", language = "mandarin_chinese", name = "Liang"},
        {gender = "male", id = "01955d76-ed5b-7612-bf44-f7bdcc808356", language = "mandarin_chinese", name = "Ming"},
        {gender = "male", id = "01955d76-ed5b-761e-abac-1956f66ac089", language = "mandarin_chinese", name = "Hao"},
        {gender = "female", id = "01955d76-ed5b-762a-9a2a-0fec3b7ace8b", language = "spanish", name = "Carmen"},
        {gender = "male", id = "01955d76-ed5b-7649-ac1e-c56a13c3302f", language = "spanish", name = "Miguel"},
        {gender = "male", id = "01955d76-ed5b-7655-98bb-fd7578af9617", language = "spanish", name = "Javier"},
        {gender = "female", id = "01955d76-ed5b-7668-877b-2fa240c1d5ee", language = "french", name = "Sophie"},
        {gender = "female", id = "01955d76-ed5b-7678-b678-3ddc5ec8b5c4", language = "hindi", name = "Priya"},
        {gender = "female", id = "01955d76-ed5b-7683-a79d-253390189fdb", language = "hindi", name = "Aditi"},
        {gender = "male", id = "01955d76-ed5b-768f-9e5b-8bcc89ba8f3d", language = "hindi", name = "Arjun"},
        {gender = "male", id = "01955d76-ed5b-769b-bd00-002a8e88dc65", language = "hindi", name = "Vikram"},
        {gender = "female", id = "01955d76-ed5b-76ab-bc6b-57cc5dfeaf01", language = "italian", name = "Bianca"},
        {gender = "male", id = "01955d76-ed5b-76ba-898e-c65bd579a334", language = "italian", name = "Marco"},
        {gender = "female", id = "01955d76-ed5b-76c6-8b9e-b713d3f0b866", language = "brazilian_portuguese", name = "Isabela"},
        {gender = "male", id = "01955d76-ed5b-76d2-8f05-b9a34b5f9011", language = "brazilian_portuguese", name = "Gabriel"},
        {gender = "male", id = "01955d76-ed5b-76dd-bef6-37119ea2f99f", language = "brazilian_portuguese", name = "Rafael"}
    }

    userLang_voices = FilterVoicesByLanguage(available_voices)

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