import os
import json

# JSON文件路径
json_dir = "data/of_npcp"
# 输出Lua文件路径
output_file = "lua/garrylord/data_backup.lua"

# 需要转换的JSON文件及其对应的全局变量名
json_files = {
    "jobs.json": "jobData",
    "name.json": "names",
    "tags.json": "tagData",
    "player_talk.json": "playerTalks",
    "citizen_talk.json": "npcTalks",
    "cards_new.json": "cards",
    "anim.json": "anim",
    "article.json": "article",
    "sponsors.json": "sponsors",
    "ai/providers.json": "aiProviders",
    "ai/voice.json": "voice",
    "language.json": "lang"
}

def convert_json_to_lua():
    lua_content = "-- 自动生成的Lua数据文件\n\n"
    lua_content += "GLOBAL_OFNPC_DATA = GLOBAL_OFNPC_DATA or {}\n\n"
    
    for json_file, var_name in json_files.items():
        file_path = os.path.join(json_dir, json_file)
        if os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8') as f:
                try:
                    data = json.load(f)
                    lua_content += f"GLOBAL_OFNPC_DATA.{var_name} = {convert_to_lua(data)}\n\n"
                except json.JSONDecodeError:
                    print(f"解析 {json_file} 时出错")
        else:
            print(f"文件 {json_file} 不存在")
    
    # 写入Lua文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(lua_content)

def convert_to_lua(data):
    if isinstance(data, dict):
        return "{" + ", ".join(f"['{k}'] = {convert_to_lua(v)}" for k, v in data.items()) + "}"
    elif isinstance(data, list):
        return "{" + ", ".join(convert_to_lua(item) for item in data) + "}"
    elif isinstance(data, str):
        return f'"{data}"'
    else:
        return str(data)

if __name__ == "__main__":
    convert_json_to_lua()
