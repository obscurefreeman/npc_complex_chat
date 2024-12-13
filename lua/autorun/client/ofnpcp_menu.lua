AddCSLuaFile()

local function RefreshNPCButtons(left_panel, right_panel)
	-- 清除现有按钮
	left_panel:Clear()
	
	-- 获取所有NPC数据
	local npcs = GetAllNPCsList()
	
	-- 为每个NPC创建按钮
	for entIndex, npcData in pairs(npcs) do
		-- 创建新的NPC按钮
		local button = vgui.Create("OFNPCButton", left_panel)
		button:Dock(TOP)
		button:DockMargin(0, 0, 0, 2)
		button:SetTall(ScrW()/ 24)
		button:SetModel(npcData.model or "models/error.mdl")
		button:SetTitle(L(npcData.name))
		
		-- 设置描述文字
		local description = ""
		if npcData.job then
			description = L(npcData.job)
			if npcData.specialization then
				description = description .. " - " .. L(npcData.specialization)
			end
		elseif npcData.rank then
			description = L(npcData.rank)
		end
		button:SetDescription(description)
		
		-- 按钮点击事件
		button.DoClick = function()
			right_panel:Clear()
			
			local nameEntry = vgui.Create("OFTextEntry", right_panel)
			nameEntry:Dock(TOP)
			nameEntry:DockMargin(4, 4, 4, 4)
			nameEntry:SetTall(32)
			nameEntry:SetValue(L(npcData.name) or "")
			
			local submitButton = vgui.Create("OFButton", right_panel)
			submitButton:Dock(TOP)
			submitButton:DockMargin(4, 4, 4, 4)
			submitButton:SetText("确认修改")
			submitButton.DoClick = function()
				local newName = nameEntry:GetValue()
				if newName and newName ~= "" then
					-- 发送更新请求到服务器
					net.Start("UpdateNPCName")
						net.WriteInt(entIndex, 32)
						net.WriteString(newName)
					net.SendToServer()
				end
			end
			
			-- 添加分隔线
			local divider = vgui.Create("DPanel", right_panel)
			divider:Dock(TOP)
			divider:DockMargin(4, 8, 4, 8)
			divider:SetTall(2)
			divider.Paint = function(self, w, h)
				surface.SetDrawColor(100, 100, 100, 255)
				surface.DrawRect(0, 0, w, h)
			end
		end

		button.DoRightClick = function()
			local menu = vgui.Create("OFMenu")
			menu:AddOption("治疗 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(entIndex, 32)
					net.WriteString("heal")
				net.SendToServer()
			end)
			
			menu:AddOption("杀死 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(entIndex, 32)
					net.WriteString("kill")
				net.SendToServer()
				
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
			
			menu:AddOption("删除 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(entIndex, 32)
					net.WriteString("remove")
				net.SendToServer()
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
						
			menu:AddOption("治疗所有 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(-1, 32)
					net.WriteString("healall")
				net.SendToServer()
				
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
			
			menu:AddOption("杀死所有 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(-1, 32)
					net.WriteString("killall")
				net.SendToServer()
				
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
			
			menu:AddOption("删除所有 NPC", function()
				net.Start("NPCAction")
					net.WriteInt(-1, 32)
					net.WriteString("removeall")
				net.SendToServer()
				
				timer.Simple(0.1, function()
					RefreshNPCButtons(left_panel, right_panel)
				end)
			end)
			
			menu:AddOption("刷新列表", function()
				RefreshNPCButtons(left_panel, right_panel)
			end)
			
			menu:Open()
		end
	end
end

local function example()
	local frame = vgui.Create("OFFrame")
	frame:SetTitle("NPC性格控制")

	local sheet = vgui.Create("OFPropertySheet", frame)
	sheet:DockMargin(4, 4, 4, 4)
	sheet:Dock(FILL)

	local pan1 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet("预览标签页", pan1)

	local pan2 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet("空白标签页", pan2)
	
	-- 添加技能按钮到pan2
	local skillButton = vgui.Create("OFSkillButton", pan2)
	skillButton:SetSize(300, 64)
	skillButton:SetIcon("path/to/your/icon")
	skillButton:SetTitle("技能名称")
	skillButton:SetDescription("技能描述")
	skillButton:SetBorderColor(Color(255, 100, 100))
	skillButton:SetPos(10, 10) -- 设置按钮位置

	-- 创建一个水平分割面板
	local horizontalDivider = vgui.Create("DHorizontalDivider", pan1)
	horizontalDivider:Dock(FILL)
	horizontalDivider:DockMargin(6, 6, 6, 6)
	horizontalDivider:SetLeftWidth(ScrW()/ 3) -- 设置左侧面板的初始宽度
	horizontalDivider:SetDividerWidth(8) -- 设置分割线宽度

	local left_panel = vgui.Create("OFScrollPanel")
	horizontalDivider:SetLeft(left_panel)

	local right_panel = vgui.Create("OFScrollPanel")
	horizontalDivider:SetRight(right_panel)

	-- 初始加载NPC列表
	RefreshNPCButtons(left_panel, right_panel)
	
	-- 添加更新钩子
	hook.Add("RefreshNPCMenu", "UpdateNPCButtonList", function()
		if IsValid(left_panel) then
			RefreshNPCButtons(left_panel, right_panel)
		end
	end)
	
	-- 当面板关闭时移除钩子
	frame.OnRemove = function()
		hook.Remove("RefreshNPCMenu", "UpdateNPCButtonList")
	end
end

list.Set("DesktopWindows", "ofnpcp", {
    title = "NPC 性格",
    icon = "oftoollogo/ofnpcplogo.png",
    init = function()
        example()
    end
})