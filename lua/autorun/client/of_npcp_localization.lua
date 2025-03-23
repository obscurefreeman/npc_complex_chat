local LANG = {}
LANG.CurrentLanguage = "en"
LANG.LanguageData = {}

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
    
    if not self.LanguageData[self.CurrentLanguage] then
        self:LoadLanguageFile(self.CurrentLanguage)
    end
    
    local keys = string.Split(key, ".")
    local current = self.LanguageData[self.CurrentLanguage]

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
    -- 如果是中文（简体或繁体），返回zh
    if gmodLang:match("^zh%-") then
        return "zh"
    end
    -- 其他语言默认使用英语
    return "en"
end

-- 创建ConVar用于切换语言
CreateConVar("of_garrylord_language", "", FCVAR_ARCHIVE, "设置NPC系统使用的语言 (en/zh)，留空则跟随系统语言")

-- 监听语言变化
cvars.AddChangeCallback("of_garrylord_language", function(name, old, new)
    -- 如果设置为空，使用系统语言
    if new == "" then
        LANG:SetLanguage(LANG:GetSystemLanguage())
    else
        LANG:SetLanguage(new)
    end
end)

-- 初始化语言系统
hook.Add("Initialize", "LoadLanguageSystem", function()
    LANG:LoadLanguageFolder("en")
    LANG:LoadLanguageFolder("zh")
    local userLang = GetConVar("of_garrylord_language"):GetString()
    if userLang == "" then
        userLang = LANG:GetSystemLanguage()
    end
    LANG:SetLanguage(userLang)
end)

-- 导出全局函数用于获取翻译
function L(key)
    return LANG:GetPhrase(key)
end 