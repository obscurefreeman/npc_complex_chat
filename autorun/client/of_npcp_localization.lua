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

function LANG:SetLanguage(lang)
    if not self.LanguageData[lang] then
        if not self:LoadLanguageFolder(lang) then
            return false
        end
    end
    self.CurrentLanguage = lang
    return true
end

hook.Add("Initialize", "LoadLanguageSystem", function()
    LANG:LoadLanguageFolder("en")
    LANG:LoadLanguageFolder("zh")
    local userLang = GetConVar("ofnpcp_language"):GetString()
    if userLang == "" then
        userLang = LANG:GetSystemLanguage()
    end
    LANG:SetLanguage(userLang)
end) 