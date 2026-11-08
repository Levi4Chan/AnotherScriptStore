--// GOTO MODEL GUI
--// LocalScript / Client-side

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    Offset = Vector3.new(0, 5, 0),
    PromptDelay = 0.3,
}

-- Remove previous GUI
if PlayerGui:FindFirstChild("GotoModelGUI") then
    PlayerGui.GotoModelGUI:Destroy()
end

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GotoModelGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(330, 230)
Main.Position = UDim2.new(0.5, -165, 0.5, -115)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(65, 65, 75)
Stroke.Transparency = 0.4
Stroke.Parent = Main

--// Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = Color3.fromRGB(29, 29, 36)
Header.BorderSizePixel = 0
Header.Parent = Main

Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "  GOTO MODEL"
Title.TextColor3 = Color3.fromRGB(235, 235, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(32, 32)
Close.Position = UDim2.new(1, -40, 0, 8)
Close.BackgroundColor3 = Color3.fromRGB(190, 55, 65)
Close.Text = "×"
Close.TextColor3 = Color3.new(1, 1, 1)
Close.TextSize = 20
Close.Font = Enum.Font.GothamBold
Close.Parent = Header

Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

--// Input Label
local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, -30, 0, 20)
Label.Position = UDim2.fromOffset(15, 62)
Label.BackgroundTransparency = 1
Label.Text = "MODEL NAME"
Label.TextColor3 = Color3.fromRGB(150, 150, 165)
Label.Font = Enum.Font.GothamBold
Label.TextSize = 10
Label.TextXAlignment = Enum.TextXAlignment.Left
Label.Parent = Main

--// Model Input
local Input = Instance.new("TextBox")
Input.Size = UDim2.new(1, -30, 0, 38)
Input.Position = UDim2.fromOffset(15, 87)
Input.BackgroundColor3 = Color3.fromRGB(35, 35, 43)
Input.PlaceholderText = "Enter model name..."
Input.PlaceholderColor3 = Color3.fromRGB(115, 115, 130)
Input.Text = ""
Input.TextColor3 = Color3.new(1, 1, 1)
Input.Font = Enum.Font.Gotham
Input.TextSize = 12
Input.ClearTextOnFocus = false
Input.Parent = Main

Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 8)

--// Goto Button
local Goto = Instance.new("TextButton")
Goto.Size = UDim2.new(1, -30, 0, 40)
Goto.Position = UDim2.fromOffset(15, 139)
Goto.BackgroundColor3 = Color3.fromRGB(115, 85, 210)
Goto.Text = "GOTO MODEL"
Goto.TextColor3 = Color3.new(1, 1, 1)
Goto.Font = Enum.Font.GothamBold
Goto.TextSize = 12
Goto.Parent = Main

Instance.new("UICorner", Goto).CornerRadius = UDim.new(0, 8)

--// Status
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -30, 0, 22)
Status.Position = UDim2.fromOffset(15, 185)
Status.BackgroundTransparency = 1
Status.Text = "Ready"
Status.TextColor3 = Color3.fromRGB(130, 190, 150)
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

--// Draggable
local Dragging = false
local DragStart
local StartPosition

Header.InputBegan:Connect(function(InputObject)
    if InputObject.UserInputType == Enum.UserInputType.MouseButton1
        or InputObject.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = InputObject.Position
        StartPosition = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(InputObject)
    if Dragging and (
        InputObject.UserInputType == Enum.UserInputType.MouseMovement
        or InputObject.UserInputType == Enum.UserInputType.Touch
    ) then

        local Delta = InputObject.Position - DragStart

        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(InputObject)
    if InputObject.UserInputType == Enum.UserInputType.MouseButton1
        or InputObject.UserInputType == Enum.UserInputType.Touch then
        Dragging = false
    end
end)

--// Goto Logic
local Busy = false

local function GotoModel()
    if Busy then return end

    Busy = true

    local Success, ErrorMessage = pcall(function()
        local ModelName = Input.Text

        if ModelName == "" then
            Status.Text = "Please enter a model name."
            return
        end

        local Model = workspace:FindFirstChild(ModelName, true)

        if not Model or not Model:IsA("Model") then
            Status.Text = "Model not found."
            return
        end

        local Character = Player.Character or Player.CharacterAdded:Wait()
        local RootPart = Character:WaitForChild("HumanoidRootPart")

        Status.Text = "Teleporting..."

        RootPart.CFrame = Model:GetPivot() + CONFIG.Offset

        task.wait(CONFIG.PromptDelay)

        -- Find ProximityPrompt
		local Prompt = Model:FindFirstChildWhichIsA(
			"ProximityPrompt",
			true
		)

		if not Prompt then
			Status.Text = "No ProximityPrompt found."
			return
		end

		-- Activate prompt
		fireproximityprompt(Prompt)

		Status.Text = "ProximityPrompt activated!"
		print("Activated:", Prompt:GetFullName())

        -- Standard Roblox interaction:
        -- The server must handle Prompt.Triggered.
        Status.Text = "Reached model. Activate its prompt."

        print("Target:", Model:GetFullName())
        print("Prompt:", Prompt:GetFullName())
    end)

    if not Success then
        Status.Text = "Error: " .. tostring(ErrorMessage)
    end

    Busy = false
end

Goto.MouseButton1Click:Connect(GotoModel)

--// Button Hover
Goto.MouseEnter:Connect(function()
    TweenService:Create(Goto, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(135, 105, 235)
    }):Play()
end)

Goto.MouseLeave:Connect(function()
    TweenService:Create(Goto, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(115, 85, 210)
    }):Play()
end)

--// Close
Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)
