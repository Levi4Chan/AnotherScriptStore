
--// AUTO SELL + AUTO MEAL GUI
--// Executor Script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ShopRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop")

--// Settings
local Running = true

local Sell = {
    Enabled = false,
    Interval = 1
}

local Meal = {
    Enabled = false,
    Interval = 1
}

--// Cleanup Previous GUI
if PlayerGui:FindFirstChild("ShopAutomationGUI") then
    PlayerGui.ShopAutomationGUI:Destroy()
end

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShopAutomationGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 290, 0, 330)
Main.Position = UDim2.new(0.5, -145, 0.5, -165)
Main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(190, 150, 65)
Stroke.Thickness = 1.2
Stroke.Parent = Main

--// UI Helper
local function CreateLabel(Name, Text, Position, Size, Color, FontSize)
    local Label = Instance.new("TextLabel")
    Label.Name = Name
    Label.Size = Size
    Label.Position = Position
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label.TextColor3 = Color
    Label.TextSize = FontSize or 12
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Main
    return Label
end

local function CreateButton(Name, Text, Position, Size, Color)
    local Button = Instance.new("TextButton")
    Button.Name = Name
    Button.Size = Size
    Button.Position = Position
    Button.BackgroundColor3 = Color
    Button.Text = Text
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 11
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Main

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)

    return Button
end

local function CreateInput(Name, Position)
    local Input = Instance.new("TextBox")
    Input.Name = Name
    Input.Size = UDim2.new(0, 170, 0, 30)
    Input.Position = Position
    Input.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
    Input.TextColor3 = Color3.new(1, 1, 1)
    Input.PlaceholderText = "Seconds"
    Input.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    Input.Text = "1"
    Input.TextSize = 12
    Input.Font = Enum.Font.Gotham
    Input.ClearTextOnFocus = false
    Input.Parent = Main

    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 6)

    return Input
end

--// Header
CreateLabel(
    "Title",
    "SHOP AUTOMATION",
    UDim2.new(0, 12, 0, 7),
    UDim2.new(1, -24, 0, 30),
    Color3.fromRGB(220, 185, 100),
    16
).Font = Enum.Font.GothamBold

--// SELL SECTION
CreateLabel(
    "SellTitle",
    "AUTO SELL",
    UDim2.new(0, 12, 0, 45),
    UDim2.new(1, -24, 0, 20),
    Color3.fromRGB(220, 185, 100),
    12
).Font = Enum.Font.GothamBold

local SellStatus = CreateLabel(
    "SellStatus",
    "Status: Disabled",
    UDim2.new(0, 12, 0, 67),
    UDim2.new(1, -24, 0, 18),
    Color3.fromRGB(170, 170, 170),
    10
)

local SellToggle = CreateButton(
    "SellToggle",
    "ENABLE AUTO SELL",
    UDim2.new(0, 12, 0, 90),
    UDim2.new(1, -24, 0, 32),
    Color3.fromRGB(65, 65, 72)
)

local SellInput = CreateInput(
    "SellInterval",
    UDim2.new(0, 12, 0, 130)
)

local SellApply = CreateButton(
    "SellApply",
    "APPLY",
    UDim2.new(1, -95, 0, 130),
    UDim2.new(0, 83, 0, 30),
    Color3.fromRGB(150, 105, 40)
)

local SellIntervalLabel = CreateLabel(
    "SellIntervalLabel",
    "Interval: 1 second",
    UDim2.new(0, 12, 0, 163),
    UDim2.new(1, -24, 0, 17),
    Color3.fromRGB(150, 150, 150),
    10
)

--// Divider
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -24, 0, 1)
Divider.Position = UDim2.new(0, 12, 0, 188)
Divider.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
Divider.BorderSizePixel = 0
Divider.Parent = Main

--// MEAL SECTION
CreateLabel(
    "MealTitle",
    "AUTO MEAL",
    UDim2.new(0, 12, 0, 198),
    UDim2.new(1, -24, 0, 20),
    Color3.fromRGB(220, 185, 100),
    12
).Font = Enum.Font.GothamBold

local MealStatus = CreateLabel(
    "MealStatus",
    "Status: Disabled",
    UDim2.new(0, 12, 0, 220),
    UDim2.new(1, -24, 0, 18),
    Color3.fromRGB(170, 170, 170),
    10
)

local MealToggle = CreateButton(
    "MealToggle",
    "ENABLE AUTO MEAL",
    UDim2.new(0, 12, 0, 243),
    UDim2.new(1, -24, 0, 32),
    Color3.fromRGB(65, 65, 72)
)

local MealInput = CreateInput(
    "MealInterval",
    UDim2.new(0, 12, 0, 282)
)

local MealApply = CreateButton(
    "MealApply",
    "APPLY",
    UDim2.new(1, -95, 0, 282),
    UDim2.new(0, 83, 0, 30),
    Color3.fromRGB(150, 105, 40)
)

--// Interval Functions
local function ApplyInterval(Config, Input, Label)
    local Value = tonumber(Input.Text)

    if Value and Value >= 0.1 then
        Config.Interval = math.clamp(Value, 0.1, 3600)
        Input.Text = tostring(Config.Interval)
        Label.Text = "Interval: " .. Config.Interval .. " seconds"
        Label.TextColor3 = Color3.fromRGB(100, 220, 130)
    else
        Label.Text = "Invalid interval (minimum 0.1)"
        Label.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end

SellApply.MouseButton1Click:Connect(function()
    ApplyInterval(Sell, SellInput, SellIntervalLabel)
end)

MealApply.MouseButton1Click:Connect(function()
    ApplyInterval(Meal, MealInput, nil)
end)

--// Toggle Functions
local function ToggleAutomation(Config, Button, Status, Name)
    Config.Enabled = not Config.Enabled

    if Config.Enabled then
        Button.Text = "DISABLE " .. Name
        Button.BackgroundColor3 = Color3.fromRGB(150, 105, 40)
        Status.Text = "Status: Running"
        Status.TextColor3 = Color3.fromRGB(100, 220, 130)
    else
        Button.Text = "ENABLE " .. Name
        Button.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
        Status.Text = "Status: Disabled"
        Status.TextColor3 = Color3.fromRGB(170, 170, 170)
    end
end

SellToggle.MouseButton1Click:Connect(function()
    ToggleAutomation(Sell, SellToggle, SellStatus, "AUTO SELL")
end)

MealToggle.MouseButton1Click:Connect(function()
    ToggleAutomation(Meal, MealToggle, MealStatus, "AUTO MEAL")
end)

--// Independent Auto Sell Loop
task.spawn(function()
    while Running and ScreenGui.Parent do
        if Sell.Enabled then
            local Success, Error = pcall(function()
                ShopRemote:InvokeServer("sell", "all")
            end)

            if not Success then
                warn("[Auto Sell]", Error)
                SellStatus.Text = "Status: Error"
                SellStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            end

            task.wait(Sell.Interval)
        else
            task.wait(0.1)
        end
    end
end)

--// Independent Auto Meal Loop
task.spawn(function()
    while Running and ScreenGui.Parent do
        if Meal.Enabled then
            local Success, Error = pcall(function()
                ShopRemote:InvokeServer("meal")
            end)

            if not Success then
                warn("[Auto Meal]", Error)
                MealStatus.Text = "Status: Error"
                MealStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            end

            task.wait(Meal.Interval)
        else
            task.wait(0.1)
        end
    end
end)

--// Draggable GUI
local Dragging = false
local DragInput
local DragStart
local StartPosition

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
        local Delta = Input.Position - DragStart

        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end
end)

--// Unload Button
local Unload = CreateButton(
    "Unload",
    "UNLOAD GUI",
    UDim2.new(0, 12, 1, -40),
    UDim2.new(1, -24, 0, 30),
    Color3.fromRGB(130, 55, 55)
)

Main.Size = UDim2.new(0, 290, 0, 370)

Unload.MouseButton1Click:Connect(function()
    Running = false
    Sell.Enabled = false
    Meal.Enabled = false
    ScreenGui:Destroy()
end)

--// Cleanup
ScreenGui.Destroying:Connect(function()
    Running = false
    Sell.Enabled = false
    Meal.Enabled = false
end)
