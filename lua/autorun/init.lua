GLOBAL_OFNPC_DATA = {
    citizenJobs = {},
    maleNames = {},
    femaleNames = {},
    tagData = {},
    rankData = {},
    nicknames = {},
    playerTalks = {},
    npcTalks = {}
}

-- 加载JSON文件
local function LoadNPCData()
    local citizenData = file.Read("data/of_npcp/citizen_jobs.json", "GAME")

    if citizenData then
        local success, data = pcall(util.JSONToTable, citizenData)
        if success and data then
            GLOBAL_OFNPC_DATA.citizenJobs = data.jobs  -- 存储在全局变量中
        else
            print("【晦涩弗里曼】解析 citizen_jobs.json 时出错。")
        end
    else
        print("【晦涩弗里曼】无法加载 citizen_jobs.json。")
    end

    -- 加载名字数据
    local maleNamesData = file.Read("data/of_npcp/name_male.json", "GAME")
    local femaleNamesData = file.Read("data/of_npcp/name_female.json", "GAME")

    if maleNamesData then
        local success, data = pcall(util.JSONToTable, maleNamesData)
        if success and data then
            GLOBAL_OFNPC_DATA.maleNames = data.names  -- 存储在全局变量中
        else
            print("【晦涩弗里曼】解析 name_male.json 时出错。")
        end
    end

    if femaleNamesData then
        local success, data = pcall(util.JSONToTable, femaleNamesData)
        if success and data then
            GLOBAL_OFNPC_DATA.femaleNames = data.names  -- 存储在全局变量中
        else
            print("【晦涩弗里曼】解析 name_female.json 时出错。")
        end
    end

    -- 加载tag数据
    local tagJsonData = file.Read("data/of_npcp/tags.json", "GAME")
    if tagJsonData then
        local success, data = pcall(util.JSONToTable, tagJsonData)
        if success and data then
            GLOBAL_OFNPC_DATA.tagData = data  -- 存储在全局变量中
        else
            print("【晦涩弗里曼】解析 tags.json 时出错。")
        end
    end

    local rankJsonData = file.Read("data/of_npcp/combine_ranks.json", "GAME")
    if rankJsonData then
        local success, data = pcall(util.JSONToTable, rankJsonData)
        if success and data then
            GLOBAL_OFNPC_DATA.rankData = data.ranks  -- 存储在全局变量中
        else
            print("【晦涩弗里曼】解析 combine_ranks.json 时出错。")
        end
    end

    local nicknameData = file.Read("data/of_npcp/citizen_nickname.json", "GAME")
    if nicknameData then
        local success, data = pcall(util.JSONToTable, nicknameData)
        if success and data then
            GLOBAL_OFNPC_DATA.nicknames = data.nicknames
        else
            print("【晦涩弗里曼】解析 citizen_nickname.json 时出错。")
        end
    else
        print("【晦涩弗里曼】无法加载 citizen_nickname.json。")
    end

    local playerTalkData = file.Read("data/of_npcp/player_talk.json", "GAME")
    if playerTalkData then
        local success, data = pcall(util.JSONToTable, playerTalkData)
        if success and data then
            GLOBAL_OFNPC_DATA.playerTalks = data
        else
            print("【晦涩弗里曼】解析 player_talk.json 时出错。")
        end
    else
        print("【晦涩弗里曼】无法加载 player_talk.json。")
    end

    local npcTalkData = file.Read("data/of_npcp/citizen_talk.json", "GAME")
    if npcTalkData then
        local success, data = pcall(util.JSONToTable, npcTalkData)
        if success and data then
            GLOBAL_OFNPC_DATA.npcTalks = data
        else
            print("【晦涩弗里曼】解析 npc_talk.json 时出错。")
        end
    else
        print("【晦涩弗里曼】无法加载 npc_talk.json。")
    end

    -- print("【调试】GLOBAL_OFNPC_DATA:", util.TableToJSON(GLOBAL_OFNPC_DATA, true))

    -- 在加载数据后添加调试信息
    print("【自由调试】:", util.TableToJSON(GLOBAL_OFNPC_DATA.rankData, true))
end

-- 在服务器启动时加载数据
hook.Add("Initialize", "LoadNPCData", LoadNPCData)