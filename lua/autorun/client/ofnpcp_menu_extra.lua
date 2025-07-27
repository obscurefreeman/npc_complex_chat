CreateClientConVar("of_garrylord_player2_enable", "0", true, true, "", 0, 1)

function OFNPCP_SetUpExtraFeatureMenu(extraFeatureMenu)
	local sheet = vgui.Create("OFPropertySheet", extraFeatureMenu)
	sheet:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	sheet:Dock(FILL)

	local pan1 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet(ofTranslate("ui.tab.model"), pan1, "icon16/monkey.png")

	local pan1HorizontalDivider = vgui.Create("DHorizontalDivider", pan1)
	pan1HorizontalDivider:Dock(FILL)
	pan1HorizontalDivider:DockMargin(6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale)
	pan1HorizontalDivider:SetLeftWidth(ScrW() / 4)

	local pan1LeftPanel = vgui.Create("EditablePanel")
	pan1HorizontalDivider:SetLeft(pan1LeftPanel)

	local pan1RightPanel = vgui.Create("OFScrollPanel")
	pan1HorizontalDivider:SetRight(pan1RightPanel)


	local function SetupPan1(pan1LeftPanel, pan1RightPanel)
		-- 本地模型表，按分类存储
		local selectedModels = {
			npc_citizen = {},
			npc_combine_s = {},
			npc_metropolice = {}
		}

		-- 尝试加载已保存的模型数据
		if file.Exists("of_npcp/model_settings.txt", "DATA") then
			local savedData = file.Read("of_npcp/model_settings.txt", "DATA")
			if savedData then
				local loadedModels = util.JSONToTable(savedData)
				if loadedModels then
					selectedModels = loadedModels
				end
			end
		end

		-- 创建Tab面板
		local tabPanel = vgui.Create("OFPropertySheet", pan1LeftPanel)
		tabPanel:Dock(FILL)
		tabPanel:DockMargin(0, 8 * OFGUI.ScreenScale, 0, 0) -- 增加顶部边距

		-- 创建右侧模型布局
		local modelLayout = vgui.Create("OFIconLayout", pan1RightPanel)
		modelLayout:Dock(TOP)
		modelLayout:SetSpaceX(8 * OFGUI.ScreenScale)
		modelLayout:SetSpaceY(8 * OFGUI.ScreenScale)
		modelLayout:SetStretchWidth(true)

		-- 创建每个分类的滚动面板
		local scrollPanels = {}
		local function CreateNPCTab(npcClass, name)
			local scrollPanel = vgui.Create("OFScrollPanel")
			scrollPanels[npcClass] = scrollPanel
			
			-- 填充已选模型
			local function UpdateScrollPanel()
				scrollPanel:Clear()
				local models = selectedModels[npcClass] or {}
				for _, model in ipairs(models) do
					local selectedIcon = vgui.Create("OFNPCButton", scrollPanel)
					selectedIcon:Dock(TOP)
					selectedIcon:DockMargin(0, 0, 0, 2)
					selectedIcon:SetTall(80 * OFGUI.ScreenScale)
					selectedIcon:SetModel(model or "models/error.mdl")
					local npcName = "Unknown NPC"
					for _, v in pairs(list.Get("NPC")) do
						if v.Model == model then
							npcName = v.Name or v.Class or "Unknown NPC"
							break
						end
					end
					selectedIcon:SetTitle(npcName)
					selectedIcon:SetDescription(model)
					selectedIcon.DoClick = function()
						-- 从对应分类的模型表中移除
						table.RemoveByValue(selectedModels[npcClass], model)
						selectedIcon:Remove()
					end
				end
			end
			UpdateScrollPanel()
			
			tabPanel:AddSheet(name, scrollPanel)
		end

		-- 创建三个分类的Tab
		CreateNPCTab("npc_citizen", ofTranslate("ui.model.citizen"))
		CreateNPCTab("npc_combine_s", ofTranslate("ui.model.combine"))
		CreateNPCTab("npc_metropolice", ofTranslate("ui.model.metropolice"))

		-- 初始化时显示第一个tab的内容
		local function UpdateModelLayout(npcClass)
			modelLayout:Clear()
			-- 获取并显示该分类的模型
			local models = {}
			for _, v in pairs(list.Get("NPC")) do
				if v.Class == npcClass and not table.HasValue(models, v.Model) then
					table.insert(models, v.Model)
				end
			end
			for _, model in ipairs(models) do
				local icon = vgui.Create("SpawnIcon", modelLayout)
				icon:SetModel(model)
				icon:SetSize(96 * OFGUI.ScreenScale, 96 * OFGUI.ScreenScale)
				icon:SetTooltipPanelOverride("OFTooltip")
				icon.DoClick = function()
					if not table.HasValue(selectedModels[npcClass], model) then
						table.insert(selectedModels[npcClass], model)
						-- 直接更新当前tab的内容，而不是重新创建
						local selectedIcon = vgui.Create("OFNPCButton", scrollPanels[npcClass])
						selectedIcon:Dock(TOP)
						selectedIcon:DockMargin(0, 0, 0, 2)
						selectedIcon:SetTall(80 * OFGUI.ScreenScale)
						selectedIcon:SetModel(model)
						local npcName = "Unknown NPC"
						for _, v in pairs(list.Get("NPC")) do
							if v.Model == model then
								npcName = v.Name or v.Class or "Unknown NPC"
								break
							end
						end
						selectedIcon:SetTitle(npcName)
						selectedIcon:SetDescription(model)
						selectedIcon.DoClick = function()
							table.RemoveByValue(selectedModels[npcClass], model)
							selectedIcon:Remove()
						end
					end
				end

				-- 添加右键菜单
				icon.OpenMenu = function( pnl )
					if ( pnl:GetParent() && pnl:GetParent().ContentContainer ) then
						container = pnl:GetParent().ContentContainer
					end
					local menu = vgui.Create("OFMenu")
					menu:AddOption( "#spawnmenu.menu.copy", function() SetClipboardText( string.gsub( model, "\\", "/" ) ) end ):SetIcon( "icon16/page_copy.png" )
					menu:AddOption( "#spawnmenu.menu.spawn_with_toolgun", function()
						RunConsoleCommand( "gmod_tool", "creator" )
						RunConsoleCommand( "creator_type", "4" )
						RunConsoleCommand( "creator_name", model )
					end ):SetIcon( "icon16/brick_add.png" )
			
					menu:AddOption( "#spawnmenu.menu.rerender", function()
						if ( IsValid( pnl ) ) then pnl:RebuildSpawnIcon() end
					end ):SetIcon( "icon16/picture.png" )

					menu:AddOption( "#spawnmenu.menu.edit_icon", function()
			
						if ( !IsValid( pnl ) ) then return end
			
						local editor = vgui.Create( "IconEditor" )
						editor:SetIcon( pnl )
						editor:Refresh()
						editor:MakePopup()
						editor:Center()
			
					end ):SetIcon( "icon16/pencil.png" )
					menu:Open()
				end
			end
		end

		-- 首次加载时显示第一个tab的内容
		UpdateModelLayout("npc_citizen")

		-- Tab切换时更新右侧模型显示
		-- 原OnActiveTabChanged无法触发，改为监听Tab按钮的DoClick事件
		for i, sheet in ipairs(tabPanel.Items or {}) do
			if IsValid(sheet.Tab) then
				sheet.Tab.DoClick = function()
					tabPanel:SetActiveTab(sheet.Tab)
					-- 这里直接用npcClass
					local npcClass
					for k, v in pairs(scrollPanels) do
						if v == sheet.Panel then
							npcClass = k
							break
						end
					end
					if npcClass then
						UpdateModelLayout(npcClass)
					end
				end
			end
		end

		-- 创建模型替换标签
		OFNPCPCreateControl(pan1LeftPanel, "OFTextLabel", {
			SetText = ofTranslate("ui.model.model_replacement")
		})

		-- 添加勾选
		OFNPCPCreateCheckBoxPanel(pan1LeftPanel, "of_garrylord_model_replacement", "ui.model.enable_randommodel")
		OFNPCPCreateCheckBoxPanel(pan1LeftPanel, "of_garrylord_model_randomskin", "ui.model.enable_randomskin")
		OFNPCPCreateCheckBoxPanel(pan1LeftPanel, "of_garrylord_model_randombodygroup", "ui.model.enable_randombodygroup")

		OFNPCPCreateControl(pan1LeftPanel, "OFTextLabel", {
			SetText = ofTranslate("ui.model.model_pool")
		})

		-- 创建保存按钮
		local savebutton = vgui.Create("OFButton", pan1LeftPanel)
		savebutton:Dock(BOTTOM)
		savebutton:SetHeight(80 * OFGUI.ScreenScale)
		savebutton:SetText(ofTranslate("ui.model.save"))
		savebutton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)

		savebutton.DoClick = function()
			-- 检查玩家权限
			if not LocalPlayer():IsSuperAdmin() then
				notification.AddLegacy(ofTranslate("ui.model.save_fail"), NOTIFY_ERROR, 5)
				return
			end
			
			-- 检查目录是否存在，不存在则创建
			if not file.IsDir("of_npcp", "DATA") then
				file.CreateDir("of_npcp")
			end
			
			-- 将选中的模型表转换为JSON格式并发送到服务器
			net.Start("OFNPCP_NS_SaveModelSettings")
				net.WriteTable(selectedModels)
			net.SendToServer()
			
			-- 显示保存成功的提示
			notification.AddLegacy(ofTranslate("ui.model.save_success"), NOTIFY_GENERIC, 5)
		end
	end

	-- 调用函数设置模型系统
	SetupPan1(pan1LeftPanel, pan1RightPanel)

	local pan2 = vgui.Create("EditablePanel", sheet)
	sheet:AddSheet(ofTranslate("ui.tab.player2"), pan2, "ofnpcp/ai/icon16/player2.png")

	local player2Panel = vgui.Create("OFScrollPanel", pan2)
	player2Panel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	player2Panel:Dock(FILL)

	OFNPCPCreateCheckBoxPanel(player2Panel, "of_garrylord_player2_enable", ofTranslate("ui.player2.enable"))
end