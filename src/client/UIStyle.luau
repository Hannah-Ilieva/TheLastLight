-- UIStyle: the shared look of every on-screen element (fonts, colours) plus small helpers
-- to create labels and panels, so all the HUD pieces match.

local UIStyle = {
	TitleFont = Enum.Font.Fondamento, -- old-folklore style, for big headings
	BodyFont = Enum.Font.GothamMedium,
	BoldFont = Enum.Font.GothamBold,

	Text = Color3.fromRGB(235, 240, 230),
	Muted = Color3.fromRGB(165, 185, 180),
	Warm = Color3.fromRGB(255, 200, 110), -- warnings and safe light
	Panel = Color3.fromRGB(8, 14, 16),
	PanelTransparency = 0.3,
	Stroke = Color3.fromRGB(120, 160, 150),
}

-- Applies a table of properties to an instance and parents it.
local function apply(instance: Instance, props, parent: Instance)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- A transparent, auto-scaling text label with a dark outline (readable on any background).
function UIStyle.label(name: string, props, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = UIStyle.BoldFont
	label.TextColor3 = UIStyle.Text
	label.TextStrokeTransparency = 0.5
	label.TextScaled = true
	return apply(label, props, parent)
end

-- A dark, rounded, see-through panel with a thin outline. `strokeColor` is optional.
function UIStyle.panel(name: string, props, parent: Instance, strokeColor: Color3?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = UIStyle.Panel
	frame.BackgroundTransparency = UIStyle.PanelTransparency
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor or UIStyle.Stroke
	stroke.Transparency = 0.4
	stroke.Thickness = 1.5
	stroke.Parent = frame
	return apply(frame, props, parent)
end

-- A clickable button with the same rounded, outlined look as the panels.
function UIStyle.button(name: string, props, parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = UIStyle.Panel
	button.BackgroundTransparency = UIStyle.PanelTransparency
	button.BorderSizePixel = 0
	button.Font = UIStyle.BoldFont
	button.TextColor3 = UIStyle.Text
	button.TextScaled = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = UIStyle.Stroke
	stroke.Transparency = 0.4
	stroke.Thickness = 1.5
	stroke.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 40) -- room for a colour swatch on the left
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = button
	return apply(button, props, parent)
end

return UIStyle
