--!strict
local Theme=require(script.Parent.Theme)
local Helpers=require(script.Parent.Parent.Utils.Helpers)
local Tween=require(script.Parent.Parent.Utils.Tween)
local Players=game:GetService("Players")

local LayoutVariants={}; LayoutVariants.__index=LayoutVariants
local SWATCHES={
 Combat=Color3.fromRGB(242,82,82), Movement=Color3.fromRGB(74,210,93), Render=Color3.fromRGB(74,205,214), World=Color3.fromRGB(244,183,40), Utility=Color3.fromRGB(177,104,255),
}
local function clean(name:string):string
 local s=name:gsub("^[%s%c]+",""); s=s:gsub("^⚙️ ",""); s=s:gsub("^⚙ ",""); return s
end
local function setCorner(inst:Instance,r:number)
 for _,c in inst:GetChildren() do if c:IsA("UICorner") then c.CornerRadius=UDim.new(0,r) end end
end
function LayoutVariants.new(window:any,initial:string):any
 local self=setmetatable({_Window=window,_Mode="Vaxorin",_Maid=require(script.Parent.Parent.Utils.Maid).new(),_AltGui=nil,_Root=nil,_Header=nil,_PageHost=nil,_TabBar=nil,_TabButtons={},_ClassicPanels=nil,_Hotbar=nil,_PlayerCard=nil,_Original={}},LayoutVariants)
 self:_build(); self:SyncTabs(); self:SetMode(initial or "Vaxorin"); return self
end
function LayoutVariants:_build()
 local w=self._Window; local parent=w._TopGuiParent or w.Gui.Parent
 local gui=Instance.new("ScreenGui"); gui.Name="VaxorinInterfaceVariants"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.DisplayOrder=2147483646; gui.Enabled=false; gui.Parent=parent; self._AltGui=gui
 local root=Helpers.CreateFrame({Name="Root",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(8,9,12),BackgroundTransparency=0.08,Parent=gui}); root.ZIndex=1; self._Root=root
 local dim=Helpers.CreateFrame({Name="Dim",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.25,Parent=root}); dim.ZIndex=0
 local top=Helpers.CreateFrame({Name="Header",Size=UDim2.new(1,0,0,42),BackgroundColor3=Color3.fromRGB(17,18,22),BackgroundTransparency=0.05,Parent=root}); Helpers.Stroke(top,Color3.fromRGB(62,65,72),1); self._Header=top
 local brand=Helpers.CreateLabel({Name="Brand",Size=UDim2.new(0,300,1,0),Position=UDim2.fromOffset(14,0),Text="REORDER CATEGORIES",Font=Theme.FontBold,TextSize=11,TextColor3=Color3.fromRGB(235,235,235),Parent=top})
 local center=Helpers.CreateLabel({Name="Title",Size=UDim2.fromOffset(240,1),Position=UDim2.new(0.5,-120,0,0),Text="HACKS",Font=Theme.FontBold,TextSize=11,TextColor3=Color3.fromRGB(235,235,235),TextXAlignment=Enum.TextXAlignment.Center,Parent=top})
 local mode=Helpers.CreateLabel({Name="Mode",Size=UDim2.fromOffset(160,1),Position=UDim2.new(1,-190,0,0),Text="VAXORIN",Font=Theme.FontBold,TextSize=9,TextColor3=Color3.fromRGB(155,160,169),TextXAlignment=Enum.TextXAlignment.Right,Parent=top}); self._ModeLabel=mode
 local close=Helpers.CreateButton({Name="Close",Size=UDim2.fromOffset(32,28),Position=UDim2.new(1,-40,0,7),Text="×",Font=Theme.FontBold,TextSize=18,TextColor3=Color3.fromRGB(220,220,220),BackgroundColor3=Color3.fromRGB(28,30,35),AutoButtonColor=false,Parent=top}); Helpers.Corner(close,5); close.MouseButton1Click:Connect(function() w:SetVisible(false) end)
 local tabs=Helpers.CreateFrame({Name="TabBar",Size=UDim2.new(1,-20,0,34),Position=UDim2.fromOffset(10,48),BackgroundTransparency=1,Parent=root}); self._TabBar=tabs
 local tabLayout=Helpers.ListLayout(tabs,8,true,Enum.FillDirection.Horizontal); tabLayout.VerticalAlignment=Enum.VerticalAlignment.Center
 local host=Instance.new("Frame"); host.Name="PageHost"; host.Size=UDim2.new(1,-20,1,-92); host.Position=UDim2.fromOffset(10,88); host.BackgroundTransparency=1; host.ClipsDescendants=true; host.Parent=root; self._PageHost=host
 local classic=Helpers.CreateFrame({Name="ClassicBackdrop",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false,Parent=root}); classic.ZIndex=2; self._ClassicPanels=classic
 local cHint=Helpers.CreateLabel({Name="ClassicHint",Size=UDim2.new(1,-20,0,18),Position=UDim2.fromOffset(10,host.AbsoluteSize.Y+host.Position.Y.Offset+2),Text="CLICK A CATEGORY  •  ARROWS / TAB TO NAVIGATE  •  RIGHT CONTROL TO TOGGLE",Font=Theme.FontBold,TextSize=8,TextColor3=Color3.fromRGB(125,130,138),Parent=root}); cHint.Visible=false; self._ClassicHint=cHint
 local playerCard=Helpers.CreateFrame({Name="PlayerCard",Size=UDim2.fromOffset(170,122),Position=UDim2.fromOffset(10,10),BackgroundColor3=Color3.fromRGB(25,27,31),Parent=root}); Helpers.Stroke(playerCard,Color3.fromRGB(78,81,88),1); Helpers.Corner(playerCard,4); playerCard.ZIndex=4; self._PlayerCard=playerCard
 local avatar=Instance.new("ImageLabel"); avatar.Name="Face"; avatar.Size=UDim2.fromOffset(70,70); avatar.Position=UDim2.fromOffset(10,10); avatar.BackgroundColor3=Color3.fromRGB(43,45,50); avatar.BackgroundTransparency=0; avatar.Image=""; avatar.ScaleType=Enum.ScaleType.Crop; avatar.Parent=playerCard; avatar.ZIndex=5; Helpers.Corner(avatar,2); Helpers.Stroke(avatar,Color3.fromRGB(100,102,110),1)
 task.spawn(function() local ok,img=pcall(function() return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end); if ok and avatar.Parent then avatar.Image=img end end)
 Helpers.CreateLabel({Name="Player",Size=UDim2.fromOffset(78,18),Position=UDim2.fromOffset(88,12),Text=Players.LocalPlayer.Name,Font=Theme.FontBold,TextSize=10,TextColor3=Color3.fromRGB(238,238,238),TextTruncate=Enum.TextTruncate.AtEnd,Parent=playerCard})
 Helpers.CreateLabel({Name="Variant",Size=UDim2.fromOffset(78,34),Position=UDim2.fromOffset(88,34),Text="INVENTORY SKIN\nREADY",Font=Theme.FontBold,TextSize=8,TextColor3=Color3.fromRGB(160,165,174),Parent=playerCard})
 local hotbar=Helpers.CreateFrame({Name="Hotbar",Size=UDim2.new(1,-360,0,56),Position=UDim2.new(0.5,0,1,-12),AnchorPoint=Vector2.new(0.5,1),BackgroundTransparency=1,Parent=root}); self._Hotbar=hotbar; local hl=Helpers.ListLayout(hotbar,4,true,Enum.FillDirection.Horizontal); hl.HorizontalAlignment=Enum.HorizontalAlignment.Center; hl.VerticalAlignment=Enum.VerticalAlignment.Center
 for i=1,9 do local slot=Helpers.CreateFrame({Name="Slot"..i,Size=UDim2.fromOffset(44,44),BackgroundColor3=Color3.fromRGB(48,50,55),Parent=hotbar}); Helpers.Stroke(slot,i==1 and Color3.fromRGB(222,222,222) or Color3.fromRGB(85,87,93),1); Helpers.Corner(slot,2); local n=Helpers.CreateLabel({Name="Number",Size=UDim2.fromOffset(14,14),Position=UDim2.fromOffset(4,2),Text=tostring(i),Font=Theme.FontBold,TextSize=8,TextColor3=Color3.fromRGB(185,185,185),Parent=slot}); local item=Helpers.CreateLabel({Name="Item",Size=UDim2.new(1,-8,0,18),Position=UDim2.fromOffset(4,19),Text=(i==1 and "SWORD" or ""),Font=Theme.FontBold,TextSize=7,TextColor3=Color3.fromRGB(230,230,230),TextXAlignment=Enum.TextXAlignment.Center,Parent=slot) end
end
function LayoutVariants:SyncTabs()
 local w=self._Window; if not self._TabBar then return end
 for _,b in pairs(self._TabButtons) do if b and b.Parent then b:Destroy() end end; self._TabButtons={}; local count=#w._Tabs
 for index,tab in ipairs(w._Tabs) do
  local color=SWATCHES[clean(tab._Name)] or (Theme.AccentAlt or Theme.Accent)
  local b=Helpers.CreateButton({Name="AltTab"..index,Size=UDim2.new(1/math.max(1,math.min(count,5)),-6,0,34),Text=clean(tab._Name),Font=Theme.FontBold,TextSize=9,TextColor3=Color3.fromRGB(220,220,220),BackgroundColor3=Color3.fromRGB(30,32,37),AutoButtonColor=false,Parent=self._TabBar}); Helpers.Stroke(b,color,1); Helpers.Corner(b,self._Mode=="Classic" and 0 or 4); self._TabButtons[tab]=b
  b.MouseButton1Click:Connect(function() w:_selectTab(tab) end); b.MouseEnter:Connect(function() Tween.Play(b,{BackgroundColor3=Color3.fromRGB(48,50,56)},{Time=0.08}) end); b.MouseLeave:Connect(function() Tween.Play(b,{BackgroundColor3=Color3.fromRGB(30,32,37)},{Time=0.08}) end)
 end
 self:_refreshTabState()
end
function LayoutVariants:_refreshTabState()
 for tab,b in pairs(self._TabButtons) do if b and b.Parent then local color=SWATCHES[clean(tab._Name)] or (Theme.AccentAlt or Theme.Accent); b.BackgroundColor3=tab==self._Window._ActiveTab and color or Color3.fromRGB(30,32,37); b.TextColor3=tab==self._Window._ActiveTab and Color3.new(1,1,1) or Color3.fromRGB(215,215,215) end end
end
function LayoutVariants:_movePagesToHost()
 local w=self._Window; for _,tab in ipairs(w._Tabs) do local p=tab.Page; if p and p.Parent~=self._PageHost then p.Parent=self._PageHost end; p.Position=UDim2.fromScale(0,0); p.Size=UDim2.fromScale(1,1) end
end
function LayoutVariants:_restorePages()
 local w=self._Window; for _,tab in ipairs(w._Tabs) do local p=tab.Page; if p and p.Parent==self._PageHost then p.Parent=w.Pages end end
end
function LayoutVariants:_remember(obj:Instance,key:string,value:any)
 if not self._Original[obj] then self._Original[obj]={} end
 if self._Original[obj][key]==nil then self._Original[obj][key]=value end
end
function LayoutVariants:_restoreSkin()
 for obj,props in pairs(self._Original) do
  if typeof(obj)=="Instance" and obj.Parent then
   for key,value in pairs(props) do pcall(function() (obj :: any)[key]=value end) end
  end
 end
 table.clear(self._Original)
end
function LayoutVariants:_classicSkin(enabled:boolean,mc:boolean)
 local w=self._Window
 if not enabled then self:_restoreSkin(); return end
 for _,tab in ipairs(w._Tabs) do local page=tab.Page; self:_remember(page,"ScrollBarThickness",page.ScrollBarThickness); page.ScrollBarThickness=2; local header=page:FindFirstChild("PageHeader"); if header then self:_remember(header,"Visible",header.Visible); header.Visible=false end
  for _,obj in ipairs(page:GetDescendants()) do
   if obj:IsA("UICorner") then self:_remember(obj,"CornerRadius",obj.CornerRadius); obj.CornerRadius=UDim.new(0,mc and 3 or 0) end
   if obj:IsA("UIStroke") then self:_remember(obj,"Color",obj.Color); obj.Color=Color3.fromRGB(85,87,93) end
   if obj:IsA("TextLabel") then self:_remember(obj,"TextColor3",obj.TextColor3); obj.TextColor3=Color3.fromRGB(225,225,225) end
   if obj:IsA("TextButton") or obj:IsA("TextBox") then self:_remember(obj,"BackgroundColor3",obj.BackgroundColor3); self:_remember(obj,"TextColor3",obj.TextColor3); obj.BackgroundColor3=Color3.fromRGB(72,73,76); obj.TextColor3=Color3.fromRGB(236,236,236) end
   if obj:IsA("Frame") and (obj.Name=="Inner" or obj.Name=="Header") then self:_remember(obj,"BackgroundColor3",obj.BackgroundColor3); obj.BackgroundColor3=Color3.fromRGB(26,28,31) end
  end
 end
end
function LayoutVariants:SetMode(mode:string)
 mode=({Vaxorin="Vaxorin",Classic="Classic",Minecraft="Minecraft"})[mode] or "Vaxorin"; self._Mode=mode; local w=self._Window
 if mode=="Vaxorin" then
  self._AltGui.Enabled=false; self:_restorePages(); if w.Main then w.Main.Visible=w._StartupComplete and w._Visible end; if w.TopBar then w.TopBar.Visible=true end; if w.Sidebar then w.Sidebar.Visible=true end; if w.Pages then w.Pages.Visible=true end; self:_classicSkin(false,false); return
 end
 w._Minimized=false; if w.Main then w.Main.Visible=false end; self._AltGui.Enabled=w._Visible
 self:_movePagesToHost(); self._TabBar.Visible=true; self._ClassicHint.Visible=mode=="Classic"; self._PlayerCard.Visible=mode=="Minecraft"; self._Hotbar.Visible=mode=="Minecraft"
 self._ModeLabel.Text=string.upper(mode); self._Root.BackgroundTransparency=mode=="Classic" and 0.22 or 0.08
 self:_classicSkin(true,mode=="Minecraft"); self:_refreshTabState()
end
function LayoutVariants:SetVisible(visible:boolean)
 self._AltGui.Enabled=visible and self._Mode~="Vaxorin"; if visible and self._Mode=="Vaxorin" and self._Window.Main then self._Window.Main.Visible=self._Window._StartupComplete end end
function LayoutVariants:RefreshTheme() self:_refreshTabState() end
function LayoutVariants:Destroy() if self._Maid then self._Maid:DoCleaning() end; if self._AltGui and self._AltGui.Parent then self._AltGui:Destroy() end end
return LayoutVariants
