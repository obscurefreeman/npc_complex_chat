import os
import json

# 定义JSON文件路径和对应的全局变量键
JSON_PATHS = {
    "data/of_npcp/jobs.json": "jobData",
    "data/of_npcp/name.json": "names",
    "data/of_npcp/tags.json": "tag",
    "data/of_npcp/player_talk.json": "playerTalks",
    "data/of_npcp/citizen_talk.json": "npcTalks",
    "data/of_npcp/cards_new.json": "cards",
    "data/of_npcp/setting.json": "setting",
    "data/of_npcp/article.json": "article",
    "data/of_npcp/sponsors.json": "sponsors",
    "data/of_npcp/ai/providers.json": "aiProviders",
    "data/of_npcp/ai/voice.json": "voice",
    "data/of_npcp/language.json": "lang"
}

# 初始化全局变量
GLOBAL_OFNPC_DATA_BASIC = {
    "jobData": {},
    "names": {},
    "tag": {},
    "playerTalks": {},
    "npcTalks": {},
    "cards": {},
    "article": {},
    "sponsors": {},
    "aiProviders": {},
    "voice": {},
    "lang": {}
}

def load_json_data(file_path, global_key):
    """加载JSON文件并存储到全局变量中"""
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
                GLOBAL_OFNPC_DATA_BASIC[global_key] = data
            except json.JSONDecodeError:
                print(f"【晦涩弗里曼】解析 {file_path} 时出错。")
    else:
        print(f"【晦涩弗里曼】无法加载 {file_path}。")

def escape_string(s):
    """转义字符串中的特殊字符"""
    return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r")

def serialize_value(v, indent=1, seen=None):
    """序列化单个值为Lua格式"""
    if seen is None:
        seen = set()
    
    if isinstance(v, dict):
        return serialize_table(v, indent, seen)
    elif isinstance(v, list):
        return serialize_array(v, indent, seen)
    elif isinstance(v, str):
        return f'"{escape_string(v)}"'
    elif isinstance(v, bool):
        return "true" if v else "false"
    elif v is None:
        return "nil"
    else:
        return str(v)

def serialize_array(arr, indent=1, seen=None):
    """序列化数组为Lua表格式"""
    if seen is None:
        seen = set()
    if id(arr) in seen:
        return '"<循环引用>"'
    seen.add(id(arr))
    
    spaces = "    " * indent
    lua_str = "{\n"
    
    for item in arr:
        lua_str += f"{spaces}{serialize_value(item, indent + 1, seen)},\n"
    
    return lua_str + ("    " * (indent - 1)) + "}"

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
        # 处理键名
        if isinstance(k, str):
            # 如果是有效的Lua标识符，可以直接使用，否则用方括号和引号
            if k.isidentifier() and not k[0].isdigit():
                key = k
            else:
                key = f'["{escape_string(k)}"]'
        else:
            key = f"[{k}]"
        
        # 处理值
        value_str = serialize_value(v, indent + 1, seen)
        lua_str += f"{spaces}{key} = {value_str},\n"
    
    return lua_str + ("    " * (indent - 1)) + "}"

def save_global_data():
    """保存全局变量到Lua文件"""
    file_path = "lua/garryload/data.lua"
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    
    lua_data = "-- 全局变量数据\nGLOBAL_OFNPC_DATA_BASIC = " + serialize_table(GLOBAL_OFNPC_DATA_BASIC)
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
                GLOBAL_OFNPC_DATA_BASIC["lang"][lang] = {}
                for json_file in os.listdir(lang_path):
                    if json_file.endswith(".json"):
                        json_path = os.path.join(lang_path, json_file)
                        with open(json_path, 'r', encoding='utf-8') as f:
                            try:
                                data = json.load(f)
                                GLOBAL_OFNPC_DATA_BASIC["lang"][lang].update(data)
                            except json.JSONDecodeError:
                                print(f"【晦涩弗里曼】解析 {json_path} 时出错。")
    
    save_global_data()

if __name__ == "__main__":
    load_npc_data()