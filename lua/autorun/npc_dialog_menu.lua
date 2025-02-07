if CLIENT then

    -- 显示对话选项菜单
    net.Receive("OpenNPCDialogMenu", function()
        local npc = net.ReadEntity()
        
        -- 通知服务器对话开始
        net.Start("NPCDialogMenuOpened")
        net.WriteEntity(npc)
        net.SendToServer()
        
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
        frame:SetNoRounded(true)
        frame:ShowCloseButton(false)
        frame:ShowMaximizeButton(false)
        frame:SetDraggable(false)

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

        for i=1, 2 do -- 左右两个部分
            local pax = vgui.Create("DPanel", i == 1 and leftPanel or rightPanel) -- 将DPanel放入对应的面板
            pax:Dock(TOP)
            pax:SetHeight(600 * OFGUI.ScreenScale)
            pax:SetMouseInputEnabled( false ) -- 阻止鼠标互动，不然把叉挡着了
            function pax:Paint( w, h ) end -- 隐藏这个DPanel
    
            local mdl = pax:Add( "DModelPanel" )
            mdl:Dock( FILL )
            mdl:SetMouseInputEnabled( false ) -- 禁止玩家触碰这个模型块
            mdl:SetModel( i == 1 and LocalPlayer():GetModel() or npc:GetModel() )
            mdl:SetAnimated( true )
    
            local ent, ply = mdl.Entity, LocalPlayer() -- 这样写可不大好啊
            local head = ent:LookupBone( "ValveBiped.Bip01_Head1" ) -- 检测模型是否有头部
            local cpos = head and ent:GetBonePosition( head ) or ( mdl:GetPos() +mdl:OBBCenter() ) -- 这个在外头只用一次，检测一下头的位置存不存在
            local move = Vector( 24, 0, 0 ) -- 摄像头到瞄准点的偏移量，这个24可以随便改改
    
            mdl:SetFOV( 40 ) -- FOV调个喜欢的
            mdl:SetCamPos( cpos +move ) -- 相机位置
            mdl:SetLookAt( cpos ) -- 相机朝向位置
    
            mdl:SetDirectionalLight( BOX_TOP, Color( 0, 0, 0 ) ) -- 这两个调光我不懂，不过可以稍微调的柔和点
            mdl:SetAmbientLight( Color( 128, 128, 128, 128 ) )
    
            mdl:SetAnimSpeed( 1 ) -- 虽然说后头还是用SetPlaybackRate调的好像不是很需要
            ent:SetAngles( Angle( 0, i == 1 and 15 or -15, 0 ) ) -- 左边朝右30度,右边朝左30度
            local animation = "idle_all_01" -- 默认动画
            if i == 2 then
                if npcIdentity.info == "npc_citizen" then
                    animation = "idle_subtle"
                elseif npcIdentity.info == "npc_metropolice" then
                    animation = "pistolidle1"
                elseif npcIdentity.info == "npc_combine_s" then
                    animation = "idle1"
                end
            end
            ent:ResetSequence(animation) -- 左边右边两个动作,按需求调
            ent:SetEyeTarget( i == 1 and cpos + move + Vector( 0, 10, 0 ) or cpos + move + Vector( 0, -10, 0 ) )
    
            if i == 1 then local col = ply:GetPlayerColor() -- 如果是玩家模型可以添上玩家的一些个性化
                if ply:GetSkin() != nil then ent:SetSkin( ply:GetSkin() ) end
                if ply:GetNumBodyGroups() != nil then
                    for i=0, ply:GetNumBodyGroups() -1 do ent:SetBodygroup( i, ply:GetBodygroup( i ) ) end
                end
                for n, m in pairs( ply:GetMaterials() ) do ent:SetSubMaterial( n-1 , m ) end
                ent:SetColor( ply:GetColor() ) ent:SetMaterial( ply:GetMaterial() )
                function ent:GetPlayerColor() -- 玩家颜色
                    return col
                end
            else -- NPC模型设置
                -- 同步皮肤
                if npc:GetSkin() != nil then 
                    ent:SetSkin(npc:GetSkin()) 
                end
                
                -- 同步bodygroups
                if npc:GetNumBodyGroups() != nil then
                    for i = 0, npc:GetNumBodyGroups() - 1 do 
                        ent:SetBodygroup(i, npc:GetBodygroup(i)) 
                    end
                end
            end
    
            function mdl:LayoutEntity( ent )
                if head then -- 这里持续调整摄像头位置矫正，不然位置会有点偏，比如说右侧反抗军会有点往下错位
                    local cpos = ent:GetBonePosition( head )
                    mdl:SetCamPos( cpos +move )
                    mdl:SetLookAt( cpos )
                end
                ent:SetPlaybackRate( mdl:GetAnimSpeed() ) -- 直接填1也行好像
                ent:FrameAdvance()
    
                -- 这边下面是一串我做床写的眨眼代码，需要就留着吧
                local blk = ent:GetFlexIDByName( "blink" ) -- 听说眨眼表情查询是分大小写的
                if !blk then blk = ent:GetFlexIDByName( "Blink" ) end -- 那就一起呗
                if blk then
                    if !ent.NextBlink or ent.NextBlink <= CurTime() then
                        if ent.NextBlink then ent.TimeBlink = CurTime() +0.2 end -- 闭眼到睁眼一共0.2秒
                        ent.NextBlink = CurTime() +math.Rand( 1.5, 4.5 ) -- 随机化下一次眨眼时间
                    end
                    if ent.TimeBlink then
                        local per = math.Clamp( ( ent.TimeBlink -CurTime() )/0.2, 0, 1 )
                        if per >= 0.5 then per = 1 -( per -0.5 )/0.5 else per = per*2 end -- 闭眼0.1睁眼0.1
                        ent:SetFlexWeight( blk, per )
                    end
                end
                -- 要嘴巴阿巴阿巴的话也是SetFlexWeight，但是市民好说玩家模型的张嘴表情号不一样就不好弄了，反正跟上面这段思路是差不多的
                
                -- 视线移动控制
                if !ent.NextEyeMove or ent.NextEyeMove <= CurTime() then
                    if ent.NextEyeMove then
                        -- 设置新的目标位置
                        local randomOffset = Vector(
                            math.Rand(-10, 10),
                            i == 1 and math.Rand(5, 15) or math.Rand(-15, -5),
                            0  -- 固定Z轴为0，保持视线高度不变
                        )
                        ent.CurrentEyeTarget = cpos + move + randomOffset
                    end
                    ent.NextEyeMove = CurTime() + math.Rand(2, 4)
                end

                -- 设置眼睛目标
                if ent.CurrentEyeTarget then
                    ent:SetEyeTarget(ent.CurrentEyeTarget)
                else
                    -- 初始化眼睛目标
                    ent.CurrentEyeTarget = cpos + move + Vector(0, i == 1 and 10 or -10, 0)
                    ent:SetEyeTarget(ent.CurrentEyeTarget)
                end
            end
        end

        -- 下方中间区域存放对话选项
        local scrollPanel = vgui.Create("OFScrollPanel", frame)
        scrollPanel:SetHeight(400 * OFGUI.ScreenScale)
        scrollPanel:Dock(BOTTOM)

        local messagelPanel = vgui.Create("OFScrollPanel", frame)
        messagelPanel:Dock(FILL)

        function CreateDialogMessages(npc, text)
            -- 创建新的消息
            local message = vgui.Create("OFMessage", messagelPanel)
            message:SetHeight(80 * OFGUI.ScreenScale)
            message:Dock(TOP)
            message:DockMargin(4, 4, 4, 4)
            
            -- 设置NPC的名字和对话内容
            message:SetName(L(npcIdentity.name) .. " “" .. L(npcIdentity.nickname) .. "”")
            message:SetText(text)
            message:SetColor(npcIdentity.color)
        end 

        local npccardPanel = vgui.Create("OFScrollPanel", rightPanel)
        npccardPanel:Dock(FILL)

        local function CreateSkillButton(parent, tag, tagDesc, iconPath, hoveredColor)
            if tag then
                local button = vgui.Create("OFSkillButton", parent)
                button:Dock(TOP)
                button:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                button:SetTall(80 * OFGUI.ScreenScale)
                button:SetIcon("ofnpcp/" .. string.gsub(iconPath, "%.", "/") .. ".png")
                button:SetTitle(L(tag))
                button:SetDescription(L(tagDesc))
                button:SetHoveredColor(hoveredColor)
            end
        end

        CreateSkillButton(npccardPanel, npcIdentity.tag_ability, npcIdentity.tag_ability_desc, npcIdentity.tag_ability, Color(100, 255, 100))
        CreateSkillButton(npccardPanel, npcIdentity.tag_trade, npcIdentity.tag_trade_desc, npcIdentity.tag_trade, Color(255, 200, 100))
        CreateSkillButton(npccardPanel, npcIdentity.tag_social, npcIdentity.tag_social_desc, npcIdentity.tag_social, Color(100, 200, 255))

        if npcIdentity.comments then
            for _, commentData in ipairs(npcIdentity.comments) do
                local commentLabel = vgui.Create("OFNPCButton", npccardPanel)
                commentLabel:Dock(TOP)
                commentLabel:SetTall(80 * OFGUI.ScreenScale)
                commentLabel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
                commentLabel:SetModel(commentData.model or "models/error.mdl")
                commentLabel:SetTitle(commentData.player)
                commentLabel:SetDescription(commentData.comment)
            end
        end

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

        -- 在关闭菜单时通知服务器对话结束
        frame.OnClose = function()
            net.Start("NPCDialogMenuClosed")
            net.WriteEntity(npc)
            net.SendToServer()
        end
    end)
end 