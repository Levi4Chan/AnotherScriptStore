local AntiDisplayName = loadstring(game:HttpGet('https://raw.githubusercontent.com/Jaaaaay2/AnotherScriptStore/main/Misc/ADN%20Lib.lua'))(function()
    getgenv().Preferences = {}
end)

Preferences = {
    RetroNaming = false,
    ShowOriginalName = true,
    ApplyToLeaderboard = true,
    IdentifyFriends = {Toggle = true, Identifier = '[Friend]'},
    IdentifyBlocked = {Toggle = true, Identifier = '[Blocked]'},
    IdentifyPremium = {Toggle = true, Identifier = '[Premium]'},
    IdentifyDeveloper = {Toggle = true, Identifier = '[Game Dev]'},
    SpoofLocalPlayer = {Toggle = false, UseRandomName = true, NewName = 'Random Name Lol'},
    Orientation = 'Horizontal'
}

--[[
    -- Terms of Service
     - Credit me at all times, please: mothra#4150 or https://v3rmillion.net/member.php?action...e&uid=2988.
     - Don't sell this script.
     - Don't steal credit for this script.
]]
