repeat wait() until game:IsLoaded() and game.Players.LocalPlayer 
getgenv().RaceList = {"Ghoul"}

getgenv().Config = {
    ["Black Screen"] = false,
}

getgenv().StopV2 = false

getgenv().StopV3 = false

_G.Animation = false
_G.Seriality = false
loadstring(game:HttpGet("https://raw.githubusercontent.com/Bieoidungbuonnua/bonty/refs/heads/main/ghoulv3test.lua"))()
