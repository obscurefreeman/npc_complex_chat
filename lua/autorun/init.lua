-- 加载基础数据，基础数据是固定的，也就是GLOBAL_OFNPC_DATA_BASIC
AddCSLuaFile("garryload/data.lua")
include("garryload/data.lua")

-- 已经加载的自定义数据，已经挂载到服务器
GLOBAL_OFNPC_DATA_CUSTOM = {}

-- 创建一个元表来实现动态数据替换
local meta = {
    __index = function(t, k)
        -- 优先在GLOBAL_OFNPC_DATA_CUSTOM里找，如果没有则在GLOBAL_OFNPC_DATA_BASIC里找
        return GLOBAL_OFNPC_DATA_CUSTOM[k] or GLOBAL_OFNPC_DATA_BASIC[k]
    end
}

-- 加载了自定义数据，最终呈现的数据。GLOBAL_OFNPC_DATA_CUSTOM会替换GLOBAL_OFNPC_DATA_BASIC的对应内容
GLOBAL_OFNPC_DATA = setmetatable({}, meta)

if SERVER then
    -- 先阅读本地保存的文件
    GLOBAL_OFNPC_DATA_CUSTOM = util.JSONToTable(file.Read("of_npcp/custom.txt", "DATA") or "{}")
    -- 然后将自定义内容发送到所有客户端
    net.Start("SyncCustomData")
        net.WriteTable(GLOBAL_OFNPC_DATA_CUSTOM)
    net.Broadcast()
end

if CLIENT then
    -- 客户端接收自定义数据
    net.Receive("SyncCustomData", function()
        GLOBAL_OFNPC_DATA_CUSTOM = net.ReadTable()
    end)
end