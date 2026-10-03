--!strict
local Theme=require(script.Parent.Parent.Core.Theme)
local Maid=require(script.Parent.Parent.Utils.Maid)
local Helpers=require(script.Parent.Parent.Utils.Helpers)
local Card={}; Card.__index=Card
function Card.new(section:any,data:any?):any
 data=data or {}; local self=setmetatable({_Section=section,_Data=data,_Maid=Maid.new()},Card); local theme=section.Tab.Window.Library.Theme
 local root=Helpers.CreateFrame({Name=data.Name or "Card",Size=UDim2.new(1,0,0,data.Height or 72),BackgroundColor3=data.BackgroundColor or theme.ElementBackground,BackgroundTransparency=data.BackgroundTransparency or 0.03,Parent=section.Inner}); Helpers.Corner(root,Theme.CornerRadiusSmall)
 local stroke=Helpers.Stroke(root,data.BorderColor or theme.Border,1); stroke.Transparency=0.18
 if data.Icon then local icon=Instance.new("ImageLabel"); icon.Name="Icon"; icon.Size=UDim2.fromOffset(30,30); icon.Position=UDim2.fromOffset(14,14); icon.BackgroundTransparency=1; icon.Image=data.Icon; icon.ImageColor3=data.IconColor or theme.Accent; icon.Parent=root; Helpers.Corner(icon,8) end
 local left=data.Icon and 56 or 14
 local title=Helpers.CreateLabel({Name="Title",Size=UDim2.new(1,-left-14,0,20),Position=UDim2.fromOffset(left,10),Text=tostring(data.Title or "Card"),Font=Theme.FontBold,TextSize=13,TextColor3=theme.Text,Parent=root})
 local content=Helpers.CreateLabel({Name="Content",Size=UDim2.new(1,-left-14,0,32),Position=UDim2.fromOffset(left,32),Text=tostring(data.Content or ""),Font=Theme.Font,TextSize=10,TextColor3=theme.TextMuted,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,Parent=root})
 self.Instance,self.TitleLabel,self.ContentLabel,self._Stroke=root,title,content,stroke
 if data.Callback then self._Maid:GiveTask(root.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then task.spawn(data.Callback,self) end end)) end
 return self
end
function Card:Set(content:string) self.ContentLabel.Text=tostring(content) end
function Card:SetTitle(title:string) self.TitleLabel.Text=tostring(title) end
function Card:RefreshTheme() local theme=self._Section.Tab.Window.Library.Theme; self.Instance.BackgroundColor3=self._Data.BackgroundColor or theme.ElementBackground; self._Stroke.Color=self._Data.BorderColor or theme.Border; self.TitleLabel.TextColor3=theme.Text; self.ContentLabel.TextColor3=theme.TextMuted end
function Card:Destroy() self._Maid:DoCleaning(); if self.Instance and self.Instance.Parent then self.Instance:Destroy() end end
return Card
