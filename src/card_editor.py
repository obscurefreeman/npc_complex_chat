# -*- coding: utf-8 -*-
import os
import json
import tkinter as tk
from tkinter import ttk, messagebox, filedialog, simpledialog
from PIL import Image, ImageTk
import re

class CardEditor:
    def __init__(self, root):
        self.root = root
        self.root.title("卡牌编辑器")
        self.style = ttk.Style()
        self.style.theme_use('clam')  # 使用现代主题
        self.configure_styles()  # 添加样式配置方法
        self.data = None
        self.current_group = None
        self.current_card = None
        self.image_dir = os.path.join(os.getcwd(), "materials", "ofnpcp", "cards", "large")
        self.lang_dir = "data/of_npcp/lang"
        self.current_lang = "zh"
        self.load_language()
        
        # 创建主界面布局
        self.create_widgets()
        
        # 自动加载cards.json
        self.load_file(os.path.join("data", "of_npcp", "cards.json"))

        # 在创建控件后添加语言切换菜单
        self.create_language_menu()

    def configure_styles(self):
        self.style.configure('TFrame', background='#F5F5F5')
        self.style.configure('TLabel', background='#F5F5F5', font=('微软雅黑', 10))
        self.style.configure('TButton', font=('微软雅黑', 10), relief='flat')
        self.style.map('TButton',
            background=[('active', '#4CAF50'), ('!disabled', '#2196F3')],
            foreground=[('active', 'white'), ('!disabled', 'white')])
        self.style.configure('Treeview.Heading', font=('微软雅黑', 10, 'bold'))
        self.style.configure('Treeview', rowheight=25)
        self.style.configure('TLabelframe', borderwidth=2, relief='groove')
        self.style.configure('TEntry', 
            fieldbackground='#FFFFFF',
            bordercolor='#E0E0E0',
            lightcolor='#E0E0E0',
            darkcolor='#E0E0E0',
            relief='flat',
            padding=5)
        
        self.style.configure('Vertical.TScrollbar', 
            gripcount=0,
            arrowsize=14,
            troughcolor='#F0F0F0',
            background='#C0C0C0')
        
        self.style.map('Vertical.TScrollbar',
            background=[('active', '#A0A0A0'), ('!disabled', '#C0C0C0')])
        
        self.style.configure('TLabelframe.Label', 
            font=('微软雅黑', 10, 'bold'),
            foreground='#404040')

        self.style.configure('Accent.TButton', 
            background='#4CAF50', 
            foreground='white',
            font=('微软雅黑', 11, 'bold'),
            padding=6)
        
        self.style.configure('Small.TButton',
            font=('微软雅黑', 9),
            padding=4)
        
        self.style.configure('Flag.TMenu',
            font=('Segoe UI Emoji', 12))

    def create_widgets(self):
        # 主布局使用PanedWindow实现可调节布局
        main_panel = ttk.PanedWindow(self.root, orient=tk.HORIZONTAL)
        main_panel.pack(fill=tk.BOTH, expand=True)

        # 左侧面板 - 阵营管理
        left_panel = ttk.Frame(main_panel, width=200)
        main_panel.add(left_panel, weight=1)
        
        # 修改后的阵营列表头部（与卡牌列表风格一致）
        group_header = ttk.Frame(left_panel)
        group_header.pack(fill=tk.X, pady=(0,5))
        ttk.Label(group_header, text=self.lang["group_list"], font=('微软雅黑', 11, 'bold')).pack(side=tk.LEFT)
        ttk.Button(group_header, text="+", 
                  command=self.add_group, 
                  style='Small.TButton').pack(side=tk.RIGHT, padx=2)
        
        # 将Listbox替换为Treeview
        self.group_tree = ttk.Treeview(left_panel, columns=('name',), show='headings', height=10)
        self.group_tree.heading('name', text='阵营名称')
        self.group_tree.column('name', width=180, anchor='w')
        self.group_tree.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.group_tree.bind('<<TreeviewSelect>>', self.on_group_select)
        # 添加鼠标滚轮事件绑定
        self.group_tree.bind("<MouseWheel>", self.on_group_wheel)

        # 中间面板 - 卡牌列表
        middle_panel = ttk.Frame(main_panel, width=400)
        main_panel.add(middle_panel, weight=2)
        
        # 中间面板头部（与阵营列表风格一致）
        card_header = ttk.Frame(middle_panel)
        card_header.pack(fill=tk.X, pady=(0,5))
        ttk.Label(card_header, text=self.lang["card_list"], font=('微软雅黑', 11, 'bold')).pack(side=tk.LEFT)
        ttk.Button(card_header, text="+", 
                 command=self.add_card, 
                 style='Small.TButton').pack(side=tk.RIGHT, padx=2)
        
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
        # 添加鼠标滚轮事件绑定
        self.card_tree.bind("<MouseWheel>", self.on_card_wheel)

        # 右侧面板 - 卡牌详情
        right_panel = ttk.Frame(main_panel, width=400)
        main_panel.add(right_panel, weight=2)
        
        # 使用网格布局管理器
        right_panel.grid_columnconfigure(0, weight=1)
        right_panel.grid_rowconfigure(0, weight=1)  # 图片区域
        right_panel.grid_rowconfigure(1, weight=2)  # 详情区域

        # 卡牌图片
        self.card_image = tk.Label(right_panel)
        self.card_image.grid(row=0, column=0, pady=10, sticky='ns', padx=10)

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
        self.desc_text = tk.Text(self.detail_frame, height=4, width=30, wrap=tk.WORD, font=('微软雅黑', 10), 
                            borderwidth=1, relief='solid', padx=5, pady=5)
        self.desc_text.grid(row=4, column=1, sticky=tk.EW, padx=5, pady=2)
        
        ttk.Separator(self.detail_frame, orient='horizontal').grid(row=5, column=0, columnspan=2, sticky='ew', pady=5)
        
        ttk.Label(self.detail_frame, text="回应:").grid(row=6, column=0, sticky=tk.W)
        self.response_text = tk.Text(self.detail_frame, height=4, width=30, wrap=tk.WORD, font=('微软雅黑', 10),
                            borderwidth=1, relief='solid', padx=5, pady=5)
        self.response_text.grid(row=6, column=1, sticky=tk.EW, padx=5, pady=2)
        
        ttk.Separator(self.detail_frame, orient='horizontal').grid(row=7, column=0, columnspan=2, sticky='ew', pady=5)
        
        ttk.Label(self.detail_frame, text="标签:").grid(row=8, column=0, sticky=tk.W)
        self.tag_entry = ttk.Entry(self.detail_frame)
        self.tag_entry.grid(row=8, column=1, sticky=tk.EW, padx=5, pady=2)
        
        # 保存按钮
        self.save_btn = ttk.Button(self.detail_frame, text="保存修改", command=self.save_card)
        self.save_btn.grid(row=9, column=1, sticky=tk.E, pady=5)

        # 修改滚动条事件绑定（完全移除悬停样式配置）
        def add_scrollbar(text_widget, row):
            scrollbar = ttk.Scrollbar(self.detail_frame, 
                                    command=text_widget.yview,
                                    style='Vertical.TScrollbar')
            scrollbar.grid(row=row, column=2, sticky='ns', pady=5)
            text_widget.config(yscrollcommand=scrollbar.set)

        # 修改滚动条调用方式
        add_scrollbar(self.desc_text, 4)
        add_scrollbar(self.response_text, 6)

        # 优化文本区域配置（添加边框圆角）
        for text_widget in [self.desc_text, self.response_text]:
            text_widget.config(
                relief='flat',
                highlightthickness=1,
                highlightcolor='#E0E0E0',
                highlightbackground='#E0E0E0',
                padx=8,
                pady=8
            )

        # 修改输入框样式
        for entry in [self.key_entry, self.name_entry, self.type_entry, self.cost_entry, self.tag_entry]:
            entry.config(font=('微软雅黑', 10), background='#FFFFFF')

        # 修改保存按钮样式
        self.save_btn.config(style='Accent.TButton')
        self.style.configure('Accent.TButton', 
            background='#4CAF50', 
            foreground='white',
            font=('微软雅黑', 11, 'bold'),
            padding=6)

        # 增加控件间距（统一修改所有padx/pady参数）
        for panel in [left_panel, middle_panel, right_panel]:
            for child in panel.winfo_children():
                if isinstance(child, (ttk.Label, ttk.Button)):
                    child.config(padding=5)

    def load_file(self, file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                self.data = json.load(f)
            self.populate_groups()
        except Exception as e:
            messagebox.showerror("错误", f"无法加载文件: {str(e)}")

    def populate_groups(self):
        self.group_tree.delete(*self.group_tree.get_children())
        for group in self.data['info']:
            self.group_tree.insert('', 'end', 
                                 values=(self.data['info'][group]['name'],), 
                                 iid=group)

    def on_group_select(self, event):
        selection = self.group_tree.selection()
        if selection:
            self.current_group = selection[0]
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
            # 获取旧图片路径
            old_image_path = os.path.join(self.image_dir, f"{self.current_card_key}.png")
            
            # 删除旧的卡牌数据
            if self.current_card_key in self.data[self.current_group]:
                del self.data[self.current_group][self.current_card_key]
            elif self.current_card_key in self.data['general']:
                del self.data['general'][self.current_card_key]
            
            # 更新当前卡牌键
            self.current_card_key = new_key
            
            # 重命名图片文件
            if os.path.exists(old_image_path):
                new_image_path = os.path.join(self.image_dir, f"{new_key}.png")
                try:
                    os.rename(old_image_path, new_image_path)
                except Exception as e:
                    messagebox.showerror("错误", f"重命名图片时出错: {str(e)}")
            
            # 处理预览图片的重命名
            old_preview_image_path = os.path.join(self.image_dir.replace("large", "preview"), f"{self.current_card_key}.png")
            if os.path.exists(old_preview_image_path):
                new_preview_image_path = os.path.join(self.image_dir.replace("large", "preview"), f"{new_key}.png")
                try:
                    os.rename(old_preview_image_path, new_preview_image_path)
                except Exception as e:
                    messagebox.showerror("错误", f"重命名预览图片时出错: {str(e)}")
        
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
        
        messagebox.showinfo(self.lang["success"], self.lang["save_success"])

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
            messagebox.showerror(self.lang["error"], 
                                f"{self.lang['save_error']}: {str(e)}")

    def load_language(self):
        try:
            lang_file = os.path.join(self.lang_dir, f"{self.current_lang}.json")
            with open(lang_file, "r", encoding="utf-8") as f:
                self.lang = json.load(f).get("ui", {})
        except Exception as e:
            messagebox.showerror("语言错误", f"加载语言文件失败: {str(e)}")
            self.lang = {}

    def create_language_menu(self):
        menu_bar = tk.Menu(self.root)
        lang_menu = tk.Menu(menu_bar, tearoff=0)
        lang_menu.add_command(label="中文", command=lambda: self.set_language("zh"))
        lang_menu.add_command(label="English", command=lambda: self.set_language("en"))
        menu_bar.add_cascade(label="Language", menu=lang_menu)
        self.root.config(menu=menu_bar)
        # 设置全局菜单字体
        self.root.option_add('*Menu*Font', 'Segoe UI Emoji 12')

    def set_language(self, lang):
        self.current_lang = lang
        self.load_language()
        self.update_ui_text()

    def update_ui_text(self):
        try:
            # 修复标签更新方式
            labels = {
                0: "key", 1: "name", 2: "type", 3: "cost",
                4: "desc", 6: "response", 8: "tags"
            }
            for row, text_key in labels.items():
                label = self.detail_frame.grid_slaves(row=row, column=0)[0]
                label.config(text=f"{self.lang[text_key]}:")
            
            # 更新其他文本元素...
        except Exception as e:
            messagebox.showerror("UI错误", f"更新界面失败: {str(e)}")

    # 新增添加卡牌方法
    def add_card(self):
        new_key = simpledialog.askstring(self.lang["add_card"], self.lang["key"]+":")
        if new_key:
            new_card = {
                "name": "New Card",
                "type": "Basic",
                "cost": "1",
                "d": [],
                "a": [],
                "tag": []
            }
            self.data[self.current_group][new_key] = new_card
            self.populate_cards()
            self.save_to_file()

    # 新增添加阵营方法  
    def add_group(self):
        dialog = tk.Toplevel(self.root)
        dialog.title(self.lang["add_group"])
        
        ttk.Label(dialog, text=self.lang["key"]+":").grid(row=0, column=0, padx=5, pady=2)
        key_entry = ttk.Entry(dialog)
        key_entry.grid(row=0, column=1, padx=5, pady=2)
        
        ttk.Label(dialog, text=self.lang["name"]+":").grid(row=1, column=0, padx=5, pady=2)
        name_entry = ttk.Entry(dialog)
        name_entry.grid(row=1, column=1, padx=5, pady=2)
        
        ttk.Label(dialog, text=self.lang["desc"]+":").grid(row=2, column=0, padx=5, pady=2)
        desc_entry = ttk.Entry(dialog)
        desc_entry.grid(row=2, column=1, padx=5, pady=2)
        
        def save_group():
            group_key = key_entry.get()
            group_name = name_entry.get()
            group_desc = desc_entry.get()
            if group_key and group_name and group_desc:
                if group_key in self.data["info"]:
                    messagebox.showerror(self.lang["error"], "阵营索引已存在！")
                    return
                self.data["info"][group_key] = {
                    "name": group_name,
                    "desc": group_desc
                }
                self.data[group_key] = {}
                self.populate_groups()
                self.save_to_file()
                dialog.destroy()
        
        ttk.Button(dialog, text=self.lang["confirm"], command=save_group).grid(row=3, columnspan=2, pady=5)

    # 新增滚轮切换方法
    def on_group_wheel(self, event):
        """处理阵营列表滚轮事件"""
        children = self.group_tree.get_children()
        if not children:
            return
        
        current = self.group_tree.selection()
        if current:
            index = children.index(current[0])
            delta = -1 if event.delta > 0 else 1  # Windows和Mac的delta值方向相反
            new_index = max(0, min(len(children)-1, index + delta))
            self.group_tree.selection_set(children[new_index])
            self.on_group_select(None)

    def on_card_wheel(self, event):
        """处理卡牌列表滚轮事件"""
        children = self.card_tree.get_children()
        if not children:
            return
        
        current = self.card_tree.selection()
        if current:
            index = children.index(current[0])
            delta = -1 if event.delta > 0 else 1  # Windows和Mac的delta值方向相反
            new_index = max(0, min(len(children)-1, index + delta))
            self.card_tree.selection_set(children[new_index])
            self.on_card_select(None)

if __name__ == "__main__":
    root = tk.Tk()
    app = CardEditor(root)
    root.mainloop() 