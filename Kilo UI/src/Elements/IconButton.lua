--!strict
local Theme=require(script.Parent.Parent.Core.Theme)
local Maid=require(script.Parent.Parent.Utils.Maid)
local Helpers=require(script.Parent.Parent.Utils.Helpers)
local Tween=require(script.Parent.Parent.Utils.Tween)
local IconButton={}; IconButton.__index=IconButton
function IconButton.new(section:any,data:any?):any
 data=data or {}; local self=setmetatable({_Section=section,_Data=data,_Maid=Maid.new()},IconButton); local theme=section.Tab.Window.Library.Theme
 local root=Helpers.CreateButton({Name=data.Name or "IconButton",Size=UDim2.new(1,0,0,data.Height or 42),Text="",BackgroundColor3=theme.ElementBackground,TextColor3=theme.Text,AutoButtonColor=false,Parent=section.Inner}); Helpers.Corner(root,Theme.CornerRadiusSmall); local stroke=Helpers.Stroke(root,theme.Border,1)
 if data.Icon then local icon=Instance.new("ImageLabel"); icon.Name="Icon"; icon.Size=UDim2.fromOffset(18,18); icon.Position=UDim2.fromOffset(12,12); icon.BackgroundTransparency=1; icon.Image=data.Icon; icon.ImageColor3=theme.Accent; icon.Parent=root end
 local text=Helpers.CreateLabel({Name="Label",Size=UDim2.new(1,-42,1,0),Position=UDim2.fromOffset(data.Icon and 38 or 12,0),Text=tostring(data.Text or data.Name or "Action"),Font=Theme.FontBold,TextSize=10,TextColor3=theme.Text,Parent=root})
 self.Instance,self.Label,self._Stroke=root,text,stroke; self._Maid:GiveTask(root.MouseEnter:Connect(function() Tween.Play(root,{BackgroundColor3=theme.ElementHover},{Time=0.1}) end)); self._Maid:GiveTask(root.MouseLeave:Connect(function() Tween.Play(root,{BackgroundColor3=theme.ElementBackground},{Time=0.1}) end)); self._Maid:GiveTask(root.MouseButton1Click:Connect(function() if section.Tab.Window._PlayClick then section.Tab.Window._PlayClick() end; if data.Callback then task.spawn(data.Callback,self) end end)); return self end
function IconButton:SetText(text:string) self.Label.Text=tostring(text) end
function IconButton:RefreshTheme() local theme=self._Section.Tab.Window.Library.Theme; self.Instance.BackgroundColor3=theme.ElementBackground; self.Label.TextColor3=theme.Text; self._Stroke.Color=theme.Border; local icon=self.Instance:FindFirstChild("Icon"); if icon and icon:IsA("ImageLabel") then icon.ImageColor3=theme.Accent end end
function IconButton:Destroy() self._Maid:DoCleaning(); if self.Instance and self.Instance.Parent then self.Instance:Destroy() end end
return IconButton
