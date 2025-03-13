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

function PlayNPCDialogVoice(npc, text)
    -- 首先检查NPC是否有效
    if not IsValid(npc) then return end

    -- 调试信息：显示NPC和文本信息
    print("[DEBUG] Playing voice for NPC:", npc)
    print("[DEBUG] Text content:", text)

    -- 获取NPC列表并检查NPC身份信息是否存在
    local npcs = GetAllNPCsList()
    local npcIdentity = npcs and npcs[npc:EntIndex()] or {}

    -- 使用默认语音编码作为后备
    local voiceCode = "zh-CN-XiaoyiNeural"
    if npcIdentity and npcIdentity.voice then
        voiceCode = npcIdentity.voice
    end

    -- 读取本地保存的配音设置
    local voiceSettings = file.Read("of_npcp/voice_settings.txt", "DATA")
    if voiceSettings then
        voiceSettings = util.JSONToTable(voiceSettings)
    else
        -- 默认设置
        voiceSettings = {
            volume = 5.0,
            api_url = "https://freetv-mocha.vercel.app/api/aiyue"
        }
    end

    local encodedText = UrlEncode(text)
    local url = voiceSettings.api_url .. "?text=" .. encodedText .. "&voiceName=" .. voiceCode ..
                "&contentType=" .. UrlEncode("text/plain") ..
                "&format=" .. UrlEncode("audio-24khz-48kbitrate-mono-mp3")

    -- 调试信息：显示请求URL
    print("[DEBUG] Request URL:", url)

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
            else
                print("[ERROR] NPC entity is invalid, cannot play audio")
            end
        else
            print("[ERROR] Failed to play URL: " .. (err or "unknown error") .. " (" .. (errName or "unknown") .. ")")
        end
    end)
end