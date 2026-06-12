if not LPH_OBFUSCATED then
    LPH_ENCSTR = LPH_ENCSTR or function(...) return ... end
    LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(...) return ... end
end

-- ================================================
-- FARMSYNC CONFIG (đặt lên đầu file)
-- ================================================
local FARMSYN_FOLDERS = {
    idle = "b8ff2a869e7688680d78b4a52245ef4af881b1e5f6c2501aa10f09d4eaaa96e5",
    done = "6902232f9e8eb629a987b2d5c8e863a120214f0eddfa18ba41ce814ae6f0ee57",
    key  = "08f6c4d56ae89e235b379cb959246b5f24dec430bcc1a6bd1ba24d86593d8a6d"
}

-- Hàm đổi acc qua FARMSYNC khi không đủ frags
local function FarmSyncChangeAcc(reason)
    warn("[FARMSYNC] " .. (reason or "Không đủ fragment") .. " → Đang đổi acc...")
    local success = pcall(function()
        getgenv().client:ChangeToFolder( 
            FARMSYN_FOLDERS.idle,
            FARMSYN_FOLDERS.done,
            true,
            FARMSYN_FOLDERS.key
        )
    end)
    if success then
        warn("[FARMSYNC] ChangeToFolder thành công, đang disconnect...")
        pcall(function()
            getgenv().client:Disconnect()
        end)
        task.wait(5)
        game:Shutdown()
    else
        warn("[FARMSYNC] ChangeToFolder thất bại, thử lại sau 10 giây...")
        task.wait(10)
    end
end

-- ================================================
-- WAIT FOR GAME LOAD
-- ================================================
repeat task.wait(0.5)
until game:IsLoaded()
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui")

local _COREGUI = game:GetService("CoreGui")
if workspace.DistributedGameTime <= 10 then
    local wfgtl = _COREGUI:FindFirstChild("WFGTL") or Instance.new("Hint", _COREGUI)
    wfgtl.Name = "WFGTL"
    wfgtl.Text = "Just a moment... Waiting while the game loads - This won't take long!"
    task.wait(math.max(0, 10 - workspace.DistributedGameTime))
    pcall(function() wfgtl:Destroy() end)
end

do
    local _rs = game:GetService("ReplicatedStorage")
    local _rem = _rs:WaitForChild("Remotes", 30)
    if _rem then _rem:WaitForChild("CommF_", 30) end
end
-- ================================================

local RS_ = game:GetService("ReplicatedStorage")
local CommF_ = RS_:WaitForChild("Remotes"):WaitForChild("CommF_")

while not game.Players.LocalPlayer.Character
   or not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
    pcall(function()
        CommF_:InvokeServer("SetTeam", "Marines")
    end)
    task.wait(1)
end
local placeIdd = game.PlaceId
local worldMap = {[2753915549]="World1",[85211729168715]="World1",[4442272183]="World2",[79091703265657]="World2",[7449423635]="World3",[100117331123089]="World3"}

local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local VIM = game:GetService("VirtualInputManager")
local LP = game:GetService("Players").LocalPlayer

local MAX_CHESTS_PER_SERVER = 55

Services = setmetatable({}, {__index = function(self, name)
    local s, c = pcall(function()
        return (cloneref or function(x) return x end)(game:GetService(name))
    end)
    if s then rawset(self, name, c) return c
    else error("Invalid Roblox Service: " .. tostring(name)) end
end})

local Root = LP.Character.HumanoidRootPart
local cyborgFile = LP.Name .. "_cyborg.txt"
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

getgenv().StopV3 = false

repeat task.wait(2)
until LP.Character
    and LP.Character:FindFirstChild("HumanoidRootPart")
    and LP.Character:FindFirstChildWhichIsA("Humanoid")
    and workspace:FindFirstChild("Characters")
    and LP.Character:IsDescendantOf(workspace.Characters)

pcall(function() LP.PlayerGui:FindFirstChild("Blank"):Destroy() end)
local ScreenGuis = Instance.new("ScreenGui", LP.PlayerGui)

local function SetText(newText)
    print(newText)
end

local shouldTween = false
local block = Instance.new("Part", workspace)
block.Name = "TweenBlock"
block.Size = Vector3.new(1, 1, 1)
block.Anchored = true
block.CanCollide = false
block.CanTouch = false
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

pcall(function()
    local ok, src = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/Bieoidungbuonnua/bonty/refs/heads/main/m1-attack.txt")
    if ok and src then pcall(loadstring(src)) end
end)

ReplicatedStorage = RS
FastAttack = loadstring([[
    local Modules = game.ReplicatedStorage.Modules
    local Net = Modules.Net
    local Register_Hit = Net:WaitForChild("RE/RegisterHit")
    local Register_Attack = Net:WaitForChild("RE/RegisterAttack")
    local Funcs = {}
    function GetAllBladeHits()
        local bladehits = {}
        for _, v in pairs(workspace.Enemies:GetChildren()) do
            if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0
            and (v.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 65 then
                table.insert(bladehits, v)
            end
        end
        return bladehits
    end
    function Getplayerhit()
        local bladehits = {}
        for _, v in pairs(workspace.Characters:GetChildren()) do
            if v.Name ~= game.Players.LocalPlayer.Name and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0
            and (v.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 65 then
                table.insert(bladehits, v)
            end
        end
        return bladehits
    end
    function Funcs:Attack()
        local bladehits = {}
        for _, v in pairs(GetAllBladeHits()) do table.insert(bladehits, v) end
        for _, v in pairs(Getplayerhit()) do table.insert(bladehits, v) end
        if #bladehits == 0 then return end
        local args = {[1]=nil, [2]={}, [4]="078da341"}
        for _, v in pairs(bladehits) do
            Register_Attack:FireServer(0)
            if not args[1] then args[1] = v.Head end
            table.insert(args[2], {[1]=v, [2]=v.HumanoidRootPart})
            table.insert(args[2], v)
        end
        Register_Hit:FireServer(unpack(args))
    end
    -- Luôn attack liên tục, không cần gate os.time()
    task.spawn(function()
        while task.wait(0.05) do
            pcall(function() Funcs:Attack() end)
        end
    end)
    getgenv().Attack = function()
        pcall(function() Funcs:Attack() end)
    end
]])
if FastAttack then pcall(FastAttack) end

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

function _tp(target)
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
    local dist = (block.Position - target.Position).Magnitude
    local speed = 350
    local time = math.max(dist / speed, 0.1)
    local tween = TS:Create(block, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = target})
    tween:Play()
    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if not shouldTween then tween:Cancel() break end
            task.wait(0.1)
        end
    end)
end

function StopTween()
    shouldTween = false
    if block and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        block.CFrame = LP.Character.HumanoidRootPart.CFrame
    end
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
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = t * CFrame.new((i-1) * 2, 0, 0)
            end
        end
    end), (function(r) warn("Modules Error [BM]: ".. r) end))
end)

--------------------------------------------------
--------------------------------------------------
local lastKenCall = tick()
KillMonster = (function(x)
    xpcall(function()
        if workspace.Enemies:FindFirstChild(x) then
            for _, v in next, workspace.Enemies:GetChildren() do
                local vh = v:FindFirstChildWhichIsA("Humanoid")
                local vhrp = v:FindFirstChild("HumanoidRootPart")
                if vh and vh.Health > 0 and vhrp and v.Name == x then
                    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if not myHrp then return end
                    local dist = (myHrp.Position - vhrp.Position).Magnitude
                    if dist > 25 then
                        TweenTo(CFrame.new(vhrp.Position + (vhrp.CFrame.LookVector * 20) + Vector3.new(0, vhrp.Position.Y > 60 and -20 or 20, 0)))
                        task.wait(0.3)
                    end
                    if tick() - lastKenCall >= 10 then
                        lastKenCall = tick()
                        pcall(function() RS.Remotes.CommE:FireServer("Ken", true) end)
                    end
                    if getgenv().Attack then
                        getgenv().Attack()
                    end
                    return
                end
            end
        end
        for _, v in next, RS:GetChildren() do
            local vhrp = v:FindFirstChild("HumanoidRootPart")
            if v:IsA("Model") and vhrp and v.Name == x then
                TweenTo(vhrp.CFrame)
                return
            end
        end
    end, function(e) warn("Modules ERROR:", e) end)
end)
--------------------------------------------------
--------------------------------------------------

local function HopServer(player)
    SetText("Hop server...")
    pcall(function()
        local servers = game:GetService("HttpService"):JSONDecode(
            game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        ).data
        for _, server in pairs(servers) do
            if server.playing < (player or 4) and server.id ~= game.JobId then
                RS:WaitForChild("__ServerBrowser"):InvokeServer("teleport", server.id)
                task.wait(4)
                break
            end
        end
    end)
end

--------------------------------------------------
task.spawn(function()
    local lastPos = Vector3.zero
    local stuckTime = 0
    while task.wait(1) do
        if not getgenv().StopV3 and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local currentPos = LP.Character.HumanoidRootPart.Position
            if (currentPos - lastPos).Magnitude < 2 then
                stuckTime = stuckTime + 1
                if stuckTime >= 120 then
                    SetText("Stuck for 120s -> Hop Server!")
                    HopServer(5)
                    stuckTime = 0
                end
            else
                stuckTime = 0
                lastPos = currentPos
            end
        end
    end
end)
--------------------------------------------------

local function HasUnlockedCyborg()
    return RS.Remotes.CommF_:InvokeServer("CyborgTrainer", "Check") == true
end

local _chestAll = 0
local function MAX_CHESTS_FarmChestFast()
    local chests, c = {}, 0
    if _chestAll < MAX_CHESTS_PER_SERVER and not CheckTool("Fist of Darkness") then
        for _, v in next, CollectionService:GetTagged("_ChestTagged") do
            if v and v.CanTouch then
                local dist = (v.Position - LP.Character.HumanoidRootPart.Position).Magnitude
                table.insert(chests, {obj = v, dist = dist})
            end
        end
        table.sort(chests, function(a, b) return a.dist < b.dist end)

        if not CheckTool("Fist of Darkness") then
            for i, t in next, chests do
                local v = t.obj
                if v:IsA("BasePart") and v.Name:find("Chest") then
                    if v.CanTouch then
                        repeat
                            task.wait()
                            SetText("Collect Chests | " .. c .. "/" .. _chestAll .. "/" .. MAX_CHESTS_PER_SERVER .. " Chests")
                            task.delay(0.5, function() if v and v.Parent then v.CanTouch = false end end)
                            if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") and LP.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                                LP.Character:SetPrimaryPartCFrame(v.CFrame)
                            end
                            VIM:SendKeyEvent(true, "Space", false, game)
                            VIM:SendKeyEvent(false, "Space", false, game)
                        until not v.CanTouch or CheckTool("Fist of Darkness") or getgenv().StopV3
                        c += 1
                        _chestAll += 1
                        if _chestAll >= MAX_CHESTS_PER_SERVER then
                            SetText("Done " .. MAX_CHESTS_PER_SERVER .. " → Hop")
                            HopServer(5)
                            return
                        end
                        if CheckTool("Fist of Darkness") then
                            SetText("Stopped: Fist of Darkness detected")
                            return "FOD"
                        end
                        if getgenv().StopV3 then return end
                        if LP.Character and c >= 10 and not CheckTool("Fist of Darkness") then
                            if LP.Character:FindFirstChildOfClass("Humanoid") then
                                LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
                                SetText("Collect Chests | Reset: " .. c .. " Chests")
                            end
                            c = 0
                            task.wait(1)
                            repeat task.wait(0.5)
                            until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                and LP.Character:FindFirstChildOfClass("Humanoid")
                                and LP.Character:FindFirstChildOfClass("Humanoid").Health > 0
                        end
                    end
                    if i % 250 == 0 then task.wait(0.1) end
                end
            end
        else
            StopTween()
            SetText("Stopped: Found Special Item")
        end
        if not CheckTool("Fist of Darkness") then
            SetText("Chest | Hết → Hop")
            HopServer(5)
        end
    end
end

local function BuyRandomFruit()
    SetText("Cyborg V3 | Random fruit...")
    TweenTo(CFrame.new(-422.202271, 72.4190063, 386.306335))
    task.wait(2)
    local ok, result = pcall(function()
        return RS.Remotes.CommF_:InvokeServer("Cousin", "Buy")
    end)
    if ok and result == 1 then
        SetText("Cyborg V3 | Đã mua trái Random!")
        task.wait(2)
        return true
    else
        SetText("Cyborg V3 | Không đủ tiền mua trái!")
        task.wait(3)
        return false
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
                    repeat
                        task.wait()
                        KillMonster("Swan Pirate")
                    until GetBP("Flower 3") or not v.Parent or v.Humanoid.Health <= 0
                else
                    SetText("V2 | Swan Pirate chưa spawn → Đến vị trí")
                    TweenTo(CFrame.new(980.099, 121.331, 1287.209))
                    task.wait(3)
                end
            end
        elseif state == 2 then
            SetText("V2 | Nộp quest")
            RS.Remotes.CommF_:InvokeServer("Alchemist", "3")
            task.wait(1)
        elseif state == -2 then
            SetText("V2 Done!")
            _G.FarmV2 = false
            break
        end
    end
end

local function GetCyborgFirstTime()
    SetText("Get Cyborg")
    if not isfile(cyborgFile) then writefile(cyborgFile, "NaN") end

    pcall(function()
        local hookedNotif
        hookedNotif = hookfunction(require(RS.Notification).new, newcclosure(function(...)
            local args = ({...})[1]
            if typeof(args) == "string" then
                if args:lower():find("supply a <core brain>") or args:find("<Fist of Darkness> has been") then
                    writefile(cyborgFile, "unlock")
                elseif args:find("Microchip not found") then
                    writefile(cyborgFile, "chest")
                end
            end
            return hookedNotif(...)
        end))
    end)

    while not getgenv().StopV3 do
        task.wait(1)
        if getCurrentRace() == "Cyborg" then SetText("Have Cyborg!") break end

        -- Đọc frags an toàn với pcall (tránh đọc stale khi data chưa sync)
        local frags = 0
        pcall(function() frags = LP.Data.Fragments.Value end)

        if frags >= 2500 then
            RS.Remotes.CommF_:InvokeServer("CyborgTrainer", "Buy")
            task.wait(2)
            if getCurrentRace() == "Cyborg" then break end
        end

        local state = "NaN"
        pcall(function() state = readfile(cyborgFile) end)

        if state == "NaN" then
            if not CheckSea(2) then
                SetText("Get Cyborg | Go sea 2")
                RS.Remotes.CommF_:InvokeServer("TravelDressrosa"); task.wait(10)
            else
                SetText("Get Cyborg | Summon Raid")
                pcall(function() fireclickdetector(workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector) end)
                RS.Remotes.CommF_:InvokeServer("CyborgTrainer", "Buy"); task.wait(3)
            end

        elseif state == "chest" then
            if not CheckSea(2) then
                SetText("GET CYBORG | go Sea 2")
                RS.Remotes.CommF_:InvokeServer("TravelDressrosa"); task.wait(10)
            else
                if CheckTool("Fist of Darkness") then
                    SetText("GET CYBORG | FOD → Summon")
                    local fod = LP.Backpack:FindFirstChild("Fist of Darkness")
                    if fod then LP.Character:FindFirstChildOfClass("Humanoid"):EquipTool(fod); task.wait(0.5) end
                    pcall(function() fireclickdetector(workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector) end)
                    task.wait(3)
                else
                    SetText("GET CYBORG | Farm chest")
                    local result = MAX_CHESTS_FarmChestFast()
                    if result == "FOD" then
                        local fod = LP.Backpack:FindFirstChild("Fist of Darkness")
                        if fod then LP.Character:FindFirstChildOfClass("Humanoid"):EquipTool(fod); task.wait(0.5) end
                        pcall(function() fireclickdetector(workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector) end)
                        task.wait(3)
                    end
                end
            end

        elseif state == "unlock" then
            if CheckTool("Microchip") or CheckTool("Core Brain") then
                if not CheckSea(2) then
                    SetText("GET CYBORG | go Sea 2")
                    RS.Remotes.CommF_:InvokeServer("TravelDressrosa"); task.wait(10)
                else
                    local orderFound = false
                    local orderTarget = nil
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Order" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
                            orderTarget = v
                            break
                        end
                    end
                    if orderTarget then
                        orderFound = true
                        SetText("GET CYBORG | Attack Order")
                        EquipByTip("Melee")
                        -- Loop nhanh theo cc.lua: di chuyển liên tục + attack liên tục, không block
                        repeat
                            task.wait()
                            local vhrp = orderTarget:FindFirstChild("HumanoidRootPart")
                            if not vhrp then break end
                            local hp = orderTarget:FindFirstChildWhichIsA("Humanoid")
                            if not hp or hp.Health <= 0 then break end
                            SetText("GET CYBORG | Kill Order HP: " .. math.floor(hp.Health / hp.MaxHealth * 100) .. "%")
                            -- Di chuyển liên tục theo Order (non-blocking)
                            KillMonster("Order")
                            -- Gọi thêm Attack() trực tiếp
                            if getgenv().Attack then getgenv().Attack() end
                        until not orderTarget or not orderTarget.Parent
                            or not orderTarget:FindFirstChildWhichIsA("Humanoid")
                            or orderTarget:FindFirstChildWhichIsA("Humanoid").Health <= 0
                            or not orderTarget:FindFirstChild("HumanoidRootPart")
                            or (LP.Character and LP.Character:FindFirstChild("Humanoid") and LP.Character.Humanoid.Health <= 0)
                        SetText("GET CYBORG | Order đã chết! Chờ xử lý...")
                        StopTween()
                        task.wait(5)
                        if getCurrentRace() == "Cyborg" then
                            SetText("Have Cyborg!")
                        end
                    end
                    if not orderFound then
                        if not CheckTool("Microchip") and not CheckTool("Core Brain") then
                            local frags2 = 0
                            pcall(function() frags2 = LP.Data.Fragments.Value end)
                            if frags2 >= 1000 then
                                RS.Remotes.CommF_:InvokeServer("BlackbeardReward", "Microchip", "2"); task.wait(1)
                            else
                                SetText("GET CYBORG | Không Đủ Fragment Để Buy Chip (" .. frags2 .. "/1000) | Cần thêm " .. (1000 - frags2) .. " → Đổi acc...")
                                FarmSyncChangeAcc("Không đủ fragment mua Microchip (" .. frags2 .. "/1000)")
                                continue
                            end
                        end
                        pcall(function() fireclickdetector(workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector) end)
                        RS.Remotes.CommF_:InvokeServer("CyborgTrainer", "Buy"); task.wait(2)
                    end
                end
            else
                -- Chưa có Microchip/Core Brain → thử mua chip
                local frags2 = 0
                pcall(function() frags2 = LP.Data.Fragments.Value end)
                if frags2 >= 1000 then
                    SetText("GET CYBORG | Mua Microchip...")
                    RS.Remotes.CommF_:InvokeServer("BlackbeardReward", "Microchip", "2"); task.wait(1)
                else
                    SetText("GET CYBORG | Không Đủ Fragment Để Buy Chip (" .. frags2 .. "/1000) | Cần thêm " .. (1000 - frags2) .. " → Đổi acc...")
                    FarmSyncChangeAcc("Không đủ fragment mua Microchip (" .. frags2 .. "/1000)")
                    task.wait(3)
                end
            end
        end
    end
end

task.wait(1)

if getCurrentRace() ~= "Cyborg" then
    if not HasUnlockedCyborg() then
        SetText("Chưa unlock Cyborg → Đang lấy...")
        GetCyborgFirstTime()
    else
        SetText("Đang đổi sang Cyborg...")
        invoke("CyborgTrainer", "Buy")
        task.wait(2)
    end
end

SetText("Bắt đầu farm Cyborg V3...")
while not getgenv().StopV3 do
    task.wait(5)

    local lv = RS.Remotes.CommF_:InvokeServer("getRaceLevel")

    if lv == 1 then
        SetText("Cyborg | V2")
        _G.FarmV2 = true
        GetV2()
    end

    if lv == 2 then
        local ws = RS.Remotes.CommF_:InvokeServer("Wenlocktoad", "1")

        if ws == 0 then
            SetText("Cyborg V3 | Get quest")
            RS.Remotes.CommF_:InvokeServer("Wenlocktoad", "2")

        elseif ws == 1 then
            local cheapest, cheapestName = math.huge, nil
            local ok, inv = pcall(function()
                return RS.Remotes.CommF_:InvokeServer("getInventory")
            end)
            if ok and inv then
                for _, v in pairs(inv) do
                    if v.Type == "Blox Fruit" and v.Value < cheapest then
                        cheapest = v.Value
                        cheapestName = v.Name
                    end
                end
            end
            if cheapestName then
                SetText("Cyborg V3 | Nộp trái: " .. cheapestName)
                RS.Remotes.CommF_:InvokeServer("LoadFruit", cheapestName)
                task.wait(1)
                RS.Remotes.CommF_:InvokeServer("Wenlocktoad", "3")
                task.wait(2)
            else
                SetText("Cyborg V3 | Không có trái → Mua trái Random!")
                local bought = BuyRandomFruit()
                if not bought then
                    SetText("Cyborg V3 | Không đủ tiền → Hop!")
                    task.wait(3)
                    HopServer()
                end
            end

        elseif ws == 2 then
            SetText("Cyborg V3 | Nộp quest")
            RS.Remotes.CommF_:InvokeServer("Wenlocktoad", "3")
            task.wait(1)

        elseif ws == -2 then
            SetText("Cyborg V3 DONE!")
            break
        end
    end

    if lv == 3 then
        SetText("Cyborg V3 DONE!")
        getgenv().StopV3 = true
        break
    end
end
SetText("Done Cyborg V3!")
