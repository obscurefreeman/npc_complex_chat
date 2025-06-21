local function OFNPCPCreateControl(parent, controlType, options)
    local control = vgui.Create(controlType, parent)
    control:Dock(TOP)
    control:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)
    control:SetTall(32 * OFGUI.ScreenScale)
    if options then
        for k, v in pairs(options) do
            control[k](control, v)
        end
    end
    return control
end

local function OFNPCPCreateCheckBoxPanel(parent, conVar, labelText)
	local checkPanel = vgui.Create("EditablePanel", parent)
	checkPanel:Dock(TOP)
	checkPanel:SetTall(21 * OFGUI.ScreenScale)
	checkPanel:DockMargin(4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale, 4 * OFGUI.ScreenScale)

	local checkBox = vgui.Create("OFCheckBox", checkPanel)
	checkBox:Dock(LEFT)
	checkBox:SetSize(21 * OFGUI.ScreenScale, 21 * OFGUI.ScreenScale)
	checkBox:DockMargin(0, 0, 8 * OFGUI.ScreenScale, 0)
	checkBox:SetConVar(conVar)

	local checkLabel = vgui.Create("OFTextLabel", checkPanel)
	checkLabel:SetFont("ofgui_small")
	checkLabel:Dock(FILL)
	checkLabel:SetText(ofTranslate(labelText))

	return checkPanel
end