import os
import json
from pathlib import Path

def generate_localized_files(cards_file):
    # 读取cards.json文件
    with open(cards_file, 'r', encoding='utf-8') as f:
        cards_data = json.load(f)
    
    # 创建本地化路径文件
    localized_paths = {}
    # 创建本地化内容文件
    localized_content = {}

    localized_content = {"card": {}}

    # 处理info部分
    if 'info' in cards_data:

        localized_paths['info'] = {}
        localized_content['info'] = {}
        
        for group, group_info in cards_data['info'].items():
            localized_paths['info'][group] = {
                "name": [f"card.info.{group}.name"],
                "desc": [f"card.info.{group}.desc"],
                "color": group_info.get("color", {})
            }
            localized_content['info'][group] = {
                "name": group_info.get("name", ""),
                "desc": group_info.get("desc", ""),
            }

    # 遍历cards.json中的阵营和卡牌
    for group, group_data in cards_data.items():
        if group == 'info':
            continue
        
        localized_paths[group] = {}
        localized_content["card"][group] = {}  # 初始化group字典
        
        for card_id, card_data in group_data.items():
            # 生成本地化路径
            localized_paths[group][card_id] = {
                "name": f"card.{group}.{card_id}.name",
                "type": card_data.get("type", ""),
                "cost": card_data.get("cost", ""),
                "tag": card_data.get("tag", ""),
                "d": [f"card.{group}.{card_id}.d.{i+1}" for i in range(len(card_data.get("d", [])))],
                "a": [f"card.{group}.{card_id}.a.{i+1}" for i in range(len(card_data.get("a", [])))]
            }

            localized_content["card"][group][card_id] = {
                "name": card_data.get("name", ""),
                "d": {str(i+1): d for i, d in enumerate(card_data.get("d", []))},
                "a": {str(i+1): a for i, a in enumerate(card_data.get("a", []))}
            }

    output_dir = Path("data/of_npcp/lang/zh-CN")
    output_dir.mkdir(parents=True, exist_ok=True)

    with open("data/of_npcp/cards_new.json", 'w', encoding='utf-8') as f:
        json.dump(localized_paths, f, ensure_ascii=False, indent=4)

    with open(output_dir / "cards.json", 'w', encoding='utf-8') as f:
        json.dump(localized_content, f, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    # 更新路径，使用绝对路径
    base_dir = Path(__file__).parent.parent  # 获取项目根目录
    cards_file = base_dir / "data/of_npcp/cards.json"
    generate_localized_files(cards_file) 