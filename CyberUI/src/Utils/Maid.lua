--!strict

export type Cleanup = RBXScriptConnection | Instance | () -> () | thread

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_tasks = {} :: { Cleanup },
	}, Maid)
end

function Maid:Give(task: Cleanup): Cleanup
	table.insert(self._tasks, task)
	return task
end

function Maid:GiveTask(connection: RBXScriptConnection): RBXScriptConnection
	table.insert(self._tasks, connection)
	return connection
end

function Maid:DoCleaning()
	for index = #self._tasks, 1, -1 do
		local task = self._tasks[index]
		self._tasks[index] = nil

		if typeof(task) == "RBXScriptConnection" then
			task:Disconnect()
		elseif typeof(task) == "Instance" then
			task:Destroy()
		elseif typeof(task) == "function" then
			task()
		elseif typeof(task) == "thread" then
			task.cancel(task)
		end
	end
end

Maid.Destroy = Maid.DoCleaning

return Maid
