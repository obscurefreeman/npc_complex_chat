if SERVER then
    -- 将 OFNPCS 设置为全局变量
    OFNPCS = {}

    -- 添加网络字符串
    util.AddNetworkString("NPCIdentityUpdate")
    util.AddNetworkString("UpdateNPCName")
    util.AddNetworkString("NPCAction")
    util.AddNetworkString("SubmitNPCComment")
    util.AddNetworkString("OFNPCRankUp")

    util.AddNetworkString("TalkStart")
    util.AddNetworkString("OpenNPCDialogMenu")
    util.AddNetworkString("PlayerDialog")
    util.AddNetworkString("NPCDialogMenuOpened")
    util.AddNetworkString("NPCDialogMenuClosed")

    -- 修改AssignNPCIdentity函数，添加绰号分配
    function AssignNPCIdentity(ent, npcInfo)
        local identity = {}

        identity.info = npcInfo
        identity.model = ent:GetModel()
        identity.nickname = GLOBAL_OFNPC_DATA.names.nicknames[math.random(#GLOBAL_OFNPC_DATA.names.nicknames)]
        
        local gamename = list.Get( "NPC" )[identity.info] and list.Get( "NPC" )[identity.info].Name
        if gamename then
            identity.gamename = gamename
        end

        if npcInfo == "npc_citizen" then
            if string.find(identity.model, "group03m") then
                identity.job = "citizen.job.medic"
                identity.type = "medic"
                identity.color = Color(245, 78, 162)
            else
                identity.job = GLOBAL_OFNPC_DATA.jobData.citizen[math.random(#GLOBAL_OFNPC_DATA.jobData.citizen)].job
                identity.type = "citizen"  -- 默认类型
                if string.find(identity.model, "group01") then
                    identity.type = "citizen"
                    identity.color = Color(1, 205, 200)
                elseif string.find(identity.model, "group02") then
                    identity.type = "refugee"
                    identity.color = Color(255, 204, 0)
                elseif string.find(identity.model, "group03") then
                    identity.type = "rebel"
                    identity.color = Color(255, 141, 23)
                end
            end

            identity.rank = math.random(1, 39)
            identity.exp = 0
            identity.exp_per_rank = CalculateExpNeeded(identity.rank)

            if string.find(identity.model, "female") then
                identity.gender = "female"
            elseif string.find(identity.model, "male") then
                identity.gender = "male"
            end

            local jobSpecializations = {}

            -- 加载职业细分
            for _, job in ipairs(GLOBAL_OFNPC_DATA.jobData.citizen) do
                local jobName = job.job
                jobSpecializations[jobName] = job.specializations
            end
            
            if jobSpecializations[identity.job] then
                local specs = jobSpecializations[identity.job]
                identity.specialization = specs[math.random(#specs)]
            end

            -- 根据性别分配名字
            if identity.gender == "female" then
                identity.name = GLOBAL_OFNPC_DATA.names.female[math.random(#GLOBAL_OFNPC_DATA.names.female)]
            else
                identity.name = GLOBAL_OFNPC_DATA.names.male[math.random(#GLOBAL_OFNPC_DATA.names.male)]
            end
        elseif npcInfo == "npc_metropolice" then
            identity.type = "metropolice"
            identity.rank = math.random(1, 39)
            identity.job = GLOBAL_OFNPC_DATA.jobData.citizen[math.random(#GLOBAL_OFNPC_DATA.jobData.citizen)].job
            identity.exp = 0
            identity.exp_per_rank = CalculateExpNeeded(identity.rank)
            identity.name = GLOBAL_OFNPC_DATA.names.male[math.random(#GLOBAL_OFNPC_DATA.names.male)]
            identity.color = Color(135, 223, 214)
        elseif npcInfo == "npc_combine_s" then
            identity.type = "combine"
            identity.rank = math.random(1, 39)
            identity.job = GLOBAL_OFNPC_DATA.jobData.citizen[math.random(#GLOBAL_OFNPC_DATA.jobData.citizen)].job
            identity.exp = 0
            identity.exp_per_rank = CalculateExpNeeded(identity.rank)
            identity.name = GLOBAL_OFNPC_DATA.names.male[math.random(#GLOBAL_OFNPC_DATA.names.male)]
            identity.color = Color(0, 149, 223)
        else
            identity.type = "other"
            identity.name = GLOBAL_OFNPC_DATA.names.male[math.random(#GLOBAL_OFNPC_DATA.names.male)]
        end

        -- 在分配完基本信息后添加tag分配
        if identity.job then
            -- 分配能力tag
            if GLOBAL_OFNPC_DATA.tagData.tag_ability[identity.job] then
                local abilityTag = GLOBAL_OFNPC_DATA.tagData.tag_ability[identity.job]
                identity.tag_ability = abilityTag.id
                identity.tag_ability_desc = abilityTag.desc
            end
        end
        
        -- 分配交易和社交tag
        if GLOBAL_OFNPC_DATA.tagData.tag_trade and #GLOBAL_OFNPC_DATA.tagData.tag_trade > 0 then
            local tradeTag = GLOBAL_OFNPC_DATA.tagData.tag_trade[math.random(#GLOBAL_OFNPC_DATA.tagData.tag_trade)]
            identity.tag_trade = tradeTag.id
            identity.tag_trade_desc = tradeTag.desc
        end
        
        if GLOBAL_OFNPC_DATA.tagData.tag_social and #GLOBAL_OFNPC_DATA.tagData.tag_social > 0 then
            local socialTag = GLOBAL_OFNPC_DATA.tagData.tag_social[math.random(#GLOBAL_OFNPC_DATA.tagData.tag_social)]
            identity.tag_social = socialTag.id
            identity.tag_social_desc = socialTag.desc
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
            if type(value) == "string" then
                print(key .. ": " .. value)
            else
                print(key .. ": " .. tostring(value))  -- 确保将非字符串值转换为字符串
            end
        end
        print("================")
    end
    
    hook.Add("OnEntityCreated", "NPCPersonality", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) or not ent:IsNPC() then return end  -- 检查实体是否仍然有效
            
            local class = ent:GetClass()

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

    -- 在其他网络接收函数后添加
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

    -- 客户端没有清理已移除NPC的数据
    hook.Add("EntityRemoved", "CleanupClientNPCData", function(ent)
        if IsValid(ent) and ent:IsNPC() then
            clientNPCs[ent:EntIndex()] = nil
        end
    end)
end