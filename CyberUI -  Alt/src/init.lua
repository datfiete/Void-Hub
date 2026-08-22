--!strict

local Theme = require(script.Core.Theme)
local Config = require(script.Core.Config)
local Notifications = require(script.Core.Notifications)
local Window = require(script.Core.Window)

export type Library = {
	Flags: { [string]: any },
	Theme: typeof(Theme),
	Config: typeof(Config.new()),
	Notifications: any,
	CreateWindow: (self: Library, options: any?) -> any,
	Notify: (self: Library, options: any) -> any,
	Destroy: (self: Library) -> (),
	SaveConfiguration: (self: Library) -> boolean,
	LoadConfiguration: (self: Library) -> boolean,
}

local sharedState = (getgenv and getgenv()) or _G

local Library = {
	Flags = {},
	Theme = Theme,
	_Windows = {},
	_PreviousLibrary = sharedState.CyberUI_Library,
	_ConfigEnabled = false,
	_AutoSave = true,
	_ConfigLoaded = false,
} :: Library

Library.Config = Config.new()
Library.Notifications = Notifications.new(Library)

sharedState.CyberUI_Library = Library

function Library:_configureSaving(options: any?)
	local config = if type(options) == "table" then options.ConfigurationSaving or options.ConfigSaving else nil
	if type(config) ~= "table" then
		self._ConfigEnabled = false
		return
	end

	self._ConfigEnabled = config.Enabled == true
	self._AutoSave = config.AutoSave ~= false
	self.Config:SetLocation(config.FolderName or "CyberUI", config.FileName or config.Name or "config")

	if self._ConfigEnabled and not self._ConfigLoaded then
		self:LoadConfiguration()
	end
end

function Library:_shouldSaveFlag(flag: string?, save: boolean?): boolean
	return self._ConfigEnabled == true and flag ~= nil and flag ~= "" and save ~= false
end

function Library:_getSavedFlag(flag: string?, default: any, save: boolean?): any
	if not self:_shouldSaveFlag(flag, save) then
		return default
	end

	local saved = self.Config:Get(`Flags.{flag}`)
	if saved ~= nil then
		return saved
	end

	return default
end

function Library:_setFlag(flag: string?, value: any, save: boolean?)
	if flag then
		self.Flags[flag] = value
	end

	if self:_shouldSaveFlag(flag, save) then
		self.Config:Set(`Flags.{flag}`, value)
		if self._AutoSave then
			self.Config:Save()
		end
	end
end

function Library:CreateWindow(options: any?)
	self:_configureSaving(options)

	if self._PreviousLibrary and self._PreviousLibrary ~= self and self._PreviousLibrary.Destroy then
		pcall(function()
			self._PreviousLibrary:Destroy()
		end)
	end
	self._PreviousLibrary = nil

	for _, existingWindow in self._Windows do
		if existingWindow and existingWindow.Destroy then
			existingWindow:Destroy()
		end
	end
	self._Windows = {}

	local window = Window.new(self, options)
	table.insert(self._Windows, window)
	return window
end

function Library:RefreshTheme()
	for _, window in self._Windows do
		if window.RefreshTheme then
			window:RefreshTheme()
		end
	end
end

function Library:Notify(options: any)
	return self.Notifications:Notify(options)
end

function Library:SaveConfiguration(): boolean
	return self.Config:Save()
end

function Library:LoadConfiguration(): boolean
	self._ConfigLoaded = true
	return self.Config:Load()
end

function Library:Destroy()
	for _, window in self._Windows do
		if window and window.Destroy then
			window:Destroy()
		end
	end
	self._Windows = {}
	if self.Notifications and self.Notifications.Destroy then
		self.Notifications:Destroy()
	end
	table.clear(self.Flags)
end

function Library:_configureSaving(options: any?)
	local config = if type(options) == "table" then options.ConfigurationSaving or options.ConfigSaving else nil
	if type(config) ~= "table" then
		self._ConfigEnabled = false
		print("[CyberUI] ConfigurationSaving not provided, config disabled")
		return
	end

	self._ConfigEnabled = config.Enabled == true
	self._AutoSave = config.AutoSave ~= false
	self.Config:SetLocation(config.FolderName, config.FileName or config.Name)

	print("[CyberUI] Config enabled:", self._ConfigEnabled, "| autosave:", self._AutoSave, "| path:", self.Config._folderName, self.Config._fileName)

	if self._ConfigEnabled and not self._ConfigLoaded then
		self:LoadConfiguration()
	end
end

return Library
