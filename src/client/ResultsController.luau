-- ResultsController: the results screen shown at dawn (the Results phase).
-- It shows how YOUR round went (points, mushrooms, blackouts survived, bonuses) and a
-- ranking of every player. All numbers come from what the server published: each
-- player's leaderstats and round-stat attributes (see Score). Nothing is decided here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local UIStyle = require(script.Parent.UIStyle)

local MAX_ROWS = 6 -- the game is for up to 6 players
local ROW_HEIGHT = 26
local REFRESH_SECONDS = 0.5

local ResultsController = {}

local player = Players.LocalPlayer

local function getPoints(who: Player): number
	local leaderstats = who:FindFirstChild("leaderstats")
	local points = leaderstats and leaderstats:FindFirstChild("Points")
	return points and points.Value or 0
end

-- One line of the breakdown: a name on the left and a value on the right.
local function statLine(parent: Instance, y: number): (TextLabel, TextLabel)
	local name = UIStyle.label("StatName", {
		Position = UDim2.fromOffset(32, y),
		Size = UDim2.new(0.6, -32, 0, 22),
		Font = UIStyle.BodyFont,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
	local value = UIStyle.label("StatValue", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -32, 0, y),
		Size = UDim2.new(0.4, -32, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, parent)
	return name, value
end

local function buildScreen(gui: ScreenGui)
	local panel = UIStyle.panel("Results", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(460, 226 + MAX_ROWS * ROW_HEIGHT + 40),
		Visible = false,
	}, gui, UIStyle.Warm)
	local ui = { panel = panel }
	ui.title = UIStyle.label("Title", {
		Position = UDim2.fromOffset(20, 12),
		Size = UDim2.new(1, -40, 0, 46),
		Font = UIStyle.TitleFont,
		Text = "Dawn Breaks",
		TextColor3 = UIStyle.Warm,
	}, panel)
	ui.subtitle = UIStyle.label("Subtitle", {
		Position = UDim2.fromOffset(20, 58),
		Size = UDim2.new(1, -40, 0, 22),
		Font = UIStyle.BodyFont,
	}, panel)
	ui.points = UIStyle.label("Points", {
		Position = UDim2.fromOffset(20, 86),
		Size = UDim2.new(1, -40, 0, 36),
		TextColor3 = UIStyle.Warm,
	}, panel)
	ui.lines = {}
	for i = 1, 3 do
		local name, value = statLine(panel, 128 + (i - 1) * 24)
		ui.lines[i] = { name = name, value = value }
	end

	UIStyle.label("RankingHeader", {
		Position = UDim2.fromOffset(32, 206),
		Size = UDim2.new(1, -64, 0, 16),
		Text = "FORAGERS",
		TextColor3 = UIStyle.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, panel)
	ui.rows = {}
	for i = 1, MAX_ROWS do
		local name, value = statLine(panel, 226 + (i - 1) * ROW_HEIGHT)
		ui.rows[i] = { name = name, value = value }
	end
	ui.footer = UIStyle.label("Footer", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -40, 0, 18),
		Font = UIStyle.BodyFont,
		TextColor3 = UIStyle.Muted,
	}, panel)
	return ui
end

local function refresh(ui)
	local survived = player:GetAttribute("SurvivedDawn") == true
	local blackouts = player:GetAttribute("RoundBlackouts") or 0
	local bonus = player:GetAttribute("RoundBonus") or 0
	ui.subtitle.Text = survived and "You survived the night." or "Caught in the dark — better luck next night."
	ui.points.Text = ("%d points"):format(getPoints(player))

	local lines = {
		{ "Mushrooms collected", tostring(player:GetAttribute("RoundMushrooms") or 0) },
		{ "Blackouts survived", ("%d / %d"):format(blackouts, GameConfig.CyclesPerRound) },
		{ "Survival bonus", ("+%d"):format(bonus) },
	}
	for i, line in ui.lines do
		line.name.Text = lines[i][1]
		line.value.Text = lines[i][2]
	end

	-- Ranking: everyone, highest points first.
	local everyone = Players:GetPlayers()
	table.sort(everyone, function(a, b)
		return getPoints(a) > getPoints(b)
	end)
	for i, row in ui.rows do
		local who = everyone[i]
		row.name.Visible = who ~= nil
		row.value.Visible = who ~= nil
		if who then
			local status = who:GetAttribute("SurvivedDawn") and "at dawn" or "caught"
			row.name.Text = ("%d.  %s  (%s)"):format(i, who.DisplayName, status)
			row.value.Text = tostring(getPoints(who))
			local color = who == player and UIStyle.Warm or UIStyle.Text
			row.name.TextColor3 = color
			row.value.TextColor3 = color
		end
	end

	local endsAt = ReplicatedStorage:GetAttribute("PhaseEndsAt") or 0
	local remaining = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
	ui.footer.Text = ("A new night begins in %d…"):format(remaining)
end

function ResultsController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ResultsScreen"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local ui = buildScreen(gui)

	local function onPhase()
		local showing = ReplicatedStorage:GetAttribute("Phase") == "Results"
		ui.panel.Visible = showing
		if not showing then
			return
		end
		task.spawn(function()
			while ReplicatedStorage:GetAttribute("Phase") == "Results" do
				refresh(ui)
				task.wait(REFRESH_SECONDS)
			end
		end)
	end
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(onPhase)
	onPhase()
end

return ResultsController
