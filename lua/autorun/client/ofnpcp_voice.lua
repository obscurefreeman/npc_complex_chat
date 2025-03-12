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
    -- 调试信息：显示NPC和文本信息
    print("[DEBUG] Playing voice for NPC:", npc)
    print("[DEBUG] Text content:", text)

    local encodedText = UrlEncode(text)
    local url = "https://garrylord.vercel.app/api/aiyue?text=" .. encodedText .. "&voiceName=zh-CN-XiaoxiaoNeural"

    -- 调试信息：显示请求URL
    print("[DEBUG] Request URL:", url)

    HTTP({
        url = url,
        method = "get",
        headers = {
            ["Authorization"] = "Bearer 123456",
            ["Content-Type"] = "text/plain",
            ["Format"] = "audio-24khz-48kbitrate-mono-mp3"
        },
        success = function(code, body, headers)
			print("success")
            -- 检查响应内容类型是否为音频
            if headers["Content-Type"] == "audio/mpeg" then
                -- 生成唯一文件名
                local uniqueID = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
                local tempFile = "voice/ofnpcp_temp_" .. uniqueID .. ".mp3"
                
                -- 将音频数据保存为临时文件
                file.Write(tempFile, body)
                print("[DEBUG] Audio data saved to: " .. tempFile)
                
                -- 播放音频文件
                sound.PlayFile("data/" .. tempFile, "mono", function(station)
                    if IsValid(station) then
                        -- 调试信息：显示音频播放信息
                        print("[DEBUG] Playing audio at position:", npc:GetPos())
                        print("[DEBUG] Audio volume set to 5.0")

                        station:SetPos(npc:GetPos())
                        station:SetVolume(5.0)
                        station:Play()
                        
                        -- 设置定时器在音频播放后删除临时文件
                        timer.Simple(station:GetLength(), function()
                            if file.Exists(tempFile, "DATA") then
                                file.Delete(tempFile)
                                print("[DEBUG] Deleted temporary file:", tempFile)
                            end
                        end)
                    else
                        print("[DEBUG] Failed to create sound station")
                    end
                end)
            else
                print("[ERROR] Unexpected response content type: " .. (headers["Content-Type"] or "unknown"))
            end
        end,
        failed = function(err)
            print("[ERROR] HTTP request failed: " .. (err or "unknown error"))
            debug.Trace()  -- 添加堆栈跟踪
        end
    })
end