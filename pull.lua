-- Pull Lever | Temple of Time | Blox Fruits | Meyy Hub
-- Compat: Fluxus / Delta / Codex / Arceus X / Solara

repeat task.wait(1) until
    game:GetService("ReplicatedStorage") and
    game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and
    game.Players.LocalPlayer and
    game.Players.LocalPlayer.Character and
    game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
    not game.Players.LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen")

-- Services
local RS      = game:GetService("ReplicatedStorage")
local TS      = game:GetService("TweenService")
local Players = game:GetService("Players")
local HS      = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local LP      = Players.LocalPlayer
local Char    = LP.Character or LP.CharacterAdded:Wait()
local HRP     = Char:WaitForChild("HumanoidRootPart")
LP.CharacterAdded:Connect(function(c) Char = c; HRP = c:WaitForChild("HumanoidRootPart") end)

-- ─── Auto join team Marines (blocking — giống bigupcy.lua) ───────────────────
-- Gọi SetTeam liên tục cho đến khi character load xong
local CommF_ = RS:WaitForChild("Remotes"):WaitForChild("CommF_")
while not LP.Character
    or not LP.Character:FindFirstChild("HumanoidRootPart") do
    pcall(function()
        CommF_:InvokeServer("SetTeam", "Marines")
    end)
    task.wait(1)
end
-- Gọi thêm 1 lần sau khi character sẵn sàng để chắc chắn
pcall(function() CommF_:InvokeServer("SetTeam", "Marines") end)
task.wait(0.5)


-- ─── Config ───────────────────────────────────────────────────────────────────
local Config = {
    Remotes = { CommF = "CommF_", CommE = "CommE", ServerBrowser = "__ServerBrowser" },
    HopAPI  = { Mirage = "http://fi11.bot-hosting.net:20758/api/name=Mirage" },
    MaxHopCount   = 10,
    MaxHopPlayers = 10,
    HopWaitTime   = 25,
    Paths = {
        TempleOfTime = {"Map", "Temple of Time"},
        MysticIsland = {"Map", "MysticIsland"},
        InnerClock   = {"Map", "Temple of Time", "InnerClock"},
    },
    NPCs  = { RipIndra = "Rip_Indra", SealedKing = "Sealed King" },
    Items = { ValkyrieHelm = "Valkyrie Helm", MirrorFractal = "Mirror Fractal" },
    ScanKeywords = {"Lever","Temple","Mirage","Gear","Moon","Race","Ancient","InnerClock","Rip_Indra"},
    TweenSpeed = 350,
}

-- ─── Utils ────────────────────────────────────────────────────────────────────
local Utils = {}
local UILog -- forward ref for UI

local function _log(level, msg)
    local tags = { INFO="[INFO]", WARN="[WARN]", ERROR="[ERROR]", SUCCESS="[SUCCESS]" }
    local full = (tags[level] or "[LOG]") .. " " .. tostring(msg)
    if level == "ERROR" or level == "WARN" then warn(full) else print(full) end
    _G.PullLeverStatus = full
    if UILog then pcall(UILog, full) end
end
function Utils.Info(m)    _log("INFO",    m) end
function Utils.Warn(m)    _log("WARN",    m) end
function Utils.Error(m)   _log("ERROR",   m) end
function Utils.Success(m) _log("SUCCESS", m) end

function Utils.Try(fn, lbl)
    local ok, err = pcall(fn)
    if not ok then Utils.Warn((lbl or "Try") .. ": " .. tostring(err)) end
    return ok, err
end

function Utils.Retry(fn, max, delay, lbl)
    max = max or 5; delay = delay or 1
    for i = 1, max do
        local ok, r = pcall(fn)
        if ok and r then return r end
        Utils.Warn(string.format("Retry [%s] %d/%d", tostring(lbl), i, max))
        task.wait(delay)
    end
    return nil
end

function Utils.Invoke(...)
    local args = {...}
    local ok, r = pcall(function() return RS.Remotes.CommF_:InvokeServer(table.unpack(args)) end)
    if not ok then Utils.Warn("Invoke failed: " .. tostring(r)) end
    return ok and r or nil
end

function Utils.HasItem(name)
    return LP.Backpack:FindFirstChild(name) ~= nil
        or (LP.Character and LP.Character:FindFirstChild(name) ~= nil)
end

function Utils.IsAlive(m)
    if not m or not m.Parent then return false end
    local h = m:FindFirstChildWhichIsA("Humanoid")
    return h and h.Health > 0 and m:FindFirstChild("HumanoidRootPart") ~= nil
end

function Utils.WaitUntil(fn, timeout, interval)
    local t0 = tick(); interval = interval or 0.5; timeout = timeout or 30
    repeat task.wait(interval) until fn() or tick() - t0 >= timeout
    return fn()
end

-- ─── TweenMove ───────────────────────────────────────────────────────────────
local TweenMove = {}
do
    local block = Instance.new("Part")
    block.Name = "PLTweenBlock"; block.Size = Vector3.new(1,1,1)
    block.Anchored = true; block.CanCollide = false; block.CanTouch = false
    block.Transparency = 1; block.Parent = workspace

    local shouldTween = false
    local curTween    = nil

    task.spawn(function()
        while task.wait() do
            pcall(function()
                if shouldTween and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                    LP.Character.HumanoidRootPart.CFrame = block.CFrame
                    local head = LP.Character:FindFirstChild("Head")
                    if head and not head:FindFirstChild("PLAntiFall") then
                        local bv = Instance.new("BodyVelocity")
                        bv.Name = "PLAntiFall"; bv.MaxForce = Vector3.new(9e9,9e9,9e9)
                        bv.Velocity = Vector3.zero; bv.Parent = head
                    end
                    for _, p in ipairs(LP.Character:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
        end
    end)

    function TweenMove.TweenTo(cf)
        if not cf then return end
        if typeof(cf) == "Vector3" then cf = CFrame.new(cf) end
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp  = LP.Character.HumanoidRootPart
        local dist = (hrp.Position - cf.Position).Magnitude
        if dist < 2 then hrp.CFrame = cf; return end
        block.CFrame = hrp.CFrame
        shouldTween  = true
        local bv = hrp:FindFirstChild("PLTweenBV")
        if not bv then
            bv = Instance.new("BodyVelocity"); bv.Name = "PLTweenBV"
            bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
            bv.Velocity = Vector3.zero; bv.Parent = hrp
        end
        local speed = dist < 100 and 400 or Config.TweenSpeed
        local tw = TS:Create(block, TweenInfo.new(dist/speed, Enum.EasingStyle.Linear), {CFrame = cf})
        if curTween then pcall(function() curTween:Cancel() end) end
        curTween = tw; tw:Play(); tw.Completed:Wait()
        shouldTween = false
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = cf
        end
    end

    function TweenMove.SafeTweenTo(cf, timeout)
        timeout = timeout or 20
        task.spawn(function() TweenMove.TweenTo(cf) end)
        local t0 = tick()
        repeat
            task.wait(0.5)
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - cf.Position).Magnitude < 5 then return true end
        until tick() - t0 >= timeout
        Utils.Warn("SafeTweenTo: stuck, force TP")
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = cf
        end
        return false
    end

    function TweenMove.StopTween()
        shouldTween = false
        if curTween then pcall(function() curTween:Cancel() end) end
    end
end

-- ─── HopServer ───────────────────────────────────────────────────────────────
local HopServer = {}
do
    local hopFile  = "workspace/" .. LP.Name .. "_hop.json"
    local hopData  = { jobids = {}, count = 0 }
    local FailedJobs = {}

    local function LoadHop()
        pcall(function()
            if isfile(hopFile) then
                local d = HS:JSONDecode(readfile(hopFile))
                if type(d) == "table" then
                    hopData = d
                    hopData.jobids = hopData.jobids or {}
                    hopData.count  = hopData.count  or 0
                end
            end
        end)
    end

    local function SaveHop()
        pcall(function()
            if hopData.count >= Config.MaxHopCount then
                hopData = { jobids = {}, count = 0 }
            end
            writefile(hopFile, HS:JSONEncode(hopData))
        end)
    end

    local function Hopped(id)
        for _, v in ipairs(hopData.jobids) do if v == id then return true end end
        return false
    end

    local function RecordHop(id)
        table.insert(hopData.jobids, id)
        hopData.count = hopData.count + 1
        SaveHop()
    end

    LoadHop()

    function HopServer.Hop(filter, maxPlayers, waitTime)
        maxPlayers = maxPlayers or Config.MaxHopPlayers
        waitTime   = waitTime   or Config.HopWaitTime
        local url  = Config.HopAPI[filter]
        if not url then Utils.Error("No API for: " .. tostring(filter)); return false end

        Utils.Info("HopServer: looking for " .. filter)
        local ok, result = pcall(function()
            local body
            pcall(function() body = game:HttpGet(url) end)
            if not body then
                local req = (syn and syn.request) or (http and http.request) or request
                body = req and req({Url=url,Method="GET"}).Body
            end
            if not body then return false end

            local data = HS:JSONDecode(body)
            if not data or not data.success then return false end

            local list = data.data
            if type(list) == "table" and type(list.data) == "table" then list = list.data end
            if type(list) ~= "table" then return false end

            local pid = tostring(game.PlaceId)
            local seen, svs = {}, {}
            for _, e in ipairs(list) do
                if e.jobid and tostring(e.placeid) == pid and not seen[e.jobid] then
                    seen[e.jobid] = true
                    table.insert(svs, {jobid=e.jobid, players=tonumber(e.player) or 99})
                end
            end
            table.sort(svs, function(a,b) return a.players < b.players end)
            Utils.Info("HopServer: " .. #svs .. " servers found")

            for _, s in ipairs(svs) do
                if s.jobid == game.JobId then continue end
                if FailedJobs[s.jobid]   then continue end
                if Hopped(s.jobid)       then continue end
                if s.players >= maxPlayers then continue end
                local ok2 = pcall(function()
                    RS:WaitForChild("__ServerBrowser"):InvokeServer("teleport", s.jobid)
                end)
                if ok2 then RecordHop(s.jobid); task.wait(15); return true
                else FailedJobs[s.jobid] = tick(); task.wait(1) end
            end

            Utils.Info("HopServer: no server, waiting " .. waitTime .. "s")
            for i = waitTime, 1, -1 do task.wait(1) end
            return false
        end)
        return ok and result
    end

    function HopServer.HopPublic()
        pcall(function()
            local d = HS:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            )).data
            for _, s in ipairs(d) do
                if s.playing < Config.MaxHopPlayers and s.id ~= game.JobId and not Hopped(s.id) then
                    RS:WaitForChild("__ServerBrowser"):InvokeServer("teleport", s.id)
                    RecordHop(s.id); task.wait(10); return
                end
            end
        end)
    end
end

-- ─── Scanner ─────────────────────────────────────────────────────────────────
local Scanner = {}
do
    local function HasKW(name)
        local l = name:lower()
        for _, kw in ipairs(Config.ScanKeywords) do
            if l:find(kw:lower(), 1, true) then return true, kw end
        end
        return false, nil
    end

    function Scanner.DumpRemoteNames()
        print("=== DumpRemoteNames ===")
        local rem = RS:FindFirstChild("Remotes")
        if not rem then Utils.Warn("RS.Remotes not found"); return end
        for _, v in ipairs(rem:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                local hit, kw = HasKW(v.Name)
                print("  " .. v.Name .. " [" .. v.ClassName .. "]" .. (hit and " <- ["..kw.."]" or ""))
            end
        end
        print("=== End ===")
    end

    function Scanner.DumpTempleObjects()
        print("=== DumpTempleObjects ===")
        local t = workspace.Map and workspace.Map:FindFirstChild("Temple of Time")
        if not t then Utils.Warn("Temple not found"); return end
        for _, v in ipairs(t:GetDescendants()) do
            local hit, kw = HasKW(v.Name)
            if hit then print(string.format("  %s [%s] %s | %s", v.Name, v.ClassName, kw, v:GetFullName())) end
        end
        print("=== End ===")
    end

    function Scanner.ScanRaceObjects()
        print("=== ScanRaceObjects ===")
        for _, v in ipairs(workspace:GetDescendants()) do
            local hit, kw = HasKW(v.Name)
            if hit then print(string.format("  %s [%s] %s", v.Name, v.ClassName, kw)) end
        end
        print("=== End ===")
    end

    function Scanner.ScanGameFunctions()
        Scanner.DumpRemoteNames()
        Scanner.ScanRaceObjects()
    end

    function Scanner.SaveInstanceTree()
        local lines = {}
        local function rec(inst, d)
            table.insert(lines, string.rep("  ", d) .. inst.Name .. " [" .. inst.ClassName .. "]")
            if d >= 6 then return end
            for _, c in ipairs(inst:GetChildren()) do pcall(rec, c, d + 1) end
        end
        pcall(rec, workspace, 0)
        local fn = "workspace/" .. LP.Name .. "_tree.txt"
        writefile(fn, table.concat(lines, "\n"))
        Utils.Success("Tree saved: " .. fn)
    end

    function Scanner.CheckPatch()
        local issues = 0
        local function chk(path, lbl)
            local ok = pcall(function()
                local cur = RS
                for _, k in ipairs(path) do
                    cur = cur:FindFirstChild(k)
                    if not cur then error("missing") end
                end
            end)
            if ok then Utils.Info("OK : " .. lbl)
            else Utils.Warn("MISS: " .. lbl); issues = issues + 1 end
        end
        chk({"Remotes","CommF_"}, "CommF_")
        chk({"Remotes","CommE"},  "CommE")
        chk({"Remotes","__ServerBrowser"}, "__ServerBrowser")
        if issues == 0 then Utils.Success("CheckPatch: all OK")
        else Utils.Error("CheckPatch: " .. issues .. " issue(s)") end
        return issues == 0
    end
end

-- ─── Conditions (via Sealed King / RaceV4Progress state) ─────────────────────
-- RaceV4Progress Check states:
--   1 = Rip_Indra not killed (Sealed King: "Here lies king Red Head...")
--   2 = Rip_Indra killed, needs to go to Temple (Sealed King: "Please head to the Great Tree...")
--   3 = Entered Temple entrance (Sealed King: "Ah, so it was the Temple of Time...")
--   4 = Quest complete / lever pulled
local Cond = {}
do
    local function GetV4State()
        local s = Utils.Invoke("RaceV4Progress", "Check")
        return type(s) == "number" and s or 0
    end

    function Cond.HasValkyrieHelm()
        if Utils.HasItem(Config.Items.ValkyrieHelm) then return true end
        local inv = Utils.Invoke("getInventory")
        if type(inv) == "table" then
            for _, v in pairs(inv) do
                if v.Name == Config.Items.ValkyrieHelm then return true end
            end
        end
        return false
    end

    function Cond.HasMirrorFractal()
        if Utils.HasItem(Config.Items.MirrorFractal) then return true end
        local inv = Utils.Invoke("getInventory")
        if type(inv) == "table" then
            for _, v in pairs(inv) do
                if v.Name == Config.Items.MirrorFractal then return true end
            end
        end
        return false
    end

    -- Sealed King dialogue state >= 2: Rip_Indra killed
    function Cond.HasKilledRipIndra()
        return GetV4State() >= 2
    end

    -- Sealed King dialogue state >= 3: entered Temple entrance
    function Cond.HasTempleAccess()
        if GetV4State() >= 3 then return true end
        local temple = workspace.Map and workspace.Map:FindFirstChild("Temple of Time")
        if not temple then return false end
        local border = temple:FindFirstChild("FFABorder")
        if border then
            local ff = border:FindFirstChild("Forcefield")
            if ff and ff.Transparency == 1 then return true end
        end
        return false
    end

    -- Pulled lever = CheckTempleDoor truthy OR state == 4
    function Cond.HasPulledLever()
        local door = Utils.Invoke("CheckTempleDoor")
        if door then return true end
        return GetV4State() == 4
    end

    -- Gear collected = TempleClock shows at least 1 gear completed
    function Cond.HasGear()
        local dt = Utils.Invoke("TempleClock", "Check")
        return type(dt) == "table"
            and type(dt.RaceDetails) == "table"
            and (dt.RaceDetails.Completed or 0) > 0
    end

    function Cond.GetV4State() return GetV4State() end

    function Cond.PrintAll()
        Utils.Info("──── Conditions ────")
        Utils.Info("V4State         : " .. tostring(Cond.GetV4State()))
        Utils.Info("ValkyrieHelm    : " .. tostring(Cond.HasValkyrieHelm()))
        Utils.Info("MirrorFractal   : " .. tostring(Cond.HasMirrorFractal()))
        Utils.Info("KilledRipIndra  : " .. tostring(Cond.HasKilledRipIndra()))
        Utils.Info("TempleAccess    : " .. tostring(Cond.HasTempleAccess()))
        Utils.Info("HasGear         : " .. tostring(Cond.HasGear()))
        Utils.Info("PulledLever     : " .. tostring(Cond.HasPulledLever()))
        Utils.Info("────────────────────")
    end
end

-- ─── Temple ───────────────────────────────────────────────────────────────────
local Temple = {}
do
    local TEMPLE_POS = Vector3.new(28310.0234, 14895.1123, 109.456741)

    function Temple.TeleportToTemple()
        Utils.Info("Temple: TP to Temple of Time")
        pcall(function() Utils.Invoke("RaceV4Progress", "Teleport") end)
        task.wait(1)
        TweenMove.SafeTweenTo(CFrame.new(TEMPLE_POS), 20)
    end

    function Temple.EnterCorridor()
        Utils.Info("Temple: entering corridor")
        local race = pcall(function() return LP.Data.Race.Value end) and LP.Data.Race.Value
        if not race then Utils.Error("Cannot get race"); return false end
        local ok, door = pcall(function()
            return workspace.Map["Temple of Time"]
                :WaitForChild(race .. "Corridor", 10)
                :WaitForChild("Door", 10)
                :WaitForChild("Entrance", 10)
        end)
        if ok and door then
            TweenMove.SafeTweenTo(door.CFrame, 15)
            return true
        end
        Utils.Warn("Temple: corridor not found for " .. tostring(race))
        return false
    end

    function Temple.EnsureInWorkspace()
        if workspace.Map:FindFirstChild("Temple of Time") then return true end
        Utils.Warn("Temple: not in workspace, checking MapStash")
        local stash = RS:FindFirstChild("MapStash")
        if stash then
            local t = stash:FindFirstChild("Temple of Time")
            if t then t.Parent = workspace.Map; return true end
        end
        Utils.Error("Temple of Time not found anywhere")
        return false
    end

    function Temple.FindLever()
        local temple = workspace.Map:FindFirstChild("Temple of Time")
        if not temple then return nil end
        for _, v in ipairs(temple:GetDescendants()) do
            if v.Name:lower():find("lever") and (v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Model")) then
                return v
            end
        end
        return nil
    end

    function Temple.InteractLever(lever)
        if not lever then Utils.Error("No lever"); return false end
        local cf = lever:IsA("Model") and lever:GetPivot() or lever.CFrame
        if cf then TweenMove.SafeTweenTo(cf * CFrame.new(0, 0, 3), 10); task.wait(0.5) end

        local function tryPP(obj)
            for _, d in ipairs(obj:GetDescendants()) do
                if d:IsA("ProximityPrompt") then fireproximityprompt(d); return true end
            end
            if obj.Parent then
                for _, d in ipairs(obj.Parent:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then fireproximityprompt(d); return true end
                end
            end
            return false
        end

        if tryPP(lever) then task.wait(2); return true end

        for _, name in ipairs({"PullLever","TempleSwitch","LeverPull","ActivateLever","InteractLever"}) do
            local rem = RS.Remotes:FindFirstChild(name)
            if rem then pcall(function() rem:FireServer() end); task.wait(2); return Cond.HasPulledLever() end
        end

        for _, action in ipairs({"PullLever","TempleSwitch","LeverActivate"}) do
            local r = Utils.Invoke(action)
            if r then task.wait(2); if Cond.HasPulledLever() then return true end end
        end

        Utils.Error("Cannot interact lever — run Scanner.DumpTempleObjects() to debug")
        return false
    end

    function Temple.PullLever()
        Utils.Info("Temple: PullLever sequence")
        if not Temple.EnsureInWorkspace() then return false end
        Temple.TeleportToTemple(); task.wait(2)
        Temple.EnterCorridor(); task.wait(1)
        local lever = Utils.Retry(Temple.FindLever, 5, 2, "FindLever")
        if not lever then Utils.Error("Lever not found"); return false end
        local ok = Temple.InteractLever(lever)
        if ok then task.wait(1); return Cond.HasPulledLever() end
        return false
    end
end

-- ─── Mirage ───────────────────────────────────────────────────────────────────
local Mirage = {}
do
    -- Tiki Island bypass TP position (Sea 3) — rút ngắn tween đến Mirage
    local TIKI_POS    = CFrame.new(-1335.5, 148.8, 506.2)
    -- Fallback center nếu không detect được pivot
    local MIRAGE_FB   = CFrame.new(-1616.5, 148, -372.5)

    local UIS = game:GetService("UserInputService")
    local VIM = game:GetService("VirtualInputManager")

    -- ── Helpers ──────────────────────────────────────────────────────────────
    local function IsNight()
        local t = Lighting.ClockTime; return t >= 18 or t < 6
    end
    local function IsFullMoon()
        return Lighting:GetAttribute("MoonPhase") == 5
    end
    local function MoonDir()
        -- hướng mặt trăng từ vị trí Sky
        local sky = Lighting:FindFirstChildWhichIsA("Sky")
        if sky then
            local moon = sky:GetAttribute("MoonDirection")
            if moon and typeof(moon) == "Vector3" then return moon end
        end
        -- fallback: trăng thường ở hướng bắc - trên
        return Vector3.new(0, 0.7, -1).Unit
    end

    -- ── ESP label (Billboard) ─────────────────────────────────────────────────
    local espBillboard = nil
    local function ShowESP(part, label, color)
        pcall(function()
            if espBillboard then espBillboard:Destroy() end
            local bb = Instance.new("BillboardGui")
            bb.Name = "PLMirageESP"
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 160, 0, 30)
            bb.StudsOffset = Vector3.new(0, 6, 0)
            bb.Adornee = part
            local lbl = Instance.new("TextLabel", bb)
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 0.4
            lbl.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
            lbl.TextColor3 = color or Color3.fromRGB(100, 200, 255)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 14
            lbl.Text = label or "⬡ Mirage"
            bb.Parent = LP.PlayerGui
            espBillboard = bb
        end)
    end
    local function HideESP()
        pcall(function() if espBillboard then espBillboard:Destroy(); espBillboard = nil end end)
    end

    -- ── Detect Mirage Island ──────────────────────────────────────────────────
    function Mirage.Detect()
        local map = workspace:FindFirstChild("Map")
        if map then
            local mi = map:FindFirstChild("MysticIsland")
            if mi then return mi end
            for _, v in ipairs(map:GetChildren()) do
                if v.Name:lower():find("mirage") then return v end
            end
        end
        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name:lower():find("mirage") or v.Name:lower():find("mystic") then return v end
        end
        return nil
    end

    -- ── Get island center CFrame ──────────────────────────────────────────────
    local function GetIslandCenter(obj)
        if not obj then return MIRAGE_FB end
        local ok, piv = pcall(function() return obj:GetPivot() end)
        if ok and piv then return piv end
        for _, v in ipairs(obj:GetDescendants()) do
            if v:IsA("BasePart") then return v.CFrame end
        end
        return MIRAGE_FB
    end

    -- ── BypassTP → Tiki Island → rút ngắn tween ──────────────────────────────
    local function BypassToTiki()
        Utils.Info("Mirage: BypassTP → Tiki Island")
        -- dùng TeleportToSpawn rồi warp tới Tiki trước
        pcall(function()
            if LP:GetAttribute("ExactLocation") == "Submerged Island" then
                RS.Remotes.CommF_:InvokeServer("TeleportToSpawn"); task.wait(6)
            end
        end)
        -- Snap thẳng đến Tiki (bypass kiểm tra server)
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = TIKI_POS
        end
        task.wait(1.5)
    end

    -- ── Camera lock vào trăng ─────────────────────────────────────────────────
    local camLock = false
    local function LockCameraToMoon()
        Utils.Info("Mirage: Locking camera to moon")
        camLock = true
        local cam = workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Scriptable
        task.spawn(function()
            while camLock do
                pcall(function()
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local moonDir = MoonDir()
                        local eyePos  = hrp.Position + Vector3.new(0, 2, 0)
                        local lookAt  = eyePos + moonDir * 1000
                        cam.CFrame    = CFrame.new(eyePos, lookAt)
                    end
                end)
                task.wait(0.1)
            end
            cam.CameraType = Enum.CameraType.Custom
        end)
    end
    local function UnlockCamera()
        camLock = false
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
    end

    -- ── Tìm Blue Gear ─────────────────────────────────────────────────────────
    local function FindGear(islandObj)
        local root = islandObj
            or (workspace.Map and workspace.Map:FindFirstChild("MysticIsland"))
            or workspace
        -- Blue Gear mesh ID
        for _, v in ipairs(root:GetDescendants()) do
            if v:IsA("MeshPart") and v.MeshId:find("10153114969") then return v end
        end
        -- fallback by name
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name:lower():find("gear") and v:IsA("BasePart") then return v end
        end
        return nil
    end

    -- ── Nhặt Gear ─────────────────────────────────────────────────────────────
    local function PickupGear(gear)
        if not gear or not gear.Parent then return false end
        Utils.Info("Mirage: ESP Blue Gear → tweening")
        ShowESP(gear, "🔵 Blue Gear", Color3.fromRGB(80, 160, 255))
        TweenMove.SafeTweenTo(gear.CFrame * CFrame.new(0, 1.5, 0), 10)
        task.wait(0.5)
        local picked = false
        pcall(function()
            for _, v in ipairs(gear:GetDescendants()) do
                if v:IsA("ProximityPrompt") then fireproximityprompt(v); picked = true; break end
            end
            if not picked and gear.Parent then
                for _, v in ipairs(gear.Parent:GetDescendants()) do
                    if v:IsA("ProximityPrompt") then fireproximityprompt(v); picked = true; break end
                end
            end
        end)
        if not picked then
            -- fallback: snap đến gear
            if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                LP.Character.HumanoidRootPart.CFrame = gear.CFrame
            end
            task.wait(0.5)
        end
        HideESP()
        task.wait(2)
        return Cond.HasGear()
    end

    -- ── Wait resonance (khi camera nhìn trăng) ───────────────────────────────
    local function WaitResonance()
        Utils.Info("Mirage: waiting for resonance...")
        local done = false
        local conn = LP.PlayerGui.DescendantAdded:Connect(function(obj)
            if (obj:IsA("TextLabel") or obj:IsA("TextButton"))
                and tostring(obj.Text):lower():find("resonat") then
                done = true
            end
        end)
        local t0 = tick()
        repeat
            task.wait(1)
            for _, v in ipairs(LP.PlayerGui:GetDescendants()) do
                if v:IsA("TextLabel") and tostring(v.Text):lower():find("resonat") then
                    done = true; break
                end
            end
        until done or tick() - t0 >= 90
        pcall(function() conn:Disconnect() end)
        if not done then Utils.Warn("Mirage: resonance timeout") end
        return done
    end

    -- ── Main Run ──────────────────────────────────────────────────────────────
    function Mirage.Run(island)
        Utils.Info("Mirage: Run() start")
        local obj = island or Mirage.Detect()
        if not obj then Utils.Error("Mirage: island not found"); return false end

        local center = GetIslandCenter(obj)

        -- 1. BypassTP đến Tiki Island để rút ngắn tween
        BypassToTiki()

        -- 2. ESP island + Tween đến trung tâm đảo (speed 350 như autocy)
        ShowESP(
            obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart"),
            "🏝 Mirage Island",
            Color3.fromRGB(100, 255, 180)
        )
        Utils.Info("Mirage: Tweening to island center")
        TweenMove.SafeTweenTo(center, 40)
        task.wait(1)

        -- 3. Đứng ở giữa đảo — chờ trời tối + trăng tròn
        UI.SetStatus("Waiting for night...")
        Utils.Info("Mirage: Waiting for night + full moon")
        local t0 = tick()
        while not IsNight() or not IsFullMoon() do
            task.wait(3)
            -- kiểm tra đảo còn tồn tại không
            if not obj or not obj.Parent then
                HideESP(); UnlockCamera()
                Utils.Warn("Mirage: Island disappeared!"); return false
            end
            -- giữ vị trí trung tâm đảo
            if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LP.Character.HumanoidRootPart.Position - center.Position).Magnitude
                if dist > 20 then
                    LP.Character.HumanoidRootPart.CFrame = center
                end
            end
            Utils.Info(string.format("Mirage: clock=%.1f moon=%s",
                Lighting.ClockTime, tostring(Lighting:GetAttribute("MoonPhase"))))
        end
        Utils.Success("Mirage: Night + Full Moon!")

        -- 4. Lock camera vào trăng
        UI.SetStatus("Locking camera to moon...")
        LockCameraToMoon()
        task.wait(1)

        -- 5. Chờ resonance
        UI.SetStatus("Waiting resonance...")
        WaitResonance()
        task.wait(1)

        -- 6. Chờ đến khi sáng (Gear xuất hiện sau resonance lúc sáng)
        Utils.Info("Mirage: Waiting for daylight to find gear")
        local gearWait = tick()
        local gear = nil
        repeat
            task.wait(2)
            gear = FindGear(obj)
            if not obj or not obj.Parent then
                UnlockCamera(); HideESP()
                Utils.Warn("Mirage: Island lost while waiting for gear"); return false
            end
        until gear or tick() - gearWait >= 120

        UnlockCamera()

        if not gear then
            Utils.Warn("Mirage: Gear not found after 120s"); return false
        end

        -- 7. Nhặt Blue Gear
        UI.SetStatus("Picking up Blue Gear...")
        local picked = PickupGear(gear)
        if picked then
            Utils.Success("Mirage: Gear collected!")
            return true
        end

        -- Fallback: SpendPoint nếu game track internal
        local dt = Utils.Invoke("TempleClock", "Check")
        if dt and dt.HadPoint then
            Utils.Invoke("TempleClock", "SpendPoint",
                "Gear" .. tostring(dt.RaceDetails and dt.RaceDetails.Completed or 1), "Alpha")
            task.wait(1)
            if Cond.HasGear() then Utils.Success("Mirage: Gear via SpendPoint!"); return true end
        end
        return false
    end
end

-- ─── UI ───────────────────────────────────────────────────────────────────────
local UI = {}
local CondLabels = {}
local StatusLabel = nil

do
    pcall(function()
        local old = LP.PlayerGui:FindFirstChild("PullLeverUI")
        if old then old:Destroy() end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "PullLeverUI"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP.PlayerGui

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Position = UDim2.new(0, 10, 0.5, -80)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BorderSizePixel  = 0; frame.Parent = sg
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28); title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(10, 10, 14); title.BorderSizePixel = 0
    title.Text = "Pull Lever | Mtr Chill"; title.TextColor3 = Color3.fromRGB(180, 130, 255)
    title.Font = Enum.Font.GothamSemibold; title.TextSize = 13; title.Parent = frame
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 8); tc.Parent = title

    local y = 34
    local function makeRow(text, color)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -12, 0, 22)
        lbl.Position = UDim2.new(0, 6, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = text; lbl.TextColor3 = color or Color3.fromRGB(220, 220, 220)
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame; y = y + 26
        return lbl
    end

    local condDefs = {
        { "Valkyrie Helm",  Cond.HasValkyrieHelm },
        { "Mirror Fractal", Cond.HasMirrorFractal },
        { "Mirage Island",  Mirage.Detect },
        { "Pull Lever",     Cond.HasPulledLever },
    }
    for _, def in ipairs(condDefs) do
        local lbl = makeRow("⬜  " .. def[1], Color3.fromRGB(200, 200, 200))
        CondLabels[def[1]] = { label = lbl, fn = def[2] }
    end

    y = y + 4
    StatusLabel = makeRow("idle", Color3.fromRGB(255, 200, 80))

    frame.Size = UDim2.new(0, 220, 0, y + 8)

    local dragging, dragStart, startPos = false, nil, nil
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    task.spawn(function()
        while task.wait(1) do
            for name, def in pairs(CondLabels) do
                local ok, val = pcall(def.fn)
                local v = ok and val
                def.label.Text = (v and "✅" or "❌") .. " " .. name
                def.label.TextColor3 = v and Color3.fromRGB(100, 255, 120) or Color3.fromRGB(255, 100, 100)
            end
            if StatusLabel and _G.PullLeverStatus then
                StatusLabel.Text = _G.PullLeverStatus:sub(1, 60)
            end
        end
    end)

    UI.SetStatus = function(msg)
        _G.PullLeverStatus = msg
        pcall(function() StatusLabel.Text = "Status: " .. msg end)
    end
end

-- ─── Main ─────────────────────────────────────────────────────────────────────
function Main()
    getgenv().PLStop = false
    Utils.Info("=== Pull Lever START | " .. LP.Name .. " ===")
    Cond.PrintAll()

    if Cond.HasPulledLever() then
        Utils.Success("Lever already pulled!"); UI.SetStatus("Done - Lever pulled"); return
    end

    if not Cond.HasValkyrieHelm() then
        Utils.Error("Missing: Valkyrie Helm"); UI.SetStatus("ERROR: Need Valkyrie Helm"); return
    end
    if not Cond.HasMirrorFractal() then
        Utils.Error("Missing: Mirror Fractal"); UI.SetStatus("ERROR: Need Mirror Fractal"); return
    end

    -- Sealed King state check
    local state = Cond.GetV4State()
    Utils.Info("V4 State: " .. state)

    -- state 1: Rip_Indra not killed
    if not Cond.HasKilledRipIndra() then
        Utils.Error("Rip_Indra not killed yet (state=" .. state .. ")")
        UI.SetStatus("ERROR: Kill Rip_Indra first"); return
    end

    -- state 2: Need to go to Temple
    if not Cond.HasTempleAccess() then
        Utils.Info("Entering Temple entrance (state=" .. state .. ")")
        UI.SetStatus("Going to Temple...")
        Temple.TeleportToTemple(); task.wait(3)
        Temple.EnterCorridor(); task.wait(2)
        Cond.PrintAll()
    end

    -- Already have gear → skip Mirage
    if Cond.HasGear() then
        Utils.Info("Gear found → pulling lever")
        UI.SetStatus("Pulling lever...")
        local ok = Temple.PullLever()
        if ok then
            Utils.Success("LEVER PULLED!")
            UI.SetStatus("SUCCESS: Lever pulled!")
        else
            Utils.Error("PullLever failed")
            UI.SetStatus("ERROR: PullLever failed")
        end
        return
    end

    -- Need Mirage → hop loop
    Utils.Info("Need Gear → searching Mirage Island")
    local attempt = 0
    while attempt < 20 and not getgenv().PLStop do
        attempt = attempt + 1
        UI.SetStatus("Mirage attempt " .. attempt)
        Utils.Info("Attempt " .. attempt .. "/20")

        if not Cond.HasValkyrieHelm() or not Cond.HasMirrorFractal() then
            Utils.Error("Items missing after hop"); UI.SetStatus("ERROR: Items missing"); return
        end

        local mi = Mirage.Detect()
        if not mi then
            Utils.Info("No Mirage, hopping...")
            UI.SetStatus("Hopping for Mirage...")
            if not HopServer.Hop("Mirage") then HopServer.HopPublic() end
            task.wait(5)
        else
            Utils.Success("Mirage found: " .. mi.Name)
            -- truyền obj vào Mirage.Run để dùng lại luôn
            local gearOk = Mirage.Run(mi)

            -- nếu Run() fail do mất đảo → hop tìm server mới
            if not gearOk then
                local stillHere = Mirage.Detect()
                if not stillHere then
                    Utils.Warn("Island lost → hopping for new Mirage server")
                    UI.SetStatus("Island lost, hopping...")
                    if not HopServer.Hop("Mirage") then HopServer.HopPublic() end
                    task.wait(5)
                else
                    Utils.Warn("Gear failed (island still here), retry")
                    task.wait(3)
                end
            elseif Cond.HasGear() then
                task.wait(2)
                UI.SetStatus("Pulling lever...")
                local ok = Temple.PullLever()
                if ok then
                    -- Verify server-side
                    task.wait(2)
                    local confirmed = Utils.Retry(Cond.HasPulledLever, 5, 1, "VerifyLever")
                    if confirmed then
                        Utils.Success("LEVER PULLED & VERIFIED!")
                        UI.SetStatus("SUCCESS: Lever pulled!")
                    else
                        Utils.Warn("Pull reported OK but server not confirmed yet")
                        UI.SetStatus("Lever pulled (unverified)")
                    end
                    return
                else
                    Utils.Error("PullLever failed after Mirage")
                end
            end
        end
    end

    Utils.Error("Max attempts reached")
    UI.SetStatus("ERROR: Max attempts reached")
end

-- ─── Expose globals ──────────────────────────────────────────────────────────
_G.PullLever = {
    HasValkyrieHelm   = Cond.HasValkyrieHelm,
    HasMirrorFractal  = Cond.HasMirrorFractal,
    HasTempleAccess   = Cond.HasTempleAccess,
    HasKilledRipIndra = Cond.HasKilledRipIndra,
    HasPulledLever    = Cond.HasPulledLever,
    HasGear           = Cond.HasGear,
    PrintConditions   = Cond.PrintAll,
    ScanGameFunctions = Scanner.ScanGameFunctions,
    DumpRemoteNames   = Scanner.DumpRemoteNames,
    DumpTempleObjects = Scanner.DumpTempleObjects,
    ScanRaceObjects   = Scanner.ScanRaceObjects,
    CheckPatch        = Scanner.CheckPatch,
    SaveInstanceTree  = Scanner.SaveInstanceTree,
    TeleportToTemple  = Temple.TeleportToTemple,
    EnterCorridor     = Temple.EnterCorridor,
    PullLever         = Temple.PullLever,
    RunMirage         = Mirage.Run,
    HopServer         = HopServer.Hop,
    Log               = Utils.Info,
}

Utils.Info("Ready. UI visible. _G.PullLever exposed.")
Utils.Info("Click [RUN] in the UI or call Main() to start.")
