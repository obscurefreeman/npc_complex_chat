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

-- 修改加载方式
local function LoadNPCData()
    include("garrylord/data_backup.lua")
end

-- 在服务器启动时加载数据
hook.Add("Initialize", "LoadNPCData", LoadNPCData)