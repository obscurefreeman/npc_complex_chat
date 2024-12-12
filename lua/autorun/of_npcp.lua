-- 共享函数区域（SERVER和CLIENT都可以访问）
function GetNPCIdentityText(identity)
    if not identity then return "" end
    
    local text = ""
    if identity.job then
        text = L(identity.name) .. " - " .. L(identity.job)
        if identity.specialization then
            text = L(identity.name) .. " - " .. L(identity.specialization)
        end
    elseif identity.rank then
        text = L(identity.name) .. " - " .. L(identity.rank)
    end
    
    return text
end

if SERVER then
    -- 将 npcs 设置为全局变量
    _G.npcs = {}
    
    -- 在文件开头添加必要的变量
    local citizenJobs = {}
    local metropoliceRanks = {}
    local combineRanks = {}
    local jobSpecializations = {}
    local maleNames = {}
    local femaleNames = {}

    -- 添加网络字符串
    util.AddNetworkString("NPCIdentityUpdate")

    -- 添加新的网络字符串
    util.AddNetworkString("UpdateNPCName")

    -- 在其他网络字符串后添加
    util.AddNetworkString("NPCAction")

    -- 加载JSON文件
    local function LoadNPCData()
        local citizenData = file.Read("data/of_npcp/citizen_jobs.json", "GAME")
        local metropoliceData = file.Read("data/of_npcp/metropolice_ranks.json", "GAME")
        local combineData = file.Read("data/of_npcp/combine_ranks.json", "GAME")

        if citizenData then
            local success, data = pcall(util.JSONToTable, citizenData)
            if success and data then
                citizenJobs = data.jobs
            else
                print("【晦涩弗里曼】解析 citizen_jobs.json 时出错。")
            end
        else
            print("【晦涩弗里曼】无法加载 citizen_jobs.json。")
        end
        if metropoliceData then
            metropoliceRanks = util.JSONToTable(metropoliceData).ranks
        end
        if combineData then
            combineRanks = util.JSONToTable(combineData).ranks
        end

        -- 加载职业细分
        for _, job in ipairs(citizenJobs) do
            local jobName = string.match(job, "citizen%.job%.(.+)")
            local specData = file.Read("data/of_npcp/jobs/" .. jobName .. ".json", "GAME")
            if specData then
                jobSpecializations[job] = util.JSONToTable(specData).specializations
            end
        end

        -- 加载名字数据
        local maleNamesData = file.Read("data/of_npcp/name_male.json", "GAME")
        local femaleNamesData = file.Read("data/of_npcp/name_female.json", "GAME")

        if maleNamesData then
            local success, data = pcall(util.JSONToTable, maleNamesData)
            if success and data then
                maleNames = data.names
            else
                print("【晦涩弗里曼】解析 name_male.json 时出错。")
            end
        end

        if femaleNamesData then
            local success, data = pcall(util.JSONToTable, femaleNamesData)
            if success and data then
                femaleNames = data.names
            else
                print("【晦涩弗里曼】解析 name_female.json 时出错。")
            end
        end
    end

    -- 在服务器启动时加载数据
    hook.Add("Initialize", "LoadNPCData", LoadNPCData)

    -- 修改AssignNPCIdentity函数，添加打印信息
    function AssignNPCIdentity(ent, npcInfo)
        local identity = {}

        identity.info = npcInfo
        identity.model = ent:GetModel()
        
        if npcInfo == "npc_citizen" then
            identity.job = citizenJobs[math.random(#citizenJobs)]

            if string.find(identity.model, "group01" ) then
                identity.type = "citizens"
            elseif string.find(identity.model, "group02" ) then
                identity.type = "refugees"
            elseif string.find(identity.model, "group03" ) then
                identity.type = "rebels"
            end

            if string.find(identity.model, "female" ) then
                identity.gender = "female"
            elseif string.find(identity.model, "male" ) then
                identity.gender = "male"
            end
            
            if jobSpecializations[identity.job] then
                local specs = jobSpecializations[identity.job]
                identity.specialization = specs[math.random(#specs)]
            end

            -- 根据性别分配名字
            if identity.gender == "female" then
                identity.name = femaleNames[math.random(#femaleNames)]
            else
                identity.name = maleNames[math.random(#maleNames)]
            end
        elseif npcInfo == "npc_metropolice" then
            local rank = math.random(1, 6)
            identity.rank = metropoliceRanks["i" .. rank]
            identity.name = maleNames[math.random(#maleNames)]
        elseif npcInfo == "npc_combine_s" then
            local rank = math.random(1, 6)
            identity.rank = combineRanks["i" .. rank]
            identity.name = maleNames[math.random(#maleNames)]
        end

        -- 存储NPC身份信息
        npcs[ent:EntIndex()] = identity
        
        -- 向客户端广播NPC身份信息
        net.Start("NPCIdentityUpdate")
            net.WriteEntity(ent)
            net.WriteTable(identity)
        net.Broadcast()

        -- 在控制台打印NPC信息
        print("\n=== 新NPC生成 ===")
        for key, value in pairs(identity) do
            print(key .. ": " .. value)
        end
        print("================")
        
    end
    
    hook.Add("OnEntityCreated", "NPCPersonality", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end  -- 检查实体是否仍然有效
            
            local class = ent:GetClass()
            -- 正确的条件判断
            if class == "npc_citizen" or class == "npc_metropolice" or class == "npc_combine_s" then
                AssignNPCIdentity(ent, class)
            end
        end)
    end)

    hook.Add("EntityRemoved", "CleanupNPCData", function(ent)
        if IsValid(ent) and ent:IsNPC() then
            npcs[ent:EntIndex()] = nil
        end
    end)

    -- 添加接收客户端请求更新NPC名字的处理函数
    net.Receive("UpdateNPCName", function(len, ply)
        local entIndex = net.ReadInt(32)
        local newName = net.ReadString()
        
        if npcs[entIndex] then
            npcs[entIndex].name = newName
            
            -- 广播更新后的身份信息给所有客户端
            net.Start("NPCIdentityUpdate")
                net.WriteEntity(Entity(entIndex))
                net.WriteTable(npcs[entIndex])
            net.Broadcast()
        end
    end)

    -- 在其他网络接收函数后添加
    net.Receive("NPCAction", function(len, ply)
        local entIndex = net.ReadInt(32)
        local action = net.ReadString()
        
        local ent = Entity(entIndex)
        if IsValid(ent) and ent:IsNPC() then
            if action == "heal" then
                ent:SetHealth(ent:GetMaxHealth())
            elseif action == "kill" then
                ent:TakeDamage(ent:GetMaxHealth(), ply, ply)
            elseif action == "remove" then
                ent:Remove()
            end
        end
    end)
end

if CLIENT then
    -- 只定义一次clientNPCs
    local clientNPCs = {}
    
    function GetAllNPCsList()
        return clientNPCs
    end
    
    -- 创建一个钩子系统来通知界面更新
    hook.Add("NPCListUpdated", "UpdateNPCMenu", function()
        hook.Run("RefreshNPCMenu")
    end)
    
    -- 接收服务器发送的NPC身份信息
    net.Receive("NPCIdentityUpdate", function()
        local ent = net.ReadEntity()
        local identity = net.ReadTable()
        if IsValid(ent) then
            clientNPCs[ent:EntIndex()] = identity
            -- 触发NPC列表更新事件
            hook.Run("NPCListUpdated")
        end
    end)
    
    -- 添加NPC顶显示功能
    -- hook.Add("PostDrawOpaqueRenderables", "DrawNPCInfo", function()
    --     local ply = LocalPlayer()
    --     if not IsValid(ply) then return end
        
    --     for _, ent in ipairs(ents.GetAll()) do
    --         if IsValid(ent) and ent:IsNPC() then
    --             local dist = ply:GetPos():Distance(ent:GetPos())
    --             -- 只渲染1000单位以内的NPC信息
    --             if dist <= 1000 then
    --                 local identity = clientNPCs[ent:EntIndex()]
    --                 if identity then
    --                     local pos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z + 5)
    --                     local ang = Angle(0, ply:EyeAngles().y - 90, 90)
                        
    --                     cam.Start3D2D(pos, ang, 0.1)
    --                         local text = GetNPCIdentityText(identity)
    --                         draw.SimpleText(text, "DermaLarge", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    --                     cam.End3D2D()
    --                 end
    --             end
    --         end
    --     end
    -- end)

    -- 客户端没有清理已移除NPC的数据
    hook.Add("EntityRemoved", "CleanupClientNPCData", function(ent)
        if IsValid(ent) and ent:IsNPC() then
            clientNPCs[ent:EntIndex()] = nil
        end
    end)
end