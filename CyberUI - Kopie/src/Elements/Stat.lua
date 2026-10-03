--!strict
local Theme=require(script.Parent.Parent.Core.Theme)
local Helpers=require(script.Parent.Parent.Utils.Helpers)
local Stat={}; Stat.__index=Stat
function Stat.new(section:any,data:any?):any
 data=data or {}; local self=setmetatable({_Section=section,_Data=data},Stat); local theme=section.Tab.Window.Library.Theme; local c=data.Color or theme.Accent
 local root=Helpers.CreateFrame({Name=data.Name or "Stat",Size=UDim2.new(1,0,0,data.Height or 62),BackgroundColor3=theme.ElementBackground,BackgroundTransparency=0.02,Parent=section.Inner}); Helpers.Corner(root,Theme.CornerRadiusSmall); local stroke=Helpers.Stroke(root,theme.Border,1)
 local label=Helpers.CreateLabel({Name="Label",Size=UDim2.new(1,-24,0,16),Position=UDim2.fromOffset(12,8),Text=tostring(data.Label or data.Title or "Stat"),Font=Theme.Font,TextSize=9,TextColor3=theme.TextMuted,Parent=root}); local val=Helpers.CreateLabel({Name="Value",Size=UDim2.new(1,-24,0,24),Position=UDim2.fromOffset(12,25),Text=tostring(data.Value or "0"),Font=Theme.FontBold,TextSize=19,TextColor3=theme.Text,Parent=root}); local delta=Helpers.CreateLabel({Name="Delta",Size=UDim2.fromOffset(80,18),Position=UDim2.new(1,-92,0,9),Text=tostring(data.Delta or ""),Font=Theme.FontBold,TextSize=9,TextColor3=c,TextXAlignment=Enum.TextXAlignment.Right,Parent=root})
 self.Instance,self.Label,self.ValueLabel,self.DeltaLabel,self._Stroke=root,label,val,delta,stroke; return self
end
function Stat:Set(value:any,delta:any?) self.ValueLabel.Text=tostring(value); if delta~=nil then self.DeltaLabel.Text=tostring(delta) end end
function Stat:RefreshTheme() local theme=self._Section.Tab.Window.Library.Theme; self.Label.TextColor3=theme.TextMuted; self.ValueLabel.TextColor3=theme.Text; self._Stroke.Color=theme.Border; if not self._Data.Color then self.DeltaLabel.TextColor3=theme.Accent end end
function Stat:Destroy() if self.Instance and self.Instance.Parent then self.Instance:Destroy() end end
return Stat
