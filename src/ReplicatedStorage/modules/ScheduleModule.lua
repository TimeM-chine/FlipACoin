local RunService = game:GetService("RunService")

local ScheduleModule = {}
local schedules = {}
local nextScheduleId = 1
local heartbeatConnection = nil

-- Process all active schedules in a single heartbeat connection
local function processSchedules(dt)
	for id, schedule in pairs(schedules) do
		schedule.timeSinceLastRun = schedule.timeSinceLastRun + dt

		if schedule.timeSinceLastRun >= schedule.timeGap then
			schedule.timeSinceLastRun = schedule.timeSinceLastRun - schedule.timeGap -- reset timer but keep remainder
			local success, err = pcall(schedule.func)
			if not success then
				warn("Error in scheduled function (ID " .. id .. "): " .. tostring(err))
			end
		end
	end
end

-- Initialize the heartbeat connection if not already initialized
local function ensureHeartbeatConnection()
	if not heartbeatConnection then
		heartbeatConnection = RunService.Heartbeat:Connect(processSchedules)
	end
end

-- Clean up the heartbeat connection if no schedules are active
local function cleanupHeartbeatIfNeeded()
	if heartbeatConnection and next(schedules) == nil then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end

-- Add a new schedule to run a function periodically
-- @param intervalSeconds: number - time in seconds between function calls
-- @param func: function - the function to run on schedule
-- @return: number - the schedule ID that can be used to cancel this schedule later
function ScheduleModule.AddSchedule(intervalSeconds, func)
	assert(type(intervalSeconds) == "number" and intervalSeconds > 0, "IntervalSeconds must be a positive number")
	assert(type(func) == "function", "Func must be a function")

	local scheduleId = nextScheduleId
	nextScheduleId = nextScheduleId + 1

	schedules[scheduleId] = {
		timeGap = intervalSeconds,
		func = func,
		timeSinceLastRun = 0,
	}

	ensureHeartbeatConnection()

	return scheduleId
end

-- Cancel a schedule by its ID
-- @param scheduleId: number - the ID of the schedule to cancel
-- @return: boolean - true if successfully canceled, false if the schedule wasn't found
function ScheduleModule.CancelSchedule(scheduleId)
	local schedule = schedules[scheduleId]
	if not schedule then
		return false
	end

	schedules[scheduleId] = nil
	cleanupHeartbeatIfNeeded()

	return true
end

-- Get all active schedule IDs
-- @return: table - array of all active schedule IDs
function ScheduleModule.GetActiveScheduleIds()
	local ids = {}
	for id, _ in pairs(schedules) do
		table.insert(ids, id)
	end
	return ids
end

-- Check if a schedule is active
-- @param scheduleId: number - the ID of the schedule to check
-- @return: boolean - true if the schedule is active, false otherwise
function ScheduleModule.IsScheduleActive(scheduleId)
	return schedules[scheduleId] ~= nil
end

-- Cleanup function to be called when the module is no longer needed
function ScheduleModule.Cleanup()
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	schedules = {}
end

return ScheduleModule
