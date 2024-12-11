-- 共享函数区域（SERVER和CLIENT都可以访问）
function GetNPCIdentityText(identity)
    if not identity then return "" end
    
    local text = ""
    if identity.job then
        text = L(identity.job)
        if identity.specialization then
            text = L(identity.specialization)
        end
    elseif identity.rank then
        text = L(identity.rank)
    end
    
    return text
end

if SERVER then
    -- 在文件开头添加必要的变量
    local citizenJobs = {}
    local metropoliceRanks = {}
    local combineRanks = {}
    local jobSpecializations = {}
    local npcs = {}

    -- 添加网络字符串
    util.AddNetworkString("NPCIdentityUpdate")

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
    end

    -- 在服务器启动时加载数据
    hook.Add("Initialize", "LoadNPCData", LoadNPCData)

    -- 修改AssignNPCIdentity函数，添加打印信息
    function AssignNPCIdentity(ent, npcInfo)
        local identity = {}

        identity.info = npcInfo
        
        if npcInfo == "npc_citizen" then
            identity.job = citizenJobs[math.random(#citizenJobs)]
            if string.find(ent:GetModel(), "male" or "Male") then
                identity.gender = "male"
            elseif string.find(ent:GetModel(), "female" or "Female") then
                identity.gender = "female"
            end
            
            if jobSpecializations[identity.job] then
                local specs = jobSpecializations[identity.job]
                identity.specialization = specs[math.random(#specs)]
            end
        elseif npcInfo == "npc_metropolice" then
            local rank = math.random(1, 6)
            identity.rank = metropoliceRanks["i" .. rank]
        elseif npcInfo == "npc_combine_s" then
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
    
    -- 添加NPC顶显示功能
    hook.Add("PostDrawOpaqueRenderables", "DrawNPCInfo", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() then
                local dist = ply:GetPos():Distance(ent:GetPos())
                -- 只渲染1000单位以内的NPC信息
                if dist <= 1000 then
                    local identity = clientNPCs[ent:EntIndex()]
                    if identity then
                        local pos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z + 5)
                        local ang = Angle(0, ply:EyeAngles().y - 90, 90)
                        
                        cam.Start3D2D(pos, ang, 0.1)
                            local text = GetNPCIdentityText(identity)
                            draw.SimpleText(text, "DermaLarge", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        cam.End3D2D()
                    end
                end
            end
        end
    end)

    -- 客户端没有清理已移除NPC的数据
    local clientNPCs = {}
    
    -- 应该添加清理钩子
    hook.Add("EntityRemoved", "CleanupClientNPCData", function(ent)
        if IsValid(ent) and ent:IsNPC() then
            clientNPCs[ent:EntIndex()] = nil
        end
    end)
end