-- 新增占位符替换函数
function ReplacePlaceholders(text, npcIdentity)
    if not text or not npcIdentity then return text end
    
    local npcName = ofTranslate(npcIdentity.name)
    if npcIdentity.name == npcIdentity.gamename then
        npcName = language.GetPhrase(npcIdentity.gamename)
    end
    
    -- 定义占位符替换表
    local replacements = {
        ["/name/"] = npcName,
        ["/nickname/"] = ofTranslate(npcIdentity.nickname),
        ["/job/"] = ofTranslate(npcIdentity.specialization),
        ["/camp/"] = ofTranslate("camp."..tostring(npcIdentity.camp)),
        ["/map/"] = game.GetMap(),
        ["/time/"] = os.date("%H:%M")
    }

    -- 遍历替换表进行替换
    for pattern, replacement in pairs(replacements) do
        text = text:gsub(pattern, replacement)
    end
    
    return text
end