local LANG = {}
LANG.CurrentLanguage = "en"
LANG.LanguageData = {}

-- 加载语言文件
function LANG:LoadLanguageFile(lang)
    local langData = file.Read("data/of_npcp/lang/" .. lang .. ".json", "GAME")
    if langData then
        self.LanguageData[lang] = util.JSONToTable(langData)
        return true
    end
    return false
end

-- 设置当前语言
function LANG:SetLanguage(lang)
    if not self.LanguageData[lang] then
        if not self:LoadLanguageFile(lang) then
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
    
    for _, k in ipairs(keys) do
        if current[k] then
            current = current[k]
        else
            return key -- 如果找不到翻译，返回原始key
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
CreateConVar("ofnpcp_language", "", FCVAR_ARCHIVE, "设置NPC系统使用的语言 (en/zh)，留空则跟随系统语言")

-- 监听语言变化
cvars.AddChangeCallback("ofnpcp_language", function(name, old, new)
    -- 如果设置为空，使用系统语言
    if new == "" then
        LANG:SetLanguage(LANG:GetSystemLanguage())
    else
        LANG:SetLanguage(new)
    end
end)

-- 初始化语言系统
hook.Add("Initialize", "LoadLanguageSystem", function()
    -- 预加载所有支持的语言
    LANG:LoadLanguageFile("en")
    LANG:LoadLanguageFile("zh")
    
    -- 获取用户设置的语言
    local userLang = GetConVar("ofnpcp_language"):GetString()
    
    -- 如果用户没有设置特定语言（值为空），则使用系统语言
    if userLang == "" then
        userLang = LANG:GetSystemLanguage()
    end
    
    -- 设置初始语言
    LANG:SetLanguage(userLang)
end)

-- 导出全局函数用于获取翻译
function L(key)
    return LANG:GetPhrase(key)
end 