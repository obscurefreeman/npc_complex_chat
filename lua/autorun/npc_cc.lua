if SERVER then
    -- 在文件开头添加必要的变量
    local citizenJobs = {}
    local metropoliceRanks = {}
    local combineRanks = {}
    local jobSpecializations = {}
    local npcs = {}

    -- 添加获取NPC身份信息的函数
    function GetNPCIdentityText(identity)
        if not identity then return "" end
        
        local text = ""
        if identity.job then
            text = L(identity.job)
            if identity.specialization then
                text = text .. " - " .. L(identity.specialization)
            end
        elseif identity.rank then
            text = L(identity.rank)
        end
        
        return text
    end

    -- 添加网络字符串
    util.AddNetworkString("NPCIdentityUpdate")

    -- 加载JSON文件
    local function LoadNPCData()
        local citizenData = file.Read("data/citizen_jobs.json", "GAME")
        local metropoliceData = file.Read("data/metropolice_ranks.json", "GAME")
        local combineData = file.Read("data/combine_ranks.json", "GAME")

        if citizenData then
            citizenJobs = util.JSONToTable(citizenData).jobs
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
            local specData = file.Read("data/jobs/" .. jobName .. ".json", "GAME")
            if specData then
                jobSpecializations[job] = util.JSONToTable(specData).specializations
            end
        end
    end

    -- 在服务器启动时加载数据
    hook.Add("Initialize", "LoadNPCData", LoadNPCData)

    -- 修改AssignNPCIdentity函数，添加网络同步
    function AssignNPCIdentity(ent, npcInfo)
        local identity = {}
        
        if npcInfo == "male" or npcInfo == "female" then
            identity.job = citizenJobs[math.random(#citizenJobs)]
            identity.gender = npcInfo
            
            if jobSpecializations[identity.job] then
                local specs = jobSpecializations[identity.job]
                identity.specialization = specs[math.random(#specs)]
            end
        elseif npcInfo == "metropolice" then
            local rank = math.random(1, 6)
            identity.rank = metropoliceRanks["i" .. rank]
        elseif npcInfo == "combine" then
            local rank = math.random(1, 6)
            identity.rank = combineRanks["i" .. rank]
        end

        -- 存储NPC身份信息
        npcs[ent:EntIndex()] = identity
        
        -- 向客户端广播NPC身份信息
        net.Start("NPCIdentityUpdate")
            net.WriteEntity(ent)
            net.WriteTable(identity)
        net.Broadcast()
    end
    
    hook.Add("OnEntityCreated", "NPCPersonality", function(ent)
        if not IsValid(ent) or not ent:IsNPC() then return end
        if ent:GetClass() == "npc_bullseye" then return end
        timer.Simple(0.1, function()
            local weaponInfo = ent:GetActiveWeapon() -- 获取武器信息
            if ent:GetClass() == "npc_citizen" then
                local npcInfo = nil
                if string.find(ent:GetModel(), "male") then
                    npcInfo = "male"
                elseif string.find(ent:GetModel(), "female") then
                    npcInfo = "female"
                end
                AssignNPCIdentity(ent, weaponInfo, npcInfo) -- 发送性别信息
            elseif ent:GetClass() == "npc_metropolice" then
                npcInfo = "metropolice"
                AssignNPCIdentity(ent, weaponInfo, npcInfo) -- 发送武器信息
            elseif ent:GetClass() == "npc_combine" then
                npcInfo = "combine"
                AssignNPCIdentity(ent, weaponInfo, npcInfo) -- 发送武器信息
            end
        end)
    end)

    hook.Add("EntityRemoved", "CleanupNPCData", function(ent)
        if IsValid(ent) and ent:IsNPC() then
            if ent:Health() > 0 then
                npcs[ent:EntIndex()] = nil
            end
        end
    end)
end

if CLIENT then
    -- 客户端NPC数据存储
    local clientNPCs = {}
    
    -- 接收服务器发送的NPC身份信息
    net.Receive("NPCIdentityUpdate", function()
        local ent = net.ReadEntity()
        local identity = net.ReadTable()
        if IsValid(ent) then
            clientNPCs[ent:EntIndex()] = identity
        end
    end)
    
    -- 添加NPC头顶显示功能
    hook.Add("PostDrawOpaqueRenderables", "DrawNPCInfo", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() then
                local identity = clientNPCs[ent:EntIndex()]
                if identity then
                    local pos = ent:GetPos() + Vector(0, 0, 85)
                    local ang = (pos - ply:GetPos()):Angle()
                    ang:RotateAroundAxis(ang:Up(), -90)
                    ang:RotateAroundAxis(ang:Forward(), 90)
                    
                    cam.Start3D2D(pos, ang, 0.1)
                        local text = GetNPCIdentityText(identity)
                        draw.SimpleText(text, "DermaLarge", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    cam.End3D2D()
                end
            end
        end
    end)
end