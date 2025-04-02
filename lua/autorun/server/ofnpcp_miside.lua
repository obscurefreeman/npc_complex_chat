util.AddNetworkString("OFSpawnChatMessage")  -- 用于发送消息

-- 用于存储每个玩家的消息数量
local messageCount = {}

-- 字符的生存时间变量（默认4.5秒）
local messageLifeTime = 4.5

-- 用于在玩家面前创建文本的函数
hook.Add("OnNPCTalkStart", "CreateMisideSubtitles", function(npc, text)
    if not IsValid(npc) then return end

    text = ofTranslate(text)

    -- 获取玩家的消息数量，如果还没有消息则为0
    if npc:IsPlayer() then
        messageCount[npc:SteamID()] = (messageCount[npc:SteamID()] or 0) + 1
    elseif npc:IsNPC() then
        messageCount[npc:EntIndex()] = (messageCount[npc:EntIndex()] or 0) + 1
    end

    -- 在第3条消息后重置高度
    if npc:IsPlayer() and messageCount[npc:SteamID()] > 3 then
        messageCount[npc:SteamID()] = 1  -- 在第3条消息后重置计数器
    elseif npc:IsNPC() and messageCount[npc:EntIndex()] > 3 then
        messageCount[npc:EntIndex()] = 1  -- 在第3条消息后重置计数器
    end

    -- 根据消息数量计算高度
    local messageHeight = (npc:IsPlayer() and messageCount[npc:SteamID()] or messageCount[npc:EntIndex()]) * 7  -- 每条消息增加7单位

    local playerPos = npc:GetPos()
    local playerAng = npc:EyeAngles()
    local yawAng = Angle(0, playerAng.y, 0)

    local basePos = playerPos + Vector(0, 0, 34)  -- 玩家眼睛前方的位置
    local forwardVec = yawAng:Forward()
    local forwardOffset = 30
    local anchorPos = basePos + forwardVec * forwardOffset
    anchorPos.z = anchorPos.z + messageHeight  -- 根据消息编号改变高度

    local anchorAng = Angle(0, yawAng.y - 270, 90)

    local letters = {}
    for p, codepoint in utf8.codes(text) do
        local ch = utf8.char(codepoint)
        table.insert(letters, ch)
    end

    local letterCount = #letters
    local spacing = 4
    local totalWidth = (letterCount - 1) * spacing

    -- 为每个字符创建单独的对象，使其依次出现
    for i, ch in ipairs(letters) do
        local index = i - 1
        local delay = (i - 1) * 0.05
        timer.Simple(delay, function()
            if not IsValid(npc) then return end

            local letterPos = anchorPos + anchorAng:Forward() * (index * spacing - totalWidth / 2)

            local prop = ents.Create("prop_physics")
            if IsValid(prop) then
                prop:SetModel("models/hunter/plates/platedonj.mdl")
                prop:SetPos(letterPos)
                prop:SetAngles(anchorAng)
                prop:Spawn()

                prop:SetRenderMode(RENDERMODE_TRANSALPHA)
                prop:SetColor(Color(255, 255, 255, 0))

                prop:SetMoveType(MOVETYPE_NONE)
                prop:SetSolid(SOLID_NONE)
                local phys = prop:GetPhysicsObject()
                if IsValid(phys) then
                    phys:EnableMotion(false)
                end

                -- 给物理对象一些时间进行设置
                timer.Simple(3, function()
                    if IsValid(prop) then
                        prop:SetMoveType(MOVETYPE_VPHYSICS)
                        prop:SetSolid(SOLID_VPHYSICS)
                        prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
                        local phys = prop:GetPhysicsObject()
                        if IsValid(phys) then
                            phys:EnableMotion(true)
                            phys:Wake()
                            phys:SetMaterial("gmod_silent")

                            -- 应用随机力使字母散开
                            local randomVelocity = Vector(
                                math.random(-50, 50),  -- X轴随机运动
                                math.random(-50, 50),  -- Y轴随机运动
                                math.random(2, 10)    -- Z轴随机运动（向上）
                            )
                            phys:SetVelocity(randomVelocity)  -- 设置初始速度
                        end
                    end
                end)

                -- 一段时间后移除对象
                timer.Simple(messageLifeTime, function()
                    if IsValid(prop) then
                        prop:Remove()
                    end
                end)

                -- 设置网络请求，将字符发送给所有客户端
                net.Start("OFSpawnChatMessage")
                net.WriteUInt(prop:EntIndex(), 16)  -- 实体索引
                net.WriteString(ch)  -- 字符本身
                net.Broadcast()
            end
        end)
    end
end)
