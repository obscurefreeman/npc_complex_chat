local LANG = {}
LANG.CurrentLanguage = "en"
LANG.LanguageData = {}
LANG.LanguageList = {}  -- 新增：用于存储语言列表

-- 修改：直接使用全局变量中的语言列表
function LANG:LoadLanguageList()
    if GLOBAL_OFNPC_DATA and GLOBAL_OFNPC_DATA.lang and GLOBAL_OFNPC_DATA.lang.language then
        self.LanguageList = GLOBAL_OFNPC_DATA.lang.language
        return true
    end
    return false
end

-- 修改：直接使用全局变量中的语言数据
function LANG:LoadLanguageFolder(lang)
    if GLOBAL_OFNPC_DATA and GLOBAL_OFNPC_DATA.lang and GLOBAL_OFNPC_DATA.lang[lang] then
        self.LanguageData[lang] = GLOBAL_OFNPC_DATA.lang[lang]
        return true
    end
    return false
end

-- 设置当前语言
function LANG:SetLanguage(lang)
    if not self.LanguageData[lang] then
        if not self:LoadLanguageFolder(lang) then
            return false
        end
    end
    self.CurrentLanguage = lang
    return true
end

-- 获取翻译文本
function LANG:GetPhrase(key)
    -- if not key or type(key) ~= "string" then
    --     ErrorNoHalt("[LANG] GetPhrase: Invalid key - " .. tostring(key) .. "\n")
    --     return "INVALID_KEY"
    -- end
    
    local result = self:GetPhraseInLanguage(self.CurrentLanguage, key)
    
    if self.CurrentLanguage ~= "en" and result == key then
        result = self:GetPhraseInLanguage("en", key)
    end
    
    return result
end

function LANG:GetPhraseInLanguage(lang, key)
    -- if not key or type(key) ~= "string" then
    --     ErrorNoHalt("[LANG] GetPhraseInLanguage: Invalid key - " .. tostring(key) .. "\n")
    --     return "INVALID_KEY"
    -- end

    if not self.LanguageData[lang] then
        self:LoadLanguageFolder(lang)
    end
    
    local keys = string.Split(key, ".")
    local current = self.LanguageData[lang]

    for i, k in ipairs(keys) do
        -- if not current then
        --     ErrorNoHalt("[LANG] GetPhraseInLanguage: Invalid path at key " .. k .. " in " .. key .. "\n")
        --     return key
        -- end
        
        if type(current) == "table" and current[k] then
            current = current[k]
        elseif tonumber(k) and type(current) == "table" and #current >= tonumber(k) then
            -- 处理数组索引
            current = current[tonumber(k)]
        else
            -- ErrorNoHalt("[LANG] GetPhraseInLanguage: Key not found - " .. k .. " in " .. key .. "\n")
            return key
        end
    end
    
    return current
end

-- 获取系统语言并转换为支持的语言代码
function LANG:GetSystemLanguage()
    local gmodLang = GetConVar("gmod_language"):GetString()
    for langCode, _ in pairs(self.LanguageList) do
        if gmodLang == langCode then
            return langCode
        end
    end
    return "en"
end

-- 仅在客户端创建ConVar和监听语言变化
if CLIENT then
    -- 创建ConVar用于切换语言
    CreateClientConVar("of_garrylord_language", "", true, true)

    -- 监听语言变化
    cvars.AddChangeCallback("of_garrylord_language", function(name, old, new)
        -- 如果设置为空，使用系统语言
        if new == "" then
            LANG:SetLanguage(LANG:GetSystemLanguage())
        else
            LANG:SetLanguage(new)
        end
    end)
end

-- 初始化语言系统
hook.Add("Initialize", "LoadLanguageSystem", function()
    -- 加载语言列表
    if not LANG:LoadLanguageList() then
        return
    end

    for langCode, _ in pairs(LANG.LanguageList) do
        LANG:LoadLanguageFolder(langCode)
    end
    
    local userLang = CLIENT and (GetConVar("of_garrylord_language"):GetString() or "") or ""
    if userLang == "" then
        userLang = LANG:GetSystemLanguage()
    end
    LANG:SetLanguage(userLang)
end)

-- 导出全局函数用于获取翻译
function ofTranslate(key)
    if not key or type(key) ~= "string" then
        ErrorNoHalt("[ofTranslate] Invalid key - " .. tostring(key) .. "\n")
        return "INVALID_KEY"
    end
    return LANG:GetPhrase(key)
end 