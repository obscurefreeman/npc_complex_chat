if CLIENT then

    -- 显示对话选项菜单
    net.Receive("OpenNPCDialogMenu", function()
        local npc = net.ReadEntity()
        local dialogOptions = {
            "makefriend",
            "trade",
            "leave"
        }

        -- 从JSON文件获取对话文本
        local playerTalkData = file.Read("data/of_npcp/player_talk.json", "GAME")
        local playerTalkOptions = {}
        if playerTalkData then
            local success, data = pcall(util.JSONToTable, playerTalkData)
            if success and data then
                for _, option in ipairs(dialogOptions) do
                    local phrases = data[option]
                    if phrases then
                        local randomPhrase = phrases[math.random(#phrases)]
                        table.insert(playerTalkOptions, randomPhrase)
                    end
                end
            end
        end

        -- 创建菜单
        local frame = vgui.Create("DFrame")
        frame:SetTitle("选择对话")
        frame:SetSize(300, 200)
        frame:Center()
        frame:MakePopup()

        local list = vgui.Create("DListView", frame)
        list:Dock(FILL)
        list:AddColumn("对话选项")

        for _, option in ipairs(playerTalkOptions) do
            local npcs = GetAllNPCsList()
            local npcIdentity = npcs[npc:EntIndex()]
            local translatedOption = L(option):gsub("/name/", L(npcIdentity.name))
            list:AddLine(translatedOption)
        end

        -- 处理对话选项选择
        list.OnRowSelected = function(_, _, line)
            local selectedOption = line:GetValue(1)
            -- 发送选定的对话选项到服务器
            net.Start("NPCDialogOptionSelected")
            net.WriteEntity(npc)
            net.WriteString(selectedOption)
            net.SendToServer()
            frame:Close()
        end
    end)

    -- -- 处理服务器发送的对话选项
    -- net.Receive("NPCDialogOptionSelected", function()
    --     local npc = net.ReadEntity()
    --     local selectedOption = net.ReadString()
    --     -- 这里可以添加代码来处理选定的对话选项
    -- end)
end 