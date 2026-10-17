--!strict
local Theme=require(script.Parent.Parent.Core.Theme)
local Maid=require(script.Parent.Parent.Utils.Maid)
local Helpers=require(script.Parent.Parent.Utils.Helpers)
local Tween=require(script.Parent.Parent.Utils.Tween)
local Progress={}; Progress.__index=Progress
function Progress.new(section:any,data:any?):any
 data=data or {}; local self=setmetatable({_Section=section,_Data=data,_Maid=Maid.new(),_Value=0},Progress); local theme=section.Tab.Window.Library.Theme
 local root=Helpers.CreateFrame({Name=data.Name or "Progress",Size=UDim2.new(1,0,0,data.Height or 56),BackgroundTransparency=1,Parent=section.Inner})
 local label=Helpers.CreateLabel({Name="Label",Size=UDim2.new(1,-70,0,18),Text=tostring(data.Title or "Progress"),Font=Theme.FontBold,TextSize=11,TextColor3=theme.Text,Parent=root})
 local value=Helpers.CreateLabel({Name="Value",Size=UDim2.fromOffset(62,18),Position=UDim2.new(1,-62,0,0),Text="0%",Font=Theme.FontBold,TextSize=10,TextColor3=data.Color or theme.Accent,TextXAlignment=Enum.TextXAlignment.Right,Parent=root})
 local track=Helpers.CreateFrame({Name="Track",Size=UDim2.new(1,0,0,8),Position=UDim2.fromOffset(0,30),BackgroundColor3=theme.Background,Parent=root}); Helpers.Corner(track,4); local fill=Helpers.CreateFrame({Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=data.Color or theme.Accent,Parent=track}); Helpers.Corner(fill,4)
 self.Instance,self.Label,self.ValueLabel,self.Fill=root,label,value,fill
 function self:Set(v:number) v=math.clamp(tonumber(v) or 0,0,1); self._Value=v; self.ValueLabel.Text=tostring(math.floor(v*100+0.5)).."%"; Tween.Play(self.Fill,{Size=UDim2.fromScale(v,1)},{Time=0.25}) end
 self:Set(data.CurrentValue or 0); return self
end
function Progress:Get() return self._Value end
function Progress:RefreshTheme() local theme=self._Section.Tab.Window.Library.Theme; self.Label.TextColor3=theme.Text; self.ValueLabel.TextColor3=self._Data.Color or theme.Accent; self.Fill.BackgroundColor3=self._Data.Color or theme.Accent end
function Progress:Destroy() self._Maid:DoCleaning(); if self.Instance and self.Instance.Parent then self.Instance:Destroy() end end
return Progress
