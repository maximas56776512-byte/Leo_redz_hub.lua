-- Services
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LeoHubUI"
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Parent = ScreenGui
Main.Size = UDim2.new(0, 400, 0, 400)
Main.Position = UDim2.new(0.5, -200, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(25,25,25)
Main.BorderSizePixel = 0
TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 400, 0, 400)}):Play()

-- Título
local Title = Instance.new("TextLabel")
Title.Parent = Main
Title.Size = UDim2.new(1,0,0,40)
Title.BackgroundColor3 = Color3.fromRGB(35,35,35)
Title.Text = "LEO HUB"
Title.TextColor3 = Color3.new(1,1,1)
Title.TextSize = 22

-- Botão minimizar
local Minimize = Instance.new("TextButton")
Minimize.Parent = Main
Minimize.Size = UDim2.new(0,40,0,40)
Minimize.Position = UDim2.new(1,-45,0,0)
Minimize.Text = "_"
Minimize.TextColor3 = Color3.new(1,1,1)
Minimize.BackgroundColor3 = Color3.fromRGB(45,45,45)
local minimized = false
Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    local goal = minimized and UDim2.new(0, 200, 0, 40) or UDim2.new(0,400,0,400)
    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = goal}):Play()
end)

-- Container
local Container = Instance.new("Frame")
Container.Parent = Main
Container.Size = UDim2.new(1,0,1,-40)
Container.Position = UDim2.new(0,0,0,40)
Container.BackgroundTransparency = 1

local UIList = Instance.new("UIListLayout")
UIList.Parent = Container
UIList.Padding = UDim.new(0,10)

-- Estados
local speedOn, sp_val = false, 100
local jumpOn, hj_pow = false, 100
local visualOn = false
local fov_on, fov_rad = false, 100
local noclip_on = false
local ammo_on = false
local nearest = nil
local Humanoid, RootPart

-- Pega humanoid/rootpart
local function getchar()
    local c = LP.Character or LP.CharacterAdded:Wait()
    Humanoid = c:WaitForChild("Humanoid")
    RootPart = c:WaitForChild("HumanoidRootPart")
end
getchar()
LP.CharacterAdded:Connect(getchar)

-- Toggle helper
local function CreateToggle(text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = Container
    btn.Size = UDim2.new(0.9,0,0,40)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 18
    btn.Text = text.." [OFF]"
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text..(state and " [ON]" or " [OFF]")
        if callback then callback(state) end
    end)
    return btn
end

-- Slider helper
local function CreateSlider(text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = Container
    frame.Size = UDim2.new(0.9,0,0,40)
    frame.BackgroundColor3 = Color3.fromRGB(45,45,45)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(1,0,0.5,0)
    label.Text = text..": "..default
    label.TextColor3 = Color3.new(1,1,1)
    label.BackgroundTransparency = 1
    label.TextSize = 16

    local slider = Instance.new("TextBox")
    slider.Parent = frame
    slider.Size = UDim2.new(0.9,0,0.5,0)
    slider.Position = UDim2.new(0.05,0,0.5,0)
    slider.Text = tostring(default)
    slider.ClearTextOnFocus = false
    slider.TextColor3 = Color3.new(1,1,1)
    slider.BackgroundColor3 = Color3.fromRGB(35,35,35)

    slider.FocusLost:Connect(function()
        local val = tonumber(slider.Text)
        if val then
            val = math.clamp(val,min,max)
            slider.Text = tostring(val)
            label.Text = text..": "..val
            if callback then callback(val) end
        else
            slider.Text = tostring(default)
        end
    end)
end

-- Criar toggles e sliders
CreateToggle("Super Speed", function(s) speedOn=s end)
CreateToggle("High Jump", function(s) jumpOn=s end)
CreateToggle("Visual ESP", function(s) visualOn=s end)
CreateToggle("Aimbot FOV", function(s) fov_on=s end)
CreateToggle("Noclip", function(s) noclip_on=s end)
CreateToggle("Infinite Ammo", function(s) ammo_on=s end)
CreateToggle("Destroy UI", function() ScreenGui:Destroy() end)
CreateSlider("Speed Power",16,200,100,function(v) sp_val=v end)
CreateSlider("Jump Power",50,200,100,function(v) hj_pow=v end)
CreateSlider("FOV Range",10,300,100,function(v) fov_rad=v end)

-- Calcula ângulo
local function angle(v1,v2)
    return math.deg(math.acos(math.clamp(v1:Dot(v2)/(v1.Magnitude*v2.Magnitude),-1,1)))
end

-- Rainbow ESP
local function rainbowColor(time)
    local hue = (tick()*100)%360/360
    return Color3.fromHSV(hue,1,1)
end

-- Loop principal
RS.RenderStepped:Connect(function()
    -- Super Speed
    if speedOn and Humanoid and RootPart then
        local look = RootPart.CFrame.LookVector
        local vel = Vector3.new(look.X,0,look.Z).Unit * sp_val
        RootPart.Velocity = Vector3.new(vel.X, RootPart.Velocity.Y, vel.Z)
    end

    -- High Jump
    if Humanoid then
        Humanoid.JumpPower = jumpOn and hj_pow or 50
    end

    -- Noclip
    if noclip_on and LP.Character then
        for _, part in ipairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    elseif LP.Character then
        for _, part in ipairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    -- Infinite Ammo genérico
    if ammo_on then
        for _, tool in ipairs(LP.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
                tool.Ammo.Value = tool.Ammo.MaxValue.Value
            end
        end
        if LP.Character then
            for _, tool in ipairs(LP.Character:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
                    tool.Ammo.Value = tool.Ammo.MaxValue.Value
                end
            end
        end
    end

    -- ESP Rainbow
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                if visualOn then
                    local highlight = head:FindFirstChild("ESPHighlight")
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name="ESPHighlight"
                        highlight.Parent = head
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.OutlineColor = Color3.new(1,1,1)
                    end
                    highlight.FillColor = rainbowColor(tick())
                else
                    local highlight = head:FindFirstChild("ESPHighlight")
                    if highlight then highlight:Destroy() end
                end
            end
        end
    end

    -- Aimbot FOV suave
    if fov_on then
        local myHead = LP.Character and LP.Character:
