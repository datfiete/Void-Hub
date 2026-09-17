--!strict
-- Point-only WorldRadar UI element for developer-owned experiences.
-- Targets may be a Folder/Instance, a list of Instances, or a function returning either.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local WorldRadar = {}
WorldRadar.__index = WorldRadar

local function make(className: string, props: {[string]: any}, parent: Instance): Instance
    local obj = Instance.new(className)
    for k, v in pairs(props) do (obj :: any)[k] = v end
    obj.Parent = parent
    return obj
end

function WorldRadar.new(section: any, data: any)
    local self = setmetatable({ _Connections = {}, _Dots = {}, _Zoom = 1, _Enabled = data.DefaultActive ~= false }, WorldRadar)
    local theme = section.Tab.Window.Library.Theme
    local root = make("Frame", {Name="WorldRadar", Size=UDim2.new(1,0,0,310), BackgroundTransparency=1, LayoutOrder=999}, section.Inner)
    self.Instance = root
    local header = make("Frame", {Name="ObjectHeader", Size=UDim2.new(1,0,0,30), BackgroundTransparency=1}, root)
    make("TextLabel", {Name="ObjectTitle", Size=UDim2.new(1,-100,1,0), BackgroundTransparency=1, Text=data.ObjectLabel or "OBJECTS", Font=Enum.Font.GothamBold, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=theme.Text}, header)
    local active = make("TextButton", {Name="Activate", Size=UDim2.fromOffset(92,26), Position=UDim2.new(1,-92,0,2), BackgroundColor3=theme.SurfaceHover, Text=self._Enabled and "ACTIVE: ON" or "ACTIVE: OFF", TextColor3=theme.Text, Font=Enum.Font.GothamSemibold, TextSize=10, AutoButtonColor=true}, header)
    make("UICorner", {CornerRadius=UDim.new(0,6)}, active)
    local categories = make("Frame", {Name="ObjectList", Size=UDim2.new(1,0,0,28), Position=UDim2.fromOffset(0,32), BackgroundTransparency=1}, root)
    local listLayout=make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,7)}, categories)
    local chestButton=make("TextButton", {Name="ChestsFilter", Size=UDim2.fromOffset(105,26), BackgroundColor3=theme.Accent, Text="✓  Chests", TextColor3=theme.Text, Font=Enum.Font.GothamMedium, TextSize=11, AutoButtonColor=true}, categories)
    make("UICorner", {CornerRadius=UDim.new(0,6)}, chestButton)
    local radar=make("Frame", {Name="PointField", Size=UDim2.new(1,0,0,240), Position=UDim2.fromOffset(0,64), BackgroundColor3=theme.Background or theme.Surface, BackgroundTransparency=0.05, BorderSizePixel=0, ClipsDescendants=true}, root)
    make("UICorner", {CornerRadius=UDim.new(0,10)}, radar)
    local stroke=make("UIStroke", {Color=theme.Border, Transparency=0.2, Thickness=1}, radar)
    -- Reference rings and crosshair provide spatial context without a terrain map.
    for _,scale in {0.35,0.68,1} do
        local ring=make("Frame", {Name="RangeRing", Size=UDim2.fromScale(scale,scale), Position=UDim2.fromScale(0.5,0.5), AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, BorderSizePixel=0}, radar)
        make("UICorner", {CornerRadius=UDim.new(1,0)}, ring)
        make("UIStroke", {Color=theme.Border, Transparency=0.45, Thickness=1}, ring)
    end
    make("Frame", {Name="CrossX", Size=UDim2.new(1,0,0,1), Position=UDim2.fromScale(0,0.5), BackgroundColor3=theme.Border, BackgroundTransparency=0.35, BorderSizePixel=0}, radar)
    make("Frame", {Name="CrossY", Size=UDim2.new(0,1,1,0), Position=UDim2.fromScale(0.5,0), BackgroundColor3=theme.Border, BackgroundTransparency=0.35, BorderSizePixel=0}, radar)
    local playerDot=make("Frame", {Name="You", Size=UDim2.fromOffset(10,10), Position=UDim2.fromScale(0.5,0.5), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=theme.Accent, BorderSizePixel=0, ZIndex=5}, radar)
    make("UICorner", {CornerRadius=UDim.new(1,0)}, playerDot)
    local zoomOut=make("TextButton", {Name="ZoomOut", Size=UDim2.fromOffset(28,28), Position=UDim2.new(1,-64,0,8), BackgroundColor3=theme.Surface, Text="−", TextColor3=theme.Text, Font=Enum.Font.GothamBold, TextSize=18, ZIndex=8}, radar)
    local zoomIn=make("TextButton", {Name="ZoomIn", Size=UDim2.fromOffset(28,28), Position=UDim2.new(1,-32,0,8), BackgroundColor3=theme.Surface, Text="+", TextColor3=theme.Text, Font=Enum.Font.GothamBold, TextSize=18, ZIndex=8}, radar)
    for _,b in {zoomIn,zoomOut} do make("UICorner", {CornerRadius=UDim.new(0,6)}, b) end
    local status=make("TextLabel", {Name="Status", Size=UDim2.new(1,-16,0,16), Position=UDim2.new(0,8,1,-20), BackgroundTransparency=1, Text="0 targets · range 250", TextColor3=theme.TextMuted, Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7}, radar)
    local chestEnabled=true
    local function getTargets()
        local source=data.Targets
        if type(source)=="function" then local ok,v=pcall(source); if ok then source=v else return {} end end
        if typeof(source)=="Instance" then return source:GetChildren() end
        if type(source)=="table" then return source end
        local folder=workspace:FindFirstChild(data.FolderName or "Chests")
        return folder and folder:GetChildren() or {}
    end
    local function clearDots()
        for inst,dot in pairs(self._Dots) do if dot and dot.Parent then dot:Destroy() end; self._Dots[inst]=nil end
    end
    local function update()
        local lp=Players.LocalPlayer; local char=lp and lp.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not self._Enabled or not chestEnabled or not hrp then clearDots(); status.Text="Radar paused"; return end
        local targets=getTargets(); local alive={}; local count=0
        local range=(data.Range or 250)/self._Zoom
        local field=radar.AbsoluteSize; local radius=math.max(1,math.min(field.X,field.Y)*0.46)
        for _,target in ipairs(targets) do
            if typeof(target)=="Instance" and target~=char and target:IsDescendantOf(workspace) then
                local part=target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart",true)
                if part then
                    alive[target]=true; count+=1
                    local delta=part.Position-hrp.Position
                    local dx,dz=delta.X,delta.Z
                    local dist=math.sqrt(dx*dx+dz*dz)
                    local scale=math.min(dist/range,1)
                    local px=dx/math.max(dist,0.001)*scale*radius
                    local py=dz/math.max(dist,0.001)*scale*radius
                    local dot=self._Dots[target]
                    if not dot or not dot.Parent then
                        dot=make("Frame", {Name="TargetDot", Size=UDim2.fromOffset(7,7), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=data.DotColor or Color3.fromRGB(255,95,110), BorderSizePixel=0, ZIndex=6}, radar)
                        make("UICorner", {CornerRadius=UDim.new(1,0)}, dot); self._Dots[target]=dot
                    end
                    dot.Position=UDim2.new(0.5,px,0.5,py)
                    dot.Visible=dist<=range
                end
            end
        end
        for inst,dot in pairs(self._Dots) do if not alive[inst] then if dot then dot:Destroy() end; self._Dots[inst]=nil end end
        status.Text=string.format("%d targets · range %d",count,math.floor(range))
    end
    table.insert(self._Connections, active.Activated:Connect(function() self._Enabled=not self._Enabled; active.Text=self._Enabled and "ACTIVE: ON" or "ACTIVE: OFF"; active.BackgroundColor3=self._Enabled and theme.Accent or theme.SurfaceHover; update() end))
    table.insert(self._Connections, chestButton.Activated:Connect(function() chestEnabled=not chestEnabled; chestButton.Text=(chestEnabled and "✓  " or "□  ").."Chests"; chestButton.BackgroundColor3=chestEnabled and theme.Accent or theme.SurfaceHover; update() end))
    table.insert(self._Connections, zoomIn.Activated:Connect(function() self._Zoom=math.max(0.5,self._Zoom/1.25); update() end))
    table.insert(self._Connections, zoomOut.Activated:Connect(function() self._Zoom=math.min(8,self._Zoom*1.25); update() end))
    table.insert(self._Connections, RunService.Heartbeat:Connect(update))
    self._Maid=nil
    function self:Destroy()
        for _,c in ipairs(self._Connections) do pcall(function() c:Disconnect() end) end
        clearDots(); if root and root.Parent then root:Destroy() end
    end
    function self:RefreshTheme() end
    return self
end
return WorldRadar
