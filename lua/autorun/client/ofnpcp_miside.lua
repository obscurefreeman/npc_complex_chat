local textColor = Color(255, 86, 23)
local outlineColor = Color(255, 255, 255, 200)

resource.AddFile("resource/fonts/XiaolaiMonoSC-Regular.ttf")
surface.CreateFont("xiaolai", {size = 100 * OFGUI.ScreenScale, weight = 300, antialias = true, extended = true, font = "Xiaolai Mono SC"})

local subtitleLetters = {}

-- 获取字母信息
net.Receive("OFSpawnChatMessage", function()
    local entIndex = net.ReadUInt(16)
    local ch = net.ReadString()

    -- 保存字符用于渲染
    subtitleLetters[entIndex] = ch
end)

-- 在玩家面前渲染字母
hook.Add("PostDrawTranslucentRenderables", "OFDrawChatText", function()
    for entIndex, ch in pairs(subtitleLetters) do
        local ent = Entity(entIndex)
        if not IsValid(ent) then
            subtitleLetters[entIndex] = nil
        else
            local pos = ent:GetPos()
            local ang = ent:GetAngles()

            -- 以正常方向显示文本
            cam.Start3D2D(pos + Vector(0, 0, 1), ang, 0.1)
                -- 绘制带描边的文本
                draw.SimpleTextOutlined(
                    ch,
                    "xiaolai",  -- 使用当前字体
                    0, 0,
                    outlineColor,  -- 描边颜色
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    2,  -- 描边厚度
                    outlineColor  -- 描边颜色
                )
                -- 绘制主颜色文本
                draw.SimpleTextOutlined(
                    ch,
                    "xiaolai",  -- 使用当前字体
                    0, 0,
                    textColor,  -- 文本颜色
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    0,  -- 主文本无描边
                    outlineColor  -- 描边颜色保留
                )
            cam.End3D2D()

            -- 以镜像方向显示文本
            local reversedAng = Angle(ang.p, ang.y, ang.r + 180)  -- Y轴旋转180度

            -- 在另一侧渲染文本（仅翻转相机方向，不翻转文本）
            cam.Start3D2D(pos + Vector(0, 0, 1), reversedAng, -0.1)  -- 使用负比例进行镜像显示
                -- 绘制带描边的文本
                draw.SimpleTextOutlined(
                    ch,
                    "xiaolai",  -- 使用当前字体
                    0, 0,
                    outlineColor,  -- 描边颜色
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    2,  -- 描边厚度
                    outlineColor  -- 描边颜色
                )
                -- 使用描边颜色绘制镜像文本
                draw.SimpleTextOutlined(
                    ch,
                    "xiaolai",  -- 使用当前字体
                    0, 0,
                    outlineColor,  -- 使用描边颜色
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    0,  -- 文本无描边
                    outlineColor  -- 描边颜色保留
                )
            cam.End3D2D()
        end
    end
end)
