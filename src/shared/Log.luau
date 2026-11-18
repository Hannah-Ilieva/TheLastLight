-- Log: prints a debug message, but only while GameConfig.Debug is true.
-- Usage: local log = require(ReplicatedStorage.Shared.Log); log("Something happened", value)

local GameConfig = require(script.Parent.GameConfig)

return function(...)
	if GameConfig.Debug then
		print("[TheLastLight]", ...)
	end
end
