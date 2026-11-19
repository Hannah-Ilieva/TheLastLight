-- SkinService: puts the chosen cosmetic look (SkinConfig) on each player's character.
-- The client can only ASK for a skin by name (SelectSkin remote). The server checks the
-- name is on the allowed list and that it's a wardrobe phase, then stores it in the
-- player's "Skin" attribute and rebuilds the pieces. Pieces are welded, massless and
-- walk-through, so they never change speed, size or how the monster finds you.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local SkinConfig = require(ReplicatedStorage.Shared.SkinConfig)
local log = require(ReplicatedStorage.Shared.Log)
local Remotes = require(script.Parent.Remotes)

local FOLDER_NAME = "Cosmetics"
local REQUEST_COOLDOWN = 0.5 -- seconds between accepted requests, so spamming does nothing
-- Width of each body part on a standard avatar; bigger avatars get bigger pieces.
local REFERENCE_WIDTH = { Head = 1.2, UpperTorso = 2, LowerTorso = 2, Torso = 2 }
local R6_PART = { UpperTorso = "Torso", LowerTorso = "Torso" }

local SkinService = {}

local lastRequest: { [Player]: number } = {}

local function buildPiece(piece, character: Model, parent: Instance)
	local bodyPart = character:FindFirstChild(piece.Attach) or character:FindFirstChild(R6_PART[piece.Attach] or "")
	if not (bodyPart and bodyPart:IsA("BasePart")) then
		return
	end
	local scale = bodyPart.Size.X / (REFERENCE_WIDTH[bodyPart.Name] or bodyPart.Size.X)
	local part = Instance.new("Part")
	part.Name = piece.Name
	if piece.Shape then
		part.Shape = Enum.PartType[piece.Shape]
	end
	part.Size = piece.Size * scale
	part.Color = piece.Color
	part.Material = piece.Material or Enum.Material.SmoothPlastic
	part.Transparency = piece.Transparency or 0
	part.Massless = true -- adds no weight, so movement is unchanged
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	local turn = piece.Turn or Vector3.zero
	local offset = piece.Offset * bodyPart.Size
	part.CFrame = bodyPart.CFrame * CFrame.new(offset) * CFrame.fromOrientation(math.rad(turn.X), math.rad(turn.Y), math.rad(turn.Z))

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = bodyPart
	weld.Part1 = part
	weld.Parent = part
	part.Parent = parent
end

-- Removes the old pieces and builds the player's current skin on their character.
function SkinService.apply(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild(FOLDER_NAME)
	if old then
		old:Destroy()
	end
	local skin = SkinConfig.Skins[player:GetAttribute("Skin")]
	if not skin or #skin.Pieces == 0 then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, piece in skin.Pieces do
		buildPiece(piece, character, folder)
	end
	folder.Parent = character
end

local function onSelectSkin(player: Player, skinName: unknown)
	if typeof(skinName) ~= "string" or not SkinConfig.Skins[skinName] then
		return -- not on the allowed list
	end
	if not GameConfig.WardrobePhases[ReplicatedStorage:GetAttribute("Phase")] then
		return
	end
	local now = os.clock()
	if now - (lastRequest[player] or 0) < REQUEST_COOLDOWN then
		return
	end
	lastRequest[player] = now
	player:SetAttribute("Skin", skinName)
	SkinService.apply(player)
	log(player.Name, "chose the", skinName, "look")
end

function SkinService.setup(player: Player)
	player:SetAttribute("Skin", "Default")
	-- Wait until Roblox has finished dressing the avatar, then add our pieces.
	player.CharacterAppearanceLoaded:Connect(function()
		SkinService.apply(player)
	end)
end

function SkinService.start()
	Remotes.SelectSkin.OnServerEvent:Connect(onSelectSkin)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return SkinService
