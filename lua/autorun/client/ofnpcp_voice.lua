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

    local encodedText = UrlEncode(text)
    local url = "https://freetv-mocha.vercel.app//api/aiyue?text=" .. encodedText .. "&voiceName=" .. voiceCode ..
                "&contentType=" .. UrlEncode("text/plain") ..
                "&format=" .. UrlEncode("audio-24khz-48kbitrate-mono-mp3")

    -- 调试信息：显示请求URL
    print("[DEBUG] Request URL:", url)

    sound.PlayURL(url, "3d", function(station, err, errName)
        if IsValid(station) then
            -- 调试信息：显示音频播放信息
            if IsValid(npc) then
                print("[DEBUG] Playing audio at position:", npc:GetPos())
                print("[DEBUG] Audio volume set to 5.0")

                station:SetPos(npc:GetPos())
                station:SetVolume(5.0)
                station:Play()
            else
                print("[ERROR] NPC entity is invalid, cannot play audio")
            end
        else
            print("[ERROR] Failed to play URL: " .. (err or "unknown error") .. " (" .. (errName or "unknown") .. ")")
        end
    end)
end