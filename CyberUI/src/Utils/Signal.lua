--!strict

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> T...,
	Destroy: (self: Signal<T...>) -> (),
}

function Signal.new<T...>(): Signal<T...>
	local self = setmetatable({
		_connections = {} :: { (...any) -> () },
	}, Signal)

	return self :: any
end

function Signal:Connect(callback: (...any) -> ()): Connection
	table.insert(self._connections, callback)

	return {
		Disconnect = function()
			local index = table.find(self._connections, callback)
			if index then
				table.remove(self._connections, index)
			end
		end,
	}
end

function Signal:Fire(...: any)
	for _, callback in self._connections do
		task.spawn(callback, ...)
	end
end

function Signal:Wait(): ...any
	local thread = coroutine.running()
	self:Connect(function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Destroy()
	table.clear(self._connections)
end

return Signal
