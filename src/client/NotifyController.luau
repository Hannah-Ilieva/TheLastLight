-- NotifyController: shows the short messages the server sends through the Notify remote
-- (mushroom pickups, powers, shield breaking, "hands full"). A new message replaces
-- the old one. Other client scripts can listen to NotifyController.shown, e.g. to play
-- a sound for each style.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIStyle = require(script.Parent.UIStyle)

local SHOW_SECONDS = 3
local FADE_SECONDS = 0.25
local STYLE_COLOR = {
	pickup = Color3.fromRGB(235, 225, 200),
	rare = Color3.fromRGB(255, 215, 140),
	power = Color3.fromRGB(255, 140, 70),
	shield = Color3.fromRGB(190, 140, 255),
	info = Color3.fromRGB(165, 185, 180),
}

local NotifyController = {}
local shownEvent = Instance.new("BindableEvent")
NotifyController.shown = shownEvent.Event -- fires (style, title, detail)

function NotifyController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Notifications"
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local panel = UIStyle.panel("Toast", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -90),
		Size = UDim2.fromOffset(360, 64),
		Visible = false,
	}, gui)
	local stroke = panel:FindFirstChildOfClass("UIStroke")
	local title = UIStyle.label("Title", {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 26),
		Font = UIStyle.TitleFont,
	}, panel)
	local detail = UIStyle.label("Detail", {
		Position = UDim2.fromOffset(14, 36),
		Size = UDim2.new(1, -28, 0, 18),
		Font = UIStyle.BodyFont,
		TextColor3 = UIStyle.Muted,
	}, panel)

	local showId = 0 -- lets an old "hide" timer know a newer message replaced it
	local function show(style: string, titleText: string, detailText: string?)
		showId += 1
		local myId = showId
		local color = STYLE_COLOR[style] or UIStyle.Text
		title.Text = titleText
		title.TextColor3 = color
		stroke.Color = color
		detail.Text = detailText or ""
		panel.Visible = true
		panel.Position = UDim2.new(0.5, 0, 1, -70)
		TweenService:Create(panel, TweenInfo.new(FADE_SECONDS, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 1, -90) }):Play()
		shownEvent:Fire(style, titleText, detailText)

		task.delay(SHOW_SECONDS, function()
			if showId == myId then
				panel.Visible = false
			end
		end)
	end

	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify").OnClientEvent:Connect(show)
end

return NotifyController
