-- Score: keeps each player's round points.
-- Points live in a "leaderstats" folder, which Roblox shows in the player list
-- (top right). Only the server changes them, so clients can't fake a score.

local Score = {}

function Score.setup(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Parent = leaderstats

	leaderstats.Parent = player
end

function Score.add(player: Player, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Points.Value += amount
	end
end

return Score
