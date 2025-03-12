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
    local encodedText = UrlEncode(text)

    local url = "http://124.222.73.18:8300/tts?text=" .. encodedText

    http.Fetch(url, function(response)
        -- 解析返回的 JSON 响应
        local data = util.JSONToTable(response)
        if data and data.audio_url then
            sound.PlayURL(data.audio_url, "mono", function(station)
                if IsValid(station) then
                    station:SetPos(npc:GetPos())
                    station:SetVolume(5.0)
                    station:Play()
                end
            end)
        else
            print("Failed to get audio URL.")
        end
    end, function(error)
        -- 错误处理
        print("HTTP request failed: " .. error)
    end)
end