import json
import os

def convert_chat_format(chat_data):
    """将chat.json的键值对格式转换为数组格式"""
    converted_data = {}
    
    for category, sub_categories in chat_data.items():
        converted_data[category] = {}
        for sub_category, messages in sub_categories.items():
            # 将字典值转换为数组
            converted_data[category][sub_category] = list(messages.values())
    
    return converted_data

def main():
    # 读取chat.json
    with open('data/of_npcp/lang/en/chat.json', 'r', encoding='utf-8') as f:
        chat_data = json.load(f)
    
    # 转换格式
    converted_data = convert_chat_format(chat_data)
    
    # 保存到src文件夹
    output_path = os.path.join('src', 'converted_chat.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(converted_data, f, ensure_ascii=False, indent=4)
    
    print(f"转换完成，文件已保存到 {output_path}")

if __name__ == "__main__":
    main() 