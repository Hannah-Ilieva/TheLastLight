-- Score: keeps each player's round points and round stats.
-- Points and status live in a "leaderstats" folder, which Roblox shows in the player
-- list (top right): "Points" and "Status" (In the woods / Caught). Only the server
-- changes them, so clients can't fake a score.
-- Round stats are attributes on the Player, read by the results screen:
--   RoundMushrooms   mushrooms collected this round
--   RoundBlackouts   blackouts survived this round
--   RoundBonus       survival bonus points earned this round
--   SurvivedDawn     true if they were still in the woods at dawn

local Score = {}

local STATS = { "RoundMushrooms", "RoundBlackouts", "RoundBonus" }
local STATUS_TEXT = { [true] = "Caught", [false] = "In the woods" }

local function getStat(player: Player, name: string): ValueBase?
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild(name)
end

function Score.setup(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Parent = leaderstats

	local status = Instance.new("StringValue")
	status.Name = "Status"
	status.Value = STATUS_TEXT[false]
	status.Parent = leaderstats

	leaderstats.Parent = player

	-- Keep the status in step with the "Caught" attribute that PlayerState sets.
	player:GetAttributeChangedSignal("Caught"):Connect(function()
		status.Value = STATUS_TEXT[player:GetAttribute("Caught") == true]
	end)
	Score.reset(player)
end

function Score.add(player: Player, amount: number)
	local points = getStat(player, "Points")
	if points then
		points.Value += amount
	end
end

-- Adds to one of the round stats (see the list at the top).
function Score.addStat(player: Player, name: string, amount: number)
	player:SetAttribute(name, (player:GetAttribute(name) or 0) + amount)
end

-- A survival bonus: points plus the RoundBonus stat.
function Score.addBonus(player: Player, amount: number)
	Score.add(player, amount)
	Score.addStat(player, "RoundBonus", amount)
end

function Score.reset(player: Player)
	local points = getStat(player, "Points")
	if points then
		points.Value = 0
	end
	for _, name in STATS do
		player:SetAttribute(name, 0)
	end
	player:SetAttribute("SurvivedDawn", false)
end

return Score
