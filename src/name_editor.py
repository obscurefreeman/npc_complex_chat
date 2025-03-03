import os
import json
import tkinter as tk
from tkinter import ttk, messagebox, simpledialog

class NameEditor:
    def __init__(self, root):
        self.root = root
        self.root.title("NPC 名字编辑器")
        self.names_data = {
            "male": {},
            "female": {},
            "nicknames": {}
        }
        self.original_zh_data = {}
        self.original_en_data = {}
        self.original_data = {}
        self.load_names()
        self.create_widgets()

    def load_names(self):
        try:
            # 加载中文文件
            with open('data/of_npcp/lang/zh/role.json', 'r', encoding='utf-8') as f:
                self.original_zh_data = json.load(f)
                self.names_data['male'] = self.original_zh_data.get('name', {}).get('male', {})
                self.names_data['female'] = self.original_zh_data.get('name', {}).get('female', {})
                self.names_data['nicknames'] = self.original_zh_data.get('nickname', {})
            
            # 加载英文文件
            with open('data/of_npcp/lang/en/role.json', 'r', encoding='utf-8') as f:
                self.original_en_data = json.load(f)
        except Exception as e:
            messagebox.showerror("错误", f"无法加载名称文件: {str(e)}")

    def create_widgets(self):
        main_frame = ttk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True)

        # 创建选项卡
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True)

        # 男性名字标签页
        male_frame = ttk.Frame(self.notebook)
        self.create_name_tab(male_frame, 'male')
        self.notebook.add(male_frame, text="男性名字")

        # 女性名字标签页
        female_frame = ttk.Frame(self.notebook)
        self.create_name_tab(female_frame, 'female')
        self.notebook.add(female_frame, text="女性名字")

        # 昵称标签页
        nickname_frame = ttk.Frame(self.notebook)
        self.create_name_tab(nickname_frame, 'nicknames')
        self.notebook.add(nickname_frame, text="昵称")

        # 保存按钮
        button_frame = ttk.Frame(main_frame)
        button_frame.pack(fill=tk.X, pady=5)

        save_button = ttk.Button(button_frame, text="保存", command=self.save_names)
        save_button.pack(side=tk.RIGHT, padx=5)

    def create_name_tab(self, parent, gender):
        # 创建Treeview
        tree_frame = ttk.Frame(parent)
        tree_frame.pack(fill=tk.BOTH, expand=True)

        self.tree = ttk.Treeview(tree_frame, columns=('key', 'en', 'zh'), show='headings')
        self.tree.heading('key', text='索引名称')
        self.tree.heading('en', text='英文名')
        self.tree.heading('zh', text='中文名')
        self.tree.pack(fill=tk.BOTH, expand=True)

        # 添加滚动条
        scrollbar = ttk.Scrollbar(tree_frame, orient=tk.VERTICAL, command=self.tree.yview)
        self.tree.configure(yscroll=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # 填充数据
        self.populate_tree(gender)

        # 操作按钮
        button_frame = ttk.Frame(parent)
        button_frame.pack(fill=tk.X, pady=5)

        add_button = ttk.Button(button_frame, text="添加", 
                              command=lambda: self.add_name(gender))
        add_button.pack(side=tk.LEFT, padx=5)

        edit_button = ttk.Button(button_frame, text="编辑", 
                               command=lambda: self.edit_name(gender))
        edit_button.pack(side=tk.LEFT, padx=5)

        delete_button = ttk.Button(button_frame, text="删除", 
                                command=lambda: self.delete_name(gender))
        delete_button.pack(side=tk.LEFT, padx=5)

    def populate_tree(self, gender):
        self.tree.delete(*self.tree.get_children())
        # 按键名排序
        sorted_names = sorted(self.names_data[gender].items(), key=lambda x: x[0].lower().replace(" ", "_"))
        for key, zh_name in sorted_names:
            en_name = self.original_en_data.get('name', {}).get(gender, {}).get(key, '')
            self.tree.insert('', 'end', values=(key, en_name, zh_name))

    def add_name(self, gender):
        # 创建自定义对话框
        dialog = tk.Toplevel(self.root)
        dialog.title("添加名字")
        
        # 创建输入框
        tk.Label(dialog, text="索引名称:").grid(row=0, column=0, padx=5, pady=5)
        key_entry = tk.Entry(dialog)
        key_entry.grid(row=0, column=1, padx=5, pady=5)
        
        tk.Label(dialog, text="英文名:").grid(row=1, column=0, padx=5, pady=5)
        en_entry = tk.Entry(dialog)
        en_entry.grid(row=1, column=1, padx=5, pady=5)
        
        tk.Label(dialog, text="中文名:").grid(row=2, column=0, padx=5, pady=5)
        zh_entry = tk.Entry(dialog)
        zh_entry.grid(row=2, column=1, padx=5, pady=5)
        
        # 确认按钮
        def confirm():
            key = key_entry.get().lower().replace(" ", "_")
            en_name = en_entry.get()
            zh_name = zh_entry.get()
            if key and en_name and zh_name:
                self.names_data[gender][key] = zh_name
                # 更新英文数据
                if 'name' not in self.original_en_data:
                    self.original_en_data['name'] = {}
                if gender not in self.original_en_data['name']:
                    self.original_en_data['name'][gender] = {}
                self.original_en_data['name'][gender][key] = en_name
                self.populate_tree(gender)
                dialog.destroy()
        
        tk.Button(dialog, text="确定", command=confirm).grid(row=3, column=0, columnspan=2, pady=5)

    def edit_name(self, gender):
        selected = self.tree.selection()
        if not selected:
            messagebox.showwarning("警告", "请先选择一个名字")
            return
        
        item = self.tree.item(selected[0])
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
                del self.original_en_data['name'][gender][key]
                # 添加新数据
                self.names_data[gender][new_key] = new_zh
                self.original_en_data['name'][gender][new_key] = new_en
                self.populate_tree(gender)
                dialog.destroy()
        
        tk.Button(dialog, text="确定", command=confirm).grid(row=3, column=0, columnspan=2, pady=5)

    def delete_name(self, gender):
        selected = self.tree.selection()
        if not selected:
            messagebox.showwarning("警告", "请先选择一个名字")
            return
        
        item = self.tree.item(selected[0])
        en_name = item['values'][0]
        del self.names_data[gender][en_name]
        self.populate_tree(gender)

    def save_names(self):
        try:
            # 保留原始数据中与名称无关的部分
            self.original_zh_data['name'] = {
                'male': self.names_data['male'],
                'female': self.names_data['female']
            }
            self.original_zh_data['nickname'] = self.names_data['nicknames']
            
            with open('data/of_npcp/lang/zh/role.json', 'w', encoding='utf-8') as f:
                json.dump(self.original_zh_data, f, ensure_ascii=False, indent=4)

            # 更新英文数据
            self.original_en_data['name'] = {
                'male': {key: self.original_en_data['name']['male'].get(key, '') for key in self.names_data['male']},
                'female': {key: self.original_en_data['name']['female'].get(key, '') for key in self.names_data['female']}
            }
            self.original_en_data['nickname'] = {key: self.original_en_data['nickname'].get(key, '') for key in self.names_data['nicknames']}

            with open('data/of_npcp/lang/en/role.json', 'w', encoding='utf-8') as f:
                json.dump(self.original_en_data, f, ensure_ascii=False, indent=4)

            messagebox.showinfo("成功", "名称已保存！")
        except Exception as e:
            messagebox.showerror("错误", f"无法保存名称文件: {str(e)}")

if __name__ == "__main__":
    root = tk.Tk()
    app = NameEditor(root)
    root.geometry("600x400")
    root.mainloop()
