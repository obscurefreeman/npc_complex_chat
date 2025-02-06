if CLIENT then

    -- 显示对话选项菜单
    net.Receive("OpenNPCDialogMenu", function()
        local npc = net.ReadEntity()
        local dialogOptions = {
            "makefriend",
            "trade",
            "leave"
        }

        local npcs = GetAllNPCsList()
        local npcIdentity = npcs[npc:EntIndex()]

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

        -- 创建全屏菜单
        local frame = vgui.Create("OFFrame")
        frame:SetSize(ScrW(), ScrH())
        frame:SetPos(0, 0)

        -- 创建布局面板
        local leftPanel = vgui.Create("DPanel", frame)
        leftPanel:Dock(LEFT)
        leftPanel:SetWidth(400 * OFGUI.ScreenScale)
        leftPanel.Paint = function(self, w, h)
            surface.SetDrawColor(0, 0, 0, 0)
            surface.DrawRect(0, 0, w, h)
        end
        local rightPanel = vgui.Create("DPanel", frame)
        rightPanel:Dock(RIGHT)
        rightPanel:SetWidth(400 * OFGUI.ScreenScale)
        rightPanel.Paint = function(self, w, h)
            surface.SetDrawColor(0, 0, 0, 0)
            surface.DrawRect(0, 0, w, h)
        end

        local playerModelPanel = vgui.Create("DModelPanel", leftPanel)
        playerModelPanel:SetModel(LocalPlayer():GetModel())
        playerModelPanel:Dock(TOP)
        playerModelPanel:SetHeight(400 * OFGUI.ScreenScale)
        function playerModelPanel:LayoutEntity( Entity ) return end

        local npcModelPanel = vgui.Create("DModelPanel", rightPanel)
        npcModelPanel:SetModel(npc:GetModel())
        npcModelPanel:Dock(TOP)
        npcModelPanel:SetHeight(400 * OFGUI.ScreenScale)
        function npcModelPanel:LayoutEntity( Entity ) return end

        -- 下方中间区域存放对话选项
        local scrollPanel = vgui.Create("OFScrollPanel", frame)
        scrollPanel:SetHeight(400 * OFGUI.ScreenScale)
        scrollPanel:Dock(BOTTOM)

        local messagelPanel = vgui.Create("OFScrollPanel", frame)
        messagelPanel:Dock(FILL)

        local message = vgui.Create("OFMessage", messagelPanel)
        message:SetHeight(80 * OFGUI.ScreenScale)
        message:Dock(TOP)
        message:DockMargin(4, 4, 4, 4)
        message:SetName(L(npcIdentity.name))
        message:SetText("2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222")

        for _, option in ipairs(playerTalkOptions) do
            local translatedOption = L(option):gsub("/name/", L(npcIdentity.name))

            -- 创建按钮并添加到ScrollPanel
            local button = vgui.Create("OFChatButton", scrollPanel)
            button:SetChatText(translatedOption)
            button:Dock(TOP)
            button:DockMargin(4, 4, 4, 4)
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
end 