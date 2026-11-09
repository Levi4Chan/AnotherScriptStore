--// FORCE TOOL EQUIP GUI
--// Executor-compatible LocalScript

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Remove previous GUI
local OldGUI = PlayerGui:FindFirstChild("ForceToolEquipGUI")
if OldGUI then
    OldGUI:Destroy()
end

-- Settings
local SelectedTool = nil
local ForceEquip = false
local Running = true
local Connections = {}

local function GetCharacter()
    return Player.Character
end

local function GetHumanoid()
    local Character = GetCharacter()
    return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function GetTool()
    local Character = GetCharacter()
    local Backpack = Player:FindFirstChild("Backpack")

    if not SelectedTool then
        return nil
    end

    if Character then
        local Tool = Character:FindFirstChild(SelectedTool)
        if Tool and Tool:IsA("Tool") then
            return Tool
        end
    end

    if Backpack then
        local Tool = Backpack:FindFirstChild(SelectedTool)
        if Tool and Tool:IsA("Tool") then
            return Tool
        end
    end

    return nil
end

local function EquipSelectedTool()
    if not ForceEquip then
        return
    end

    local Humanoid = GetHumanoid()
    local Tool = GetTool()
    local Character = GetCharacter()

    if not Humanoid or not Tool or not Character then
        return
    end

    if Tool.Parent ~= Character then
        Humanoid:EquipTool(Tool)
    end
end

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ForceToolEquipGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(280, 260)
Main.Position = UDim2.new(0.5, -140, 0.5, -130)
Main.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(205, 165, 70)
Stroke.Thickness = 1
Stroke.Parent = Main

local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, -45, 0, 42)
Header.Position = UDim2.fromOffset(14, 0)
Header.BackgroundTransparency = 1
Header.Text = "FORCE TOOL EQUIP"
Header.TextColor3 = Color3.fromRGB(235, 190, 90)
Header.TextSize = 16
Header.Font = Enum.Font.GothamBold
Header.TextXAlignment = Enum.TextXAlignment.Left
Header.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -38, 0, 6)
Close.Text = "−"
Close.TextSize = 22
Close.TextColor3 = Color3.new(1, 1, 1)
Close.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
Close.Parent = Main
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

local Dropdown = Instance.new("TextButton")
Dropdown.Size = UDim2.new(1, -28, 0, 38)
Dropdown.Position = UDim2.fromOffset(14, 55)
Dropdown.BackgroundColor3 = Color3.fromRGB(39, 39, 46)
Dropdown.TextColor3 = Color3.new(1, 1, 1)
Dropdown.Text = "Select Tool  ▼"
Dropdown.TextSize = 13
Dropdown.Font = Enum.Font.Gotham
Dropdown.Parent = Main
Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0, 8)

local ToolList = Instance.new("ScrollingFrame")
ToolList.Size = UDim2.new(1, -28, 0, 105)
ToolList.Position = UDim2.fromOffset(14, 96)
ToolList.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
ToolList.BorderSizePixel = 0
ToolList.ScrollBarThickness = 3
ToolList.Visible = false
ToolList.ZIndex = 5
ToolList.Parent = Main
Instance.new("UICorner", ToolList).CornerRadius = UDim.new(0, 8)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 3)
ListLayout.Parent = ToolList

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -28, 0, 40)
Toggle.Position = UDim2.fromOffset(14, 108)
Toggle.BackgroundColor3 = Color3.fromRGB(80, 42, 42)
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.Text = "Force Equip: OFF"
Toggle.TextSize = 14
Toggle.Font = Enum.Font.GothamBold
Toggle.Parent = Main
Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 8)

local Refresh = Instance.new("TextButton")
Refresh.Size = UDim2.new(1, -28, 0, 36)
Refresh.Position = UDim2.fromOffset(14, 157)
Refresh.BackgroundColor3 = Color3.fromRGB(47, 47, 55)
Refresh.TextColor3 = Color3.new(1, 1, 1)
Refresh.Text = "Refresh Tools"
Refresh.TextSize = 13
Refresh.Font = Enum.Font.Gotham
Refresh.Parent = Main
Instance.new("UICorner", Refresh).CornerRadius = UDim.new(0, 8)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -28, 0, 40)
Status.Position = UDim2.fromOffset(14, 204)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.fromRGB(160, 160, 170)
Status.TextSize = 12
Status.Font = Enum.Font.Gotham
Status.TextWrapped = true
Status.Text = "Select a tool to begin."
Status.Parent = Main

-- Floating show button
local ShowButton = Instance.new("TextButton")
ShowButton.Size = UDim2.fromOffset(54, 40)
ShowButton.Position = UDim2.fromOffset(20, 180)
ShowButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ShowButton.TextColor3 = Color3.fromRGB(235, 190, 90)
ShowButton.Text = "TOOLS"
ShowButton.TextSize = 11
ShowButton.Font = Enum.Font.GothamBold
ShowButton.Visible = false
ShowButton.Parent = ScreenGui
Instance.new("UICorner", ShowButton).CornerRadius = UDim.new(0, 10)

-- Draggable GUI
local function MakeDraggable(Frame, Handle)
    local Dragging = false
    local DragStart
    local StartPosition

    Handle.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then

            Dragging = true
            DragStart = Input.Position
            StartPosition = Frame.Position
        end
    end)

    UIS.InputChanged:Connect(function(Input)
        if Dragging and (
            Input.UserInputType == Enum.UserInputType.MouseMovement
            or Input.UserInputType == Enum.UserInputType.Touch
        ) then
            local Delta = Input.Position - DragStart

            Frame.Position = UDim2.new(
                StartPosition.X.Scale,
                StartPosition.X.Offset + Delta.X,
                StartPosition.Y.Scale,
                StartPosition.Y.Offset + Delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)
end

MakeDraggable(Main, Header)
MakeDraggable(ShowButton, ShowButton)

-- Tool dropdown
local function RefreshTools()
    for _, Child in ipairs(ToolList:GetChildren()) do
        if Child:IsA("TextButton") then
            Child:Destroy()
        end
    end

    local Tools = {}
    local Seen = {}

    local function AddTools(Container)
        if not Container then return end

        for _, Object in ipairs(Container:GetChildren()) do
            if Object:IsA("Tool") and not Seen[Object.Name] then
                Seen[Object.Name] = true
                table.insert(Tools, Object.Name)
            end
        end
    end

    AddTools(Player:FindFirstChild("Backpack"))
    AddTools(GetCharacter())

    table.sort(Tools)

    for _, Name in ipairs(Tools) do
        local Item = Instance.new("TextButton")
        Item.Size = UDim2.new(1, -6, 0, 30)
        Item.BackgroundColor3 = Color3.fromRGB(44, 44, 51)
        Item.TextColor3 = Color3.new(1, 1, 1)
        Item.Text = Name
        Item.TextSize = 12
        Item.Font = Enum.Font.Gotham
        Item.ZIndex = 6
        Item.Parent = ToolList

        Instance.new("UICorner", Item).CornerRadius = UDim.new(0, 6)

        Item.MouseButton1Click:Connect(function()
            SelectedTool = Name
            Dropdown.Text = Name .. "  ▼"
            ToolList.Visible = false
            Status.Text = "Selected: " .. Name

            EquipSelectedTool()
        end)
    end

    ToolList.CanvasSize = UDim2.fromOffset(0, #Tools * 33)

    if #Tools == 0 then
        Status.Text = "No tools found in Backpack or Character."
    end
end

Dropdown.MouseButton1Click:Connect(function()
    if not ToolList.Visible then
        RefreshTools()
    end

    ToolList.Visible = not ToolList.Visible
end)

Refresh.MouseButton1Click:Connect(function()
    RefreshTools()
    Status.Text = "Tool list refreshed."
end)

Toggle.MouseButton1Click:Connect(function()
    if not SelectedTool then
        Status.Text = "Please select a tool first."
        return
    end

    ForceEquip = not ForceEquip

    if ForceEquip then
        Toggle.Text = "Force Equip: ON"
        Toggle.BackgroundColor3 = Color3.fromRGB(42, 105, 72)
        Status.Text = "Keeping " .. SelectedTool .. " equipped."
        EquipSelectedTool()
    else
        Toggle.Text = "Force Equip: OFF"
        Toggle.BackgroundColor3 = Color3.fromRGB(80, 42, 42)
        Status.Text = "Force equip disabled."
    end
end)

Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    ShowButton.Visible = true
end)

ShowButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    ShowButton.Visible = false
end)

-- Automatically re-equip selected tool
task.spawn(function()
    while Running and ScreenGui.Parent do
        if ForceEquip then
            EquipSelectedTool()
        end

        task.wait(0.15)
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(1)
    RefreshTools()
    EquipSelectedTool()
end)

RefreshTools()

print("[FORCE TOOL EQUIP] GUI Loaded!")
