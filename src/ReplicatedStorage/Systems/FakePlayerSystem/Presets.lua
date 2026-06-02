local Presets = {}

Presets.RuntimeFolderName = "FakePlayersRuntime"
Presets.DirectorInterval = 0.4
Presets.LowPopulationMaxRealPlayers = 2
Presets.MinFakePlayers = 1
Presets.MaxFakePlayers = 3
Presets.DesiredCountRefreshMin = 600
Presets.DesiredCountRefreshMax = 1200
Presets.FakeUserIdBase = -900000
Presets.FakeBiasLevelMin = 0
Presets.FakeBiasLevelMax = 5
Presets.FakeCoinCountLevelMin = 1
Presets.FakeCoinCountLevelMax = 3
Presets.StartingCashMin = 18
Presets.StartingCashMax = 220
Presets.FirstActionMinDelay = 0.35
Presets.FirstActionMaxDelay = 2.4
Presets.ActionMinDelay = 0.35
Presets.ActionMaxDelay = 0.95
Presets.PostFlipPauseChance = 0.12
Presets.PostFlipPauseMin = 3.5
Presets.PostFlipPauseMax = 8.5
Presets.FlipActionChance = 0.92
Presets.GestureDurationMin = 0.7
Presets.GestureDurationMax = 1.25
Presets.GestureCyclesMin = 1.1
Presets.GestureCyclesMax = 1.9
Presets.NodPitchMin = math.rad(7)
Presets.NodPitchMax = math.rad(14)
Presets.ShakeYawMin = math.rad(16)
Presets.ShakeYawMax = math.rad(30)
Presets.NeckPitchWeight = 0.7
Presets.NeckYawWeight = 0.72
Presets.WaistYawWeight = 0.2

return Presets
