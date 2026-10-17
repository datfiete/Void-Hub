--!strict

local Theme = require(script.Core.Theme)
local Config = require(script.Core.Config)
local Notifications = require(script.Core.Notifications)
local Window = require(script.Core.Window)
local ESPWorldRenderer = require(script.Core.ESPWorldRenderer)

export type Library = {
	Flags: { [string]: any },
	Theme: typeof(Theme),
	Config: typeof(Config.new()),
	Notifications: any,
	ESPWorldRenderer: typeof(ESPWorldRenderer),
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
Library.ESPWorldRenderer = ESPWorldRenderer

sharedState.CyberUI_Library = Library

function Library:_configureSaving(options: any?)
	local config = if type(options) == "table" then options.ConfigurationSaving or options.ConfigSaving else nil
	if type(config) ~= "table" then
		self._ConfigEnabled = false
		return
	end

	self._ConfigEnabled = config.Enabled == true
	self._AutoSave = config.AutoSave ~= false
	self.Config:SetLocation(config.FolderName or "Vaxorin", config.FileName or config.Name or "config")

	if self._ConfigEnabled and not self._ConfigLoaded then
		self:LoadConfiguration()
	else
		self:_hydrateFlagsFromConfig()
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
			self.Config:_queueAutoSave()
		end
	end
end

function Library:_bindFlagControl(flag: string?, control: any)
	if not flag or flag == "" or not control then
		return
	end
	if not self._FlagControls then
		self._FlagControls = {}
	end
	self._FlagControls[flag] = control
end

function Library:_hydrateFlagsFromConfig()
	local all = self.Config.GetAll and self.Config:GetAll() or nil
	if type(all) ~= "table" then
		return
	end
	for key, value in pairs(all) do
		if type(key) == "string" and string.sub(key, 1, 6) == "Flags." then
			local flag = string.sub(key, 7)
			if flag ~= "" then
				self.Flags[flag] = value
			end
		end
	end
end

function Library:GetSession(key: string, default: any): any
	local value = self.Config:Get(`Session.{key}`)
	if value == nil then
		return default
	end
	return value
end

function Library:SetSession(key: string, value: any)
	if not self._ConfigEnabled then
		return
	end
	self.Config:Set(`Session.{key}`, value)
end

function Library:SaveProfile(name: string): boolean
	if not self._ConfigEnabled then
		return false
	end
	name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		return false
	end

	local flags = {}
	for flag, value in pairs(self.Flags) do
		flags[flag] = value
	end
	-- merge any config flags not yet in memory
	local all = self.Config:GetAll()
	if type(all) == "table" then
		for key, value in pairs(all) do
			if type(key) == "string" and string.sub(key, 1, 6) == "Flags." then
				local flag = string.sub(key, 7)
				if flag ~= "" and flags[flag] == nil then
					flags[flag] = value
				end
			end
		end
	end

	local profiles = self.Config:Get("Profiles")
	if type(profiles) ~= "table" then
		profiles = {}
	end
	profiles[name] = {
		Flags = flags,
		Layout = self:GetSession("Layout", nil),
		LastTab = self:GetSession("LastTab", nil),
		SavedAt = os.time(),
	}
	self.Config:Set("Profiles", profiles)
	self.Config:Set("Session.ActiveProfile", name)
	return self.Config:Save()
end

function Library:LoadProfile(name: string): boolean
	if not self._ConfigEnabled then
		return false
	end
	name = tostring(name or "")
	local profiles = self.Config:Get("Profiles")
	if type(profiles) ~= "table" or type(profiles[name]) ~= "table" then
		return false
	end

	local profile = profiles[name]
	local flags = profile.Flags
	if type(flags) ~= "table" then
		return false
	end

	-- apply into memory + disk without spamming full save each flag
	local prevAuto = self._AutoSave
	self._AutoSave = false
	for flag, value in pairs(flags) do
		self.Flags[flag] = value
		self.Config:Set(`Flags.{flag}`, value)
		local control = self._FlagControls and self._FlagControls[flag]
		if control and control.Set then
			pcall(function()
				control:Set(value, true)
			end)
		end
	end
	self._AutoSave = prevAuto

	if profile.Layout then
		self:SetSession("Layout", profile.Layout)
		for _, window in self._Windows do
			if window and window.SetLayout then
				pcall(function()
					window:SetLayout(profile.Layout)
				end)
			end
		end
	end
	if profile.LastTab then
		self:SetSession("LastTab", profile.LastTab)
		for _, window in self._Windows do
			if window and window._Tabs then
				for _, tab in window._Tabs do
					local tabName = tab._Name or tab.Name
					if tabName == profile.LastTab and window._selectTab then
						pcall(function()
							window:_selectTab(tab)
						end)
						break
					end
				end
			end
		end
	end

	self.Config:Set("Session.ActiveProfile", name)
	return self.Config:Save()
end

function Library:DeleteProfile(name: string): boolean
	if not self._ConfigEnabled then
		return false
	end
	local profiles = self.Config:Get("Profiles")
	if type(profiles) ~= "table" or profiles[name] == nil then
		return false
	end
	profiles[name] = nil
	self.Config:Set("Profiles", profiles)
	if self.Config:Get("Session.ActiveProfile") == name then
		self.Config:Set("Session.ActiveProfile", nil)
	end
	return self.Config:Save()
end

function Library:GetProfiles(): { string }
	local profiles = self.Config:Get("Profiles")
	local list = {}
	if type(profiles) == "table" then
		for name in pairs(profiles) do
			if type(name) == "string" then
				table.insert(list, name)
			end
		end
		table.sort(list)
	end
	return list
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
	local ok = self.Config:Load()
	self:_hydrateFlagsFromConfig()
	return ok
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


return Library
