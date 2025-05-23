import os
import json
from arrr import translate  # 替换为arrr库

def convert_file_to_pirate_speak(file_path, output_path):
    """将单个文件从标准英语转换为海盗英语"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # 递归转换所有字符串
        def convert_dict(d):
            if isinstance(d, dict):
                return {k: convert_dict(v) for k, v in d.items()}
            elif isinstance(d, list):
                return [convert_dict(i) for i in d]
            elif isinstance(d, str):
                return translate(d)  # 使用arrr库的translate方法
            return d
        
        converted_data = convert_dict(data)
        
        # 确保输出目录存在
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(converted_data, f, ensure_ascii=False, indent=4)
            
        print(f"成功转换: {file_path} -> {output_path}")
    except Exception as e:
        print(f"转换文件 {file_path} 时出错: {str(e)}")

def convert_all_files():
    """转换data/of_npcp/lang/en/目录下的所有文件"""
    source_dir = 'data/of_npcp/lang/en'
    target_dir = 'data/of_npcp/lang/en-PT'
    
    if not os.path.exists(source_dir):
        print(f"源目录不存在: {source_dir}")
        return
    
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.endswith('.json'):
                source_path = os.path.join(root, file)
                relative_path = os.path.relpath(source_path, source_dir)
                target_path = os.path.join(target_dir, relative_path)
                convert_file_to_pirate_speak(source_path, target_path)

if __name__ == "__main__":
    convert_all_files() 