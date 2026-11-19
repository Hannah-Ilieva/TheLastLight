-- SoundConfig: every sound the game plays, in one place. All come from Roblox's licensed
-- libraries (APM Music and Pro Sound Effects), so they are free to use in Roblox games.
-- To swap a sound, change its Id here. Volume is 0-1.

return {
	-- Music and atmosphere (played by the client's AudioController)
	Song = { Id = 1839911004, Volume = 0.45 }, -- "Nursery Crime": the eerie music-box song the forest listens to
	Ambience = { Id = 9114894498, Volume = 0.22 }, -- night insects and a light breeze
	Heartbeat = { Id = 9043365842, Volume = 0.7 }, -- speeds up during the Warning
	BlackoutDrone = { Id = 9112775175, Volume = 0.4 }, -- low rumbling presence in the dark
	Dawn = { Id = 9112831284, Volume = 0.35 }, -- morning birds on the results screen

	-- Short effects
	Pickup = { Id = 9116394545, Volume = 0.45 }, -- soft magic chime
	RarePickup = { Id = 9116395089, Volume = 0.55 }, -- longer, brighter chime for power mushrooms
	SpeedBoost = { Id = 9114373678, Volume = 0.6 }, -- airy whoosh
	ShieldBreak = { Id = 9119467693, Volume = 0.7 }, -- spirits rushing past
	Caught = { Id = 1846887425, Volume = 0.55 }, -- a short orchestral sting (not a loud blast)
}
