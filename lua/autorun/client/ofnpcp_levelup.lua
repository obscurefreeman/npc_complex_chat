-- 创建客户端ConVar，用于控制NPC升级时的文字、特效和声音
CreateClientConVar("of_garrylord_levelup_effects", "1", true, true, "", 0, 1)

local levelUpEffects = {}

net.Receive("OFNPCP_NS_RankUp", function()
    -- 检查ConVar是否开启
    if GetConVar("of_garrylord_levelup_effects"):GetInt() == 0 then return end

    local ent = net.ReadEntity()
    local identity = net.ReadTable()
    local rankname = ""
    local rankimage = ""

    -- 检查实体是否有效
    if not IsValid(ent) then return end

    -- 播放晋级音效
    ent:EmitSound("ofnpcp/rankup.ogg")

    rankimage = "ofnpcp/usrankicons/rank_".. identity.rank .. ".png"
    rankname = ofTranslate("rank.".. identity.rank)

    -- 创建一个文本标签来显示晋级信息
    local levelUpText = rankname
    local textDuration = 2  -- 持续时间为2秒
    local startTime = CurTime()  -- 记录开始时间

    -- 在NPC上方显示文本
    local function DrawLevelUpText()
        if not IsValid(ent) then return end  -- 检查实体是否有效
        local elapsed = CurTime() - startTime  -- 计算经过的时间
        local pos = ent:GetPos() + Vector(0, 0, ent:OBBCenter().z + (elapsed * 10))
        
        -- 计算透明度，随着时间的推移逐渐变浅，先慢后快
        local alpha = math.max(255 * (1 - (elapsed / textDuration)), 0)  -- 计算透明度，最大255，最小0
        -- 调整透明度变化速度，使其先慢后快
        alpha = 255 * (1 - (elapsed / textDuration) ^ 2)
        
        local screenPos = pos:ToScreen()  -- 将世界坐标转换为屏幕坐标
        -- 计算文本宽度
        local textWidth, textHeight = surface.GetTextSize(levelUpText)  -- 获取文本的宽度和高度
        -- 绘制等级图片
        local rankImagePath = rankimage  -- 使用等级图片路径
        surface.SetMaterial(Material(rankImagePath))  -- 设置图片材质
        surface.SetDrawColor(255, 255, 255, alpha)  -- 设置图片透明度
        
        -- 计算整体宽度（图片宽度 + 文字宽度）
        local imageWidth = textHeight  -- 高度与字体大小相同
        local totalWidth = imageWidth + textWidth
        
        -- 绘制图片（在文字左侧）
        surface.DrawTexturedRect(screenPos.x - totalWidth / 2, screenPos.y - textHeight / 2, imageWidth, textHeight)

        -- 绘制文本（在图片右侧）
        draw.SimpleText(levelUpText, "ofgui_big", screenPos.x - totalWidth / 2 + imageWidth, screenPos.y, Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- 在HUD中绘制文本
    local hookName = "DrawLevelUpText_" .. ent:EntIndex()  -- 使用实体索引创建唯一钩子名称
    hook.Add("HUDPaint", hookName, function()
        DrawLevelUpText()
        -- 在持续时间后移除钩子
        if CurTime() - startTime >= textDuration then
            hook.Remove("HUDPaint", hookName)
        end
    end)

    -- 添加升级特效
    levelUpEffects[ent] = {
        startTime = CurTime(),
        color = GLOBAL_OFNPC_DATA.setting.camp_setting[identity.camp].color,
        duration = 1
    }
end)

-- 添加3D渲染特效
hook.Add("PostDrawOpaqueRenderables", "RenderNPCLevelUpEffect", function()
    -- 检查ConVar是否开启
    if GetConVar("of_garrylord_levelup_effects"):GetInt() == 0 then return end

    for npc, effectData in pairs(levelUpEffects) do
        if IsValid(npc) then
            local timeElapsed = CurTime() - effectData.startTime
            if timeElapsed <= effectData.duration then
                local alpha = 255 * (1 - timeElapsed / effectData.duration)
                
                cam.Start3D()
                    render.SetColorModulation(effectData.color.r/255, effectData.color.g/255, effectData.color.b/255)
                    render.SuppressEngineLighting(true)
                    render.MaterialOverride(Material("models/debug/debugwhite"))
                    render.SetBlend(alpha/255)
                    npc:DrawModel()
                    render.MaterialOverride()
                    render.SuppressEngineLighting(false)
                    render.SetBlend(1)
                cam.End3D()
            else
                levelUpEffects[npc] = nil
            end
        else
            levelUpEffects[npc] = nil
        end
    end
end)
