--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║           PULL LEVER - TEMPLE OF TIME AUTOMATION                ║
    ║           Blox Fruits | Sea 3 | Race V4 Series                  ║
    ║           Author  : Meyy Hub                                    ║
    ║           Version : 1.0.0                                       ║
    ║           Compat  : Fluxus / Delta / Codex / Arceus X / Solara  ║
    ╚══════════════════════════════════════════════════════════════════╝

    MODULES:
      - Utils       : Logger, TweenTo, SafeInvoke, Retry ...
      - Conditions  : HasValkyrieHelm, HasMirrorFractal, HasPulledLever,
                      HasGear, HasKilledRipIndra, HasTempleAccess
      - HopServer   : Per-account hop file, anti-duplicate
      - Scanner     : ScanGameFunctions / DumpRemoteNames / DumpTempleObjects
      - Temple      : EnterTemple, PullLever logic
      - Mirage      : DetectMirage, WaitNight, AlignMoon, PickupGear
      - Main        : Orchestrator loop
]]

-- ─────────────────────────────────────────────────────────────────────────────
-- SAFETY GUARD: make sure game is loaded before doing anything
-- ─────────────────────────────────────────────────────────────────────────────
repeat task.wait(1) until
    game:GetService("ReplicatedStorage") and
    game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and
    game.Players and
    game.Players.LocalPlayer and
    game.Players.LocalPlayer.Character and
    game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
    not game.Players.LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen")

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────────────────────────────
local RS          = game:GetService("ReplicatedStorage")
local TS          = game:GetService("TweenService")
local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting    = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local RunService  = game:GetService("RunService")

local LP          = Players.LocalPlayer
local Char        = LP.Character or LP.CharacterAdded:Wait()
local HRP         = Char:WaitForChild("HumanoidRootPart")

-- Rebind on respawn
LP.CharacterAdded:Connect(function(c)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart")
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- CONFIG  (change when game updates → only edit here)
-- ─────────────────────────────────────────────────────────────────────────────
local Config = {
    -- ── Remote names ──────────────────────────────────────────────
    Remotes = {
        CommF           = "CommF_",
        CommE           = "CommE",
        ServerBrowser   = "__ServerBrowser",
    },

    -- ── Server-hop API (nested data.data format) ──────────────────
    -- Response format: { success=true, data={ count=N, data=[{jobid,placeid,player}] } }
    HopAPI = {
        Mirage = "http://fi11.bot-hosting.net:20758/api/name=Mirage",
        -- add more filters here if needed
    },

    MaxHopCount    = 10,     -- reset hop file after N hops
    MaxHopPlayers  = 10,     -- skip servers with >= this many players
    HopWaitTime    = 25,     -- seconds to wait when no server found

    -- ── Object paths (update here when game patches) ───────────────
    Paths = {
        TempleOfTime = {"Map", "Temple of Time"},
        MysticIsland = {"Map", "MysticIsland"},
        InnerClock   = {"Map", "Temple of Time", "InnerClock"},
        LeverFolder  = {"Map", "Temple of Time"},       -- lever is inside here
        Enemies      = {"Enemies"},
        Characters   = {"Characters"},
    },

    -- ── NPC / mob names ────────────────────────────────────────────
    NPCs = {
        RipIndra = "Rip_Indra",
    },

    -- ── Item names ─────────────────────────────────────────────────
    Items = {
        ValkyrieHelm  = "Valkyrie Helm",
        MirrorFractal = "Mirror Fractal",
    },

    -- ── Known lever/gear keywords for scanner ─────────────────────
    ScanKeywords = {
        "Lever", "Temple", "Mirage", "Gear", "Moon",
        "Race", "Ancient", "InnerClock", "Rip_Indra",
    },

    -- ── Tween speed (studs/s) ─────────────────────────────────────
    TweenSpeed = 350,

    -- ── Debug ─────────────────────────────────────────────────────
    DebugMode = true,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- MODULE: Utils
-- ─────────────────────────────────────────────────────────────────────────────
local Utils = {}

do
    -- Status label (printed + stored in _G)
    local function _tag(level)
        local tags = {INFO="[INFO]", WARN="[WARN]", ERROR="[ERROR]", SUCCESS="[SUCCESS]"}
        return tags[level] or "[LOG]"
    end

    function Utils.Log(level, msg)
        local tag = _tag(level)
        local full = string.format("%s [PullLever] %s", tag, tostring(msg))
        if level == "ERROR" then
            warn(full)
        elseif level == "WARN" then
            warn(full)
        else
            print(full)
        end
        _G.PullLeverStatus = full
    end

    function Utils.Info(m)    Utils.Log("INFO",    m) end
    function Utils.Warn(m)    Utils.Log("WARN",    m) end
    function Utils.Error(m)   Utils.Log("ERROR",   m) end
    function Utils.Success(m) Utils.Log("SUCCESS", m) end

    -- Safe pcall wrapper with optional log
    function Utils.Try(fn, label)
        local ok, err = pcall(fn)
        if not ok and Config.DebugMode then
            Utils.Warn((label or "Try") .. " failed: " .. tostring(err))
        end
        return ok, err
    end

    -- Retry a function up to `maxAttempts` times with `delay` between attempts
    function Utils.Retry(fn, maxAttempts, delay, label)
        maxAttempts = maxAttempts or 5
        delay       = delay or 1
        for i = 1, maxAttempts do
            local ok, result = pcall(fn)
            if ok and result then return result end
            if Config.DebugMode then
                Utils.Warn(string.format("Retry [%s] %d/%d failed", tostring(label), i, maxAttempts))
            end
            task.wait(delay)
        end
        return nil
    end

    -- Safe invoke CommF_
    function Utils.Invoke(...)
        local args = {...}
        local ok, result = pcall(function()
            return RS.Remotes[Config.Remotes.CommF]:InvokeServer(table.unpack(args))
        end)
        if not ok and Config.DebugMode then
            Utils.Warn("Invoke failed: " .. tostring(result))
        end
        return ok and result or nil
    end

    -- Check backpack + equipped
    function Utils.HasItem(name)
        return  LP.Backpack:FindFirstChild(name) ~= nil
             or (LP.Character and LP.Character:FindFirstChild(name) ~= nil)
    end

    -- Distance between two CFrames/Instances
    function Utils.Dist(a, b)
        local function pos(x)
            if typeof(x) == "CFrame"   then return x.Position
            elseif typeof(x) == "Vector3" then return x
            elseif typeof(x) == "Instance" and x:IsA("BasePart") then return x.Position
            elseif typeof(x) == "Instance" and x:FindFirstChild("HumanoidRootPart") then return x.HumanoidRootPart.Position
            end
            return Vector3.zero
        end
        return (pos(a) - pos(b)).Magnitude
    end

    -- Humanoid check
    function Utils.IsAlive(model)
        if not model or not model.Parent then return false end
        local h = model:FindFirstChildWhichIsA("Humanoid")
        return h and h.Health > 0 and model:FindFirstChild("HumanoidRootPart") ~= nil
    end

    -- Timeout wait: call fn() repeatedly until it returns truthy or timeout
    function Utils.WaitUntil(fn, timeout, interval, label)
        timeout  = timeout  or 30
        interval = interval or 0.5
        local t0 = tick()
        repeat
            task.wait(interval)
            if fn() then return true end
        until tick() - t0 >= timeout
        if Config.DebugMode then
            Utils.Warn("WaitUntil timeout: " .. tostring(label))
        end
        return false
    end

    -- Navigate to path in workspace hierarchy
    function Utils.GetPath(root, pathTable)
        local cur = root
        for _, key in ipairs(pathTable) do
            if not cur then return nil end
            cur = cur:FindFirstChild(key)
        end
        return cur
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MODULE: TweenMovement  (adapted from KaitunV4 + KaitunGhoul patterns)
-- ─────────────────────────────────────────────────────────────────────────────
local TweenMove = {}

do
    -- Internal block used to lock character position during tween
    local block = Instance.new("Part")
    block.Name        = "PullLeverTweenBlock"
    block.Size        = Vector3.new(1, 1, 1)
    block.Anchored    = true
    block.CanCollide  = false
    block.CanTouch    = false
    block.Transparency = 1
    block.Parent      = workspace

    local shouldTween = false
    local currentTween = nil

    -- Background loop: keep character glued to block while tweening
    task.spawn(function()
        while task.wait() do
            Utils.Try(function()
                if shouldTween and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp  = LP.Character.HumanoidRootPart
                    hrp.CFrame = block.CFrame
                    -- Anti-fall
                    local head = LP.Character:FindFirstChild("Head")
                    if head and not head:FindFirstChild("PLAntiFall") then
                        local bv = Instance.new("BodyVelocity")
                        bv.Name      = "PLAntiFall"
                        bv.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
                        bv.Velocity  = Vector3.zero
                        bv.Parent    = head
                    end
                    -- NoCollide
                    for _, p in ipairs(LP.Character:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end, "TweenLoop")
        end
    end)

    -- Tween HRP (or any BasePart) to target CFrame
    function TweenMove.TweenObject(Object, TargetCF, Speed)
        if not Object or not TargetCF then return end
        Speed = Speed or Config.TweenSpeed
        local dist = (TargetCF.Position - Object.Position).Magnitude
        if dist < 0.5 then return end
        local info  = TweenInfo.new(dist / Speed, Enum.EasingStyle.Linear)
        local tw    = TS:Create(Object, info, {CFrame = TargetCF})
        if currentTween then pcall(function() currentTween:Cancel() end) end
        currentTween = tw
        tw:Play()
    end

    -- Primary movement: tween character to a target CFrame
    function TweenMove.TweenTo(TargetCF)
        if not TargetCF then return end
        if typeof(TargetCF) == "Vector3" then
            TargetCF = CFrame.new(TargetCF)
        end
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end

        -- If stuck underwater, teleport to spawn first (same as KaitunGhoul)
        Utils.Try(function()
            if LP:GetAttribute("ExactLocation") == "Submerged Island" then
                RS.Remotes[Config.Remotes.CommF]:InvokeServer("TeleportToSpawn")
                task.wait(6)
            end
        end, "SubmergedCheck")

        local hrp = LP.Character.HumanoidRootPart
        block.CFrame = hrp.CFrame
        shouldTween  = true

        -- Add BodyVelocity to HRP to keep it from drifting
        local bv = hrp:FindFirstChild("PLTweenBV")
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name      = "PLTweenBV"
            bv.MaxForce  = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity  = Vector3.zero
            bv.Parent    = hrp
        end

        local dist = (hrp.Position - TargetCF.Position).Magnitude
        if dist < 2 then
            hrp.CFrame  = TargetCF
            shouldTween = false
            return
        end

        local speed = dist < 100 and 400 or Config.TweenSpeed
        local info  = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
        local tw    = TS:Create(block, info, {CFrame = TargetCF})
        if currentTween then pcall(function() currentTween:Cancel() end) end
        currentTween = tw
        tw:Play()

        tw.Completed:Wait()
        shouldTween = false

        -- Final snap
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = TargetCF
        end
    end

    function TweenMove.StopTween()
        shouldTween = false
        if currentTween then pcall(function() currentTween:Cancel() end) end
        if block and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            block.CFrame = LP.Character.HumanoidRootPart.CFrame
        end
    end

    -- Anti-stuck: if we haven't moved far enough after N seconds, reset position
    function TweenMove.SafeTweenTo(TargetCF, timeout)
        timeout = timeout or 20
        local startPos = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position
        task.spawn(function()
            TweenMove.TweenTo(TargetCF)
        end)
        local t0 = tick()
        repeat
            task.wait(0.5)
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - TargetCF.Position).Magnitude < 5 then return true end
        until tick() - t0 >= timeout
        -- Anti-stuck: force teleport if tween got stuck
        Utils.Warn("SafeTweenTo: stuck detected, force TP")
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = TargetCF
        end
        return false
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MODULE: HopServer  (per-account, anti-duplicate)
-- ─────────────────────────────────────────────────────────────────────────────
local HopServer = {}

do
    local accName    = LP.Name
    local hopFile    = "workspace/" .. accName .. "_hop.json"
    local hopData    = { jobids = {}, timestamps = {}, count = 0 }
    local FailedJobs = {}

    -- Load existing hop file
    local function LoadHopData()
        Utils.Try(function()
            if isfile(hopFile) then
                local raw = readfile(hopFile)
                if raw and raw ~= "" then
                    local decoded = HttpService:JSONDecode(raw)
                    if type(decoded) == "table" then
                        hopData = decoded
                        hopData.jobids     = hopData.jobids     or {}
                        hopData.timestamps = hopData.timestamps or {}
                        hopData.count      = hopData.count      or 0
                    end
                end
            end
        end, "LoadHopData")
    end

    -- Save hop file; after MaxHopCount, reset it
    local function SaveHopData()
        Utils.Try(function()
            if hopData.count >= Config.MaxHopCount then
                Utils.Info("Hop count reached " .. Config.MaxHopCount .. ", resetting hop file")
                hopData = { jobids = {}, timestamps = {}, count = 0 }
            end
            writefile(hopFile, HttpService:JSONEncode(hopData))
        end, "SaveHopData")
    end

    -- Was this jobId already hopped?
    local function AlreadyHopped(jobId)
        for _, jid in ipairs(hopData.jobids) do
            if jid == jobId then return true end
        end
        return false
    end

    -- Record a new hop
    local function RecordHop(jobId)
        table.insert(hopData.jobids, jobId)
        table.insert(hopData.timestamps, math.floor(tick()))
        hopData.count = hopData.count + 1
        SaveHopData()
    end

    -- Init
    LoadHopData()

    -- Main hop function
    -- filterName: key in Config.HopAPI
    function HopServer.Hop(filterName, maxPlayers, waitTime)
        maxPlayers = maxPlayers or Config.MaxHopPlayers
        waitTime   = waitTime   or Config.HopWaitTime
        local apiUrl = Config.HopAPI[filterName]
        if not apiUrl then
            Utils.Error("No API URL for filter: " .. tostring(filterName))
            return false
        end

        Utils.Info("HopServer: looking for " .. filterName .. " server...")

        local ok, result = pcall(function()
            local responseBody
            -- Try HttpGet first, fallback to request()
            local httpOk = pcall(function()
                responseBody = game:HttpGet(apiUrl)
            end)
            if not httpOk or not responseBody then
                local reqFunc = (syn and syn.request) or (http and http.request) or request
                if reqFunc then
                    local resp = reqFunc({ Url = apiUrl, Method = "GET" })
                    responseBody = resp and resp.Body
                end
            end
            if not responseBody then
                Utils.Warn("HopServer: could not fetch API")
                return false
            end

            local data = HttpService:JSONDecode(responseBody)
            -- Support nested format: { success, data = { count, data = [...] } }
            if not data or not data.success then
                Utils.Warn("HopServer: API returned failure")
                return false
            end

            local list = data.data
            if type(list) == "table" and type(list.data) == "table" then
                list = list.data   -- nested format
            elseif type(list) ~= "table" then
                Utils.Warn("HopServer: unexpected data format")
                return false
            end

            local CURRENT_PLACE_ID = tostring(game.PlaceId)
            local seen, servers    = {}, {}
            for _, entry in ipairs(list) do
                local jobId  = entry.jobid
                local placeId = tostring(entry.placeid)
                local players = tonumber(entry.player) or 99
                if jobId and placeId == CURRENT_PLACE_ID and not seen[jobId] then
                    seen[jobId] = true
                    table.insert(servers, { jobid = jobId, players = players })
                end
            end

            -- Sort by fewest players
            table.sort(servers, function(a, b) return a.players < b.players end)
            Utils.Info("HopServer: found " .. #servers .. " valid servers")

            for _, server in ipairs(servers) do
                local jobId  = server.jobid
                local players = server.players

                if jobId == game.JobId       then continue end
                if FailedJobs[jobId]         then continue end
                if AlreadyHopped(jobId)      then continue end
                if players >= maxPlayers     then continue end

                Utils.Info("HopServer: joining [" .. jobId .. "] | " .. players .. " players")
                local teleOk = pcall(function()
                    RS:WaitForChild(Config.Remotes.ServerBrowser):InvokeServer("teleport", jobId)
                end)
                if teleOk then
                    RecordHop(jobId)
                    task.wait(15)
                    return true
                else
                    FailedJobs[jobId] = tick()
                    Utils.Warn("HopServer: failed to join " .. jobId)
                    task.wait(1)
                end
            end

            Utils.Info("HopServer: no suitable server found, waiting " .. waitTime .. "s")
            for i = waitTime, 1, -1 do
                task.wait(1)
                if i % 5 == 0 then
                    Utils.Info("HopServer: retry in " .. i .. "s")
                end
            end
            return false
        end)

        return ok and result
    end

    -- Simple Roblox public server hop (fallback)
    function HopServer.HopPublic()
        Utils.Info("HopServer: falling back to public server list")
        pcall(function()
            local body = game:HttpGet(
                "https://games.roblox.com/v1/games/" .. game.PlaceId ..
                "/servers/Public?sortOrder=Asc&limit=100"
            )
            local servers = HttpService:JSONDecode(body).data
            for _, server in ipairs(servers) do
                if server.playing < Config.MaxHopPlayers and server.id ~= game.JobId
                   and not AlreadyHopped(server.id) and not FailedJobs[server.id] then
                    RS:WaitForChild(Config.Remotes.ServerBrowser):InvokeServer("teleport", server.id)
                    RecordHop(server.id)
                    task.wait(10)
                    return
                end
            end
        end)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MODULE: Scanner  (anti-patch / debug tool)
-- ─────────────────────────────────────────────────────────────────────────────
local Scanner = {}

do
    local function ContainsKeyword(name)
        local lower = name:lower()
        for _, kw in ipairs(Config.ScanKeywords) do
            if lower:find(kw:lower(), 1, true) then return true, kw end
        end
        return false, nil
    end

    -- Dump all RemoteEvent / RemoteFunction names under RS.Remotes
    function Scanner.DumpRemoteNames()
        Utils.Info("=== DumpRemoteNames ===")
        local remotes = RS:FindFirstChild("Remotes")
        if not remotes then Utils.Warn("RS.Remotes not found"); return end
        for _, v in ipairs(remotes:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                local hit, kw = ContainsKeyword(v.Name)
                local mark = hit and (" ← [" .. kw .. "]") or ""
                print("  Remote: " .. v.Name .. " [" .. v.ClassName .. "]" .. mark)
            end
        end
        Utils.Info("=== End DumpRemoteNames ===")
    end

    -- Scan workspace for objects related to Temple/Lever/Gear/Mirage
    function Scanner.DumpTempleObjects()
        Utils.Info("=== DumpTempleObjects ===")
        local temple = workspace.Map and workspace.Map:FindFirstChild("Temple of Time")
        if not temple then Utils.Warn("Temple of Time not in workspace.Map"); return end
        for _, v in ipairs(temple:GetDescendants()) do
            local hit, kw = ContainsKeyword(v.Name)
            if hit then
                print(string.format("  [Temple] %s | Class=%s | Keyword=%s | Path=%s",
                    v.Name, v.ClassName, kw, v:GetFullName()))
            end
        end
        Utils.Info("=== End DumpTempleObjects ===")
    end

    -- Scan workspace for Mirage Island objects
    function Scanner.ScanRaceObjects()
        Utils.Info("=== ScanRaceObjects ===")
        for _, v in ipairs(workspace:GetDescendants()) do
            local hit, kw = ContainsKeyword(v.Name)
            if hit then
                print(string.format("  [Workspace] %s | Class=%s | Keyword=%s",
                    v.Name, v.ClassName, kw))
            end
        end
        Utils.Info("=== End ScanRaceObjects ===")
    end

    -- Scan all remotes and game functions for race v4 related keywords
    function Scanner.ScanGameFunctions()
        Utils.Info("=== ScanGameFunctions ===")
        Scanner.DumpRemoteNames()
        Scanner.ScanRaceObjects()
        Utils.Info("=== End ScanGameFunctions ===")
    end

    -- Save full workspace instance tree to a JSON file
    function Scanner.SaveInstanceTree()
        Utils.Info("Saving workspace instance tree...")
        local lines = {}
        local function recurse(inst, depth)
            table.insert(lines, string.rep("  ", depth) .. inst.Name .. " [" .. inst.ClassName .. "]")
            -- Limit depth to avoid huge files
            if depth >= 6 then return end
            for _, child in ipairs(inst:GetChildren()) do
                pcall(recurse, child, depth + 1)
            end
        end
        pcall(recurse, workspace, 0)
        local content = table.concat(lines, "\n")
        local filename = "workspace/" .. LP.Name .. "_instance_tree.txt"
        writefile(filename, content)
        Utils.Success("Instance tree saved to " .. filename)
    end

    -- Quick patch-check: verify known remotes still exist
    function Scanner.CheckPatch()
        Utils.Info("=== CheckPatch ===")
        local issues = 0
        local function check(path, label)
            local ok = pcall(function()
                local cur = RS
                for _, key in ipairs(path) do
                    cur = cur:FindFirstChild(key)
                    if not cur then error("missing") end
                end
            end)
            if ok then
                Utils.Info("  OK : " .. label)
            else
                Utils.Warn("  MISSING: " .. label .. "  ← may need update")
                issues = issues + 1
            end
        end

        check({"Remotes", "CommF_"},      "RS.Remotes.CommF_")
        check({"Remotes", "CommE"},        "RS.Remotes.CommE")
        check({"Remotes", "__ServerBrowser"}, "RS.__ServerBrowser")

        if issues == 0 then
            Utils.Success("CheckPatch: all remotes OK")
        else
            Utils.Error("CheckPatch: " .. issues .. " issue(s) found")
        end
        Utils.Info("=== End CheckPatch ===")
        return issues == 0
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MODULE: Conditions
-- ─────────────────────────────────────────────────────────────────────────────
local Cond = {}

do
    -- 1. Has Valkyrie Helm in backpack/character/inventory?
    function Cond.HasValkyrieHelm()
        if Utils.HasItem(Config.Items.ValkyrieHelm) then return true end
        -- Also check via inventory remote
        local inv = Utils.Invoke("getInventory")
        if type(inv) == "table" then
            for _, v in pairs(inv) do
                if v.Name == Config.Items.ValkyrieHelm then return true end
            end
        end
        return false
    end

    -- 2. Has Mirror Fractal?
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

    -- 3. Has already pulled lever?  CheckTempleDoor → truthy = pulled
    function Cond.HasPulledLever()
        local result = Utils.Invoke("CheckTempleDoor")
        return result ~= nil and result ~= false
    end

    -- 4. Has collected Gear (at least one RaceDetails point or completed)?
    function Cond.HasGear()
        local dt = Utils.Invoke("TempleClock", "Check")
        if not dt then return false end
        -- If RaceDetails.Completed > 0, we have at least one gear
        return type(dt) == "table"
            and type(dt.RaceDetails) == "table"
            and (dt.RaceDetails.Completed or 0) > 0
    end

    -- 5. Has killed Rip_Indra?
    --    Rip_Indra kill is tracked via RaceV4Progress; state == 2 means teleport
    --    state >= 2 typically means Rip_Indra was already killed
    function Cond.HasKilledRipIndra()
        local state = Utils.Invoke("RaceV4Progress", "Check")
        if type(state) == "number" and state >= 2 then return true end
        -- Also check if Rip_Indra is not alive in workspace
        local ri = workspace.Enemies and workspace.Enemies:FindFirstChild(Config.NPCs.RipIndra)
        if not ri or not Utils.IsAlive(ri) then
            -- If they never spawned or are dead, consider killed
            -- But only if state > 0 (quest was started)
            if type(state) == "number" and state > 0 then return true end
        end
        return false
    end

    -- 6. Has Temple access (door unlocked / inside)?
    function Cond.HasTempleAccess()
        local temple = workspace.Map and workspace.Map:FindFirstChild("Temple of Time")
        if not temple then return false end
        local border = temple:FindFirstChild("FFABorder")
        if border then
            local ff = border:FindFirstChild("Forcefield")
            -- Transparency == 1 means forcefield is invisible → open
            if ff and ff.Transparency == 1 then return true end
        end
        return false
    end

    -- Print all condition statuses
    function Cond.PrintAll()
        Utils.Info("──── Condition Check ────")
        Utils.Info("HasValkyrieHelm  : " .. tostring(Cond.HasValkyrieHelm()))
        Utils.Info("HasMirrorFractal : " .. tostring(Cond.HasMirrorFractal()))
        Utils.Info("HasKilledRipIndra: " .. tostring(Cond.HasKilledRipIndra()))
        Utils.Info("HasTempleAccess  : " .. tostring(Cond.HasTempleAccess()))
        Utils.Info("HasPulledLever   : " .. tostring(Cond.HasPulledLever()))
        Utils.Info("HasGear          : " .. tostring(Cond.HasGear()))
        Utils.Info("────────────────────────")
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MODULE: Temple
-- ─────────────────────────────────────────────────────────────────────────────
local Temple = {}

do
    -- Known Temple of Time entrance position
    local TEMPLE_ENTRANCE_POS = Vector3.new(28310.0234, 14895.1123, 109.456741)

    -- Teleport to Temple of Time using requestEntrance remote
    function Temple.TeleportToTemple()
        Utils.Info("Temple: teleporting to Temple of Time")
        -- Use RaceV4Progress Teleport (from KaitunV4 line ~202)
        local ok = pcall(function()
            Utils.Invoke("RaceV4Progress", "Teleport")
        end)
        task.wait(1)
        -- Also tween to entrance as fallback
        TweenMove.SafeTweenTo(CFrame.new(TEMPLE_ENTRANCE_POS), 20)
    end

    -- Enter the race corridor inside Temple
    function Temple.EnterCorridor()
        Utils.Info("Temple: entering corridor")
        local race = Utils.Try(function()
            return LP.Data.Race.Value
        end) and LP.Data.Race.Value or nil

        if not race then
            Utils.Error("Temple: cannot get race value")
            return false
        end

        local ok, door = pcall(function()
            return workspace.Map["Temple of Time"]
                :WaitForChild(race .. "Corridor", 10)
                :WaitForChild("Door", 10)
                :WaitForChild("Entrance", 10)
        end)
        if ok and door then
            Utils.Info("Temple: tweening to " .. race .. " corridor door")
            TweenMove.SafeTweenTo(door.CFrame, 15)
            return true
        else
            Utils.Warn("Temple: could not find corridor door for race " .. tostring(race))
            return false
        end
    end

    -- Recover Temple from MapStash if missing (KaitunV4 pattern)
    function Temple.EnsureTempleInWorkspace()
        if workspace.Map:FindFirstChild("Temple of Time") then return true end
        Utils.Warn("Temple: Temple of Time not in workspace.Map, checking MapStash")
        local stash = RS:FindFirstChild("MapStash")
        if stash then
            local t = stash:FindFirstChild("Temple of Time")
            if t then
                t.Parent = workspace.Map
                Utils.Success("Temple: moved from MapStash to workspace.Map")
                return true
            end
        end
        Utils.Error("Temple: Temple of Time not found anywhere")
        return false
    end

    -- Find the Lever inside Temple
    function Temple.FindLever()
        local temple = workspace.Map:FindFirstChild("Temple of Time")
        if not temple then return nil end
        for _, v in ipairs(temple:GetDescendants()) do
            if v.Name:lower():find("lever") and (v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Model")) then
                Utils.Info("Temple: found lever → " .. v:GetFullName())
                return v
            end
        end
        -- Fallback: try workspace-wide scan
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name:lower():find("lever") and (v:IsA("BasePart") or v:IsA("MeshPart")) then
                Utils.Info("Temple: found lever (global) → " .. v:GetFullName())
                return v
            end
        end
        return nil
    end

    -- Interact with lever using ProximityPrompt or direct fire
    function Temple.InteractLever(leverObj)
        if not leverObj then
            Utils.Error("Temple: no lever object provided")
            return false
        end

        -- Get position of the lever (handle Model vs BasePart)
        local leverCF
        if leverObj:IsA("Model") then
            leverCF = leverObj:GetPivot()
        elseif leverObj:IsA("BasePart") or leverObj:IsA("MeshPart") then
            leverCF = leverObj.CFrame
        end

        if leverCF then
            Utils.Info("Temple: tweening to lever")
            TweenMove.SafeTweenTo(leverCF * CFrame.new(0, 0, 3), 10)
            task.wait(0.5)
        end

        -- Try ProximityPrompt
        local function tryPP(obj)
            for _, d in ipairs(obj:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    Utils.Info("Temple: firing ProximityPrompt on lever")
                    fireproximityprompt(d)
                    return true
                end
            end
            -- Check parent
            if obj.Parent then
                for _, d in ipairs(obj.Parent:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        fireproximityprompt(d)
                        return true
                    end
                end
            end
            return false
        end

        if tryPP(leverObj) then
            task.wait(2)
            return true
        end

        -- Fallback: try using PullLever remote
        local remoteNames = {"PullLever", "TempleSwitch", "LeverPull", "ActivateLever", "InteractLever"}
        for _, name in ipairs(remoteNames) do
            local remote = RS.Remotes:FindFirstChild(name)
            if remote then
                Utils.Info("Temple: firing " .. name .. " remote")
                pcall(function() remote:FireServer() end)
                task.wait(2)
                return Cond.HasPulledLever()
            end
        end

        -- Last resort: CommF_ with known action names
        local actionNames = {"PullLever", "TempleSwitch", "LeverActivate", "ActivateLever"}
        for _, action in ipairs(actionNames) do
            Utils.Info("Temple: trying CommF_ action: " .. action)
            local result = Utils.Invoke(action)
            if result then
                task.wait(2)
                if Cond.HasPulledLever() then return true end
            end
        end

        Utils.Error("Temple: could not interact with lever — scan with Scanner.DumpTempleObjects() to find correct remote")
        return false
    end

    -- Full Pull Lever sequence
    function Temple.PullLever()
        Utils.Info("Temple: starting Pull Lever sequence")

        -- Ensure temple exists in workspace
        if not Temple.EnsureTempleInWorkspace() then
            return false
        end

        -- Teleport to temple
        Temple.TeleportToTemple()
        task.wait(2)

        -- Enter corridor
        Temple.EnterCorridor()
        task.wait(1)

        -- Find lever
        local lever = Utils.Retry(Temple.FindLever, 5, 2, "FindLever")
        if not lever then
            Utils.Error("Temple: lever not found after retries")
            return false
        end

        -- Interact
        local success = Temple.InteractLever(lever)
        if success then
            task.wait(1)
            if Cond.HasPulledLever() then
                Utils.Success("Temple: Lever pulled successfully!")
                return true
            end
        end

        Utils.Error("Temple: PullLever sequence failed")
        return false
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MODULE: Mirage
-- ─────────────────────────────────────────────────────────────────────────────
local Mirage = {}

do
    -- Center position of Mirage Island (approximate; detected dynamically when possible)
    local MIRAGE_CENTER_FALLBACK = CFrame.new(-1616.5, 148, -372.5)

    local function IsNight()
        local c = Lighting.ClockTime
        return c >= 16 or c < 5
    end

    local function IsFullMoon()
        return Lighting:GetAttribute("MoonPhase") == 5
    end

    -- Detect Mirage Island in workspace (check for MysticIsland or Mirage keyword)
    function Mirage.Detect()
        -- Check workspace.Map for MysticIsland
        local map = workspace:FindFirstChild("Map")
        if map then
            local mi = map:FindFirstChild("MysticIsland")
            if mi then return mi end
            -- Also look for "Mirage" keyword
            for _, v in ipairs(map:GetChildren()) do
                if v.Name:lower():find("mirage") then return v end
            end
        end
        -- Global workspace scan
        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name:lower():find("mirage") or v.Name:lower():find("mystic") then
                return v
            end
        end
        return nil
    end

    -- Get center position of Mirage Island
    function Mirage.GetCenter(mirageObj)
        if not mirageObj then return MIRAGE_CENTER_FALLBACK end
        local ok, pivot = pcall(function() return mirageObj:GetPivot() end)
        if ok and pivot then return pivot end
        -- Fallback: use first BasePart
        for _, v in ipairs(mirageObj:GetDescendants()) do
            if v:IsA("BasePart") then return v.CFrame end
        end
        return MIRAGE_CENTER_FALLBACK
    end

    -- Find the Gear (Blue Gear / MeshPart with Gear meshid)
    -- KaitunV4 uses meshid "rbxassetid://10153114969"
    function Mirage.FindGear(mirageObj)
        local searchRoot = mirageObj or (workspace.Map and workspace.Map:FindFirstChild("MysticIsland")) or workspace
        for _, v in ipairs(searchRoot:GetDescendants()) do
            if v:IsA("MeshPart") and v.MeshId == "rbxassetid://10153114969" then
                Utils.Info("Mirage: found Gear MeshPart at " .. v:GetFullName())
                return v
            end
        end
        -- Fallback: look for any object named "Gear" near mirage
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name:lower():find("gear") and v:IsA("BasePart") then
                Utils.Info("Mirage: found Gear (name match) at " .. v:GetFullName())
                return v
            end
        end
        return nil
    end

    -- Align camera to look at the Moon (for Mirror Fractal resonance)
    function Mirage.AlignCameraToMoon()
        Utils.Info("Mirage: aligning camera to moon")
        pcall(function()
            local camera = workspace.CurrentCamera
            -- Moon is typically above; face camera upward/north
            -- Use Lighting.ClockTime to estimate moon direction
            local moonDir = Vector3.new(0, 1, -0.5).Unit   -- approximate upward-north
            if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local hrpPos = LP.Character.HumanoidRootPart.Position
                local targetPos = hrpPos + moonDir * 500
                local cf = CFrame.new(hrpPos, targetPos)
                -- Tween camera
                local info = TweenInfo.new(1, Enum.EasingStyle.Sine)
                local tw = TS:Create(camera, info, {CFrame = cf})
                tw:Play()
                tw.Completed:Wait()
            end
        end)
    end

    -- Wait for night + full moon
    function Mirage.WaitForNight()
        Utils.Info("Mirage: waiting for night + full moon")
        while not IsNight() or not IsFullMoon() do
            task.wait(2)
            Utils.Info("Mirage: time=" .. tostring(math.floor(Lighting.ClockTime)) ..
                        " | moonPhase=" .. tostring(Lighting:GetAttribute("MoonPhase")) ..
                        " | isNight=" .. tostring(IsNight()) ..
                        " | isFullMoon=" .. tostring(IsFullMoon()))
        end
        Utils.Success("Mirage: it is now night + full moon!")
    end

    -- Wait for Mirror Fractal resonance message
    function Mirage.WaitForResonance()
        Utils.Info("Mirage: waiting for Mirror Fractal resonance...")
        local resonated = false
        local conn
        conn = game.Players.LocalPlayer.PlayerGui.DescendantAdded:Connect(function(obj)
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                if obj.Text:find("Mirror Fractal") and obj.Text:find("resonated") then
                    Utils.Success("Mirage: Mirror Fractal resonated!")
                    resonated = true
                end
            end
        end)
        -- Also check via GUI polling
        local timeout = 120
        local t0 = tick()
        repeat
            task.wait(1)
            -- Check all TextLabel in PlayerGui
            for _, v in ipairs(LP.PlayerGui:GetDescendants()) do
                if v:IsA("TextLabel") and v.Text:find("resonated") then
                    resonated = true
                end
            end
        until resonated or tick() - t0 >= timeout
        pcall(function() conn:Disconnect() end)
        if not resonated then
            Utils.Warn("Mirage: resonance timeout — proceeding anyway")
        end
        return resonated
    end

    -- Full Mirage Island sequence
    function Mirage.Run()
        Utils.Info("Mirage: starting Mirage Island sequence")

        -- Detect island
        local mirageObj = Utils.Retry(Mirage.Detect, 10, 3, "Mirage.Detect")
        if not mirageObj then
            Utils.Error("Mirage: island not detected")
            return false
        end
        Utils.Success("Mirage: detected " .. mirageObj.Name)

        -- Tween to center
        local center = Mirage.GetCenter(mirageObj)
        Utils.Info("Mirage: tweening to island center")
        TweenMove.SafeTweenTo(center, 20)
        task.wait(1)

        -- Wait for night + full moon
        Mirage.WaitForNight()
        task.wait(1)

        -- Align camera to moon
        Mirage.AlignCameraToMoon()
        task.wait(2)

        -- Wait for resonance message
        local resonated = Mirage.WaitForResonance()
        if not resonated then
            Utils.Warn("Mirage: continuing without confirmed resonance")
        end
        task.wait(1)

        -- Locate and pick up Gear
        Utils.Info("Mirage: locating Gear")
        local gear = Utils.Retry(function() return Mirage.FindGear(mirageObj) end, 10, 2, "FindGear")
        if not gear then
            Utils.Error("Mirage: Gear not found")
            return false
        end

        Utils.Info("Mirage: tweening to Gear")
        TweenMove.SafeTweenTo(gear.CFrame * CFrame.new(0, 2, 0), 10)
        task.wait(1)

        -- Collect gear via ProximityPrompt or Touch
        local pickedUp = false
        Utils.Try(function()
            for _, v in ipairs(gear:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    fireproximityprompt(v)
                    pickedUp = true
                    break
                end
            end
            if not pickedUp and gear.Parent then
                for _, v in ipairs(gear.Parent:GetDescendants()) do
                    if v:IsA("ProximityPrompt") then
                        fireproximityprompt(v)
                        pickedUp = true
                        break
                    end
                end
            end
        end, "PickupGear PP")

        if not pickedUp then
            -- Try touching (TP onto gear)
            LP.Character.HumanoidRootPart.CFrame = gear.CFrame * CFrame.new(0, 0.5, 0)
            task.wait(0.5)
        end

        task.wait(2)

        -- Verify gear
        if Cond.HasGear() then
            Utils.Success("Mirage: Gear collected!")
            return true
        else
            Utils.Warn("Mirage: HasGear() returned false — gear may have a different mechanism")
            -- Try TempleClock SpendPoint (from KaitunV4 checkgear pattern)
            local dt = Utils.Invoke("TempleClock", "Check")
            if dt and dt.HadPoint then
                Utils.Info("Mirage: using TempleClock SpendPoint")
                Utils.Invoke("TempleClock", "SpendPoint",
                    "Gear" .. tostring(dt.RaceDetails and dt.RaceDetails.Completed or 1), "Alpha")
                task.wait(1)
                if Cond.HasGear() then
                    Utils.Success("Mirage: Gear confirmed via SpendPoint!")
                    return true
                end
            end
            return false
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MAIN ORCHESTRATOR
-- ─────────────────────────────────────────────────────────────────────────────
local function Main()
    Utils.Info("════════════════════════════════════════")
    Utils.Info("  Pull Lever - Temple of Time | START  ")
    Utils.Info("  Account : " .. LP.Name)
    Utils.Info("  JobId   : " .. game.JobId)
    Utils.Info("════════════════════════════════════════")

    -- 1. Run patch check first
    if not Scanner.CheckPatch() then
        Utils.Error("Patch check failed — some remotes may have changed. Check Scanner output.")
        -- Continue anyway; individual calls use pcall internally
    end

    -- 2. Print all conditions
    Cond.PrintAll()

    -- 3. If lever already pulled → done
    if Cond.HasPulledLever() then
        Utils.Success("Lever already pulled! Nothing to do.")
        return
    end

    -- 4. Check required items
    if not Cond.HasValkyrieHelm() then
        Utils.Error("Missing: Valkyrie Helm — cannot proceed")
        return
    end
    if not Cond.HasMirrorFractal() then
        Utils.Error("Missing: Mirror Fractal — cannot proceed")
        return
    end
    Utils.Success("Items OK: Valkyrie Helm + Mirror Fractal present")

    -- 5. If Rip_Indra hasn't been killed yet, we can't open temple
    if not Cond.HasKilledRipIndra() then
        Utils.Error("Rip_Indra not killed yet — this script does not auto-kill Rip_Indra")
        Utils.Info("Please kill Rip_Indra first, then re-run this script")
        return
    end
    Utils.Info("Rip_Indra: confirmed killed")

    -- 6. Ensure temple access; if not, teleport there and check conditions
    if not Cond.HasTempleAccess() then
        Utils.Info("Temple not open → teleporting and re-checking")
        Temple.TeleportToTemple()
        task.wait(3)
        Temple.EnterCorridor()
        task.wait(2)
        Cond.PrintAll()
    else
        Utils.Info("Temple: already have access")
    end

    -- 7. If gear already collected, skip Mirage and go straight to pulling lever
    if Cond.HasGear() then
        Utils.Info("Gear already collected — skipping Mirage, going straight to lever")
        local leverSuccess = Temple.PullLever()
        if leverSuccess then
            Utils.Success("════════════════════════════════")
            Utils.Success("  LEVER PULLED SUCCESSFULLY!    ")
            Utils.Success("════════════════════════════════")
        else
            Utils.Error("Pull Lever failed — run Scanner.DumpTempleObjects() to debug")
        end
        return
    end

    -- 8. Need Gear → go through Mirage server hop loop
    Utils.Info("Gear not yet collected → starting server hop for Mirage Island")

    local maxAttempts = 20
    local attempt = 0

    while attempt < maxAttempts do
        attempt = attempt + 1
        Utils.Info("Mirage attempt " .. attempt .. "/" .. maxAttempts)

        -- Re-verify items each server join
        if not Cond.HasValkyrieHelm() or not Cond.HasMirrorFractal() then
            Utils.Error("Items missing after server hop — stopping")
            return
        end

        -- Check if Mirage Island exists in this server
        local mirageNow = Mirage.Detect()
        if not mirageNow then
            Utils.Info("No Mirage Island in this server → hopping")
            local hopped = HopServer.Hop("Mirage", Config.MaxHopPlayers, Config.HopWaitTime)
            if not hopped then
                Utils.Warn("Hop API failed, trying public servers")
                HopServer.HopPublic()
            end
            task.wait(5)  -- give time to load new server
            continue
        end

        Utils.Success("Mirage Island found! Running Mirage sequence")
        local gearOk = Mirage.Run()

        if gearOk and Cond.HasGear() then
            Utils.Success("Gear collected! Now pulling lever")
            task.wait(2)

            local leverOk = Temple.PullLever()
            if leverOk then
                Utils.Success("════════════════════════════════")
                Utils.Success("  LEVER PULLED SUCCESSFULLY!    ")
                Utils.Success("════════════════════════════════")
                return
            else
                Utils.Error("Pull Lever failed after Mirage — will retry")
            end
        else
            Utils.Warn("Gear sequence failed — hopping to next server")
            HopServer.Hop("Mirage", Config.MaxHopPlayers, Config.HopWaitTime)
            task.wait(5)
        end
    end

    Utils.Error("Max attempts reached — script stopping")
    Utils.Info("Run Scanner.ScanGameFunctions() and Scanner.DumpTempleObjects() to debug")
end

-- ─────────────────────────────────────────────────────────────────────────────
-- EXPOSE GLOBALS FOR DEBUGGING
-- ─────────────────────────────────────────────────────────────────────────────
_G.PullLever = {
    -- Condition checks
    HasValkyrieHelm  = Cond.HasValkyrieHelm,
    HasMirrorFractal = Cond.HasMirrorFractal,
    HasPulledLever   = Cond.HasPulledLever,
    HasGear          = Cond.HasGear,
    HasKilledRipIndra = Cond.HasKilledRipIndra,
    HasTempleAccess  = Cond.HasTempleAccess,
    PrintConditions  = Cond.PrintAll,

    -- Scanner / patch tools
    ScanGameFunctions = Scanner.ScanGameFunctions,
    ScanRaceObjects   = Scanner.ScanRaceObjects,
    DumpRemoteNames   = Scanner.DumpRemoteNames,
    DumpTempleObjects = Scanner.DumpTempleObjects,
    CheckPatch        = Scanner.CheckPatch,
    SaveInstanceTree  = Scanner.SaveInstanceTree,

    -- Manual triggers
    TeleportToTemple = Temple.TeleportToTemple,
    EnterCorridor    = Temple.EnterCorridor,
    PullLever        = Temple.PullLever,
    RunMirage        = Mirage.Run,
    HopServer        = HopServer.Hop,

    -- Utils
    Log              = Utils.Log,
}

Utils.Info("_G.PullLever exposed for debugging. Use _G.PullLever.PrintConditions() to check state.")
Utils.Info("Use _G.PullLever.DumpTempleObjects() / _G.PullLever.ScanGameFunctions() for patch analysis.")

-- ─────────────────────────────────────────────────────────────────────────────
-- RUN
-- ─────────────────────────────────────────────────────────────────────────────
task.spawn(Main)
