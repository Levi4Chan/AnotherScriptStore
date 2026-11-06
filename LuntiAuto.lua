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
