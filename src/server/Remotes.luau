-- Remotes: creates the RemoteEvents that server and clients use to talk, in
-- ReplicatedStorage.Remotes. Clients find them with WaitForChild.
--   UseAbility  client -> server: "I'd like to use my power." The server checks everything.
--   SelectSkin  client -> server: (skinName) "I'd like this look." Checked against SkinConfig.
--   Notify      server -> client: (style, title, detail) a short message to show on screen.
--               Styles: "pickup", "rare", "power", "shield", "info".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = Instance.new("Folder")
folder.Name = "Remotes"
folder.Parent = ReplicatedStorage

local function makeEvent(name: string): RemoteEvent
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	return event
end

return {
	UseAbility = makeEvent("UseAbility"),
	SelectSkin = makeEvent("SelectSkin"),
	Notify = makeEvent("Notify"),
}
