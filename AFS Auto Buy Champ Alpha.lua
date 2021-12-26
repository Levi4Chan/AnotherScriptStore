--SaiyanPod 1000 Chikara, SaiyanPod2 20000 Spirit Shards, SaiyanPod3 10000 Chiakara, SaiyanPod4 25000000
local StartAmount = 0
local Price = 25000000
local MaxAmount = 105e8
local TotalRolls = MaxAmount / Price
local RemRolls = TotalRolls
rconsolename('AFS Auto Buy Output')
while getgenv().ABChamp do wait()
    
if game.Players.LocalPlayer.PlayerGui.Main.Category.Frames.Champions.Container.Space.Text == "Champion Inventory [16/16]" then
    rconsoleclear()
    rconsoleprint('@@RED@@')
    rconsoleprint("Champion Slot Full\n")
    getgenv().ABChamp = false
end
wait()
if game.Players.LocalPlayer.PlayerGui.Main.Category.Frames.Champions.Container.Space.Text ~= "Champion Inventory [16/16]" then
repeat
    fireclickdetector(game:GetService("Workspace").Shops.SaiyanPod4.ClickBox.ClickDetector)
    wait()
    for k,v in next,getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Main.Category.Frames.SpecialObtain.Container.Buy.MouseButton1Click) do
	    v.Function()
    end
    StartAmount = StartAmount + Price
    RemRolls = RemRolls - 1
until game.Players.LocalPlayer.PlayerGui.Main.Category.Frames.Champions.Container.Space.Text == "Champion Inventory [16/16]"
end

rconsoleprint('@@WHITE@@')
rconsoleprint("----------------------\n")

for k,v in next, game.Players.LocalPlayer.PlayerGui.Main.Category.Frames.Champions.Container.List:GetDescendants() do
    if v.Name == "16" and v.Container.ChampionName.Text ~= "Awakaned Naturo" and v.Container.ChampionName.Text ~= "Ultra Instinct Gokro" and v.Container.ChampionName.Text ~= "Brolie" then
        wait(0.1)
        rconsoleprint('@@LIGHT_CYAN@@')
        rconsoleprint("Selling " .. v.Container.ChampionName.Text .."\n")
        for z,s in next,getconnections(v.Container.View.MouseButton1Click) do
			s.Function()
		end
        wait(0.1)
        for i,o in next,getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Main.Category.Frames.Champions.Container.Details.Sell.MouseButton1Click) do
            o:Fire()
        end
        wait(0.1)
        for l,p in next,getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Main.Category.Frames.Champions.Container.Details.Confirm.Yes.MouseButton1Click) do
            p.Function()
        end
    end
end

wait()

for k,v in next, game.Players.LocalPlayer.PlayerGui.Main.Category.Frames.Champions.Container.List:GetDescendants() do
    if v.Name == "15" and v.Container.ChampionName.Text ~= "Awakaned Naturo" and v.Container.ChampionName.Text ~= "Ultra Instinct Gokro" and v.Container.ChampionName.Text ~= "Brolie" then
        wait(0.1)
        rconsoleprint('@@LIGHT_CYAN@@')
        rconsoleprint("Selling " .. v.Container.ChampionName.Text .."\n")
        for z,s in next,getconnections(v.Container.View.MouseButton1Click) do
			s.Function()
		end
        wait(0.1)
        for i,o in next,getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Main.Category.Frames.Champions.Container.Details.Sell.MouseButton1Click) do
            o:Fire()
        end
        wait(0.1)
        for l,p in next,getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Main.Category.Frames.Champions.Container.Details.Confirm.Yes.MouseButton1Click) do
            p.Function()
        end
    end
end
wait()
rconsoleprint('@@YELLOW@@')
rconsoleprint('Total Rolls Remaining: ' .. RemRolls .. "\n")
rconsoleprint('Total Amount Spent: ' .. StartAmount .. "\n")
rconsoleprint("Remaining Spirit Shards: " .. require(game:GetService("Players").LocalPlayer.PlayerGui.Main.MainClient.PlayerDataClient).Data.SpiritShards .."\n")

if StartAmount == MaxAmount  then
    rconsoleprint("Auto Buy Stopped. Max Amount Reached\n")
    getgenv().ABChamp = false
end
wait()
end
