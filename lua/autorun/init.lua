GLOBAL_OFNPC_DATA = {
    jobData = {},
    names = {},
    tagData = {},
    playerTalks = {},
    npcTalks = {},
    cards = {},
    anim = {},
    log = {},
    aiProviders = {},
    voice = {},
    cards = {
        info = {},
        general = {}
    }
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
    LoadJsonData("data/of_npcp/player_talk.json", "playerTalks")
    LoadJsonData("data/of_npcp/citizen_talk.json", "npcTalks")
    LoadJsonData("data/of_npcp/cards.json", "cards")
    LoadJsonData("data/of_npcp/anim.json", "anim")
    LoadJsonData("data/of_npcp/log.json", "log")
    LoadJsonData("data/of_npcp/sponsors.json", "sponsors")
    LoadJsonData("data/of_npcp/ai/providers.json", "aiProviders")
    LoadJsonData("data/of_npcp/ai/voice.json", "voice")
end

-- 在服务器启动时加载数据
hook.Add("Initialize", "LoadNPCData", LoadNPCData)