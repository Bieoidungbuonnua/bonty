if not LPH_OBFUSCATED then
    LPH_ENCSTR = LPH_ENCSTR or function(...) return ... end
    LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(...) return ... end
end

-- ============================================================
--  KATA.LUA  |  Farm Cake Prince (Boss World 3)
-- ============================================================

local RS_ = game:GetService("ReplicatedStorage")
local CommF_ = RS_:WaitForChild("Remotes"):WaitForChild("CommF_")

while not game.Players.LocalPlayer.Character
   or not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
    pcall(function()
        CommF_:InvokeServer("SetTeam", "Marines")
    end)
    task.wait(1)
end

local RS  = game:GetService("ReplicatedStorage")
local TS  = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local LP  = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")

local placeIdd = game.PlaceId
local worldMap = {
    [2753915549]   = "World1",
    [85211729168715] = "World1",
    [4442272183]   = "World2",
    [79091703265657] = "World2",
    [7449423635]   = "World3",
    [100117331123089] = "World3",
}

-- Config tương thích (nếu không có Config thì dùng default)
local CG = getgenv().Config or { ["Black Screen"] = false, toolTip = "Melee" }
if not CG.toolTip then CG.toolTip = "Melee" end

Services = setmetatable({}, {__index = function(self, name)
    local s, c = pcall(function()
        return (cloneref or function(x) return x end)(game:GetService(name))
    end)
    if s then rawset(self, name, c) return c
    else error("Invalid Roblox Service: " .. tostring(name)) end
end})

local Root = LP.Character.HumanoidRootPart
_G.FarmV2 = false

LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    Root = char.HumanoidRootPart
end)

local Character, Humanoid, HumanoidRootPart
if LP then
    Character     = LP.Character
    Humanoid      = Character:FindFirstChildWhichIsA("Humanoid") or Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart")
end

-- ============================================================
--  BIẾN GLOBAL
-- ============================================================
getgenv().StopKata = false
isHopping = false

-- Auto rejoin khi bị lỗi / security kick
local function RejoinSelf()
    pcall(function()
        RS:WaitForChild("__ServerBrowser"):InvokeServer("teleport", game.JobId)
    end)
end

game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
    if isHopping then return end
    -- ErrorPrompt thông thường
    if child.Name == 'ErrorPrompt'
    and child:FindFirstChild('MessageArea')
    and child.MessageArea:FindFirstChild('ErrorFrame') then
        RejoinSelf()
        return
    end
    -- Security kick (Roblox hiện qua ErrorPrompt hoặc LeaveGamePrompt)
    if child.Name == 'LeaveGamePrompt' then
        task.wait(1)
        RejoinSelf()
        return
    end
end)

-- Detect bị kick bởi anti-cheat / security qua PlayerRemoving / Humanoid
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        task.wait(2)
        RejoinSelf()
    end
end)

-- Auto Buso
spawn(function()
    while task.wait(1) do
        pcall(function()
            if not LP.Character:FindFirstChild("HasBuso") then
                RS.Remotes.CommF_:InvokeServer("Buso")
            end
        end)
    end
end)

-- ============================================================
--  TWEEN / TP SYSTEM  (lấy từ bigupcy.lua)
-- ============================================================
local shouldTween = false
local block = Instance.new("Part", workspace)
block.Name  = "TweenBlock_Kata"
block.Size  = Vector3.new(1,1,1)
block.Anchored  = true
block.CanCollide = false
block.CanTouch  = false
block.Transparency = 1

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

local function _tp(target)
    if not target then return end
    target = typeof(target) ~= "CFrame" and CFrame.new(target) or target
    shouldTween = true
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local dist = (block.Position - LP.Character.HumanoidRootPart.Position).Magnitude
        if dist > 100 then block.CFrame = LP.Character.HumanoidRootPart.CFrame end
    end
    if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") and LP.Character.Humanoid.Sit then
        block.CFrame = CFrame.new(block.Position.X, target.Y, block.Position.Z)
    end
    local dist  = (block.Position - target.Position).Magnitude
    local speed = 350
    local time  = math.max(dist / speed, 0.1)
    local tween = TS:Create(block, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = target})
    tween:Play()
    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if not shouldTween then tween:Cancel() break end
            task.wait(0.1)
        end
    end)
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

function StopTween()
    shouldTween = false
    if block and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        block.CFrame = LP.Character.HumanoidRootPart.CFrame
    end
end

-- ============================================================
--  LABEL UI
-- ============================================================
local ScreenGuis = Instance.new("ScreenGui", LP.PlayerGui)
local label = Instance.new("TextLabel", ScreenGuis)
label.Name = "KataLabel"
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.new(0.5, 0, 0.5, 0)
label.Size = UDim2.new(0.6, 0, 0.15, 0)
label.Text = "Kata | Starting..."
label.TextScaled = true
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Center
label.TextYAlignment = Enum.TextYAlignment.Center
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamSemibold
label.TextSize = 48
label.TextColor3 = Color3.fromRGB(255, 255, 0)

local function SetText(newText)
    label.Text = newText
    print("[Kata] " .. tostring(newText))
end

-- ============================================================
--  UTIL FUNCTIONS
-- ============================================================
local function CheckTool(v)
    return (LP.Backpack:FindFirstChild(v) or (LP.Character and LP.Character:FindFirstChild(v))) and true or false
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

-- ============================================================
--  BRING MOB  (lấy từ KaitunGhoul.lua)
-- ============================================================
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
            local h   = v:FindFirstChildWhichIsA("Humanoid")
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
            if hrp and (not isnetworkowner or isnetworkowner(hrp)) then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = t * CFrame.new((i-1) * 2, 0, 0)
            end
        end
    end), (function(r) warn("[Kata] BringMonster Error: ".. r) end))
end)

-- ============================================================
--  FAST ATTACK  (lấy từ KaitunGhoul.lua – Layer 1)
-- ============================================================
_G.FastAttack = true

if _G.FastAttack then
    local _ENV = (getgenv or getrenv or getfenv)()

    local function SafeWaitForChild(parent, childName)
        local success, result = pcall(function()
            return parent:WaitForChild(childName, 10)
        end)
        if not success or not result then
            warn("[Kata] Không tìm thấy: " .. childName)
        end
        return result
    end

    local VirtualInputManager = game:GetService("VirtualInputManager")
    local ReplicatedStorage   = game:GetService("ReplicatedStorage")
    local Players             = game:GetService("Players")
    local Player              = Players.LocalPlayer

    if Player then
        local Remotes = SafeWaitForChild(ReplicatedStorage, "Remotes")
        if Remotes then
            local Enemies   = SafeWaitForChild(workspace, "Enemies")
            local Characters = SafeWaitForChild(workspace, "Characters")
            local Modules   = SafeWaitForChild(ReplicatedStorage, "Modules")
            local Net       = SafeWaitForChild(Modules, "Net")

            local Settings = { AutoClick = true, ClickDelay = 0 }
            local Module   = {}

            Module.FastAttack = (function()
                if _ENV.rz_FastAttack then return _ENV.rz_FastAttack end

                local FastAttack = {
                    Distance      = 100,
                    attackMobs    = true,
                    attackPlayers = true,
                    Equipped      = nil
                }

                local RegisterAttack = SafeWaitForChild(Net, "RE/RegisterAttack")
                local RegisterHit    = SafeWaitForChild(Net, "RE/RegisterHit")

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
                    if not BasePart or #OthersEnemies == 0 then return end
                    RegisterAttack:FireServer(Settings.ClickDelay or 0)
                    RegisterHit:FireServer(BasePart, OthersEnemies)
                end

                function FastAttack:AttackNearest()
                    local OthersEnemies = {}
                    local Part1 = ProcessEnemies(OthersEnemies, Enemies)
                    local Part2 = ProcessEnemies(OthersEnemies, Characters)
                    local character = Player.Character
                    if not character then return end
                    local equippedWeapon = character:FindFirstChildOfClass("Tool")
                    if equippedWeapon and equippedWeapon:FindFirstChild("LeftClickRemote") then
                        for _, enemyData in ipairs(OthersEnemies) do
                            local enemy = enemyData[1]
                            local direction = (enemy.HumanoidRootPart.Position - character:GetPivot().Position).Unit
                            pcall(function() equippedWeapon.LeftClickRemote:FireServer(direction, 1) end)
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
    end
end

-- Layer 2: remote + CombatUtil attack (giống bigupcy)
local remote, idremote
for _, v in next, ({RS.Util, RS.Common, RS.Remotes, RS.Assets, RS.FX}) do
    pcall(function()
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
    end)
end

task.spawn(function()
    while task.wait(0.05) do
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local parts = {}
        for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0
                   and (hrp.Position - root.Position).Magnitude <= 60 then
                    for _, _v in ipairs(v:GetChildren()) do
                        if _v:IsA("BasePart") and (hrp.Position - root.Position).Magnitude <= 60 then
                            parts[#parts + 1] = {v, _v}
                        end
                    end
                end
            end
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if #parts > 0 and tool
           and (tool:GetAttribute("WeaponType") == "Melee" or tool:GetAttribute("WeaponType") == "Sword") then
            pcall(function()
                require(RS.Modules.Net):RemoteEvent("RegisterHit", true)
                RS.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head = parts[1][1]:FindFirstChild("Head")
                if not head then return end
                RS.Modules.Net["RE/RegisterHit"]:FireServer(head, parts, {},
                    tostring(LP.UserId):sub(2,4) .. tostring(coroutine.running()):sub(11,15))
                if remote and idremote then
                    pcall(function()
                        cloneref(remote):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
                            return string.char(bit32.bxor(string.byte(c),
                                math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
                        end), bit32.bxor(idremote + 909090,
                            RS.Modules.Net.seed:InvokeServer() * 2), head, parts)
                    end)
                end
            end)
        end
    end
end)

-- Layer 3: CombatUtil
local M  = RS:WaitForChild("Modules")
local CU, WD = nil, nil
task.spawn(function()
    local ok1, r1 = pcall(function() return require(M:WaitForChild("CombatUtil", 10)) end)
    if ok1 then CU = r1 else warn("[Kata] Không load được CombatUtil") end
    local ok2, r2 = pcall(function() return require(M:WaitForChild("WeaponData", 10)) end)
    if ok2 then WD = r2 else warn("[Kata] Không load được WeaponData") end
end)

local N  = M:FindFirstChild("Net")
local RA = N and (N:FindFirstChild("RE/RegisterAttack") or N:FindFirstChild("RegisterAttack"))
local RH = N and (N:FindFirstChild("RE/RegisterHit")    or N:FindFirstChild("RegisterHit"))
local IS
do
    local PS = LP:WaitForChild("PlayerScripts")
    for _, s in next, PS:GetChildren() do
        if s:IsA("LocalScript") then
            local ok, env = pcall(getsenv, s)
            if ok and env and env._G and typeof(env._G.SendHitsToServer) == "function" then
                IS = env._G.SendHitsToServer
                break
            end
        end
    end
    if not IS and _G.SendHitsToServer then IS = _G.SendHitsToServer end
end

pcall(function()
    hookfunction(CU.GetComboPaddingTime,     function() return 0    end)
    hookfunction(CU.GetAttackCancelMultiplier, function() return 0  end)
    hookfunction(CU.CanAttack,               function() return true end)
end)

local HList = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm",
               "RightHand","LeftHand","HumanoidRootPart","Head","UpperTorso","LowerTorso"}

okm = function(m)
    local h = m:FindFirstChildWhichIsA("Humanoid")
    return h and h.Health > 0 and m:FindFirstChild("HumanoidRootPart") and not m:FindFirstChild("VehicleSeat")
end
hpt = function(m)
    for _ = 1, 2 do
        local p = m:FindFirstChild(HList[math.random(1, #HList)])
        if p then return p end
    end
    return m:FindFirstChild("HumanoidRootPart")
end
near = function(r, maxN)
    local out, ch = {}, LP.Character
    if not ch then return out end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return out end
    local p0 = hrp.Position
    for _, grp in next, {workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("Characters")} do
        if grp then
            for _, v in next, grp:GetChildren() do
                if #out >= maxN then break end
                if v ~= ch and okm(v) then
                    local hr = v:FindFirstChild("HumanoidRootPart")
                    if hr and (hr.Position - p0).Magnitude <= r then
                        out[#out+1] = v
                    end
                end
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
                if not main then main = p end
                hits[#hits+1] = {v, p}
            end
        end
    end
    return main, hits
end
send = function(main, hits)
    if main and #hits > 0 then
        if IS then IS(main, hits)
        elseif RH then RH:FireServer(main, hits) end
    end
end
local AC, HM = {}, nil
setH = function(c)
    local h = c:FindFirstChildWhichIsA("Humanoid")
    if h then HM = h; AC = {} end
end
if LP.Character then setH(LP.Character) end
LP.CharacterAdded:Connect(function(c) c:WaitForChild("Humanoid"); setH(c) end)
anim = function(tool)
    if not (HM and tool and WD) then return end
    local wn = CU:GetWeaponName(tool)
    local data = WD[wn] or WD[string.lower(wn)] or WD[CU:GetPureWeaponName(wn)]
    if not (data and data.Moveset and data.Moveset.Basic) then return end
    local mv = data.Moveset.Basic
    local a  = mv[math.random(1, #mv)]
    if not (a and a.AnimationId) then return end
    if not AC[a.AnimationId] then
        local n = Instance.new("Animation")
        n.AnimationId = a.AnimationId
        AC[a.AnimationId] = HM:LoadAnimation(n)
    end
    local tr = AC[a.AnimationId]
    if tr then tr:Play(1, 1, 0.2) end
end
spawn(function()
    while task.wait(0.019) do
        local ok, err = pcall(function()
            local ch = LP.Character
            if not ch then return end
            local tool = ch:FindFirstChildOfClass("Tool")
            if not tool then return end
            local tg = near(60, 20)
            if #tg == 0 then return end
            local main, hits = pkg(tg)
            if not main then return end
            if RA then RA:FireServer(0) end
            if _G.Animation then anim(tool) end
            task.defer(function()
                pcall(function()
                    CU:AttackStart(main, 1)
                    CU:RunHitDetection(main.Parent or main, 1, {_Object = {Length = 0.02, IsPlaying = true}})
                end)
            end)
            send(main, hits)
        end)
    end
end)

-- Layer 3b: loadstring FastAttack (giống KaitunGhoul)
local FastAttackLS = loadstring([[
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
    local Net2 = (Services.ReplicatedStorage.Modules.Net)
    local RegisterAttack = require(Net2):RemoteEvent('RegisterAttack', true)
    local RegisterHit = require(Net2):RemoteEvent('RegisterHit', true)
    function Funcs:Attack()
        local bladehits = {}
        for r,v in pairs(GetAllBladeHits()) do table.insert(bladehits, v) end
        for r,v in pairs(Getplayerhit()) do table.insert(bladehits, v) end
        if #bladehits == 0 then return end
        local args = {[1]=nil,[2]={},[3]=nil,[4]="078da341"}
        for r, v in pairs(bladehits) do
            RegisterAttack:FireServer(0)
            if not args[1] then args[1] = v.Head end
            table.insert(args[2], {[1]=v,[2]=v.HumanoidRootPart})
            table.insert(args[2], v)
        end
        RegisterHit:FireServer(unpack(args))
    end
    task.spawn(function()
        while task.wait(.05) do
            if _G.FastAttack == os.time() then
                pcall(function() Funcs:Attack() end)
            end
        end
    end)
    getgenv().Attack = function(MonResult)
        pcall(function() _G.FastAttack = os.time() end)
    end
]])
if FastAttackLS then FastAttackLS() end

-- ============================================================
--  KILL MONSTER  (logic từ bigupcy.lua – có BringMob)
-- ============================================================
local lastKenCall = tick()
KillMonster = function(x)
    xpcall(function()
        if workspace.Enemies:FindFirstChild(x) then
            for _, v in next, workspace.Enemies:GetChildren() do
                local vh   = v:FindFirstChildWhichIsA("Humanoid")
                local vhrp = v:FindFirstChild("HumanoidRootPart")
                if vh and vh.Health > 0 and vhrp and v.Name == x then
                    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if not myHrp then return end

                    local toolTipConfig = CG["toolTip"] or "Melee"
                    EquipByTip(toolTipConfig)

                    local dx = myHrp.Position.X - vhrp.Position.X
                    local dy = myHrp.Position.Y - vhrp.Position.Y
                    local dz = myHrp.Position.Z - vhrp.Position.Z

                    if dx*dx + dy*dy + dz*dz <= 4900 then
                        if tick() - lastKenCall >= 10 then
                            lastKenCall = tick()
                            RS.Remotes.CommE:FireServer("Ken", true)
                        end
                    end

                    if toolTipConfig == "Blox Fruit" then
                        local currentHealth = vh.Health
                        local prevHealth = vh:GetAttribute("PrevHealth") or currentHealth
                        if currentHealth < prevHealth then
                            StopTween()
                            myHrp.CFrame = CFrame.new(vhrp.Position.X, vhrp.Position.Y + 10000000, vhrp.Position.Z)
                        else
                            StopTween()
                            myHrp.CFrame = vhrp.CFrame
                        end
                        vh:SetAttribute("PrevHealth", currentHealth)
                        BringMob()
                        return
                    else
                        shouldTween = false
                        local bossPos = vhrp.Position
                        myHrp.CFrame = CFrame.new(myHrp.Position.X, 10000000, myHrp.Position.Z)
                        myHrp.CFrame = CFrame.new(bossPos.X, 10000000, bossPos.Z)
                        myHrp.CFrame = CFrame.new(bossPos.X, bossPos.Y + 3, bossPos.Z)
                        BringMob()
                        return
                    end
                end
            end
        end
        for _, v in next, RS:GetChildren() do
            local vhrp = v:FindFirstChild("HumanoidRootPart")
            if v:IsA("Model") and vhrp and v.Name == x then
                local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    shouldTween = false
                    myHrp.CFrame = CFrame.new(myHrp.Position.X, 10000000, myHrp.Position.Z)
                    myHrp.CFrame = CFrame.new(vhrp.Position.X, 10000000, vhrp.Position.Z)
                    myHrp.CFrame = CFrame.new(vhrp.Position.X, vhrp.Position.Y + 3, vhrp.Position.Z)
                end
                return
            end
        end
    end, function(e) warn("[Kata] KillMonster ERROR:", e) end)
end

-- ============================================================
--  HOP API  –  name_kata.json  (lưu jobid đã hop)
-- ============================================================
local KATA_FILE     = LP.Name .. "_kata.json"
local HoppedJobIds  = {}
local HopCount      = 0
getgenv().FailedJobIds   = getgenv().FailedJobIds or {}
getgenv().LastApiRefresh = getgenv().LastApiRefresh or 0

local function LoadHoppedJobIds()
    pcall(function()
        local ok, data = pcall(readfile, KATA_FILE)
        if ok and data and data ~= "" then
            local decoded = HttpService:JSONDecode(data)
            if type(decoded) == "table" then
                for _, jobId in ipairs(decoded) do
                    HoppedJobIds[jobId] = true
                end
            end
        end
    end)
end

local function SaveHoppedJobIds()
    pcall(function()
        local list = {}
        for jobId, _ in pairs(HoppedJobIds) do
            table.insert(list, jobId)
        end
        writefile(KATA_FILE, HttpService:JSONEncode(list))
    end)
end

LoadHoppedJobIds()

-- ============================================================
--  DEBUG: In tọa độ đảo CakeLoaf vào console
-- ============================================================
local function DebugCakeLoafPosition()
    -- Tìm đảo trong workspace theo tên
    local candidates = {"CakeLoaf", "Cake_Loaf", "Cake Loaf", "CakeIsland", "Mirror World"}
    for _, name in ipairs(candidates) do
        -- Tìm trong Map
        local mapFolder = workspace:FindFirstChild("Map")
        if mapFolder then
            local island = mapFolder:FindFirstChild(name, true)
            if island then
                local pos = island:IsA("BasePart") and island.Position
                    or (island:FindFirstChildWhichIsA("BasePart") and island:FindFirstChildWhichIsA("BasePart").Position)
                if pos then
                    print("[Kata] DEBUG CakeLoaf island '" .. name .. "' Position:", pos)
                end
            end
        end
        -- Tìm trong Locations
        local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
        if worldOrigin then
            local locs = worldOrigin:FindFirstChild("Locations")
            if locs then
                local loc = locs:FindFirstChild(name, true)
                if loc then
                    print("[Kata] DEBUG Location '" .. name .. "':", loc:GetFullName(), loc.Value or loc.Position or loc)
                end
            end
        end
    end
    -- In tọa độ cổng Mirror World đã biết
    print("[Kata] DEBUG Cổng Mirror World (hard-coded): -2152.15, 120, -12398.39")
    -- In tọa độ hiện tại của player để so sánh
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        print("[Kata] DEBUG Player Position:", LP.Character.HumanoidRootPart.Position)
    end
end

-- ============================================================
--  BYPASS TP ĐẾN CỔNG MIRROR WORLD
-- ============================================================
-- Tọa độ cổng vào Mirror World (Cake Prince)
local GATE_POSITION = Vector3.new(-2152.15, 120, -12398.39)

local function BypassTpToCakeLoaf()
    SetText("Kata | Bypass TP → Cổng Mirror World...")
    DebugCakeLoafPosition()

    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    -- Tắt collision toàn thân để bypass tường
    for _, part in LP.Character:GetDescendants() do
        if part:IsA("BasePart") then part.CanCollide = false end
    end

    -- Thử requestEntrance để server mở cổng
    pcall(function()
        RS.Remotes.CommF_:InvokeServer("requestEntrance", GATE_POSITION)
    end)
    task.wait(0.5)

    -- TP thẳng HRP vào tọa độ cổng (không dùng tween block tránh bị server đẩy ra)
    -- Dùng vòng loop giữ tại cổng cho đến khi vào được Mirror World
    local timeout = 15
    local elapsed = 0
    while elapsed < timeout do
        task.wait(0.5)
        elapsed = elapsed + 0.5

        -- Kiểm tra đã vào Mirror World chưa
        local loc = LP:GetAttribute("CurrentLocation") or LP:GetAttribute("ExactLocation") or ""
        if loc:lower():find("mirror") or loc:lower():find("cake") then
            SetText("Kata | Đã vào Mirror World!")
            break
        end

        -- Giữ player tại tọa độ cổng mỗi tick (override server push-back)
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(GATE_POSITION)
        end

        -- Tiếp tục gọi requestEntrance mỗi 2s
        if elapsed % 2 < 0.6 then
            pcall(function()
                RS.Remotes.CommF_:InvokeServer("requestEntrance", GATE_POSITION)
            end)
        end
    end

    task.wait(0.5)
end

-- ============================================================
--  KIỂM TRA BOSS CAKE PRINCE
-- ============================================================
local function HasCakePrince()
    -- Tìm trong workspace.Enemies
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == "Cake Prince" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            return true
        end
    end
    -- Tìm trong RS (boss chưa spawn vào Enemies)
    for _, v in pairs(RS:GetChildren()) do
        if v.Name == "Cake Prince" and v:IsA("Model")
           and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            return true
        end
    end
    return false
end

-- ============================================================
--  HOP API ĐẾN SERVER CÓ CAKE PRINCE
-- ============================================================
local CAKE_PRINCE_API = "http://mbasic7.pikamc.vn:25082/api/name=cakeprince?apikey=CONCACDUMAMAY"

local function HopApiCakePrince(maxPlayers, waitTime)
    isHopping = true
    maxPlayers = maxPlayers or 12
    waitTime   = waitTime   or 25

    if tick() - getgenv().LastApiRefresh > 600 then
        getgenv().FailedJobIds  = {}
        getgenv().LastApiRefresh = tick()
    end

    local CURRENT_PLACE_ID = game.PlaceId

    local ok, result = pcall(function()
        local responseBody
        pcall(function() responseBody = game:HttpGet(CAKE_PRINCE_API) end)
        if not responseBody then
            local reqFunc = (syn and syn.request) or request or http.request
            local req = reqFunc({ Url = CAKE_PRINCE_API, Method = "GET" })
            responseBody = req.Body
        end

        local data = HttpService:JSONDecode(responseBody)
        if not data or not data.success or type(data.data) ~= "table" or type(data.data.data) ~= "table" then
            SetText("Kata | API sai dữ liệu, đợi...")
            return false
        end

        -- Lọc server đúng placeId
        local seen, servers = {}, {}
        for _, entry in ipairs(data.data.data) do
            local jobId  = entry.jobid
            local placeId = entry.placeid
            local players = tonumber(entry.player) or 99
            if jobId and placeId then
                if not seen[jobId] then
                    seen[jobId] = true
                    table.insert(servers, {jobid = jobId, placeid = placeId, players = players})
                end
            end
        end

        local filtered = {}
        for _, s in ipairs(servers) do
            if tostring(s.placeid) == tostring(CURRENT_PLACE_ID) then
                table.insert(filtered, s)
            end
        end
        table.sort(filtered, function(a, b) return a.players < b.players end)
        SetText("Kata | API: " .. #filtered .. " server có Cake Prince")

        local triedCount = 0
        for _, server in ipairs(filtered) do
            local jobId  = server.jobid
            local players = server.players

            if jobId == game.JobId then continue end
            if getgenv().FailedJobIds[jobId] then continue end
            if HoppedJobIds[jobId] then continue end
            if players >= maxPlayers then continue end

            triedCount = triedCount + 1
            -- Retry cùng 1 jobId tối đa 5 lần, mỗi lần cách 1s
            local retrySuccess = false
            for retry = 1, 5 do
                if getgenv().StopKata then return false end
                SetText("Kata | Hop [" .. retry .. "/5] → " .. players .. " người | " .. jobId:sub(1,8) .. "...")
                local teleportOk = pcall(function()
                    RS:WaitForChild("__ServerBrowser"):InvokeServer("teleport", jobId)
                end)
                if teleportOk then
                    HopCount = HopCount + 1
                    HoppedJobIds[jobId] = true
                    -- Sau 10 lần hop → reset file
                    if HopCount >= 10 then
                        HopCount = 0
                        HoppedJobIds = {}
                        writefile(KATA_FILE, "[]")
                        SetText("Kata | Reset " .. KATA_FILE)
                    else
                        SaveHoppedJobIds()
                    end
                    task.wait(15)
                    retrySuccess = true
                    return true
                end
                -- Chưa vào được → thử lại sau 1s
                task.wait(1)
            end
            -- Sau 5 lần vẫn fail → đánh dấu jobId này và đổi sang jobId khác
            if not retrySuccess then
                getgenv().FailedJobIds[jobId] = tick()
                SetText("Kata | Fail 5 lần server #" .. triedCount .. " → Đổi jobId...")
            end
        end

        SetText("Kata | Hết server | Đợi API " .. waitTime .. "s...")
        for i = waitTime, 1, -1 do
            if getgenv().StopKata then return false end
            SetText("Kata | Đợi API: " .. i .. "s")
            task.wait(1)
        end
        return false
    end)

    isHopping = false
    return ok and result
end

-- ============================================================
--  KILL CAKE PRINCE  (logic target từ bigupcy + tên boss thay)
-- ============================================================
local function FindAndKillCakePrince()
    local boss = GetConnectionEnemies("Cake Prince")
    if not boss then return false end

    SetText("Kata | Tìm thấy Cake Prince! Attack...")
    local hrp = boss:FindFirstChild("HumanoidRootPart")

    repeat
        task.wait(0.3)
        if getgenv().StopKata then break end
        if not boss or not boss.Parent then break end
        hrp = boss:FindFirstChild("HumanoidRootPart")
        if not hrp then break end

        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then task.wait(1); continue end

        local dist = (myHrp.Position - hrp.Position).Magnitude
        if dist > 80 then
            TweenTo(hrp.CFrame * CFrame.new(0, 15, 0))
            task.wait(0.5)
        end

        local hp = math.floor(boss.Humanoid.Health / boss.Humanoid.MaxHealth * 100)
        SetText("Kata | Cake Prince HP: " .. hp .. "% | Đang kill...")
        EquipByTip("Melee")
        BringMob()
        KillMonster("Cake Prince")
        pcall(function() getgenv().Attack() end)

    until not boss or not boss.Parent or boss.Humanoid.Health <= 0 or getgenv().StopKata

    if boss and boss.Parent and boss.Humanoid.Health <= 0 then
        SetText("Kata | Cake Prince đã chết!")
        task.wait(3)
        return true
    end
    return false
end

-- ============================================================
--  ANTI STUCK
-- ============================================================
task.spawn(function()
    local lastPos   = Vector3.zero
    local stuckTime = 0
    while task.wait(1) do
        if not getgenv().StopKata and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local currentPos = LP.Character.HumanoidRootPart.Position
            if (currentPos - lastPos).Magnitude < 2 then
                stuckTime = stuckTime + 1
                if stuckTime >= 120 then
                    SetText("Kata | Stuck 120s → HopAPI!")
                    HopApiCakePrince(12, 10)
                    stuckTime = 0
                end
            else
                stuckTime = 0
                lastPos   = currentPos
            end
        end
    end
end)

-- ============================================================
--  MAIN LOOP
-- ============================================================
SetText("Kata | Khởi động Farm Cake Prince...")
task.wait(2)

while not getgenv().StopKata do
    task.wait(1)

    -- Bước 1: Check có boss Cake Prince không
    if HasCakePrince() then
        SetText("Kata | Có Cake Prince! Đang TP đến cổng...")

        -- Bước 2: Bypass TP đến cổng Mirror World
        BypassTpToCakeLoaf()
        task.wait(2)

        -- Bước 3: Kill boss
        local killed = FindAndKillCakePrince()

        if killed then
            SetText("Kata | Boss xong! HopAPI tìm boss mới...")
            task.wait(3)
            -- Hop ngay sau khi kill để farm liên tục
            HopApiCakePrince(12, 25)
        else
            -- Boss mất/không kill được → hop
            SetText("Kata | Không kill được boss → HopAPI...")
            task.wait(2)
            HopApiCakePrince(12, 15)
        end

    else
        -- Bước 4: Không có boss → HopAPI
        SetText("Kata | Không có Cake Prince → HopAPI...")
        HopApiCakePrince(12, 25)
    end
end

SetText("Kata | Đã dừng.")
