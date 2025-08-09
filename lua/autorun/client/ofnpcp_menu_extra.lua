-- CreateClientConVar("of_garrylord_player2_enable", "0", true, true, "", 0, 1)

function OFNPCP_SetUpExtraFeatureMenu(pan1)
	local pan1HorizontalDivider = vgui.Create("DHorizontalDivider", pan1)
	pan1HorizontalDivider:Dock(FILL)
	pan1HorizontalDivider:DockMargin(6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale)
	pan1HorizontalDivider:SetLeftWidth(ScrW() / 4)

	local pan1LeftPanel = vgui.Create("EditablePanel")
	pan1HorizontalDivider:SetLeft(pan1LeftPanel)

	local pan1RightPanel = vgui.Create("EditablePanel")
	pan1HorizontalDivider:SetRight(pan1RightPanel)


	local function SetupPan1(pan1LeftPanel, pan1RightPanel)
		-- 本地模型表，按分类存储
		local selectedModels = {
			npc_citizen = {},
			npc_combine_s = {},
			npc_metropolice = {}
		}

		local blockedBodygroups = {}

		-- 尝试加载已保存的模型数据
		if file.Exists("of_npcp/model_settings.txt", "DATA") then
			local savedData = file.Read("of_npcp/model_settings.txt", "DATA")
			if savedData then
				local loadedData = util.JSONToTable(savedData)
				if loadedData then
					selectedModels = loadedData.modelsettings or selectedModels
					blockedBodygroups = loadedData.bodygroupsettings or blockedBodygroups
				end
			end
		end

		-- 创建Tab面板
		local tabPanel = vgui.Create("OFPropertySheet", pan1LeftPanel)
		tabPanel:Dock(FILL)
		tabPanel:DockMargin(0, 8 * OFGUI.ScreenScale, 0, 0) -- 增加顶部边距

		local pan1TopPanel = vgui.Create("EditablePanel", pan1RightPanel)
		pan1TopPanel:Dock(TOP)
		pan1TopPanel:SetTall(300 * OFGUI.ScreenScale)  -- 设置顶部面板高度为屏幕高度的30%

		local pan1ModelPanel = vgui.Create("DAdjustableModelPanel", pan1TopPanel)
		pan1ModelPanel:SetFOV(80)
		pan1ModelPanel:SetAnimated( true )
		pan1ModelPanel:SetAnimationEnabled(true)
		pan1ModelPanel:SetAmbientLight( Color( 128, 128, 128, 128 ) )
		pan1ModelPanel:SetDirectionalLight(BOX_TOP, Color( 200, 200, 200, 255 ))
		pan1ModelPanel:SetDirectionalLight(BOX_FRONT, Color( 255, 255, 255, 255 ))
		pan1ModelPanel:SetDirectionalLight(BOX_BOTTOM, Color(0, 0, 0))
		pan1ModelPanel:SetDirectionalLight(BOX_BACK, Color( 200, 200, 200, 255 ))
		pan1ModelPanel:SetDirectionalLight(BOX_LEFT, Color( 80, 160, 255, 255 ))
		pan1ModelPanel:SetDirectionalLight(BOX_RIGHT, Color( 255, 160, 80, 255 ))

		pan1ModelPanel:SetLookAng(Angle(0, 180, 0))
		pan1ModelPanel:SetCamPos(Vector(50, 0, 35))

		pan1ModelPanel:Dock(LEFT)
		pan1ModelPanel:SetWidth(ScrW() / 6)

		function pan1ModelPanel:LayoutEntity( ent )
			if IsValid(ent) then
				local eyeAngles = (pan1ModelPanel:GetCamPos() - ent:GetPos()):Angle()
				ent:SetEyeTarget(pan1ModelPanel:GetCamPos())
				ent:FrameAdvance(FrameTime())
			end
		end
	
		local pan1ListPanel = vgui.Create("OFListView", pan1TopPanel)
		pan1ListPanel:AddColumn( "ID" )
		pan1ListPanel:AddColumn( ofTranslate("ui.model.bodygroup") )
		pan1ListPanel:AddColumn( ofTranslate("ui.model.current_display") )
		pan1ListPanel:AddColumn( ofTranslate("ui.model.block") )
		pan1ListPanel:Dock(FILL)
		pan1ListPanel:DockMargin(6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale, 6 * OFGUI.ScreenScale)

		-- 添加点击事件处理
		pan1ListPanel.OnRowSelected = function(_, _, line)
			local bodyGroupName = line:GetColumnText(2)
			local entity = pan1ModelPanel.Entity
			if IsValid(entity) then
				local bodyGroups = entity:GetBodyGroups()
				for _, bodyGroup in ipairs(bodyGroups) do
					if bodyGroup.name == bodyGroupName then
						local current = entity:GetBodygroup(bodyGroup.id)
						local num = bodyGroup.num
						local nextBodyGroup = (current + 1) % num
						entity:SetBodygroup(bodyGroup.id, nextBodyGroup)
						-- 更新当前显示的数字
						line:SetColumnText(3, tostring(nextBodyGroup))
						break
					end
				end
			end
		end

		-- 添加右键菜单
		pan1ListPanel.OnRowRightClick = function(_, _, line)
			local bodyGroupID = line:GetColumnText(1)
			local model = pan1ModelPanel.Entity:GetModel()
			
			-- 初始化模型的身体组屏蔽记录
			if not blockedBodygroups[model] then
				blockedBodygroups[model] = {}
			end
			
			-- 检查当前是否已经设置
			if line:GetColumnText(4) == ofTranslate("ui.model.block_last_one") then
				-- 如果已经设置，则清除
				line:SetColumnText(4, "")
				blockedBodygroups[model][bodyGroupID] = nil
			else
				-- 如果没有设置，则添加
				line:SetColumnText(4, ofTranslate("ui.model.block_last_one"))
				blockedBodygroups[model][bodyGroupID] = true
			end
		end

		-- 初始化时设置当前显示的数字
		local function UpdateBodyGroupList(entity)
			pan1ListPanel:Clear()
			local bodyGroups = entity:GetBodyGroups()
			for _, bodyGroup in ipairs(bodyGroups) do
				local current = entity:GetBodygroup(bodyGroup.id)
				local line = pan1ListPanel:AddLine(bodyGroup.id, bodyGroup.name, tostring(current))
				line:SetTooltip(ofTranslate("ui.model.tooltip_bodygroup"))
				
				-- 检查当前身体组是否被屏蔽
				local model = entity:GetModel()
				if blockedBodygroups[model] and blockedBodygroups[model][bodyGroup.id] then
					line:SetColumnText(4, ofTranslate("ui.model.block_last_one"))
				end
			end
		end

		local pan1IconPanel = vgui.Create("OFScrollPanel", pan1RightPanel)
		pan1IconPanel:Dock(FILL)

		-- 创建右侧模型布局
		local modelLayout = vgui.Create("OFIconLayout", pan1IconPanel)
		modelLayout:Dock(TOP)
		modelLayout:SetSpaceX(8 * OFGUI.ScreenScale)
		modelLayout:SetSpaceY(8 * OFGUI.ScreenScale)
		modelLayout:SetStretchWidth(true)

		-- 创建每个分类的滚动面板
		local scrollPanels = {}
		-- 新增函数：创建并设置 OFNPCButton
		local function CreateNPCButton(parent, model, npcClass, selectedModels)
			local selectedIcon = vgui.Create("OFNPCButton", parent)
			selectedIcon:Dock(TOP)
			selectedIcon:DockMargin(0, 0, 0, 2)
			selectedIcon:SetTall(80 * OFGUI.ScreenScale)
			selectedIcon:SetModel(model)
			local npcName = "Unknown NPC"
			-- 特殊处理该死的国民护卫队，这玩意正常情况没设置模型
			if model == "models/police.mdl" then
				npcName = "#npc_metropolice"
			else
				for _, v in pairs(list.Get("NPC")) do
					if v.Model == model then
						npcName = v.Name or v.Class or "Unknown NPC"
						break
					end
				end
			end
			selectedIcon:SetTitle(npcName)
			selectedIcon:SetDescription(model)
			selectedIcon.DoClick = function()
				table.RemoveByValue(selectedModels[npcClass], model)
				selectedIcon:Remove()
			end
			selectedIcon.DoRightClick = function( pnl )
				local menu = vgui.Create("OFMenu")

				menu:AddOption( ofTranslate("ui.model.remove"), function()
					if table.HasValue(selectedModels[npcClass], model) then
						table.RemoveByValue(selectedModels[npcClass], model)
						selectedIcon:Remove()
					end
				end )
				menu:AddOption( ofTranslate("ui.model.copy"), function() SetClipboardText( string.gsub( model, "\\", "/" ) ) end )
				menu:AddOption( ofTranslate("ui.model.spawn_with_toolgun"), function()
					RunConsoleCommand( "gmod_tool", "creator" )
					RunConsoleCommand( "creator_type", "4" )
					RunConsoleCommand( "creator_name", model )
				end )
		
				menu:AddOption( ofTranslate("ui.model.rerender"), function()
					if ( IsValid( pnl ) ) then pnl:RebuildSpawnIcon() end
				end )

				menu:AddOption( ofTranslate("ui.model.bodygroup_setting"), function()
					-- 更新模型面板中的模型
					pan1ModelPanel:SetModel(model)

					-- 清空并更新身体组列表
					UpdateBodyGroupList(pan1ModelPanel.Entity)
				end )
				menu:Open()
			end
			return selectedIcon
		end

		-- 修改后的 UpdateScrollPanel 函数
		local function UpdateScrollPanel(npcClass)
			local scrollPanel = scrollPanels[npcClass]
			if IsValid(scrollPanel) then
				scrollPanel:Clear()
				local models = selectedModels[npcClass] or {}
				for _, model in ipairs(models) do
					CreateNPCButton(scrollPanel, model, npcClass, selectedModels)
				end
			end
		end

		local function CreateNPCTab(npcClass, name)
			local scrollPanel = vgui.Create("OFScrollPanel")
			scrollPanels[npcClass] = scrollPanel
			
			-- 填充已选模型
			UpdateScrollPanel(npcClass)
			
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
				-- 特殊处理该死的国民护卫队，这玩意正常情况没设置模型
				if v.Class == "npc_metropolice" and v.Name == "#npc_metropolice" and not v.Model then
					v.Model = "models/police.mdl"
				end
				
				if v.Class == npcClass and not table.HasValue(models, v.Model) then
					table.insert(models, v.Model)
				end
			end

			-- 如果有模型，就显示第一个

			if #models > 0 then
				local firstModel = models[1]
				pan1ModelPanel:SetModel(firstModel)
				UpdateBodyGroupList(pan1ModelPanel.Entity)
			end
			
			for _, model in ipairs(models) do
				local icon = vgui.Create("SpawnIcon", modelLayout)
				icon:SetModel(model)
				icon:SetSize(96 * OFGUI.ScreenScale, 96 * OFGUI.ScreenScale)
				icon:SetTooltipPanelOverride("OFTooltip")
				icon:SetTooltip(ofTranslate("ui.model.tooltip_add") .. model)
				
				-- 添加勾选标记
				icon.PaintOver = function(self, w, h)
					if table.HasValue(selectedModels[npcClass], model) then
						surface.SetDrawColor(Color(0, 255, 0, 255))
						surface.SetMaterial(Material("icon16/tick.png"))
						surface.DrawTexturedRect(w - 16, 0, 16, 16)
					end
				end

				icon.DoClick = function()
					-- 检查模型是否已经在模型池中
					if table.HasValue(selectedModels[npcClass], model) then
						-- 如果已经在模型池中，则移除
						table.RemoveByValue(selectedModels[npcClass], model)
						-- 更新左侧的模型池
						UpdateScrollPanel(npcClass)
					else
						-- 如果不在模型池中，则添加
						table.insert(selectedModels[npcClass], model)
						-- 直接更新当前tab的内容，而不是重新创建
						CreateNPCButton(scrollPanels[npcClass], model, npcClass, selectedModels)
					end
				end

				-- 添加右键菜单
				icon.OpenMenu = function( pnl )
					local menu = vgui.Create("OFMenu")
					menu:AddOption( ofTranslate("ui.model.add"), function()
						if not table.HasValue(selectedModels[npcClass], model) then
							table.insert(selectedModels[npcClass], model)
							CreateNPCButton(scrollPanels[npcClass], model, npcClass, selectedModels)
						end
					end )

					menu:AddOption( ofTranslate("ui.model.remove"), function()
						if table.HasValue(selectedModels[npcClass], model) then
							table.RemoveByValue(selectedModels[npcClass], model)
							UpdateScrollPanel(npcClass)
						end
					end )
					menu:AddOption( ofTranslate("ui.model.copy"), function() SetClipboardText( string.gsub( model, "\\", "/" ) ) end )
					menu:AddOption( ofTranslate("ui.model.spawn_with_toolgun"), function()
						RunConsoleCommand( "gmod_tool", "creator" )
						RunConsoleCommand( "creator_type", "4" )
						RunConsoleCommand( "creator_name", model )
					end )
			
					menu:AddOption( ofTranslate("ui.model.rerender"), function()
						if ( IsValid( pnl ) ) then pnl:RebuildSpawnIcon() end
					end )

					menu:AddOption( ofTranslate("ui.model.edit_icon"), function()
			
						if ( !IsValid( pnl ) ) then return end
			
						local editor = vgui.Create( "IconEditor" )
						editor:SetIcon( pnl )
						editor:Refresh()
						editor:MakePopup()
						editor:Center()
			
					end )

					menu:AddOption( ofTranslate("ui.model.bodygroup_setting"), function()
						-- 更新模型面板中的模型
						pan1ModelPanel:SetModel(model)

						-- 清空并更新身体组列表
						UpdateBodyGroupList(pan1ModelPanel.Entity)
					end )
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
		OFNPCPCreateCheckBoxPanel(pan1LeftPanel, "of_garrylord_model_sandboxlimitation", "ui.model.enable_sandboxlimitation")

		OFNPCPCreateControl(pan1LeftPanel, "OFTextLabel", {
			SetText = ofTranslate("ui.model.model_pool")
		})

		-- 创建保存按钮
		local savebutton = vgui.Create("OFButton", pan1LeftPanel)
		savebutton:Dock(BOTTOM)
		savebutton:SetTall(32 * OFGUI.ScreenScale)
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
			
			-- 将选中的模型表和被屏蔽的身体组合并为一个表
			local combinedData = {
				modelsettings = selectedModels,
				bodygroupsettings = blockedBodygroups
			}

			-- 将合并后的表转换为JSON格式并发送到服务器
			net.Start("OFNPCP_NS_SaveModelSettings")
				net.WriteTable(combinedData)
			net.SendToServer()
			
			-- 显示保存成功的提示
			notification.AddLegacy(ofTranslate("ui.model.save_success"), NOTIFY_GENERIC, 5)
		end

		-- 创建导出按钮
		local exportButton = vgui.Create("OFButton", pan1LeftPanel)
		exportButton:Dock(BOTTOM)
		exportButton:SetHeight(40 * OFGUI.ScreenScale)
		exportButton:SetText(ofTranslate("ui.model.export"))
		exportButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)

		exportButton.DoClick = function()

			-- 将选中的模型表和被屏蔽的身体组合并为一个表
			local combinedData = {
				modelsettings = selectedModels,
				bodygroupsettings = blockedBodygroups
			}

			-- 将合并后的表转换为JSON格式并复制到剪贴板
			local jsonData = util.TableToJSON(combinedData, true)
			SetClipboardText(jsonData)
			notification.AddLegacy(ofTranslate("ui.model.export_success"), NOTIFY_GENERIC, 5)
		end

		-- 创建导入按钮
		local importButton = vgui.Create("OFButton", pan1LeftPanel)
		importButton:Dock(BOTTOM)
		importButton:SetHeight(40 * OFGUI.ScreenScale)
		importButton:SetText(ofTranslate("ui.model.import"))
		importButton:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)

		-- 创建分享码输入框
		local importEntry = vgui.Create("OFTextEntry", pan1LeftPanel)
		importEntry:Dock(BOTTOM)
		importEntry:SetHeight(40 * OFGUI.ScreenScale)
		importEntry:SetPlaceholderText(ofTranslate("ui.model.import_entry"))
		importEntry:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)

		importButton.DoClick = function()
			-- 获取输入框内容
			local shareCode = importEntry:GetValue()
			
			-- 检查分享码是否为空
			if shareCode == "" then
				notification.AddLegacy(ofTranslate("ui.model.import_fail"), NOTIFY_ERROR, 5)
				return
			end
			
			-- 尝试解析JSON
			local success, data = pcall(util.JSONToTable, shareCode)
			if not success or not data then
				notification.AddLegacy(ofTranslate("ui.model.import_fail"), NOTIFY_ERROR, 5)
				return
			end
			
			-- 更新选中的模型和身体组
			selectedModels = data.modelsettings or {}
			blockedBodygroups = data.bodygroupsettings or {}
			
			-- 显示导入成功提示
			notification.AddLegacy(ofTranslate("ui.model.import_success"), NOTIFY_GENERIC, 5)
			
			-- 更新所有分类的滚动面板
			for npcClass, _ in pairs(scrollPanels) do
				UpdateScrollPanel(npcClass)
			end
		end
	end

	-- 调用函数设置模型系统
	SetupPan1(pan1LeftPanel, pan1RightPanel)

	-- local pan2 = vgui.Create("EditablePanel", sheet)
	-- sheet:AddSheet(ofTranslate("ui.tab.player2"), pan2, "ofnpcp/ai/icon16/player2.png")

	-- local player2Panel = vgui.Create("OFScrollPanel", pan2)
	-- player2Panel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
	-- player2Panel:Dock(FILL)

	-- OFNPCPCreateCheckBoxPanel(player2Panel, "of_garrylord_player2_enable", ofTranslate("ui.player2.enable"))
end