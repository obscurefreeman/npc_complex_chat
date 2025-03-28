import os
import json
from googletrans import Translator
import ssl
import time
import re
from multiprocessing.pool import ThreadPool
import email  # 替代cgi模块
from deep_translator import GoogleTranslator

ssl._create_default_https_context = ssl._create_unverified_context

def translate_file(file_path, output_path, dest_lang):
    """使用Google翻译将文件内容翻译成目标语言"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        translator = GoogleTranslator(source='auto', target=dest_lang)
        
        # 递归翻译所有字符串
        def translate_dict(d):
            if isinstance(d, dict):
                return {k: translate_dict(v) for k, v in d.items()}
            elif isinstance(d, list):
                return [translate_dict(i) for i in d]
            elif isinstance(d, str):
                # 处理超长文本
                if len(d) > 5000:
                    chunks = [d[i:i+5000] for i in range(0, len(d), 5000)]
                    # 使用线程池并行翻译
                    pool = ThreadPool(8)
                    translated_chunks = pool.map(lambda x: translator.translate(x), chunks)
                    pool.close()
                    pool.join()
                    return ''.join(translated_chunks)
                try:
                    # 直接返回翻译结果
                    return translator.translate(d)
                except Exception as e:
                    print(f"翻译失败: {str(e)}")
                    return d  # 返回原文以防翻译失败
            return d
        
        translated_data = translate_dict(data)
        
        # 确保输出目录存在
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(translated_data, f, ensure_ascii=False, indent=4)
            
        print(f"成功翻译: {file_path} -> {output_path}")
    except Exception as e:
        print(f"翻译文件 {file_path} 时出错: {str(e)}")

def translate_all_files(dest_lang):
    """翻译data/of_npcp/lang/zh-CN/目录下的所有文件"""
    source_dir = 'data/of_npcp/lang/zh-CN'
    target_dir = f'data/of_npcp/lang/{dest_lang}'
    
    if not os.path.exists(source_dir):
        print(f"源目录不存在: {source_dir}")
        return
    
    # 获取所有需要翻译的文件
    files_to_translate = []
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.endswith('.json'):
                source_path = os.path.join(root, file)
                relative_path = os.path.relpath(source_path, source_dir)
                target_path = os.path.join(target_dir, relative_path)
                files_to_translate.append((source_path, target_path))
    
    total_files = len(files_to_translate)
    if total_files == 0:
        print("没有找到需要翻译的文件")
        return
    
    print(f"开始翻译，共发现 {total_files} 个文件")
    
    for index, (source_path, target_path) in enumerate(files_to_translate, 1):
        print(f"\n正在处理文件 {index}/{total_files} ({index/total_files:.1%})")
        print(f"源文件: {source_path}")
        print(f"目标文件: {target_path}")
        
        start_time = time.time()
        try:
            translate_file(source_path, target_path, dest_lang)
            elapsed_time = time.time() - start_time
            print(f"文件 {index}/{total_files} 翻译完成，耗时 {elapsed_time:.2f} 秒")
        except Exception as e:
            print(f"文件 {index}/{total_files} 翻译失败: {str(e)}")
    
    print("\n所有文件处理完成")

if __name__ == "__main__":
    # 示例：将中文翻译成英文
    translate_all_files('de') 