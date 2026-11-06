-- Lunti Auto | client GUI for your Garden experience
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts.
-- Expected API: ReplicatedStorage.Garden.Remotes.Action (RemoteFunction)
-- and seed packet instances under ReplicatedStorage.Garden.Assets.SeedPackets.
-- The server remains responsible for validating every action.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local garden = ReplicatedStorage:WaitForChild("Garden")
local seedPackets = garden:WaitForChild("Assets"):WaitForChild("SeedPackets")

local COLORS = {
	background = Color3.fromRGB(17, 26, 22),
	panel = Color3.fromRGB(25, 38, 31),
	panelLight = Color3.fromRGB(33, 49, 40),
	green = Color3.fromRGB(126, 213, 137),
	greenDark = Color3.fromRGB(67, 148, 87),
	text = Color3.fromRGB(239, 246, 239),
	muted = Color3.fromRGB(157, 177, 162),
	line = Color3.fromRGB(56, 77, 62),
	red = Color3.fromRGB(246, 132, 119),
}

local seedOptions = {}
local selectedSeedIndex = 1
local growWaitSeconds = 60
local jobInProgress = false
local autoCycleRunning = false
local autoCycleRunId = 0

local function refreshSeedOptions()
	seedOptions = seedPackets:GetChildren()
	table.sort(seedOptions, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)
	if #seedOptions == 0 then
		selectedSeedIndex = 1
	elseif selectedSeedIndex > #seedOptions then
		selectedSeedIndex = 1
	end
end
refreshSeedOptions()

local gui = Instance.new("ScreenGui")
gui.Name = "LuntiAutoGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local scale = Instance.new("UIScale")
scale.Parent = gui

local function updateScale()
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	scale.Scale = math.clamp(math.min(viewport.X / 450, viewport.Y / 700), 0.76, 1)
end
updateScale()
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local function round(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
	return corner
end

local function stroke(instance, color, transparency)
	local outline = Instance.new("UIStroke")
	outline.Color = color
	outline.Transparency = transparency or 0
	outline.Thickness = 1
	outline.Parent = instance
	return outline
end

local function label(parent, name, text, position, size, textSize, color, font)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.BackgroundTransparency = 1
	item.Position = position
	item.Size = size
	item.Font = font or Enum.Font.Gotham
	item.Text = text
	item.TextSize = textSize
	item.TextColor3 = color or COLORS.text
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextYAlignment = Enum.TextYAlignment.Center
	item.Parent = parent
	return item
end

local function button(parent, name, text, position, size, background, textColor)
	local item = Instance.new("TextButton")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundColor3 = background
	item.BorderSizePixel = 0
	item.AutoButtonColor = true
	item.Font = Enum.Font.GothamSemibold
	item.Text = text
	item.TextSize = 12
	item.TextColor3 = textColor or COLORS.text
	item.Parent = parent
	round(item, 10)
	return item
end

local window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Size = UDim2.fromOffset(390, 590)
window.BackgroundColor3 = COLORS.background
window.BorderSizePixel = 0
window.Parent = gui
round(window, 18)
stroke(window, COLORS.line, 0.15)

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 72)
header.BackgroundColor3 = COLORS.panel
header.BorderSizePixel = 0
header.Parent = window
round(header, 18)
local headerFill = Instance.new("Frame")
headerFill.Position = UDim2.new(0, 0, 1, -18)
headerFill.Size = UDim2.new(1, 0, 0, 18)
headerFill.BackgroundColor3 = COLORS.panel
headerFill.BorderSizePixel = 0
headerFill.Parent = header

local logo = Instance.new("Frame")
logo.Position = UDim2.fromOffset(18, 17)
logo.Size = UDim2.fromOffset(38, 38)
logo.BackgroundColor3 = Color3.fromRGB(45, 83, 55)
logo.BorderSizePixel = 0
logo.Parent = header
round(logo, 12)
local logoText = label(logo, "LogoLetter", "L", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 21, COLORS.green, Enum.Font.GothamBold)
logoText.TextXAlignment = Enum.TextXAlignment.Center
label(header, "Title", "LUNTI AUTO", UDim2.fromOffset(67, 15), UDim2.new(1, -125, 0, 25), 17, COLORS.text, Enum.Font.GothamBold)
label(header, "Subtitle", "GARDEN CONTROL", UDim2.fromOffset(68, 39), UDim2.new(1, -125, 0, 16), 9, COLORS.muted, Enum.Font.GothamSemibold)
local closeButton = button(header, "Close", "×", UDim2.new(1, -48, 0, 15), UDim2.fromOffset(30, 30), COLORS.panelLight, COLORS.muted)
closeButton.TextSize = 21

local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(18, 88)
content.Size = UDim2.new(1, -36, 1, -106)
content.BackgroundTransparency = 1
content.Parent = window

local statusCard = Instance.new("Frame")
statusCard.Name = "StatusCard"
statusCard.Size = UDim2.new(1, 0, 0, 56)
statusCard.BackgroundColor3 = COLORS.panel
statusCard.BorderSizePixel = 0
statusCard.Parent = content
round(statusCard, 12)
local statusDot = Instance.new("Frame")
statusDot.Position = UDim2.fromOffset(14, 22)
statusDot.Size = UDim2.fromOffset(9, 9)
statusDot.BackgroundColor3 = COLORS.muted
statusDot.BorderSizePixel = 0
statusDot.Parent = statusCard
round(statusDot, 6)
label(statusCard, "StatusCaption", "STATUS", UDim2.fromOffset(32, 10), UDim2.fromOffset(90, 14), 9, COLORS.muted, Enum.Font.GothamBold)
local statusText = label(statusCard, "StatusText", "Ready", UDim2.fromOffset(32, 27), UDim2.new(1, -45, 0, 18), 12, COLORS.text, Enum.Font.GothamMedium)
statusText.TextTruncate = Enum.TextTruncate.AtEnd

label(content, "SeedLabel", "SEED PACKET", UDim2.fromOffset(2, 68), UDim2.new(1, -4, 0, 16), 10, COLORS.muted, Enum.Font.GothamBold)
local seedCard = Instance.new("Frame")
seedCard.Position = UDim2.fromOffset(0, 91)
seedCard.Size = UDim2.new(1, 0, 0, 58)
seedCard.BackgroundColor3 = COLORS.panel
seedCard.BorderSizePixel = 0
seedCard.Parent = content
round(seedCard, 12)
local seedName = label(seedCard, "SeedName", "Loading seed packets…", UDim2.fromOffset(16, 0), UDim2.new(1, -112, 1, 0), 14, COLORS.text, Enum.Font.GothamSemibold)
local previousSeed = button(seedCard, "PreviousSeed", "‹", UDim2.new(1, -86, 0.5, -17), UDim2.fromOffset(32, 34), COLORS.panelLight, COLORS.muted)
previousSeed.TextSize = 22
local nextSeed = button(seedCard, "NextSeed", "›", UDim2.new(1, -46, 0.5, -17), UDim2.fromOffset(32, 34), COLORS.panelLight, COLORS.green)
nextSeed.TextSize = 22

label(content, "GrowWaitLabel", "GROW WAIT BEFORE HARVEST", UDim2.fromOffset(2, 161), UDim2.new(1, -4, 0, 16), 10, COLORS.muted, Enum.Font.GothamBold)
local waitCard = Instance.new("Frame")
waitCard.Position = UDim2.fromOffset(0, 184)
waitCard.Size = UDim2.new(1, 0, 0, 58)
waitCard.BackgroundColor3 = COLORS.panel
waitCard.BorderSizePixel = 0
waitCard.Parent = content
round(waitCard, 12)
label(waitCard, "WaitHint", "Auto cycle pause", UDim2.fromOffset(16, 0), UDim2.new(1, -160, 1, 0), 12, COLORS.muted, Enum.Font.Gotham)
local waitValue = label(waitCard, "WaitValue", tostring(growWaitSeconds) .. "s", UDim2.new(1, -118, 0, 0), UDim2.fromOffset(48, 58), 14, COLORS.text, Enum.Font.GothamSemibold)
waitValue.TextXAlignment = Enum.TextXAlignment.Center
local lessWait = button(waitCard, "LessWait", "−", UDim2.new(1, -69, 0.5, -16), UDim2.fromOffset(28, 32), COLORS.panelLight, COLORS.muted)
local moreWait = button(waitCard, "MoreWait", "+", UDim2.new(1, -35, 0.5, -16), UDim2.fromOffset(28, 32), COLORS.panelLight, COLORS.green)
lessWait.TextSize = 18
moreWait.TextSize = 18

label(content, "ActionsLabel", "QUICK ACTIONS", UDim2.fromOffset(2, 257), UDim2.new(1, -4, 0, 16), 10, COLORS.muted, Enum.Font.GothamBold)
local buyButton = button(content, "BuySeed", "BUY SELECTED", UDim2.fromOffset(0, 280), UDim2.new(0.5, -5, 0, 44), COLORS.panelLight, COLORS.text)
local plantButton = button(content, "PlantAll", "PLANT SLOTS 1–10", UDim2.new(0.5, 5, 0, 280), UDim2.new(0.5, -5, 0, 44), COLORS.panelLight, COLORS.green)
local harvestButton = button(content, "HarvestAll", "HARVEST 1–10", UDim2.fromOffset(0, 334), UDim2.new(0.5, -5, 0, 44), COLORS.panelLight, COLORS.text)
local sellButton = button(content, "Sell", "SELL ALL", UDim2.new(0.5, 5, 0, 334), UDim2.new(0.5, -5, 0, 44), COLORS.panelLight, COLORS.text)
local autoButton = button(content, "AutoCycle", "START AUTO CYCLE", UDim2.fromOffset(0, 396), UDim2.new(1, 0, 0, 48), COLORS.greenDark, COLORS.text)
autoButton.TextSize = 13
local footer = label(content, "Footer", "Auto cycle: buy → plant 1–10 → wait → harvest → sell", UDim2.fromOffset(2, 454), UDim2.new(1, -4, 0, 18), 9, COLORS.muted, Enum.Font.Gotham)
footer.TextXAlignment = Enum.TextXAlignment.Center

local function setStatus(message, color)
	statusText.Text = message
	statusDot.BackgroundColor3 = color or COLORS.green
end

local function selectedCrop()
	refreshSeedOptions()
	if #seedOptions == 0 then return nil end
	return seedOptions[selectedSeedIndex]
end

local function cropDisplayName(crop)
	if not crop then return "No seed packets found" end
	return crop.Name
end

local function refreshSeedLabel()
	local crop = selectedCrop()
	seedName.Text = cropDisplayName(crop)
end
refreshSeedLabel()

local function getActionRemote()
	local remotes = garden:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("Action")
	if remote and remote:IsA("RemoteFunction") then return remote end
	return nil
end

local function invokeAction(action, argument)
	local remote = getActionRemote()
	if not remote then
		return false, "Garden.Remotes.Action RemoteFunction not found"
	end

	local callOk, result, detail = pcall(function()
		return remote:InvokeServer(action, argument)
	end)
	if not callOk then
		return false, action .. " request failed"
	end
	if result == false then
		return false, type(detail) == "string" and detail or (action .. " was declined")
	end
	if type(detail) == "string" then return true, detail end
	if type(result) == "string" then return true, result end
	return true, nil
end

local function mustInvoke(action, argument, progressMessage)
	setStatus(progressMessage, COLORS.green)
	local ok, response = invokeAction(action, argument)
	if not ok then error(response, 0) end
	return response
end

local function runJob(progressMessage, job)
	if jobInProgress then
		setStatus("An action is already running", COLORS.muted)
		return
	end
	jobInProgress = true
	setStatus(progressMessage, COLORS.green)
	task.spawn(function()
		local ok, result = pcall(job)
		jobInProgress = false
		if ok then
			setStatus(type(result) == "string" and result or "Action complete", COLORS.green)
		else
			setStatus(tostring(result), COLORS.red)
			if autoCycleRunning then
				autoCycleRunning = false
				autoButton.Text = "START AUTO CYCLE"
				autoButton.BackgroundColor3 = COLORS.greenDark
			end
		end
	end)
end

previousSeed.Activated:Connect(function()
	refreshSeedOptions()
	if #seedOptions == 0 then
		refreshSeedLabel()
		setStatus("SeedPackets folder is empty", COLORS.red)
		return
	end
	selectedSeedIndex = ((selectedSeedIndex - 2) % #seedOptions) + 1
	refreshSeedLabel()
end)
nextSeed.Activated:Connect(function()
	refreshSeedOptions()
	if #seedOptions == 0 then
		refreshSeedLabel()
		setStatus("SeedPackets folder is empty", COLORS.red)
		return
	end
	selectedSeedIndex = (selectedSeedIndex % #seedOptions) + 1
	refreshSeedLabel()
end)

lessWait.Activated:Connect(function()
	growWaitSeconds = math.max(growWaitSeconds - 10, 10)
	waitValue.Text = tostring(growWaitSeconds) .. "s"
end)
moreWait.Activated:Connect(function()
	growWaitSeconds = math.min(growWaitSeconds + 10, 600)
	waitValue.Text = tostring(growWaitSeconds) .. "s"
end)

buyButton.Activated:Connect(function()
	runJob("Buying seed packet…", function()
		local crop = selectedCrop()
		if not crop then error("No seed packets found in SeedPackets", 0) end
		local response = mustInvoke("Buy", crop, "Buying " .. crop.Name .. "…")
		return response or (crop.Name .. " bought")
	end)
end)

plantButton.Activated:Connect(function()
	runJob("Planting slots 1–10…", function()
		local crop = selectedCrop()
		if not crop then error("No seed packets found in SeedPackets", 0) end
		for i = 1, 10 do
			mustInvoke("Plant", { Crop = crop, Slot = i }, "Planting " .. crop.Name .. " in slot " .. i .. "/10…")
		end
		return "Slots 1–10 planted"
	end)
end)

harvestButton.Activated:Connect(function()
	runJob("Harvesting slots 1–10…", function()
		for i = 1, 10 do
			mustInvoke("Harvest", i, "Harvesting slot " .. i .. "/10…")
		end
		return "Slots 1–10 harvested"
	end)
end)

sellButton.Activated:Connect(function()
	runJob("Selling harvest…", function()
		local response = mustInvoke("Sell", nil, "Selling all harvested crops…")
		return response or "Harvest sold"
	end)
end)

local function waitForGrowTime(thisRun)
	local remaining = growWaitSeconds
	while remaining > 0 and autoCycleRunning and thisRun == autoCycleRunId do
		local step = math.min(remaining, 0.25)
		task.wait(step)
		remaining -= step
	end
end

autoButton.Activated:Connect(function()
	if autoCycleRunning then
		autoCycleRunning = false
		autoCycleRunId += 1
		autoButton.Text = "START AUTO CYCLE"
		autoButton.BackgroundColor3 = COLORS.greenDark
		setStatus("Auto cycle stopping…", COLORS.muted)
		return
	end
	if jobInProgress then
		setStatus("Wait for the current action to finish", COLORS.muted)
		return
	end
	if not selectedCrop() then
		setStatus("No seed packets found in SeedPackets", COLORS.red)
		return
	end
	if not getActionRemote() then
		setStatus("Garden.Remotes.Action not found", COLORS.red)
		return
	end

	autoCycleRunning = true
	jobInProgress = true
	autoCycleRunId += 1
	local thisRun = autoCycleRunId
	autoButton.Text = "STOP AUTO CYCLE"
	autoButton.BackgroundColor3 = Color3.fromRGB(137, 77, 69)

	task.spawn(function()
		local ok, result = pcall(function()
			while autoCycleRunning and thisRun == autoCycleRunId do
				local crop = selectedCrop()
				if not crop then error("No seed packets found in SeedPackets", 0) end
				for i = 1, 10 do
					if not autoCycleRunning or thisRun ~= autoCycleRunId then break end
					mustInvoke("Buy", crop, "Buying " .. crop.Name .. " for slot " .. i .. "/10…")
					if not autoCycleRunning or thisRun ~= autoCycleRunId then break end
					mustInvoke("Plant", { Crop = crop, Slot = i }, "Planting " .. crop.Name .. " in slot " .. i .. "/10…")
				end
				if not autoCycleRunning or thisRun ~= autoCycleRunId then break end
				setStatus("Waiting " .. tostring(growWaitSeconds) .. "s for crops…", COLORS.green)
				waitForGrowTime(thisRun)
				if not autoCycleRunning or thisRun ~= autoCycleRunId then break end
				for i = 1, 10 do
					if not autoCycleRunning or thisRun ~= autoCycleRunId then break end
					mustInvoke("Harvest", i, "Harvesting slot " .. i .. "/10…")
				end
				if not autoCycleRunning or thisRun ~= autoCycleRunId then break end
				mustInvoke("Sell", nil, "Selling harvested crops…")
			end
			return "Auto cycle stopped"
		end)
		jobInProgress = false
		if ok then
			if autoCycleRunning then setStatus("Auto cycle complete", COLORS.green) end
		else
			setStatus(tostring(result), COLORS.red)
		end
		autoCycleRunning = false
		autoButton.Text = "START AUTO CYCLE"
		autoButton.BackgroundColor3 = COLORS.greenDark
	end)
end)

-- Make the header draggable on desktop and touch screens.
local dragging = false
local dragInput
local dragStart
local startPosition
header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = window.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		window.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
	end
end)

closeButton.Activated:Connect(function()
	autoCycleRunning = false
	autoCycleRunId += 1
	gui:Destroy()
end)

