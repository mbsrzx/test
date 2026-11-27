-- ================================================================
--  TEST  |  Blox Fruits PVP (WindUI - Crimson & Black)
-- ================================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VIM               = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")

local lp = Players.LocalPlayer

local World1 = game.PlaceId == 2753915549 or game.PlaceId == 85211729168715
local World2 = game.PlaceId == 4442272183 or game.PlaceId == 79091703265657
local World3 = game.PlaceId == 7449423635 or game.PlaceId == 100117331123089

local CONFIG_DIR    = "test"
local CONFIG_FILE   = CONFIG_DIR .. "/config.json"
local CACHED_SCRIPT = CONFIG_DIR .. "/cached_test.lua"
local AUTOEXEC_DIR  = "autoexec"
local AUTOEXEC_FILE = AUTOEXEC_DIR .. "/test_AutoExec.lua"

-- ================================================================
--  CONFIG & STATE
-- ================================================================
local CFG = {
    -- Screen-Share Proof & Soru Visual Cooldown (ON by default)
    ScreenShareProof = true,
    SoruVisualCD     = true,
    -- Auto-Save & Auto-Exec (ON by default)
    AutoSaveConfig   = true,
    AutoExec         = true,
    HostedScriptUrl  = "",
    -- Silent Aim
    SilentAimPlayers = false, SilentAimNPCs = false,
    FovRadius = 120, AimMaxRange = 1000,
    HitPart = "HumanoidRootPart", FovCentre = false,
    VelX = 0.22, VelY = 0.00,
    OffsetX = 0, OffsetY = 0, OffsetZ = 0,
    -- Gun Aimbot
    GunAim = false, GunFovRadius = 200, GunMaxRange = 1500,
    -- Soru
    SoruAim = false, SoruInfinite = false,
    SoruDistance = false, SoruDistMult = 2.0,
    -- Follow-up & Loadout
    SoruFollowup = false,
    FollowupCategory = "Fruit",
    FollowupSkill = "X",
    FollowupDelay = 0.05,
    FollowupSlotDelay = 0.08,
    FollowupStepGap = 0.07,
    FollowupTriggerKey = "None",
    LoadoutSlots = {
        Fruit = "2",
        Melee = "1",
        Sword = "3",
        Gun   = "4",
    },
    -- Stack UD
    StackUD = false, StackUDHeight = 8, StackUDSpeed = 0.04,
    -- Auto Ken
    AutoKen = false, KenRange = 60, KenCooldown = 0.35,
    KenReaction = 0.05, KenKey = Enum.KeyCode.Q,
    -- Aura / Combat
    FastAttackMobs = false, FastAttackPlayers = false,
    FastAttackMode = "Mode2",
    FruitM1 = false, VoidFruitM1 = false,
    AutoHaki = false, AutoV3 = false, AutoV4 = false,
    AutoFlee = false, AutoFleeHP = 30,
    AutoSoru = false,
    -- Movement
    SpeedEnabled = false, SpeedValue = 50,
    JumpEnabled = false, JumpValue = 50,
    InfiniteJump = false,
    Noclip = false, BoatNoclip = false,
    FlyEnabled = false, FlySpeed = 50,
    DodgeNoCooldown = false,
    DashLengthEnabled = false, DashLength = 5,
    WalkOnWater = false, RemoveWater = false,
    -- Movement Glitches
    ZBoostKey = Enum.KeyCode.G,
    SuperJumpKey = Enum.KeyCode.H,
    SuperJumpBoost = 300,
    -- World
    CameraZoom = 128, RemoveLava = false, RemoveFog = false,
    BringMobs = false, ClickJump = false,
    -- ESP
    ESPEnabled = false, ESP_Name = true, ESP_Level = true,
    ESP_Bounty = true, ESP_Fruit = true,
    ESP_Distance = true, ESP_HP = true,
    ESP_Highlight = false, ESP_TextSize = 14,
    -- Experimental (10)
    ExpAuraShellOrbit    = false,
    ExpAvatarSizeFlag    = false,
    ExpFlyDownDraft      = false,
    ExpHitConfirmGate    = false,
    ExpFlyVectorLead     = false,
    ExpSoruBackSlip      = false,
    ExpHitstunPace       = false,
    ExpV4Emergency       = false,
    ExpSecondFlyerSpace  = false,
    ExpSmoothAimBlend    = false,
    -- UI
    UIVisible = true,
}

local AIM = { pos = nil, rawPos = nil, gunPos = nil, soruPos = nil }
local Whitelist = {}
local toggleCallbacks = {}
local uiSyncCallbacks = {}
local OversizedPlayers = {}
local _suppressAutoSave = false
local _captureActive = false
local _soruFakeCdStart = tick()

local KB = {
    ToggleUI         = Enum.KeyCode.RightShift,
    SilentAimPlayers = Enum.KeyCode.F1,
    SilentAimNPCs    = Enum.KeyCode.F2,
    SoruAim          = Enum.KeyCode.F3,
    SoruInfinite     = Enum.KeyCode.F4,
    AutoKen          = Enum.KeyCode.F5,
}

local SLOT_TO_KEYCODE = {
    ["1"] = Enum.KeyCode.One,
    ["2"] = Enum.KeyCode.Two,
    ["3"] = Enum.KeyCode.Three,
    ["4"] = Enum.KeyCode.Four,
    ["5"] = Enum.KeyCode.Five,
    ["6"] = Enum.KeyCode.Six,
    ["7"] = Enum.KeyCode.Seven,
    ["8"] = Enum.KeyCode.Eight,
    ["9"] = Enum.KeyCode.Nine,
    ["0"] = Enum.KeyCode.Zero,
}

-- ================================================================
--  CONFIG PERSISTENCE, AUTO-EXEC & CAPTURE SIGNALS
-- ================================================================
local function ensureFolder(path)
    if type(isfolder) == "function" and type(makefolder) == "function" then
        if not isfolder(path) then
            pcall(makefolder, path)
        end
    end
end

local function serializeValue(val)
    local t = typeof(val)
    if t == "EnumItem" then
        return { __enumType = tostring(val.EnumType), name = val.Name }
    elseif type(val) == "table" then
        local copy = {}
        for k, v in pairs(val) do
            copy[k] = serializeValue(v)
        end
        return copy
    end
    return val
end

local function deserializeValue(val, fallback)
    if type(val) == "table" and val.__enumType and val.name then
        local enumContainer = Enum[tostring(val.__enumType)]
        if enumContainer and enumContainer[val.name] then
            return enumContainer[val.name]
        end
        return fallback
    elseif type(val) == "string" and typeof(fallback) == "EnumItem" then
        local enumContainer = Enum[tostring(fallback.EnumType)]
        if enumContainer and enumContainer[val] then
            return enumContainer[val]
        end
        return fallback
    elseif type(val) == "table" and type(fallback) == "table" then
        local merged = {}
        for k, fb in pairs(fallback) do
            merged[k] = val[k] ~= nil and deserializeValue(val[k], fb) or fb
        end
        for k, v in pairs(val) do
            if merged[k] == nil then
                merged[k] = v
            end
        end
        return merged
    end
    return val
end

local function saveConfigFile(silent)
    if type(writefile) ~= "function" then
        if not silent then warn("[test] writefile is not supported in this executor.") end
        return false
    end
    local ok, err = pcall(function()
        ensureFolder(CONFIG_DIR)
        local serializedCfg = {}
        for k, v in pairs(CFG) do
            serializedCfg[k] = serializeValue(v)
        end
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            CFG = serializedCfg,
            Whitelist = Whitelist,
        }))
    end)
    if not ok then
        warn("[test] Config save error: " .. tostring(err))
        return false
    end
    if not silent then
        print("[test] Saved config to " .. CONFIG_FILE)
    end
    return true
end

local _saveQueued = false
local function scheduleAutoSave()
    if _suppressAutoSave or not CFG.AutoSaveConfig or _saveQueued then return end
    _saveQueued = true
    task.delay(0.3, function()
        _saveQueued = false
        if CFG.AutoSaveConfig and not _suppressAutoSave then
            saveConfigFile(true)
        end
    end)
end

local function buildAutoExecLoader()
    local url = tostring(CFG.HostedScriptUrl or ""):gsub('"', '\\"')
    return table.concat({
        "-- test AutoExec bootstrapper",
        "repeat task.wait() until game:IsLoaded()",
        "task.wait(1)",
        'if type(isfile) == "function" and type(readfile) == "function" and isfile("' .. CACHED_SCRIPT .. '") then',
        '    local fn, err = loadstring(readfile("' .. CACHED_SCRIPT .. '"))',
        "    if fn then task.spawn(fn) else warn('[test AutoExec] ' .. tostring(err)) end",
        'elseif "' .. url .. '" ~= "" then',
        '    local ok, src = pcall(function() return game:HttpGet("' .. url .. '") end)',
        "    if ok and type(src) == 'string' and #src > 0 then",
        "        local fn, err = loadstring(src)",
        "        if fn then task.spawn(fn) else warn('[test AutoExec] ' .. tostring(err)) end",
        "    end",
        "else",
        '    warn("[test AutoExec] Cache missing at ' .. CACHED_SCRIPT .. '. Copy script & click Cache Clipboard in Config tab.")',
        "end",
    }, "\n")
end

local function syncAutoExec(enabled)
    if type(writefile) ~= "function" then
        warn("[test] writefile not available; cannot write autoexec file.")
        return false
    end
    local ok, err = pcall(function()
        if enabled then
            ensureFolder(CONFIG_DIR)
            ensureFolder(AUTOEXEC_DIR)
            writefile(AUTOEXEC_FILE, buildAutoExecLoader())
        else
            if type(isfile) == "function" and type(delfile) == "function" and isfile(AUTOEXEC_FILE) then
                delfile(AUTOEXEC_FILE)
            end
        end
    end)
    if not ok then
        warn("[test] AutoExec sync error: " .. tostring(err))
        return false
    end
    return true
end

local function cacheScriptFromClipboard()
    local getClip = getclipboard or fromclipboard
    if type(getClip) ~= "function" or type(writefile) ~= "function" then
        warn("[test] Executor missing getclipboard or writefile.")
        return false
    end
    local ok, clip = pcall(getClip)
    if not ok or type(clip) ~= "string" or #clip < 200 or not clip:find("WindUI", 1, true) then
        warn("[test] Clipboard does not contain the full script source.")
        return false
    end
    ensureFolder(CONFIG_DIR)
    writefile(CACHED_SCRIPT, clip)
    if CFG.AutoExec then
        syncAutoExec(true)
    end
    print("[test] Cached script to " .. CACHED_SCRIPT .. " (" .. #clip .. " bytes)")
    return true
end

lp.OnTeleport:Connect(function()
    if not CFG.AutoExec then return end
    local qot = queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
    if type(qot) == "function" then
        pcall(qot, buildAutoExecLoader())
    end
end)

task.spawn(function()
    pcall(function()
        local cap = game:GetService("CaptureService")
        if cap and cap.ScreenshotCaptured then
            cap.ScreenshotCaptured:Connect(function()
                if CFG.ScreenShareProof then _captureActive = true end
            end)
        end
        if cap and cap.CaptureEnded then
            cap.CaptureEnded:Connect(function()
                _captureActive = false
            end)
        end
    end)
end)

-- ================================================================
--  HELPERS
-- ================================================================
local function myHRP()
    return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
end

local function getVel(part)
    return part.AssemblyLinearVelocity or part.Velocity or Vector3.new()
end

local function isAlly(tp)
    local sc = lp:FindFirstChild("PlayerGui")
        and lp.PlayerGui:FindFirstChild("Main")
        and lp.PlayerGui.Main:FindFirstChild("Allies")
        and lp.PlayerGui.Main.Allies:FindFirstChild("ScrollingFrame")
    if not sc then return false end
    for _, f in ipairs(sc:GetChildren()) do
        if f:IsA("ImageButton") and f.Name == tp.Name then return true end
    end
    return false
end

local function isEnemy(tp)
    if not tp or tp == lp then return false end
    if Whitelist[tp.Name] then return false end
    local mt2, tt = lp.Team, tp.Team
    if mt2 and tt and mt2 == tt then
        return mt2.Name == "Pirates" and not isAlly(tp)
    end
    return true
end

local function getFovCentre()
    if CFG.FovCentre then
        local vp = workspace.CurrentCamera.ViewportSize
        return Vector2.new(vp.X / 2, vp.Y / 2)
    end
    return UserInputService:GetMouseLocation()
end

local function getClosestPlayer(range, fov)
    local base = myHRP(); if not base then return nil end
    local cam = workspace.CurrentCamera
    local ctr = getFovCentre()
    local best, bestD = nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp and isEnemy(pl) and pl.Character then
            local hum = pl.Character:FindFirstChildWhichIsA("Humanoid")
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp and (hrp.Position - base.Position).Magnitude <= range then
                local sp, vis = cam:WorldToViewportPoint(hrp.Position)
                if vis then
                    local d = (Vector2.new(sp.X, sp.Y) - ctr).Magnitude
                    if d <= fov and d < bestD then bestD = d; best = pl.Character end
                end
            end
        end
    end
    return best
end

local function getClosestNPC(fov)
    local base = myHRP(); if not base then return nil end
    local container = workspace:FindFirstChild("Enemies"); if not container then return nil end
    local cam = workspace.CurrentCamera
    local ctr = getFovCentre()
    local best, bestD = nil, math.huge
    for _, npc in ipairs(container:GetChildren()) do
        if npc:IsA("Model") and not Players:GetPlayerFromCharacter(npc) then
            local hum = npc:FindFirstChildOfClass("Humanoid")
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                local sp, vis = cam:WorldToViewportPoint(hrp.Position)
                if vis then
                    local d = (Vector2.new(sp.X, sp.Y) - ctr).Magnitude
                    if d <= fov and d < bestD then bestD = d; best = npc end
                end
            end
        end
    end
    return best
end

local _sc = { lastTool = nil, tf = nil }
local function skillReady()
    local char = lp.Character; if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool"); if not tool then return false end
    if _sc.lastTool ~= tool then
        _sc.lastTool = tool
        local sf = lp:FindFirstChild("PlayerGui")
            and lp.PlayerGui:FindFirstChild("Main")
            and lp.PlayerGui.Main:FindFirstChild("Skills")
        _sc.tf = sf and sf:FindFirstChild(tool.Name) or nil
    end
    if not _sc.tf then return false end
    for _, k in ipairs({ "Z", "X", "C", "V" }) do
        local sk = _sc.tf:FindFirstChild(k)
        local cd = sk and sk:FindFirstChild("Cooldown")
        if cd and cd:IsA("Frame") and cd.Size.X.Scale == 0 then return true end
    end
    return false
end

-- ================================================================
--  VIM / STACK UD / LOADOUT & FOLLOW-UP ENGINE
-- ================================================================
local function sendKeyTap(kc, hold)
    hold = hold or 0.06
    if typeof(kc) == "EnumItem" and kc.EnumType == Enum.UserInputType then
        local loc = UserInputService:GetMouseLocation()
        VIM:SendMouseButtonEvent(loc.X, loc.Y, 0, true, game, 1)
        task.delay(hold, function()
            pcall(function()
                VIM:SendMouseButtonEvent(loc.X, loc.Y, 0, false, game, 1)
            end)
        end)
    elseif typeof(kc) == "EnumItem" and kc.EnumType == Enum.KeyCode then
        VIM:SendKeyEvent(true, kc, false, game)
        task.delay(hold, function()
            pcall(function()
                VIM:SendKeyEvent(false, kc, false, game)
            end)
        end)
    end
end

local function pressKey(kc, hold)
    sendKeyTap(kc, hold)
end

local _stackRunning = false
local _lastStackTick = 0
local function doStackUD()
    if _stackRunning then return end
    local hrp = myHRP(); if not hrp then return end
    _stackRunning = true
    local origin = hrp.CFrame
    pcall(function() hrp.CFrame = origin + Vector3.new(0, CFG.StackUDHeight, 0) end)
    task.delay(CFG.StackUDSpeed, function()
        pcall(function() hrp.CFrame = origin end)
        task.delay(CFG.StackUDSpeed, function() _stackRunning = false end)
    end)
end

local function maybeStackUD()
    if not CFG.StackUD then return end
    local now = tick()
    if now - _lastStackTick < 0.4 then return end
    _lastStackTick = now
    doStackUD()
end

local _followupRunning = false
local function executeLoadoutFollowup(force)
    if _followupRunning then return end
    if not force and not CFG.SoruFollowup then return end
    _followupRunning = true
    task.spawn(function()
        local ok, err = pcall(function()
            if CFG.FollowupDelay > 0 then
                task.wait(CFG.FollowupDelay)
            end

            local cat = CFG.FollowupCategory or "Fruit"
            local slotStr = CFG.LoadoutSlots and CFG.LoadoutSlots[cat]
            local slotKC = slotStr and SLOT_TO_KEYCODE[tostring(slotStr)]

            if slotKC then
                sendKeyTap(slotKC, 0.05)
                if CFG.FollowupSlotDelay > 0 then
                    task.wait(CFG.FollowupSlotDelay)
                end
            end

            if CFG.StackUD then
                doStackUD()
                if CFG.StackUDSpeed > 0 then
                    task.wait(CFG.StackUDSpeed)
                end
            end

            local paceExtra = 0
            if CFG.ExpHitstunPace then
                local cp = getClosestPlayer(120, 300)
                local hum = cp and cp:FindFirstChildOfClass("Humanoid")
                if hum and (hum:GetState() == Enum.HumanoidStateType.Freefall or hum:GetState() == Enum.HumanoidStateType.GettingUp) then
                    paceExtra = 0.02
                end
            end

            local skillName = tostring(CFG.FollowupSkill or "X"):upper()
            local skillKC = Enum.KeyCode[skillName]
            if skillKC then
                sendKeyTap(skillKC, 0.07)
            end

            task.wait(math.max(CFG.FollowupStepGap + paceExtra, 0.05))
        end)
        if not ok then
            warn("[test Followup Error]: " .. tostring(err))
        end
        _followupRunning = false
    end)
end

local function fireSoruFollowup()
    executeLoadoutFollowup(false)
end

-- ================================================================
--  KEN ENGINE
-- ================================================================
local HITBOX_NAMES = {
    HitBox = true, Hitbox = true, DmgPart = true, Hit = true,
    AttackHitbox = true, HitPart = true, DamagePart = true,
    ProjectileHit = true, SkillHit = true, Collider = true,
}
local ATTACK_ANIM_IDS = {
    [507766666] = true, [507766388] = true, [507766063] = true, [507766987] = true,
    [6395290806] = true, [6395291617] = true, [6395292316] = true,
    [4849836984] = true, [4849838704] = true,
    [10471449979] = true, [10471450598] = true, [10471451104] = true,
    [13062401247] = true, [13062402019] = true,
    [9064724891] = true, [9064725600] = true,
}
local SKILL_REMOTES = {
    useskill = true, skill = true, attack = true, usemove = true,
    action = true, m1 = true, click = true, swing = true,
}
local SORU_PATTERNS = { "flashstep", "soru", "teleport", "blink", "dash" }

local KEN_lock, KEN_last = false, 0
local kenConns = {}

local function fireKen()
    if KEN_lock then return end
    local now = tick()
    if now - KEN_last < CFG.KenCooldown then return end
    KEN_lock = true; KEN_last = now
    task.delay(CFG.KenReaction, function()
        pressKey(CFG.KenKey, 0.07)
        KEN_lock = false
    end)
end

local function dcKen(key)
    if not kenConns[key] then return end
    for _, c in ipairs(kenConns[key]) do pcall(c.Disconnect, c) end
    kenConns[key] = nil
end

local function hookChar(char)
    if not char then return end
    dcKen(char)
    local conns = {}
    kenConns[char] = conns
    local function inRange()
        local m = myHRP(); if not m then return false end
        local h = char:FindFirstChild("HumanoidRootPart"); if not h then return false end
        return (h.Position - m.Position).Magnitude <= CFG.KenRange
    end
    conns[#conns + 1] = char.ChildAdded:Connect(function(child)
        if not CFG.AutoKen or not inRange() then return end
        if HITBOX_NAMES[child.Name] or (child:IsA("BasePart") and child.Name:lower():find("hit", 1, true)) then
            fireKen()
        end
    end)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator") or char:FindFirstChildOfClass("Animator")
    if animator then
        conns[#conns + 1] = animator.AnimationPlayed:Connect(function(track)
            if not CFG.AutoKen or not inRange() then return end
            local id = tonumber(track.Animation.AnimationId:match("%d+"))
            if id and ATTACK_ANIM_IDS[id] then fireKen(); return end
            if track.Length > 0 and track.Length < 0.65 then fireKen() end
        end)
    end
    if hum then
        conns[#conns + 1] = hum.StateChanged:Connect(function(_, new)
            if not CFG.AutoKen or not inRange() then return end
            if new == Enum.HumanoidStateType.GettingUp or new == Enum.HumanoidStateType.FallingDown then
                fireKen()
            end
        end)
    end
end

local function hookPlayer(pl)
    if pl == lp then return end
    if pl.Character then hookChar(pl.Character) end
    kenConns[pl] = kenConns[pl] or {}
    kenConns[pl][#kenConns[pl] + 1] = pl.CharacterAdded:Connect(function(char)
        task.wait(0.12)
        hookChar(char)
    end)
end

local function unhookPlayer(pl)
    dcKen(pl)
    if pl.Character then dcKen(pl.Character) end
end

for _, pl in ipairs(Players:GetPlayers()) do hookPlayer(pl) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(unhookPlayer)

-- ================================================================
--  SORU, VISIBLE ICON COOLDOWN & AUTO SORU
-- ================================================================
local _soruAttrConn = nil
local autoSoruThread = nil

local function isSoruRemote(name)
    local low = name:lower()
    for _, p in ipairs(SORU_PATTERNS) do
        if low:find(p, 1, true) then return true end
    end
    return false
end

local function extendSoruTarget(cf)
    local base = myHRP(); if not base then return cf end
    local dir = cf.Position - base.Position
    local len = dir.Magnitude
    if len < 0.5 then return cf end
    return CFrame.new(base.Position + dir.Unit * (len * CFG.SoruDistMult)) * (cf - cf.Position)
end

local function enforceSoruAttr(char)
    if _soruAttrConn then _soruAttrConn:Disconnect(); _soruAttrConn = nil end
    if not char then return end
    if CFG.SoruInfinite then
        pcall(function() char:SetAttribute("FlashstepCooldown", 1) end)
    end
    if CFG.SoruDistance then
        pcall(function()
            local v = char:GetAttribute("MaxFlashstepDistance")
            if v and v > 0 then char:SetAttribute("MaxFlashstepDistance", v * CFG.SoruDistMult) end
        end)
    end
    _soruAttrConn = char.AttributeChanged:Connect(function(attr)
        if attr == "FlashstepCooldown" and CFG.SoruInfinite then
            pcall(function() char:SetAttribute("FlashstepCooldown", 1) end)
        elseif attr == "MaxFlashstepDistance" and CFG.SoruDistance then
            pcall(function()
                local v = char:GetAttribute("MaxFlashstepDistance")
                if v and v < 200 then char:SetAttribute("MaxFlashstepDistance", v * CFG.SoruDistMult) end
            end)
        end
    end)
end

lp.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    enforceSoruAttr(char)
end)
if lp.Character then
    task.spawn(function() task.wait(0.1); enforceSoruAttr(lp.Character) end)
end

task.spawn(function()
    local cycleDuration = 4.0
    while true do
        task.wait(0.08)
        if CFG.SoruInfinite and lp.Character then
            pcall(function() lp.Character:SetAttribute("FlashstepCooldown", 1) end)
        end
        if CFG.SoruInfinite and CFG.SoruVisualCD then
            pcall(function()
                local pg = lp:FindFirstChild("PlayerGui")
                local main = pg and pg:FindFirstChild("Main")
                if not main then return end
                local elapsed = (tick() - _soruFakeCdStart) % cycleDuration
                local frac = math.clamp(1 - (elapsed / cycleDuration), 0.05, 1)
                local secsLeft = math.max(1, math.ceil((1 - (elapsed / cycleDuration)) * cycleDuration))
                for _, desc in ipairs(main:GetDescendants()) do
                    local n = desc.Name:lower()
                    if n:find("soru", 1, true) or n:find("flashstep", 1, true) then
                        local cdFrame = desc:FindFirstChild("Cooldown", true)
                        if cdFrame and cdFrame:IsA("GuiObject") then
                            cdFrame.Visible = true
                            if cdFrame:IsA("Frame") then
                                cdFrame.Size = UDim2.new(cdFrame.Size.X.Scale, cdFrame.Size.X.Offset, frac, 0)
                            end
                        end
                        local cdLabel = desc:FindFirstChildWhichIsA("TextLabel", true)
                        if cdLabel then
                            cdLabel.Text = tostring(secsLeft) .. "s"
                            cdLabel.Visible = true
                        end
                    end
                end
            end)
        end
    end
end)

local function soruToTarget(targetPos)
    local char = lp.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end
    local startCF = hrp.CFrame
    local finalCF = (startCF - startCF.Position) + targetPos + Vector3.new(0, hrp.Size.Y * 1.5, 0)
    pcall(function()
        ReplicatedStorage.Remotes.CommE:FireServer(
            "Soru", startCF, finalCF,
            workspace:GetServerTimeNow(), math.random(1, 999999999)
        )
    end)
end

local function autoSoruLoop()
    while CFG.AutoSoru do
        pcall(function()
            local base = myHRP(); if not base then return end
            local best, bestD = nil, math.huge
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= lp and isEnemy(pl) and pl.Character then
                    local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                    local hum = pl.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local d = (hrp.Position - base.Position).Magnitude
                        if d < bestD then bestD = d; best = hrp end
                    end
                end
            end
            if best then soruToTarget((best.CFrame * CFrame.new(0, 0, 3)).Position) end
        end)
        task.wait(1)
    end
    autoSoruThread = nil
end

-- ================================================================
--  AURA, FRUIT M1 & AUTO SKILLS
-- ================================================================
local Net = pcall(function()
    return ReplicatedStorage:WaitForChild("Modules", 1):WaitForChild("Net", 1)
end) and ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
local RegisterAttack = Net and Net:FindFirstChild("RE/RegisterAttack")
local RegisterHit    = Net and Net:FindFirstChild("RE/RegisterHit")
local AuraState = { FoundRemote = nil, FoundRemoteId = nil }

task.spawn(function()
    local function checkChild(child)
        if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
            AuraState.FoundRemoteId = child:GetAttribute("Id")
            AuraState.FoundRemote = child
        end
    end
    for _, name in ipairs({ "Util", "Common", "Remotes", "Assets", "FX" }) do
        local folder = ReplicatedStorage:FindFirstChild(name)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do checkChild(child) end
            folder.ChildAdded:Connect(checkChild)
        end
    end
end)

local function getAuraTargets()
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    local targets = {}
    local myPos = root.Position
    local maxDist = CFG.ExpHitConfirmGate and 120 or 500
    local function collect(container, include)
        if not container or not include then return end
        for _, model in ipairs(container:GetChildren()) do
            if model ~= char then
                local tRoot = model:FindFirstChild("HumanoidRootPart")
                local tHum  = model:FindFirstChildOfClass("Humanoid")
                if tRoot and tHum and tHum.Health > 0 and (tRoot.Position - myPos).Magnitude < maxDist then
                    table.insert(targets, { Model = model, Root = tRoot, Head = model:FindFirstChild("Head") or tRoot })
                end
            end
        end
    end
    collect(workspace:FindFirstChild("Enemies"), CFG.FastAttackMobs)
    collect(workspace:FindFirstChild("Characters"), CFG.FastAttackPlayers)
    return targets
end

local function performAura()
    local char = lp.Character; if not char then return end
    if not (char:FindFirstChildOfClass("Tool") or char:FindFirstChild("EquippedWeapon")) then return end
    local targets = getAuraTargets(); if #targets == 0 then return end
    local main = targets[1]
    local hitList = {}
    for _, t in ipairs(targets) do table.insert(hitList, { t.Model, t.Root }) end
    if RegisterAttack and RegisterHit then
        pcall(function()
            RegisterAttack:FireServer(0)
            RegisterHit:FireServer(main.Head, hitList)
        end)
    end
    if CFG.FastAttackMode == "Mode2" and AuraState.FoundRemote and AuraState.FoundRemoteId then
        pcall(function()
            local RemoteSeed = Net and Net:FindFirstChild("seed")
            local seedValue = RemoteSeed and RemoteSeed:InvokeServer() or 1
            local encId = bit32.bxor(AuraState.FoundRemoteId + 909090, seedValue * 2)
            local rawName = "RE/RegisterHit"
            local ts = math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
            local encName = rawName:gsub(".", function(c)
                return string.char(bit32.bxor(string.byte(c), ts))
            end)
            AuraState.FoundRemote:FireServer(encName, encId, main.Head, hitList)
        end)
    end
end

task.spawn(function()
    while true do
        if CFG.FastAttackMobs or CFG.FastAttackPlayers then
            local t0 = tick()
            pcall(performAura)
            task.wait(math.max(0.05 - (tick() - t0), 0.001))
        else
            task.wait(0.3)
        end
    end
end)

local function getPlayerFruit()
    local char = lp.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Blox Fruit" then return tool end
        end
    end
    local bp = lp:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Blox Fruit" then return tool end
        end
    end
    return nil
end

local fruitM1Thread, voidM1Thread = nil, nil

local function startFruitM1()
    if fruitM1Thread then return end
    fruitM1Thread = task.spawn(function()
        while CFG.FruitM1 do
            task.wait(0.1)
            local fruit = getPlayerFruit()
            local remote = fruit and fruit:FindFirstChild("LeftClickRemote")
            local root = myHRP()
            if remote and root then
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= lp and isEnemy(pl) and pl.Character then
                        local tHRP = pl.Character:FindFirstChild("HumanoidRootPart")
                        local hum  = pl.Character:FindFirstChildOfClass("Humanoid")
                        if tHRP and hum and hum.Health > 0 and (tHRP.Position - root.Position).Magnitude < 500 then
                            pcall(function() remote:FireServer((tHRP.Position - root.Position).Unit, 1, true) end)
                        end
                    end
                end
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, npc in ipairs(enemies:GetChildren()) do
                        local tHRP = npc:FindFirstChild("HumanoidRootPart")
                        local hum  = npc:FindFirstChildOfClass("Humanoid")
                        if tHRP and hum and hum.Health > 0 and (tHRP.Position - root.Position).Magnitude < 500 then
                            pcall(function() remote:FireServer((tHRP.Position - root.Position).Unit, 1, true) end)
                        end
                    end
                end
            end
        end
        fruitM1Thread = nil
    end)
end

local function startVoidM1()
    if voidM1Thread then return end
    voidM1Thread = task.spawn(function()
        local voidVec = Vector3.new(9e30, 9e30, 9e30)
        while CFG.VoidFruitM1 do
            task.wait(0.3)
            local fruit = getPlayerFruit()
            local remote = fruit and fruit:FindFirstChild("LeftClickRemote")
            if remote then pcall(function() remote:FireServer(voidVec, 5, true) end) end
        end
        voidM1Thread = nil
    end)
end

task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
    local commF   = remotes and remotes:WaitForChild("CommF_", 5)
    while true do
        task.wait(2)
        if CFG.AutoHaki and commF and lp.Character and not lp.Character:FindFirstChild("HasBuso") then
            pcall(function() commF:InvokeServer("Buso") end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if CFG.AutoV3 then
            pcall(function()
                local commE = ReplicatedStorage.Remotes:FindFirstChild("CommE")
                if commE then commE:FireServer("ActivateAbility") end
            end)
        end
    end
end)

local function tryAwakenV4()
    pcall(function()
        local char = lp.Character; if not char then return end
        local energy      = char:FindFirstChild("RaceEnergy")
        local transformed = char:FindFirstChild("RaceTransformed")
        if not energy or energy.Value < 1 or not transformed or transformed.Value then return end
        local awakening = (lp:FindFirstChild("Backpack") and lp.Backpack:FindFirstChild("Awakening"))
            or char:FindFirstChild("Awakening")
        if awakening then awakening.RemoteFunction:InvokeServer(true) end
    end)
end

task.spawn(function()
    while true do
        task.wait(1)
        if CFG.AutoV4 then
            tryAwakenV4()
        end
        if CFG.ExpV4Emergency and lp.Character then
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and (hum.Health / math.max(hum.MaxHealth, 1)) <= 0.45 then
                tryAwakenV4()
            end
        end
    end
end)

task.spawn(function()
    local lastAt = 0
    while true do
        task.wait(1)
        if CFG.AutoKen and tick() - lastAt >= 2 then
            pcall(function()
                local char = lp.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if not char or not hum or hum.Health <= 0 or char:FindFirstChild("KenDisabled") then return end
                local blur = Lighting:FindFirstChild("Blur")
                if char:GetAttribute("KenActive") == true or (blur and blur.Enabled) then return end
                local commE = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommE")
                if commE and commE:IsA("RemoteEvent") then
                    lastAt = tick()
                    commE:FireServer("Ken", true)
                end
            end)
        end
    end
end)

-- ================================================================
--  AUTO FLEE / RAID
-- ================================================================
local fleeThread = nil
local fleeTriggered = false

local function hasRaidChip()
    for _, cont in ipairs({ lp.Character, lp:FindFirstChild("Backpack") }) do
        if cont then
            for _, t in ipairs(cont:GetChildren()) do
                if t:IsA("Tool") then
                    local n = t.Name:lower()
                    if n:find("chip", 1, true) or n:find("micro", 1, true) then return true end
                end
            end
        end
    end
    return false
end

local function triggerRaid()
    local map = workspace:FindFirstChild("Map"); if not map then return false end
    local holder = World3 and map:FindFirstChild("Boat Castle") or (World2 and map:FindFirstChild("CircleIsland"))
    local btn = holder and holder:FindFirstChild("RaidSummon2"); if not btn then return false end
    btn = btn:FindFirstChild("Button") or btn
    btn = btn:FindFirstChild("Main") or btn
    local det = btn:FindFirstChild("ClickDetector")
    if det and fireclickdetector then pcall(fireclickdetector, det); return true end
    local pr = btn:FindFirstChild("ProximityPrompt")
    if pr and fireproximityprompt then pcall(fireproximityprompt, pr); return true end
    return false
end

local function startAutoFlee()
    if fleeThread then return end
    fleeThread = task.spawn(function()
        while CFG.AutoFlee do
            task.wait(0.2)
            pcall(function()
                local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then return end
                local pct = (hum.Health / hum.MaxHealth) * 100
                if pct <= CFG.AutoFleeHP then
                    if not fleeTriggered then
                        fleeTriggered = true
                        if hasRaidChip() then triggerRaid() end
                    end
                else
                    fleeTriggered = false
                end
            end)
        end
        fleeThread = nil
        fleeTriggered = false
    end)
end

local function stopAutoFlee()
    CFG.AutoFlee = false
    fleeTriggered = false
    if fleeThread then task.cancel(fleeThread); fleeThread = nil end
end

-- ================================================================
--  EXPERIMENTAL HELPERS (10)
-- ================================================================
local _orbitAngle = 0
local function stepExperimentalFeatures(dt)
    local base = myHRP()
    local myHum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")

    if CFG.ExpAvatarSizeFlag then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp and pl.Character then
                local ok, sz = pcall(function() return pl.Character:GetExtentsSize() end)
                if ok and sz and sz.Magnitude > 22 then
                    if not OversizedPlayers[pl.Name] then
                        OversizedPlayers[pl.Name] = true
                        warn("[test experimental] Large avatar extents detected: " .. pl.Name .. " (" .. math.floor(sz.Magnitude) .. ")")
                    end
                else
                    OversizedPlayers[pl.Name] = nil
                end
            end
        end
    end

    if not base or not myHum or myHum.Health <= 0 then return end

    if CFG.ExpAuraShellOrbit then
        local cp = getClosestPlayer(160, 400)
        local tHRP = cp and cp:FindFirstChild("HumanoidRootPart")
        if tHRP then
            _orbitAngle = (_orbitAngle + dt * 3.2) % (math.pi * 2)
            local radius = 28
            local desired = tHRP.Position + Vector3.new(math.cos(_orbitAngle) * radius, 6, math.sin(_orbitAngle) * radius)
            local delta = desired - base.Position
            if delta.Magnitude > 0.5 then
                pcall(function()
                    base.CFrame = CFrame.new(base.Position + delta.Unit * math.min(delta.Magnitude, 3.5))
                end)
            end
        end
    end

    if CFG.ExpFlyDownDraft then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp and isEnemy(pl) and pl.Character then
                local tHRP = pl.Character:FindFirstChild("HumanoidRootPart")
                local tHum = pl.Character:FindFirstChildOfClass("Humanoid")
                if tHRP and tHum and tHum.Health > 0 then
                    local horiz = Vector2.new(tHRP.Position.X - base.Position.X, tHRP.Position.Z - base.Position.Z).Magnitude
                    local vertAbove = tHRP.Position.Y - base.Position.Y
                    if horiz <= 65 and vertAbove >= 14 then
                        pcall(function()
                            tHRP.AssemblyLinearVelocity = Vector3.new(tHRP.AssemblyLinearVelocity.X, -85, tHRP.AssemblyLinearVelocity.Z)
                        end)
                    end
                end
            end
        end
    end

    if CFG.ExpSecondFlyerSpace then
        local nearCount = 0
        local pushDir = Vector3.zero
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp and isEnemy(pl) and pl.Character then
                local tHRP = pl.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local diff = base.Position - tHRP.Position
                    local flat = Vector3.new(diff.X, 0, diff.Z)
                    if flat.Magnitude < 32 and flat.Magnitude > 0.1 then
                        nearCount = nearCount + 1
                        pushDir = pushDir + flat.Unit
                    end
                end
            end
        end
        if nearCount >= 2 and pushDir.Magnitude > 0.1 then
            pcall(function()
                base.CFrame = base.CFrame + pushDir.Unit * 1.4
            end)
        end
    end
end

-- ================================================================
--  MOVEMENT & MOVEMENT GLITCHES
-- ================================================================
local speedConn, speedWalkConn = nil, nil
local function applySpeed(hum)
    if hum and CFG.SpeedEnabled then hum.WalkSpeed = math.clamp(CFG.SpeedValue, 1, 2000) end
end
local function startSpeed()
    if speedConn then return end
    local function bind(char)
        local hum = char:WaitForChild("Humanoid", 5); if not hum then return end
        applySpeed(hum)
        if speedWalkConn then speedWalkConn:Disconnect() end
        speedWalkConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if CFG.SpeedEnabled and hum.Health > 0 then applySpeed(hum) end
        end)
    end
    speedConn = lp.CharacterAdded:Connect(bind)
    if lp.Character then bind(lp.Character) end
end
local function stopSpeed()
    if speedConn then speedConn:Disconnect(); speedConn = nil end
    if speedWalkConn then speedWalkConn:Disconnect(); speedWalkConn = nil end
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = 16 end
end

local jumpConn = nil
local function updateJump(hum)
    if not hum then return end
    if hum.UseJumpPower then hum.JumpPower = CFG.JumpEnabled and CFG.JumpValue or 50
    else hum.JumpHeight = CFG.JumpEnabled and CFG.JumpValue or 7.2 end
end
local function bindJump(hum)
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    local prop = hum.UseJumpPower and "JumpPower" or "JumpHeight"
    jumpConn = hum:GetPropertyChangedSignal(prop):Connect(function()
        if CFG.JumpEnabled then updateJump(hum) end
    end)
    updateJump(hum)
end
lp.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then bindJump(hum) end
end)
if lp.Character then
    local hum = lp.Character:FindFirstChildOfClass("Humanoid")
    if hum then bindJump(hum) end
end

local SJ = { running = false, last = 0, fns = {}, fnsSky = nil }
function SJ.Reset(char)
    if not (char and getgc and getupvalues and setupvalue) then return end
    local sky = char:FindFirstChild("Skyjump"); if not sky then return end
    if SJ.fnsSky ~= sky or #SJ.fns == 0 then
        SJ.fnsSky = sky; SJ.fns = {}
        for _, fn in next, getgc() do
            if typeof(fn) == "function" then
                local ok, env = pcall(getfenv, fn)
                if ok and env and env.script == sky then table.insert(SJ.fns, fn) end
            end
        end
    end
    for _, fn in ipairs(SJ.fns) do
        for i, uv in next, getupvalues(fn) do
            if type(uv) == "table" and uv.LastUse ~= nil then
                uv.LastUse = 0
            elseif type(uv) == "number" and uv >= 5 and uv <= 100 then
                pcall(setupvalue, fn, i, 0)
            end
        end
    end
end
function SJ.DoJump()
    if not CFG.InfiniteJump then return end
    local now = tick(); if now - SJ.last < 0.05 then return end; SJ.last = now
    local char = lp.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 or hum.Sit then return end
    SJ.Reset(char)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    local jp = hum.UseJumpPower and hum.JumpPower or math.sqrt(math.max(hum.JumpHeight or 7.2, 0) * 2 * workspace.Gravity)
    local vel = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, math.max(jp * 1.5, 50), vel.Z)
end
UserInputService.JumpRequest:Connect(SJ.DoJump)
function SJ.StartLoop()
    if SJ.running then return end; SJ.running = true
    task.spawn(function()
        while CFG.InfiniteJump do pcall(SJ.Reset, lp.Character); task.wait(0.1) end
        SJ.running = false
    end)
end

local NoclipState = { conn = nil, descConn = nil, char = nil, parts = {}, saved = {} }
local function noclipBind(char)
    for part in pairs(NoclipState.saved) do
        pcall(function() if part.Parent then part.CanCollide = true end end)
    end
    NoclipState.saved = {}; NoclipState.char = char; NoclipState.parts = {}
    if NoclipState.descConn then NoclipState.descConn:Disconnect() end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and d.CanCollide then
            NoclipState.saved[d] = true; d.CanCollide = false
            table.insert(NoclipState.parts, d)
        end
    end
    NoclipState.descConn = char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") and d.CanCollide then
            NoclipState.saved[d] = true; d.CanCollide = false
            table.insert(NoclipState.parts, d)
        end
    end)
end
local function startNoclip()
    if NoclipState.conn then return end
    if lp.Character then noclipBind(lp.Character) end
    NoclipState.conn = RunService.Stepped:Connect(function()
        local cur = lp.Character; if not cur then return end
        if cur ~= NoclipState.char then noclipBind(cur); return end
        for i = #NoclipState.parts, 1, -1 do
            local p = NoclipState.parts[i]
            if not p.Parent then table.remove(NoclipState.parts, i)
            elseif p.CanCollide then p.CanCollide = false end
        end
    end)
end
local function stopNoclip()
    if NoclipState.conn then NoclipState.conn:Disconnect(); NoclipState.conn = nil end
    if NoclipState.descConn then NoclipState.descConn:Disconnect(); NoclipState.descConn = nil end
    for part in pairs(NoclipState.saved) do
        pcall(function() if part.Parent then part.CanCollide = true end end)
    end
    NoclipState.char = nil; NoclipState.parts = {}; NoclipState.saved = {}
end

local FlyState = { on = false, att = nil, lv = nil, ao = nil, conn = nil, char = nil, hum = nil, root = nil }
local FlyControls = nil
local function getFlyControls()
    if FlyControls then return FlyControls end
    pcall(function()
        local pm = require(lp.PlayerScripts:WaitForChild("PlayerModule", 5))
        FlyControls = pm:GetControls()
    end)
    return FlyControls
end
local function clearFlyPhysics()
    if FlyState.att then FlyState.att:Destroy(); FlyState.att = nil end
    FlyState.lv = nil; FlyState.ao = nil
end
local function setupFly()
    FlyState.char = lp.Character or lp.CharacterAdded:Wait()
    FlyState.hum  = FlyState.char:WaitForChild("Humanoid")
    FlyState.root = FlyState.char:WaitForChild("HumanoidRootPart")
    clearFlyPhysics()
    if not FlyState.on then return end
    FlyState.hum.PlatformStand = true
    FlyState.att = Instance.new("Attachment"); FlyState.att.Parent = FlyState.root
    FlyState.lv = Instance.new("LinearVelocity")
    FlyState.lv.MaxForce = 9e9; FlyState.lv.VectorVelocity = Vector3.zero
    FlyState.lv.Attachment0 = FlyState.att; FlyState.lv.RelativeTo = Enum.ActuatorRelativeTo.World
    FlyState.lv.Parent = FlyState.att
    FlyState.ao = Instance.new("AlignOrientation")
    FlyState.ao.MaxTorque = 9e9; FlyState.ao.Responsiveness = 200
    FlyState.ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    FlyState.ao.Attachment0 = FlyState.att; FlyState.ao.Parent = FlyState.att
end
local function startFly()
    if FlyState.on then return end; FlyState.on = true; setupFly()
    if FlyState.conn then return end
    local controls = getFlyControls(); if not controls then return end
    FlyState.conn = RunService.RenderStepped:Connect(function()
        if not FlyState.on or not FlyState.root or not FlyState.lv or not FlyState.ao then return end
        local cam = workspace.CurrentCamera; if not cam then return end
        local mv = controls:GetMoveVector()
        local dir = Vector3.zero
        if mv.Magnitude > 0 then
            local raw = (cam.CFrame.LookVector * -mv.Z) + (cam.CFrame.RightVector * mv.X)
            if raw.Magnitude > 0.001 then dir = raw.Unit end
        end
        local tv = dir.Magnitude > 0 and (dir * CFG.FlySpeed) or Vector3.zero
        FlyState.lv.VectorVelocity = tv
        FlyState.root.AssemblyLinearVelocity = tv
        FlyState.ao.CFrame = cam.CFrame
    end)
end
local function stopFly()
    if not FlyState.on then return end; FlyState.on = false
    if FlyState.conn then FlyState.conn:Disconnect(); FlyState.conn = nil end
    if FlyState.hum then pcall(function() FlyState.hum.PlatformStand = false end) end
    clearFlyPhysics()
end

lp.CharacterAdded:Connect(function()
    task.wait(0.15)
    FlyState.char = lp.Character
    FlyState.hum  = FlyState.char and FlyState.char:FindFirstChildOfClass("Humanoid")
    FlyState.root = FlyState.char and FlyState.char:FindFirstChild("HumanoidRootPart")
    if FlyState.on then setupFly() end
end)

local function startDashNoCooldown()
    if not (getgc and getupvalues and setupvalue) then return end
    task.spawn(function()
        for _, v in next, getgc() do
            local char = lp.Character
            if char and char:FindFirstChild("Dodge") and typeof(v) == "function" then
                local ok, env = pcall(getfenv, v)
                if ok and env and env.script == char.Dodge then
                    for i2, v2 in next, getupvalues(v) do
                        if tostring(v2) == "0.4" then
                            task.spawn(function()
                                repeat setupvalue(v, i2, 0); task.wait(0.1) until not CFG.DodgeNoCooldown
                            end)
                        end
                    end
                end
            end
        end
    end)
end

local dashLenThread = nil
local function manageDashLength()
    if dashLenThread then task.cancel(dashLenThread); dashLenThread = nil end
    if CFG.DashLengthEnabled then
        dashLenThread = task.spawn(function()
            while CFG.DashLengthEnabled do
                task.wait(0.1)
                if lp.Character then
                    lp.Character:SetAttribute("DashLength", CFG.DashLength)
                    lp.Character:SetAttribute("DashLengthAir", CFG.DashLength)
                end
            end
        end)
    elseif lp.Character then
        lp.Character:SetAttribute("DashLength", 1)
        lp.Character:SetAttribute("DashLengthAir", 1)
    end
end

local walkWaterThread = nil
local function startWalkOnWater()
    if walkWaterThread then return end
    walkWaterThread = task.spawn(function()
        while CFG.WalkOnWater do
            task.wait(0.2)
            pcall(function()
                local wb = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WaterBase-Plane")
                if wb then wb.Size = Vector3.new(1000, 112, 1000) end
            end)
        end
        walkWaterThread = nil
    end)
end
local function stopWalkOnWater()
    CFG.WalkOnWater = false
    if walkWaterThread then task.cancel(walkWaterThread); walkWaterThread = nil end
    pcall(function()
        local wb = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WaterBase-Plane")
        if wb then wb.Size = Vector3.new(1000, 80, 1000) end
    end)
end

local function removeWaterTick()
    pcall(function()
        local wb = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WaterBase-Plane")
        if wb then wb:Destroy() end
    end)
end

-- Z Boost (Fling / Ragdoll engine)
local zBoostCfg = {
    power           = 0,
    launchDuration  = 0.05,
    ragdollDuration = 0.5,
    visualRagdoll   = true,
}
local isFlung = false

local function applyRagdoll(char)
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    if zBoostCfg.visualRagdoll then
        for _, j in ipairs(char:GetDescendants()) do
            if j:IsA("Motor6D") and j.Part0 and j.Part1 then
                local s  = Instance.new("BallSocketConstraint")
                local a0 = Instance.new("Attachment")
                local a1 = Instance.new("Attachment")
                a0.CFrame    = j.C0
                a1.CFrame    = j.C1
                a0.Parent    = j.Part0
                a1.Parent    = j.Part1
                s.Attachment0 = a0
                s.Attachment1 = a1
                s.Parent      = j.Parent
                j.Enabled     = false
            end
        end
    end
end

local function clearRagdoll(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BallSocketConstraint") then
            pcall(function()
                if v.Attachment0 then v.Attachment0:Destroy() end
                if v.Attachment1 then v.Attachment1:Destroy() end
                v:Destroy()
            end)
        end
    end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("Motor6D") then v.Enabled = true end
    end
    if hum and hum.Health > 0 then
        task.wait(0.05)
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
end

local function triggerZBoost()
    if isFlung then return end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root then return end
    isFlung = true

    local loc = UserInputService:GetMouseLocation()
    local cam = workspace.CurrentCamera
    local aimPos = root.Position + root.CFrame.LookVector * 10
    if cam then
        local ray = cam:ViewportPointToRay(loc.X, loc.Y)
        aimPos = ray.Origin + ray.Direction * 50
    end
    local delta = aimPos - root.Position
    local dir = delta.Magnitude > 0.001 and delta.Unit or root.CFrame.LookVector

    applyRagdoll(char)
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = dir * zBoostCfg.power
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.P = 1e4
    bv.Parent = root

    task.delay(zBoostCfg.launchDuration, function()
        pcall(function() bv:Destroy() end)
    end)
    task.delay(zBoostCfg.ragdollDuration, function()
        pcall(function() clearRagdoll(char) end)
        isFlung = false
    end)
end

-- Super Jump (~300 studs vertical launch)
local function triggerSuperJump()
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hrp or not hum or hum.Health <= 0 then return end
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    local targetUpSpeed = math.sqrt(math.max(2 * workspace.Gravity * (CFG.SuperJumpBoost or 300), 100))
    hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, targetUpSpeed, hrp.AssemblyLinearVelocity.Z)
end

-- Air Stall (3s zero-drop hold)
local function triggerAirStall()
    local hrp = myHRP(); if not hrp then return end
    local att = Instance.new("Attachment"); att.Name = "testStallAtt"; att.Parent = hrp
    local lv = Instance.new("LinearVelocity")
    lv.Name = "testStallLV"
    lv.MaxForce = 5e4
    lv.VectorVelocity = Vector3.zero
    lv.Attachment0 = att
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.Parent = att
    hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
    task.delay(3, function()
        pcall(function() lv:Destroy() end)
        pcall(function() att:Destroy() end)
    end)
end

-- ================================================================
--  WORLD MISC
-- ================================================================
local function removeLava()
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "Lava" then pcall(function() v:Destroy() end) end
        end
    end)
end

local function removeFog()
    pcall(function()
        Lighting.FogEnd = 9000000000
        local ll = Lighting:FindFirstChild("LightingLayers")
        if ll then ll:Destroy() end
    end)
end

local function applyCameraZoom()
    lp.CameraMaxZoomDistance = (CFG.CameraZoom and CFG.CameraZoom > 0) and CFG.CameraZoom or 128
    lp.CameraMinZoomDistance = 0.5
end

lp.CharacterAdded:Connect(function()
    isFlung = false
    task.wait(1)
    applyCameraZoom()
    if CFG.InfiniteJump then task.wait(1); SJ.StartLoop() end
    if CFG.DodgeNoCooldown then task.wait(1); startDashNoCooldown() end
end)

local bringMobsConn = nil
local function startBringMobs()
    if bringMobsConn then return end
    bringMobsConn = RunService.Heartbeat:Connect(function()
        if not CFG.BringMobs then return end
        pcall(function()
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end
            if sethiddenproperty then sethiddenproperty(lp, "SimulationRadius", math.huge) end
            local feet = hrp.Position - Vector3.new(0, 17, 0)
            local enemies = workspace:FindFirstChild("Enemies"); if not enemies then return end
            for _, enemy in ipairs(enemies:GetChildren()) do
                if enemy:IsA("Model") then
                    local eHRP = enemy:FindFirstChild("HumanoidRootPart")
                    local eHum = enemy:FindFirstChildOfClass("Humanoid")
                    if eHRP and eHum and eHum.Health > 0 and (eHRP.Position - feet).Magnitude <= 500 then
                        pcall(function() eHum.WalkSpeed = 0 end)
                        if (eHRP.Position - feet).Magnitude > 0.5 then eHRP.CFrame = CFrame.new(feet) end
                    end
                end
            end
        end)
    end)
end
local function stopBringMobs()
    CFG.BringMobs = false
    if bringMobsConn then bringMobsConn:Disconnect(); bringMobsConn = nil end
end

local clickJumpConn = nil
local function startClickJump()
    if clickJumpConn then return end
    clickJumpConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not CFG.ClickJump or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        pcall(function()
            local hrp = myHRP()
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            local cam = workspace.CurrentCamera
            if not hrp or not hum or hum.Health <= 0 or not cam then return end
            local loc = UserInputService:GetMouseLocation()
            local ray = cam:ViewportPointToRay(loc.X, loc.Y)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(hrp.Position + ray.Direction.Unit * 300)
        end)
    end)
end
local function stopClickJump()
    if clickJumpConn then clickJumpConn:Disconnect(); clickJumpConn = nil end
end

-- ================================================================
--  ESP
-- ================================================================
local espObjects = {}
local espRunning = false

local function createESP(pl)
    if pl == lp then return end
    local char = pl.Character
    local head = char and char:FindFirstChild("Head"); if not head then return end
    local bb = Instance.new("BillboardGui")
    bb.Adornee = head; bb.Size = UDim2.new(0, 220, 0, 130)
    bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true
    local lbl2 = Instance.new("TextLabel")
    lbl2.Size = UDim2.new(1, 0, 1, 0); lbl2.BackgroundTransparency = 1
    lbl2.TextScaled = false; lbl2.TextSize = CFG.ESP_TextSize
    lbl2.RichText = true; lbl2.Font = Enum.Font.SourceSansBold
    lbl2.TextStrokeTransparency = 0; lbl2.TextColor3 = Color3.new(1, 1, 1)
    lbl2.Parent = bb; bb.Parent = head

    local hl = nil
    if CFG.ESP_Highlight then
        hl = Instance.new("Highlight"); hl.Name = "ESP_HL"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = Color3.fromRGB(220, 20, 60); hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.fromRGB(255, 50, 80); hl.OutlineTransparency = 0
        hl.Parent = char
    end
    espObjects[pl] = { gui = bb, lbl = lbl2, char = char, hl = hl }
end

local function removeESP(pl)
    local d = espObjects[pl]; if not d then return end
    pcall(function() d.gui:Destroy() end)
    if d.hl then pcall(function() d.hl:Destroy() end) end
    espObjects[pl] = nil
end

local function updateESP()
    local myRoot = myHRP(); if not myRoot then return end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp then
            local char = pl.Character
            local head = char and char:FindFirstChild("Head")
            if char and head then
                if not espObjects[pl] or espObjects[pl].char ~= char then
                    removeESP(pl); createESP(pl)
                end
                local d = espObjects[pl]
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if d and hum and root then
                    local dist = math.floor((root.Position - myRoot.Position).Magnitude)
                    local hp   = math.floor((hum.Health / math.max(hum.MaxHealth, 1)) * 100)
                    local team = pl.Team and pl.Team.Name or "?"
                    local level, fruit, bounty = "?", "None", 0
                    pcall(function() level  = pl.Data.Level.Value end)
                    pcall(function() fruit  = pl.Data.DevilFruit.Value end)
                    pcall(function() bounty = pl.leaderstats["Bounty/Honor"].Value end)
                    local parts = {}
                    if CFG.ESP_Name     then table.insert(parts, "[" .. team .. "] " .. pl.Name) end
                    if CFG.ESP_Level    then table.insert(parts, "Lv." .. level) end
                    if CFG.ESP_Fruit    then table.insert(parts, "🍎 " .. fruit) end
                    if CFG.ESP_Bounty   then
                        local bs = bounty >= 1e6 and string.format("%.1fM", bounty / 1e6) or string.format("%.1fK", bounty / 1000)
                        table.insert(parts, "💰 " .. bs)
                    end
                    if CFG.ESP_Distance then table.insert(parts, dist .. "m") end
                    if CFG.ESP_HP       then table.insert(parts, "HP " .. hp .. "%") end
                    d.lbl.Text = table.concat(parts, "\n")
                    d.lbl.TextSize = CFG.ESP_TextSize
                end
            else
                removeESP(pl)
            end
        end
    end
end

local function enableESP()
    if espRunning then return end; espRunning = true
    for _, pl in ipairs(Players:GetPlayers()) do createESP(pl) end
    task.spawn(function()
        while espRunning do pcall(updateESP); task.wait(0.1) end
    end)
end

local function disableESP()
    espRunning = false
    for pl in pairs(espObjects) do removeESP(pl) end
    espObjects = {}
end

Players.PlayerRemoving:Connect(removeESP)

-- ================================================================
--  TELEPORT, CHASE & SERVER HOP
-- ================================================================
local ActiveTween = nil
local ChaseConn   = nil
local ChaseMode   = nil
local ChaseSpeed  = 180
local ChaseSample = nil
local ChaseLastSnap = 0
local ChaseTarget = nil

local function setNoCollide()
    local char = lp.Character; if not char then return end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("BasePart") then v.CanCollide = false end
    end
end

local function tweenTo(pos, speed)
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    local dist = (pos.Position - hrp.Position).Magnitude
    speed = math.max(tonumber(speed) or 180, 1)
    if ActiveTween then ActiveTween:Cancel() end
    ActiveTween = TweenService:Create(hrp, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), { CFrame = pos })
    local alive = true
    task.spawn(function()
        while alive and ActiveTween and ActiveTween.PlaybackState == Enum.PlaybackState.Playing do
            setNoCollide(); task.wait(0.001)
        end
    end)
    ActiveTween:Play()
    ActiveTween.Completed:Connect(function()
        alive = false
        if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
    end)
end

local function chaseStop()
    if ChaseConn then ChaseConn:Disconnect(); ChaseConn = nil end
    if ActiveTween then ActiveTween:Cancel(); ActiveTween = nil end
    ChaseMode = nil; ChaseSample = nil
end

local function chaseStart(mode)
    chaseStop(); ChaseMode = mode
    ChaseConn = RunService.Stepped:Connect(function()
        if not ChaseMode then return end
        local myRoot = myHRP()
        local myHum  = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if not myRoot or not myHum or myHum.Health <= 0 then return end
        local tH = nil
        if ChaseMode == "lock2" and ChaseTarget and ChaseTarget.Parent and ChaseTarget.Character then
            tH = ChaseTarget.Character:FindFirstChild("HumanoidRootPart")
        elseif ChaseMode == "nearest" then
            local bd = math.huge
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= lp and isEnemy(pl) and pl.Character then
                    local h  = pl.Character:FindFirstChild("HumanoidRootPart")
                    local hu = pl.Character:FindFirstChildOfClass("Humanoid")
                    if h and hu and hu.Health > 0 then
                        local d = (h.Position - myRoot.Position).Magnitude
                        if d < bd then bd = d; tH = h end
                    end
                end
            end
        end
        if not tH then return end
        local now = tick()
        local vel = Vector3.zero
        if ChaseSample then
            local dt = now - ChaseSample.t
            if dt > 0 and dt < 1 then vel = (tH.Position - ChaseSample.pos) / dt end
        end
        ChaseSample = { pos = tH.Position, t = now }
        local dist = (myRoot.Position - tH.Position).Magnitude
        if dist <= 70 then
            if ActiveTween then ActiveTween:Cancel() end
            if now - ChaseLastSnap >= 0.01 then
                ChaseLastSnap = now
                pcall(function() myRoot.CFrame = tH.CFrame + vel * 0.18 end)
            end
        else
            tweenTo(tH.CFrame, ChaseSpeed)
        end
    end)
end

local function serverHop(region, minP, maxP, minB, maxB)
    local browser = ReplicatedStorage:FindFirstChild("__ServerBrowser"); if not browser then return end
    task.spawn(function()
        local servers = {}
        for page = 1, 50 do
            local ok, res = pcall(function() return browser:InvokeServer(page) end)
            if ok and type(res) == "table" then
                for job, info in pairs(res) do
                    if type(info) == "table" then servers[job] = info end
                end
            end
            task.wait(0.02)
        end
        local matches = {}
        for job, info in pairs(servers) do
            if job ~= game.JobId then
                local r   = tostring(info.Region or ""):lower()
                local cnt = tonumber(info.Count) or 0
                local b   = tonumber(info.Bounty) or 0
                local rOk = region == "" or r:find(region:lower(), 1, true)
                if rOk and cnt >= minP and cnt <= maxP and b >= minB and b <= maxB then
                    table.insert(matches, { job = job, info = info })
                end
            end
        end
        if #matches == 0 then return end
        local pick = matches[math.random(1, #matches)]
        pcall(function() browser:InvokeServer("teleport", pick.job) end)
    end)
end

-- ================================================================
--  FOV CIRCLES & HEARTBEAT
-- ================================================================
local FOVCircle, GunFOVCircle = nil, nil
pcall(function()
    FOVCircle = Drawing.new("Circle"); FOVCircle.Visible = false
    FOVCircle.Color = Color3.fromRGB(220, 20, 60); FOVCircle.Thickness = 1.2
    FOVCircle.Filled = false; FOVCircle.Transparency = 1; FOVCircle.NumSides = 48
end)
pcall(function()
    GunFOVCircle = Drawing.new("Circle"); GunFOVCircle.Visible = false
    GunFOVCircle.Color = Color3.fromRGB(255, 65, 95); GunFOVCircle.Thickness = 1.0
    GunFOVCircle.Filled = false; GunFOVCircle.Transparency = 1; GunFOVCircle.NumSides = 48
end)

local _tick = 0
RunService.Heartbeat:Connect(function(dt)
    stepExperimentalFeatures(dt)
    _tick = _tick + dt; if _tick < 0.033 then return end; _tick = 0
    local ctr = getFovCentre()
    local mouseLoc = UserInputService:GetMouseLocation()
    local overlayAllowed = CFG.UIVisible and not (CFG.ScreenShareProof and _captureActive)
    if FOVCircle then
        FOVCircle.Position = ctr; FOVCircle.Radius = CFG.FovRadius
        FOVCircle.Visible = overlayAllowed and (CFG.SilentAimPlayers or CFG.SilentAimNPCs or CFG.SoruAim)
    end
    if GunFOVCircle then
        GunFOVCircle.Position = mouseLoc; GunFOVCircle.Radius = CFG.GunFovRadius
        GunFOVCircle.Visible = overlayAllowed and CFG.GunAim
    end
    if CFG.AutoKen then
        local base = myHRP()
        if base then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= lp and isEnemy(pl) and pl.Character then
                    local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - base.Position).Magnitude <= CFG.KenRange then
                        local v = getVel(hrp)
                        if Vector2.new(v.X, v.Z).Magnitude >= 50 then fireKen(); break end
                    end
                end
            end
        end
    end
    if not CFG.SilentAimPlayers and not CFG.SilentAimNPCs then
        AIM.pos = nil; AIM.rawPos = nil
    else
        local cp = CFG.SilentAimPlayers and getClosestPlayer(CFG.AimMaxRange, CFG.FovRadius) or nil
        local cn = CFG.SilentAimNPCs and getClosestNPC(CFG.FovRadius) or nil
        local pH = cp and (cp:FindFirstChild(CFG.HitPart) or cp:FindFirstChild("HumanoidRootPart"))
        local nH = cn and cn:FindFirstChild("HumanoidRootPart")
        local tp = pH or nH
        if tp then
            local vel = getVel(tp)
            local flyLead = (CFG.ExpFlyVectorLead and vel.Magnitude > 25) and (vel * 0.14) or Vector3.zero
            AIM.rawPos = tp.Position
            local computedPos = tp.Position
                + Vector3.new(vel.X * CFG.VelX, vel.Y * CFG.VelY, vel.Z * CFG.VelX)
                + flyLead
                + Vector3.new(CFG.OffsetX, CFG.OffsetY, CFG.OffsetZ)
            if CFG.ExpSmoothAimBlend and AIM.pos then
                AIM.pos = AIM.pos:Lerp(computedPos, 0.55)
            else
                AIM.pos = computedPos
            end
            if CFG.SilentAimPlayers and pH then
                local base = myHRP()
                if base and skillReady() then
                    if CFG.StackUD then maybeStackUD() end
                    local ap = AIM.pos
                    local ld = (Vector3.new(ap.X, base.Position.Y, ap.Z) - base.Position).Unit
                    pcall(function() base.CFrame = CFrame.new(base.Position, base.Position + ld) end)
                end
            end
        else
            AIM.pos = nil; AIM.rawPos = nil
        end
    end
    if CFG.SoruAim then
        local cl = getClosestPlayer(CFG.AimMaxRange, CFG.FovRadius)
        local hrp = cl and cl:FindFirstChild("HumanoidRootPart")
        if hrp then
            local slipOffset = CFG.ExpSoruBackSlip and (-hrp.CFrame.LookVector * 4) or Vector3.zero
            AIM.soruPos = hrp.Position + slipOffset
        else
            AIM.soruPos = nil
        end
    else
        AIM.soruPos = nil
    end
    if CFG.GunAim then
        local cl = getClosestPlayer(CFG.GunMaxRange, CFG.GunFovRadius)
        local hrp = cl and cl:FindFirstChild("HumanoidRootPart")
        if hrp then
            local gPos = hrp.Position + Vector3.new(CFG.OffsetX, CFG.OffsetY, CFG.OffsetZ)
            if CFG.ExpSmoothAimBlend and AIM.gunPos then
                AIM.gunPos = AIM.gunPos:Lerp(gPos, 0.55)
            else
                AIM.gunPos = gPos
            end
        else
            AIM.gunPos = nil
        end
    else
        AIM.gunPos = nil
    end
end)

-- ================================================================
--  METATABLE HOOKS
-- ================================================================
task.spawn(function()
    if not getrawmetatable or not getnamecallmethod or not newcclosure then return end
    local ok, mt = pcall(getrawmetatable, game); if not ok or not mt then return end
    local oldIdx = rawget(mt, "__index")
    local oldNC  = rawget(mt, "__namecall")
    local mouse  = lp:GetMouse()
    local function isMine() return checkcaller and checkcaller() or false end

    pcall(setreadonly, mt, false)
    rawset(mt, "__index", newcclosure(function(self, key)
        if not isMine() and self == mouse and (key == "Hit" or key == "Target") then
            if CFG.SoruAim and AIM.soruPos then
                local base = myHRP()
                if base and (base.Position - AIM.soruPos).Magnitude <= CFG.AimMaxRange then
                    local pos = AIM.soruPos + Vector3.new(CFG.OffsetX, CFG.OffsetY, CFG.OffsetZ)
                    if key == "Hit" then return CFrame.new(pos) end
                    if key == "Target" then return nil end
                end
            end
            if CFG.GunAim and AIM.gunPos then
                if key == "Hit" then return CFrame.new(AIM.gunPos) end
                if key == "Target" then return nil end
            end
        end
        return oldIdx(self, key)
    end))

    rawset(mt, "__namecall", newcclosure(function(self, ...)
        local args = { ... }
        local method = getnamecallmethod():lower()
        local isRemote = (method == "fireserver" or method == "invokeserver")
        if isRemote and not isMine() then
            local si = typeof(self) == "Instance" and self or nil
            local isSoruCall = false
            if si then
                if isSoruRemote(si.Name) and si:FindFirstAncestorOfClass("Model") == lp.Character then
                    isSoruCall = true
                elseif si.Name == "CommE" and tostring(args[1]) == "Soru" then
                    isSoruCall = true
                end
            end

            if isSoruCall then
                _soruFakeCdStart = tick()
                if CFG.SoruFollowup then
                    fireSoruFollowup()
                elseif CFG.StackUD then
                    doStackUD()
                end
                if CFG.SoruDistance then
                    local newArgs = {}
                    for i, arg in ipairs(args) do
                        if typeof(arg) == "CFrame" then
                            newArgs[i] = extendSoruTarget(arg)
                        elseif typeof(arg) == "Vector3" then
                            local base = myHRP()
                            if base then
                                local dir = arg - base.Position
                                local len = dir.Magnitude
                                newArgs[i] = len > 0.5 and (base.Position + dir.Unit * (len * CFG.SoruDistMult)) or arg
                            else
                                newArgs[i] = arg
                            end
                        else
                            newArgs[i] = arg
                        end
                    end
                    return oldNC(self, unpack(newArgs))
                end
            end

            if CFG.AutoKen and si then
                local rname = si.Name:lower()
                local matched = false
                for pat in pairs(SKILL_REMOTES) do
                    if rname:find(pat, 1, true) then matched = true; break end
                end
                if matched then
                    local ancestor = si:FindFirstAncestorOfClass("Model")
                    if ancestor and ancestor ~= lp.Character then
                        local base = myHRP()
                        local tHRP = ancestor:FindFirstChild("HumanoidRootPart")
                        if base and tHRP and (tHRP.Position - base.Position).Magnitude <= CFG.KenRange then
                            fireKen()
                        end
                    end
                end
            end

            if AIM.pos and (CFG.SilentAimPlayers or CFG.SilentAimNPCs) then
                local changed = false
                for i, arg in ipairs(args) do
                    if typeof(arg) == "Vector3" then args[i] = AIM.pos; changed = true end
                    if typeof(arg) == "CFrame" then args[i] = CFrame.new(AIM.pos); changed = true end
                end
                if changed then return oldNC(self, unpack(args)) end
            end
        end
        return oldNC(self, ...)
    end))
    pcall(setreadonly, mt, true)
end)

-- ================================================================
--  WINDUI (CRIMSON RED & BLACK)
-- ================================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local CRIMSON  = Color3.fromRGB(220, 20, 60)
local DARK_RED = Color3.fromRGB(130, 12, 32)
local PITCH    = Color3.fromRGB(10, 10, 12)

pcall(function()
    WindUI:AddTheme({
        Name = "ZyraCrimson",
        Accent = CRIMSON,
        Dialog = PITCH,
        Outline = DARK_RED,
        Text = Color3.fromRGB(245, 240, 242),
        Placeholder = Color3.fromRGB(150, 125, 130),
        Background = PITCH,
        Button = DARK_RED,
        Icon = CRIMSON,
    })
end)

local Window = WindUI:CreateWindow({
    Title = "test",
    Icon = "flame",
    Author = "Blox Fruits PVP",
    Folder = "test",
    Size = UDim2.fromOffset(560, 410),
    Transparent = true,
    Theme = "ZyraCrimson",
    SideBarWidth = 155,
    HasOutline = true,
})

local function toggleWindUI()
    CFG.UIVisible = not CFG.UIVisible
    if Window then
        if Window.Toggle then
            pcall(function() Window:Toggle() end)
        elseif CFG.UIVisible and Window.Open then
            pcall(function() Window:Open() end)
        elseif (not CFG.UIVisible) and Window.Close then
            pcall(function() Window:Close() end)
        end
    end
end

local function addCfgToggle(tab, cfgKey, title, desc, onChanged)
    local tgl = tab:Toggle({
        Title = title,
        Desc = desc or "",
        Default = CFG[cfgKey],
        Callback = function(state)
            CFG[cfgKey] = state
            if onChanged then onChanged(state) end
            scheduleAutoSave()
        end,
    })
    toggleCallbacks[cfgKey] = function()
        local nextVal = not CFG[cfgKey]
        CFG[cfgKey] = nextVal
        if tgl and tgl.Set then
            pcall(function() tgl:Set(nextVal) end)
        end
        if onChanged then onChanged(nextVal) end
        scheduleAutoSave()
    end
    uiSyncCallbacks[cfgKey] = function()
        if tgl and tgl.Set then pcall(function() tgl:Set(CFG[cfgKey]) end) end
        if onChanged then pcall(onChanged, CFG[cfgKey]) end
    end
    return tgl
end

local function addCfgSlider(tab, cfgKey, title, step, minVal, maxVal, onChanged)
    local sld = tab:Slider({
        Title = title,
        Step = step,
        Value = { Min = minVal, Max = maxVal, Default = CFG[cfgKey] },
        Callback = function(v)
            CFG[cfgKey] = v
            if onChanged then onChanged(v) end
            scheduleAutoSave()
        end,
    })
    uiSyncCallbacks[cfgKey] = function()
        if sld and sld.Set then pcall(function() sld:Set(CFG[cfgKey]) end) end
        if onChanged then pcall(onChanged, CFG[cfgKey]) end
    end
    return sld
end

local function addCfgDropdown(tab, cfgKey, title, values, onChanged)
    local dd = tab:Dropdown({
        Title = title,
        Values = values,
        Value = CFG[cfgKey],
        Callback = function(v)
            CFG[cfgKey] = v
            if onChanged then onChanged(v) end
            scheduleAutoSave()
        end,
    })
    uiSyncCallbacks[cfgKey] = function()
        if dd then
            if dd.Set then pcall(function() dd:Set(CFG[cfgKey]) end)
            elseif dd.Select then pcall(function() dd:Select(CFG[cfgKey]) end) end
        end
        if onChanged then pcall(onChanged, CFG[cfgKey]) end
    end
    return dd
end

local function syncAllUIFromConfig()
    _suppressAutoSave = true
    for _, fn in pairs(uiSyncCallbacks) do
        pcall(fn)
    end
    _suppressAutoSave = false
end

local function loadConfigFile(silent)
    if type(readfile) ~= "function" or type(isfile) ~= "function" or not isfile(CONFIG_FILE) then
        if not silent then warn("[test] No saved config file at " .. CONFIG_FILE) end
        return false
    end
    local ok, err = pcall(function()
        local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if type(decoded) ~= "table" then return end
        local rawCfg = type(decoded.CFG) == "table" and decoded.CFG or decoded
        for k, fb in pairs(CFG) do
            if rawCfg[k] ~= nil then
                CFG[k] = deserializeValue(rawCfg[k], fb)
            end
        end
        CFG.UIVisible = true
        if type(decoded.Whitelist) == "table" then
            Whitelist = decoded.Whitelist
        end
    end)
    if not ok then
        warn("[test] Config load error: " .. tostring(err))
        return false
    end
    syncAllUIFromConfig()
    if not silent then
        print("[test] Loaded config from " .. CONFIG_FILE)
    end
    return true
end

-- Tabs
local tAim     = Window:Tab({ Title = "Aim",               Icon = "crosshair" })
local tGun     = Window:Tab({ Title = "Gun",               Icon = "target" })
local tSoru    = Window:Tab({ Title = "Soru",              Icon = "zap" })
local tLoadout = Window:Tab({ Title = "loadout",           Icon = "layers" })
local tAura    = Window:Tab({ Title = "Aura",              Icon = "swords" })
local tMove    = Window:Tab({ Title = "Move",              Icon = "wind" })
local tGlitch  = Window:Tab({ Title = "movement glitches", Icon = "activity" })
local tExp     = Window:Tab({ Title = "experimental",      Icon = "flask-conical" })
local tWorld   = Window:Tab({ Title = "World",             Icon = "globe" })
local tESP     = Window:Tab({ Title = "ESP",               Icon = "eye" })
local tTP      = Window:Tab({ Title = "TP / Hop",          Icon = "navigation" })
local tKen     = Window:Tab({ Title = "Auto Ken",          Icon = "shield" })
local tWL      = Window:Tab({ Title = "Whitelist",         Icon = "user-check" })
local tConfig  = Window:Tab({ Title = "Config",            Icon = "save" })

-- AIM TAB
tAim:Section({ Title = "Silent Aim" })
addCfgToggle(tAim, "SilentAimPlayers", "Silent Aim Players [F1]", "Redirects remote position args on enemy players")
addCfgToggle(tAim, "SilentAimNPCs",    "Silent Aim NPCs [F2]",    "Redirects remote position args on NPCs/mobs")
addCfgDropdown(tAim, "HitPart", "Target Part", { "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso" })
do
    local fovDD = tAim:Dropdown({
        Title = "FOV Origin",
        Values = { "Mouse", "Centre" },
        Value = CFG.FovCentre and "Centre" or "Mouse",
        Callback = function(v)
            CFG.FovCentre = (v == "Centre")
            scheduleAutoSave()
        end,
    })
    uiSyncCallbacks["FovCentre"] = function()
        local label = CFG.FovCentre and "Centre" or "Mouse"
        if fovDD then
            if fovDD.Set then pcall(function() fovDD:Set(label) end)
            elseif fovDD.Select then pcall(function() fovDD:Select(label) end) end
        end
    end
end
addCfgSlider(tAim, "FovRadius",   "FOV Radius",        1,  10,  500)
addCfgSlider(tAim, "AimMaxRange", "Max Range (studs)", 10, 100, 5000)

tAim:Section({ Title = "Prediction & Offset" })
addCfgSlider(tAim, "VelX",    "Vel X/Z",  0.01, 0,   1)
addCfgSlider(tAim, "VelY",    "Vel Y",    0.01, 0,   1)
addCfgSlider(tAim, "OffsetX", "Offset X", 0.5,  -15, 15)
addCfgSlider(tAim, "OffsetY", "Offset Y", 0.5,  -15, 15)
addCfgSlider(tAim, "OffsetZ", "Offset Z", 0.5,  -15, 15)

-- GUN TAB
tGun:Section({ Title = "Gun Aimbot" })
addCfgToggle(tGun, "GunAim", "Gun Aimbot", "Redirects mouse.Hit to closest target in gun FOV")
addCfgSlider(tGun, "GunFovRadius", "Gun FOV Radius",        1,  10,  500)
addCfgSlider(tGun, "GunMaxRange",  "Gun Max Range (studs)", 10, 100, 5000)

-- SORU TAB
tSoru:Section({ Title = "Soru & Flashstep" })
addCfgToggle(tSoru, "SoruAim",      "Soru Aim [F3]",      "Targets closest player in FOV via mouse.Hit")
addCfgToggle(tSoru, "SoruInfinite", "Infinite Soru [F4]", "Keeps FlashstepCooldown at 1")
addCfgToggle(tSoru, "SoruVisualCD", "Visible Soru Icon Cooldown", "Keeps a visual cooldown indicator on the Soru icon during Infinite Soru")
addCfgToggle(tSoru, "SoruDistance", "Soru Distance Boost","Extends Soru/Flashstep distance")
addCfgSlider(tSoru, "SoruDistMult", "Distance Multiplier", 0.1, 1, 5)

tSoru:Section({ Title = "Stack UD & Follow-up" })
addCfgToggle(tSoru, "StackUD", "Stack UD", "Vertical CFrame hop on Soru/skills")
addCfgSlider(tSoru, "StackUDHeight", "Stack Height",    1,    2,    20)
addCfgSlider(tSoru, "StackUDSpeed",  "Stack Speed (s)", 0.01, 0.01, 0.15)
addCfgToggle(tSoru, "SoruFollowup", "Follow-up Combo", "Switches to configured category slot & fires follow-up skill after Soru")
addCfgSlider(tSoru, "FollowupDelay",     "Trigger Delay (s)",    0.01, 0,    0.5)
addCfgSlider(tSoru, "FollowupSlotDelay", "Slot Equip Delay (s)", 0.01, 0.02, 0.4)
addCfgSlider(tSoru, "FollowupStepGap",   "Step Gap (s)",         0.01, 0.02, 0.5)
tSoru:Button({
    Title = "Trigger Follow-Up Now",
    Desc = "Manually runs [Selected Slot] -> [Follow-up Skill]",
    Callback = function() executeLoadoutFollowup(true) end,
})

tSoru:Section({ Title = "Auto Soru" })
addCfgToggle(tSoru, "AutoSoru", "Auto Soru (CommE)", "Fires CommE Soru toward nearest enemy", function(on)
    if on and not autoSoruThread then autoSoruThread = task.spawn(autoSoruLoop) end
end)

-- LOADOUT TAB
tLoadout:Section({ Title = "Weapon Hotbar Slots (1-9, 0)" })
local slotChoices = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
local function addSlotDropdown(catKey, title)
    local dd = tLoadout:Dropdown({
        Title = title,
        Values = slotChoices,
        Value = CFG.LoadoutSlots[catKey],
        Callback = function(v)
            CFG.LoadoutSlots[catKey] = v
            scheduleAutoSave()
        end,
    })
    uiSyncCallbacks["Slot_" .. catKey] = function()
        if dd then
            if dd.Set then pcall(function() dd:Set(CFG.LoadoutSlots[catKey]) end)
            elseif dd.Select then pcall(function() dd:Select(CFG.LoadoutSlots[catKey]) end) end
        end
    end
end
addSlotDropdown("Fruit", "Devil Fruit Slot")
addSlotDropdown("Melee", "Melee Slot")
addSlotDropdown("Sword", "Sword Slot")
addSlotDropdown("Gun",   "Gun Slot")

tLoadout:Section({ Title = "Follow-Up Category & Skill" })
addCfgDropdown(tLoadout, "FollowupCategory",   "Follow-Up Weapon Category", { "Fruit", "Sword", "Melee", "Gun" })
addCfgDropdown(tLoadout, "FollowupSkill",      "Follow-Up Skill Move",      { "Z", "X", "C", "V", "F" })
addCfgDropdown(tLoadout, "FollowupTriggerKey", "Manual Follow-Up Keybind",  { "None", "T", "R", "F", "G", "V", "B" })
tLoadout:Button({
    Title = "Test Follow-Up Sequence",
    Desc = "Presses configured slot number then skill key",
    Callback = function() executeLoadoutFollowup(true) end,
})

-- AURA TAB
tAura:Section({ Title = "Fast Attack" })
addCfgDropdown(tAura, "FastAttackMode", "Attack Mode", { "Mode1", "Mode2" })
addCfgToggle(tAura, "FastAttackMobs",    "Fast Attack Mobs",    "Hits nearby NPCs/mobs")
addCfgToggle(tAura, "FastAttackPlayers", "Fast Attack Players", "Hits nearby players")

tAura:Section({ Title = "Fruit M1 & Auto Skills" })
addCfgToggle(tAura, "FruitM1",     "Fruit M1",      "Auto-fires Blox Fruit LeftClickRemote", function(on) if on then startFruitM1() end end)
addCfgToggle(tAura, "VoidFruitM1", "Void Fruit M1", "Sends void vector on LeftClickRemote", function(on) if on then startVoidM1() end end)
addCfgToggle(tAura, "AutoHaki",    "Auto Haki",     "Invokes Buso when missing")
addCfgToggle(tAura, "AutoV3",      "Auto V3",       "Fires CommE ActivateAbility")
addCfgToggle(tAura, "AutoV4",      "Auto V4",       "Invokes Awakening when energy is full")

tAura:Section({ Title = "Auto Flee" })
addCfgToggle(tAura, "AutoFlee", "Auto Flee (Raid)", "Triggers raid summon when HP is low", function(on)
    if on then startAutoFlee() else stopAutoFlee() end
end)
addCfgSlider(tAura, "AutoFleeHP", "Flee HP %", 1, 1, 100)

-- MOVE TAB
tMove:Section({ Title = "Speed & Jump" })
addCfgToggle(tMove, "SpeedEnabled", "Speed Hack", "Overrides Humanoid WalkSpeed", function(on) if on then startSpeed() else stopSpeed() end end)
addCfgSlider(tMove, "SpeedValue", "Walk Speed", 1, 1, 2000, function(v)
    if CFG.SpeedEnabled and lp.Character then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)
addCfgToggle(tMove, "JumpEnabled", "High Jump", "Overrides JumpPower / JumpHeight", function(on)
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        if on then updateJump(hum)
        elseif hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
    end
end)
addCfgSlider(tMove, "JumpValue", "Jump Power / Height", 1, 50, 500, function()
    if CFG.JumpEnabled and lp.Character then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then updateJump(hum) end
    end
end)
addCfgToggle(tMove, "InfiniteJump", "Infinite Jump", "Resets Skyjump cooldowns", function(on) if on then SJ.StartLoop() end end)

tMove:Section({ Title = "Noclip, Fly, Dash & Water" })
addCfgToggle(tMove, "Noclip", "Noclip", "Disables character part collisions", function(on) if on then startNoclip() else stopNoclip() end end)
addCfgToggle(tMove, "FlyEnabled", "Fly", "LinearVelocity flight", function(on) if on then startFly() else stopFly() end end)
addCfgSlider(tMove, "FlySpeed", "Fly Speed", 1, 1, 500)
addCfgToggle(tMove, "DodgeNoCooldown", "Dodge No Cooldown", "Zeroes Dodge cooldown upvalue", function(on) if on then startDashNoCooldown() end end)
addCfgToggle(tMove, "DashLengthEnabled", "Dash Length Override", "Sets DashLength attributes", function() manageDashLength() end)
addCfgSlider(tMove, "DashLength", "Dash Length", 1, 1, 20, function()
    if CFG.DashLengthEnabled then manageDashLength() end
end)
addCfgToggle(tMove, "WalkOnWater", "Walk on Water", "Expands WaterBase-Plane", function(on) if on then startWalkOnWater() else stopWalkOnWater() end end)
tMove:Button({ Title = "Remove Water Surface", Desc = "One-shot WaterBase-Plane removal", Callback = removeWaterTick })

-- MOVEMENT GLITCHES TAB
tGlitch:Section({ Title = "Ragdoll & Launch Glitches" })
tGlitch:Button({
    Title = "z boost",
    Desc = "Ragdoll/launch impulse (Power 0, 0.05s launch, 0.5s ragdoll | Key: G)",
    Callback = triggerZBoost,
})
tGlitch:Button({
    Title = "super jump",
    Desc = "Launches ~300 studs into the air (Default Key: H)",
    Callback = triggerSuperJump,
})
tGlitch:Dropdown({
    Title = "Super Jump Keybind",
    Values = { "H", "J", "K", "L", "U", "Y" },
    Value = CFG.SuperJumpKey.Name,
    Callback = function(keyName)
        if Enum.KeyCode[keyName] then
            CFG.SuperJumpKey = Enum.KeyCode[keyName]
            scheduleAutoSave()
        end
    end,
})
tGlitch:Button({
    Title = "air stall (3s)",
    Desc = "Holds vertical velocity near zero for 3 seconds mid-air",
    Callback = triggerAirStall,
})
tGlitch:Button({
    Title = "unragdoll / recover",
    Desc = "Restores Motor6D joints, clears constraints, and gets up",
    Callback = function()
        isFlung = false
        clearRagdoll(lp.Character)
    end,
})

-- EXPERIMENTAL TAB (10 FEATURES)
tExp:Section({ Title = "Experimental HvH & Anti-Aura" })
addCfgToggle(tExp, "ExpAuraShellOrbit",   "Aura Shell Orbit ( experimental )",   "Orbits around close target at ~28 studs offset")
addCfgToggle(tExp, "ExpAvatarSizeFlag",   "Oversized Avatar Flag ( experimental )", "Logs players with unusually large character extents")
addCfgToggle(tExp, "ExpFlyDownDraft",     "Fly Down-Draft Nudger ( experimental )", "Applies downward velocity nudge to high flyers nearby")
addCfgToggle(tExp, "ExpHitConfirmGate",   "Hit-Confirm Aura Gate ( experimental )", "Tightens aura candidate range to 120 studs")
addCfgToggle(tExp, "ExpFlyVectorLead",    "Fly Vector Lead ( experimental )",     "Adds forward velocity lead on fast airborne targets")
addCfgToggle(tExp, "ExpSoruBackSlip",     "Soru Back-Slip ( experimental )",      "Offsets Soru aim point slightly behind target look direction")
addCfgToggle(tExp, "ExpHitstunPace",      "Hitstun Cadence Pace ( experimental )",  "Adds slight step pacing when target is airborne/getting up")
addCfgToggle(tExp, "ExpV4Emergency",      "V4 Emergency Trigger ( experimental )",  "Attempts V4 awakening when HP drops to 45% or lower")
addCfgToggle(tExp, "ExpSecondFlyerSpace", "Second-Flyer Spacing ( experimental )",  "Pushes slightly away if 2+ enemies are close")
addCfgToggle(tExp, "ExpSmoothAimBlend",   "Smooth Aim Blend ( experimental )",    "Lerps aim target coordinates instead of snapping")

-- WORLD TAB
tWorld:Section({ Title = "Environment & Utilities" })
addCfgSlider(tWorld, "CameraZoom", "Camera Max Zoom", 10, 1, 2000, function() applyCameraZoom() end)
tWorld:Button({ Title = "Remove Lava", Desc = "Destroys Lava parts in workspace", Callback = removeLava })
tWorld:Button({ Title = "Remove Fog",  Desc = "Pushes FogEnd out and clears LightingLayers", Callback = removeFog })
addCfgToggle(tWorld, "BringMobs", "Bring Mobs", "Pulls nearby mobs below feet", function(on) if on then startBringMobs() else stopBringMobs() end end)
addCfgToggle(tWorld, "ClickJump", "Click Jump", "LMB dashes 300 studs along cursor ray", function(on) if on then startClickJump() else stopClickJump() end end)
tWorld:Button({
    Title = "Reduce Graphics",
    Desc = "Simplifies materials, particles, and decals",
    Callback = function()
        pcall(function()
            for _, d in ipairs(game:GetDescendants()) do
                if d:IsA("Part") or d:IsA("Union") then
                    d.Material = Enum.Material.Plastic; d.Reflectance = 0
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    d.Transparency = 1
                elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
                    d.Lifetime = NumberRange.new(0)
                elseif d:IsA("Fire") or d:IsA("SpotLight") or d:IsA("Smoke") then
                    d.Enabled = false
                end
            end
        end)
    end,
})
tWorld:Button({
    Title = "Unlock FPS",
    Desc = "Sets fps cap to 999 if supported",
    Callback = function() if setfpscap then setfpscap(999) end end,
})

-- ESP TAB
tESP:Section({ Title = "Player ESP" })
addCfgToggle(tESP, "ESPEnabled",    "ESP Enabled",    "Shows BillboardGui info on players", function(on) if on then enableESP() else disableESP() end end)
addCfgToggle(tESP, "ESP_Name",     "Show Name",      "")
addCfgToggle(tESP, "ESP_Level",    "Show Level",     "")
addCfgToggle(tESP, "ESP_Fruit",    "Show Fruit",     "")
addCfgToggle(tESP, "ESP_Bounty",   "Show Bounty",    "")
addCfgToggle(tESP, "ESP_Distance", "Show Distance",  "")
addCfgToggle(tESP, "ESP_HP",       "Show HP",        "")
addCfgToggle(tESP, "ESP_Highlight","Highlight ESP",  "Adds crimson Highlight to players", function()
    if CFG.ESPEnabled then disableESP(); enableESP() end
end)
addCfgSlider(tESP, "ESP_TextSize", "ESP Text Size", 1, 8, 32)

-- TP / HOP TAB
tTP:Section({ Title = "Target & Chase" })
local function getOtherPlayerNames()
    local out = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp then table.insert(out, pl.Name) end
    end
    return out
end
local tpDropdown = tTP:Dropdown({
    Title = "Select Target",
    Values = getOtherPlayerNames(),
    Callback = function(name)
        ChaseTarget = Players:FindFirstChild(name)
    end,
})
tTP:Button({
    Title = "Refresh Player List",
    Callback = function()
        if tpDropdown and tpDropdown.Refresh then
            pcall(function() tpDropdown:Refresh(getOtherPlayerNames(), true) end)
        end
    end,
})
tTP:Toggle({
    Title = "Lock 2 (Chase Selected)",
    Default = false,
    Callback = function(on)
        if on then
            if ChaseTarget then chaseStart("lock2") end
        else
            chaseStop()
        end
    end,
})
tTP:Toggle({
    Title = "Chase Nearest Enemy",
    Default = false,
    Callback = function(on)
        if on then chaseStart("nearest") else chaseStop() end
    end,
})
tTP:Slider({
    Title = "Chase / Tween Speed",
    Step = 5,
    Value = { Min = 10, Max = 500, Default = ChaseSpeed },
    Callback = function(v) ChaseSpeed = v end,
})

tTP:Section({ Title = "Teleport & Server Hop" })
local tpLocs = World2 and {
    ["Mansion"] = Vector3.new(-390, 332, 673),
    ["Swan Room"] = Vector3.new(2285, 15, 905),
    ["Ship Inside"] = Vector3.new(923, 126, 32852),
    ["Zombie Island"] = Vector3.new(-6509, 83, -133),
} or World3 and {
    ["Castle of the Sea"] = Vector3.new(-4999, 314, -3010),
    ["Floating Turtle"] = Vector3.new(-11352, 331, -10368),
    ["Mansion (W3)"] = Vector3.new(-12592, 336, -7470),
    ["Hydra Island"] = Vector3.new(5404, 1004, 506),
} or {}
for name, pos in pairs(tpLocs) do
    tTP:Button({
        Title = "TP: " .. name,
        Callback = function()
            local hrp = myHRP()
            if hrp then setNoCollide(); hrp.CFrame = CFrame.new(pos) end
        end,
    })
end

local hopRegion = "Singapore"
tTP:Dropdown({
    Title = "Hop Region",
    Values = { "Oregon", "Florida", "Singapore", "Germany", "Hong Kong", "Brazil", "California", "Texas" },
    Value = hopRegion,
    Callback = function(v) hopRegion = v end,
})
tTP:Button({
    Title = "Server Hop",
    Callback = function() serverHop(hopRegion, 1, 12, 0, 999999999) end,
})

-- KEN TAB
tKen:Section({ Title = "Auto Ken" })
addCfgToggle(tKen, "AutoKen", "Auto Ken [F5]", "5-layer detection + CommE Ken")
tKen:Dropdown({
    Title = "Ken Key",
    Values = { "Q", "E", "R", "G", "H", "V" },
    Value = CFG.KenKey.Name,
    Callback = function(k)
        if Enum.KeyCode[k] then
            CFG.KenKey = Enum.KeyCode[k]
            scheduleAutoSave()
        end
    end,
})
addCfgSlider(tKen, "KenRange",    "Ken Range (studs)",  1,    10,  150)
addCfgSlider(tKen, "KenReaction", "Reaction Delay (s)", 0.01, 0,   0.3)
addCfgSlider(tKen, "KenCooldown", "Cooldown (s)",       0.05, 0.1, 2.0)

-- WHITELIST TAB
tWL:Section({ Title = "Player Protection" })
local selectedWL = nil
local wlDropdown = tWL:Dropdown({
    Title = "Select Player",
    Values = getOtherPlayerNames(),
    Callback = function(name) selectedWL = name end,
})
tWL:Button({
    Title = "Refresh Players",
    Callback = function()
        if wlDropdown and wlDropdown.Refresh then
            pcall(function() wlDropdown:Refresh(getOtherPlayerNames(), true) end)
        end
    end,
})
tWL:Button({
    Title = "Whitelist Selected",
    Callback = function()
        if selectedWL then
            Whitelist[selectedWL] = true
            scheduleAutoSave()
        end
    end,
})
tWL:Button({
    Title = "Remove From Whitelist",
    Callback = function()
        if selectedWL then
            Whitelist[selectedWL] = nil
            scheduleAutoSave()
        end
    end,
})

-- CONFIG TAB
tConfig:Section({ Title = "Auto-Save, Auto-Exec & Stream Guard" })
addCfgToggle(tConfig, "AutoSaveConfig",   "Auto-Save Config",        "Automatically saves enabled options to test/config.json", function(on)
    if on then saveConfigFile(true) end
end)
addCfgToggle(tConfig, "AutoExec",         "Auto-Execute on Inject",  "Writes autoexec/test_AutoExec.lua & queues on teleport", function(on)
    syncAutoExec(on)
    saveConfigFile(true)
end)
addCfgToggle(tConfig, "ScreenShareProof", "Screen-Share Proof",      "Auto-enabled capture-signal guard for FOV overlays")
tConfig:Button({
    Title = "Cache Clipboard to test/cached_test.lua",
    Desc = "Copy full script first, then click so Auto-Exec has the script payload",
    Callback = cacheScriptFromClipboard,
})
tConfig:Button({
    Title = "Save Config Now",
    Desc = "Immediately writes settings & whitelist to test/config.json",
    Callback = function() saveConfigFile(false) end,
})
tConfig:Button({
    Title = "Load Config Now",
    Desc = "Reloads settings & whitelist from test/config.json",
    Callback = function() loadConfigFile(false) end,
})
if tConfig.Input then
    pcall(function()
        tConfig:Input({
            Title = "Hosted Script URL (Optional)",
            Placeholder = "https://raw.githubusercontent.com/...",
            Value = CFG.HostedScriptUrl,
            Callback = function(txt)
                CFG.HostedScriptUrl = tostring(txt or "")
                if CFG.AutoExec then syncAutoExec(true) end
                scheduleAutoSave()
            end,
        })
    end)
end

Players.PlayerRemoving:Connect(function(pl)
    if ChaseTarget == pl then ChaseTarget = nil end
    if selectedWL == pl.Name then selectedWL = nil end
    OversizedPlayers[pl.Name] = nil
end)

-- ================================================================
--  KEYBINDS & INIT
-- ================================================================
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == KB.ToggleUI then
        toggleWindUI()
        return
    end
    if i.KeyCode == CFG.ZBoostKey then
        triggerZBoost()
        return
    end
    if i.KeyCode == CFG.SuperJumpKey then
        triggerSuperJump()
        return
    end
    if CFG.FollowupTriggerKey and CFG.FollowupTriggerKey ~= "None" then
        local trigKC = Enum.KeyCode[CFG.FollowupTriggerKey]
        if trigKC and i.KeyCode == trigKC then
            executeLoadoutFollowup(true)
            return
        end
    end
    for cfgKey, kbKey in pairs(KB) do
        if i.KeyCode == kbKey and toggleCallbacks[cfgKey] then
            toggleCallbacks[cfgKey]()
            if cfgKey == "AutoKen" and CFG.AutoKen then
                for _, pl in ipairs(Players:GetPlayers()) do hookPlayer(pl) end
            end
            return
        end
    end
end)

loadConfigFile(true)
if CFG.AutoExec then
    syncAutoExec(true)
end
task.spawn(applyCameraZoom)
print("[test] Loaded | AutoSave=" .. tostring(CFG.AutoSaveConfig) .. " | AutoExec=" .. tostring(CFG.AutoExec) .. " | ScreenShareProof=" .. tostring(CFG.ScreenShareProof))