-- PlayerState: tracks who is still in the round and who was caught.
-- "Caught" is an attribute on each Player: true means spectating until the next round.
-- Main turns off Players.CharacterAutoLoads, so characters spawn only when this
-- script says so. That is what keeps caught players out until the round ends.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local log = require(ReplicatedStorage.Shared.Log)

local RESPAWN_DELAY = 3 -- seconds before someone who died another way (e.g. fell off the map) respawns
local REMOVE_BODY_DELAY = 2 -- seconds before a caught player's body disappears

local PlayerState = {}

-- True if the player is in the round with a living character (the monster can chase them).
function PlayerState.isActive(player: Player): boolean
	if player:GetAttribute("Caught") then
		return false
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- True if at least one player has not been caught (used to end a round early).
function PlayerState.anyoneLeft(): boolean
	for _, player in Players:GetPlayers() do
		if not player:GetAttribute("Caught") then
			return true
		end
	end
	return false
end

function PlayerState.catch(player: Player)
	if player:GetAttribute("Caught") then
		return
	end
	player:SetAttribute("Caught", true) -- set first, so the Died handler below won't respawn them
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
	task.delay(REMOVE_BODY_DELAY, function()
		if character and character.Parent then
			character:Destroy()
		end
	end)
	log(player.Name, "was caught")
end

-- Respawns players who die for any reason other than being caught.
local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		if player:GetAttribute("Caught") then
			return
		end
		task.delay(RESPAWN_DELAY, function()
			if player.Parent and player.Character == character then
				player:LoadCharacter()
			end
		end)
	end)
end

function PlayerState.setup(player: Player)
	player:SetAttribute("Caught", false)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player:LoadCharacter()
end

-- Start of a round: nobody is caught, and everyone respawns at the trailhead.
function PlayerState.resetRound()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Caught", false)
		player:LoadCharacter()
	end
end

return PlayerState
