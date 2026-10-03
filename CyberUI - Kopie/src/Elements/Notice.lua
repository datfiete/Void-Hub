--!strict
local Theme=require(script.Parent.Parent.Core.Theme)
local Maid=require(script.Parent.Parent.Utils.Maid)
local Helpers=require(script.Parent.Parent.Utils.Helpers)
local Tween=require(script.Parent.Parent.Utils.Tween)
local Notice={}; Notice.__index=Notice
function Notice.new(section:any,data:any?):any
 data=data or {}; local self=setmetatable({_Section=section,_Data=data,_Maid=Maid.new()},Notice); local theme=section.Tab.Window.Library.Theme; local c=data.Color or theme.Accent
 local root=Helpers.CreateFrame({Name=data.Name or "Notice",Size=UDim2.new(1,0,0,data.Height or 62),BackgroundColor3=data.BackgroundColor or theme.SurfaceHover,BackgroundTransparency=0.05,Parent=section.Inner}); Helpers.Corner(root,Theme.CornerRadiusSmall); local stroke=Helpers.Stroke(root,c,1); stroke.Transparency=0.18; local rail=Helpers.CreateFrame({Name="Rail",Size=UDim2.fromOffset(4,34),Position=UDim2.fromOffset(10,14),BackgroundColor3=c,Parent=root}); Helpers.Corner(rail,2)
 local title=Helpers.CreateLabel({Name="Title",Size=UDim2.new(1,-42,0,18),Position=UDim2.fromOffset(24,8),Text=tostring(data.Title or "Notice"),Font=Theme.FontBold,TextSize=11,TextColor3=theme.Text,Parent=root}); local body=Helpers.CreateLabel({Name="Content",Size=UDim2.new(1,-42,0,30),Position=UDim2.fromOffset(24,27),Text=tostring(data.Content or ""),Font=Theme.Font,TextSize=10,TextColor3=theme.TextMuted,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,Parent=root})
 self.Instance,self.TitleLabel,self.ContentLabel,self._Stroke,self._Rail=root,title,body,stroke,rail; if data.Callback then self._Maid:GiveTask(root.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then task.spawn(data.Callback) end end)) end; return self
end
function Notice:Set(content:string) self.ContentLabel.Text=tostring(content) end
function Notice:RefreshTheme() local theme=self._Section.Tab.Window.Library.Theme; local c=self._Data.Color or theme.Accent; self._Stroke.Color=c; self._Rail.BackgroundColor3=c; self.TitleLabel.TextColor3=theme.Text; self.ContentLabel.TextColor3=theme.TextMuted end
function Notice:Destroy() self._Maid:DoCleaning(); if self.Instance and self.Instance.Parent then self.Instance:Destroy() end end
return Notice
