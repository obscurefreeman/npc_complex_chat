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

    HTTP({
        url = "http://124.222.73.18:8300/tts?text=" .. encodedText,
        method = "get",
        headers = {
            ["Authorization"] = "Bearer "
        },
        success = function(code, body, headers)
            local data = util.JSONToTable(body)
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
        end,
        failed = function(err)
            print("HTTP request failed: " .. (err or "unknown error"))
        end
    })
end