
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local vim1 = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))

while not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", getgenv().Team )
    task.wait(1)
end
local placeId = game.PlaceId
local worldMap = {[2753915549] = "World1",[85211729168715] = "World1",[4442272183] = "World2",[79091703265657] = "World2",[7449423635] = "World3",[100117331123089] = "World3"}
sea = getgenv().Config["Select Sea"]
if sea == "Sea 1" then
   if placeId == 4442272183 or placeId == 79091703265657 or placeId == 7449423635 or placeId == 100117331123089 then
   game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelMain")
   end
elseif sea == "Sea 2" then
   if placeId == 2753915549 or placeId == 85211729168715 or placeId == 7449423635 or placeId == 100117331123089 then
   game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelDressrosa")
   end
elseif sea == "Sea 3" then
    if placeId == 4442272183 or placeId == 79091703265657 or placeId == 2753915549 or placeId == 85211729168715 then
    game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelZou")
    end
end

local RunService = game:GetService("RunService")

task.spawn(function()
    local connection
    connection = RunService.RenderStepped:Connect(function()
---------------------------------------------------------
        local promptOverlay = game:GetService("CoreGui").RobloxPromptGui.promptOverlay
        local errorPrompt = promptOverlay:FindFirstChild("ErrorPrompt")
        
        if errorPrompt and errorPrompt:FindFirstChild('MessageArea') then
            local errorFrame = errorPrompt.MessageArea:FindFirstChild("ErrorFrame")
            if errorFrame and errorFrame:FindFirstChild("ErrorMessage") then
                local errorText = errorFrame.ErrorMessage.Text
                
                if not errorText:find("772") then
                    game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser"):InvokeServer("teleport", game.JobId)
                    connection:Disconnect()
                end
            end
        end
---------------------------------------------------------
    end)
end)


loadstring(game:HttpGet("https://raw.githubusercontent.com/Bieoidungbuonnua/bonty/refs/heads/main/m1-attack.txt"))()
local character = LocalPlayer.Character or player.CharacterAdded:Wait()

local controls = playerModule:GetControls()
local function disableControls()
    controls:Disable()
end

local function startWalking(char)
    local humanoid = char:WaitForChild("Humanoid")
    local rootPart = char:WaitForChild("HumanoidRootPart")   
    disableControls()
    task.spawn(function()
        while char:IsDescendantOf(game) and humanoid.Health > 0 do
            local randomX = math.random(-20, 20)
            local randomZ = math.random(-20, 20)
            local targetPos = rootPart.Position + Vector3.new(randomX, 0, randomZ)           
            humanoid:MoveTo(targetPos)           
            humanoid.MoveToFinished:Wait()
            task.wait()
        end
    end)
end

player.CharacterAdded:Connect(function(char)
    startWalking(char)
end)
if player.Character then
    startWalking(player.Character)
end
wait(.5)

local CONFIG = {
    FollowDelay = 0.0,
    SwitchDelay = 8,
    Offset = Vector3.new(3, 0, 0),
    MinBounty = 0,
    SkimDelay = 0.05
}

local isHopping = false 
local currentTarget = nil
local running = false
local followThread = nil
local switchTimer = 0
local rejoinEnabled = true
local kenEnabled = true
local lastDamageTime = tick()
local lastTargetHealth = 0

local Whitelist = {}
local Blacklist = {}
local ScanCompleted = false
local IsScanning = false

local NotificationSystem = {
    notifications = {},
    spacing = 90, 
    gui = nil
}

local function CreateNotifyGui()
    local pGui = player:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("MeyyCloudNotify") then return pGui:FindFirstChild("MeyyCloudNotify") end
    local sg = Instance.new("ScreenGui")
    sg.Name = "MeyyCloudNotify"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = game:GetService("CoreGui") or pGui
    return sg
end

NotificationSystem.gui = CreateNotifyGui()

function NotificationSystem:UpdatePositions()
    for i, notif in ipairs(self.notifications) do
        if notif and notif.Parent then
            local targetPos = UDim2.new(1, -20, 1, -20 - ((i - 1) * self.spacing))
            game:GetService("TweenService"):Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        end
    end
end

function NotificationSystem:Notify(title, message, duration)
    local m = Instance.new("Frame", self.gui)
    m.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    m.BackgroundTransparency = 0.3
    m.Size = UDim2.new(0, 260, 0, 80) 
    m.Position = UDim2.new(1, 300, 1, -20) 
    m.AnchorPoint = Vector2.new(1, 1)
    Instance.new("UICorner", m).CornerRadius = UDim.new(0, 10)

    local u = Instance.new("UIStroke", m)
    u.Thickness = 2.5
    u.Color = Color3.new(1, 1, 1)
    local e = Instance.new("UIGradient", u)
    
    local bgGrad = Instance.new("UIGradient", m)
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 248, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(224, 240, 255))
    })

    local function CreateLabel(txt, pos, sz)
        local l = Instance.new("TextLabel", m)
        l.Size = UDim2.new(1, -20, 0, 25)
        l.Position = UDim2.new(0.5, 0, 0, pos)
        l.AnchorPoint = Vector2.new(0.5, 0)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.Text = txt
        l.TextSize = sz
        l.TextColor3 = Color3.new(1, 1, 1)
        local ts = Instance.new("UIStroke", l)
        ts.Thickness = 1.2
        ts.Color = Color3.fromRGB(150, 200, 220)
        return l
    end

    CreateLabel(title, 12, 18)
    CreateLabel(message, 40, 12)

    local r = 0
    local conn
    conn = game:GetService("RunService").RenderStepped:Connect(function()
        r = (r + 2) % 360
        e.Rotation = r
        local c1 = Color3.fromRGB(180, 220, 255)
        e.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, c1)})
    end)

    table.insert(self.notifications, m)
    self:UpdatePositions()

    task.delay(duration or 3, function()
        for i, notif in ipairs(self.notifications) do
            if notif == m then table.remove(self.notifications, i) break end
        end
        self:UpdatePositions()
        local hide = game:GetService("TweenService"):Create(m, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 300, m.Position.Y.Scale, m.Position.Y.Offset)})
        hide:Play()
        hide.Completed:Connect(function()
            conn:Disconnect()
            m:Destroy()
        end)
    end)
end

_G.Notify = NotificationSystem
function notify(title, msg, time)
    _G.Notify:Notify(title, msg, time or 3)
end

local function getBounty(p)
    local ok, val = pcall(function()
        local ls = p:FindFirstChild("leaderstats")
        if ls then
            local b = ls:FindFirstChild("Bounty/Honor") or ls:FindFirstChild("Bounty") or ls:FindFirstChild("Honor")
            if b then return b.Value end
        end
        return 0
    end)
    return ok and val or 0
end

local function isInSafeZone(p)
    local char = p and p.Character
    if not char then return false end
    if char:FindFirstChild("NoPvP") or char:FindFirstChild("SafeZone") then return true end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local ok = pcall(function()
            for _, v in pairs(workspace["_WorldOrigin"]["SafeZones"]:GetChildren()) do
                if v:IsA("Part") and (v.Position - hrp.Position).Magnitude <= 400 then error("in") end
            end
        end)
        if not ok then return true end
    end
    return false
end

local function isPvPDisabled(p)
    return p:GetAttribute("PvpDisabled") == true
end

function CheckInCombat()
    return LocalPlayer:GetAttribute("PvpDisabled") == true
end

function risk() 
       local success, val = pcall(function()
        local mainGui = lp.PlayerGui:FindFirstChild("Main")
        if mainGui then
            for _, v in ipairs(mainGui:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible then
                    local text = v.Text
                    if string.find(text, "risk") or string.find(text, "risk") then
                        return true
                    end
                end
            end
        end
        return false
    end)
    return success and val
end


local predictionData = {} 
local PREDICT_RATIO = 65 / 140
local MAX_SAMPLES = 10
local enemyHistory = {}
local function teleportTo(target)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        local myPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
        local targetChar = target.Character
        if not targetChar then return end
        
        local targetPart = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("Head")
        local targetHum = targetChar:FindFirstChild("Humanoid")
        
        if myPart and targetPart then
            local currentTime = tick()
            local currentPos = targetPart.Position
            
            if not enemyHistory[target.Name] then
                enemyHistory[target.Name] = {
                    lastPos = currentPos,
                    lastTime = currentTime,
                    speeds = {}
                }
                return
            end
            
            local data = enemyHistory[target.Name]
            local deltaTime = currentTime - data.lastTime
            
            if deltaTime > 0 then
                local distance = (currentPos - data.lastPos).Magnitude
                local instantSpeed = distance / deltaTime
                
                table.insert(data.speeds, instantSpeed)
                if #data.speeds > MAX_SAMPLES then
                    table.remove(data.speeds, 1)
                end
                
                local sumSpeed = 0
                for _, s in ipairs(data.speeds) do
                    sumSpeed = sumSpeed + s
                end
                local averageSpeed = sumSpeed / #data.speeds
                
                ---------------------------------------------------------
                local moveActualDir = (currentPos - data.lastPos).Unit
                ---------------------------------------------------------
                
                data.lastPos = currentPos
                data.lastTime = currentTime
                
                local basePos
                if averageSpeed > 0.5 then
                    local finalDir
                    if targetHum and targetHum.MoveDirection.Magnitude > 0 then
                        local moveDir = targetHum.MoveDirection
                        local lookDir = targetPart.CFrame.LookVector
                        finalDir = (moveDir.Unit + lookDir).Unit
                    else
                        finalDir = moveActualDir
                    end
                    
                    local predictStud = averageSpeed * PREDICT_RATIO
                    basePos = targetPart.Position + (finalDir * predictStud)
                else
                    basePos = targetPart.Position + (targetPart.CFrame.LookVector * 5)
                end

                local offsets = {
                    Vector3.new(7, 5, 0),
                    Vector3.new(-7, 5, 0),
                    Vector3.new(0, 5, 7),
                    Vector3.new(0, 5, -4)
                }
                local randomOffset = offsets[math.random(1, #offsets)]
                local finalTpPos = basePos + randomOffset
                
                myPart.CFrame = CFrame.new(finalTpPos, targetPart.Position)
            end
        end
    end)
end


------------------------------------------------------------------------------------------------------------------
local function hopServer()
    if isHopping then return end 
    isHopping = true 

    task.spawn(function()
        if not getgenv().Config["Reset"] then 
            notify("Hop System", "Moving to safety (10k height)...", 5) 

            task.spawn(function()
                while isHopping do
                    pcall(function()
                        local character = game.Players.LocalPlayer.Character
                        local myHrp = character and character:FindFirstChild("HumanoidRootPart") 
                        if myHrp then
                            myHrp.CFrame = CFrame.new(myHrp.Position.X, 10000000000, myHrp.Position.Z) 
                            myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        end
                    end)
                    task.wait()
                end
            end)

            local hasRisk = false
            pcall(function()
                if string.find(string.lower(game.Players.LocalPlayer.PlayerGui.Main.BottomHUDList.InCombat.Text), "risk") then
                    hasRisk = true
                end
            end)

            if hasRisk then
                notify("Hop System", "Risk detected! Waiting 30s...", 30)
                task.wait(36)
            end
        end

        notify("Hop System", "Searching servers...", 5) 
        
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerGui.ServerBrowser.Frame.Filters.SearchRegion.TextBox.Text = "Singapore" 
        end)
        
        while isHopping do
            task.wait(0)
            if not CheckInCombat() then
                for r = 1, 100 do 
                    local success, servers = pcall(function() 
                        return game.ReplicatedStorage.__ServerBrowser:InvokeServer(r) 
                    end) 
                    
                    if success and servers then
                        for k, v in pairs(servers) do
                            if k ~= game.JobId and v["Count"] <= 10 then 
                                notify("Hop System", "Found server! Teleporting...", 3) 
                                game.ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", k) 
                                task.wait()
                            end
                        end
                    end
                end
            end
        end
        isHopping = false 
    end)
end

local function isValidTarget(p)
    if p == LocalPlayer then return false end
    if not p or not p.Parent then return false end
    
    if Blacklist[p.Name] then return false end 
    
    if getgenv().Config.mode == "method2" then
        if p.Team == LocalPlayer.Team and LocalPlayer.Team and LocalPlayer.Team.Name == "Marines" then return false end
    end
    
    local char = p.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    if isInSafeZone(p) then return false end
    if isPvPDisabled(p) then return false end
    
    local raidMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("RaidMap")
    if raidMap and char:IsDescendantOf(raidMap) then 
        return false 
    end
    
    local function getLv(plr)
        local d = plr:FindFirstChild("Data")
        local l = d and d:FindFirstChild("Level")
        return l and l.Value or 0
    end
    
    if math.abs(getLv(LocalPlayer) - getLv(p)) > 500 then 
        return false 
    end
    

    if CONFIG.MinBounty > 0 and getBounty(p) < CONFIG.MinBounty then return false end
    return true
end

local function getRandomPlayer()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            if getgenv().Config.mode == "method2" and ScanCompleted then
                if Whitelist[p.Name] then table.insert(list, p) end
            else
                table.insert(list, p)
            end
        end
    end
    if #list == 0 then return nil end
    return list[math.random(1, #list)]
end

local function pickNewTarget(reason)
    local old = currentTarget and currentTarget.Name or "none"
    currentTarget = getRandomPlayer()
    switchTimer = 0
    
    lastTargetHealth = 0
    lastDamageTime = tick() 
    
    if currentTarget then
        print(string.format("Target [%s] %s -> %s", reason, old, currentTarget.Name))
    else
        print("Waiting for valid targets...")
        if getgenv().Config.mode == "method2" and ScanCompleted then
            notify("Auto Bounty", "No targets left, hopping server...", 5)
            hopServer()
        elseif getgenv().Config.mode == "method1" then
            notify("Auto Bounty", "No targets left, hopping server...", 5)
            hopServer()
        end
    end
end

local function checkCurrentTarget()
    if not currentTarget then return false end
    if not currentTarget.Parent then pickNewTarget("left game"); return false end
    local char = currentTarget.Character
    if not char then pickNewTarget("no character"); return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then
        if getgenv().Config.mode == "method2" then Whitelist[currentTarget.Name] = nil end
        pickNewTarget("died"); return false
    end
    if isInSafeZone(currentTarget) then pickNewTarget("entered safezone"); return false end
    if isPvPDisabled(currentTarget) then pickNewTarget("pvp disabled"); return false end
    return true
end

local function RunFullScan()
    if ScanCompleted or IsScanning then return end
    IsScanning = true
    notify("Scan System", "Starting 5-cycle skimming scan...", 7)

    for cycle = 1, 7 do
        if not running then IsScanning = false return end
        notify("Scan System", "Cycle: " .. cycle .. "/7", 2)
        
        for _, p in pairs(Players:GetPlayers()) do
            if not running then break end
            local isMarine = LocalPlayer.Team and LocalPlayer.Team.Name == "Marines"
            local isSameTeam = p.Team == LocalPlayer.Team

            if p ~= LocalPlayer and not (isMarine and isSameTeam) and not Blacklist[p.Name] then
                if Whitelist[p.Name] then
                    local char = p.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    if not char or not hum or hum.Health <= 0 then
                        Whitelist[p.Name] = nil
                        Blacklist[p.Name] = true
                    end
                    continue
                end

                if not Whitelist[p.Name] then
                    local char = p.Character
                    if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
                        if not isInSafeZone(p) and not isPvPDisabled(p) then
                        notify("Scan System", "Checking: " .. p.Name, 1.5)
                            local hum = char.Humanoid
                            local startHealth = hum.Health
                            
                            for i = 1, 20 do
                                if not running then break end
                                teleportTo(p)
                                task.wait(CONFIG.SkimDelay) 
                            end
                            
                            task.wait(0.05) 
                            local newHealth = hum.Health
                            if newHealth < startHealth then
                                Whitelist[p.Name] = true
                                notify("Scan System", "Whitelist added: " .. p.Name, 2)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not Whitelist[p.Name] then Blacklist[p.Name] = true end
    end

    IsScanning = false
    ScanCompleted = true
    notify("Scan System", "Scan finished! Ready to hunt.", 7)
end


local function stopAll()
    running = false
    IsScanning = false
    if followThread then task.cancel(followThread); followThread = nil end
    currentTarget = nil
    switchTimer = 0
end

local function startRandom()
    stopAll() 
    running = true

    if getgenv().Config.mode == "method1" then
        pickNewTarget("start")
        followThread = task.spawn(function()
            while running do
                task.wait(0.1) 
                if not running then break end
                if not checkCurrentTarget() then task.wait(1); continue end
                teleportTo(currentTarget)
                
                local hum = currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid")
                if hum then
                    if hum.Health < lastTargetHealth then
                        lastDamageTime = tick() 
                    end
                    lastTargetHealth = hum.Health
                end

                if tick() - lastDamageTime >= CONFIG.SwitchDelay then
                    if currentTarget then
                        Blacklist[currentTarget.Name] = true
                    end
                    pickNewTarget("8s khĂ´ng máº¥t mĂ¡u")
                end
            end
        end)
    else
        followThread = task.spawn(function()
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHrp then
                local placeId = game.PlaceId
                
                if placeId == 2753915133 then
                    local function hasValkyrieHelm()
                        local inv = ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
                        if inv then
                            for _, v in ipairs(inv) do
                                if v.Name == "Valkyrie Helm" then return true end
                            end
                        end
                        return false
                    end

                    if hasValkyrieHelm() then
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(5643.45263671875, 1013.0858154296875, -340.51025390625))
                    end

                elseif placeId == 4442272160 then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923, 126, 32852))
                end
                
                task.wait(1.5)
            end

            if not ScanCompleted then RunFullScan() end 
            if not running then return end
            pickNewTarget("start")

            while running do
                task.wait(0.1) 
                if not running then break end
                if not checkCurrentTarget() then task.wait(1); continue end
                
                if Whitelist[currentTarget.Name] then
                    for i = 1, 5 do
                        if not running or not checkCurrentTarget() then break end
                        teleportTo(currentTarget) 
                        task.wait(CONFIG.SkimDelay) 
                    end
                else
                    teleportTo(currentTarget)
                end
               
                local hum = currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid")
                if hum then
                    if hum.Health < lastTargetHealth then
                        lastDamageTime = tick()
                    end
                    lastTargetHealth = hum.Health
                end

                switchTimer = switchTimer + 0.1 
                if switchTimer >= CONFIG.SwitchDelay then 
                    if currentTarget then
                        Blacklist[currentTarget.Name] = true
                        Whitelist[currentTarget.Name] = nil
                    end
                    pickNewTarget("8s timeout & blacklist") 
                end
            end
        end)
    end
end


local SKIP_NOTIF_KEYWORDS = {
    "pvp", "chua bat", "cannot attack", "unable to attack",
    "khong the tan cong", "nguoi choi", "player recently",
    "vua tu tran", "protection", "bao ve",
    "player", "safezone"
}

spawn(function()
    while task.wait(0.2) do
        pcall(function()
            local notifs = LocalPlayer.PlayerGui:FindFirstChild("Notifications")
            if notifs then
                for _, v in pairs(notifs:GetChildren()) do
                    local lbl = v:IsA("TextLabel") and v or v:FindFirstChildWhichIsA("TextLabel", true)
                    if lbl and lbl.Text and lbl.Text ~= "" then
                        local text = lbl.Text:lower()
                        for _, kw in pairs(SKIP_NOTIF_KEYWORDS) do
                            if text:find(kw, 1, true) then
                                if currentTarget then 
                                    if getgenv().Config.mode == "method2" then Whitelist[currentTarget.Name] = nil end
                                    Blacklist[currentTarget.Name] = true
                                end
                                pickNewTarget("notification bypass")
                                pcall(function() v:Destroy() end)
                                break
                            end
                        end
                    end
                end
            end
        end)
    end
end)

spawn(function()
    while task.wait(1) do
        if getgenv().Config.mode == "method1" then continue end
        if not running or not ScanCompleted or not currentTarget then
            continue
        end
        if tick() - lastDamageTime >= 30 then
            lastDamageTime = tick()
            hopServer() 
        end
    end
end)

local function ForceEnablePvP()
    pcall(function()
        local mainGui = LocalPlayer.PlayerGui:FindFirstChild("Main")
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("EnablePvp")
        if mainGui then
            local pvpBtn = mainGui:FindFirstChild("PvpDisabled") or mainGui:FindFirstChild("SafeZone")
            if pvpBtn and pvpBtn.Visible then
                for _, connection in pairs(getconnections(pvpBtn.MouseButton1Click)) do
                    connection:Fire()
                end
            end
        end
    end)
end

task.spawn(function()
    while task.wait(2) do 
        ForceEnablePvP()
    end
end)

spawn(function()
    while task.wait(2) do
        if not kenEnabled then continue end
        pcall(function()
            local char = LocalPlayer.Character
            if char and not char:FindFirstChild("HasObservation") then
                VirtualUser:CaptureController()
                VirtualUser:SetKeyDown("0x65")
                task.wait(0.05)
                VirtualUser:SetKeyUp("0x65")
            end
        end)
    end
end)

LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent and rejoinEnabled then task.wait(2); rejoin() end
end)

if getgenv().MainUI then
    pcall(function() getgenv().MainUI:Destroy() end)
    getgenv().MainUI = nil
end

if getgenv().Config.BlackScreen then
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ScreenGui"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")

    local Frame = Instance.new("Frame")
    Frame.Name = "Frame"
    Frame.Position = UDim2.new(-0.206146, 0, -0.150063, 0)
    Frame.Size = UDim2.new(0, 2544, 0, 1355)
    Frame.BackgroundColor3 = Color3.new(0.0235294, 0.0235294, 0.0235294)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Position = UDim2.new(0.462572, 0, 0.343508, 0)
    TextLabel.Size = UDim2.new(0, 200, 0, 50)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = "Time Elapsed : ..."
    TextLabel.TextColor3 = Color3.new(1, 1, 1)
    TextLabel.TextSize = 28
    TextLabel.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    TextLabel.Parent = ScreenGui
    getgenv()._BS_TimeLabel = TextLabel

    local TextLabel2 = Instance.new("TextLabel")
    TextLabel2.Position = UDim2.new(0.462572, 0, 0.266818, 0)
    TextLabel2.Size = UDim2.new(0, 200, 0, 50)
    TextLabel2.BackgroundTransparency = 1
    TextLabel2.Text = "Bounty Earned : ...."
    TextLabel2.TextColor3 = Color3.new(1, 1, 1)
    TextLabel2.TextSize = 28
    TextLabel2.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    TextLabel2.Parent = ScreenGui
    getgenv()._BS_BountyLabel = TextLabel2

    local TextLabel3 = Instance.new("TextLabel")
    TextLabel3.Position = UDim2.new(0.462572, 0, 0.204578, 0)
    TextLabel3.Size = UDim2.new(0, 200, 0, 50)
    TextLabel3.BackgroundTransparency = 1
    TextLabel3.Text = "Target : "
    TextLabel3.TextColor3 = Color3.new(1, 1, 1)
    TextLabel3.TextSize = 25
    TextLabel3.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    TextLabel3.Parent = ScreenGui
    getgenv()._BS_TargetLabel = TextLabel3

    local TextLabel4 = Instance.new("TextLabel")
    TextLabel4.Position = UDim2.new(0.350045, 0, 0.0638366, 0)
    TextLabel4.Size = UDim2.new(0, 571, 0, 102)
    TextLabel4.BackgroundTransparency = 1
    TextLabel4.Text = "Meyy Hub - Auto Bounty M1 Fruit"
    TextLabel4.TextColor3 = Color3.new(1, 1, 1)
    TextLabel4.TextSize = 35
    TextLabel4.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    TextLabel4.Parent = ScreenGui

    local Line = Instance.new("Frame")
    Line.Position = UDim2.new(0.361577, 0, 0.191517, 0)
    Line.Size = UDim2.new(0, 533, 0, 1)
    Line.BackgroundColor3 = Color3.new(0.686275, 0.0980392, 0.658824)
    Line.BorderSizePixel = 0
    Line.Parent = ScreenGui
else
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "meyyy_hub_bounty_final_" .. math.random(100, 999)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    getgenv().MainUI = ScreenGui

    local isMini = false
    local m = Instance.new("Frame", ScreenGui)
    m.Name = "MainFrame"
    m.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    m.BackgroundTransparency = 0.2
    m.Size = UDim2.new(0, 500, 0, 350)
    m.Position = UDim2.new(0.5, 0, 0.5, 0)
    m.AnchorPoint = Vector2.new(0.5, 0.5)
    m.ClipsDescendants = true
    Instance.new("UICorner", m).CornerRadius = UDim.new(0, 15)

    local u = Instance.new("UIStroke", m)
    u.Thickness = 3.5
    u.Color = Color3.new(1, 1, 1)
    local e = Instance.new("UIGradient", u)
    local RotateGradients = {e}

    local bgGradient = Instance.new("UIGradient", m)
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 250, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 245, 255))
    })

    local dragging, dragInput, dragStart, startPos
    m.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            dragStart = input.Position
            startPos = m.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            m.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local SnowContainer = Instance.new("Frame", m)
    SnowContainer.Size = UDim2.new(1, -20, 1, -20)
    SnowContainer.Position = UDim2.new(0, 10, 0, 10)
    SnowContainer.BackgroundTransparency = 1
    SnowContainer.ZIndex = 0
    SnowContainer.ClipsDescendants = true 

    task.spawn(function()
        while task.wait(0.25) do 
            if not m.Visible or isMini then continue end
            local flake = Instance.new("ImageLabel", SnowContainer)
            flake.BackgroundTransparency = 1
            flake.Image = "rbxthumb://type=Asset&id=137906289429512&w=150&h=150"
            local randomSize = math.random(8, 15)
            flake.Size = UDim2.new(0, randomSize, 0, randomSize)
            flake.Position = UDim2.new(math.random(), 0, -0.1, 0)
            flake.ImageTransparency = math.random(4, 8) / 10 
            local tween = TweenService:Create(flake, TweenInfo.new(math.random(3, 5), Enum.EasingStyle.Linear), {
                Position = UDim2.new(flake.Position.X.Scale, 0, 1.1, 0),
                Rotation = math.random(-180, 180)
            })
            tween:Play()
            tween.Completed:Connect(function() flake:Destroy() end)
        end
    end)

    local function CreateLabel(name, parent, pos, size, text, textSize, align)
        local l = Instance.new("TextLabel", parent)
        l.Name = name
        l.Size = size
        l.Position = pos
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.Text = text
        l.TextSize = textSize
        l.TextColor3 = Color3.new(1, 1, 1)
        l.TextXAlignment = align or Enum.TextXAlignment.Center
        local ts = Instance.new("UIStroke", l)
        ts.Thickness = 1.8
        ts.Color = Color3.fromRGB(130, 190, 230)
        local tg = Instance.new("UIGradient", l)
        table.insert(RotateGradients, tg)
        return l
    end

    local function CreateMeyyButton(parent, size, pos, anchor, buttonText)
        local btn = Instance.new("TextButton", parent)
        btn.Size = size
        btn.Position = pos
        btn.AnchorPoint = anchor
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 0.6 
        btn.AutoButtonColor = false
        btn.Text = "" 
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Thickness = 2.5 
        btnStroke.Color = Color3.new(1, 1, 1)
        btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border 

        local btnGrad = Instance.new("UIGradient", btnStroke)
        btnGrad.Color = ColorSequence.new({ 
            ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 230, 255)), 
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 230, 255))
        })

        table.insert(RotateGradients, btnGrad)
        
        local label = Instance.new("TextLabel", btn)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.Text = buttonText 
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 14 
        
        local txtStroke = Instance.new("UIStroke", label)
        txtStroke.Thickness = 1
        txtStroke.Color = Color3.fromRGB(100, 170, 220)
        
        local originalSize = size
        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 4, originalSize.Y.Scale, originalSize.Y.Offset - 4)}):Play()
        end)
        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {Size = originalSize}):Play()
        end)
        return btn, label
    end

    CreateLabel("Title", m, UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 30), "Meyy Hub - Auto Bounty", 22)

    local TargetLabel = CreateLabel("TargetLabel", m, UDim2.new(0, 25, 0, 125), UDim2.new(1, -50, 0, 30), "Target: --", 18, Enum.TextXAlignment.Left)
    local StatusLabel = CreateLabel("StatusLabel", m, UDim2.new(0, 25, 0, 75), UDim2.new(1, -50, 0, 30), "Status: --", 18, Enum.TextXAlignment.Left)

    local ActionFrame = Instance.new("Frame", m)
    ActionFrame.Size = UDim2.new(1, -40, 0, 130)
    ActionFrame.Position = UDim2.new(0, 20, 1, -145) 
    ActionFrame.BackgroundTransparency = 1

    local UIList = Instance.new("UIListLayout", ActionFrame)
    UIList.Padding = UDim.new(0, 10)
    UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function CreateRow()
        local r = Instance.new("Frame", ActionFrame)
        r.Size = UDim2.new(1, 0, 0, 35)
        r.BackgroundTransparency = 1
        return r
    end

    local Row1 = CreateRow()
    local ToggleBtn, ToggleLbl = CreateMeyyButton(Row1, UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), Vector2.new(0,0), "Stop")
    local SkipBtn, SkipLbl = CreateMeyyButton(Row1, UDim2.new(0.48, 0, 1, 0), UDim2.new(1, 0, 0, 0), Vector2.new(1,0), "Skip Player")

    local Row2 = CreateRow()
    local HopBtn, HopLbl = CreateMeyyButton(Row2, UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), Vector2.new(0,0), "Hop Server")
    local RejoinBtn, RejoinLbl = CreateMeyyButton(Row2, UDim2.new(0.48, 0, 1, 0), UDim2.new(1, 0, 0, 0), Vector2.new(1,0), "Auto Rejoin: ON")

    local Row3 = CreateRow()
    local KenBtn, KenLbl = CreateMeyyButton(Row3, UDim2.new(0.48, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), Vector2.new(0.5,0), "Ken: ON")

SkipBtn.MouseButton1Click:Connect(function()
    if currentTarget then
        Blacklist[currentTarget.Name] = true
        if getgenv().Config.mode == "method2" then 
            Whitelist[currentTarget.Name] = nil 
        end
        notify("Meyy Hub", "Skipped & Blacklisted: " .. currentTarget.Name, 2)
    end
    pickNewTarget("manual skip")
end)

    ToggleBtn.MouseButton1Click:Connect(function()
        if running then
            stopAll()
            ToggleLbl.Text = "Start"
            notify("Auto Bounty", "Script stopped, hopping server...", 3)
            hopServer()
        else
            startRandom()
            ToggleLbl.Text = "Stop"
        end
    end)

    HopBtn.MouseButton1Click:Connect(function() hopServer() end)

    RejoinBtn.MouseButton1Click:Connect(function()
        rejoinEnabled = not rejoinEnabled
        if rejoinEnabled then RejoinLbl.Text = "Auto Rejoin: ON" else RejoinLbl.Text = "Auto Rejoin: OFF" end
    end)

    KenBtn.MouseButton1Click:Connect(function()
        kenEnabled = not kenEnabled
        if kenEnabled then KenLbl.Text = "Ken: ON" else KenLbl.Text = "Ken: OFF" end
    end)

    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                if IsScanning then
                    TargetLabel.Text = "Target: --"
                    StatusLabel.Text = "Status: Scanning Server..."
                elseif currentTarget then
                    TargetLabel.Text = "Target: " .. currentTarget.Name
                    if not isValidTarget(currentTarget) then
                        if isInSafeZone(currentTarget) then StatusLabel.Text = "Status: SafeZone"
                        elseif isPvPDisabled(currentTarget) then StatusLabel.Text = "Status: No PvP"
                        else StatusLabel.Text = "Status: Switching..." end
                    else
                        StatusLabel.Text = "Status: Following"
                    end
                else
                    TargetLabel.Text = "Target: waiting scan"
                    if running then
                        StatusLabel.Text = "Status: Searching..."
                    else
                        StatusLabel.Text = "Status: Stopped"
                        if not currentTarget and not IsScanning then hopServer() end
                    end
                end
            end)
        end
    end)

    local ToggleIcon = Instance.new("ImageButton", ScreenGui)
    ToggleIcon.Name = "ToggleIcon"
    ToggleIcon.Size = UDim2.new(0, 45, 0, 45)
    ToggleIcon.Position = UDim2.new(0, 20, 1, -65)
    ToggleIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleIcon.BackgroundTransparency = 0.4
    ToggleIcon.Image = "rbxassetid://6031090990" 
    Instance.new("UICorner", ToggleIcon).CornerRadius = UDim.new(1, 0)
    local tst = Instance.new("UIStroke", ToggleIcon)
    tst.Thickness = 2
    tst.Color = Color3.new(1,1,1)

    ToggleIcon.MouseButton1Click:Connect(function()
        if not isMini then
            isMini = true
            TweenService:Create(m, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        else
            isMini = false
            TweenService:Create(m, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 350)}):Play()
        end
    end)

    RunService.RenderStepped:Connect(function()
        local r = (tick() * 60) % 360
        local colorSeq = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 230, 255)), 
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 230, 255))
        })
        for _, grad in ipairs(RotateGradients) do 
            grad.Rotation = r 
            grad.Color = colorSeq 
        end
        bgGradient.Offset = Vector2.new(math.sin(tick() * 1.5) * 0.1, 0)
    end)

    m.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(m, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 350)}):Play()
end

LocalPlayer.Chatted:Connect(function(msg)
    local mText = msg:lower()
    if mText == "/randtp" then startRandom() 
    elseif mText == "/stoptp" then stopAll() hopServer()
    elseif mText == "/newtp" then pickNewTarget("manual") end
end)

function startRandomTp() startRandom() end
function stopRandomTp() stopAll() hopServer() end
function newTarget() pickNewTarget("manual") end

startRandom()


local humanoid = character:WaitForChild("Humanoid")
local function equipFruit()
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == "Blox Fruit" then
            humanoid:EquipTool(tool)
            return true
        end
    end
    return false
end
equipFruit()

spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local equipped = character:FindFirstChildOfClass("Tool")
            if not equipped or equipped.ToolTip ~= "Blox Fruit" then equipFruit() end
        end)
    end
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    task.wait()
    equipFruit()
end)

_G.RaceClickAutov4 = true
spawn(function()
    while task.wait(0.2) do
        if _G.RaceClickAutov4 then
            pcall(function()
                local char = player.Character
                if char and char:FindFirstChild("RaceEnergy") and char.RaceEnergy.Value >= 1 then
                    vim1:SendKeyEvent(true, "Y", false, game)
                    vim1:SendKeyEvent(false, "Y", false, game)
                end
            end)
        end
    end
end)

spawn(function()
    while task.wait(1) do
        pcall(function()
            local char = LocalPlayer.Character
            if char and not char:FindFirstChild("HasBuso") then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
            end
        end)
    end
end)

function sendKillWebhook(targetName, bountyEarned, currentBounty)
    if not getgenv().Config.Webhook.Enabled or getgenv().Config.Webhook.Url == "" then
        return
    end    
    local url = getgenv().Config.Webhook.Url
    local player = game.Players.LocalPlayer
    local function formatBounty(bounty)
        if bounty >= 1000000 then
            return string.format("%.1fM", bounty / 1000000)
        elseif bounty >= 1000 then
            return string.format("%.1fK", bounty / 1000)
        else
            return tostring(bounty)
        end
    end
    local data = {
        ["embeds"] = {{
            ["title"] = " Auto Bounty M1 Fruit ",
            ["description"] = "Kill Player",
            ["color"] = 0x67eb34,
            ["fields"] = {
                {
                    ["name"] = " Target",
                    ["value"] = "```" .. targetName .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = " Bounty Earned",
                    ["value"] = "```" .. formatBounty(bountyEarned) .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = " Current Bounty",
                    ["value"] = "```" .. formatBounty(currentBounty) .. "```", 
                    ["inline"] = true
                },
                {
                    ["name"] = " Hunter",
                    ["value"] = "```" .. player.Name .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = " Level",
                    ["value"] = "```" .. tostring(player.Data.Level.Value) .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = " Time",
                    ["value"] = "```" .. os.date("%H:%M:%S %d/%m/%Y") .. "```",
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "By Meyy Hub "
            },
            ["thumbnail"] = {
                ["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
            }}}}
    pcall(function()
        local jsonData = game:GetService("HttpService"):JSONEncode(data)
        local success, response = pcall(function()
            if syn then
                return syn.request({
                    Url = url,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = jsonData
                })
            else
                return request({
                    Url = url,
                    Method = "POST", 
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = jsonData
                })
            end
        end)
        
        if success then
            print(" Sent kill webhook: " .. targetName)
        else
            print(" Webhook error: " .. tostring(response))
        end
    end)
end
local SAVE_FOLDER = "MeyyHub_DataBounty"
local SAVE_FILE = SAVE_FOLDER .. "/TotalBounty_" .. player.Name .. ".json"
if not isfolder(SAVE_FOLDER) then makefolder(SAVE_FOLDER) end

local totalBountyEarned = 0
local allTimeKills = 0
local sessionBountyEarned = 0
local totalTimeElapsed = 0

local bsStartTime = os.time()
local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%dh %dm %02ds", h, m, s)
end

spawn(function()
    task.wait(2)
    while task.wait(1) do
        pcall(function()
            if not getgenv().Config.BlackScreen then return end
            local tLbl = getgenv()._BS_TimeLabel
            local bLbl = getgenv()._BS_BountyLabel
            local tgLbl = getgenv()._BS_TargetLabel
            if not tLbl or not bLbl or not tgLbl then return end

            tLbl.Text = "Time Elapsed : " .. formatTime(totalTimeElapsed + math.floor(os.time() - bsStartTime))
            bLbl.Text = "Bounty Earned : +" .. tostring(sessionBountyEarned) .. "$ | Total: " .. tostring(totalBountyEarned) .. "$"

            if IsScanning then
                tgLbl.Text = "Target : Scanning..."
            elseif currentTarget then
                tgLbl.Text = "Target : " .. currentTarget.Name .. " (" .. tostring(getBounty(currentTarget)) .. "$)"
            else
                tgLbl.Text = "Target : Searching..."
            end
        end)
    end
end)

pcall(function()
    if isfile(SAVE_FILE) then
        local data = game:GetService("HttpService"):JSONDecode(readfile(SAVE_FILE))
        totalBountyEarned = data.TotalEarned or 0
        allTimeKills = data.AllTimeKills or 0
        totalTimeElapsed = data.TotalTimeElapsed or 0
    end
end)

local function saveEarnedData()
    pcall(function()
        writefile(SAVE_FILE, game:GetService("HttpService"):JSONEncode({
            TotalEarned = totalBountyEarned,
            AllTimeKills = allTimeKills,
            TotalTimeElapsed = totalTimeElapsed + math.floor(os.time() - bsStartTime),
            LastSave = os.date("%H:%M %d/%m/%Y"),
            Player = player.Name
        }))
    end)
end
local lastBounty = 0
spawn(function()
    while task.wait(1) do
        pcall(function()
            if player and player:FindFirstChild("leaderstats") then
                local cur = player.leaderstats["Bounty/Honor"] and player.leaderstats["Bounty/Honor"].Value or 0
                if cur > lastBounty and lastBounty > 0 then
                    local inc = cur - lastBounty
                    sessionBountyEarned = sessionBountyEarned + inc
                    totalBountyEarned = totalBountyEarned + inc
                    allTimeKills = allTimeKills + 1
                    sendKillWebhook(currentTarget.Name, inc, cur)

                    saveEarnedData()
                end
                lastBounty = cur
            end
        end)
    end
end)

spawn(function()
    task.wait(3)
    pcall(function() lastBounty = player.leaderstats["Bounty/Honor"] and player.leaderstats["Bounty/Honor"].Value or 0 end)
end)

local lp = game.Players.LocalPlayer
local replicated = game:GetService("ReplicatedStorage")

function OutSafeZone()
    local success, val = pcall(function()
        local mainGui = lp.PlayerGui:FindFirstChild("Main")
        if mainGui then
            for _, v in ipairs(mainGui:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible then
                    local text = v.Text
                    if string.find(text, "Safe Zone") or string.find(text, "VĂ¹ng An toĂ n") then
                        return true
                    end
                end
            end
        end
        return false
    end)
    return success and val
end

-------------------------------------------------------------------------

local function hasValkyrieHelm()
    local success, inv = pcall(function()
        return replicated.Remotes.CommF_:InvokeServer("getInventory")
    end)
    
    if success and inv then
        for _, v in ipairs(inv) do
            if v.Name == "Valkyrie Helm" then
                return true
            end
        end
    end
    return false
end

task.spawn(function()
    while task.wait(0.5) do
        if OutSafeZone() then
            if hasValkyrieHelm() then
                replicated.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(5643.45263671875, 1013.0858154296875, -340.51025390625))
            end
            replicated.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923, 126, 32852))
        end
    end
end)


local function IsPvpOn(player)
    return player:GetAttribute("PvpDisabled") ~= true
end



local function CheckAndReset()
    if getgenv().Config and getgenv().Config["Reset"] == true then
        task.wait(0.3) 
        if not OutSafeZone() and IsPvpOn(LocalPlayer) then
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                if player.Character.Humanoid.Health > 0 then
                    player.Character.Humanoid.Health = 0
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do 
        CheckAndReset()
    end
end)

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	
	humanoid.Died:Connect(function()
		local hrp = character:WaitForChild("HumanoidRootPart")
		
		local connection
		connection = RunService.Heartbeat:Connect(function()
			if hrp and hrp.Parent then
				hrp.Anchored = true
			else
				connection:Disconnect()
			end
		end)
	end)
end)
notify("Meyy Hub", "Loaded successfully", 3)
