-- SpectateController: while you are caught, the camera follows another player who is
-- still in the round. When the next round starts, your new character takes the camera
-- back automatically (Roblox's default camera does that on spawn).

local Players = game:GetService("Players")

local CHECK_INTERVAL = 1 -- seconds between "is the person I'm watching still playing?" checks

local SpectateController = {}

local player = Players.LocalPlayer

-- Returns the Humanoid of someone still playing (not caught, alive), or nil.
local function findSomeoneToWatch(): Humanoid?
	for _, other in Players:GetPlayers() do
		local humanoid = other.Character and other.Character:FindFirstChildOfClass("Humanoid")
		if other ~= player and not other:GetAttribute("Caught") and humanoid and humanoid.Health > 0 then
			return humanoid
		end
	end
	return nil
end

local function spectate()
	local camera = workspace.CurrentCamera
	while player:GetAttribute("Caught") do
		local subject = camera.CameraSubject
		local watching = subject and subject:IsA("Humanoid") and subject.Parent ~= player.Character and subject.Health > 0
		if not watching then
			camera.CameraSubject = findSomeoneToWatch() or camera.CameraSubject
		end
		task.wait(CHECK_INTERVAL)
	end
end

function SpectateController.start()
	player:GetAttributeChangedSignal("Caught"):Connect(function()
		if player:GetAttribute("Caught") then
			task.spawn(spectate)
		end
	end)
end

return SpectateController
