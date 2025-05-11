util.AddNetworkString("OFDamageNumber")

hook.Add("EntityTakeDamage", "SpawnDamageNumbers", function(ent, dmg)
    if not IsValid(ent) or not ent:IsNPC() then return end
    
    local damage = math.Round(dmg:GetDamage())
    local pos = dmg:GetDamagePosition()  -- 获取伤害的命中位置
    local randomYaw = math.random(0, 360)
    local ang = Angle(0, randomYaw, 90)

    local prop = ents.Create("prop_physics")
    if IsValid(prop) then
        prop:SetModel("models/hunter/plates/platedonj.mdl")
        prop:SetPos(pos)
        prop:SetAngles(ang)
        prop:Spawn()
        

        prop:SetMoveType(MOVETYPE_VPHYSICS)
        prop:SetRenderMode(RENDERMODE_TRANSALPHA)
        prop:SetSolid(SOLID_VPHYSICS)
        prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        prop:SetColor(Color(255,0,0,0))
        
        net.Start("OFDamageNumber")
            net.WriteUInt(prop:EntIndex(), 16)
            net.WriteString(tostring(damage))
            net.WriteEntity(ent)
        net.Broadcast()

        local phys = prop:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(true)
            phys:Wake()
            phys:SetMaterial("gmod_silent")

            -- 应用随机力使字母散开
            local randomVelocity = Vector(
                math.random(-50, 50),  -- X轴随机运动
                math.random(-50, 50),  -- Y轴随机运动
                math.random(200, 300)    -- Z轴随机运动（向上）
            )
            phys:SetVelocity(randomVelocity)  -- 设置初始速度
        end

        timer.Simple(3, function()
            if IsValid(prop) then prop:Remove() end
        end)
    end
end)
