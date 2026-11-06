

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
    PlantDelay = 0.4,
    HarvestDelay = 0.2,
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
local SelectedSeeds = {}

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

    -- The server expects the seed NAME (string), not the Instance.
    -- The selected name comes from:
    -- ReplicatedStorage.Garden.Assets.SeedPackets
    local CropsValue = SeedOptions[SelectedSeedIndex]

    if not CropsValue or not CropsValue.Parent then
        return nil
    end

    return CropsValue.Name
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
    Size = UDim2.fromOffset(390, 650),
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


--// PRIORITY SEED MULTI-SELECT
MakeLabel(Content, "SEED PACKET PRIORITY (TOP TO BOTTOM)", UDim2.new(1,0,0,17), UDim2.fromOffset(2,66), 10, COLORS.Muted).Font = Enum.Font.GothamBold
local SeedDropdownButton = MakeButton(Content, "  Choose seed packets  ▾", UDim2.new(1,0,0,42), UDim2.fromOffset(0,88), COLORS.PanelLight)
SeedDropdownButton.TextXAlignment = Enum.TextXAlignment.Left
local SeedDropdown = Create("ScrollingFrame", {
    Name = "SeedPriorityDropdown", Position = UDim2.fromOffset(0,134),
    Size = UDim2.new(1,0,0,104), BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0,0),
    Visible = false, ZIndex = 20,
}, Content)
Round(SeedDropdown,10)
Outline(SeedDropdown,COLORS.Border,0.15)
local SeedDropdownLayout = Create("UIListLayout", {
    Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder,
}, SeedDropdown)
local SeedPrioritySummary = MakeLabel(Content, "Priority: none", UDim2.new(1,0,0,18), UDim2.fromOffset(2,137), 9, COLORS.Muted)

local function GetPrioritySeedNames()
    local names = {}
    for _, name in ipairs(SelectedSeeds) do
        if type(name) == "string" and name ~= "" then table.insert(names,name) end
    end
    return names
end

local function RefreshSeedLabel()
    local names = GetPrioritySeedNames()
    if #names == 0 then
        SeedDropdownButton.Text = "  Choose seed packets  ▾"
        SeedPrioritySummary.Text = "Priority: none"
    else
        SeedDropdownButton.Text = "  " .. #names .. " selected  ▾"
        SeedPrioritySummary.Text = "Priority: " .. table.concat(names," → ")
    end
end

local function RefreshSeedDropdown()
    RefreshSeedOptions()
    for _, child in ipairs(SeedDropdown:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local present = {}
    for _, obj in ipairs(SeedOptions) do present[obj.Name] = true end
    for i = #SelectedSeeds, 1, -1 do
        if not present[SelectedSeeds[i]] then table.remove(SelectedSeeds,i) end
    end
    for index, obj in ipairs(SeedOptions) do
        local name = obj.Name
        local selectedIndex
        for i, chosen in ipairs(SelectedSeeds) do
            if chosen == name then selectedIndex = i break end
        end
        local option = MakeButton(
            SeedDropdown,
            selectedIndex and (selectedIndex .. ". ✓  " .. name) or ("＋  " .. name),
            UDim2.new(1,-8,0,30), UDim2.fromOffset(4,0),
            selectedIndex and COLORS.PanelHover or COLORS.PanelLight
        )
        option.LayoutOrder = index
        option.TextXAlignment = Enum.TextXAlignment.Left
        option.ZIndex = 21
        option.Activated:Connect(function()
            local found
            for i, chosen in ipairs(SelectedSeeds) do
                if chosen == name then found = i break end
            end
            if found then table.remove(SelectedSeeds,found)
            else table.insert(SelectedSeeds,name) end
            RefreshSeedDropdown()
            RefreshSeedLabel()
        end)
    end
    task.defer(function()
        SeedDropdown.CanvasSize = UDim2.fromOffset(0,SeedDropdownLayout.AbsoluteContentSize.Y + 8)
    end)
    RefreshSeedLabel()
end

SeedDropdownButton.Activated:Connect(function()
    SeedDropdown.Visible = not SeedDropdown.Visible
    if SeedDropdown.Visible then RefreshSeedDropdown() end
end)

--// GROW WAIT SECTION

MakeLabel(
    Content,
    "GROW WAIT BEFORE HARVEST",
    UDim2.new(1, 0, 0, 17),
    UDim2.fromOffset(2, 220),
    10,
    COLORS.Muted
).Font = Enum.Font.GothamBold

local WaitCard = MakeCard(
    Content,
    UDim2.new(1, 0, 0, 58),
    UDim2.fromOffset(0, 242)
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
    UDim2.fromOffset(2, 313),
    10,
    COLORS.Muted
).Font = Enum.Font.GothamBold

local BuyButton = MakeButton(
    Content,
    "BUY SELECTED",
    UDim2.new(0.5, -5, 0, 44),
    UDim2.fromOffset(0, 336),
    COLORS.PanelLight
)

local PlantButton = MakeButton(
    Content,
    "PLANT SLOTS 1–10",
    UDim2.new(0.5, -5, 0, 44),
    UDim2.new(0.5, 5, 0, 336),
    COLORS.PanelLight
)

PlantButton.TextColor3 = COLORS.Green

local HarvestButton = MakeButton(
    Content,
    "HARVEST 1–10",
    UDim2.new(0.5, -5, 0, 44),
    UDim2.fromOffset(0, 388),
    COLORS.PanelLight
)

local SellButton = MakeButton(
    Content,
    "SELL ALL",
    UDim2.new(0.5, -5, 0, 44),
    UDim2.new(0.5, 5, 0, 388),
    COLORS.PanelLight
)

--// AUTO CYCLE BUTTON

local AutoButton = MakeButton(
    Content,
    "START AUTO CYCLE",
    UDim2.new(1, 0, 0, 48),
    UDim2.fromOffset(0, 448),
    COLORS.GreenDark
)

AutoButton.TextSize = 13

MakeLabel(
    Content,
    "Buy → Plant → Wait → Harvest → Sell",
    UDim2.new(1, 0, 0, 20),
    UDim2.fromOffset(0, 502),
    9,
    COLORS.Muted
).TextXAlignment = Enum.TextXAlignment.Center

--// TELEPORT BUTTON

local TeleportButton = MakeButton(
    Content,
    "TELEPORT TO 272, 5, -104",
    UDim2.new(1, 0, 0, 44),
    UDim2.fromOffset(0, 530),
    COLORS.PanelLight
)
TeleportButton.TextSize = 12
TeleportButton.TextColor3 = COLORS.Green

TeleportButton.Activated:Connect(function()
    local character = Player.Character or Player.CharacterAdded:Wait()
    local root = character:FindFirstChild("HumanoidRootPart")
        or character:WaitForChild("HumanoidRootPart", 5)

    if not root then
        SetStatus("Teleport failed: character root not found", COLORS.Red)
        return
    end

    root.CFrame = CFrame.new(272, 5, -104)
    SetStatus("Teleported to 272, 5, -104", COLORS.Green)
end)

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

    -- Exact game API:
    -- Exact server API; Crop values are seed-name strings:
    -- Buy:     InvokeServer("Buy", "Carrot")
    -- Plant:   InvokeServer("Plant", {Crop = "Carrot", Slot = slot})
    -- Harvest: InvokeServer("Harvest", slot)
    -- Sell:    InvokeServer("Sell", nil)
    if action == "Buy" then
        print("[Lunti Auto] Buy seed name:", tostring(argument))
    elseif action == "Plant" and type(argument) == "table" then
        print("[Lunti Auto] Plant seed name:",
            tostring(argument.Crop),
            "Slot:", tostring(argument.Slot))
    else
        print("[Lunti Auto] InvokeServer:", action, "Argument:", tostring(argument))
    end

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
                or lower:find("error", 1, true)
                or lower:find("nothing is ready", 1, true)
                or lower:find("nothing ready", 1, true)
                or lower:find("not ready", 1, true)
                or lower:find("empty", 1, true)
                or lower:find("slow down", 1, true)
                or lower:find("cooldown", 1, true)
                or lower:find("out of stock", 1, true)
                or lower:find("restock", 1, true) then
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
            or lower:find("error", 1, true)
                or lower:find("nothing is ready", 1, true)
                or lower:find("nothing ready", 1, true)
                or lower:find("not ready", 1, true)
                or lower:find("empty", 1, true)
                or lower:find("slow down", 1, true)
                or lower:find("cooldown", 1, true)
                or lower:find("out of stock", 1, true)
                or lower:find("restock", 1, true) then
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
    -- Retry this specific action when the server applies its request cooldown.
    -- Do not restart the entire cycle at SELL just because one request was rate-limited.
    local retryDelays = {1, 2, 3, 5, 5}
    local attempt = 0

    while true do
        SetStatus(message .. " [" .. action .. "]", COLORS.Green)

        local success, response = InvokeAction(action, argument)

        if success then
            return response
        end

        local errorText = tostring(response or "Unknown server response")
        local lower = errorText:lower()

        if lower:find("slow down", 1, true)
            or lower:find("cooldown", 1, true)
            or lower:find("too fast", 1, true) then

            attempt += 1
            if attempt > #retryDelays then
                error(action .. " still rate-limited after retries: " .. errorText, 0)
            end

            local delaySeconds = retryDelays[attempt]
            warn("[Lunti Auto] " .. action .. " rate-limited; retrying in "
                .. delaySeconds .. "s (attempt " .. attempt .. "/" .. #retryDelays .. ")")
            SetStatus(action .. " rate-limited; retrying in " .. delaySeconds .. "s", COLORS.Red)
            task.wait(delaySeconds)
        else
            error(action .. " failed: " .. errorText, 0)
        end
    end
end

-- Try every plot slot. A slot that is empty/not ready must not stop
-- the scan, otherwise ready crops in later slots are never checked.
local function HarvestAllSlots(isAuto, runID)
    local harvested = 0
    local skipped = 0
    local failures = {}

    for slot = 1, 10 do
        if isAuto and (not AutoCycleRunning or runID ~= AutoCycleID) then
            break
        end

        SetStatus("Checking harvest slot " .. slot .. "/10...", COLORS.Green)

        local ok, response = InvokeAction("Harvest", slot)
        local message = tostring(response or "")
        local lower = message:lower()

        if ok then
            harvested += 1
        elseif lower:find("nothing is ready", 1, true)
            or lower:find("nothing ready", 1, true)
            or lower:find("not ready", 1, true)
            or lower:find("empty", 1, true) then
            skipped += 1
            print("[Lunti Auto] Slot " .. slot .. " is not ready: " .. message)
        elseif lower:find("slow down", 1, true)
            or lower:find("cooldown", 1, true)
            or lower:find("too fast", 1, true) then
            -- Retry this harvest slot with a growing wait instead of treating
            -- the cooldown as an empty slot or aborting the entire scan.
            local delays = {1, 2, 3, 5}
            local recovered = false

            for attempt, delaySeconds in ipairs(delays) do
                if isAuto and (not AutoCycleRunning or runID ~= AutoCycleID) then
                    break
                end

                SetStatus("Harvest slot " .. slot .. " rate-limited; retrying in "
                    .. delaySeconds .. "s", COLORS.Red)
                task.wait(delaySeconds)

                ok, response = InvokeAction("Harvest", slot)
                message = tostring(response or "")
                lower = message:lower()

                if ok then
                    harvested += 1
                    recovered = true
                    break
                elseif lower:find("nothing is ready", 1, true)
                    or lower:find("nothing ready", 1, true)
                    or lower:find("not ready", 1, true)
                    or lower:find("empty", 1, true) then
                    skipped += 1
                    recovered = true
                    break
                elseif not (lower:find("slow down", 1, true)
                    or lower:find("cooldown", 1, true)
                    or lower:find("too fast", 1, true)) then
                    break
                end
            end

            if not recovered then
                table.insert(failures, "Harvest slot " .. slot .. ": " .. message)
            end
        else
            table.insert(failures, "Harvest slot " .. slot .. ": " .. message)
        end

        if slot < 10 then
            task.wait(CONFIG.HarvestDelay)
        end
    end

    if #failures > 0 then
        warn("[Lunti Auto] Harvest issues: " .. table.concat(failures, " | "))
    end

    return harvested, skipped, failures
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

local function IsRateLimitResponse(message)
    local lower = tostring(message or ""):lower()
    return lower:find("slow down",1,true)
        or lower:find("cooldown",1,true)
        or lower:find("too fast",1,true)
        or lower:find("rate limit",1,true)
end

local function IsSeedFallbackResponse(message)
    local lower = tostring(message or ""):lower()
    return lower:find("unknown seed",1,true)
        or lower:find("invalid seed",1,true)
        or lower:find("out of stock",1,true)
        or lower:find("restock",1,true)
        or lower:find("unavailable",1,true)
        or lower:find("not available",1,true)
        or lower:find("not enough",1,true)
        or lower:find("insufficient",1,true)
        or lower:find("no seed",1,true)
        or lower:find("seed packet",1,true)
        or lower:find("not owned",1,true)
        or lower:find("cannot plant",1,true)
        or lower:find("can't plant",1,true)
        or lower:find("cannot use",1,true)
        or lower:find("not plantable",1,true)
        or lower:find("locked",1,true)
        or lower:find("rejected",1,true)
        or lower:find("failed",1,true)
end

local function BuyWithSeedFallback(seedNames)
    local errors = {}
    for _, seedName in ipairs(seedNames) do
        local ok, response = InvokeAction("Buy",seedName)
        if ok then return seedName,response end
        local reason = tostring(response or "Buy rejected")
        if IsSeedFallbackResponse(reason) then
            table.insert(errors,seedName .. ": " .. reason)
            SetStatus(seedName .. " unavailable; trying next selected seed...",COLORS.Muted)
            task.wait(CONFIG.PlantDelay)
        else
            error("Buy failed for " .. seedName .. ": " .. reason,0)
        end
    end
    error("All selected seeds failed to buy: " .. table.concat(errors," | "),0)
end

BuyButton.Activated:Connect(function()
    RunJob("Buying selected seed packets...",function()
        local names = GetPrioritySeedNames()
        if #names == 0 then error("Select one or more seed packets first",0) end
        local bought,response = BuyWithSeedFallback(names)
        return response or (bought .. " purchased")
    end)
end)

--// SHARED PLANT ROUTINE
-- Both the manual Plant button and Auto Cycle call this exact routine.
local function PlantAllSlots(isAuto, runID)
    local seedNames = GetPrioritySeedNames()
    if #seedNames == 0 then error("Select one or more seed packets first",0) end
    print("[Lunti Auto] Plant priority order: " .. table.concat(seedNames, " -> "))
    local planted = 0
    local slotFailures = {}

    for slot = 1,10 do
        if isAuto and (not AutoCycleRunning or runID ~= AutoCycleID) then break end
        local plantedThisSlot = false
        local errors = {}

        for _, seedName in ipairs(seedNames) do
            if isAuto and (not AutoCycleRunning or runID ~= AutoCycleID) then break end
            SetStatus("Planting slot " .. slot .. " with " .. seedName .. "...",COLORS.Green)
            local ok,response = InvokeAction("Plant",{Crop=seedName,Slot=slot})
            if ok then
                planted += 1
                plantedThisSlot = true
                break
            end

            local reason = tostring(response or "Plant rejected")
            if IsRateLimitResponse(reason) then
                -- A cooldown is not a seed mismatch. Retry this exact seed first.
                local retryDelays = {1, 2, 3, 5}
                local recovered = false
                for _, delaySeconds in ipairs(retryDelays) do
                    if isAuto and (not AutoCycleRunning or runID ~= AutoCycleID) then break end
                    SetStatus("Plant rate-limited; retrying " .. seedName .. " in " .. delaySeconds .. "s", COLORS.Red)
                    task.wait(delaySeconds)
                    ok,response = InvokeAction("Plant",{Crop=seedName,Slot=slot})
                    if ok then
                        planted += 1
                        plantedThisSlot = true
                        recovered = true
                        break
                    end
                    reason = tostring(response or "Plant rejected")
                    if not IsRateLimitResponse(reason) then break end
                end
                if plantedThisSlot then break end
                if not recovered and IsRateLimitResponse(reason) then
                    error("Plant remained rate-limited for slot " .. slot .. ": " .. reason,0)
                end
                table.insert(errors,seedName .. ": " .. reason)
                SetStatus(seedName .. " rejected for slot " .. slot .. "; trying next priority...",COLORS.Muted)
                task.wait(CONFIG.PlantDelay)
            else
                table.insert(errors,seedName .. ": " .. reason)
                SetStatus(seedName .. " rejected for slot " .. slot .. "; trying next priority...",COLORS.Muted)
                task.wait(CONFIG.PlantDelay)
            end
        end

        if not plantedThisSlot then
            table.insert(slotFailures,"Slot " .. slot .. " rejected all selected seeds (" .. table.concat(errors,"; ") .. ")")
        end
        if slot < 10 then task.wait(CONFIG.PlantDelay) end
    end

    if #slotFailures > 0 then error(table.concat(slotFailures," | "),0) end
    return planted
end

--// PLANT ALL

PlantButton.Activated:Connect(function()
    RunJob("Planting slots 1–10...", function()
        local planted = PlantAllSlots(false)

        return "Slots planted: " .. planted
    end)
end)

--// HARVEST ALL

HarvestButton.Activated:Connect(function()
    RunJob("Checking harvest slots...", function()
        local harvested, skipped, failures = HarvestAllSlots(false)

        if #failures > 0 then
            return "Harvested " .. harvested .. "; skipped " .. skipped
                .. "; errors: " .. #failures
        end

        return "Harvested " .. harvested .. " slot(s); not ready/empty: " .. skipped
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

    local prioritySeeds = GetPrioritySeedNames()

    if #prioritySeeds == 0 then
        SetStatus("Select one or more seed packets first", COLORS.Red)
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
        -- Order: HARVEST -> PLANT -> BUY -> SELL.
        -- Any failed stage aborts the current pass and restarts at HARVEST.
        -- Auto Cycle stops only when the user presses STOP or closes the GUI.
        while AutoCycleRunning and currentRun == AutoCycleID and GUI.Parent do
            local function stillRunning()
                return AutoCycleRunning and currentRun == AutoCycleID and GUI.Parent ~= nil
            end

            local function retryFromHarvest(stageName, reason)
                local message = stageName .. " failed: " .. tostring(reason)
                    .. " | restarting from Harvest in 3s"
                warn("[Lunti Auto] " .. message)
                SetStatus(message, COLORS.Red)

                for _ = 1, 12 do
                    if not stillRunning() then
                        return false
                    end
                    task.wait(0.25)
                end

                return stillRunning()
            end

            local passOK, failedStage, failureReason = true, nil, nil

            -- STEP 1: HARVEST
            do
                local ok, harvested, skipped, harvestErrors = pcall(function()
                    return HarvestAllSlots(true, currentRun)
                end)

                if not stillRunning() then
                    break
                end

                if not ok then
                    passOK, failedStage, failureReason = false, "Harvest", harvested
                elseif #harvestErrors > 0 then
                    passOK, failedStage, failureReason =
                        false, "Harvest", table.concat(harvestErrors, " | ")
                else
                    SetStatus(
                        "Harvested " .. harvested .. "; skipped " .. skipped,
                        COLORS.Green
                    )
                end
            end
            
            -- STEP 2: BUY. Only run if Plant succeeded.
            if passOK and stillRunning() then
                local ok, result = pcall(function()
                    local selectedCrop = GetSelectedSeed()
                    if not selectedCrop then
                        error("Selected seed is unavailable", 0)
                    end

                    local bought = 0
                    for i = 1, 10 do
                        if not stillRunning() then
                            return bought
                        end

                        MustInvoke(
                            "Buy",
                            selectedCrop,
                            "Buying " .. selectedCrop .. " (" .. i .. "/10)"
                        )
                        bought += 1
                    end
                    return bought
                end)

                if not stillRunning() then
                    break
                end

                if not ok then
                    passOK, failedStage, failureReason = false, "Buy", result
                end
            end

            -- STEP 3: PLANT. Only run if Harvest succeeded.
            if passOK and stillRunning() then
                local ok, result = pcall(function()
                    return PlantAllSlots(true, currentRun)
                end)

                if not stillRunning() then
                    break
                end

                if not ok then
                    passOK, failedStage, failureReason = false, "Plant", result
                end
            end

            -- STEP 4: SELL. Only run if Buy succeeded.
            if passOK and stillRunning() then
                local ok, result = pcall(function()
                    return MustInvoke("Sell", nil, "Selling harvested crops...")
                end)

                if not stillRunning() then
                    break
                end

                if not ok then
                    passOK, failedStage, failureReason = false, "Sell", result
                end
            end

            if not stillRunning() then
                break
            end

            if passOK then
                SetStatus("All steps completed; restarting from Harvest...", COLORS.Green)
                task.wait(1)
            else
                -- Do not continue to the next stage after a failure.
                -- Restart the entire sequence at STEP 1: HARVEST.
                if not retryFromHarvest(failedStage, failureReason) then
                    break
                end
            end
        end

        JobInProgress = false
        AutoCycleRunning = false

        if GUI.Parent then
            AutoButton.Text = "START AUTO CYCLE"
            AutoButton.BackgroundColor3 = COLORS.GreenDark
            SetStatus("Auto cycle stopped", COLORS.Muted)
        end
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
RefreshSeedDropdown()
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
