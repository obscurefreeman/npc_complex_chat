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
    },
    lang = {}
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

local function SerializeTable(tbl, indent, seen)
    indent = indent or 1
    seen = seen or {}
    local str = "{\n"
    local spaces = string.rep("    ", indent)

    if seen[tbl] then
        return "\"<循环引用>\""
    end
    seen[tbl] = true
    
    for k, v in pairs(tbl) do
        local key = type(k) == "string" and ("[\""..k.."\"]") or ("["..k.."]")
        if type(v) == "table" then
            str = str .. spaces .. key .. " = " .. SerializeTable(v, indent + 1, seen) .. ",\n"
        else
            local value = type(v) == "string" and ("\""..v.."\"") or tostring(v)
            str = str .. spaces .. key .. " = " .. value .. ",\n"
        end
    end
    
    return str .. string.rep("    ", indent - 1) .. "}"
end

local function SaveGlobalData()
    -- 保存全局变量
    local filePath = "of_npcp/global_data.txt"
    local fileData = "-- 全局变量数据\nGLOBAL_OFNPC_DATA = " .. SerializeTable(GLOBAL_OFNPC_DATA)
    file.Write(filePath, fileData)
end

-- 修改加载方式
local function LoadNPCData()
    LoadJsonData("data/of_npcp/jobs.json", "jobData")
    LoadJsonData("data/of_npcp/name.json", "names")
    LoadJsonData("data/of_npcp/tags.json", "tagData")
    LoadJsonData("data/of_npcp/player_talk.json", "playerTalks")
    LoadJsonData("data/of_npcp/citizen_talk.json", "npcTalks")
    LoadJsonData("data/of_npcp/cards_new.json", "cards")
    LoadJsonData("data/of_npcp/anim.json", "anim")
    LoadJsonData("data/of_npcp/article.json", "article")
    LoadJsonData("data/of_npcp/sponsors.json", "sponsors")
    LoadJsonData("data/of_npcp/ai/providers.json", "aiProviders")
    LoadJsonData("data/of_npcp/ai/voice.json", "voice")
    LoadJsonData("data/of_npcp/language.json", "lang")

    -- 存储语言
    for lang, _ in pairs(GLOBAL_OFNPC_DATA.lang.language) do
        GLOBAL_OFNPC_DATA.lang[lang] = {}
        local jsonFiles = file.Find("data/of_npcp/lang/" .. lang .. "/*.json", "GAME")
        for _, jsonFile in ipairs(jsonFiles) do
            local jsonData = file.Read("data/of_npcp/lang/" .. lang .. "/" .. jsonFile, "GAME")
            if jsonData then
                local success, data = pcall(util.JSONToTable, jsonData)
                if success and data then
                    table.Merge(GLOBAL_OFNPC_DATA.lang[lang], data)
                end
            end
        end
    end

    SaveGlobalData()

    -- include("garrylord/data_backup.lua")
end

-- 在服务器启动时加载数据
hook.Add("Initialize", "LoadNPCData", LoadNPCData)