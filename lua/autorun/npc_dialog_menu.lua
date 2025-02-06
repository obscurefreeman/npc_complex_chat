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
                    animation = "baton_idle1"
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
            end
        end

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
        message:SetText("Lorem ipsum dolor sit amet, ius ferri mucius cu, vel fugit nobis prompta ei. His possit urbanitas moderatius ea, duo an exerci mandamus definitionem. Nec novum facilisi intellegat ut, legere aeterno gloriatur an est. Vim eu doming alterum, mel minim aliquando mediocritatem at. Vix et novum molestiae, movet reformidans quo an, ex vis tamquam sadipscing. Dolor tamquam id pro, no nusquam philosophia eos.His posse salutandi id. Equidem saperet accusamus eum an, eu his solet utroque deseruisse, nostro inimicus mea cu. An quodsi perpetua rationibus qui, usu omittam offendit ex. Eu amet ponderum temporibus duo, ea apeirian mandamus per.Sed ex eleifend sadipscing. Usu at novum partem officiis, quo rebum nulla cu. In nihil essent intellegebat quo. Quot tota reprimique qui ne.Est ullum etiam libris ne. Est amet minimum an. Ipsum docendi adversarium pro ne, reprimique philosophia an qui. Qui ad tale ferri. Cu eum nihil recteque eloquentiam. Dolorum omnesque te has.Te ubique posidonium pro, id nec case vide veritus. Ad periculis reprehendunt cum, ad ius probo signiferumque. Id vocent fuisset duo. Duo ex purto labitur disputationi. In vel unum appetere mnesarchum, ut vix sententiae consectetuer, ea usu sumo veritus.")

        local npccardPanel = vgui.Create("OFScrollPanel", rightPanel)
        npccardPanel:Dock(FILL)

        -- 添加tag显示
        if npcIdentity.tag_ability then
            local abilityButton = vgui.Create("OFSkillButton", npccardPanel)
            abilityButton:Dock(TOP)
            abilityButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
            abilityButton:SetTall(80 * OFGUI.ScreenScale)
            local abilityIconPath = string.gsub(npcIdentity.tag_ability, "%.", "/")
            abilityButton:SetIcon("ofnpcp/" .. abilityIconPath .. ".png")
            abilityButton:SetTitle(L(npcIdentity.tag_ability))
            abilityButton:SetDescription(L(npcIdentity.tag_ability_desc))
            abilityButton:SetHoveredColor(Color(100, 255, 100))
        end
        
        if npcIdentity.tag_trade then
            local tradeButton = vgui.Create("OFSkillButton", npccardPanel)
            tradeButton:Dock(TOP)
            tradeButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
            tradeButton:SetTall(80 * OFGUI.ScreenScale)
            local tradeIconPath = string.gsub(npcIdentity.tag_trade, "%.", "/")
            tradeButton:SetIcon("ofnpcp/" .. tradeIconPath .. ".png")
            tradeButton:SetTitle(L(npcIdentity.tag_trade))
            tradeButton:SetDescription(L(npcIdentity.tag_trade_desc))
            tradeButton:SetHoveredColor(Color(255, 200, 100))
        end
        
        if npcIdentity.tag_social then
            local socialButton = vgui.Create("OFSkillButton", npccardPanel)
            socialButton:Dock(TOP)
            socialButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
            socialButton:SetTall(80 * OFGUI.ScreenScale)
            local socialIconPath = string.gsub(npcIdentity.tag_social, "%.", "/")
            socialButton:SetIcon("ofnpcp/" .. socialIconPath .. ".png")
            socialButton:SetTitle(L(npcIdentity.tag_social))
            socialButton:SetDescription(L(npcIdentity.tag_social_desc))
            socialButton:SetHoveredColor(Color(100, 200, 255))
        end

        -- 显示评论
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
    end)
end 