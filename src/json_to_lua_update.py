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
GLOBAL_OFNPC_DATA = {
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
                GLOBAL_OFNPC_DATA[global_key] = data
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

def save_global_data(max_chars_per_file=60000):
    """
    保存全局变量到多个 Lua 文件中，避免单个文件过大。
    会生成：
        lua/autorun/shared/ofnpcp_data_001.lua
        lua/autorun/shared/ofnpcp_data_002.lua
        ...
    每个文件中都会往同一个 GLOBAL_OFNPC_DATA 表里写入不同的顶层字段，
    最终结构与原先的 GLOBAL_OFNPC_DATA 完全一致。
    """
    base_dir = "lua/autorun/shared"
    base_name = "ofnpcp_data"

    os.makedirs(base_dir, exist_ok=True)

    # 清理旧的数据文件（单文件和多文件）
    for fname in os.listdir(base_dir):
        if fname == f"{base_name}.lua" or (
            fname.startswith(f"{base_name}_") and fname.endswith(".lua")
        ):
            try:
                os.remove(os.path.join(base_dir, fname))
            except OSError:
                # 如果删除失败就跳过，避免整个流程中断
                pass

    def format_top_level_key(k):
        # 顶层我们统一用下标形式，防止特殊字符导致语法错误
        if isinstance(k, str):
            return f'["{escape_string(k)}"]'
        return f"[{k}]"

    file_index = 1

    def new_file_header(idx):
        return (
            f"-- 全局变量数据（自动生成，分片 {idx:03d}）\n"
            "GLOBAL_OFNPC_DATA = GLOBAL_OFNPC_DATA or {}\n"
        )

    current_content = new_file_header(file_index)

    def flush_file(content, idx):
        file_path = os.path.join(base_dir, f"{base_name}_{idx:03d}.lua")
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)

    # 按顶层 key 拆分，保证每个文件都是完整的 Lua 代码
    for key, value in GLOBAL_OFNPC_DATA.items():
        key_expr = format_top_level_key(key)
        value_str = serialize_value(value, indent=1)
        chunk = f"GLOBAL_OFNPC_DATA{key_expr} = {value_str}\n"

        # 如果当前文件放不下这一块，就先写出，再开新文件
        if len(current_content) + len(chunk) > max_chars_per_file:
            flush_file(current_content, file_index)
            file_index += 1
            current_content = new_file_header(file_index)

        current_content += chunk

    # 写出最后一个文件
    if current_content.strip():
        flush_file(current_content, file_index)

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