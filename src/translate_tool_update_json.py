import json

# 定义需要处理的语言文件夹列表
LANGUAGE_FOLDERS = ['en']  # 在这里添加其他语言文件夹

for lang_folder in LANGUAGE_FOLDERS:
    print(f"正在处理 {lang_folder} 语言...")
    
    # 读取ui.json文件
    ui_path = f'data/of_npcp/lang/{lang_folder}/ui.json'
    with open(ui_path, 'r', encoding='utf-8') as ui_file:
        ui_data = json.load(ui_file)

    # 提取guide和text内容
    guide_content = ui_data['ui']['personalization'].pop('guide', None)
    text_content = ui_data['ui']['personalization'].pop('text', None)

    # 读取article.json文件
    article_path = f'data/of_npcp/lang/{lang_folder}/article.json'
    with open(article_path, 'r', encoding='utf-8') as article_file:
        article_data = json.load(article_file)

    # 检查并创建document键
    if 'document' not in article_data['article']:
        article_data['article']['document'] = {}

    # 更新article.json中的tts部分
    article_data['article']['document']['tts'] = {
        "title": guide_content,
        "content": text_content
    }

    # 将更新后的内容写回article.json
    with open(article_path, 'w', encoding='utf-8') as article_file:
        json.dump(article_data, article_file, ensure_ascii=False, indent=4)

    # 将更新后的内容写回ui.json
    with open(ui_path, 'w', encoding='utf-8') as ui_file:
        json.dump(ui_data, ui_file, ensure_ascii=False, indent=4)

    print(f"{lang_folder} 语言处理完成！\n")

print("所有语言更新完成！") 