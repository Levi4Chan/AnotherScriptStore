

--[[
    LUNTI AUTO | GARDEN CONTROL
    Modern GUI Edition

    Features:
    - Automatic GUI creation
    - Duplicate GUI prevention
    - Minimize / Restore
    - Draggable interface
    - Responsive scaling
    - Seed packet navigation
    - Adjustable grow wait
    - Buy selected seed
    - Plant slots 1-10
    - Harvest slots 1-10
    - Sell all
    - Auto Cycle
    - Status notifications

    Expected game API:
    ReplicatedStorage.Garden.Remotes.Action
    ReplicatedStorage.Garden.Assets.SeedPackets

    Intended for your own authorized Roblox experience.
]]

--// SERVICES

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

--// GUI CLEANUP

local function getGuiParents()
    local candidates = {}
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and typeof(result) == "Instance" then
            table.insert(candidates, result)
        end
    end
    table.insert(candidates, Player:WaitForChild("PlayerGui"))
    table.insert(candidates, CoreGui)
    return candidates
end

local GUI_PARENT = nil
local GUI_CANDIDATES = getGuiParents()

-- Cleanup all possible parents, not just the selected one.
for _, parent in ipairs(GUI_CANDIDATES) do
    pcall(function()
        local old = parent:FindFirstChild("LuntiAutoGui")
        if old then old:Destroy() end
    end)
end

--// CONFIGURATION

local CONFIG = {
    GrowWait = 60,
    MinimumWait = 10,
    MaximumWait = 600,
    WaitStep = 10,
    TweenSpeed = 0.18,
}

local COLORS = {
    Background = Color3.fromRGB(15, 23, 19),
    Panel = Color3.fromRGB(23, 35, 28),
    PanelLight = Color3.fromRGB(31, 47, 37),
    PanelHover = Color3.fromRGB(42, 61, 47),

    Green = Color3.fromRGB(135, 218, 144),
    GreenDark = Color3.fromRGB(65, 139, 81),

    Text = Color3.fromRGB(240, 247, 241),
    Muted = Color3.fromRGB(151, 173, 157),

    Red = Color3.fromRGB(222, 103, 91),
    Border = Color3.fromRGB(54, 76, 60),
}

--// VARIABLES

local SeedOptions = {}
local SelectedSeedIndex = 1

local JobInProgress = false
local AutoCycleRunning = false
local AutoCycleID = 0

local GardenReference
local SeedPacketsReference

--// GARDEN REFERENCES
-- These are non-blocking so the GUI can appear immediately.

local function GetGarden()
    return ReplicatedStorage:FindFirstChild("Garden")
end

local function GetSeedPackets()
    local Garden = GetGarden()
    if not Garden then return nil end

    local Assets = Garden:FindFirstChild("Assets")
    if not Assets then return nil end

    return Assets:FindFirstChild("SeedPackets")
end

local function RefreshSeedOptions()
    GardenReference = GetGarden()
    SeedPacketsReference = GetSeedPackets()

    SeedOptions = {}

    if SeedPacketsReference then
        SeedOptions = SeedPacketsReference:GetChildren()
    end

    table.sort(SeedOptions, function(A, B)
        return A.Name:lower() < B.Name:lower()
    end)

    if #SeedOptions == 0 then
        SelectedSeedIndex = 1
    elseif SelectedSeedIndex > #SeedOptions then
        SelectedSeedIndex = 1
    end
end

local function GetSelectedSeed()
    RefreshSeedOptions()

    if #SeedOptions == 0 then
        return nil
    end

    return SeedOptions[SelectedSeedIndex]
end

--// GUI HELPERS

local function Create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties) do
        object[property] = value
    end

    object.Parent = parent

    return object
end

local function Round(object, radius)
    Create("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, object)
end

local function Outline(object, color, transparency)
    Create("UIStroke", {
        Color = color or COLORS.Border,
        Transparency = transparency or 0,
        Thickness = 1,
    }, object)
end

local function MakeLabel(parent, text, size, position, fontSize, color)
    return Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        Size = size,
        Position = position,
        Font = Enum.Font.GothamMedium,
        TextSize = fontSize or 12,
        TextColor3 = color or COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)
end

local function MakeButton(parent, text, size, position, color)
    local button = Create("TextButton", {
        Text = text,
        Size = size,
        Position = position,
        BackgroundColor3 = color or COLORS.PanelLight,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = COLORS.Text,
        AutoButtonColor = true,
    }, parent)

    Round(button, 10)

    return button
end

local function MakeCard(parent, size, position)
    local card = Create("Frame", {
        Size = size,
        Position = position,
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, parent)

    Round(card, 12)

    return card
end

--// SCREEN GUI

local GUI = Instance.new("ScreenGui")
GUI.Name = "LuntiAutoGui"
GUI.ResetOnSpawn = false
GUI.DisplayOrder = 999
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.IgnoreGuiInset = true

local attached = false
for _, parent in ipairs(GUI_CANDIDATES) do
    local ok = pcall(function()
        GUI.Parent = parent
    end)
    if ok and GUI.Parent == parent then
        GUI_PARENT = parent
        attached = true
        break
    end
end
if not attached then
    warn("[Lunti Auto] Unable to attach GUI to any supported container")
    return
end

-- UIScale must be parented to a GuiObject, not a ScreenGui.
local WindowScale
local function UpdateScale()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local factor = math.min(viewport.X / 440, viewport.Y / 680)
    if WindowScale then
        WindowScale.Scale = math.clamp(factor, 0.55, 1)
    end
end

--// MAIN WINDOW

local Window = Create("Frame", {
    Name = "MainWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(390, 590),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
}, GUI)

WindowScale = Create("UIScale", { Scale = 1 }, Window)
UpdateScale()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    UpdateScale()
end)
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
end

Round(Window, 18)
Outline(Window, COLORS.Border, 0.1)

--// HEADER

local Header = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 70),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, Window)

Round(Header, 18)

Create("Frame", {
    Position = UDim2.new(0, 0, 1, -16),
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, Header)

local Logo = Create("Frame", {
    Position = UDim2.fromOffset(17, 16),
    Size = UDim2.fromOffset(38, 38),
    BackgroundColor3 = Color3.fromRGB(43, 78, 51),
    BorderSizePixel = 0,
}, Header)

Round(Logo, 12)

local LogoText = MakeLabel(
    Logo,
    "L",
    UDim2.fromScale(1, 1),
    UDim2.fromScale(0, 0),
    22,
    COLORS.Green
)

LogoText.TextXAlignment = Enum.TextXAlignment.Center
LogoText.Font = Enum.Font.GothamBold

MakeLabel(
    Header,
    "LUNTI AUTO",
    UDim2.fromOffset(200, 24),
    UDim2.fromOffset(65, 12),
    17,
    COLORS.Text
).Font = Enum.Font.GothamBold

MakeLabel(
    Header,
    "GARDEN CONTROL CENTER",
    UDim2.fromOffset(200, 18),
    UDim2.fromOffset(66, 36),
    9,
    COLORS.Muted
)

local MinimizeButton = MakeButton(
    Header,
    "−",
    UDim2.fromOffset(30, 30),
    UDim2.new(1, -84, 0, 18),
    COLORS.PanelLight
)

MinimizeButton.TextSize = 20

local CloseButton = MakeButton(
    Header,
    "×",
    UDim2.fromOffset(30, 30),
    UDim2.new(1, -44, 0, 18),
    COLORS.PanelLight
)

CloseButton.TextSize = 20

--// CONTENT

local Content = Create("Frame", {
    Position = UDim2.fromOffset(17, 84),
    Size = UDim2.new(1, -34, 1, -99),
    BackgroundTransparency = 1,
}, Window)

--// STATUS CARD

local StatusCard = MakeCard(
    Content,
    UDim2.new(1, 0, 0, 55),
    UDim2.fromOffset(0, 0)
)

local StatusDot = Create("Frame", {
    Position = UDim2.fromOffset(14, 22),
    Size = UDim2.fromOffset(10, 10),
    BackgroundColor3 = COLORS.Green,
    BorderSizePixel = 0,
}, StatusCard)

Round(StatusDot, 10)

MakeLabel(
    StatusCard,
    "STATUS",
    UDim2.fromOffset(100, 15),
    UDim2.fromOffset(33, 7),
    9,
    COLORS.Muted
).Font = Enum.Font.GothamBold

local StatusText = MakeLabel(
    StatusCard,
    "Initializing...",
    UDim2.new(1, -48, 0, 20),
    UDim2.fromOffset(33, 25),
    12,
    COLORS.Text
)

StatusText.TextTruncate = Enum.TextTruncate.AtEnd

local function SetStatus(message, color)
    StatusText.Text = tostring(message)
    StatusDot.BackgroundColor3 = color or COLORS.Green
end

--// SEED SECTION

MakeLabel(
    Content,
    "SEED PACKET",
    UDim2.new(1, 0, 0, 17),
    UDim2.fromOffset(2, 66),
    10,
    COLORS.Muted
).Font = Enum.Font.GothamBold

local SeedCard = MakeCard(
    Content,
    UDim2.new(1, 0, 0, 58),
    UDim2.fromOffset(0, 88)
)

local SeedName = MakeLabel(
    SeedCard,
    "Loading seed packets...",
    UDim2.new(1, -115, 1, 0),
    UDim2.fromOffset(15, 0),
    13,
    COLORS.Text
)

SeedName.Font = Enum.Font.GothamSemibold
SeedName.TextTruncate = Enum.TextTruncate.AtEnd

local PreviousSeed = MakeButton(
    SeedCard,
    "‹",
    UDim2.fromOffset(32, 34),
    UDim2.new(1, -84, 0.5, -17),
    COLORS.PanelLight
)

PreviousSeed.TextSize = 22

local NextSeed = MakeButton(
    SeedCard,
    "›",
    UDim2.fromOffset(32, 34),
    UDim2.new(1, -44, 0.5, -17),
    COLORS.PanelLight
)

NextSeed.TextSize = 22
NextSeed.TextColor3 = COLORS.Green

local function RefreshSeedLabel()
    local crop = GetSelectedSeed()

    if crop then
        SeedName.Text = crop.Name
    else
        SeedName.Text = "No seed packets found"
    end
end

--// GROW WAIT SECTION

MakeLabel(
    Content,
    "GROW WAIT BEFORE HARVEST",
    UDim2.new(1, 0, 0, 17),
    UDim2.fromOffset(2, 158),
    10,
    COLORS.Muted
).Font = Enum.Font.GothamBold

local WaitCard = MakeCard(
    Content,
    UDim2.new(1, 0, 0, 58),
    UDim2.fromOffset(0, 180)
)

MakeLabel(
    WaitCard,
    "Auto cycle pause",
    UDim2.new(1, -155, 1, 0),
    UDim2.fromOffset(15, 0),
    12,
    COLORS.Muted
)

local WaitValue = MakeLabel(
    WaitCard,
    tostring(CONFIG.GrowWait) .. "s",
    UDim2.fromOffset(55, 58),
    UDim2.new(1, -122, 0, 0),
    14,
    COLORS.Text
)

WaitValue.TextXAlignment = Enum.TextXAlignment.Center

local LessWait = MakeButton(
    WaitCard,
    "−",
    UDim2.fromOffset(28, 32),
    UDim2.new(1, -67, 0.5, -16),
    COLORS.PanelLight
)

local MoreWait = MakeButton(
    WaitCard,
    "+",
    UDim2.fromOffset(28, 32),
    UDim2.new(1, -34, 0.5, -16),
    COLORS.PanelLight
)

LessWait.TextSize = 18
MoreWait.TextSize = 18
MoreWait.TextColor3 = COLORS.Green

--// QUICK ACTIONS

MakeLabel(
    Content,
    "QUICK ACTIONS",
    UDim2.new(1, 0, 0, 17),
    UDim2.fromOffset(2, 251),
    10,
    COLORS.Muted
).Font = Enum.Font.GothamBold

local BuyButton = MakeButton(
    Content,
    "BUY SELECTED",
    UDim2.new(0.5, -5, 0, 44),
    UDim2.fromOffset(0, 274),
    COLORS.PanelLight
)

local PlantButton = MakeButton(
    Content,
    "PLANT SLOTS 1–10",
    UDim2.new(0.5, -5, 0, 44),
    UDim2.new(0.5, 5, 0, 274),
    COLORS.PanelLight
)

PlantButton.TextColor3 = COLORS.Green

local HarvestButton = MakeButton(
    Content,
    "HARVEST 1–10",
    UDim2.new(0.5, -5, 0, 44),
    UDim2.fromOffset(0, 326),
    COLORS.PanelLight
)

local SellButton = MakeButton(
    Content,
    "SELL ALL",
    UDim2.new(0.5, -5, 0, 44),
    UDim2.new(0.5, 5, 0, 326),
    COLORS.PanelLight
)

--// AUTO CYCLE BUTTON

local AutoButton = MakeButton(
    Content,
    "START AUTO CYCLE",
    UDim2.new(1, 0, 0, 48),
    UDim2.fromOffset(0, 386),
    COLORS.GreenDark
)

AutoButton.TextSize = 13

MakeLabel(
    Content,
    "Buy → Plant → Wait → Harvest → Sell",
    UDim2.new(1, 0, 0, 20),
    UDim2.fromOffset(0, 440),
    9,
    COLORS.Muted
).TextXAlignment = Enum.TextXAlignment.Center

--// MINIMIZE / RESTORE

local RestoreButton = MakeButton(
    GUI,
    "L",
    UDim2.fromOffset(48, 48),
    UDim2.new(0, 20, 0.5, 0),
    COLORS.GreenDark
)

RestoreButton.AnchorPoint = Vector2.new(0, 0.5)
RestoreButton.Visible = false
RestoreButton.TextSize = 20
RestoreButton.Font = Enum.Font.GothamBold

MinimizeButton.Activated:Connect(function()
    Window.Visible = false
    RestoreButton.Visible = true
end)

RestoreButton.Activated:Connect(function()
    Window.Visible = true
    RestoreButton.Visible = false
end)

--// REMOTE ACCESS
-- InvokeServer is used because Action must be a RemoteFunction.
-- The client argument contract below preserves the uploaded script's original
-- calls. If the server says "Unknown seed", the server handler's expected
-- seed identifier/argument must be confirmed; the client cannot infer it.

local function GetActionRemote()
    local Garden = GetGarden()
    if not Garden then return nil end

    local Remotes = Garden:FindFirstChild("Remotes")
    if not Remotes then return nil end

    local Remote = Remotes:FindFirstChild("Action")

    if Remote and Remote:IsA("RemoteFunction") then
        return Remote
    end

    return nil
end

local function InvokeAction(action, argument)
    local Remote = GetActionRemote()

    if not Remote then
        return false, "Garden.Remotes.Action RemoteFunction unavailable"
    end

    -- This game API is assumed to accept (actionName, argument).
    -- Keep the original argument shapes until the server handler confirms otherwise.
    local ok, result, detail = pcall(function()
        return Remote:InvokeServer(action, argument)
    end)

    if not ok then
        warn("[Lunti Auto] InvokeServer failed for", action, ":", result)
        return false, tostring(result)
    end

    -- Support common server response formats without assuming every response is a string.
    if result == false then
        local message = type(detail) == "string" and detail or (action .. " was rejected by the server")
        warn("[Lunti Auto] Server rejected", action, ":", message)
        return false, message
    end

    if type(result) == "table" then
        local succeeded = result.Success
        if succeeded == nil then succeeded = result.success end
        if succeeded == nil then succeeded = result.Ok end
        if succeeded == nil then succeeded = result.ok end

        local message = result.Message or result.message or result.Error or result.error or result.Status or result.status
        if succeeded == false then
            message = tostring(message or (action .. " was rejected by the server"))
            warn("[Lunti Auto] Server rejected", action, ":", message)
            return false, message
        end

        if message ~= nil then
            message = tostring(message)
            local lower = message:lower()
            if lower:find("unknown seed", 1, true)
                or lower:find("invalid seed", 1, true)
                or lower:find("not enough", 1, true)
                or lower:find("failed", 1, true)
                or lower:find("error", 1, true) then
                warn("[Lunti Auto] Server response for", action, ":", message)
                return false, message
            end
            return true, message
        end

        return true, nil
    end

    if type(result) == "string" then
        local lower = result:lower()
        if lower:find("unknown seed", 1, true)
            or lower:find("invalid seed", 1, true)
            or lower:find("not enough", 1, true)
            or lower:find("failed", 1, true)
            or lower:find("error", 1, true) then
            warn("[Lunti Auto] Server response for", action, ":", result)
            return false, result
        end
        return true, result
    end

    if type(detail) == "string" then
        return true, detail
    end

    return true, nil
end

local function MustInvoke(action, argument, message)
    SetStatus(message, COLORS.Green)

    local success, response = InvokeAction(action, argument)

    if not success then
        error(response, 0)
    end

    return response
end

--// JOB HANDLER

local function RunJob(message, callback)
    if JobInProgress then
        SetStatus("An action is already running", COLORS.Muted)
        return
    end

    JobInProgress = true
    SetStatus(message, COLORS.Green)

    task.spawn(function()
        local success, result = pcall(callback)

        JobInProgress = false

        if success then
            SetStatus(
                type(result) == "string" and result or "Action complete",
                COLORS.Green
            )
        else
            SetStatus(tostring(result), COLORS.Red)

            if AutoCycleRunning then
                AutoCycleRunning = false
                AutoCycleID += 1

                AutoButton.Text = "START AUTO CYCLE"
                AutoButton.BackgroundColor3 = COLORS.GreenDark
            end
        end
    end)
end

--// SEED NAVIGATION

PreviousSeed.Activated:Connect(function()
    RefreshSeedOptions()

    if #SeedOptions == 0 then
        RefreshSeedLabel()
        SetStatus("No seed packets available", COLORS.Red)
        return
    end

    SelectedSeedIndex =
        ((SelectedSeedIndex - 2) % #SeedOptions) + 1

    RefreshSeedLabel()
end)

NextSeed.Activated:Connect(function()
    RefreshSeedOptions()

    if #SeedOptions == 0 then
        RefreshSeedLabel()
        SetStatus("No seed packets available", COLORS.Red)
        return
    end

    SelectedSeedIndex =
        (SelectedSeedIndex % #SeedOptions) + 1

    RefreshSeedLabel()
end)

--// WAIT TIME CONTROLS

LessWait.Activated:Connect(function()
    CONFIG.GrowWait = math.max(
        CONFIG.MinimumWait,
        CONFIG.GrowWait - CONFIG.WaitStep
    )

    WaitValue.Text = tostring(CONFIG.GrowWait) .. "s"
end)

MoreWait.Activated:Connect(function()
    CONFIG.GrowWait = math.min(
        CONFIG.MaximumWait,
        CONFIG.GrowWait + CONFIG.WaitStep
    )

    WaitValue.Text = tostring(CONFIG.GrowWait) .. "s"
end)

--// BUY SELECTED SEED

BuyButton.Activated:Connect(function()
    RunJob("Buying seed packet...", function()
        local crop = GetSelectedSeed()

        if not crop then
            error("No seed packets found", 0)
        end

        local response = MustInvoke(
            "Buy",
            crop,
            "Buying " .. crop.Name .. "..."
        )

        return response or crop.Name .. " purchased"
    end)
end)

--// PLANT ALL

PlantButton.Activated:Connect(function()
    RunJob("Planting slots 1–10...", function()
        local crop = GetSelectedSeed()

        if not crop then
            error("No seed packets found", 0)
        end

        for i = 1, 10 do
            MustInvoke(
                "Plant",
                {
                    Crop = crop,
                    Slot = i
                },
                "Planting slot " .. i .. "/10..."
            )
        end

        return "Slots 1–10 planted"
    end)
end)

--// HARVEST ALL

HarvestButton.Activated:Connect(function()
    RunJob("Harvesting crops...", function()
        for i = 1, 10 do
            MustInvoke(
                "Harvest",
                i,
                "Harvesting slot " .. i .. "/10..."
            )
        end

        return "Slots 1–10 harvested"
    end)
end)

--// SELL ALL

SellButton.Activated:Connect(function()
    RunJob("Selling harvested crops...", function()
        local response = MustInvoke(
            "Sell",
            nil,
            "Selling all harvested crops..."
        )

        return response or "Harvest sold"
    end)
end)

--// AUTO CYCLE

local function WaitForGrowTime(runID)
    local remaining = CONFIG.GrowWait

    while remaining > 0
        and AutoCycleRunning
        and runID == AutoCycleID do

        local step = math.min(remaining, 0.25)

        SetStatus("Growing crops: " .. math.ceil(remaining) .. "s", COLORS.Green)
        task.wait(step)
        remaining -= step
    end
end

AutoButton.Activated:Connect(function()

    -- STOP AUTO CYCLE

    if AutoCycleRunning then
        AutoCycleRunning = false
        AutoCycleID += 1

        AutoButton.Text = "START AUTO CYCLE"
        AutoButton.BackgroundColor3 = COLORS.GreenDark

        SetStatus("Auto cycle stopping...", COLORS.Muted)
        return
    end

    if JobInProgress then
        SetStatus("Wait for current action to finish", COLORS.Muted)
        return
    end

    local crop = GetSelectedSeed()

    if not crop then
        SetStatus("No seed packets found", COLORS.Red)
        return
    end

    if not GetActionRemote() then
        SetStatus("Garden Action Remote unavailable", COLORS.Red)
        return
    end

    AutoCycleRunning = true
    JobInProgress = true
    AutoCycleID += 1

    local currentRun = AutoCycleID

    AutoButton.Text = "STOP AUTO CYCLE"
    AutoButton.BackgroundColor3 = COLORS.Red

    task.spawn(function()

        local success, result = pcall(function()

            while AutoCycleRunning
                and currentRun == AutoCycleID do

                local selectedCrop = GetSelectedSeed()

                if not selectedCrop then
                    error("Selected seed is unavailable", 0)
                end

                -- BUY AND PLANT SLOTS

                for i = 1, 10 do
                    if not AutoCycleRunning
                        or currentRun ~= AutoCycleID then
                        break
                    end

                    MustInvoke(
                        "Buy",
                        selectedCrop,
                        "Buying " .. selectedCrop.Name .. " (" .. i .. "/10)"
                    )

                    if not AutoCycleRunning
                        or currentRun ~= AutoCycleID then
                        break
                    end

                    MustInvoke(
                        "Plant",
                        {
                            Crop = selectedCrop,
                            Slot = i
                        },
                        "Planting slot " .. i .. "/10..."
                    )
                end

                if not AutoCycleRunning
                    or currentRun ~= AutoCycleID then
                    break
                end

                -- WAIT FOR CROPS

                SetStatus(
                    "Growing crops: " .. CONFIG.GrowWait .. "s",
                    COLORS.Green
                )

                WaitForGrowTime(currentRun)

                if not AutoCycleRunning
                    or currentRun ~= AutoCycleID then
                    break
                end

                -- HARVEST

                for i = 1, 10 do
                    if not AutoCycleRunning
                        or currentRun ~= AutoCycleID then
                        break
                    end

                    MustInvoke(
                        "Harvest",
                        i,
                        "Harvesting slot " .. i .. "/10..."
                    )
                end

                if not AutoCycleRunning
                    or currentRun ~= AutoCycleID then
                    break
                end

                -- SELL

                MustInvoke(
                    "Sell",
                    nil,
                    "Selling harvested crops..."
                )
            end

            return "Auto cycle stopped"

        end)

        JobInProgress = false

        if success then
            SetStatus(
                result or "Auto cycle finished",
                COLORS.Green
            )
        else
            SetStatus(tostring(result), COLORS.Red)
        end

        AutoCycleRunning = false

        AutoButton.Text = "START AUTO CYCLE"
        AutoButton.BackgroundColor3 = COLORS.GreenDark

    end)
end)

--// DRAGGABLE WINDOW

local Dragging = false
local DragStart
local StartPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = input.Position
        StartPosition = Window.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

local dragConnection = UserInputService.InputChanged:Connect(function(input)
    if not Dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - DragStart

        Window.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end
end)

--// CLOSE GUI

CloseButton.Activated:Connect(function()
    AutoCycleRunning = false
    AutoCycleID += 1

    GUI:Destroy()
    if dragConnection then dragConnection:Disconnect() end
end)

--// INITIALIZATION

RefreshSeedOptions()
RefreshSeedLabel()

if #SeedOptions > 0 then
    SetStatus("Garden interface ready", COLORS.Green)
else
    SetStatus("Waiting for seed packets...", COLORS.Muted)

    -- Continue checking for assets without blocking GUI creation.
    task.spawn(function()
        while GUI.Parent and #SeedOptions == 0 do
            task.wait(2)

            RefreshSeedOptions()
            RefreshSeedLabel()

            if #SeedOptions > 0 then
                SetStatus("Seed packets loaded", COLORS.Green)
                break
            end
        end
    end)
end

print("[Lunti Auto] GUI successfully initialized.")
