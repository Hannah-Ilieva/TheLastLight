-- AbilityController: shows the power mushroom you carry (upper right, under your points)
-- and lets you use it: Q on keyboard, Y on a controller, or the on-screen button on
-- mobile. Pressing only SENDS A REQUEST; the server decides whether it works.
-- While a speed boost is active, the camera widens a little so the speed is felt.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MushroomConfig = require(ReplicatedStorage.Shared.MushroomConfig)
local UIStyle = require(script.Parent.UIStyle)

local ACTION_NAME = "UseAbility"
local KEYS = { Enum.KeyCode.Q, Enum.KeyCode.ButtonY }
local HINT = {
	Speed = "Press Q to use",
	Shield = "Blocks one catch",
}
local NORMAL_FOV = 70
local BOOST_FOV = 82

local AbilityController = {}

local player = Players.LocalPlayer

function AbilityController.start()
	local useAbility = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseAbility")

	local gui = Instance.new("ScreenGui")
	gui.Name = "AbilityHUD"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local slot = UIStyle.panel("PowerSlot", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 68),
		Size = UDim2.fromOffset(200, 50),
		Visible = false,
	}, gui)
	local stroke = slot:FindFirstChildOfClass("UIStroke")
	local orb = Instance.new("Frame") -- a glowing dot in the mushroom's colour
	orb.Name = "Orb"
	orb.Position = UDim2.fromOffset(12, 13)
	orb.Size = UDim2.fromOffset(24, 24)
	orb.BorderSizePixel = 0
	Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
	orb.Parent = slot
	local nameLabel = UIStyle.label("PowerName", {
		Position = UDim2.fromOffset(46, 7),
		Size = UDim2.new(1, -56, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, slot)
	local hintLabel = UIStyle.label("Hint", {
		Position = UDim2.fromOffset(46, 28),
		Size = UDim2.new(1, -56, 0, 14),
		Font = UIStyle.BodyFont,
		TextColor3 = UIStyle.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, slot)

	local function onAction(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			useAbility:FireServer()
		end
		return Enum.ContextActionResult.Sink
	end

	-- Shows the carried power, and binds the key only when there is something to use.
	local function refreshPower()
		local config = MushroomConfig[player:GetAttribute("Power")]
		ContextActionService:UnbindAction(ACTION_NAME)
		slot.Visible = config ~= nil
		if not config then
			return
		end
		nameLabel.Text = config.DisplayName
		nameLabel.TextColor3 = config.GlowColor
		orb.BackgroundColor3 = config.GlowColor
		stroke.Color = config.GlowColor
		hintLabel.Text = HINT[config.Power] or ""
		if config.Power == "Speed" then
			ContextActionService:BindAction(ACTION_NAME, onAction, true, table.unpack(KEYS))
			ContextActionService:SetTitle(ACTION_NAME, "Speed")
			ContextActionService:SetPosition(ACTION_NAME, UDim2.new(1, -170, 1, -150))
		end
	end

	-- Widens the camera while the server says we are boosted.
	local function refreshBoost()
		local boosted = player:GetAttribute("BoostEndsAt") ~= nil
		local camera = workspace.CurrentCamera
		local info = TweenInfo.new(boosted and 0.25 or 0.8, Enum.EasingStyle.Sine)
		TweenService:Create(camera, info, { FieldOfView = boosted and BOOST_FOV or NORMAL_FOV }):Play()
	end

	player:GetAttributeChangedSignal("Power"):Connect(refreshPower)
	player:GetAttributeChangedSignal("BoostEndsAt"):Connect(refreshBoost)
	refreshPower()
end

return AbilityController
