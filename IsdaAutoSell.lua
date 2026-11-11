
--// Auto Sell GUI
--// Executor Script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local ShopRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop")

--// Settings
local AutoSell = false
local SellInterval = 10

--// Prevent duplicate GUIs
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("AutoSellGUI") then
    PlayerGui.AutoSellGUI:Destroy()
end

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoSellGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 155)
Main.Position = UDim2.new(0.5, -130, 0.5, -77)
Main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

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
Status.Size = UDim2.new(1, -20, 0, 25)
Status.Position = UDim2.new(0, 10, 0, 43)
Status.BackgroundTransparency = 1
Status.Text = "Status: Disabled"
Status.TextColor3 = Color3.fromRGB(180, 180, 180)
Status.TextSize = 12
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

--// Toggle Button
local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -20, 0, 38)
Toggle.Position = UDim2.new(0, 10, 0, 75)
Toggle.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
Toggle.Text = "ENABLE AUTO SELL"
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.TextSize = 12
Toggle.Font = Enum.Font.GothamBold
Toggle.AutoButtonColor = true
Toggle.Parent = Main

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 7)
ToggleCorner.Parent = Toggle

--// Interval
local IntervalLabel = Instance.new("TextLabel")
IntervalLabel.Size = UDim2.new(1, -20, 0, 20)
IntervalLabel.Position = UDim2.new(0, 10, 0, 120)
IntervalLabel.BackgroundTransparency = 1
IntervalLabel.Text = "Interval: 1 second"
IntervalLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
IntervalLabel.TextSize = 11
IntervalLabel.Font = Enum.Font.Gotham
IntervalLabel.TextXAlignment = Enum.TextXAlignment.Left
IntervalLabel.Parent = Main

--// Toggle Logic
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
    while ScreenGui.Parent do
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

--// Draggable GUI
local UserInputService = game:GetService("UserInputService")

local Dragging = false
local DragStart
local StartPosition

Main.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = Input.Position
        StartPosition = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(Input)
    if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
        local Delta = Input.Position - DragStart

        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)
