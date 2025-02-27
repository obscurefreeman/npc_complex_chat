GLOBAL_OFNPC_DATA = {
    jobData = {},
    names = {},
    tagData = {},
    rankData = {},
    playerTalks = {},
    npcTalks = {},
    cards = {}
}

-- 加载JSON文件的通用函数
local function LoadJsonData(filePath, globalKey)
    local jsonData = file.Read(filePath, "GAME")
    if jsonData then
        local success, data = pcall(util.JSONToTable, jsonData)
        if success and data then
            GLOBAL_OFNPC_DATA[globalKey] = data  -- 存储在全局变量中
        else
            print("【晦涩弗里曼】解析 " .. filePath .. " 时出错。")
        end
    else
        print("【晦涩弗里曼】无法加载 " .. filePath .. "。")
    end
end

-- 加载数据
local function LoadNPCData()
    LoadJsonData("data/of_npcp/jobs.json", "jobData")
    LoadJsonData("data/of_npcp/name.json", "names")
    LoadJsonData("data/of_npcp/tags.json", "tagData")
    LoadJsonData("data/of_npcp/combine_ranks.json", "rankData")
    LoadJsonData("data/of_npcp/player_talk.json", "playerTalks")
    LoadJsonData("data/of_npcp/citizen_talk.json", "npcTalks")
    LoadJsonData("data/of_npcp/cards.json", "cards")

    -- 在加载数据后添加调试信息
    -- print("【自由调试】:", util.TableToJSON(GLOBAL_OFNPC_DATA.rankData.ranks, true))
end

-- 在服务器启动时加载数据
hook.Add("Initialize", "LoadNPCData", LoadNPCData)