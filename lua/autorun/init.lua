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
            return true
        else
            print("【晦涩弗里曼】解析 " .. filePath .. " 时出错。")
        end
    else
        print("【晦涩弗里曼】无法加载 " .. filePath .. "。")
    end
    return false
end

local function LoadFromLuaBackup()
    if file.Exists("lua/garrylord/data_backup.lua", "GAME") then
        include("garrylord/data_backup.lua")
        return true
    end
    return false
end

local function SaveJsonData(globalKey, filePath)
    local data = GLOBAL_OFNPC_DATA[globalKey]
    if data then
        file.Write(filePath, util.TableToJSON(data, true))
    end
end

local function RestoreJsonFiles()
    if not GLOBAL_OFNPC_DATA._file_paths then return end
    
    for key, path in pairs(GLOBAL_OFNPC_DATA._file_paths) do
        local data = GLOBAL_OFNPC_DATA[key]
        if data then
            local full_path = "data/of_npcp/" .. path
            -- 创建目录（如果不存在）
            local dir = string.match(full_path, "^(.*)/[^/]*$")
            if dir and not file.IsDir(dir, "GAME") then
                file.CreateDir(dir)
            end
            file.Write(full_path, util.TableToJSON(data, true))
        end
    end
end

-- 定义所有需要加载的JSON文件及其对应的全局键
local json_files = {
    ["data/of_npcp/jobs.json"] = "jobData",
    ["data/of_npcp/name.json"] = "names",
    ["data/of_npcp/tags.json"] = "tagData",
    ["data/of_npcp/player_talk.json"] = "playerTalks",
    ["data/of_npcp/citizen_talk.json"] = "npcTalks",
    ["data/of_npcp/cards_new.json"] = "cards",
    ["data/of_npcp/anim.json"] = "anim",
    ["data/of_npcp/article.json"] = "article",
    ["data/of_npcp/sponsors.json"] = "sponsors",
    ["data/of_npcp/ai/providers.json"] = "aiProviders",
    ["data/of_npcp/ai/voice.json"] = "voice",
    ["data/of_npcp/language.json"] = "lang"
}

-- 加载数据
local function LoadNPCData()
    local missing_files = false
    
    -- 检查所有JSON文件
    for file_path, global_key in pairs(json_files) do
        if not LoadJsonData(file_path, global_key) then
            missing_files = true
        end
    end
    
    -- 如果有文件缺失，尝试从备份恢复
    if missing_files then
        if LoadFromLuaBackup() then
            RestoreJsonFiles()
            -- 重新加载所有JSON文件
            for file_path, global_key in pairs(json_files) do
                LoadJsonData(file_path, global_key)
            end
        end
    end
end

-- 在服务器启动时加载数据
hook.Add("Initialize", "LoadNPCData", LoadNPCData)