loadstring(game:HttpGet("https://github.com/Levi4Chan/AnotherScriptStore/raw/main/Access/PunchSim.lua"))()

if getgenv().NotAllowed then return end

local Library = loadstring(game:HttpGet("https://pastebin.com/raw/vff1bQ9F"))()

local button = game:GetService("Players").LocalPlayer.PlayerGui.DungeonFinishUI.Frame.ClaimButton
local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}

local Window = Library.CreateLib("Punch Sim by Jay", "DarkTheme")

local Tab = Window:NewTab("Main")

local SectionA = Tab:NewSection("Auto Dungeon")
local SectionB = Tab:NewSection("Other Script")

SectionA:NewTextBox("Wave to stop", "Will stop at the exact wave before it starts.", function(txt)
	getgenv().DunPlace = tonumber(txt)
end)

SectionA:NewToggle("Auto Start Dungeon", "Will automatically starts a dungeon.", function(state)
    getgenv().DungeonTog = state
	if getgenv().DungeonTog then 
		game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("DungeonEvent"):FireServer("StartDungeon") 
	end
end)

SectionB:NewButton("Start Tora", "Must have for auto dungeon", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ToraIsMe/ToraIsMe/main/0PUNCH"))()
end)

SectionB:NewButton("Start Blox Hub", "For Eggs and Teleports!", function()
    loadstring(game:HttpGet(('https://raw.githubusercontent.com/malicious-dev/RobloxScripting/main/punchsimulator.lua'),true))()
end)


task.spawn(function()
    while task.wait() do
	    if getgenv().DungeonTog then
	    --print("Stopping on " .. "Wave: " .. tostring(getgenv().DunPlace))
            if game:GetService("Players").LocalPlayer.PlayerGui.DungeonMain.Frame.Wave.WaveNumber.Text ~= "Wave: " .. tostring(getgenv().DunPlace) then
                repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui.DungeonMain.Frame.Wave.WaveNumber.Text == "Wave: " .. tostring(getgenv().DunPlace)
                task.wait(2)
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("DungeonEvent"):FireServer("Exit")
                task.wait(5)
                for i,v in pairs(events) do
                    for i,v in pairs(getconnections(button[v])) do
                        v:Fire()
                    end
                end
                task.wait(8)
		if getgenv().DungeonTog then
                	game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("DungeonEvent"):FireServer("StartDungeon")
		end
            end
        end
    end
end)

local GC = getconnections or get_signal_cons
local Players = game:GetService("Players")
	if GC then
		for i,v in pairs(GC(Players.LocalPlayer.Idled)) do
			if v["Disable"] then
				v["Disable"](v)
			elseif v["Disconnect"] then
				v["Disconnect"](v)
			end
		end
	else
		Players.LocalPlayer.Idled:Connect(function()
			local VirtualUser = game:GetService("VirtualUser")
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
