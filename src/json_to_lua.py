import os
import json
import re

def escape_lua_string(s):
    # 转义Lua字符串中的特殊字符
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    s = s.replace('\n', '\\n')
    s = s.replace('\r', '\\r')
    s = s.replace('\t', '\\t')
    return s

def json_to_lua(data, indent=0):
    if isinstance(data, dict):
        lua_str = "{\n"
        for key, value in data.items():
            lua_str += " " * (indent + 4)
            if isinstance(key, str):
                lua_str += f'["{escape_lua_string(key)}"] = '
            else:
                lua_str += f"[{key}] = "
            
            lua_str += json_to_lua(value, indent + 4)
            lua_str += ",\n"
        lua_str += " " * indent + "}"
        return lua_str
    elif isinstance(data, list):
        items = []
        for item in data:
            items.append(json_to_lua(item, indent))
        return "{" + ", ".join(items) + "}"
    elif isinstance(data, str):
        return f'"{escape_lua_string(data)}"'
    else:
        return str(data)

def convert_json_to_lua(json_dir, output_file):
    # 确保输出目录存在
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    lua_data = "GLOBAL_OFNPC_DATA = {\n"
    file_paths = {}
    
    # 检查输入目录是否存在
    if not os.path.exists(json_dir):
        print(f"错误：目录 {json_dir} 不存在")
        return
    
    # 遍历目录并处理JSON文件
    json_files = []
    for root, dirs, files in os.walk(json_dir):
        for file in files:
            if file.endswith(".json"):
                json_files.append(os.path.join(root, file))
    
    if not json_files:
        print(f"警告：在目录 {json_dir} 中未找到任何JSON文件")
        return
    
    for file_path in json_files:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                json_data = json.load(f)
            # 使用完整相对路径作为key
            rel_path = os.path.relpath(file_path, json_dir).replace('\\', '/')
            key = rel_path.replace('/', '_').replace('.json', '')
            lua_data += f'    ["{escape_lua_string(key)}"] = {json_to_lua(json_data)},\n'
            # 存储文件路径信息
            file_paths[key] = rel_path
        except Exception as e:
            print(f"错误：处理文件 {file_path} 时出错 - {str(e)}")
    
    lua_data += "}\n"
    lua_data += "GLOBAL_OFNPC_DATA._file_paths = " + json_to_lua(file_paths) + "\n"
    
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(lua_data)
    print(f"成功生成备份文件：{output_file}")

if __name__ == "__main__":
    convert_json_to_lua("data/of_npcp", "lua/garrylord/data_backup.lua")
