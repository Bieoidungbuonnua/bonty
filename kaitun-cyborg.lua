
if not LPH_OBFUSCATED then
    LPH_ENCSTR = LPH_ENCSTR or function(...) return ... end
    LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(...) return ... end
end

while not game.Players.LocalPlayer.Character
   or not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", "Marines")
    task.wait(1)
end

local placeIdd = game.PlaceId
local worldMap = {[2753915549]="World1",[85211729168715]="World1",[4442272183]="World2",[79091703265657]="World2",[7449423635]="World3",[100117331123089]="World3"}

local CG = getgenv().Config
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local VIM = game:GetService("VirtualInputManager")
local LP = game:GetService("Players").LocalPlayer

local MAX_CHESTS_PER_SERVER = 55

Services = setmetatable({}, {__index = function(self, name)
    local s, c = pcall(function() return cloneref(game:GetService(name)) end)
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

local Character = LP.Character
repeat task.wait(2)
until Character
    and Character:FindFirstChild("HumanoidRootPart")
    and Character:FindFirstChildWhichIsA("Humanoid")
    and Character:IsDescendantOf(workspace.Characters)

pcall(function() LP.PlayerGui:FindFirstChild("Blank"):Destroy() end)
local ScreenGuis = Instance.new("ScreenGui", LP.PlayerGui)

if CG["Black Screen"] then
    local BlankScreen = Instance.new("ScreenGui", LP.PlayerGui)
    BlankScreen.Name = "Blank"
    BlankScreen.ResetOnSpawn = false
    BlankScreen.DisplayOrder = -math.huge
    BlankScreen.IgnoreGuiInset = true
    local Black = Instance.new("Frame", BlankScreen)
    Black.Name = "Black Screen"
    Black.Size = UDim2.new(1, 0, 1, 0)
    Black.BackgroundColor3 = Color3.new(0, 0, 0)
    Black.ZIndex = -math.huge
    if Black.Visible then RunService:Set3dRenderingEnabled(false) end
end



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

loadstring(game:HttpGet("https://raw.githubusercontent.com/naa-aneex211/-/refs/heads/main/m1-attack.txt"))()


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
    task.spawn(function()
        while task.wait(.05) do
            if _G.FastAttack == os.time() then
                pcall(function() Funcs:Attack() end)
            end
        end
    end)
    getgenv().Attack = function()
        pcall(function() _G.FastAttack = os.time() end)
    end
]])
if FastAttack then FastAttack() end

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

--------------------------------------------------
--------------------------------------------------
local lastKenCall = tick()
KillMonster = function(x)
    xpcall(function()
        if workspace.Enemies:FindFirstChild(x) then
            for _, v in next, workspace.Enemies:GetChildren() do
                local vh = v:FindFirstChildWhichIsA("Humanoid")
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
                        -- Step 1: Vọt lên trời tại vị trí XZ hiện tại
                        myHrp.CFrame = CFrame.new(myHrp.Position.X, 10000000, myHrp.Position.Z)
                        -- Step 2: Bay ngang sang XZ của boss (vẫn ở trên cao)
                        myHrp.CFrame = CFrame.new(bossPos.X, 10000000, bossPos.Z)
                        -- Step 3: Lao thẳng xuống boss nhưng giữ nguyên XZ vừa set (Sky Hop)
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
    end, function(e) warn("Modules ERROR:", e) end)
end
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
                if stuckTime >= 30 then
                    SetText("Stuck for 30s -> Hop Server!")
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

local function MAX_CHESTS_FarmChestFast()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local Chests = CollectionService:GetTagged("_ChestTagged")
    local Position = LP.Character.HumanoidRootPart.Position
    local sorted = {}
    for _, chest in ipairs(Chests) do
        if chest:IsA("BasePart") and chest.CanTouch and not chest:GetAttribute("IsDisabled") then
            table.insert(sorted, {obj=chest, dist=(chest.Position - Position).Magnitude})
        end
    end
    table.sort(sorted, function(a, b) return a.dist < b.dist end)

    if #sorted == 0 then
        SetText("Not Found Chest → Hop")
        HopServer(5)
        return
    end

    local collected = 0
    for _, data in ipairs(sorted) do
        if getgenv().StopV3 then break end
        if CheckTool("Fist of Darkness") then return "FOD" end
        if collected >= MAX_CHESTS_PER_SERVER then
            SetText("Done " .. MAX_CHESTS_PER_SERVER .. " → Hop")
            HopServer(5)
            return
        end
        local chest = data.obj
        if not chest or not chest.Parent or not chest.CanTouch then continue end
        for _, part in LP.Character:GetDescendants() do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        local attempts = 0
        repeat
            attempts = attempts + 1
            if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then break end
            if not chest or not chest.Parent then break end
            if CheckTool("Fist of Darkness") then return "FOD" end
            LP.Character.HumanoidRootPart.CFrame = chest.CFrame
            task.wait(0.3)
        until not chest.CanTouch or attempts > 15
        if not chest.CanTouch then
            collected = collected + 1
            SetText("Chest | " .. collected .. "/" .. MAX_CHESTS_PER_SERVER)
        end
        if collected > 0 and collected % 10 == 0 then
            if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
                LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
                task.wait(3)
                repeat task.wait(0.5)
                until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    and LP.Character:FindFirstChildOfClass("Humanoid")
                    and LP.Character:FindFirstChildOfClass("Humanoid").Health > 0
            end
        end
    end
    SetText("Chest | Hết (" .. collected .. ") → Hop")
    HopServer(5)
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
                    repeat task.wait() KillMonster("Swan Pirate")
                    until GetBP("Flower 3") or not v.Parent or v.Humanoid.Health <= 0
                else
                    TweenTo(CFrame.new(980.099, 121.331, 1287.209))
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

        if LP.Data.Fragments.Value >= 2500 then
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
            local frags = LP.Data.Fragments.Value
            if frags >= 5000 or CheckTool("Microchip") or CheckTool("Core Brain") then
                if not CheckSea(2) then
                    SetText("GET CYBORG | go Sea 2")
                    RS.Remotes.CommF_:InvokeServer("TravelDressrosa"); task.wait(10)
                else
                    local orderFound = false
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Order" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            orderFound = true
                            SetText("GET CYBORG | Attack Order")
                            EquipByTip("Melee")
                            KillMonster("Order"); break
                        end
                    end
                    if not orderFound then
                        if not CheckTool("Microchip") and not CheckTool("Core Brain") then
                            RS.Remotes.CommF_:InvokeServer("BlackbeardReward", "Microchip", "2"); task.wait(1)
                        end
                        pcall(function() fireclickdetector(workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector) end)
                        RS.Remotes.CommF_:InvokeServer("CyborgTrainer", "Buy"); task.wait(2)
                    end
                end
            else
                if not CheckSea(3) then
                    SetText("GET CYBORG | go Sea 3")
                    RS.Remotes.CommF_:InvokeServer("TravelZou"); task.wait(10)
                end
            end
        end
    end
end


local world = worldMap[placeIdd]
if world == "World1" or world == "World3" then
    RS.Remotes.CommF_:InvokeServer("TravelDressrosa")
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
        break
    end
end

SetText("Done Cyborg V3!")
