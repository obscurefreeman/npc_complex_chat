if CLIENT then

    -- 显示对话选项菜单
    net.Receive("OpenNPCDialogMenu", function()
        local npc = net.ReadEntity()
        local dialogOptions = {
            "makefriend",
            "trade",
            "leave"
        }

        -- 从全局变量获取对话文本
        local playerTalkOptions = {}
        if GLOBAL_OFNPC_DATA.playerTalks then
            for _, option in ipairs(dialogOptions) do
                local phrases = GLOBAL_OFNPC_DATA.playerTalks[option]
                if phrases then
                    local randomPhrase = phrases[math.random(#phrases)]
                    table.insert(playerTalkOptions, randomPhrase)
                end
            end
        end

        -- 创建菜单
        local frame = vgui.Create("OFFrame")
        frame:SetSize(800 * OFGUI.ScreenScale, 300 * OFGUI.ScreenScale)
        frame:SetPos(ScrW() / 2 - 400 * OFGUI.ScreenScale, ScrH() - 400 * OFGUI.ScreenScale)
        -- frame:SetDraggable(false)

        -- 创建ScrollPanel
        local scrollPanel = vgui.Create("OFScrollPanel", frame)
        scrollPanel:Dock(FILL)

        for _, option in ipairs(playerTalkOptions) do
            local npcs = GetAllNPCsList()
            local npcIdentity = npcs[npc:EntIndex()]
            local translatedOption = L(option):gsub("/name/", L(npcIdentity.name))

            -- 创建按钮并添加到ScrollPanel
            local button = vgui.Create("OFChatButton", scrollPanel)
            button:SetChatText(translatedOption)
            button:Dock(TOP)
            button:DockMargin(4, 4, 4, 4) -- 添加按钮之间的间距
            button:SetIcon("ofnpcp/chaticons/chat.png")
            button:SetHoveredColor(Color(100, 255, 100))
            button:SetTall(50 * OFGUI.ScreenScale) -- 设置按钮的高度

            -- 处理按钮点击事件
            button.DoClick = function()
                -- 发送选定的对话选项到服务器
                net.Start("NPCDialogOptionSelected")
                net.WriteEntity(npc)
                net.WriteString(option)
                net.SendToServer()
                frame:Close()
            end
        end
    end)

    -- -- 处理服务器发送的对话选项
    -- net.Receive("NPCDialogOptionSelected", function()
    --     local npc = net.ReadEntity()
    --     local selectedOption = net.ReadString()
    --     -- 这里可以添加代码来处理选定的对话选项
    -- end)
end 