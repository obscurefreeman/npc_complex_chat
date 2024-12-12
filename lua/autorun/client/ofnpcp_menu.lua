AddCSLuaFile()

local function RefreshNPCButtons(left_panel)
	-- 清除现有按钮
	left_panel:Clear()
	
	-- 获取所有NPC数据
	local npcs = GetAllNPCsList()
	
	-- 为每个NPC创建按钮
	for entIndex, npcData in pairs(npcs) do
		-- 创建一个容器面板来放置图标和按钮
		local container = vgui.Create("DPanel", left_panel)
		container:Dock(TOP)
		container:DockMargin(0, 0, 0, 2)
		container:SetTall(64) -- 设置合适的高度
		container:SetPaintBackground(false)
		
		-- 创建模型图标
		local icon = vgui.Create("ModelImage", container)
		icon:Dock(LEFT)
		icon:SetSize(64, 64)
		icon:SetModel(npcData.model or "models/error.mdl")
		
		-- 创建按钮
		local button = vgui.Create("XPButton", container)
		button:Dock(RIGHT)
		button:SetSize(left_panel:GetWide() - 88, 64) -- 调整按钮宽度
		button:SetText(L(npcData.name))
        if npcData.job then
            button:SetToolTip(L(npcData.job))
            if npcData.specialization then
                button:SetToolTip(L(npcData.specialization))
            end
        elseif npcData.rank then
            button:SetToolTip(L(npcData.rank))
        end
	end
end

local function example()
	local frame = vgui.Create("XPFrame")
	frame:SetTitle("NPC性格控制")
	-- frame:SetBackgroundBlur(false)
	-- frame:SetFrameBlur(false)
	frame:SetNoRounded(false)

	local sheet = vgui.Create("XPPropertySheet", frame)
	sheet:DockMargin(4, 4, 4, 4)
	sheet:Dock(FILL)

	local pan1 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet("预览标签页", pan1)

	local pan2 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet("空白标签页", pan2)

	local bottom_button1 = frame:SetBottomButton("左侧", LEFT, function()
		frame:Remove()
	end)

	local bottom_button2 = frame:SetBottomButton("右侧", RIGHT, function()
		frame:Remove()
	end)

	local bottom_button3 = frame:SetBottomButton("关闭", FILL, function()
		frame:Remove()
	end)

	--[[
		Left Panel
	]]

	local left_panel = vgui.Create("XPScrollPanel", pan1)
	left_panel:Dock(LEFT)
	left_panel:DockMargin(6, 6, 6, 6)
	left_panel:SetWide(frame:GetWide() / 2 - 4)

	-- 初始加载NPC列表
	RefreshNPCButtons(left_panel)
	
	-- 添加更新钩子
	hook.Add("RefreshNPCMenu", "UpdateNPCButtonList", function()
		if IsValid(left_panel) then
			RefreshNPCButtons(left_panel)
		end
	end)
	
	-- 当面板关闭时移除钩子
	frame.OnRemove = function()
		hook.Remove("RefreshNPCMenu", "UpdateNPCButtonList")
	end

	--[[
		Right Panel
	]]

	local right_panel = vgui.Create("XPScrollPanel", pan1)
	right_panel:Dock(RIGHT)
	right_panel:DockMargin(6, 6, 6, 6)
	right_panel:SetWide(frame:GetWide() / 2 - 20)

	-- ComboBox
	local combobox = vgui.Create("XPComboBox", right_panel)
	combobox:Dock(TOP)
	combobox:DockMargin(4, 4, 4, 16)
	combobox:SetValue("请选择一个数字")

	for i = 1, 9 do
		combobox:AddChoice(i)
	end

	-- List
	local list = vgui.Create("XPListView", right_panel)
	list:Dock(TOP)
	list:SetTall(frame:GetTall() / 2)
	list:DockMargin(4, 4, 4, 4)

	list:AddColumn("序号")
	list:AddColumn("当前值+前值")

	for i = 1, 32 do
		list:AddLine(i, i + (i - 1))
	end

	-- Text Entry
	local entry = vgui.Create("XPTextEntry", right_panel)
	entry:Dock(TOP)
	entry:DockMargin(4, 4, 4, 4)
	entry:SetTall(32)
	entry:SetText("文本输入框")

	-- Checkbox
	for i = 1, 6 do
		local pnl = vgui.Create("EditablePanel", right_panel)
		pnl:Dock(TOP)
		pnl:SetTall(24)
		pnl:DockMargin(4, 4, 4, 4)

		local cb = vgui.Create("XPCheckBox", pnl)
		cb:SetPos(0, 0)
		cb:SetSize(24, 24)
		cb:SetValue(true)

		local txt = vgui.Create("DLabel", pnl)
		txt:SetFont("xpgui_medium")
		txt:SetPos(28, 0)
		txt:SetWide(frame:GetWide() / 2)
		txt:SetText("简单复选框")
	end
end

list.Set("DesktopWindows", "ofnpcp", {
    title = "npc性格",
    icon = "oftoollogo/ofnpcplogo.png",
    init = function()
        example()
    end
})