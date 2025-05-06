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

-- 添加客户端ConVar
CreateClientConVar("of_garrylord_voice", "0", true, true, "", 0, 1)

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