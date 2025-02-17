import os
import json
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
from PIL import Image, ImageTk
import re

class CardEditor:
    def __init__(self, root):
        self.root = root
        self.root.title("卡牌编辑器")
        self.data = None
        self.current_group = None
        self.current_card = None
        self.image_dir = os.path.join(os.getcwd(), "materials", "ofnpcp", "cards", "large")
        
        # 创建主界面布局
        self.create_widgets()
        
        # 自动加载cards.json
        self.load_file(os.path.join("data", "of_npcp", "cards.json"))

    def create_widgets(self):
        # 主布局
        main_panel = ttk.PanedWindow(self.root, orient=tk.HORIZONTAL)
        main_panel.pack(fill=tk.BOTH, expand=True)

        # 左侧面板 - 阵营选择
        left_panel = ttk.Frame(main_panel, width=200)
        main_panel.add(left_panel)
        
        self.group_listbox = tk.Listbox(left_panel)
        self.group_listbox.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.group_listbox.bind('<<ListboxSelect>>', self.on_group_select)
        
        # 中间面板 - 卡牌列表
        middle_panel = ttk.Frame(main_panel)
        main_panel.add(middle_panel)
        
        self.card_tree = ttk.Treeview(middle_panel, columns=('index', 'cost', 'type', 'key', 'name', 'tag'), show='headings')
        self.card_tree.heading('index', text='序号')
        self.card_tree.heading('cost', text='消耗')
        self.card_tree.heading('type', text='类型')
        self.card_tree.heading('key', text='索引')
        self.card_tree.heading('name', text='名称')
        self.card_tree.heading('tag', text='标签')
        self.card_tree.column('index', width=50, anchor='center')
        self.card_tree.column('cost', width=50, anchor='center')
        self.card_tree.column('type', width=100, anchor='center')
        self.card_tree.column('key', width=150, anchor='w')
        self.card_tree.column('name', width=200, anchor='w')
        self.card_tree.column('tag', width=150, anchor='w')
        self.card_tree.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.card_tree.bind('<<TreeviewSelect>>', self.on_card_select)
        
        # 右侧面板 - 卡牌详情
        right_panel = ttk.Frame(main_panel)
        main_panel.add(right_panel)

        # 使用网格布局管理器
        right_panel.grid_columnconfigure(0, weight=1)
        right_panel.grid_rowconfigure(0, weight=1)  # 图片区域
        right_panel.grid_rowconfigure(1, weight=2)  # 详情区域

        # 卡牌图片
        self.card_image = tk.Label(right_panel)
        self.card_image.grid(row=0, column=0, pady=10, sticky='ns')  # 修改为上下居中

        # 卡牌详情框架
        self.detail_frame = ttk.LabelFrame(right_panel, text="卡牌详情")
        self.detail_frame.grid(row=1, column=0, sticky='nsew', padx=5, pady=5)

        # 使用网格布局管理器
        self.detail_frame.grid_columnconfigure(1, weight=1)

        # 详情编辑控件
        ttk.Label(self.detail_frame, text="索引:").grid(row=0, column=0, sticky=tk.W)
        self.key_entry = ttk.Entry(self.detail_frame)
        self.key_entry.grid(row=0, column=1, sticky=tk.EW, padx=5, pady=2)
        
        ttk.Label(self.detail_frame, text="名称:").grid(row=1, column=0, sticky=tk.W)
        self.name_entry = ttk.Entry(self.detail_frame)
        self.name_entry.grid(row=1, column=1, sticky=tk.EW, padx=5, pady=2)
        
        ttk.Label(self.detail_frame, text="类型:").grid(row=2, column=0, sticky=tk.W)
        self.type_entry = ttk.Entry(self.detail_frame)
        self.type_entry.grid(row=2, column=1, sticky=tk.EW, padx=5, pady=2)
        
        ttk.Label(self.detail_frame, text="消耗:").grid(row=3, column=0, sticky=tk.W)
        self.cost_entry = ttk.Entry(self.detail_frame)
        self.cost_entry.grid(row=3, column=1, sticky=tk.EW, padx=5, pady=2)
        
        ttk.Label(self.detail_frame, text="描述:").grid(row=4, column=0, sticky=tk.W)
        self.desc_text = tk.Text(self.detail_frame, height=4, width=30)
        self.desc_text.grid(row=4, column=1, sticky=tk.EW, padx=5, pady=2)
        
        ttk.Label(self.detail_frame, text="回应:").grid(row=5, column=0, sticky=tk.W)
        self.response_text = tk.Text(self.detail_frame, height=4, width=30)
        self.response_text.grid(row=5, column=1, sticky=tk.EW, padx=5, pady=2)
        
        ttk.Label(self.detail_frame, text="标签:").grid(row=6, column=0, sticky=tk.W)
        self.tag_entry = ttk.Entry(self.detail_frame)
        self.tag_entry.grid(row=6, column=1, sticky=tk.EW, padx=5, pady=2)
        
        # 保存按钮
        self.save_btn = ttk.Button(self.detail_frame, text="保存修改", command=self.save_card)
        self.save_btn.grid(row=7, column=1, sticky=tk.E, pady=5)

    def load_file(self, file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                self.data = json.load(f)
            self.populate_groups()
        except Exception as e:
            messagebox.showerror("错误", f"无法加载文件: {str(e)}")

    def populate_groups(self):
        self.group_listbox.delete(0, tk.END)
        for group in self.data['info']:
            self.group_listbox.insert(tk.END, self.data['info'][group]['name'])

    def on_group_select(self, event):
        selection = self.group_listbox.curselection()
        if selection:
            group_name = self.group_listbox.get(selection[0])
            self.current_group = [k for k, v in self.data['info'].items() if v['name'] == group_name][0]
            self.populate_cards()

    def populate_cards(self):
        self.card_tree.delete(*self.card_tree.get_children())
        if self.current_group in self.data:
            # 合并通用卡牌和当前阵营卡牌
            all_cards = {**self.data.get('general', {}), **self.data.get(self.current_group, {})}
            # 按消耗排序
            sorted_cards = sorted(all_cards.items(), key=lambda x: int(x[1]['cost']))
            for index, (card_id, card_data) in enumerate(sorted_cards, start=1):
                self.card_tree.insert('', 'end', 
                                   values=(index, 
                                         card_data['cost'], 
                                         card_data['type'], 
                                         card_id, 
                                         card_data['name'], 
                                         ", ".join(card_data.get('tag', []))), 
                                   iid=card_id)

    def on_card_select(self, event):
        selected = self.card_tree.selection()
        if selected:
            self.current_card_key = selected[0]
            # 先检查当前阵营，再检查通用卡牌
            self.current_card = self.data[self.current_group].get(self.current_card_key) or \
                               self.data['general'].get(self.current_card_key, {})
            self.show_card_details()

    def show_card_details(self):
        if not self.current_card or not self.current_card_key:
            return
        
        # 显示卡牌图片
        image_path = os.path.join(self.image_dir, f"{self.current_card_key}.png")
        if os.path.exists(image_path):
            try:
                img = Image.open(image_path)
                img = img.resize((300, 300), Image.Resampling.LANCZOS)
                self.card_image.img = ImageTk.PhotoImage(img)
                self.card_image.config(image=self.card_image.img)
            except Exception as e:
                print(f"加载图片时出错: {e}")
                self.card_image.config(image='')
        else:
            self.card_image.config(image='')
        
        # 填充编辑框
        self.key_entry.delete(0, tk.END)
        self.key_entry.insert(0, self.current_card_key)
        
        self.name_entry.delete(0, tk.END)
        self.name_entry.insert(0, self.current_card.get('name', ''))
        
        self.type_entry.delete(0, tk.END)
        self.type_entry.insert(0, self.current_card.get('type', ''))
        
        self.cost_entry.delete(0, tk.END)
        self.cost_entry.insert(0, self.current_card.get('cost', ''))
        
        self.desc_text.delete(1.0, tk.END)
        self.desc_text.insert(1.0, "\n".join(self.current_card.get('d', [])))
        
        self.response_text.delete(1.0, tk.END)
        self.response_text.insert(1.0, "\n".join(self.current_card.get('a', [])))
        
        self.tag_entry.delete(0, tk.END)
        self.tag_entry.insert(0, ", ".join(self.current_card.get('tag', [])))

    def save_card(self):
        if not self.current_card:
            return
        
        # 获取新的索引名称
        new_key = self.key_entry.get()
        
        # 如果索引名称改变了
        if new_key != self.current_card_key:
            # 删除旧的卡牌数据
            if self.current_card_key in self.data[self.current_group]:
                del self.data[self.current_group][self.current_card_key]
            elif self.current_card_key in self.data['general']:
                del self.data['general'][self.current_card_key]
            # 更新当前卡牌键
            self.current_card_key = new_key
        
        # 更新卡牌数据
        self.current_card['name'] = self.name_entry.get()
        self.current_card['type'] = self.type_entry.get()
        self.current_card['cost'] = self.cost_entry.get()
        self.current_card['d'] = self.desc_text.get(1.0, tk.END).strip().split("\n")
        self.current_card['a'] = self.response_text.get(1.0, tk.END).strip().split("\n")
        # 处理中英文逗号分隔的标签
        self.current_card['tag'] = [t.strip() for t in re.split(r'[，,]', self.tag_entry.get()) if t.strip()]
        
        # 保存到数据中
        if self.current_card_key in self.data['general']:
            self.data['general'][self.current_card_key] = self.current_card
        else:
            self.data[self.current_group][self.current_card_key] = self.current_card
        
        # 更新树状视图
        self.populate_cards()
        
        # 保存到文件
        self.save_to_file()
        
        messagebox.showinfo("成功", "卡牌信息已更新")

    def save_to_file(self):
        file_path = os.path.join("data", "of_npcp", "cards.json")
        try:
            # 对每个阵营的卡牌按消耗排序
            sorted_data = {}
            for group, cards in self.data.items():
                if group == 'info':
                    sorted_data[group] = cards
                else:
                    sorted_data[group] = dict(sorted(cards.items(), 
                                                  key=lambda x: int(x[1]['cost'])))
            
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(sorted_data, f, ensure_ascii=False, indent=4)
        except Exception as e:
            messagebox.showerror("错误", f"保存文件时出错: {str(e)}")

if __name__ == "__main__":
    root = tk.Tk()
    app = CardEditor(root)
    root.mainloop() 