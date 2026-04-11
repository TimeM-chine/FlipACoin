-- ---- services ----
-- local Replicated = game:GetService("ReplicatedStorage")

-- ---- requires ----
-- local GAModule = require(Replicated.modules.GAModule)
-- local GameConfig = require(Replicated.configs.GameConfig)

-- ---- classes ----

-- ---- events ----
-- local myDesignEvent = Replicated.modules.GAModule.myDesignEvent

-- ---- enums ----

-- GAModule:configureBuild(GameConfig.version)

-- GAModule:setEnabledDebugLog(false)
-- GAModule:setEnabledInfoLog(false)

-- GAModule:initServer("fb39761579712621c22791879c1d0dc8", "2f7c6b9f0aac440631ae2add01399e98d82ef72d") -- test game

-- myDesignEvent.OnServerEvent:Connect(function(player, param)
-- 	GAModule:addDesignEvent(player.UserId, param)
-- end)
