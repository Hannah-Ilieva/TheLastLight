-- PowerService: the power mushrooms.
--   Ember Morel  ("Speed")  - the player presses the ability key for a short speed boost.
--   Guardian Cap ("Shield") - blocks the next catch automatically, then is used up.
-- The power a player carries is the "Power" attribute on their Player (a MushroomConfig
-- key, or nil). Clients can only ASK to use it through the UseAbility remote; the server
-- checks that they really have it, are still playing, and that it's the right phase.
-- While boosted, "BoostEndsAt" holds the server time the boost ends (for client effects).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MushroomConfig = require(ReplicatedStorage.Shared.MushroomConfig)
local log = require(ReplicatedStorage.Shared.Log)
local Remotes = require(script.Parent.Remotes)
local PlayerState = require(script.Parent.PlayerState)

local CONFIG = GameConfig.Powers

local PowerService = {}

-- Returns the power type ("Speed"/"Shield") of what the player carries, or nil.
local function heldPower(player: Player): string?
	local config = MushroomConfig[player:GetAttribute("Power")]
	return config and config.Power
end

function PowerService.canCarry(player: Player): boolean
	return player:GetAttribute("Power") == nil
end

function PowerService.give(player: Player, kind: string)
	player:SetAttribute("Power", kind)
end

-- Removes any carried power and active boost (start of a round, or when caught).
function PowerService.clear(player: Player)
	player:SetAttribute("Power", nil)
	player:SetAttribute("BoostEndsAt", nil)
end

local function useSpeed(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local endsAt = workspace:GetServerTimeNow() + CONFIG.SpeedBoostSeconds
	humanoid.WalkSpeed = CONFIG.SpeedBoostWalkSpeed
	player:SetAttribute("BoostEndsAt", endsAt)
	task.delay(CONFIG.SpeedBoostSeconds, function()
		humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
		if player:GetAttribute("BoostEndsAt") == endsAt then
			player:SetAttribute("BoostEndsAt", nil)
		end
	end)
end

local function onUseAbility(player: Player)
	local phase = ReplicatedStorage:GetAttribute("Phase")
	if heldPower(player) ~= "Speed" or not CONFIG.UsePhases[phase] or not PlayerState.isActive(player) then
		return -- not allowed right now: ignore the request
	end
	player:SetAttribute("Power", nil)
	useSpeed(player)
	Remotes.Notify:FireClient(player, "power", "Ember Morel!", "Run!")
	log(player.Name, "used a speed boost")
end

-- Called by the monster when it reaches a player. Returns true if a Guardian Cap
-- blocked the catch (and uses it up).
function PowerService.absorbCatch(player: Player): boolean
	if heldPower(player) ~= "Shield" then
		return false
	end
	player:SetAttribute("Power", nil)
	Remotes.Notify:FireClient(player, "shield", "Your Guardian Cap shattered!", "Get to the light!")
	log(player.Name, "was saved by a Guardian Cap")
	return true
end

function PowerService.start()
	Remotes.UseAbility.OnServerEvent:Connect(onUseAbility)
end

return PowerService
