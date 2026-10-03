--!strict
local Theme=require(script.Parent.Parent.Core.Theme)
local Helpers=require(script.Parent.Parent.Utils.Helpers)
local Status={}; Status.__index=Status
function Status.new(section:any,data:any?):any
 data=data or {}; local self=setmetatable({_Section=section,_Data=data},Status); local theme=section.Tab.Window.Library.Theme; local c=data.Color or theme.Success or theme.Accent
 local root=Helpers.CreateFrame({Name=data.Name or "Status",Size=UDim2.new(1,0,0,data.Height or 50),BackgroundColor3=theme.ElementBackground,BackgroundTransparency=0.02,Parent=section.Inner}); Helpers.Corner(root,Theme.CornerRadiusSmall); local stroke=Helpers.Stroke(root,theme.Border,1); local dot=Helpers.CreateFrame({Name="Dot",Size=UDim2.fromOffset(8,8),Position=UDim2.fromOffset(14,21),BackgroundColor3=c,Parent=root}); Helpers.Corner(dot,4)
 local title=Helpers.CreateLabel({Name="Title",Size=UDim2.new(1,-44,0,18),Position=UDim2.fromOffset(32,8),Text=tostring(data.Title or "System Status"),Font=Theme.FontBold,TextSize=11,TextColor3=theme.Text,Parent=root}); local body=Helpers.CreateLabel({Name="Content",Size=UDim2.new(1,-44,0,17),Position=UDim2.fromOffset(32,27),Text=tostring(data.Content or "Operational"),Font=Theme.Font,TextSize=10,TextColor3=theme.TextMuted,Parent=root})
 self.Instance,self.TitleLabel,self.ContentLabel,self.Dot,self._Stroke=root,title,body,dot,stroke; return self
end
function Status:Set(title:string,content:string?) self.TitleLabel.Text=tostring(title); if content~=nil then self.ContentLabel.Text=tostring(content) end end
function Status:SetColor(color:Color3) self.Dot.BackgroundColor3=color end
function Status:RefreshTheme() local theme=self._Section.Tab.Window.Library.Theme; self.TitleLabel.TextColor3=theme.Text; self.ContentLabel.TextColor3=theme.TextMuted; self._Stroke.Color=theme.Border; if not self._Data.Color then self.Dot.BackgroundColor3=theme.Success or theme.Accent end end
function Status:Destroy() if self.Instance and self.Instance.Parent then self.Instance:Destroy() end end
return Status
