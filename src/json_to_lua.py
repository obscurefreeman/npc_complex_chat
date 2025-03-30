import os
import json

# 定义JSON文件路径和对应的全局变量键
JSON_PATHS = {
    "data/of_npcp/jobs.json": "jobData",
    "data/of_npcp/name.json": "names",
    "data/of_npcp/tags.json": "tagData",
    "data/of_npcp/player_talk.json": "playerTalks",
    "data/of_npcp/citizen_talk.json": "npcTalks",
    "data/of_npcp/cards_new.json": "cards",
    "data/of_npcp/anim.json": "anim",
    "data/of_npcp/article.json": "article",
    "data/of_npcp/sponsors.json": "sponsors",
    "data/of_npcp/ai/providers.json": "aiProviders",
    "data/of_npcp/ai/voice.json": "voice",
    "data/of_npcp/language.json": "lang"
}

# 初始化全局变量
GLOBAL_OFNPC_DATA = {
    "jobData": {},
    "names": {},
    "tagData": {},
    "playerTalks": {},
    "npcTalks": {},
    "cards": {},
    "anim": {},
    "log": {},
    "aiProviders": {},
    "voice": {},
    "cards": {
        "info": {},
        "general": {}
    },
    "lang": {}
}

def load_json_data(file_path, global_key):
    """加载JSON文件并存储到全局变量中"""
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
                GLOBAL_OFNPC_DATA[global_key] = data
            except json.JSONDecodeError:
                print(f"【晦涩弗里曼】解析 {file_path} 时出错。")
    else:
        print(f"【晦涩弗里曼】无法加载 {file_path}。")

def serialize_table(tbl, indent=1, seen=None):
    """将Python字典序列化为Lua表格式"""
    if seen is None:
        seen = set()
    if id(tbl) in seen:
        return '"<循环引用>"'
    seen.add(id(tbl))
    
    spaces = "    " * indent
    lua_str = "{\n"
    
    for k, v in tbl.items():
        # 所有键都用方括号包裹，并确保键名是字符串
        key = f'["{k}"]' if isinstance(k, str) else f"[{k}]"
        
        if isinstance(v, dict):
            lua_str += f"{spaces}{key} = {serialize_table(v, indent + 1, seen)},\n"
        elif isinstance(v, list):
            # 处理数组
            lua_str += f"{spaces}{key} = {{\n"
            for item in v:
                if isinstance(item, str):
                    item = item.replace("\n", "\\n").replace("\r", "\\r")
                    lua_str += f"{spaces}    \"{item}\",\n"
                else:
                    lua_str += f"{spaces}    {item},\n"
            lua_str += f"{spaces}}},\n"
        else:
            # 处理字符串中的换行符，确保\n被保留为转义字符
            if isinstance(v, str):
                v = v.replace("\n", "\\n").replace("\r", "\\r")
            value = f'"{v}"' if isinstance(v, str) else str(v)
            lua_str += f"{spaces}{key} = {value},\n"
    
    return lua_str + ("    " * (indent - 1)) + "}"

def save_global_data():
    """保存全局变量到Lua文件"""
    file_path = "lua/garrylord/data_backup.lua"
    lua_data = "-- 全局变量数据\nGLOBAL_OFNPC_DATA = " + serialize_table(GLOBAL_OFNPC_DATA)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(lua_data)

def load_npc_data():
    """加载所有NPC数据"""
    for file_path, global_key in JSON_PATHS.items():
        load_json_data(file_path, global_key)
    
    # 处理语言文件
    lang_dir = "data/of_npcp/lang"
    if os.path.exists(lang_dir):
        for lang in os.listdir(lang_dir):
            lang_path = os.path.join(lang_dir, lang)
            if os.path.isdir(lang_path):
                GLOBAL_OFNPC_DATA["lang"][lang] = {}
                for json_file in os.listdir(lang_path):
                    if json_file.endswith(".json"):
                        json_path = os.path.join(lang_path, json_file)
                        with open(json_path, 'r', encoding='utf-8') as f:
                            try:
                                data = json.load(f)
                                GLOBAL_OFNPC_DATA["lang"][lang].update(data)
                            except json.JSONDecodeError:
                                print(f"【晦涩弗里曼】解析 {json_path} 时出错。")
    
    save_global_data()

if __name__ == "__main__":
    load_npc_data()
