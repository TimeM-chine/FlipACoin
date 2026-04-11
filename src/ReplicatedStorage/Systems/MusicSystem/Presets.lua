local MusicPresets = {}

local freeClickBtn = "rbxassetid://452267918"

local other = {
    train = {
        tireHitLand = {
            id = "rbxassetid://18573568052",
            looped = false,
            volume = 0.5,
        },
    }
}

MusicPresets.Musics = {}

for k, v in pairs(other) do
    for name, config in pairs(v) do
        MusicPresets.Musics[k] = MusicPresets.Musics[k] or {}
        config.looped = config.looped or false
        config.volume = config.volume or 0.5
        MusicPresets.Musics[k][name] = config
    end
end

return MusicPresets