-- EffectsController: small visual touches that run only on this computer.
-- Right now: mushroom lights "breathe" (slowly brighten and dim), each at its own pace,
-- and Ember Morels pulse faster and stronger, like a warm ember.

local TweenService = game:GetService("TweenService")

local PULSE = {
	EmberMorel = { Seconds = 0.7, Strength = 1.8 },
	Default = { Seconds = 1.8, Strength = 1.35 },
}

local EffectsController = {}

local rng = Random.new()

local function pulse(light: PointLight, kind: string?)
	local style = PULSE[kind] or PULSE.Default
	local info = TweenInfo.new(style.Seconds * rng:NextNumber(0.85, 1.15), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 1))
	TweenService:Create(light, info, { Brightness = light.Brightness * style.Strength }):Play()
end

local function onMushroomAdded(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local kind = model:GetAttribute("MushroomType")
	for _, item in model:GetDescendants() do
		if item:IsA("PointLight") then
			pulse(item, kind)
		end
	end
end

-- The server replaces the Mushrooms folder every round, so watch for it each time.
local function watchFolder(folder: Instance)
	folder.ChildAdded:Connect(function(model)
		task.wait() -- let the model's parts finish loading
		onMushroomAdded(model)
	end)
	for _, model in folder:GetChildren() do
		onMushroomAdded(model)
	end
end

function EffectsController.start()
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Mushrooms" then
			watchFolder(child)
		end
	end)
	local current = workspace:FindFirstChild("Mushrooms")
	if current then
		watchFolder(current)
	end
end

return EffectsController
