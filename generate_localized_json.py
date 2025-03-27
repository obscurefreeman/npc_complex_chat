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

    # 遍历cards.json中的阵营和卡牌
    for group, group_data in cards_data.items():
        if group == 'info':
            continue
        
        localized_paths[group] = {}
        localized_content[group] = {}
        
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
            
            # 生成本地化内容
            localized_content[group][card_id] = {
                "name": card_data.get("name", ""),
                "desc": card_data.get("d", []),
                "response": card_data.get("a", [])
            }

    output_dir = Path("data/of_npcp/lang/zh-CN")
    output_dir.mkdir(parents=True, exist_ok=True)

    with open("data/of_npcp/cards_new.json", 'w', encoding='utf-8') as f:
        json.dump(localized_paths, f, ensure_ascii=False, indent=4)

    with open(output_dir / "cards.json", 'w', encoding='utf-8') as f:
        json.dump(localized_content, f, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    cards_file = "data/of_npcp/cards.json"
    generate_localized_files(cards_file) 