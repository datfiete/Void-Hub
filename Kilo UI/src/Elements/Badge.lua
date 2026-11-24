--!strict
local Theme=require(script.Parent.Parent.Core.Theme)
local Helpers=require(script.Parent.Parent.Utils.Helpers)
local Badge={}; Badge.__index=Badge
function Badge.new(section:any,data:any?):any
 data=data or {}; local self=setmetatable({_Section=section,_Data=data},Badge); local theme=section.Tab.Window.Library.Theme; local color=data.Color or theme.Accent
 local root=Helpers.CreateFrame({Name=data.Name or "Badge",Size=UDim2.fromOffset(data.Width or 96,data.Height or 28),BackgroundColor3=color,BackgroundTransparency=data.BackgroundTransparency or 0.80,Parent=section.Inner}); Helpers.Corner(root,999); local stroke=Helpers.Stroke(root,color,1); stroke.Transparency=0.22; Helpers.Padding(root,8,4)
 local label=Helpers.CreateLabel({Name="Text",Size=UDim2.new(1,0,1,0),Text=tostring(data.Text or "STATUS"),Font=Theme.FontBold,TextSize=data.TextSize or 10,TextColor3=color,TextXAlignment=Enum.TextXAlignment.Center,Parent=root})
 self.Instance,self.Label,self._Stroke=root,label,stroke; return self
end
function Badge:Set(text:string) self.Label.Text=tostring(text) end
function Badge:RefreshTheme() local theme=self._Section.Tab.Window.Library.Theme; local c=self._Data.Color or theme.Accent; self._Stroke.Color=c; self.Label.TextColor3=c end
function Badge:Destroy() if self.Instance and self.Instance.Parent then self.Instance:Destroy() end end
return Badge
