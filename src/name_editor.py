import os
import json
import tkinter as tk
from tkinter import ttk, messagebox, simpledialog

class NameEditor:
    def __init__(self, root):
        self.root = root
        self.root.title("NPC 名字编辑器")
        self.style = ttk.Style()
        self.style.theme_use('clam')
        self.configure_styles()
        
        self.names_data = {
            "male": {},
            "female": {},
            "nicknames": {}
        }
        self.original_zh_data = {}
        self.original_en_data = {}
        self.name_json_data = {}
        self.load_names()
        self.create_widgets()

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
        
        self.style.configure('Accent.TButton', 
            background='#4CAF50', 
            foreground='white',
            font=('微软雅黑', 11, 'bold'),
            padding=6)
        
        self.style.configure('Small.TButton',
            font=('微软雅黑', 9),
            padding=4)

    def load_names(self):
        try:
            # 加载name.json
            with open('data/of_npcp/name.json', 'r', encoding='utf-8') as f:
                self.name_json_data = json.load(f)
                # 将name.json中的名字转换为字典格式
                self.names_data['male'] = {name.split('.')[-1]: '' for name in self.name_json_data['male']}
                self.names_data['female'] = {name.split('.')[-1]: '' for name in self.name_json_data['female']}
                self.names_data['nicknames'] = {name.split('.')[-1]: '' for name in self.name_json_data['nicknames']}
            
            # 加载中文文件
            with open('data/of_npcp/lang/zh/role.json', 'r', encoding='utf-8') as f:
                self.original_zh_data = json.load(f)
                # 合并中文翻译
                for gender in ['male', 'female']:
                    for key in self.names_data[gender]:
                        self.names_data[gender][key] = self.original_zh_data.get('name', {}).get(gender, {}).get(key, '')
                for key in self.names_data['nicknames']:
                    self.names_data['nicknames'][key] = self.original_zh_data.get('nickname', {}).get(key, '')
            
            # 加载英文文件
            with open('data/of_npcp/lang/en/role.json', 'r', encoding='utf-8') as f:
                self.original_en_data = json.load(f)
                if 'nickname' not in self.original_en_data:
                    self.original_en_data['nickname'] = {}
        except Exception as e:
            messagebox.showerror("错误", f"无法加载名称文件: {str(e)}")

    def create_widgets(self):
        main_frame = ttk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True)

        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        male_frame = ttk.Frame(self.notebook)
        self.create_name_tab(male_frame, 'male')
        self.notebook.add(male_frame, text="男性名字")

        female_frame = ttk.Frame(self.notebook)
        self.create_name_tab(female_frame, 'female')
        self.notebook.add(female_frame, text="女性名字")

        nickname_frame = ttk.Frame(self.notebook)
        self.create_name_tab(nickname_frame, 'nicknames')
        self.notebook.add(nickname_frame, text="昵称")

        button_frame = ttk.Frame(main_frame)
        button_frame.pack(fill=tk.X, pady=10, padx=10)

        save_button = ttk.Button(button_frame, text="保存", command=self.save_names, style='Accent.TButton')
        save_button.pack(side=tk.RIGHT, padx=5)

    def create_name_tab(self, parent, gender):
        tree_frame = ttk.Frame(parent)
        tree_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        tree = ttk.Treeview(tree_frame, columns=('key', 'en', 'zh'), show='headings')
        tree.heading('key', text='索引名称')
        tree.heading('en', text='英文名')
        tree.heading('zh', text='中文名')
        tree.pack(fill=tk.BOTH, expand=True)

        scrollbar = ttk.Scrollbar(tree_frame, orient=tk.VERTICAL, command=tree.yview)
        tree.configure(yscroll=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.populate_tree(gender, tree)

        button_frame = ttk.Frame(parent)
        button_frame.pack(fill=tk.X, pady=5, padx=10)

        add_button = ttk.Button(button_frame, text="添加", 
                              command=lambda: self.add_name(gender, tree),
                              style='Small.TButton')
        add_button.pack(side=tk.LEFT, padx=5)

        edit_button = ttk.Button(button_frame, text="编辑", 
                               command=lambda: self.edit_name(gender, tree),
                               style='Small.TButton')
        edit_button.pack(side=tk.LEFT, padx=5)

        delete_button = ttk.Button(button_frame, text="删除", 
                                command=lambda: self.delete_name(gender, tree),
                                style='Small.TButton')
        delete_button.pack(side=tk.LEFT, padx=5)

    def populate_tree(self, gender, tree):
        tree.delete(*tree.get_children())
        sorted_names = sorted(self.names_data[gender].items(), key=lambda x: x[0].lower())
        for key, zh_name in sorted_names:
            if gender == 'nicknames':
                en_name = self.original_en_data.get('nickname', {}).get(key, '')
            else:
                en_name = self.original_en_data.get('name', {}).get(gender, {}).get(key, '')
            tree.insert('', 'end', values=(key, en_name, zh_name))

    def add_name(self, gender, tree):
        dialog = tk.Toplevel(self.root)
        dialog.title("添加名字")
        dialog.geometry("300x200")
        
        ttk.Label(dialog, text="索引名称:").grid(row=0, column=0, padx=10, pady=5)
        key_entry = ttk.Entry(dialog)
        key_entry.grid(row=0, column=1, padx=10, pady=5)
        
        ttk.Label(dialog, text="英文名:").grid(row=1, column=0, padx=10, pady=5)
        en_entry = ttk.Entry(dialog)
        en_entry.grid(row=1, column=1, padx=10, pady=5)
        
        ttk.Label(dialog, text="中文名:").grid(row=2, column=0, padx=10, pady=5)
        zh_entry = ttk.Entry(dialog)
        zh_entry.grid(row=2, column=1, padx=10, pady=5)
        
        def confirm():
            key = key_entry.get().lower().replace(" ", "_")
            en_name = en_entry.get()
            zh_name = zh_entry.get()
            if key and en_name and zh_name:
                # 更新所有三个文件的数据
                self.names_data[gender][key] = zh_name
                self.name_json_data[gender].append(f"name.{gender}.{key}")
                
                if gender == 'nicknames':
                    if 'nickname' not in self.original_en_data:
                        self.original_en_data['nickname'] = {}
                    self.original_en_data['nickname'][key] = en_name
                else:
                    if 'name' not in self.original_en_data:
                        self.original_en_data['name'] = {}
                    if gender not in self.original_en_data['name']:
                        self.original_en_data['name'][gender] = {}
                    self.original_en_data['name'][gender][key] = en_name
                self.populate_tree(gender, tree)
                dialog.destroy()
        
        ttk.Button(dialog, text="确定", command=confirm, style='Small.TButton').grid(row=3, column=0, columnspan=2, pady=10)

    def edit_name(self, gender, tree):
        selected = tree.selection()
        if not selected:
            messagebox.showwarning("警告", "请先选择一个名字")
            return
        
        item = tree.item(selected[0])
        key, en_name, zh_name = item['values']
        
        # 创建编辑对话框
        dialog = tk.Toplevel(self.root)
        dialog.title("编辑名字")
        
        # 创建输入框
        tk.Label(dialog, text="索引名称:").grid(row=0, column=0, padx=5, pady=5)
        key_entry = tk.Entry(dialog)
        key_entry.insert(0, key)
        key_entry.grid(row=0, column=1, padx=5, pady=5)
        
        tk.Label(dialog, text="英文名:").grid(row=1, column=0, padx=5, pady=5)
        en_entry = tk.Entry(dialog)
        en_entry.insert(0, en_name)
        en_entry.grid(row=1, column=1, padx=5, pady=5)
        
        tk.Label(dialog, text="中文名:").grid(row=2, column=0, padx=5, pady=5)
        zh_entry = tk.Entry(dialog)
        zh_entry.insert(0, zh_name)
        zh_entry.grid(row=2, column=1, padx=5, pady=5)
        
        # 确认按钮
        def confirm():
            new_key = key_entry.get().lower().replace(" ", "_")
            new_en = en_entry.get()
            new_zh = zh_entry.get()
            if new_key and new_en and new_zh:
                # 删除旧数据
                del self.names_data[gender][key]
                if gender == 'nicknames':
                    del self.original_en_data['nickname'][key]
                del self.original_en_data['name'][gender][key]
                # 添加新数据
                self.names_data[gender][new_key] = new_zh
                self.original_en_data['name'][gender][new_key] = new_en
                self.populate_tree(gender, tree)
                dialog.destroy()
        
        tk.Button(dialog, text="确定", command=confirm).grid(row=3, column=0, columnspan=2, pady=5)

    def delete_name(self, gender, tree):
        selected = tree.selection()
        if not selected:
            messagebox.showwarning("警告", "请先选择一个名字")
            return
        
        item = tree.item(selected[0])
        en_name = item['values'][0]
        del self.names_data[gender][en_name]
        self.populate_tree(gender, tree)

    def save_names(self):
        try:
            # 按索引名称的首字母顺序整理数据
            self.original_zh_data['name']['male'] = dict(sorted(self.names_data['male'].items()))
            self.original_zh_data['name']['female'] = dict(sorted(self.names_data['female'].items()))
            self.original_zh_data['nickname'] = dict(sorted(self.names_data['nicknames'].items()))

            self.original_en_data['name']['male'] = dict(sorted({key: self.original_en_data['name']['male'].get(key, '') for key in self.names_data['male']}.items()))
            self.original_en_data['name']['female'] = dict(sorted({key: self.original_en_data['name']['female'].get(key, '') for key in self.names_data['female']}.items()))
            self.original_en_data['nickname'] = dict(sorted({key: self.original_en_data['nickname'].get(key, '') for key in self.names_data['nicknames']}.items()))

            with open('data/of_npcp/lang/zh/role.json', 'w', encoding='utf-8') as f:
                json.dump(self.original_zh_data, f, ensure_ascii=False, indent=4)

            with open('data/of_npcp/lang/en/role.json', 'w', encoding='utf-8') as f:
                json.dump(self.original_en_data, f, ensure_ascii=False, indent=4)

            messagebox.showinfo("成功", "名称已保存！")
        except Exception as e:
            messagebox.showerror("错误", f"无法保存名称文件: {str(e)}")

if __name__ == "__main__":
    root = tk.Tk()
    app = NameEditor(root)
    root.geometry("1920x1080")
    root.mainloop()
