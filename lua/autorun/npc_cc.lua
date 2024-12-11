if SERVER then
    -- 在文件开头添加必要的变量
    local citizenJobs = {}
    local metropoliceRanks = {}
    local combineRanks = {}
    local jobSpecializations = {}

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

    function AssignNPCIdentity(ent, weaponInfo, npcInfo)
        local identity = {}
        identity.weapon = IsValid(weaponInfo) and weaponInfo:GetClass() or "none"
        
        if npcInfo == "male" or npcInfo == "female" then
            -- 为市民随机分配职业
            identity.job = citizenJobs[math.random(#citizenJobs)]
            identity.gender = npcInfo
            
            -- 分配细分职业
            if jobSpecializations[identity.job] then
                local specs = jobSpecializations[identity.job]
                identity.specialization = specs[math.random(#specs)]
            end
        elseif npcInfo == "metropolice" then
            -- 为城市保护队随机分配军衔
            local rank = math.random(1, 6)
            identity.rank = metropoliceRanks["i" .. rank]
        elseif npcInfo == "combine" then
            -- 为联合军随机分配军衔
            local rank = math.random(1, 6)
            identity.rank = combineRanks["i" .. rank]
        end

        -- 存储NPC身份信息
        npcs[ent:EntIndex()] = identity
    end
    
    hook.Add("OnEntityCreated", "NPCPersonality", function(ent)
        if not ofkc_enabled:GetBool() then return end
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