local Material = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/MaterialLua/master/Module.lua"))()

local button = game:GetService("Players").LocalPlayer.PlayerGui.DungeonFinishUI.Frame.ClaimButton
local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}

local X = Material.Load({
	Title = "Punch Sim",
	Style = 2,
	SizeX = 210,
	SizeY = 170,
	Theme = "Dark"
})

local Y = X.New({
	Title = "Main"
})

local Z = X.New({
	Title = "Others"
})

local A = Y.TextField({
	Text = "Wave to stop",
	Callback = function(DunString)
		getgenv().DunPlace = tonumber(DunString)
	end
})

local B = Y.Toggle({
	Text = "Auto Start Dungeon",
	Callback = function(Value)
		getgenv().DungeonTog = Value
		if getgenv().DungeonTog then game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("DungeonEvent"):FireServer("StartDungeon") end
	end
})

local C = Z.Button({
	Text = "Start Tora",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/ToraIsMe/ToraIsMe/main/0PUNCH"))()
	end
})

local D = Z.Button({
	Text = "Start Blox Hub",
	Callback = function()
		loadstring(game:HttpGet(('https://raw.githubusercontent.com/malicious-dev/RobloxScripting/main/punchsimulator.lua'),true))()
	end
})

local E = Z.Button({
	Text = "Start Auto Clicker",
	Callback = function()
		loadstring(game:HttpGet(('https://raw.githubusercontent.com/Levi4Chan/AnotherScriptStore/main/Misc/EzpiAC.lua'),true))()
	end
})

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
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("DungeonEvent"):FireServer("StartDungeon")
            end
        end
    end
end)
