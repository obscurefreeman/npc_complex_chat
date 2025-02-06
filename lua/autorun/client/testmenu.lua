
if IsValid( xdetmenu ) then xdetmenu:Remove() end xdetmenu = nil

concommand.Add( "testmenu", function( ply, cmd, var )
    if IsValid( xdetmenu ) then xdetmenu:Remove() end
    xdetmenu = vgui.Create( "DFrame" )
    xdetmenu:SetSize( 420, 300 ) xdetmenu:SetTitle( "" )
    xdetmenu:Center() xdetmenu:MakePopup()
    xdetmenu.T_Mdls = {}

    local function DoBlock( xx, yy, ww, hh ) -- 背景块用两个部分组成
        surface.SetDrawColor( 16, 16, 16, 128 ) surface.DrawRect( xx, yy, ww, hh ) -- 一抹半透明黑色
        surface.SetDrawColor( 0, 0, 0 ) surface.DrawOutlinedRect( xx, yy, ww, hh ) -- 黑色线框
    end

    function xdetmenu:Paint( w, h )
        DoBlock( 0, 0, 200, 300 ) DoBlock( 220, 0, 200, 300 ) -- 提前打上两个背景块在模型下头
    end

    for i=1, 2 do -- 左右两个部分
        local pax = xdetmenu:Add( "DPanel" ) -- 我看都是把DModelPanel放一个DPanel里然后Dock填充的，我随大流反正
        pax:SetPos( 1 +( i-1 )*220, 1 ) -- 位置朝着右下挪一下不然跟黑线框穿模
        pax:SetSize( 198, 298 ) -- 长宽减去2不然跟黑线框穿模
        pax:SetMouseInputEnabled( false ) -- 阻止鼠标互动，不然把叉挡着了
        function pax:Paint( w, h ) end -- 隐藏这个DPanel

        local mdl = pax:Add( "DModelPanel" )
        xdetmenu.T_Mdls[ i ] = mdl -- 开个近路后头可以调用
        mdl:Dock( FILL )
        mdl:SetMouseInputEnabled( false ) -- 禁止玩家触碰这个模型块
        mdl:SetModel( i == 1 and LocalPlayer():GetModel() or "models/Humans/Group03/male_09.mdl" ) -- 左边是你的模型，右边是一个反抗军

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
        ent:SetAngles( Angle( 0, i == 1 and 30 or -30, 0 ) ) -- 左边朝右30度,右边朝左30度
        ent:ResetSequence( i == 1 and "idle_all_01" or "idle_subtle" ) -- 左边右边两个动作,按需求调

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
end )