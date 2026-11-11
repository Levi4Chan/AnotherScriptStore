
--// AUTO SELL GUI
--// Executor Script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ShopRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop")

--// Settings
local AutoSell = false
local SellInterval = 1
local Running = true

--// Cleanup previous GUI
if PlayerGui:FindFirstChild("AutoSellGUI") then
    PlayerGui.AutoSellGUI:Destroy()
end

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoSellGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 270, 0, 205)
Main.Position = UDim2.new(0.5, -135, 0.5, -102)
Main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(190, 150, 65)
Stroke.Thickness = 1.2
Stroke.Parent = Main

--// Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "AUTO SELL"
Title.TextColor3 = Color3.fromRGB(220, 185, 100)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

--// Status
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 20)
Status.Position = UDim2.new(0, 10, 0, 40)
Status.BackgroundTransparency = 1
Status.Text = "Status: Disabled"
Status.TextColor3 = Color3.fromRGB(180, 180, 180)
Status.TextSize = 12
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

--// Toggle
local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -20, 0, 35)
Toggle.Position = UDim2.new(0, 10, 0, 65)
Toggle.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
Toggle.Text = "ENABLE AUTO SELL"
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.TextSize = 12
Toggle.Font = Enum.Font.GothamBold
Toggle.Parent = Main

Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 7)

--// Interval Label
local IntervalLabel = Instance.new("TextLabel")
IntervalLabel.Size = UDim2.new(1, -20, 0, 20)
IntervalLabel.Position = UDim2.new(0, 10, 0, 110)
IntervalLabel.BackgroundTransparency = 1
IntervalLabel.Text = "Interval (seconds)"
IntervalLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
IntervalLabel.TextSize = 11
IntervalLabel.Font = Enum.Font.Gotham
IntervalLabel.TextXAlignment = Enum.TextXAlignment.Left
IntervalLabel.Parent = Main

--// Interval Input
local IntervalInput = Instance.new("TextBox")
IntervalInput.Size = UDim2.new(0, 155, 0, 32)
IntervalInput.Position = UDim2.new(0, 10, 0, 135)
IntervalInput.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
IntervalInput.Text = tostring(SellInterval)
IntervalInput.PlaceholderText = "Enter seconds"
IntervalInput.TextColor3 = Color3.new(1, 1, 1)
IntervalInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
IntervalInput.TextSize = 12
IntervalInput.Font = Enum.Font.Gotham
IntervalInput.ClearTextOnFocus = false
IntervalInput.Parent = Main

Instance.new("UICorner", IntervalInput).CornerRadius = UDim.new(0, 6)

--// Apply Button
local Apply = Instance.new("TextButton")
Apply.Size = UDim2.new(0, 85, 0, 32)
Apply.Position = UDim2.new(1, -95, 0, 135)
Apply.BackgroundColor3 = Color3.fromRGB(150, 105, 40)
Apply.Text = "APPLY"
Apply.TextColor3 = Color3.new(1, 1, 1)
Apply.TextSize = 11
Apply.Font = Enum.Font.GothamBold
Apply.Parent = Main

Instance.new("UICorner", Apply).CornerRadius = UDim.new(0, 6)

--// Interval Status
local CurrentInterval = Instance.new("TextLabel")
CurrentInterval.Size = UDim2.new(1, -20, 0, 20)
CurrentInterval.Position = UDim2.new(0, 10, 0, 173)
CurrentInterval.BackgroundTransparency = 1
CurrentInterval.Text = "Current interval: 1 second"
CurrentInterval.TextColor3 = Color3.fromRGB(150, 150, 150)
CurrentInterval.TextSize = 10
CurrentInterval.Font = Enum.Font.Gotham
CurrentInterval.TextXAlignment = Enum.TextXAlignment.Left
CurrentInterval.Parent = Main

--// Apply Interval
Apply.MouseButton1Click:Connect(function()
    local Value = tonumber(IntervalInput.Text)

    if Value and Value >= 0.1 then
        SellInterval = math.clamp(Value, 0.1, 3600)

        IntervalInput.Text = tostring(SellInterval)
        CurrentInterval.Text = "Current interval: " .. SellInterval .. " seconds"
        CurrentInterval.TextColor3 = Color3.fromRGB(100, 220, 130)
    else
        CurrentInterval.Text = "Invalid! Minimum: 0.1 seconds"
        CurrentInterval.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)

--// Toggle Auto Sell
Toggle.MouseButton1Click:Connect(function()
    AutoSell = not AutoSell

    if AutoSell then
        Toggle.Text = "DISABLE AUTO SELL"
        Toggle.BackgroundColor3 = Color3.fromRGB(150, 105, 40)
        Status.Text = "Status: Running"
        Status.TextColor3 = Color3.fromRGB(100, 220, 130)
    else
        Toggle.Text = "ENABLE AUTO SELL"
        Toggle.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
        Status.Text = "Status: Disabled"
        Status.TextColor3 = Color3.fromRGB(180, 180, 180)
    end
end)

--// Auto Sell Loop
task.spawn(function()
    while Running and ScreenGui.Parent do
        if AutoSell then
            local Success, Error = pcall(function()
                ShopRemote:InvokeServer("sell", "all")
            end)

            if not Success then
                warn("[Auto Sell] Error:", Error)
                Status.Text = "Status: Error"
                Status.TextColor3 = Color3.fromRGB(255, 80, 80)
            end

            task.wait(SellInterval)
        else
            task.wait(0.1)
        end
    end
end)

--// Draggable GUI (Mouse + Touch)
local Dragging = false
local DragInput
local DragStart
local StartPosition

local function UpdateDrag(Input)
    local Delta = Input.Position - DragStart

    Main.Position = UDim2.new(
        StartPosition.X.Scale,
        StartPosition.X.Offset + Delta.X,
        StartPosition.Y.Scale,
        StartPosition.Y.Offset + Delta.Y
    )
end

Main.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = Input.Position
        StartPosition = Main.Position

        Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

Main.InputChanged:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseMovement
        or Input.UserInputType == Enum.UserInputType.Touch then
        DragInput = Input
    end
end)

UserInputService.InputChanged:Connect(function(Input)
    if Dragging and Input == DragInput then
        UpdateDrag(Input)
    end
end)

--// Cleanup
ScreenGui.Destroying:Connect(function()
    Running = false
    AutoSell = false
end)
