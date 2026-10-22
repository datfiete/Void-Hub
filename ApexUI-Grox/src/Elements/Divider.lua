--!strict
local Theme=require(script.Parent.Parent.Core.Theme)
local Helpers=require(script.Parent.Parent.Utils.Helpers)
local Divider={}; Divider.__index=Divider
function Divider.new(section:any,data:any?):any
 data=data or {}; local self=setmetatable({_Section=section,_Data=data},Divider); local theme=section.Tab.Window.Library.Theme; local root=Helpers.CreateFrame({Name=data.Name or "Divider",Size=UDim2.new(1,0,0,data.Height or 16),BackgroundTransparency=1,Parent=section.Inner}); local line=Helpers.CreateFrame({Name="Line",Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=data.Color or theme.Border,Parent=root}); self.Instance,self.Line=root,line; return self end
function Divider:RefreshTheme() local theme=self._Section.Tab.Window.Library.Theme; if not self._Data.Color then self.Line.BackgroundColor3=theme.Border end end
function Divider:Destroy() if self.Instance and self.Instance.Parent then self.Instance:Destroy() end end
return Divider
