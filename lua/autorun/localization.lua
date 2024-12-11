local LANG = {}
LANG.CurrentLanguage = "en"
LANG.LanguageData = {}

-- 加载语言文件
function LANG:LoadLanguageFile(lang)
    local langData = file.Read("data/lang/" .. lang .. ".json", "GAME")
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

-- 创建ConVar用于切换语言
CreateConVar("ofnpcp_language", "en", FCVAR_ARCHIVE, "设置NPC系统使用的语言 (en/zh)")

-- 监听语言变化
cvars.AddChangeCallback("ofnpcp_language", function(name, old, new)
    LANG:SetLanguage(new)
end)

-- 初始化语言系统
hook.Add("Initialize", "LoadLanguageSystem", function()
    -- 预加载所有支持的语言
    LANG:LoadLanguageFile("en")
    LANG:LoadLanguageFile("zh")
    -- 设置初始语言
    LANG:SetLanguage(GetConVar("ofnpcp_language"):GetString())
end)

-- 导出全局函数用于获取翻译
function L(key)
    return LANG:GetPhrase(key)
end 