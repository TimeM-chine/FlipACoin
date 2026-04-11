--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: Types.lua
--Last Modified: 2024-02-21 11:05:00
--]]

local Types = {}

export type System = {
	Remotes: { RemoteEvent },
	whiteList: table,
	IsLoaded: boolean,
}

Types.mt = {
	__index = function(t, key)
		if type(key) == "string" then
			local defaultFunc = function(...)
				local args = { ... }
				table.insert(t.pendingCalls, {
					functionName = key,
					args = args,
				})
				return nil
			end
			rawset(t, key, defaultFunc) -- 将默认函数存入原表，避免重复触发__index
			return defaultFunc
		end
		return nil
	end,
}

return Types
