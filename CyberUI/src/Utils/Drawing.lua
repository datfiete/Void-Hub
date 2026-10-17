--!strict
-- Lightweight Drawing helpers for environments that expose a Drawing API
-- (common in some Roblox executors). Falls back gracefully when unavailable.

local DrawingLib = rawget(_G, "Drawing") or (getgenv and rawget(getgenv(), "Drawing"))

local Drawing = {}

export type DrawingObject = {
	Remove: (self: DrawingObject) -> (),
	Visible: boolean,
	[string]: any,
}

function Drawing.IsAvailable(): boolean
	return type(DrawingLib) == "table" and type(DrawingLib.new) == "function"
end

function Drawing.new(className: string, props: { [string]: any }?): DrawingObject?
	if not Drawing.IsAvailable() then
		return nil
	end

	local ok, obj = pcall(function()
		return DrawingLib.new(className)
	end)

	if not ok or not obj then
		return nil
	end

	if type(props) == "table" then
		for k, v in pairs(props) do
			pcall(function()
				(obj :: any)[k] = v
			end)
		end
	end

	return obj
end

function Drawing.Remove(obj: DrawingObject?)
	if obj and type(obj.Remove) == "function" then
		pcall(function()
			obj:Remove()
		end)
	end
end

return Drawing
