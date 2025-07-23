CreateConVar("of_garrylord_player2_enable", "0", FCVAR_ARCHIVE, "")
CreateConVar("of_garrylord_player2_tts_enable", "0", FCVAR_ARCHIVE, "")

net.Receive("OFNPCP_NS_NPCAIDialog_Player2", function(len, ply)
    if GetConVar("of_garrylord_player2_enable"):GetInt() == 0 then
        NPCTalkManager:StartDialog(npc, ofTranslate("ui.dialog.player2_not_enabled"), "dialogue", ply, true)
        return
    -- elseif not reqwest then
    --     NPCTalkManager:StartDialog(npc, ofTranslate("ui.dialog.no_reqwest"), "dialogue", ply, true)
    --     return
    end

    require("reqwest")

    local npc = net.ReadEntity()
    local aiDialogs = net.ReadTable() or {}

    local requestBody = {
        messages = aiDialogs,
        stream = false
    }

    local function correctFloatToInt(jsonString)
        return string.gsub(jsonString, '(%d+)%.0', '%1')
    end

    reqwest({
        method = "POST",
        url = "http://127.0.0.1:4315",
        timeout = 30,
        body = correctFloatToInt(util.TableToJSON(requestBody)),
        type = "application/json",
        
        success = function(code, body, headers)
            local response = util.JSONToTable(body)
            -- 重要debug代码，如果获得了回应，就会立即将上下文和回复打在控制台里
            if response then
                PrintTable(response)
            end

            PrintTable(requestBody)
            
            if response and response.choices and #response.choices > 0 and response.choices[1].message then
                local responseContent = response.choices[1].message.content
                
                -- 将AI回复发送到服务器
                NPCTalkManager:StartDialog(npc, responseContent, "dialogue", ply, true, response or {})
            elseif response and response.error and response.error.message then
                -- 成功了，但报错
                NPCTalkManager:StartDialog(npc, ofTranslate("ui.dialog.error") .. response.error.message, "dialogue", ply, true)
            else
                -- 成功了，但是回答格式是错误的
                NPCTalkManager:StartDialog(npc, ofTranslate("ui.dialog.invalid_response"), "dialogue", ply, true)
            end
        end,
        
        failed = function(err)
            -- 没有成功，可能没连上网
            NPCTalkManager:StartDialog(npc, ofTranslate("ui.dialog.http_error") .. (err or ofTranslate("ui.dialog.unknown")), "dialogue", ply, true)
        end
    })

    -- HTTP({
    --     url = "http://127.0.0.1:4315",
    --     type = "application/json",
    --     method = "post",
    --     headers = {
    --         ["Content-Type"] = "application/json"
    --     },
    --     body = correctFloatToInt(util.TableToJSON(requestBody)),
        
    --     success = function(code, body, headers)
    --         local response = util.JSONToTable(body)
    --         -- 重要debug代码，如果获得了回应，就会立即将上下文和回复打在控制台里
    --         if aiDialogs and response then
    --             PrintTable(aiDialogs)
    --             PrintTable(response)
    --         end
            
    --         if response and response.choices and #response.choices > 0 and response.choices[1].message then
    --             local responseContent = response.choices[1].message.content
                
    --             -- 将AI回复发送到服务器
    --             NPCTalkManager:StartDialog(npc, responseContent, "dialogue", ply, true, response or {})
    --         elseif response and response.error and response.error.message then
    --             -- 成功了，但报错
    --             NPCTalkManager:StartDialog(npc, ofTranslate("ui.dialog.error") .. response.error.message, "dialogue", ply, true)
    --         else
    --             -- 成功了，但是回答格式是错误的
    --             NPCTalkManager:StartDialog(npc, ofTranslate("ui.dialog.invalid_response"), "dialogue", ply, true)
    --         end
    --     end,
        
    --     failed = function(err)
    --         -- 没有成功，可能没连上网
    --         NPCTalkManager:StartDialog(npc, ofTranslate("ui.dialog.http_error") .. (err or ofTranslate("ui.dialog.unknown")), "dialogue", ply, true)
    --     end
    -- })
end)