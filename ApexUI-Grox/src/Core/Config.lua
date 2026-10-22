--!strict

local HttpService = game:GetService("HttpService")

local Config = {}
Config.__index = Config

export type ConfigHandle = {
	Save: (self: ConfigHandle) -> boolean,
	Load: (self: ConfigHandle) -> boolean,
	Get: (self: ConfigHandle, key: string) -> any,
	Set: (self: ConfigHandle, key: string, value: any) -> (),
	SetLocation: (self: ConfigHandle, folderName: string?, fileName: string?) -> (),
	Destroy: (self: ConfigHandle) -> (),
}

local function getGameName(): string
	local success, id = pcall(function()
		return game.PlaceId
	end)
	if success and id then
		return tostring(id)
	end
	return "Game"
end

local function sanitizeFileName(name: string): string
	return (string.gsub(name, "[\\/:%*%?\"<>|]", "_"))
end

function Config.new(folderName: string?): ConfigHandle
	local defaultFileName = `Vaxorin-{sanitizeFileName(getGameName())}-Config`

	local self = setmetatable({
		_folderName = sanitizeFileName(folderName or "Vaxorin"),
		_fileName = sanitizeFileName(defaultFileName),
		_values = {} :: { [string]: any },
		_autoSave = true,
		_pendingSave = false,
	}, Config)

	return self :: any
end

function Config:SetLocation(folderName: string?, fileName: string?)
	if folderName and folderName ~= "" then
		self._folderName = sanitizeFileName(folderName)
	end
	if fileName and fileName ~= "" then
		self._fileName = sanitizeFileName(fileName)
	end
end

function Config:_getPath(): string
	return `{self._folderName}/{self._fileName}.json`
end

function Config:_encode(value: any): any
	if typeof(value) == "Color3" then
		return { __type = "Color3", R = value.R, G = value.G, B = value.B }
	elseif typeof(value) == "EnumItem" then
		return { __type = "EnumItem", EnumType = tostring(value.EnumType), Name = value.Name }
	elseif type(value) == "table" then
		local encoded = {}
		for key, childValue in value do
			encoded[key] = self:_encode(childValue)
		end
		return encoded
	end
	return value
end

function Config:_decode(value: any): any
	if type(value) ~= "table" then
		return value
	end

	if value.__type == "Color3" then
		return Color3.new(value.R or 0, value.G or 0, value.B or 0)
	elseif value.__type == "EnumItem" and value.EnumType and value.Name then
		local enumName = string.gsub(value.EnumType, "^Enum%.", "")
		local enumType = Enum[enumName]
		if enumType and enumType[value.Name] then
			return enumType[value.Name]
		end
	end

	local decoded = {}
	for key, childValue in value do
		decoded[key] = self:_decode(childValue)
	end
	return decoded
end

function Config:Save(): boolean
	if not isfolder or not makefolder or not writefile then
		warn("[Config] Save aborted: isfolder/makefolder/writefile not available in this executor")
		return false
	end

	local success, err = pcall(function()
		if not isfolder(self._folderName) then
			makefolder(self._folderName)
		end
		local encoded = self:_encode(self._values)
		local json = (next(encoded) == nil) and "{}" or HttpService:JSONEncode(encoded)
		writefile(self:_getPath(), json)
	end)

	if not success then
		warn("[Config] Save failed:", err, "| path:", self._folderName, self._fileName)
	end

	return success
end

function Config:Load(): boolean
	if not isfile or not readfile then
		return false
	end

	local path = self:_getPath()
	local existsOk, exists = pcall(isfile, path)
	if not existsOk or not exists then
		return false
	end

	local success, decoded = pcall(function()
		local raw = readfile(path)
		local parsed = HttpService:JSONDecode(raw)
		if typeof(parsed) ~= "table" then
			error("root JSON value must be an object")
		end
		return self:_decode(parsed)
	end)

	if success and typeof(decoded) == "table" then
		self._values = decoded
		return true
	end

	warn("[Config] Load failed: invalid or unreadable config at", path, decoded)
	return false
end

function Config:Get(key: string): any
	-- Preserve compatibility with older files that store dotted keys flat
	-- (for example "Flags.Aim.Enabled"), while also supporting nested tables.
	local direct = self._values[key]
	if direct ~= nil then
		return direct
	end

	local current: any = self._values
	for part in string.gmatch(key, "[^%.]+") do
		if type(current) ~= "table" then
			return nil
		end
		current = current[part]
		if current == nil then
			return nil
		end
	end
	return current
end

function Config:GetAll(): { [string]: any }
	return self._values
end

function Config:Set(key: string, value: any)
	-- tables always write (profiles mutate in place)
	if type(value) ~= "table" and self._values[key] == value then
		return
	end
	self._values[key] = value
	self:_queueAutoSave()
end

function Config:SetAutoSave(enabled: boolean)
	self._autoSave = enabled
end

function Config:_queueAutoSave()
	if not self._autoSave then return end
	if self._pendingSave then return end
	self._pendingSave = true
	task.defer(function()
		self._pendingSave = false
		self:Save()
	end)
end

function Config:Destroy()
	table.clear(self._values)
end

return Config