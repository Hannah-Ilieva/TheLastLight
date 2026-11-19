-- LobbyController: the lobby screen and the wardrobe.
--   Title card (Lobby only): the game's name, the one-line rule and the controls.
--   Wardrobe (Lobby and Results): pick a look. Clicking only ASKS the server
--   (SelectSkin remote); the highlight follows the "Skin" attribute the server sets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local SkinConfig = require(ReplicatedStorage.Shared.SkinConfig)
local UIStyle = require(script.Parent.UIStyle)

local RULE_TEXT = "Gather mushrooms while the song plays. When it stops, run to a light."
local CONTROLS_TEXT = "E / tap: collect     Q / button: use power     Stay in the light during the Blackout"
local BUTTON_HEIGHT = 40
local SELECTED_STROKE = UIStyle.Warm

local LobbyController = {}

local player = Players.LocalPlayer

local function buildTitleCard(gui: ScreenGui): Frame
	local card = UIStyle.panel("TitleCard", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 100),
		Size = UDim2.fromOffset(560, 150),
	}, gui)
	UIStyle.label("Title", {
		Position = UDim2.fromOffset(20, 10),
		Size = UDim2.new(1, -40, 0, 56),
		Font = UIStyle.TitleFont,
		Text = "The Last Light",
		TextColor3 = UIStyle.Warm,
	}, card)
	UIStyle.label("Rule", {
		Position = UDim2.fromOffset(20, 72),
		Size = UDim2.new(1, -40, 0, 26),
		Font = UIStyle.BodyFont,
		Text = RULE_TEXT,
	}, card)
	UIStyle.label("Controls", {
		Position = UDim2.fromOffset(20, 108),
		Size = UDim2.new(1, -40, 0, 18),
		Font = UIStyle.BodyFont,
		Text = CONTROLS_TEXT,
		TextColor3 = UIStyle.Muted,
	}, card)
	return card
end

local function buildWardrobe(gui: ScreenGui, selectSkin: RemoteEvent): Frame
	local count = #SkinConfig.Order
	local panel = UIStyle.panel("Wardrobe", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -16),
		Size = UDim2.fromOffset(240, 66 + count * (BUTTON_HEIGHT + 6) + 22),
	}, gui)
	UIStyle.label("Header", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 20),
		Text = "WARDROBE",
		TextColor3 = UIStyle.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, panel)
	local description = UIStyle.label("Description", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -10),
		Size = UDim2.new(1, -28, 0, 36),
		Font = UIStyle.BodyFont,
		TextColor3 = UIStyle.Muted,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, panel)

	local buttons = {}
	for i, skinName in SkinConfig.Order do
		local skin = SkinConfig.Skins[skinName]
		local button = UIStyle.button(skinName, {
			Position = UDim2.fromOffset(12, 36 + (i - 1) * (BUTTON_HEIGHT + 6)),
			Size = UDim2.new(1, -24, 0, BUTTON_HEIGHT),
			Text = skin.DisplayName,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, panel)
		local swatch = Instance.new("Frame") -- a colour dot showing the look's main colour
		swatch.Name = "Swatch"
		swatch.AnchorPoint = Vector2.new(0, 0.5)
		swatch.Position = UDim2.new(0, -30, 0.5, 0)
		swatch.Size = UDim2.fromOffset(20, 20)
		swatch.BackgroundColor3 = skin.Swatch
		swatch.BorderSizePixel = 0
		Instance.new("UICorner", swatch).CornerRadius = UDim.new(1, 0)
		swatch.Parent = button
		button.Activated:Connect(function()
			selectSkin:FireServer(skinName)
		end)
		buttons[skinName] = button
	end

	-- Highlights the look the server says we are wearing.
	local function refresh()
		local current = player:GetAttribute("Skin") or "Default"
		for skinName, button in buttons do
			local stroke = button:FindFirstChildOfClass("UIStroke")
			stroke.Color = skinName == current and SELECTED_STROKE or UIStyle.Stroke
			stroke.Transparency = skinName == current and 0 or 0.4
		end
		local skin = SkinConfig.Skins[current]
		description.Text = skin and skin.Description or ""
	end
	player:GetAttributeChangedSignal("Skin"):Connect(refresh)
	refresh()
	return panel
end

function LobbyController.start()
	local selectSkin = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SelectSkin")
	local gui = Instance.new("ScreenGui")
	gui.Name = "LobbyScreen"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local titleCard = buildTitleCard(gui)
	local wardrobe = buildWardrobe(gui, selectSkin)

	local function onPhase()
		local phase = ReplicatedStorage:GetAttribute("Phase")
		titleCard.Visible = phase == "Lobby"
		wardrobe.Visible = GameConfig.WardrobePhases[phase] == true
	end
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(onPhase)
	onPhase()
end

return LobbyController
