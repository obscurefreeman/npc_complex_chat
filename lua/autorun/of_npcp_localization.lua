local LANG = {}
LANG.CurrentLanguage = "en"
LANG.LanguageData = {}
LANG.LanguageList = {}  -- 新增：用于存储语言列表

-- 加载 language.json 文件
function LANG:LoadLanguageList()
    local langData = file.Read("data/of_npcp/language.json", "GAME")
    if langData then
        local success, data = pcall(util.JSONToTable, langData)
        if success and data and data.language then
            self.LanguageList = data.language
            return true
        end
    end
    return false
end

-- 加载语言文件
function LANG:LoadLanguageFolder(lang)
    local files = file.Find("data/of_npcp/lang/" .. lang .. "/*.json", "GAME")
    self.LanguageData[lang] = {}
    for _, filename in ipairs(files) do
        local langData = file.Read("data/of_npcp/lang/" .. lang .. "/" .. filename, "GAME")
        if langData then
            local data = util.JSONToTable(langData)
            table.Merge(self.LanguageData[lang], data)
        end
    end
    return next(self.LanguageData[lang]) ~= nil
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
    local result = self:GetPhraseInLanguage(self.CurrentLanguage, key)
    
    if self.CurrentLanguage ~= "en" and result == key then
        result = self:GetPhraseInLanguage("en", key)
    end
    
    return result
end

function LANG:GetPhraseInLanguage(lang, key)
    if not self.LanguageData[lang] then
        self:LoadLanguageFolder(lang)
    end
    
    local keys = string.Split(key, ".")
    local current = self.LanguageData[lang]

    for i, k in ipairs(keys) do
        if type(current) == "table" and current[k] then
            current = current[k]
        elseif tonumber(k) and type(current) == "table" and #current >= tonumber(k) then
            -- 处理数组索引
            current = current[tonumber(k)]
        else
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
    return LANG:GetPhrase(key)
end 