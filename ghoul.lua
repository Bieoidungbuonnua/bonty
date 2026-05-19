


if not LPH_OBFUSCATED then
    LPH_ENCSTR = LPH_ENCSTR or function(...)
        return ...
    end
    LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(...)
        return ...
    end
end
ConChoChisiti36 = {
    PlayerData = {},
    Enemies = {},
    NPCs = {},
    Tools = {}
}

while not game.Players.LocalPlayer.Character
   or not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", "Marines")
    task.wait(1)
end
local placeIdd = game.PlaceId
local worldMap = {[2753915549] = "World1",[85211729168715] = "World1",[4442272183] = "World2",[79091703265657] = "World2",[7449423635] = "World3",[100117331123089] = "World3"}
local World2 = false


local CG = getgenv().Config
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local VIM = game:GetService("VirtualInputManager")
local LP = game:GetService("Players").LocalPlayer
GatCanChuaNguoiDep = RS.Remotes.CommF_:InvokeServer('CheckTempleDoor')
AiChoMaDiGatCan = RS.Remotes.CommF_:InvokeServer('RaceV4Progress', 'Check') == 4
Services = setmetatable({}, {__index = function(self, name)
    local s, c = pcall(function() return cloneref(game:GetService(name)) end)
    if s then rawset(self, name, c) return c
    else error("Invalid Roblox Service: " .. tostring(name))
    end
end})

local Root = LP.Character.HumanoidRootPart
_G.FarmV2 = false

LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    Root = char.HumanoidRootPart
end)
if LP then 
    Character = LP.Character
    Humanoid = Character:FindFirstChildWhichIsA("Humanoid") or Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart")
end
isHopping = false
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
    if not isHopping and child.Name == 'ErrorPrompt' and child:FindFirstChild('MessageArea') and child.MessageArea:FindFirstChild("ErrorFrame") then
        game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser"):InvokeServer("teleport", game.JobId)
    end
end)

spawn(function()
    while task.wait(1) do
        pcall(function()
            if not LP.Character:FindFirstChild("HasBuso") then
                RS.Remotes.CommF_:InvokeServer("Buso")
            end
        end)
    end
end)
getgenv().FailedJobIds = {}
getgenv().LastApiRefresh = 0
local apiUrl = nil

local function HopToServerByAPI(filterNames, maxPlayers, waitTime)
    isHopping = true
    maxPlayers = maxPlayers or 10
    waitTime = waitTime or 25

    if filterNames == "Cursed Captain" then
        apiUrl = 'http://fi11.bot-hosting.net:20758/api/name=cursedcaptain'
    end

    if tick() - getgenv().LastApiRefresh > 600 then
        getgenv().FailedJobIds = {}
        getgenv().LastApiRefresh = tick()
    end

    local CURRENT_PLACE_ID = game.PlaceId

    local ok, result = pcall(function()
        local HttpService = game:GetService("HttpService")
        local responseBody
        pcall(function() responseBody = game:HttpGet(apiUrl) end)
        if not responseBody then
            local reqFunc = (syn and syn.request) or request or http.request
            local req = reqFunc({ Url = apiUrl, Method = "GET" })
            responseBody = req.Body
        end
        local data = HttpService:JSONDecode(responseBody)
        if not data or not data.success or type(data.data) ~= "table" then
            print(" API trả về dữ liệu sai")
            return false
        end
        local seen = {}
        local servers = {}
        for _, entry in ipairs(data.data) do
            local jobId = entry.jobid
            local placeId = entry.placeid
            local players = tonumber(entry.player) or 99

            if jobId and placeId then
                if not seen[jobId] then
                    seen[jobId] = true
                    table.insert(servers, {
                        jobid = jobId,
                        placeid = placeId,
                        players = players,
                    })
                end
            end
        end
        local filtered = {}
        for _, s in ipairs(servers) do
            if s.placeid == CURRENT_PLACE_ID then
                table.insert(filtered, s)
            end
        end
        table.sort(filtered, function(a, b) return a.players < b.players end)
        print(" Tìm thấy " .. #filtered .. " server hợp lệ")
        local triedCount = 0
        for _, server in ipairs(filtered) do
            local jobId = server.jobid
            local players = server.players

            if jobId == game.JobId then continue end
            if getgenv().FailedJobIds[jobId] then continue end
            if players >= maxPlayers then continue end

            triedCount = triedCount + 1
            print(" " .. filterNames .. " | " .. players .. " người | Đang join...")
            local teleportOk = pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser"):InvokeServer("teleport", jobId)
            end)
            if teleportOk then
                task.wait(15)
                return true
            else
                getgenv().FailedJobIds[jobId] = tick()
                print(" Không vào được server #" .. triedCount)
                task.wait(1)
            end
        end
        print(" Hết server phù hợp | Đợi API cập nhật...")
        for i = waitTime, 1, -1 do
            if getgenv().StopV3 then return false end
            print(" Đợi API: " .. i .. "s | " .. filterNames)
            task.wait(1)
        end
        return false
    end)
    return ok and result
end
getgenv().StopV2 = false
local Character = LP.Character
repeat task.wait(2)
until Character
    and Character:FindFirstChild("HumanoidRootPart")
    and Character:FindFirstChildWhichIsA("Humanoid")
    and Character:IsDescendantOf(workspace.Characters)

pcall(function() LP.PlayerGui:FindFirstChild("Blank"):Destroy() end)
local ScreenGuis = Instance.new("ScreenGui", LP.PlayerGui)
if CG["Black Screen"] then
local BlankScreen = Instance.new("ScreenGui", LP.PlayerGui);BlankScreen.Name = "Blank";BlankScreen.ResetOnSpawn = false;BlankScreen.DisplayOrder = -math.huge;BlankScreen.IgnoreGuiInset = true;local Black = Instance.new("Frame", BlankScreen);Black.Name = "Black Screen";Black.Size = UDim2.new(1, 0, 1, 0);Black.BackgroundColor3 = Color3.new(0, 0, 0);Black.ZIndex = -math.huge
if Black.Visible then RunService:Set3dRenderingEnabled(false) end
end
local label = Instance.new("TextLabel", ScreenGuis);label.Name = "CenteredLabel";label.AnchorPoint = Vector2.new(0.5, 0.5);label.Position = UDim2.new(0.5, 0, 0.5, 0);label.Size = UDim2.new(0.6, 0, 0.15, 0);label.Text = "Loading...";label.TextScaled = true;label.TextWrapped = true;label.TextXAlignment = Enum.TextXAlignment.Center;label.TextYAlignment = Enum.TextYAlignment.Center;label.BackgroundTransparency = 1;label.Font = Enum.Font.GothamSemibold;label.TextSize = 48;label.TextColor3 = Color3.fromRGB(255, 255, 255)
local function SetText(newText)
    label.Text = newText
    print(newText)
end
local shouldTween = false
local block = Instance.new("Part", workspace);block.Name = "TweenBlock";block.Size = Vector3.new(1, 1, 1);block.Anchored = true;block.CanCollide = false;block.CanTouch = false;block.Transparency = 1

task.spawn(function()
    while task.wait() do
        pcall(function()
            if shouldTween and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LP.Character.HumanoidRootPart
                hrp.CFrame = block.CFrame 
                local Head = LP.Character:FindFirstChild("Head")
                if Head and not Head:FindFirstChild("AntiFall") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "AntiFall"
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    bv.Velocity = Vector3.zero
                    bv.Parent = Head
                end
                for _, part in LP.Character:GetDescendants() do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
end)
    _G.FastAttack = true

if _G.FastAttack then
    local _ENV = (getgenv or getrenv or getfenv)()

    local function SafeWaitForChild(parent, childName)
        local success, result = pcall(function()
            return parent:WaitForChild(childName)
        end)
        if not success or not result then
            warn("noooooo: " .. childName)
        end
        return result
    end

    local function WaitChilds(path, ...)
        local last = path
        for _, child in {...} do
            last = last:FindFirstChild(child) or SafeWaitForChild(last, child)
            if not last then
                break
            end
        end
        return last
    end

    local VirtualInputManager = game:GetService("VirtualInputManager")
    local CollectionService = game:GetService("CollectionService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TeleportService = game:GetService("TeleportService")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer

    if not Player then
        warn("Không tìm thấy người chơi cục bộ.")
        return
    end

    local Remotes = SafeWaitForChild(ReplicatedStorage, "Remotes")
    if not Remotes then
        return
    end

    local Validator = SafeWaitForChild(Remotes, "Validator")
    local CommF = SafeWaitForChild(Remotes, "CommF_")
    local CommE = SafeWaitForChild(Remotes, "CommE")

    local ChestModels = SafeWaitForChild(workspace, "ChestModels")
    local WorldOrigin = SafeWaitForChild(workspace, "_WorldOrigin")
    local Characters = SafeWaitForChild(workspace, "Characters")
    local Enemies = SafeWaitForChild(workspace, "Enemies")
    local Map = SafeWaitForChild(workspace, "Map")

    local EnemySpawns = SafeWaitForChild(WorldOrigin, "EnemySpawns")
    local Locations = SafeWaitForChild(WorldOrigin, "Locations")

    local RenderStepped = RunService.RenderStepped
    local Heartbeat = RunService.Heartbeat
    local Stepped = RunService.Stepped

    local Modules = SafeWaitForChild(ReplicatedStorage, "Modules")
    local Net = SafeWaitForChild(Modules, "Net")

    local sethiddenproperty = sethiddenproperty or function(...)
        return ...
    end
    local setupvalue = setupvalue or (debug and debug.setupvalue)
    local getupvalue = getupvalue or (debug and debug.getupvalue)

    local Settings = {
        AutoClick = true,
        ClickDelay = 0
    }

    local Module = {}

    Module.FastAttack = (function()
        if _ENV.rz_FastAttack then
            return _ENV.rz_FastAttack
        end

        local FastAttack = {
            Distance = 100,
            attackMobs = true,
            attackPlayers = true,
            Equipped = nil
        }

        local RegisterAttack = SafeWaitForChild(Net, "RE/RegisterAttack")
        local RegisterHit = SafeWaitForChild(Net, "RE/RegisterHit")

        local function IsAlive(character)
            return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
        end

        local function ProcessEnemies(OthersEnemies, Folder)
            local BasePart = nil
            for _, Enemy in Folder:GetChildren() do
                local Head = Enemy:FindFirstChild("Head")
                if Head and IsAlive(Enemy) and Player:DistanceFromCharacter(Head.Position) < FastAttack.Distance then
                    if Enemy ~= Player.Character then
                        table.insert(OthersEnemies, {Enemy, Head})
                        BasePart = Head
                    end
                end
            end
            return BasePart
        end

        function FastAttack:Attack(BasePart, OthersEnemies)
            if not BasePart or #OthersEnemies == 0 then
                return
            end
            RegisterAttack:FireServer(Settings.ClickDelay or 0)
            RegisterHit:FireServer(BasePart, OthersEnemies)
        end

        function FastAttack:AttackNearest()
            local OthersEnemies = {}
            local Part1 = ProcessEnemies(OthersEnemies, Enemies)
            local Part2 = ProcessEnemies(OthersEnemies, Characters)

            local character = Player.Character
            if not character then
                return
            end
            local equippedWeapon = character:FindFirstChildOfClass("Tool")

            if equippedWeapon and equippedWeapon:FindFirstChild("LeftClickRemote") then
                for _, enemyData in ipairs(OthersEnemies) do
                    local enemy = enemyData[1]
                    local direction = (enemy.HumanoidRootPart.Position - character:GetPivot().Position).Unit
                    pcall(function()
                        equippedWeapon.LeftClickRemote:FireServer(direction, 1)
                    end)
                end
            elseif #OthersEnemies > 0 then
                self:Attack(Part1 or Part2, OthersEnemies)
            else
                task.wait(0)
            end
        end

        function FastAttack:BladeHits()
            local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
            if Equipped and Equipped.ToolTip ~= "Gun" then
                self:AttackNearest()
            else
                task.wait(0)
            end
        end

        task.spawn(function()
            while task.wait(Settings.ClickDelay) do
                if Settings.AutoClick then
                    FastAttack:BladeHits()
                end
            end
        end)

        _ENV.rz_FastAttack = FastAttack
        return FastAttack
    end)()
end
local remote, idremote
for _, v in next, ({game.ReplicatedStorage.Util, game.ReplicatedStorage.Common, game.ReplicatedStorage.Remotes,game.ReplicatedStorage.Assets, game.ReplicatedStorage.FX}) do
    for _, n in next, v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end
    v.ChildAdded:Connect(function(n)
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end)
end
task.spawn(function()
    while task.wait(0.05) do
        local char = game.Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local parts = {}
        for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0 and (hrp.Position - root.Position).Magnitude <= 60 then
                    for _, _v in ipairs(v:GetChildren()) do
                        if _v:IsA("BasePart") and (hrp.Position - root.Position).Magnitude <= 60 then
                            parts[#parts + 1] = {v, _v}
                        end
                    end
                end
            end
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if #parts > 0 and tool and
            (tool:GetAttribute("WeaponType") == "Melee" or tool:GetAttribute("WeaponType") == "Sword") then
            pcall(function()
                require(game.ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
                game.ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head = parts[1][1]:FindFirstChild("Head")
                if not head then
                    return
                end
                game.ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(head, parts, {}, tostring(
                    game.Players.LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
                cloneref(remote):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
                    return string.char(
                        bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
                end), bit32.bxor(idremote + 909090, game.ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2), head,
                    parts)
            end)
        end
    end
end)

local P = game:GetService("Players")
local L = P.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local W = workspace
local M = RS:WaitForChild("Modules")
local CU = pcall(require, M:WaitForChild("CombatUtil")) and require(M.CombatUtil) or nil
local WD = pcall(require, M:WaitForChild("WeaponData")) and require(M.WeaponData) or nil
if not CU then return end
local N = M:FindFirstChild("Net")
local RA = N and (N:FindFirstChild("RE/RegisterAttack") or N:FindFirstChild("RegisterAttack"))
local RH = N and (N:FindFirstChild("RE/RegisterHit") or N:FindFirstChild("RegisterHit"))	
local IS
do
	local PS = L:WaitForChild("PlayerScripts")
    for d ,  s in next, PS:GetChildren() do
        if s:IsA("LocalScript") then
            local ok, env = pcall(getsenv, s)
            if ok and env and env._G and typeof(env._G.SendHitsToServer) == "function" then
                IS = env._G.SendHitsToServer
                break
            end
        end
    end
    if not IS and _G.SendHitsToServer then
        IS = _G.SendHitsToServer
    end
end

pcall(function()
    hookfunction(CU.GetComboPaddingTime, function()
        return 0
    end)
    hookfunction(CU.GetAttackCancelMultiplier, function()
        return 0
    end)
    hookfunction(CU.CanAttack, function()
        return true
    end)
end)

local HList = {
    "RightLowerArm",
    "RightUpperArm",
    "LeftLowerArm",
    "LeftUpperArm",
    "RightHand",
    "LeftHand",
    "HumanoidRootPart",
    "Head",
    "UpperTorso",
    "LowerTorso"
}

okm = function(m)
    local h = m:FindFirstChildWhichIsA("Humanoid")
    return h and h.Health > 0 and m:FindFirstChild("HumanoidRootPart") and not m:FindFirstChild("VehicleSeat")
end

hpt = function(m)
    for _ = 1, 2 do
        local p = m:FindFirstChild(HList[math.random(1, #HList)])
        if p then
            return p
        end
    end
    return m:FindFirstChild("HumanoidRootPart")
end

near = function(r, maxN)
    local out, ch = {}, L.Character
    if not ch then
        return out
    end

    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return out
    end
    local p0 = hrp.Position

    for _, grp in next, {
        W:FindFirstChild("Enemies"),
        W:FindFirstChild("Characters")
    } do
        if grp then
            for _, v in next, grp:GetChildren() do
                if #out >= maxN then
                    break
                end
                if v ~= ch and okm(v) then
                    local hr = v:FindFirstChild("HumanoidRootPart")
                    if hr and (hr.Position - p0).Magnitude <= r then
                        out[#out + 1] = v
                    end
                end
            end
        end
    end

    for _, pl in next, P:GetPlayers() do
        if #out >= maxN then
            break
        end
        if pl ~= L and pl.Character and okm(pl.Character) then
            local hr = pl.Character:FindFirstChild("HumanoidRootPart")
            if hr and (hr.Position - p0).Magnitude <= r then
                out[#out + 1] = pl.Character
            end
        end
    end

    return out
end

pkg = function(t)
    local main, hits = nil, {}
    for _, v in next, t do
        if okm(v) then
            local p = hpt(v)
            if p then
                if not main then
                    main = p
                end
                hits[#hits + 1] = {
                    v,
                    p
                }
            end
        end
    end
    return main, hits
end

send = function(main, hits)
    if main and #hits > 0 then
        if IS then
            IS(main, hits)
        elseif RH then
            RH:FireServer(main, hits)
        end
    end
end

local AC, HM = {}, nil

setH = function(c)
    local h = c:FindFirstChildWhichIsA("Humanoid")
    if h then
        HM = h;
        AC = {}
    end
end

if L.Character then
    setH(L.Character)
end
L.CharacterAdded:Connect(function(c)
    c:WaitForChild("Humanoid")
    setH(c)
end)

anim = function(tool)
    if not (HM and tool and WD) then
        return
    end
    local wn = CU:GetWeaponName(tool)
    local data = WD[wn] or WD[string.lower(wn)] or WD[CU:GetPureWeaponName(wn)]
    if not (data and data.Moveset and data.Moveset.Basic) then
        return
    end

    local mv = data.Moveset.Basic
    local a = mv[math.random(1, #mv)]
    if not (a and a.AnimationId) then
        return
    end

    if not AC[a.AnimationId] then
        local n = Instance.new("Animation")
        n.AnimationId = a.AnimationId
        AC[a.AnimationId] = HM:LoadAnimation(n)
    end

    local tr = AC[a.AnimationId]
    if tr then
        tr:Play(1, 1, 0.2)
    end
end

spawn(function()
    while task.wait(0.019) do
        local ok, err = pcall(function()
            local ch = L.Character
            if not ch then
                return
            end

            local tool = ch:FindFirstChildOfClass("Tool")
            if not tool then
                return
            end

            local tg = near(60, 20)
            if #tg == 0 then
                return
            end

            local main, hits = pkg(tg)
            if not main then
                return
            end

            if RA then
                RA:FireServer(0)
            end
			if _G.Animation then
            	anim(tool)
			end
			if _G.Seriality then
				if tool.ToolTip == "Blox Fruit" then
					if tg then
						local LeftClickRemote = tool:FindFirstChild('LeftClickRemote');
						if LeftClickRemote then
							LeftClickRemote:FireServer(Vector3.new(0.01, - 500, 0.01), 1, true);
							LeftClickRemote:FireServer(false)
						end
					end
				end
            end
            task.defer(function()
                pcall(function()
                    CU:AttackStart(main, 1)
                    CU:RunHitDetection(main.Parent or main, 1, {
                        _Object = {
                            Length = 0.02,
                            IsPlaying = true
                        }
                    })
                end)
            end)

            send(main, hits)
        end)
    end
end)
FastAttack = loadstring([[
        local Modules = game.ReplicatedStorage.Modules
        local Net = Modules.Net
        local Register_Hit, Register_Attack = Net:WaitForChild('RE/RegisterHit'), Net:WaitForChild('RE/RegisterAttack')
        local Funcs = {}
        function GetAllBladeHits()
            bladehits = {}
            for _, v in pairs(workspace.Enemies:GetChildren()) do
                if v:FindFirstChild('Humanoid') and v:FindFirstChild('HumanoidRootPart') and v.Humanoid.Health > 0 
                and (v.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 65 then
                    table.insert(bladehits, v)
                end
            end
            return bladehits
        end
        function Getplayerhit()
            bladehits = {}
            for _, v in pairs(workspace.Characters:GetChildren()) do
                if v.Name ~= game.Players.LocalPlayer.Name and v:FindFirstChild('Humanoid') and v:FindFirstChild('HumanoidRootPart') and v.Humanoid.Health > 0 
                and (v.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 65 then
                    table.insert(bladehits, v)
                end
            end
            return bladehits
        end

        local Net = (Services.ReplicatedStorage.Modules.Net)

        local RegisterAttack = require(Net):RemoteEvent('RegisterAttack', true)
        local RegisterHit = require(Net):RemoteEvent('RegisterHit', true)

        function Funcs:Attack()
            
            
            local bladehits = {}
            for r,v in pairs(GetAllBladeHits()) do
                table.insert(bladehits, v)
        
            end
            for r,v in pairs(Getplayerhit()) do
                table.insert(bladehits, v)
            end
            
            if #bladehits == 0 then
                
                return
            end
            
            local args = {
                [1] = nil;
                [2] = {},
                [4] = '078da341'
            }
            for r, v in pairs(bladehits) do
                
                
                RegisterAttack:FireServer(0)
                if not args[1] then
                    args[1] = v.Head
                end
                table.insert(args[2], {
                    [1] = v,
                    [2] = v.HumanoidRootPart
                })
                table.insert(args[2], v)
            end
            
            
            RegisterHit:FireServer(unpack(args))
        end

        task.spawn(function() 
            while task.wait(.05) do 
                if _G.FastAttack == os.time() then 
                    pcall(function() 
                        Funcs:Attack() 
                    end)
                end 
            end
        end)

        getgenv().Attack = function(MonResult) 
            pcall(function() 
                _G.FastAttack = os.time()
            end)
        end 
        ]])



function ConvertTo(Type, Data)
    return Type.new(Data.x, Data.y, Data.z)
end

function CaculateDistance(Origin, Destination)
    if not Destination then
        Destination = LP.Character:GetPrimaryPartCFrame()
    end

    local Origin, Destination = ConvertTo(Vector3, Origin), ConvertTo(Vector3, Destination)

    return (Origin - Destination).Magnitude
end

function TweenTo(Position)
    if not Position then return end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    Position = typeof(Position) ~= "CFrame" and CFrame.new(Position) or Position
    if LP:GetAttribute("ExactLocation") == "Submerged Island" then
        RS:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("TeleportToSpawn")
        task.wait(6)
    end
    block.CFrame = LP.Character.HumanoidRootPart.CFrame
    _tp(Position)
end

function _tp(Pos)
    local lp = game:GetService("Players").LocalPlayer
    if not Pos or not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end

    local hrp = lp.Character.HumanoidRootPart
    for _, v in pairs(lp.Character:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = false end
    end
    local bv = hrp:FindFirstChild("TweenBV")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "TweenBV"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hrp
    end
    local dist = (hrp.Position - Pos.Position).Magnitude
    local speed = 350
    if dist < 100 then speed = 400 end
    local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    local tween = game:GetService("TweenService"):Create(hrp, tweenInfo, {CFrame = Pos})
    tween:Play()
    if dist < 5 then 
        tween:Cancel()
        hrp.CFrame = Pos 
    end
end

local function CheckSea(v)
    local ok, result = pcall(function()
        return v == tonumber(workspace:GetAttribute("MAP"):match("%d+"))
    end)
    return ok and result
end

local function CheckTool(v)
    return (LP.Backpack:FindFirstChild(v) or (LP.Character and LP.Character:FindFirstChild(v))) and true or false
end

local function GetBP(v)
    return LP.Backpack:FindFirstChild(v) or (LP.Character and LP.Character:FindFirstChild(v))
end

local function EquipByTip(toolTip)
    if not LP.Character then return end
    local equipped = LP.Character:FindFirstChildOfClass("Tool")
    if equipped and equipped.ToolTip == toolTip then return equipped end
    for _, tool in pairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == toolTip then
            LP.Character:FindFirstChildOfClass("Humanoid"):EquipTool(tool)
            return tool
        end
    end
    return nil
end

local function GetConnectionEnemies(a)
    for _, v in pairs(RS:GetChildren()) do
        if v:IsA("Model") and ((typeof(a) == "table" and table.find(a, v.Name)) or v.Name == a)
           and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            return v
        end
    end
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:IsA("Model") and ((typeof(a) == "table" and table.find(a, v.Name)) or v.Name == a)
           and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            return v
        end
    end
    return nil
end
local function invoke(...)
    local args = {...}
    local s, r = pcall(function() return RS.Remotes.CommF_:InvokeServer(unpack(args)) end)
    return s, r
end

local function getCurrentRace()
    local s, r = pcall(function() return LP.Data.Race.Value end)
    return s and r or nil
end

local function UseSkill(key)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, key, false, game)
    task.wait(0.3)
end


local function TweenObject(Object, Pos, Speed)
    Speed = Speed or 350
    if not Object or not Pos then return end
    local Distance = (Pos.Position - Object.Position).Magnitude
    local info = TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)
    local tween = TS:Create(Object, info, {CFrame = Pos})
    tween:Play()
end

local function GetMobPosition(EnemiesName)
    local pos = Vector3.zero
    local count = 0
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == EnemiesName and v:FindFirstChild("HumanoidRootPart") then
            pos = pos + v.HumanoidRootPart.Position
            count = count + 1
        end
    end
    if count == 0 then return nil end
    return pos / count
end

local titleMap = {
    Ghoul = "Ghoul"
}

local function HasRaceV2(raceName)
    local ok, titles = pcall(function() return RS.Remotes.CommF_:InvokeServer("getTitles") end)
    if not ok or not titles or typeof(titles) ~= "table" then return false end
    local keyword = titleMap[raceName]
    if not keyword then return false end
    for _, title in pairs(titles) do
        if title.Unlocked and title.Description
           and title.Description:find("V2") and title.Description:find(keyword) then
            return true
        end
    end
    return false
end

local function PrintV2Status()
    print(" V2 Status:")
    for _, race in ipairs(getgenv().RaceList) do
        print(HasRaceV2(race) and ("   " .. race) or ("   " .. race))
    end
    print("Version Race :" .. RS.Remotes.CommF_:InvokeServer("getRaceLevel"))
end
local function BringMob()
    pcall(function()
        sethiddenproperty(LP, "SimulationRadius", math.huge)
    end)
    
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = LP.Character.HumanoidRootPart.Position
    
    for _, enemy in pairs(workspace.Enemies:GetChildren()) do
        if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") 
           and enemy.Humanoid.Health > 0 then
            
            local dist = (enemy.HumanoidRootPart.Position - myPos).Magnitude
            if dist <= 350 then
                enemy.HumanoidRootPart.CFrame = CFrame.new(myPos + Vector3.new(0, 0, 5))
                enemy.HumanoidRootPart.CanCollide = false
                enemy.Humanoid.WalkSpeed = 0
                enemy.Humanoid.JumpPower = 0
                
                if enemy.Humanoid:FindFirstChild("Animator") then
                    enemy.Humanoid.Animator:Destroy()
                end
            end
        end
    end
end
BringMonster = (function(name, count) count = count or 3
    if count < 2 then return end
    pcall(function() setscriptable(LP, "SimulationRadius", true) end)
    pcall(function() sethiddenproperty(LP, "SimulationRadius", math.huge) end)
    xpcall((function()
        local mob, t = {}, nil
        for _, v in next, workspace.Enemies:GetChildren() do
            local h = v:FindFirstChildWhichIsA("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.Health > 0 and (not name or v.Name == name)
                and (HumanoidRootPart.Position - hrp.Position).Magnitude <= ((count or 3) * 250) then
                if not table.find(mob, function(chosen)
                    local chrp = chosen:FindFirstChild("HumanoidRootPart")
                    return chrp and (hrp.Position - chrp.Position).Magnitude <= 5
                end) then mob[#mob+1], t = v, t or hrp.CFrame
                end
                if #mob >= (count or 3) then break end
            end
        end
        if not t then return end
        for i = 1, #mob do
            local hrp = mob[i]:FindFirstChild("HumanoidRootPart")
            local h = mob[i]:FindFirstChildWhichIsA("Humanoid")
            if hrp and (not isnetworkowner or isnetworkowner(hrp)) then
                -- h.PlatformStand = false h.AutoRotate = false
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = t * CFrame.new((i-1) * 2, 0, 0)
            end
        end
    end), (function(r) warn("Modules Error [BM]: ".. r) end))
end)
FastAttack()
local lastKenCall=tick() -- pray
KillMonster=(function(x)
    xpcall(function()
        if workspace.Enemies:FindFirstChild(x) then
            for _,v in next,workspace.Enemies:GetChildren() do
                local vh=v:FindFirstChildWhichIsA("Humanoid") local vhrp=v:FindFirstChild("HumanoidRootPart")
                if vh and vh.Health > 0 and vhrp and v.Name==x then

                    TweenTo(CFrame.new(vhrp.Position + (vhrp.CFrame.LookVector * 20) + Vector3.new(0, vhrp.Position.Y > 60 and -20 or 20, 0)))
                        return
                end
            end
        end
        for _,v in next,ReplicatedStorage:GetChildren() do
            local vhrp=v:FindFirstChild("HumanoidRootPart")
            if v:IsA("Model") and vhrp and v.Name==x then TweenTo(vhrp.CFrame) return end
        end
    end,function(e) warn("Modules ERROR:",e) end)
end)

local function HopServer()
    SetText(" Hop server...")
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        local servers = HttpService:JSONDecode(
            game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        ).data
        for _, server in pairs(servers) do
            if server.playing < 12 and server.id ~= game.JobId then
                game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser"):InvokeServer("teleport", server.id)
                task.wait(5) break
            end
        end
    end)
end


local function GetEctoCount()
    local ok, inv = pcall(function()
        return RS.Remotes.CommF_:InvokeServer("getInventory")
    end)
    if ok and inv then
        for _, v in pairs(inv) do
            if v.Name == "Ectoplasm" and v.Type == "Material" then
                return v.Count or 0
            end
        end
    end
    return 0
end
local function GetPlayers()
    local players = {}
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LP and player.Character 
           and player.Character:FindFirstChild("HumanoidRootPart")
           and player.Character:FindFirstChild("Humanoid")
           and player.Character.Humanoid.Health > 0 then
            table.insert(players, player)
        end
    end
    return players
end
local function IsValidLevel(player)
    local myLevel = LP.Data.Level.Value
    local targetLevel = GetPlayerLevel(player)
    local diff = math.abs(myLevel - targetLevel)
    return diff <= 200
end
local function GetPlayerRace(player)
    local ok, race = pcall(function()
        return player.Data.Race.Value
    end)
    return ok and race or nil
end
local function GetPlayerLevel(player)
    local ok, level = pcall(function()
        return player.Data.Level.Value
    end)
    return ok and level or 0
end
local function FindWeakestPlayer()
    local players = GetPlayers()
    if #players == 0 then return nil end
    
    table.sort(players, function(a, b)
        return GetPlayerLevel(a) < GetPlayerLevel(b)
    end)
    
    return players[1]
end
local function FindPlayerWithRace(raceName)
    for _, player in pairs(GetPlayers()) do
        if GetPlayerRace(player) == raceName then
            return player
        end
    end
    return nil
end
local function IsPvpEnabled()
    local ok, result = pcall(function()
        return not LP.PlayerGui.Main.PvpDisabled.Visible
    end)
    return ok and result
end


local function AttackPlayer(targetPlayer, reason)
    if not targetPlayer or not targetPlayer.Character then return false end

    if not IsValidLevel(targetPlayer) then
        SetText("Skip" .. targetPlayer.Name .. " ( > 200 Lv)")
        task.wait(1)
        return false
    end

    local targetChar = targetPlayer.Character
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local targetHum = targetChar:FindFirstChild("Humanoid")
    
    if not targetHRP or not targetHum or targetHum.Health <= 0 then return false end
    if not IsPvpEnabled() then
        pcall(function() RS.Remotes.CommF_:InvokeServer("EnablePvp") end)
    end

    local lastHealth = targetHum.Health
    local lastDamageTime = tick()
    
    shouldTween = true

    repeat
        task.wait(0.1)
        if not targetPlayer.Character or not targetHum or targetHum.Health <= 0 or getgenv().StopV2 then break end
        
        targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetHRP then break end
        if targetPlayer:GetAttribute('IslandRaiding') then
            SetText("Skip" .. targetPlayer.Name .. " ( Raiding )")
            task.wait(1)
            return false
        end
        SetText(reason .. " | Attack: " .. targetPlayer.Name .. " | HP: " .. math.floor(targetHum.Health))
        _tp(targetHRP.CFrame * CFrame.new(0, 5, 2))
        local dist = (LP.Character.HumanoidRootPart.Position - targetHRP.Position).Magnitude
        if dist < 40 then
            EquipByTip("Melee")
            game:GetService("VirtualUser"):ClickButton1(Vector2.new()) 
            UseSkill("Z") UseSkill("X") UseSkill("C")
        end
        if targetHum.Health < lastHealth then
            lastHealth = targetHum.Health
            lastDamageTime = tick() 
        elseif tick() - lastDamageTime > 10 then
            SetText("Player not enable Pvp -> check other player")
            task.wait(1)
            return false
        end
        
    until not targetHum or targetHum.Health <= 0
    
    SetText("Done kill player")
    return true
end


getgenv().KilledPlayers = getgenv().KilledPlayers or {}

local function CountKilledPlayers()
    local count = 0
    for _, v in pairs(getgenv().KilledPlayers) do
        if v then count = count + 1 end
    end
    return count
end

function StopTween()
    shouldTween = false
    if block and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        block.CFrame = LP.Character.HumanoidRootPart.CFrame
    end
end

local function FarmEctoplasm()

    if LP:GetAttribute("CurrentLocation") ~= "Cursed Ship" then
        SetText("Đi vào Cursed Ship...")
        pcall(function()
            RS.Remotes.CommF_:InvokeServer(
                "requestEntrance",
                Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)
            )
        end)
        task.wait(1)
    end

    local ectoMobs = {
        "Ship Deckhand",
        "Ship Engineer",
        "Ship Steward",
        "Ship Officer",
        "Arctic Warrior",
    }

    v = GetConnectionEnemies(ectoMobs)
    if v then
        BringMob()
        repeat task.wait() KillMonster(v.Name)
        until not v.Parent
               or v.Humanoid.Health <= 0
               or getgenv().StopV2
    else
        wait(1)
    end

end


local function FindAndKillCursedCaptain()
    captain =  GetConnectionEnemies("Cursed Captain")
    if captain then
        if LP:GetAttribute("CurrentLocation") ~= "Cursed Ship" then
        SetText("Đi vào Cursed Ship...")
        pcall(function()
            RS.Remotes.CommF_:InvokeServer(
                "requestEntrance",
                Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)
            )
        end)
        task.wait(1)
        else
        SetText("Attack Cursed Captain!")
        local hrp = captain:FindFirstChild("HumanoidRootPart")

        repeat
            task.wait(0.3)
            if getgenv().StopV2 then break end
            hrp = captain:FindFirstChild("HumanoidRootPart")
            if not hrp then break end

            local hp = math.floor(captain.Humanoid.Health / captain.Humanoid.MaxHealth * 100)
            SetText("Atack Cursed Captain HP: " .. hp .. "%")
            EquipByTip("Melee")
            KillMonster("Cursed Captain")
            
        until not captain.Parent or captain.Humanoid.Health <= 0 or getgenv().StopV2

        if captain and captain.Parent and captain.Humanoid.Health <= 0 then
            SetText(" Cursed Captain Die")
            return true
        end
       end
    else 
    SetText("ko co boss")
    HopToServerByAPI("Cursed Captain", 12, 2)
    end

    return false
end

local function HasUnlockedGhoul()
    local ecto = GetEctoCount()
    if ecto < 100 then return false end
local args = {
	"Ectoplasm",
	"Buy",
	4
}
game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))

    if getCurrentRace() == "Ghoul" then
        return true
    end

    return false
end

local function GetGhoulFirstTime()
    SetText(" Start Get Ghoul Race")

    while not getgenv().StopV2 do
        task.wait(.5)


        if getCurrentRace() == "Ghoul" then
            SetText("Đã có Ghoul!")
            break
        end

        local ecto = GetEctoCount()
        local hasTorch = CheckTool("Hellfire Torch")

        if ecto < 100 then
            SetText("Farm Ecto " .. ecto .. "/100")
            FarmEctoplasm()

        elseif not hasTorch then
 FindAndKillCursedCaptain()
        else
            SetText("Done Ecto , Torch → Mua Ghoul!")
local args = {
	"Ectoplasm",
	"Buy",
	4
}
game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))


            if getCurrentRace() == "Ghoul" then
                SetText(" Buy Ghoul Race done")
                break
            else
                SetText(" Buy Failed , retry....")
            end
        end
    end
end

local function GetV2()
    while task.wait(0.5) do
        if not _G.FarmV2 then break end
        local state = RS.Remotes.CommF_:InvokeServer("Alchemist", "1")

        if state == 0 then
            SetText("V2 | Get quest")
            RS.Remotes.CommF_:InvokeServer("Alchemist", "2")
        elseif state == 1 then
            if not GetBP("Flower 1") then
                SetText("V2 | Flower 1")
                TweenTo(workspace.Flower1.CFrame)
            elseif not GetBP("Flower 2") then
                SetText("V2 | Flower 2")
                TweenTo(workspace.Flower2.CFrame)
            elseif not GetBP("Flower 3") then
                SetText("V2 | Kill Swan Pirate")
                local v = GetConnectionEnemies("Swan Pirate")
                if v then
                    EquipByTip("Melee")
                    BringMob()
                    repeat task.wait() KillMonster("Swan Pirate")
                    until GetBP("Flower 3") or not v.Parent or v.Humanoid.Health <= 0
                else TweenTo(CFrame.new(980.099, 121.331, 1287.209))
                end
            end
        elseif state == 2 then
            SetText("V2 | Nộp quest")
            RS.Remotes.CommF_:InvokeServer("Alchemist", "3")
            task.wait(1)
        elseif state == -2 then
            SetText(" V2 Done !")
            _G.FarmV2 = false
            break
        end
    end
end


local function switchToRace(targetRace)
    local current = getCurrentRace()
    if current == targetRace then return true end
    SetText(" Change " .. tostring(current) .. " → " .. targetRace)

if targetRace == "Ghoul" then
    local ecto = GetEctoCount()
    if ecto >= 100 then
        invoke("Ectoplasm", "BuyCheck", 4)
        task.wait(1)
        invoke("Ectoplasm", "Change", 4)
        task.wait(2)
        if getCurrentRace() == "Ghoul" then return true end
    end
    return true
end
    return false
end

getgenv().V2Farms = {

    ["Ghoul"] = function()
        if getCurrentRace() ~= "Ghoul" then
            local ecto = GetEctoCount()
            if ecto >= 100 then
                invoke("Ectoplasm", "BuyCheck", 4)
                task.wait(1)
                invoke("Ectoplasm", "Change", 4)
                task.wait(1)
            end

            if getCurrentRace() ~= "Ghoul" then
                SetText(" Get race Ghoul...")
                GetGhoulFirstTime()
                return
            end
        end

        local lv = RS.Remotes.CommF_:InvokeServer("getRaceLevel")

        if lv == 1 then
            SetText("Ghoul | V2")
            _G.FarmV2 = true
            GetV2()
        end
        
    end
}

PrintV2Status()

SetText(table.concat(getgenv().RaceList, ", "))
local world = worldMap[placeIdd]
    if world == "World1" or world == "World3" then
        replicated = game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelDressrosa")
    elseif world == "World2" then
        World2 = true
    end
task.wait(.5)

for index, targetRace in getgenv().RaceList do
    if getgenv().StopV2 then SetText(" Stop ") break end

    if HasRaceV2(targetRace) then
        SetText("Có Ghoul v2 rồi !!!")
    end


    local farmFunc = getgenv().V2Farms[targetRace]
    if farmFunc then
        local farmThread = task.spawn(function()
            while not getgenv().StopV2 do
                if HasRaceV2(targetRace) then break end
                local cur = getCurrentRace()
                if cur ~= targetRace and targetRace ~= "Ghoul" then
                    SetText(" Race đổi → " .. targetRace)
                    switchToRace(targetRace)
                end
                pcall(farmFunc)
                task.wait(1)
            end
        end)

    end
    task.wait(.5)
end
