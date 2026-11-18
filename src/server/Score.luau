-- Score: keeps each player's round points.
-- Points live in a "leaderstats" folder, which Roblox shows in the player list
-- (top right). Only the server changes them, so clients can't fake a score.

local Score = {}

local function getPoints(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Points")
end

function Score.setup(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Parent = leaderstats

	leaderstats.Parent = player
end

function Score.add(player: Player, amount: number)
	local points = getPoints(player)
	if points then
		points.Value += amount
	end
end

function Score.reset(player: Player)
	local points = getPoints(player)
	if points then
		points.Value = 0
	end
end

return Score
