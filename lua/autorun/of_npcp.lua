if SERVER then
    -- 将 OFNPCS 设置为全局变量
    OFNPCS = {}
    OFPLAYERS = OFPLAYERS or {}  -- 确保OFPLAYERS被初始化

    -- 添加网络字符串
    util.AddNetworkString("OFNPCP_NS_NPCIdentityUpdate")
    util.AddNetworkString("OFNPCP_NS_UpdateNPCName")
    util.AddNetworkString("OFNPCP_NS_NPCAction")
    util.AddNetworkString("OFNPCP_NS_SubmitNPCComment")
    util.AddNetworkString("OFNPCP_NS_RankUp")
    util.AddNetworkString("OFNPCP_NS_NPCAIDialog")  -- 新增AI对话网络消息

    util.AddNetworkString("OFNPCP_NS_TalkStart")
    util.AddNetworkString("OFNPCP_NS_OpenNPCDialogMenu")
    util.AddNetworkString("OFNPCP_NS_RequestClientNPCData")
    util.AddNetworkString("OFNPCP_NS_SendClientNPCData")
    util.AddNetworkString("OFNPCP_NS_PlayerDialog")
    util.AddNetworkString("OFNPCP_NS_NPCDialogMenuOpened")
    util.AddNetworkString("OFNPCP_NS_NPCDialogMenuClosed")

    util.AddNetworkString("OFNPCP_NS_SelectPlayerDeck")
    util.AddNetworkString("OFNPCP_NS_UpdatePlayerDeck")
    util.AddNetworkString("OFNPCP_NS_UpdateNPCPrompt")
    util.AddNetworkString("OFNPCP_NS_UpdatePlayerVoice")
    util.AddNetworkString("OFNPCP_NS_RequestPlayerDataSync")
    util.AddNetworkString("OFNPCP_NS_UpdateAllPlayerData")
    util.AddNetworkString("OFNPCP_NS_UpdateNPCVoice")
    util.AddNetworkString("OFNPCP_NS_RequestNPCData")
    util.AddNetworkString("OFNPCP_NS_AddtoKillfeed")
    util.AddNetworkString("OFNPCP_NS_SaveModelSettings")
    util.AddNetworkString("OFNPCP_NS_SaveBlockedBodygroups")

    function AssignNPCIdentity(ent, npcInfo)
        local identity = {}

        identity.info = npcInfo
        identity.model = ent:GetModel()
        identity.nickname = GLOBAL_OFNPC_DATA.names.nicknames[math.random(#GLOBAL_OFNPC_DATA.names.nicknames)]
        identity.anim = GLOBAL_OFNPC_DATA.setting.npc_setting[npcInfo].anim
        identity.rank = math.random(1, 33)
        identity.exp = 0
        identity.exp_per_rank = CalculateExpNeeded(identity.rank)
        identity.dialogHistory = {}

        -- 声音列表初始化，根据服务器语言确定
        
        local gamename = list.Get( "NPC" )[identity.info] and list.Get( "NPC" )[identity.info].Name
        if gamename then
            identity.gamename = gamename
        end

        local femaleVoices = {}
        local maleVoices = {}
        
        local serverLang = GetConVar("gmod_language"):GetString()

        if not GLOBAL_OFNPC_DATA.lang.language[serverLang] then
            serverLang = "en"
        end

        for _, voice in ipairs(GLOBAL_OFNPC_DATA.voice.voices) do
            if voice.language == serverLang then
                for _, v in ipairs(voice.voices) do
                    if v.gender == "female" then
                        table.insert(femaleVoices, v.code)
                    elseif v.gender == "male" then
                        table.insert(maleVoices, v.code)
                    end
                end
            end
        end

        -- 第一步，查找模型设置
        local modelSetting = GLOBAL_OFNPC_DATA.setting.model_setting and GLOBAL_OFNPC_DATA.setting.model_setting[identity.model]
        if modelSetting then
            -- 应用所有模型设置
            for k, v in pairs(modelSetting) do
                identity[k] = v
            end
        else
            -- 第二步，查找NPC种类设置
            local npcSetting = GLOBAL_OFNPC_DATA.setting.npc_setting[identity.info]
            if npcSetting then
                -- 应用所有NPC设置
                for k, v in pairs(npcSetting) do
                    identity[k] = v
                end
            end
        end

        -- 第三步，处理没有的情况

        -- 如果没有设置性别，则通过模型名称判断性别

        if not identity.gender then
            if string.find(identity.model, "female") then
                identity.gender = "female"
            elseif string.find(identity.model, "male") then
                identity.gender = "male"
            else
                identity.gender = "male"
            end
        end

        -- 根据性别分配名字和配音
        if identity.gender == "female" then
            identity.voice = femaleVoices[math.random(#femaleVoices)]
        else
            identity.voice = maleVoices[math.random(#maleVoices)]
        end

        if not identity.name and identity.type ~= "maincharacter" then
            -- 只有这几种能随机分配姓名
            if identity.gender == "female" then
                identity.name = GLOBAL_OFNPC_DATA.names.female[math.random(#GLOBAL_OFNPC_DATA.names.female)]
            else
                identity.name = GLOBAL_OFNPC_DATA.names.male[math.random(#GLOBAL_OFNPC_DATA.names.male)]
            end
        else
            -- 否则使用游戏的名称
            identity.name = gamename
        end

        -- 如果没有阵营，则分配阵营

        if not identity.camp then
            local camps = {
                "resistance", 
                "union",
                "warlord",
                "church",
                "bandit",
                "other"
            }
            identity.camp = camps[math.random(#camps)]
        end

        -- 如果没有职业，则通过模型名称判断职业

        if not identity.job then
            if string.find(identity.model, "group03m") then
                identity.job = "citizen.job.medic"
            else
                identity.job = GLOBAL_OFNPC_DATA.jobData.citizen[math.random(#GLOBAL_OFNPC_DATA.jobData.citizen)].job
            end
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

        -- 如果没有提示词，则根据阵营判断提示词
        if not identity.prompt then
            identity.prompt = GLOBAL_OFNPC_DATA.setting.camp_setting[identity.camp].prompt
        end

        -- 优化后的tag分配逻辑
        local function AssignTag(category, specific)
            if specific then
                -- 分配特定tag
                local tagID = GLOBAL_OFNPC_DATA.tag[category][specific]
                if tagID then
                    identity["tag_"..category] = tagID
                end
            else
                -- 随机分配tag
                local tags = GLOBAL_OFNPC_DATA.tag[category]
                if tags and #tags > 0 then
                    local tag = tags[math.random(#tags)]
                    identity["tag_"..category] = tag
                end
            end
        end

        AssignTag("ability", identity.job)
        AssignTag("trade")
        AssignTag("social")

        -- 替换模型
        local randommodel = OFNPCP_ReplaceNPCModel( ent, identity )

        -- print("[OFNPCP] 随机模型: " .. (randommodel or "无"))
        -- if randombodygroups and #randombodygroups > 0 then
        --     print("[OFNPCP] 随机身体组:")
        --     for _, bg in ipairs(randombodygroups) do
        --         print("  ID: " .. bg.id .. ", 值: " .. bg.num)
        --     end
        -- else
        --     print("[OFNPCP] 随机身体组: 无")
        -- end
        -- print("[OFNPCP] 随机皮肤: " .. (randomskin or "无"))

        -- 读取替换后的模型
        if randommodel then
            identity.model = randommodel
        end
        -- if randombodygroups and #randombodygroups > 0 then
        --     identity.bodygroups = randombodygroups
        -- end
        -- if randomskin then
        --     identity.skin = randomskin
        -- end

        -- 存储NPC身份信息
        OFNPCS[ent:EntIndex()] = identity
        
        -- 向客户端广播NPC身份信息
        net.Start("OFNPCP_NS_NPCIdentityUpdate")
            net.WriteEntity(ent)
            net.WriteTable(identity)
        net.Broadcast()

        -- 在控制台打印NPC信息
        -- print("\n=== 新NPC生成 ===")
        -- for key, value in pairs(identity) do
        --     if type(value) == "string" then
        --         print(key .. ": " .. value)
        --     else
        --         print(key .. ": " .. tostring(value))  -- 确保将非字符串值转换为字符串
        --     end
        -- end
        -- print("================")
    end
    
    hook.Add("OnEntityCreated", "NPCPersonality", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) or not ent:IsNPC() or not ent:LookupBone("ValveBiped.Bip01_Head1") then return end
            
            local class = ent:GetClass()

            if GLOBAL_OFNPC_DATA.setting.npc_setting[class] then
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
    net.Receive("OFNPCP_NS_UpdateNPCName", function(len, ply)
        local entIndex = net.ReadInt(32)
        local newName = net.ReadString()
        local newNickname = net.ReadString()
        
        if OFNPCS[entIndex] then
            OFNPCS[entIndex].name = newName
            OFNPCS[entIndex].nickname = newNickname
            
            -- 广播更新后的身份信息给所有客户端
            net.Start("OFNPCP_NS_NPCIdentityUpdate")
                net.WriteEntity(Entity(entIndex))
                net.WriteTable(OFNPCS[entIndex])
            net.Broadcast()
        end
    end)

    -- 在其他网络接收函数后添加
    net.Receive("OFNPCP_NS_NPCAction", function(len, ply)
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
    net.Receive("OFNPCP_NS_SubmitNPCComment", function(len, ply)
        local entIndex = net.ReadInt(32)
        local comment = net.ReadString()

        if OFNPCS[entIndex] then
            -- 如果评论表不存在，则初始化
            if not OFNPCS[entIndex].comments then
                OFNPCS[entIndex].comments = {}
            end

            local playerDeck = OFPLAYERS[ply:SteamID()] and OFPLAYERS[ply:SteamID()].deck or "resistance"
            local deckColor = GLOBAL_OFNPC_DATA.setting.camp_setting[playerDeck].color

            -- 添加评论
            table.insert(OFNPCS[entIndex].comments, {
                player = ply:Nick(),
                model = ply:GetModel(),
                comment = comment,
                color = deckColor
            })

            -- 广播更新后的身份信息给所有客户端
            net.Start("OFNPCP_NS_NPCIdentityUpdate")
                net.WriteEntity(Entity(entIndex))
                net.WriteTable(OFNPCS[entIndex])
            net.Broadcast()
        end
    end)

    -- 添加加载玩家数据的函数
    local function LoadPlayerData(ply)
        local data = file.Read("of_npcp/playerdata.txt", "DATA")
        if data then
            local playerData = util.JSONToTable(data)
            local steamID = ply:SteamID()
            if playerData[steamID] then
                OFPLAYERS[steamID] = {
                    deck = playerData[steamID].deck,
                    voice = playerData[steamID].voice or "zh-CN-XiaoyiNeural"
                }
            else
                OFPLAYERS[steamID] = {
                    deck = "resistance",
                    voice = "zh-CN-XiaoyiNeural"
                }
            end
        else
            OFPLAYERS[ply:SteamID()] = {
                deck = "resistance",
                voice = "zh-CN-XiaoyiNeural"
            }
        end
    end

    -- 玩家加入时加载数据
    hook.Add("PlayerInitialSpawn", "LoadPlayerDeck", function(ply)
        LoadPlayerData(ply)
    end)

    -- 修改保存玩家数据的函数
    local function SavePlayerData()
        if not file.IsDir("of_npcp", "DATA") then
            file.CreateDir("of_npcp")
        end
        local playerData = {}
        for steamID, data in pairs(OFPLAYERS) do
            playerData[steamID] = {
                deck = data.deck,
                voice = data.voice  -- 保存配音设置
            }
        end
        file.Write("of_npcp/playerdata.txt", util.TableToJSON(playerData))
        
        -- 广播更新后的玩家数据给所有客户端
        net.Start("OFNPCP_NS_UpdateAllPlayerData")
            net.WriteTable(playerData)
        net.Broadcast()
    end

    -- 处理玩家牌组选择
    net.Receive("OFNPCP_NS_SelectPlayerDeck", function(len, ply)
        local deck = net.ReadString()
        if not OFPLAYERS[ply:SteamID()] then
            OFPLAYERS[ply:SteamID()] = {}
        end
        OFPLAYERS[ply:SteamID()].deck = deck

        SavePlayerData()
        
        -- 广播给所有客户端
        net.Start("OFNPCP_NS_UpdatePlayerDeck")
            net.WriteString(ply:SteamID())
            net.WriteString(deck)
        net.Broadcast()
    end)

    -- 添加调试命令
    concommand.Add("of_garrylord_debug", function(ply)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        
        print("\n=== 当前所有NPC数据 ===")
        if not next(OFNPCS) then
            print("没有已生成的NPC")
            return
        end
        
        for entIndex, npcData in pairs(OFNPCS) do
            PrintTable(npcData)
            print("----------------------")
        end

        print("\n=== 当前所有玩家数据 ===")
        if not next(OFPLAYERS) then
            print("没有玩家数据")
            return
        end
        
        for entIndex, playerData in pairs(OFPLAYERS) do
            PrintTable(playerData)
            print("----------------------")
        end

        -- 请求客户端数据
        net.Start("OFNPCP_NS_RequestClientNPCData")
        net.Send(ply)
    end)

    -- 接收客户端数据
    net.Receive("OFNPCP_NS_SendClientNPCData", function(len, ply)
        local clientNPCs = net.ReadTable()
        
        print("\n=== 客户端NPC数据 ===")
        if not next(clientNPCs) then
            print("没有客户端NPC数据")
            return
        end
        
        for entIndex, npcData in pairs(clientNPCs) do
            PrintTable(npcData)
            print("----------------------")
        end
    end)

    -- 接收客户端请求更新NPC提示词的处理函数
    net.Receive("OFNPCP_NS_UpdateNPCPrompt", function(len, ply)
        local entIndex = net.ReadInt(32)
        local newPrompt = net.ReadString()
        
        if OFNPCS[entIndex] then
            OFNPCS[entIndex].prompt = newPrompt
            
            -- 广播更新后的身份信息给所有客户端
            net.Start("OFNPCP_NS_NPCIdentityUpdate")
                net.WriteEntity(Entity(entIndex))
                net.WriteTable(OFNPCS[entIndex])
            net.Broadcast()
        end
    end)

    -- 在服务器端添加接收处理函数
    net.Receive("OFNPCP_NS_UpdateNPCVoice", function(len, ply)
        local entIndex = net.ReadInt(32)
        local newVoice = net.ReadString()
        
        if OFNPCS[entIndex] then
            OFNPCS[entIndex].voice = newVoice
            
            -- 广播更新后的身份信息给所有客户端
            net.Start("OFNPCP_NS_NPCIdentityUpdate")
                net.WriteEntity(Entity(entIndex))
                net.WriteTable(OFNPCS[entIndex])
            net.Broadcast()
        end
    end)

    -- 添加接收玩家配音设置的处理函数
    net.Receive("OFNPCP_NS_UpdatePlayerVoice", function(len, ply)
        local voiceCode = net.ReadString()
        if not OFPLAYERS[ply:SteamID()] then
            OFPLAYERS[ply:SteamID()] = {}
        end
        OFPLAYERS[ply:SteamID()].voice = voiceCode
        
        -- 保存玩家数据
        SavePlayerData()
    end)

    -- 添加接收所有玩家数据的处理函数
    net.Receive("OFNPCP_NS_UpdateAllPlayerData", function()
        local playerData = net.ReadTable()
        OFPLAYERS = playerData
    end)

    -- 添加接收客户端请求数据的处理函数
    net.Receive("OFNPCP_NS_RequestPlayerDataSync", function(len, ply)
        net.Start("OFNPCP_NS_UpdateAllPlayerData")
            net.WriteTable(OFPLAYERS)
        net.Send(ply)
    end)

    -- 添加处理客户端请求NPC数据的函数
    net.Receive("OFNPCP_NS_RequestNPCData", function(len, ply)
        local entIndex = net.ReadInt(32)
        local ent = Entity(entIndex)
        
        if IsValid(ent) and ent:IsNPC() and OFNPCS[entIndex] then
            net.Start("OFNPCP_NS_NPCIdentityUpdate")
                net.WriteEntity(ent)
                net.WriteTable(OFNPCS[entIndex])
            net.Send(ply)
        end
    end)
end

if CLIENT then
    OFPLAYERS = OFPLAYERS or {}
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
    net.Receive("OFNPCP_NS_NPCIdentityUpdate", function()
        local ent = net.ReadEntity()
        local identity = net.ReadTable()
        if IsValid(ent) then
            clientNPCs[ent:EntIndex()] = identity
            -- 添加hook触发
            hook.Run("OnNPCIdentityUpdated", ent, identity)
            hook.Run("NPCListUpdated")
        end
    end)

    net.Receive("OFNPCP_NS_UpdatePlayerDeck", function()
        local steamID = net.ReadString()
        local deck = net.ReadString()
        if not OFPLAYERS[steamID] then
            OFPLAYERS[steamID] = {}
        end
        OFPLAYERS[steamID].deck = deck
    end)

    -- 客户端没有清理已移除NPC的数据
    hook.Add("EntityRemoved", "CleanupClientNPCData", function(ent)
        if IsValid(ent) and ent:IsNPC() then
            clientNPCs[ent:EntIndex()] = nil
        end
    end)

    -- 接收服务器请求客户端数据的消息
    net.Receive("OFNPCP_NS_RequestClientNPCData", function()
        net.Start("OFNPCP_NS_SendClientNPCData")
        net.WriteTable(clientNPCs)
        net.SendToServer()
    end)

    -- 添加接收所有玩家数据的处理函数
    net.Receive("OFNPCP_NS_UpdateAllPlayerData", function()
        local playerData = net.ReadTable()
        OFPLAYERS = playerData
    end)

    -- 在客户端初始化时主动请求数据
    hook.Add("InitPostEntity", "RequestPlayerData", function()
        net.Start("OFNPCP_NS_RequestPlayerDataSync")
        net.SendToServer()
    end)

    -- 定时检查NPC同步
    local function CheckNPCSync()
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() and ent:LookupBone("ValveBiped.Bip01_Head1") then
                local class = ent:GetClass()
                if GLOBAL_OFNPC_DATA.setting.npc_setting[class] then
                    local entIndex = ent:EntIndex()
                    if not clientNPCs[entIndex] then
                        -- 如果客户端没有该NPC的数据，向服务器请求
                        net.Start("OFNPCP_NS_RequestNPCData")
                        net.WriteInt(entIndex, 32)
                        net.SendToServer()
                        -- print("向服务器请求NPC数据，实体索引：" .. entIndex)
                    end
                end
            end
        end
    end

    -- 每5秒检查一次NPC同步
    timer.Create("NPCSyncCheck", 5, 0, CheckNPCSync)
end