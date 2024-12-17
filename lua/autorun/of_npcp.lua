if SERVER then
    -- 将 OFNPCS 设置为全局变量
    OFNPCS = {}
    
    -- 在文件开头添加必要的变量
    local citizenJobs = {}
    local metropoliceRanks = {}
    local combineRanks = {}
    local jobSpecializations = {}
    local maleNames = {}
    local femaleNames = {}
    local tagData = {}
    local nicknames = {}

    -- 添加网络字符串
    util.AddNetworkString("NPCIdentityUpdate")

    -- 添加新的网络字符串
    util.AddNetworkString("UpdateNPCName")

    -- 在其他网络字符串后添加
    util.AddNetworkString("NPCAction")

    -- 添加网络字符串
    util.AddNetworkString("SubmitNPCComment")

    -- 加载JSON文件
    local function LoadNPCData()
        local citizenData = file.Read("data/of_npcp/citizen_jobs.json", "GAME")

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

        -- 加载职业细分
        for _, job in ipairs(citizenJobs) do
            local jobName = job.job
            jobSpecializations[jobName] = job.specializations
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

        -- 加载tag数据
        local tagJsonData = file.Read("data/of_npcp/tags.json", "GAME")
        if tagJsonData then
            local success, data = pcall(util.JSONToTable, tagJsonData)
            if success and data then
                tagData = data
            else
                print("【晦涩弗里曼】解析 tags.json 时出错。")
            end
        end
    end

    -- 在服务器启动时加载数据
    hook.Add("Initialize", "LoadNPCData", LoadNPCData)

    -- 加载绰号数据
    local function LoadNicknameData()
        local nicknameData = file.Read("data/of_npcp/citizen_nickname.json", "GAME")
        if nicknameData then
            local success, data = pcall(util.JSONToTable, nicknameData)
            if success and data then
                nicknames = data.nicknames
            else
                print("【晦涩弗里曼】解析 citizen_nickname.json 时出错。")
            end
        else
            print("【晦涩弗里曼】无法加载 citizen_nickname.json。")
        end
    end

    -- 在服务器启动时加载绰号数据
    hook.Add("Initialize", "LoadNicknameData", LoadNicknameData)

    -- 修改AssignNPCIdentity函数，添加绰号分配
    function AssignNPCIdentity(ent, npcInfo)
        local identity = {}

        identity.info = npcInfo
        identity.model = ent:GetModel()
        identity.nickname = nicknames[math.random(#nicknames)]
        
        if npcInfo == "npc_citizen" then
            if string.find(identity.model, "group03m") then
                identity.job = "citizen.job.medic"
                identity.type = "medic"
            else
                identity.job = citizenJobs[math.random(#citizenJobs)].job
                identity.type = "citizens"  -- 默认类型
                if string.find(identity.model, "group01") then
                    identity.type = "citizens"
                elseif string.find(identity.model, "group02") then
                    identity.type = "refugees"
                elseif string.find(identity.model, "group03") then
                    identity.type = "rebels"
                end
            end

            if string.find(identity.model, "female") then
                identity.gender = "female"
            elseif string.find(identity.model, "male") then
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
            identity.type = "metropolice"
            identity.rank = math.random(1, 5)
            identity.name = maleNames[math.random(#maleNames)]
        elseif npcInfo == "npc_combine_s" then
            identity.type = "combine"
            identity.rank = math.random(1, 39)
            identity.name = maleNames[math.random(#maleNames)]
        end

        -- 在分配完基本信息后添加tag分配
        if identity.job then
            -- 分配能力tag
            if tagData.tag_ability[identity.job] then
                local abilityTag = tagData.tag_ability[identity.job]
                identity.tag_ability = abilityTag.id
                identity.ability_desc = abilityTag.desc
            end
        end
        
        -- 分配交易和社交tag
        if tagData.tag_trade and #tagData.tag_trade > 0 then
            local tradeTag = tagData.tag_trade[math.random(#tagData.tag_trade)]
            identity.tag_trade = tradeTag.id
            identity.trade_desc = tradeTag.desc
        end
        
        if tagData.tag_social and #tagData.tag_social > 0 then
            local socialTag = tagData.tag_social[math.random(#tagData.tag_social)]
            identity.tag_social = socialTag.id
            identity.social_desc = socialTag.desc
        end
        
        -- 存储NPC身份信息
        OFNPCS[ent:EntIndex()] = identity
        
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
            OFNPCS[ent:EntIndex()] = nil
        end
    end)

    -- 添加接收客户端请求更新NPC名字的处理函数
    net.Receive("UpdateNPCName", function(len, ply)
        local entIndex = net.ReadInt(32)
        local newName = net.ReadString()
        
        if OFNPCS[entIndex] then
            OFNPCS[entIndex].name = newName
            
            -- 广播更新后的身份信息给所有客户端
            net.Start("NPCIdentityUpdate")
                net.WriteEntity(Entity(entIndex))
                net.WriteTable(OFNPCS[entIndex])
            net.Broadcast()
        end
    end)

    -- 在其他网络接收函数后添���
    net.Receive("NPCAction", function(len, ply)
        local entIndex = net.ReadInt(32)
        local action = net.ReadString()
        
        if entIndex == -1 then
            -- 处理所有NPC的操作
            for _, ent in ipairs(ents.GetAll()) do
                if IsValid(ent) and ent:IsNPC() then
                    if action == "healall" then
                        ent:SetHealth(ent:GetMaxHealth())
                    elseif action == "killall" then
                        ent:TakeDamage(ent:GetMaxHealth(), ply, ply)
                    elseif action == "removeall" then
                        ent:Remove()
                    end
                end
            end
            return
        end
        
        -- 处理单个NPC的操作
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

    -- 处理评论的接收
    net.Receive("SubmitNPCComment", function(len, ply)
        local entIndex = net.ReadInt(32)
        local comment = net.ReadString()

        if OFNPCS[entIndex] then
            -- 如果评论表不存在，则初始化
            if not OFNPCS[entIndex].comments then
                OFNPCS[entIndex].comments = {}
            end

            -- 添加评论
            table.insert(OFNPCS[entIndex].comments, {
                player = ply:Nick(),
                model = ply:GetModel(),
                comment = comment
            })

            -- 广播更新后的身份信息给所有客户端
            net.Start("NPCIdentityUpdate")
                net.WriteEntity(Entity(entIndex))
                net.WriteTable(OFNPCS[entIndex])
            net.Broadcast()
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