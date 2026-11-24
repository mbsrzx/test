-- ============================================================================
--  ZYVORA FARM v1  |  Auto-Level, Event Boss Hop & Auto-Exec Farming Suite
--  Theme: Classic Crimson Red & Obsidian Black
-- ============================================================================

repeat task.wait(0.2) until game:IsLoaded()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local GuiService        = game:GetService("GuiService")
local Stats             = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local WORLD_1 = game.PlaceId == 2753915549 or game.PlaceId == 85211729168715
local WORLD_2 = game.PlaceId == 4442272183 or game.PlaceId == 79091703265657
local WORLD_3 = game.PlaceId == 7449423635 or game.PlaceId == 100117331123089

local env = (type(getgenv) == "function" and getgenv()) or _G
if env.ZYVORA_FARM_V1 then
	pcall(function() env.ZYVORA_FARM_V1.Destroy() end)
end

-- ============================================================================
--  1. PATHS, AUTO-EXEC & CROSS-SERVER PERSISTENCE
-- ============================================================================
local CONFIG_DIR     = "ZyvoraFarmV1"
local CONFIG_FILE    = CONFIG_DIR .. "/default.json"
local BOSSHOP_FILE   = CONFIG_DIR .. "/boss_hop_state.json"
local CACHED_SCRIPT  = CONFIG_DIR .. "/cached_farm.lua"
local AUTOEXEC_DIR   = "autoexec"
local AUTOEXEC_FILE  = AUTOEXEC_DIR .. "/ZyvoraFarmV1_AutoExec.lua"

-- Optional: set your raw GitHub URL here if you host updates remotely.
-- If left empty, Auto-Exec & queue_on_teleport run the cached local build.
local HOSTED_SCRIPT_URL = ""

local function EnsureFolder(path)
	if type(isfolder) == "function" and type(makefolder) == "function" then
		pcall(function()
			if not isfolder(path) then makefolder(path) end
		end)
	end
end

local function BuildBootstrapSource()
	local urlLiteral = string.format("%q", HOSTED_SCRIPT_URL)
	local cacheLiteral = string.format("%q", CACHED_SCRIPT)
	return table.concat({
		"-- Zyvora Farm v1 Auto-Exec & Teleport Bootstrapper",
		"repeat task.wait(0.25) until game:IsLoaded()",
		"local url = " .. urlLiteral,
		"local cachePath = " .. cacheLiteral,
		"local src = nil",
		"if url ~= '' then",
		"    local ok, res = pcall(function() return game:HttpGet(url) end)",
		"    if ok and type(res) == 'string' and #res > 100 then src = res end",
		"end",
		"if (not src) and type(isfile) == 'function' and type(readfile) == 'function' and isfile(cachePath) then",
		"    local ok, res = pcall(readfile, cachePath)",
		"    if ok and type(res) == 'string' and #res > 100 then src = res end",
		"end",
		"if src then",
		"    local fn, err = loadstring(src)",
		"    if fn then task.spawn(fn) else warn('[Zyvora AutoExec] Compile error: ' .. tostring(err)) end",
		"end",
	}, "\n")
end

local function InstallAutoExecAndCache(rawSource)
	if type(writefile) ~= "function" then return false end
	EnsureFolder(CONFIG_DIR)
	EnsureFolder(AUTOEXEC_DIR)
	if type(rawSource) == "string" and #rawSource > 100 then
		pcall(writefile, CACHED_SCRIPT, rawSource)
	end
	local ok = pcall(writefile, AUTOEXEC_FILE, BuildBootstrapSource())
	return ok
end

local function QueueTeleportReExec()
	local qFn = (syn and syn.queue_on_teleport)
		or queue_on_teleport
		or (fluxus and fluxus.queue_on_teleport)
		or queueonteleport
	if type(qFn) == "function" then
		pcall(qFn, BuildBootstrapSource())
	end
end

-- ============================================================================
--  2. COMPLETE EVENT & RAID BOSS CATALOG (SEA 1, SEA 2, SEA 3)
-- ============================================================================
local BOSS_CATALOG = {
	-- Event & Raid Bosses (Cross-Sea / High Priority)
	{ Name = "Darkbeard",            Sea = 2, Category = "Event", Keywords = { "darkbeard", "blackbeard" },                  ArenaPos = Vector3.new(3777, 15, -3498) },
	{ Name = "rip_indra",            Sea = 3, Category = "Event", Keywords = { "rip_indra", "rip indra" },                   ArenaPos = Vector3.new(-5344, 424, -2725) },
	{ Name = "Dough King",           Sea = 3, Category = "Event", Keywords = { "dough king" },                                 ArenaPos = Vector3.new(-2151, 70, -12404) },
	{ Name = "Cake Prince",          Sea = 3, Category = "Event", Keywords = { "cake prince" },                                ArenaPos = Vector3.new(-2151, 70, -12404) },
	{ Name = "Soul Reaper",          Sea = 3, Category = "Event", Keywords = { "soul reaper" },                                ArenaPos = Vector3.new(-9524, 315, 6655) },
	{ Name = "Tyrant of the Skies",  Sea = 3, Category = "Event", Keywords = { "tyrant of the skies", "tyrant" },              ArenaPos = Vector3.new(-16540, 120, 1050) },
	{ Name = "Greybeard",            Sea = 1, Category = "Event", Keywords = { "greybeard", "whitebeard" },                  ArenaPos = Vector3.new(-5023, 28, 4332) },
	{ Name = "Cursed Captain",       Sea = 2, Category = "Event", Keywords = { "cursed captain" },                             ArenaPos = Vector3.new(916, 181, 33335) },
	{ Name = "Order",                Sea = 2, Category = "Event", Keywords = { "order" },                                      ArenaPos = Vector3.new(-6217, 28, -5053) },
	{ Name = "Core",                 Sea = 2, Category = "Event", Keywords = { "core" },                                       ArenaPos = Vector3.new(448, 199, -441) },
	{ Name = "Don Swan",             Sea = 2, Category = "Event", Keywords = { "don swan" },                                   ArenaPos = Vector3.new(2285, 15, 905) },
	{ Name = "Saber Expert",         Sea = 1, Category = "Event", Keywords = { "saber expert", "shanks" },                     ArenaPos = Vector3.new(-1458, 30, -51) },
	{ Name = "The Saw",              Sea = 1, Category = "Event", Keywords = { "the saw" },                                    ArenaPos = Vector3.new(-690, 15, 1583) },
	{ Name = "Leviathan",            Sea = 3, Category = "Event", Keywords = { "leviathan" },                                  ArenaPos = Vector3.new(-16500, 50, 1200) },
	{ Name = "Terrorshark",          Sea = 3, Category = "Event", Keywords = { "terrorshark" },                                ArenaPos = Vector3.new(-16500, 40, 1200) },
	{ Name = "Sea Beast",            Sea = 0, Category = "Event", Keywords = { "seabeast", "sea beast" },                      ArenaPos = Vector3.new(-5000, 35, -3000) },
	{ Name = "Elite Pirates",        Sea = 3, Category = "Event", Keywords = { "diablo", "deandre", "urban" },                 ArenaPos = Vector3.new(-5000, 314, -3010) },

	-- Sea 1 Standard Bosses
	{ Name = "The Gorilla King",     Sea = 1, Category = "Boss",  Keywords = { "gorilla king" },                               ArenaPos = Vector3.new(-1128, 6, -451) },
	{ Name = "Bobby",                Sea = 1, Category = "Boss",  Keywords = { "bobby" },                                      ArenaPos = Vector3.new(-1131, 14, 4357) },
	{ Name = "Yeti",                 Sea = 1, Category = "Boss",  Keywords = { "yeti" },                                       ArenaPos = Vector3.new(1185, 106, -1518) },
	{ Name = "Mob Leader",           Sea = 1, Category = "Boss",  Keywords = { "mob leader" },                                 ArenaPos = Vector3.new(-2848, 7, 5342) },
	{ Name = "Vice Admiral",         Sea = 1, Category = "Boss",  Keywords = { "vice admiral" },                               ArenaPos = Vector3.new(-4807, 21, 4360) },
	{ Name = "Warden",               Sea = 1, Category = "Boss",  Keywords = { "warden" },                                     ArenaPos = Vector3.new(5232, 5, 745) },
	{ Name = "Chief Warden",         Sea = 1, Category = "Boss",  Keywords = { "chief warden" },                               ArenaPos = Vector3.new(5232, 5, 745) },
	{ Name = "Swan",                 Sea = 1, Category = "Boss",  Keywords = { "swan" },                                       ArenaPos = Vector3.new(5232, 5, 745) },
	{ Name = "Magma Admiral",        Sea = 1, Category = "Boss",  Keywords = { "magma admiral" },                              ArenaPos = Vector3.new(-5694, 18, 8735) },
	{ Name = "Fishman Lord",         Sea = 1, Category = "Boss",  Keywords = { "fishman lord" },                               ArenaPos = Vector3.new(61350, 31, 1095) },
	{ Name = "Wysper",               Sea = 1, Category = "Boss",  Keywords = { "wysper" },                                     ArenaPos = Vector3.new(-7927, 5551, -637) },
	{ Name = "Thunder God",          Sea = 1, Category = "Boss",  Keywords = { "thunder god" },                                ArenaPos = Vector3.new(-7751, 5607, -2305) },
	{ Name = "Cyborg",               Sea = 1, Category = "Boss",  Keywords = { "cyborg" },                                     ArenaPos = Vector3.new(6138, 10, 3939) },

	-- Sea 2 Standard Bosses
	{ Name = "Diamond",              Sea = 2, Category = "Boss",  Keywords = { "diamond" },                                    ArenaPos = Vector3.new(-1569, 199, -31) },
	{ Name = "Jeremy",               Sea = 2, Category = "Boss",  Keywords = { "jeremy" },                                     ArenaPos = Vector3.new(2316, 449, 787) },
	{ Name = "Fajita",               Sea = 2, Category = "Boss",  Keywords = { "fajita" },                                     ArenaPos = Vector3.new(-2086, 73, -4208) },
	{ Name = "Smoke Admiral",        Sea = 2, Category = "Boss",  Keywords = { "smoke admiral" },                              ArenaPos = Vector3.new(-5078, 24, -5352) },
	{ Name = "Awakened Ice Admiral", Sea = 2, Category = "Boss",  Keywords = { "awakened ice admiral" },                       ArenaPos = Vector3.new(6473, 297, -6944) },
	{ Name = "Tide Keeper",          Sea = 2, Category = "Boss",  Keywords = { "tide keeper" },                                ArenaPos = Vector3.new(-3711, 77, -11469) },

	-- Sea 3 Standard Bosses
	{ Name = "Stone",                Sea = 3, Category = "Boss",  Keywords = { "stone" },                                      ArenaPos = Vector3.new(-1049, 40, 6791) },
	{ Name = "Island Empress",       Sea = 3, Category = "Boss",  Keywords = { "island empress" },                             ArenaPos = Vector3.new(5730, 602, 199) },
	{ Name = "Kilo Admiral",         Sea = 3, Category = "Boss",  Keywords = { "kilo admiral" },                               ArenaPos = Vector3.new(2889, 424, -7233) },
	{ Name = "Captain Elephant",     Sea = 3, Category = "Boss",  Keywords = { "captain elephant" },                           ArenaPos = Vector3.new(-13393, 319, -8423) },
	{ Name = "Beautiful Pirate",     Sea = 3, Category = "Boss",  Keywords = { "beautiful pirate" },                           ArenaPos = Vector3.new(5370, 22, -89) },
	{ Name = "Cake Queen",           Sea = 3, Category = "Boss",  Keywords = { "cake queen" },                                 ArenaPos = Vector3.new(-710, 382, -11150) },
	{ Name = "Longma",               Sea = 3, Category = "Boss",  Keywords = { "longma" },                                     ArenaPos = Vector3.new(-10218, 332, -9444) },
}

local BOSS_LOOKUP = {}
local BOSS_NAME_LIST = { "All Event Bosses", "All Bosses" }
for _, entry in ipairs(BOSS_CATALOG) do
	BOSS_LOOKUP[entry.Name] = entry
	table.insert(BOSS_NAME_LIST, entry.Name)
end

-- ============================================================================
--  3. CONFIGURATION TABLE
-- ============================================================================
local CFG = {
	-- Tab 1: Auto Level
	AutoLevel            = false,
	AutoQuest            = true,
	AutoUpgradeQuest     = true,
	QuestSkipPureMob     = false,
	BringMobs            = true,
	BringRadius          = 260,
	FarmHeight           = 18,
	FarmPositionMode     = "Above", -- "Above" | "Below" | "Behind" | "Orbit"
	OrbitSpeed           = 0.16,
	ClusterScoring       = true,
	BossPriority         = true,
	SkipStuckMobs        = true,
	StuckTimeout         = 8,
	SmoothStepMove       = true,
	StepMoveSpeed        = 24,
	AutoEquipSlot        = true,
	PreferredSlot        = "1",

	-- Tab 2: Boss Hop
	AutoBossHop          = false,
	BossHopTarget        = "Darkbeard",
	BossHopJoinGraceSec  = 3.5,
	BossHopAutoKillAura  = true,
	BossHopAutoSkills    = true,
	BossHopFlySpeed      = 280,
	HopAfterBossKill     = true,
	StopOnBossFound      = false,

	-- Tab 3: Combat & Skills
	FastAttackMobs       = false,
	FastAttackMode       = "Mode2",
	AttackDelay          = 0.06,
	AuraRadius           = 450,
	SplashTargetCap      = 12,
	AutoSkillRotation    = false,
	RotSkillZ            = true,
	RotSkillX            = true,
	RotSkillC            = true,
	RotSkillV            = false,
	RotSkillF            = false,
	CheckSkillCooldownUI = true,
	SkillCastDelay       = 0.35,
	LowEnergyPause       = true,
	AutoHaki             = false,
	AutoKen              = false,
	AutoV3               = false,
	AutoV4               = false,
	FaceTargetLock       = true,

	-- Tab 4: Mastery & Fruits
	FruitM1              = false,
	VoidFruitM1          = false,
	FruitM1Delay         = 0.12,
	MasteryAutoStop      = false,
	MasteryGoal          = 400,
	MasterySlotRotator   = false,
	MasteryRotateSec     = 6,
	RotSlot1             = true,
	RotSlot2             = true,
	RotSlot3             = true,
	RotSlot4             = false,
	AutoStoreFruit       = false,
	FruitSpawnScanner    = false,
	AutoCollectFruit     = false,
	FruitAlertBanner     = true,
	AutoRollFruit        = false,
	MinBeliReserve       = 500000,
	AutoBoneSurprise     = false,

	-- Tab 5: Chests & Materials
	AutoChestFarm        = false,
	ChestTierFilter      = "All",
	ChestHopWhenEmpty    = false,
	MaterialFilter       = "Any",
	MaterialGoalCount    = 100,
	MaterialAutoStop     = false,
	AutoSweepDrops       = false,
	FactoryCorePriority  = true,
	EliteHunterPriority  = true,
	SessionKillCounter   = true,
	AutoTouchOrbs        = false,
	ReturnFarmAfterChest = true,
	MaxChestRange        = 8000,

	-- Tab 6: Sea, Raids & TP
	AutoRaidTrigger      = false,
	AutoAwakenMove       = false,
	AutoBuyRaidChip      = false,
	RaidChipType         = "Flame",
	DetectMirage         = true,
	DetectKitsune        = true,
	DetectPrehistoric    = true,
	SeaAlertBanner       = true,
	WalkOnWater          = false,
	ExpandWaterPlane     = false,
	TweenTravelSpeed     = 240,

	-- Tab 7: Movement & Survivability
	SpeedEnabled         = false,
	SpeedValue           = 65,
	JumpEnabled          = false,
	JumpValue            = 65,
	InfiniteJump         = false,
	Noclip               = false,
	BoatNoclip           = false,
	FlyEnabled           = false,
	FlySpeed             = 95,
	SoruInfinite         = false,
	AutoFleeLowHP        = false,
	FleeHPThreshold      = 25,
	AntiVoidGuard        = true,
	AntiAFK              = true,
	HumanizedJitter      = true,
	PingAutoThrottle     = true,
	PingThrottleMs       = 250,
	AutoRejoinError      = false,
	CameraZoom           = 128,

	-- Tab 8: Farm ESP & GFX
	ESPEnabled           = false,
	ESP_Bosses           = true,
	ESP_Fruits           = true,
	ESP_Chests           = false,
	ESP_Distance         = true,
	ESP_HP               = true,
	ESP_TextSize         = 13,
	ESP_MaxDistance      = 4500,
	Fullbright           = false,
	PotatoGFX            = false,
	Disable3DRender      = false,
	FPSCapValue          = "240",

	-- Tab 9: Hop & Goals
	UseServerBrowser     = true,
	HopRegion            = "Any",
	HopMaxPlayers        = 10,
	AvoidVisitedJobs     = true,
	ScheduledStopEnabled = false,
	ScheduledStopMinutes = 120,
	TargetLevelStop      = false,
	TargetLevelGoal      = 2600,

	-- Tab 10: Config & Auto-Exec
	AutoExecEnabled      = true,
	AutoSaveConfig       = false,
	UIToggleKey          = "RightShift",
	HotkeyFarmPause      = true,
	HotkeyBossHopToggle  = true,
	HotkeyServerHop      = true,
	HotkeyPanicStop      = true,
	MiniHudVisible       = true,
	UIVisible            = true,
}

-- ============================================================================
--  4. RUNTIME STATE, TELEMETRY & BOSS HOP PERSISTENCE
-- ============================================================================
local Runtime = {
	Alive            = true,
	Connections      = {},
	Threads          = {},
	VisitedJobs      = {},
	StuckUntil       = {},
	CountedDeadMobs  = {},
	Logs             = {},
	UIControls       = {},
	WaterPad         = nil,
	ActiveTween      = nil,
	LastSafePos      = nil,
	ActiveQuestKey   = nil,
	JoinedServerAt   = os.clock(),
	StartClock       = os.clock(),
	StartBeli        = 0,
	StartFrags       = 0,
	StartLevel       = 1,
	SessionKills     = 0,
	SessionChests    = 0,
	BossKillsSession = 0,
	StatusText       = "Ready — Zyvora Farm v1",
	AlertText        = "",
	CommF            = nil,
	CommE            = nil,
	NetFolder        = nil,
	RegisterAttack   = nil,
	RegisterHit      = nil,
	FoundRemote      = nil,
	FoundRemoteId    = nil,
}

local function AddLog(msg)
	local line = ("[%s] %s"):format(os.date("%H:%M:%S"), tostring(msg))
	table.insert(Runtime.Logs, line)
	if #Runtime.Logs > 80 then table.remove(Runtime.Logs, 1) end
end

local function SetStatus(msg)
	Runtime.StatusText = tostring(msg)
end

local function SetAlert(msg)
	Runtime.AlertText = tostring(msg)
	if msg ~= "" then AddLog("ALERT: " .. tostring(msg)) end
end

local function TrackConn(c)
	if c then table.insert(Runtime.Connections, c) end
	return c
end

local function TrackThread(fn)
	local th = task.spawn(fn)
	table.insert(Runtime.Threads, th)
	return th
end

local function SaveBossHopState()
	if type(writefile) ~= "function" then return end
	EnsureFolder(CONFIG_DIR)
	pcall(function()
		writefile(BOSSHOP_FILE, HttpService:JSONEncode({
			AutoBossHop   = CFG.AutoBossHop,
			BossHopTarget = CFG.BossHopTarget,
			HopAfterKill  = CFG.HopAfterBossKill,
			VisitedJobs   = Runtime.VisitedJobs,
			BossKills     = Runtime.BossKillsSession,
		}))
	end)
end

local function RestoreBossHopState()
	if type(readfile) ~= "function" or type(isfile) ~= "function" or not isfile(BOSSHOP_FILE) then return end
	pcall(function()
		local parsed = HttpService:JSONDecode(readfile(BOSSHOP_FILE))
		if type(parsed) == "table" then
			if type(parsed.AutoBossHop) == "boolean" then CFG.AutoBossHop = parsed.AutoBossHop end
			if type(parsed.BossHopTarget) == "string" and parsed.BossHopTarget ~= "" then
				CFG.BossHopTarget = parsed.BossHopTarget
			end
			if type(parsed.HopAfterKill) == "boolean" then CFG.HopAfterBossKill = parsed.HopAfterKill end
			if type(parsed.VisitedJobs) == "table" then Runtime.VisitedJobs = parsed.VisitedJobs end
			if type(parsed.BossKills) == "number" then Runtime.BossKillsSession = parsed.BossKills end
			if CFG.AutoBossHop then
				AddLog("Resumed Boss Hop after server join -> Target: " .. CFG.BossHopTarget)
			end
		end
	end)
end

local function JitterWait(baseSec)
	local jitter = CFG.HumanizedJitter and (math.random(0, 35) / 1000) or 0
	local scale = 1
	if CFG.PingAutoThrottle then
		pcall(function()
			local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			if ping > CFG.PingThrottleMs then scale = 1.6 end
		end)
	end
	task.wait(math.max(baseSec * scale + jitter, 0.01))
end

-- ============================================================================
--  5. PLAYER, DATA, WORLD & REMOTE HELPERS
-- ============================================================================
local function GetChar() return LocalPlayer.Character end
local function GetHumanoid() local c = GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function GetHRP() local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local function GetCurrentSea()
	if WORLD_1 then return 1 end
	if WORLD_2 then return 2 end
	if WORLD_3 then return 3 end
	return 0
end

local function GetStatValue(name, fallback)
	local data = LocalPlayer:FindFirstChild("Data")
	local obj = data and data:FindFirstChild(name)
	if obj and (typeof(obj.Value) == "number" or typeof(obj.Value) == "string") then return obj.Value end
	return fallback
end

local function GetPlayerLevel() return tonumber(GetStatValue("Level", 1)) or 1 end
local function GetPlayerBeli()  return tonumber(GetStatValue("Beli", 0)) or 0 end
local function GetPlayerFrags() return tonumber(GetStatValue("Fragments", 0)) or 0 end

local function GetEquippedToolMastery()
	local char = GetChar()
	local tool = char and char:FindFirstChildOfClass("Tool")
	local lvl = tool and tool:FindFirstChild("Level")
	return (lvl and typeof(lvl.Value) == "number" and lvl.Value) or 0
end

local function IsValidEnemyModel(model)
	local char = GetChar()
	if not model or model == char or not model:IsA("Model") then return nil, nil end
	if Players:GetPlayerFromCharacter(model) then return nil, nil end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hrp and hrp:IsA("BasePart") and hum then
		if hum.Health <= 0 then
			if CFG.SessionKillCounter and not Runtime.CountedDeadMobs[model] then
				Runtime.CountedDeadMobs[model] = true
				Runtime.SessionKills += 1
			end
			return nil, nil
		end
		return hrp, hum
	end
	return nil, nil
end

local function DiscoverRemotes()
	pcall(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes then
			Runtime.CommF = remotes:FindFirstChild("CommF_")
			Runtime.CommE = remotes:FindFirstChild("CommE")
		end
		local modules = ReplicatedStorage:FindFirstChild("Modules")
		Runtime.NetFolder = (modules and modules:FindFirstChild("Net")) or ReplicatedStorage:FindFirstChild("Net", true)
		if Runtime.NetFolder then
			Runtime.RegisterAttack = Runtime.NetFolder:FindFirstChild("RE/RegisterAttack")
			Runtime.RegisterHit    = Runtime.NetFolder:FindFirstChild("RE/RegisterHit")
		end
		local function inspect(obj)
			if obj:IsA("RemoteEvent") and obj:GetAttribute("Id") ~= nil then
				Runtime.FoundRemote   = obj
				Runtime.FoundRemoteId = obj:GetAttribute("Id")
			end
		end
		for _, folderName in ipairs({ "Util", "Common", "Remotes", "Assets", "FX", "Net" }) do
			local f = ReplicatedStorage:FindFirstChild(folderName)
			if f then
				for _, d in ipairs(f:GetDescendants()) do inspect(d) end
				TrackConn(f.DescendantAdded:Connect(inspect))
			end
		end
	end)
end

-- ============================================================================
--  6. BOSS MATCHER (WORKSPACE.ENEMIES + REPLICATEDSTORAGE)
-- ============================================================================
local function ModelMatchesBossTarget(modelName, targetSelection)
	local low = modelName:lower()

	if targetSelection == "All Event Bosses" then
		for _, entry in ipairs(BOSS_CATALOG) do
			if entry.Category == "Event" then
				for _, kw in ipairs(entry.Keywords) do
					if low:find(kw, 1, true) then return true, entry end
				end
			end
		end
		return false, nil
	end

	if targetSelection == "All Bosses" then
		for _, entry in ipairs(BOSS_CATALOG) do
			for _, kw in ipairs(entry.Keywords) do
				if low:find(kw, 1, true) then return true, entry end
			end
		end
		return low:find("boss", 1, true) ~= nil, nil
	end

	local spec = BOSS_LOOKUP[targetSelection]
	if spec then
		for _, kw in ipairs(spec.Keywords) do
			if low:find(kw, 1, true) then return true, spec end
		end
		return false, spec
	end

	return low:find(targetSelection:lower(), 1, true) ~= nil, nil
end

-- Checks both live workspace.Enemies AND ReplicatedStorage (un-streamed bosses)
local function FindTargetBossEntity(targetSelection)
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		for _, model in ipairs(enemies:GetChildren()) do
			local mHRP, mHum = IsValidEnemyModel(model)
			if mHRP and mHum then
				local ok, spec = ModelMatchesBossTarget(model.Name, targetSelection)
				if ok then
					return {
						State = "Live",
						Model = model,
						HRP   = mHRP,
						Hum   = mHum,
						Pos   = mHRP.Position,
						Spec  = spec,
					}
				end
			end
		end
	end

	-- Check ReplicatedStorage for spawned bosses outside streaming radius
	for _, obj in ipairs(ReplicatedStorage:GetChildren()) do
		if obj:IsA("Model") then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			local r   = obj:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 then
				local ok, spec = ModelMatchesBossTarget(obj.Name, targetSelection)
				if ok then
					local arenaPos = (r and r.Position) or (spec and spec.ArenaPos)
					if arenaPos then
						return {
							State = "StreamedOut",
							Model = obj,
							HRP   = r,
							Hum   = hum,
							Pos   = arenaPos,
							Spec  = spec,
						}
					end
				end
			end
		end
	end

	return nil
end

-- ============================================================================
--  7. AUTO-LEVEL QUEST PROGRESSION TABLE
-- ============================================================================
local QUEST_PROFILES = {
	-- SEA 1
	{ Sea = 1, MinLv = 1,   QuestNpc = "Bandit Quest Giver",      QuestId = 1, Mob = "Bandit",              QuestPos = Vector3.new(1059, 16, 1544),   MobPos = Vector3.new(1145, 17, 1632) },
	{ Sea = 1, MinLv = 10,  QuestNpc = "JungleQuest",             QuestId = 1, Mob = "Monkey",              QuestPos = Vector3.new(-1598, 36, 153),   MobPos = Vector3.new(-1448, 22, 118) },
	{ Sea = 1, MinLv = 15,  QuestNpc = "JungleQuest",             QuestId = 2, Mob = "Gorilla",             QuestPos = Vector3.new(-1598, 36, 153),   MobPos = Vector3.new(-1225, 6, -485) },
	{ Sea = 1, MinLv = 30,  QuestNpc = "BuggyQuest1",             QuestId = 1, Mob = "Pirate",              QuestPos = Vector3.new(-1140, 4, 3829),    MobPos = Vector3.new(-1103, 13, 3896) },
	{ Sea = 1, MinLv = 40,  QuestNpc = "BuggyQuest1",             QuestId = 2, Mob = "Brute",               QuestPos = Vector3.new(-1140, 4, 3829),    MobPos = Vector3.new(-1145, 14, 4350) },
	{ Sea = 1, MinLv = 60,  QuestNpc = "DesertQuest",             QuestId = 1, Mob = "Desert Bandit",       QuestPos = Vector3.new(897, 6, 4388),     MobPos = Vector3.new(932, 7, 4484) },
	{ Sea = 1, MinLv = 75,  QuestNpc = "DesertQuest",             QuestId = 2, Mob = "Desert Officer",      QuestPos = Vector3.new(897, 6, 4388),     MobPos = Vector3.new(1572, 10, 4373) },
	{ Sea = 1, MinLv = 90,  QuestNpc = "SnowQuest",               QuestId = 1, Mob = "Snow Bandit",         QuestPos = Vector3.new(1386, 87, -1297),  MobPos = Vector3.new(1354, 87, -1393) },
	{ Sea = 1, MinLv = 100, QuestNpc = "SnowQuest",               QuestId = 2, Mob = "Snowman",             QuestPos = Vector3.new(1386, 87, -1297),  MobPos = Vector3.new(1189, 105, -1410) },
	{ Sea = 1, MinLv = 120, QuestNpc = "MarineQuest2",            QuestId = 1, Mob = "Chief Petty Officer", QuestPos = Vector3.new(-5035, 28, 4324),  MobPos = Vector3.new(-4855, 22, 4273) },
	{ Sea = 1, MinLv = 150, QuestNpc = "SkyQuest",                QuestId = 1, Mob = "Sky Bandit",          QuestPos = Vector3.new(-4841, 717, -2623),MobPos = Vector3.new(-4970, 294, -2890) },
	{ Sea = 1, MinLv = 175, QuestNpc = "SkyQuest",                QuestId = 2, Mob = "Dark Master",         QuestPos = Vector3.new(-4841, 717, -2623),MobPos = Vector3.new(-5220, 388, -2271) },
	{ Sea = 1, MinLv = 190, QuestNpc = "PrisonerQuest",           QuestId = 1, Mob = "Prisoner",            QuestPos = Vector3.new(5308, 1, 474),     MobPos = Vector3.new(5411, 96, 690) },
	{ Sea = 1, MinLv = 210, QuestNpc = "PrisonerQuest",           QuestId = 2, Mob = "Dangerous Prisoner",  QuestPos = Vector3.new(5308, 1, 474),     MobPos = Vector3.new(5411, 96, 690) },
	{ Sea = 1, MinLv = 250, QuestNpc = "ColosseumQuest",          QuestId = 1, Mob = "Toga Warrior",        QuestPos = Vector3.new(-1576, 7, -2983),  MobPos = Vector3.new(-1779, 8, -2733) },
	{ Sea = 1, MinLv = 275, QuestNpc = "ColosseumQuest",          QuestId = 2, Mob = "Gladiator",           QuestPos = Vector3.new(-1576, 7, -2983),  MobPos = Vector3.new(-1274, 8, -3188) },
	{ Sea = 1, MinLv = 300, QuestNpc = "MagmaQuest",              QuestId = 1, Mob = "Military Soldier",    QuestPos = Vector3.new(-5314, 12, 8515),  MobPos = Vector3.new(-5369, 61, 8556) },
	{ Sea = 1, MinLv = 325, QuestNpc = "MagmaQuest",              QuestId = 2, Mob = "Military Spy",        QuestPos = Vector3.new(-5314, 12, 8515),  MobPos = Vector3.new(-5787, 75, 8820) },
	{ Sea = 1, MinLv = 375, QuestNpc = "FishmanQuest",            QuestId = 1, Mob = "Fishman Warrior",     QuestPos = Vector3.new(61122, 18, 1569),  MobPos = Vector3.new(60844, 98, 1298) },
	{ Sea = 1, MinLv = 400, QuestNpc = "FishmanQuest",            QuestId = 2, Mob = "Fishman Commando",    QuestPos = Vector3.new(61122, 18, 1569),  MobPos = Vector3.new(61738, 64, 1433) },
	{ Sea = 1, MinLv = 450, QuestNpc = "SkyExp1Quest",            QuestId = 1, Mob = "God's Guard",         QuestPos = Vector3.new(-4721, 845, -1954),MobPos = Vector3.new(-4628, 866, -1931) },
	{ Sea = 1, MinLv = 475, QuestNpc = "SkyExp1Quest",            QuestId = 2, Mob = "Shanda",              QuestPos = Vector3.new(-7863, 5545, -379),MobPos = Vector3.new(-7685, 5566, -502) },
	{ Sea = 1, MinLv = 525, QuestNpc = "SkyExp2Quest",            QuestId = 1, Mob = "Royal Squad",         QuestPos = Vector3.new(-7903, 5635, -1410),MobPos = Vector3.new(-7654, 5637, -1407) },
	{ Sea = 1, MinLv = 550, QuestNpc = "SkyExp2Quest",            QuestId = 2, Mob = "Royal Soldier",       QuestPos = Vector3.new(-7903, 5635, -1410),MobPos = Vector3.new(-7760, 5679, -1884) },
	{ Sea = 1, MinLv = 625, QuestNpc = "FountainQuest",           QuestId = 1, Mob = "Galley Pirate",       QuestPos = Vector3.new(5258, 38, 4050),   MobPos = Vector3.new(5557, 152, 3998) },
	{ Sea = 1, MinLv = 650, QuestNpc = "FountainQuest",           QuestId = 2, Mob = "Galley Captain",      QuestPos = Vector3.new(5258, 38, 4050),   MobPos = Vector3.new(5677, 92, 4966) },

	-- SEA 2
	{ Sea = 2, MinLv = 700,  QuestNpc = "Area1Quest",             QuestId = 1, Mob = "Raider",              QuestPos = Vector3.new(-427, 73, 1836),   MobPos = Vector3.new(-746, 39, 2331) },
	{ Sea = 2, MinLv = 725,  QuestNpc = "Area1Quest",             QuestId = 2, Mob = "Mercenary",           QuestPos = Vector3.new(-427, 73, 1836),   MobPos = Vector3.new(-874, 141, 1312) },
	{ Sea = 2, MinLv = 775,  QuestNpc = "Area2Quest",             QuestId = 1, Mob = "Swan Pirate",         QuestPos = Vector3.new(635, 73, 918),     MobPos = Vector3.new(878, 121, 1235) },
	{ Sea = 2, MinLv = 800,  QuestNpc = "Area2Quest",             QuestId = 2, Mob = "Factory Staff",       QuestPos = Vector3.new(635, 73, 918),     MobPos = Vector3.new(295, 73, -56) },
	{ Sea = 2, MinLv = 875,  QuestNpc = "MarineQuest3",           QuestId = 1, Mob = "Marine Lieutenant",   QuestPos = Vector3.new(-2441, 73, -3219), MobPos = Vector3.new(-2552, 73, -3050) },
	{ Sea = 2, MinLv = 900,  QuestNpc = "MarineQuest3",           QuestId = 2, Mob = "Marine Captain",      QuestPos = Vector3.new(-2441, 73, -3219), MobPos = Vector3.new(-1695, 73, -3248) },
	{ Sea = 2, MinLv = 950,  QuestNpc = "ZombieQuest",            QuestId = 1, Mob = "Zombie",              QuestPos = Vector3.new(-5495, 48, -794),  MobPos = Vector3.new(-5634, 126, -697) },
	{ Sea = 2, MinLv = 975,  QuestNpc = "ZombieQuest",            QuestId = 2, Mob = "Vampire",             QuestPos = Vector3.new(-5495, 48, -794),  MobPos = Vector3.new(-6030, 6, -1313) },
	{ Sea = 2, MinLv = 1000, QuestNpc = "SnowMountainQuest",      QuestId = 1, Mob = "Snow Trooper",        QuestPos = Vector3.new(607, 401, -5371),  MobPos = Vector3.new(535, 401, -5329) },
	{ Sea = 2, MinLv = 1050, QuestNpc = "SnowMountainQuest",      QuestId = 2, Mob = "Winter Warrior",      QuestPos = Vector3.new(607, 401, -5371),  MobPos = Vector3.new(1223, 454, -5170) },
	{ Sea = 2, MinLv = 1100, QuestNpc = "IceSideQuest",           QuestId = 1, Mob = "Lab Subordinate",     QuestPos = Vector3.new(-6061, 15, -4904), MobPos = Vector3.new(-5769, 37, -4468) },
	{ Sea = 2, MinLv = 1125, QuestNpc = "IceSideQuest",           QuestId = 2, Mob = "Horned Warrior",      QuestPos = Vector3.new(-6061, 15, -4904), MobPos = Vector3.new(-6400, 24, -5818) },
	{ Sea = 2, MinLv = 1175, QuestNpc = "FireSideQuest",          QuestId = 1, Mob = "Magma Ninja",         QuestPos = Vector3.new(-5429, 15, -5297), MobPos = Vector3.new(-5296, 58, -4712) },
	{ Sea = 2, MinLv = 1200, QuestNpc = "FireSideQuest",          QuestId = 2, Mob = "Lava Pirate",         QuestPos = Vector3.new(-5429, 15, -5297), MobPos = Vector3.new(-4955, 58, -4656) },
	{ Sea = 2, MinLv = 1250, QuestNpc = "ShipQuest1",             QuestId = 1, Mob = "Ship Deckhand",       QuestPos = Vector3.new(1040, 125, 32909), MobPos = Vector3.new(1185, 125, 32979) },
	{ Sea = 2, MinLv = 1275, QuestNpc = "ShipQuest1",             QuestId = 2, Mob = "Ship Engineer",       QuestPos = Vector3.new(1040, 125, 32909), MobPos = Vector3.new(916, 44, 32974) },
	{ Sea = 2, MinLv = 1300, QuestNpc = "ShipQuest2",             QuestId = 1, Mob = "Ship Steward",        QuestPos = Vector3.new(971, 125, 33245),  MobPos = Vector3.new(915, 129, 33436) },
	{ Sea = 2, MinLv = 1325, QuestNpc = "ShipQuest2",             QuestId = 2, Mob = "Ship Officer",        QuestPos = Vector3.new(971, 125, 33245),  MobPos = Vector3.new(916, 181, 33335) },
	{ Sea = 2, MinLv = 1350, QuestNpc = "FrostQuest",             QuestId = 1, Mob = "Arctic Warrior",      QuestPos = Vector3.new(5668, 28, -6484),  MobPos = Vector3.new(5935, 77, -6472) },
	{ Sea = 2, MinLv = 1375, QuestNpc = "FrostQuest",             QuestId = 2, Mob = "Snow Lurker",         QuestPos = Vector3.new(5668, 28, -6484),  MobPos = Vector3.new(5628, 57, -6618) },
	{ Sea = 2, MinLv = 1425, QuestNpc = "ForgottenQuest",         QuestId = 1, Mob = "Sea Soldier",         QuestPos = Vector3.new(-3054, 236, -10147),MobPos = Vector3.new(-3185, 58, -9663) },
	{ Sea = 2, MinLv = 1450, QuestNpc = "ForgottenQuest",         QuestId = 2, Mob = "Water Fighter",       QuestPos = Vector3.new(-3054, 236, -10147),MobPos = Vector3.new(-3262, 298, -10552) },

	-- SEA 3
	{ Sea = 3, MinLv = 1500, QuestNpc = "PiratePortQuest",        QuestId = 1, Mob = "Pirate Millionaire",  QuestPos = Vector3.new(-290, 44, 5580),   MobPos = Vector3.new(-46, 44, 5638) },
	{ Sea = 3, MinLv = 1525, QuestNpc = "PiratePortQuest",        QuestId = 2, Mob = "Pistol Billionaire",  QuestPos = Vector3.new(-290, 44, 5580),   MobPos = Vector3.new(219, 105, 6018) },
	{ Sea = 3, MinLv = 1575, QuestNpc = "DragonCrewQuest",        QuestId = 1, Mob = "Dragon Crew Warrior", QuestPos = Vector3.new(6735, 126, -711),  MobPos = Vector3.new(6615, 51, -978) },
	{ Sea = 3, MinLv = 1600, QuestNpc = "DragonCrewQuest",        QuestId = 2, Mob = "Dragon Crew Archer",  QuestPos = Vector3.new(6735, 126, -711),  MobPos = Vector3.new(6818, 483, 512) },
	{ Sea = 3, MinLv = 1625, QuestNpc = "VenomCrewQuest",         QuestId = 1, Mob = "Female Islander",     QuestPos = Vector3.new(5446, 601, 751),   MobPos = Vector3.new(4685, 720, 814) },
	{ Sea = 3, MinLv = 1650, QuestNpc = "VenomCrewQuest",         QuestId = 2, Mob = "Giant Islander",      QuestPos = Vector3.new(5446, 601, 751),   MobPos = Vector3.new(4902, 670, 39) },
	{ Sea = 3, MinLv = 1700, QuestNpc = "MarineTreeIsland",       QuestId = 1, Mob = "Marine Commodore",    QuestPos = Vector3.new(2179, 28, -6740),  MobPos = Vector3.new(2498, 190, -7160) },
	{ Sea = 3, MinLv = 1725, QuestNpc = "MarineTreeIsland",       QuestId = 2, Mob = "Marine Rear Admiral", QuestPos = Vector3.new(2179, 28, -6740),  MobPos = Vector3.new(3951, 229, -6912) },
	{ Sea = 3, MinLv = 1775, QuestNpc = "DeepForestIsland3",      QuestId = 1, Mob = "Fishman Raider",      QuestPos = Vector3.new(-10583, 331, -8757),MobPos = Vector3.new(-10553, 521, -8176) },
	{ Sea = 3, MinLv = 1800, QuestNpc = "DeepForestIsland3",      QuestId = 2, Mob = "Fishman Captain",     QuestPos = Vector3.new(-10583, 331, -8757),MobPos = Vector3.new(-10789, 389, -9140) },
	{ Sea = 3, MinLv = 1825, QuestNpc = "DeepForestIsland",       QuestId = 1, Mob = "Forest Pirate",       QuestPos = Vector3.new(-13232, 332, -7626),MobPos = Vector3.new(-13489, 400, -7770) },
	{ Sea = 3, MinLv = 1850, QuestNpc = "DeepForestIsland",       QuestId = 2, Mob = "Mythological Pirate", QuestPos = Vector3.new(-13232, 332, -7626),MobPos = Vector3.new(-13508, 582, -6985) },
	{ Sea = 3, MinLv = 1900, QuestNpc = "DeepForestIsland2",      QuestId = 1, Mob = "Jungle Pirate",       QuestPos = Vector3.new(-12682, 390, -9902),MobPos = Vector3.new(-12266, 389, -10498) },
	{ Sea = 3, MinLv = 1925, QuestNpc = "DeepForestIsland2",      QuestId = 2, Mob = "Musketeer Pirate",    QuestPos = Vector3.new(-12682, 390, -9902),MobPos = Vector3.new(-13291, 520, -9904) },
	{ Sea = 3, MinLv = 1975, QuestNpc = "HauntedQuest1",          QuestId = 1, Mob = "Reborn Skeleton",     QuestPos = Vector3.new(-9480, 142, 5567), MobPos = Vector3.new(-8761, 183, 6168) },
	{ Sea = 3, MinLv = 2000, QuestNpc = "HauntedQuest1",          QuestId = 2, Mob = "Living Zombie",       QuestPos = Vector3.new(-9480, 142, 5567), MobPos = Vector3.new(-10103, 238, 6179) },
	{ Sea = 3, MinLv = 2025, QuestNpc = "HauntedQuest2",          QuestId = 1, Mob = "Demonic Soul",        QuestPos = Vector3.new(-9516, 178, 6078), MobPos = Vector3.new(-9712, 204, 6193) },
	{ Sea = 3, MinLv = 2050, QuestNpc = "HauntedQuest2",          QuestId = 2, Mob = "Posessed Mummy",      QuestPos = Vector3.new(-9516, 178, 6078), MobPos = Vector3.new(-9533, 6, 6375) },
	{ Sea = 3, MinLv = 2075, QuestNpc = "NutsIslandQuest",        QuestId = 1, Mob = "Peanut Scout",        QuestPos = Vector3.new(-2105, 37, -10195),MobPos = Vector3.new(-2150, 122, -10358) },
	{ Sea = 3, MinLv = 2100, QuestNpc = "NutsIslandQuest",        QuestId = 2, Mob = "Peanut President",    QuestPos = Vector3.new(-2105, 37, -10195),MobPos = Vector3.new(-2150, 122, -10358) },
	{ Sea = 3, MinLv = 2125, QuestNpc = "IceCreamIslandQuest",    QuestId = 1, Mob = "Ice Cream Chef",      QuestPos = Vector3.new(-819, 64, -10967), MobPos = Vector3.new(-789, 209, -11009) },
	{ Sea = 3, MinLv = 2150, QuestNpc = "IceCreamIslandQuest",    QuestId = 2, Mob = "Ice Cream Commander", QuestPos = Vector3.new(-819, 64, -10967), MobPos = Vector3.new(-789, 209, -11009) },
	{ Sea = 3, MinLv = 2200, QuestNpc = "CakeQuest1",             QuestId = 1, Mob = "Cookie Crafter",      QuestPos = Vector3.new(-2022, 36, -12030),MobPos = Vector3.new(-2321, 36, -12216) },
	{ Sea = 3, MinLv = 2225, QuestNpc = "CakeQuest1",             QuestId = 2, Mob = "Cake Guard",          QuestPos = Vector3.new(-2022, 36, -12030),MobPos = Vector3.new(-1418, 36, -12255) },
	{ Sea = 3, MinLv = 2250, QuestNpc = "CakeQuest2",             QuestId = 1, Mob = "Baking Staff",        QuestPos = Vector3.new(-1928, 37, -12840),MobPos = Vector3.new(-1980, 36, -12983) },
	{ Sea = 3, MinLv = 2275, QuestNpc = "CakeQuest2",             QuestId = 2, Mob = "Head Baker",          QuestPos = Vector3.new(-1928, 37, -12840),MobPos = Vector3.new(-2251, 52, -13033) },
	{ Sea = 3, MinLv = 2300, QuestNpc = "ChocQuest1",             QuestId = 1, Mob = "Cocoa Warrior",       QuestPos = Vector3.new(231, 23, -12200),  MobPos = Vector3.new(167, 26, -12238) },
	{ Sea = 3, MinLv = 2325, QuestNpc = "ChocQuest1",             QuestId = 2, Mob = "Chocolate Bar Battler",QuestPos = Vector3.new(231, 23, -12200), MobPos = Vector3.new(701, 25, -12708) },
	{ Sea = 3, MinLv = 2350, QuestNpc = "ChocQuest2",             QuestId = 1, Mob = "Sweet Thief",         QuestPos = Vector3.new(151, 23, -12774),  MobPos = Vector3.new(-140, 25, -12652) },
	{ Sea = 3, MinLv = 2375, QuestNpc = "ChocQuest2",             QuestId = 2, Mob = "Candy Rebel",         QuestPos = Vector3.new(151, 23, -12774),  MobPos = Vector3.new(47, 25, -13029) },
	{ Sea = 3, MinLv = 2400, QuestNpc = "CandyQuest1",            QuestId = 1, Mob = "Candy Pirate",        QuestPos = Vector3.new(-1148, 13, -14446),MobPos = Vector3.new(-1437, 17, -14385) },
	{ Sea = 3, MinLv = 2425, QuestNpc = "CandyQuest1",            QuestId = 2, Mob = "Snow Demon",          QuestPos = Vector3.new(-1148, 13, -14446),MobPos = Vector3.new(-916, 17, -14638) },
	{ Sea = 3, MinLv = 2450, QuestNpc = "TikiQuest1",             QuestId = 1, Mob = "Isle Outlaw",         QuestPos = Vector3.new(-16547, 55, -172), MobPos = Vector3.new(-16431, 116, -264) },
	{ Sea = 3, MinLv = 2475, QuestNpc = "TikiQuest1",             QuestId = 2, Mob = "Island Boy",          QuestPos = Vector3.new(-16547, 55, -172), MobPos = Vector3.new(-16849, 84, -172) },
	{ Sea = 3, MinLv = 2500, QuestNpc = "TikiQuest2",             QuestId = 1, Mob = "Sun-kissed Warrior",  QuestPos = Vector3.new(-16539, 54, 1051), MobPos = Vector3.new(-16347, 64, 984) },
	{ Sea = 3, MinLv = 2525, QuestNpc = "TikiQuest2",             QuestId = 2, Mob = "Isle Champion",       QuestPos = Vector3.new(-16539, 54, 1051), MobPos = Vector3.new(-16634, 85, 1106) },
}

local MATERIAL_MOB_HINTS = {
	["Bones"]          = { "reborn", "living zombie", "demonic soul", "posessed" },
	["Ectoplasm"]      = { "ship deckhand", "ship engineer", "ship steward", "ship officer" },
	["Scrap Metal"]    = { "pirate", "brute", "gladiator", "mercenary" },
	["Mystic Droplet"] = { "water fighter", "sea soldier", "tide keeper" },
	["Vampire Fang"]   = { "vampire" },
	["Angel Wings"]    = { "god's guard", "shanda", "royal squad", "royal soldier" },
	["Magma Ore"]      = { "military soldier", "military spy", "magma ninja", "lava pirate" },
}

local function ResolveQuestProfile()
	local sea = GetCurrentSea()
	local lv = GetPlayerLevel()
	local best = nil
	for _, entry in ipairs(QUEST_PROFILES) do
		if entry.Sea == sea and lv >= entry.MinLv then best = entry end
	end
	return best
end

local function GetQuestProfileKey(p)
	if not p then return "" end
	return tostring(p.Sea) .. ":" .. tostring(p.QuestNpc) .. ":" .. tostring(p.QuestId)
end

local function HasActiveQuest()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	local main = pg and pg:FindFirstChild("Main")
	local q = main and main:FindFirstChild("Quest")
	return q and q.Visible == true
end

local function MatchesMaterialFilter(mobName)
	local filter = CFG.MaterialFilter
	if not filter or filter == "Any" then return true end
	local hints = MATERIAL_MOB_HINTS[filter]
	if not hints then return true end
	local low = mobName:lower()
	for _, h in ipairs(hints) do
		if low:find(h, 1, true) then return true end
	end
	return false
end

local function FindBestMob(preferredName)
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return nil end

	local hrp = GetHRP()
	local origin = hrp and hrp.Position or Vector3.zero
	local now = os.clock()
	local allMobs = enemies:GetChildren()
	local bestModel, bestHRP, bestHum, bestScore = nil, nil, nil, math.huge

	for _, model in ipairs(allMobs) do
		if CFG.SkipStuckMobs and Runtime.StuckUntil[model] and now < Runtime.StuckUntil[model] then
			continue
		end
		local mHRP, mHum = IsValidEnemyModel(model)
		if mHRP and mHum then
			local low = model.Name:lower()
			local matMatch = MatchesMaterialFilter(model.Name)
			local nameMatch = (not preferredName) or (low:find(preferredName:lower(), 1, true) ~= nil)
			if matMatch and nameMatch then
				local dist = (mHRP.Position - origin).Magnitude
				local isBoss = CFG.BossPriority and (low:find("boss", 1, true) or low:find("admiral", 1, true) or low:find("king", 1, true))
				local isCore = CFG.FactoryCorePriority and (low:find("core", 1, true) ~= nil)
				local isElite = CFG.EliteHunterPriority and (low:find("diablo", 1, true) or low:find("deandre", 1, true) or low:find("urban", 1, true))
				local clusterBonus = 0
				if CFG.ClusterScoring then
					for _, other in ipairs(allMobs) do
						if other ~= model then
							local oHRP = other:FindFirstChild("HumanoidRootPart")
							if oHRP and (oHRP.Position - mHRP.Position).Magnitude <= 65 then
								clusterBonus += 35
							end
						end
					end
				end
				local score = dist - clusterBonus - (isBoss and 500 or 0) - (isCore and 700 or 0) - (isElite and 650 or 0)
				if score < bestScore then
					bestScore = score; bestModel = model; bestHRP = mHRP; bestHum = mHum
				end
			end
		end
	end

	if not bestModel and preferredName then
		return FindBestMob(nil)
	end
	return bestModel, bestHRP, bestHum
end

local function FindSpawnedFruits()
	local found = {}
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name:lower():find("fruit", 1, true) then
			local part = obj:IsA("BasePart") and obj
				or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)))
				or (obj:IsA("Tool") and (obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)))
			if part then table.insert(found, { Object = obj, Part = part, Name = obj.Name }) end
		end
	end
	return found
end

local function FindActiveChests()
	local hrp = GetHRP()
	local origin = hrp and hrp.Position or Vector3.zero
	local list = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Parent and obj.Parent.Name:match("^Chest[123]$") then
			if obj.Position.Y < -200 then continue end
			local tier = obj.Parent.Name
			local okTier = (CFG.ChestTierFilter == "All")
				or (CFG.ChestTierFilter == "Diamond+Gold" and (tier == "Chest2" or tier == "Chest3"))
				or (CFG.ChestTierFilter == "Diamond Only" and tier == "Chest3")
			local dist = (obj.Position - origin).Magnitude
			if okTier and dist <= CFG.MaxChestRange then
				table.insert(list, { Part = obj, Tier = tier, Dist = dist })
			end
		end
	end
	table.sort(list, function(a, b) return a.Dist < b.Dist end)
	return list
end

-- ============================================================================
--  8. NAVIGATION, FLIGHT, SLOT EQUIP & MOB GROUPING
-- ============================================================================
local SLOT_KEYCODES = {
	["1"] = Enum.KeyCode.One, ["2"] = Enum.KeyCode.Two, ["3"] = Enum.KeyCode.Three,
	["4"] = Enum.KeyCode.Four, ["5"] = Enum.KeyCode.Five, ["6"] = Enum.KeyCode.Six,
	["7"] = Enum.KeyCode.Seven, ["8"] = Enum.KeyCode.Eight, ["9"] = Enum.KeyCode.Nine,
	["0"] = Enum.KeyCode.Zero,
}

local function SendKeyTap(kc)
	if not kc then return end
	local vim = game:FindFirstChild("VirtualInputManager")
	if vim then
		pcall(function()
			vim:SendKeyEvent(true, kc, false, game)
			task.delay(0.05, function() pcall(function() vim:SendKeyEvent(false, kc, false, game) end) end)
		end)
	end
end

local function EquipSlot(slotStr)
	local char = GetChar()
	local hum = GetHumanoid()
	local bp = LocalPlayer:FindFirstChild("Backpack")
	if not char or not hum or not bp or hum.Health <= 0 then return end

	local tools = {}
	for _, t in ipairs(bp:GetChildren()) do
		if t:IsA("Tool") then table.insert(tools, t) end
	end
	local idx = tonumber(slotStr)
	if idx == 0 then idx = 10 end
	local targetTool = (idx and tools[idx]) or tools[1]
	if targetTool and char:FindFirstChildOfClass("Tool") ~= targetTool then
		pcall(function() hum:EquipTool(targetTool) end)
	else
		SendKeyTap(SLOT_KEYCODES[tostring(slotStr)])
	end
end

local function CancelActiveTween()
	if Runtime.ActiveTween then
		pcall(function() Runtime.ActiveTween:Cancel() end)
		Runtime.ActiveTween = nil
	end
end

local function FlyStepToCFrame(targetCF, customSpeed)
	local hrp = GetHRP()
	local hum = GetHumanoid()
	if not hrp or not hum or hum.Health <= 0 then return end

	local cur = hrp.CFrame
	local dist = (targetCF.Position - cur.Position).Magnitude
	local step = math.clamp(customSpeed or CFG.StepMoveSpeed, 8, 90)
	local nextCF = dist > step
		and cur:Lerp(targetCF, math.clamp(step / dist, 0.12, 0.92))
		or targetCF

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = nextCF
end

local function TweenMoveTo(targetPos, speedOverride)
	local hrp = GetHRP()
	local hum = GetHumanoid()
	if not hrp or not hum or hum.Health <= 0 then return end
	CancelActiveTween()

	local dist = (targetPos - hrp.Position).Magnitude
	local spd = math.max(speedOverride or CFG.TweenTravelSpeed, 50)
	local tw = TweenService:Create(hrp, TweenInfo.new(dist / spd, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(targetPos),
	})
	Runtime.ActiveTween = tw
	tw:Play()
end

local function GroupNearbyMobs(anchorPos, targetName)
	if not CFG.BringMobs then return end
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return end

	if sethiddenproperty then
		pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)
	end

	for _, model in ipairs(enemies:GetChildren()) do
		local mHRP, mHum = IsValidEnemyModel(model)
		if mHRP and mHum then
			local match = (not targetName) or (model.Name:lower():find(targetName:lower(), 1, true) ~= nil)
			if match and (mHRP.Position - anchorPos).Magnitude <= CFG.BringRadius then
				pcall(function()
					mHum.WalkSpeed = 0
					mHRP.CanCollide = false
					mHRP.AssemblyLinearVelocity = Vector3.zero
					if (mHRP.Position - anchorPos).Magnitude > 1.5 then
						mHRP.CFrame = CFrame.new(anchorPos)
					end
				end)
			end
		end
	end
end

-- ============================================================================
--  9. COMBAT: KILL AURA (FAST ATTACK), SKILLS, FRUITS & BUFFS
-- ============================================================================
local function CollectMobAuraTargets()
	local hrp = GetHRP()
	if not hrp then return {} end
	local list = {}
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return list end

	for _, model in ipairs(enemies:GetChildren()) do
		local r, h = IsValidEnemyModel(model)
		if r and h and (r.Position - hrp.Position).Magnitude <= CFG.AuraRadius then
			table.insert(list, { Model = model, Root = r, Head = model:FindFirstChild("Head") or r })
			if #list >= CFG.SplashTargetCap then break end
		end
	end
	return list
end

local function PerformFastAttack()
	local char = GetChar()
	if not char or not (char:FindFirstChildOfClass("Tool") or char:FindFirstChild("EquippedWeapon")) then return end

	local targets = CollectMobAuraTargets()
	if #targets == 0 then return end

	local main = targets[1]
	local hitList = {}
	for _, t in ipairs(targets) do table.insert(hitList, { t.Model, t.Root }) end

	if Runtime.RegisterAttack and Runtime.RegisterHit then
		pcall(function()
			Runtime.RegisterAttack:FireServer(0)
			Runtime.RegisterHit:FireServer(main.Head, hitList)
		end)
	end

	if CFG.FastAttackMode == "Mode2" and Runtime.FoundRemote and Runtime.FoundRemoteId ~= nil then
		pcall(function()
			local seedVal = 1
			local seedFn = Runtime.NetFolder and Runtime.NetFolder:FindFirstChild("seed")
			if seedFn and seedFn:IsA("RemoteFunction") then
				local ok, res = pcall(function() return seedFn:InvokeServer() end)
				if ok and type(res) == "number" then seedVal = res end
			end
			local encId = bit32.bxor(tonumber(Runtime.FoundRemoteId) + 909090, seedVal * 2)
			local shift = math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
			local encName = ("RE/RegisterHit"):gsub(".", function(c)
				return string.char(bit32.bxor(string.byte(c), shift))
			end)
			Runtime.FoundRemote:FireServer(encName, encId, main.Head, hitList)
		end)
	end
end

local function IsSkillReadyByUI(keyLetter)
	if not CFG.CheckSkillCooldownUI then return true end
	local char = GetChar()
	local tool = char and char:FindFirstChildOfClass("Tool")
	if not tool then return false end
	local skills = LocalPlayer:FindFirstChild("PlayerGui")
		and LocalPlayer.PlayerGui:FindFirstChild("Main")
		and LocalPlayer.PlayerGui.Main:FindFirstChild("Skills")
	local tf = skills and skills:FindFirstChild(tool.Name)
	local sk = tf and tf:FindFirstChild(keyLetter)
	local cd = sk and sk:FindFirstChild("Cooldown")
	if cd and cd:IsA("Frame") then return cd.Size.X.Scale <= 0.01 end
	return true
end

local function RunSkillRotationBurst()
	local char = GetChar()
	if not char then return end
	if CFG.LowEnergyPause then
		local energy = char:FindFirstChild("Energy")
		if energy and typeof(energy.Value) == "number" and energy.Value < 150 then return end
	end

	local order = {
		{ Flag = "RotSkillZ", Key = "Z", Code = Enum.KeyCode.Z },
		{ Flag = "RotSkillX", Key = "X", Code = Enum.KeyCode.X },
		{ Flag = "RotSkillC", Key = "C", Code = Enum.KeyCode.C },
		{ Flag = "RotSkillV", Key = "V", Code = Enum.KeyCode.V },
		{ Flag = "RotSkillF", Key = "F", Code = Enum.KeyCode.F },
	}
	for _, entry in ipairs(order) do
		if CFG[entry.Flag] and IsSkillReadyByUI(entry.Key) then
			SendKeyTap(entry.Code)
			task.wait(0.06)
		end
	end
end

local function FireFruitM1(voidMode)
	local hrp = GetHRP()
	local char = GetChar()
	if not hrp or not char then return end

	local fruit = nil
	for _, cont in ipairs({ char, LocalPlayer:FindFirstChild("Backpack") }) do
		if cont then
			for _, t in ipairs(cont:GetChildren()) do
				if t:IsA("Tool") and t.ToolTip == "Blox Fruit" then fruit = t; break end
			end
		end
		if fruit then break end
	end

	local remote = fruit and (fruit:FindFirstChild("LeftClickRemote") or fruit:FindFirstChildWhichIsA("RemoteEvent", true))
	if not remote or not remote:IsA("RemoteEvent") then return end

	if voidMode then
		pcall(function() remote:FireServer(Vector3.new(9e30, 9e30, 9e30), 5, true) end)
		return
	end

	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return end
	for _, npc in ipairs(enemies:GetChildren()) do
		local r, h = IsValidEnemyModel(npc)
		if r and h and (r.Position - hrp.Position).Magnitude <= 500 then
			pcall(function() remote:FireServer((r.Position - hrp.Position).Unit, 1, true) end)
		end
	end
end

local function StoreAllFruitsNow()
	if not Runtime.CommF then return end
	for _, cont in ipairs({ GetChar(), LocalPlayer:FindFirstChild("Backpack") }) do
		if cont then
			for _, item in ipairs(cont:GetChildren()) do
				if item:IsA("Tool") and (item.Name:lower():find("fruit", 1, true) or item.ToolTip == "Blox Fruit") then
					pcall(function()
						Runtime.CommF:InvokeServer("StoreFruit", item:GetAttribute("OriginalName") or item.Name, item)
					end)
				end
			end
		end
	end
end

local function TriggerRaidPedestal()
	local map = workspace:FindFirstChild("Map")
	if not map then return false end
	local holder = (WORLD_3 and map:FindFirstChild("Boat Castle")) or (WORLD_2 and map:FindFirstChild("CircleIsland"))
	local btn = holder and holder:FindFirstChild("RaidSummon2")
	if not btn then return false end
	btn = btn:FindFirstChild("Button") or btn:FindFirstChild("Main") or btn
	local det = btn:FindFirstChild("ClickDetector")
	if det and type(fireclickdetector) == "function" then pcall(fireclickdetector, det); return true end
	local pr = btn:FindFirstChild("ProximityPrompt")
	if pr and type(fireproximityprompt) == "function" then pcall(fireproximityprompt, pr); return true end
	return false
end

-- ============================================================================
--  10. SMART SERVER HOP (PERSISTS BOSS HOP + QUEUES TELEPORT)
-- ============================================================================
local function CountVisitedJobs()
	local n = 0
	for _ in pairs(Runtime.VisitedJobs) do n += 1 end
	return n
end

local isHoppingNow = false
local function SmartServerHop(reason)
	if isHoppingNow then return end
	isHoppingNow = true
	SetStatus(reason or "Hopping to fresh server...")
	Runtime.VisitedJobs[game.JobId] = true
	SaveBossHopState()
	QueueTeleportReExec()

	task.spawn(function()
		if CFG.UseServerBrowser then
			local browser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
			if browser and browser:IsA("RemoteFunction") then
				for page = 1, 15 do
					local ok, res = pcall(function() return browser:InvokeServer(page) end)
					if ok and type(res) == "table" then
						for job, info in pairs(res) do
							if job ~= game.JobId and type(info) == "table" then
								local cnt = tonumber(info.Count) or 0
								local reg = tostring(info.Region or "")
								local regOk = (CFG.HopRegion == "Any") or (reg:lower():find(CFG.HopRegion:lower(), 1, true) ~= nil)
								if regOk and cnt >= 1 and cnt <= CFG.HopMaxPlayers and (not CFG.AvoidVisitedJobs or not Runtime.VisitedJobs[job]) then
									AddLog("Hopping via __ServerBrowser -> " .. tostring(job))
									pcall(function() browser:InvokeServer("teleport", job) end)
									task.wait(4)
								end
							end
						end
					end
					task.wait(0.05)
				end
			end
		end

		local ok, data = pcall(function()
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
			return HttpService:JSONDecode(game:HttpGet(url))
		end)
		if ok and type(data) == "table" and type(data.data) == "table" then
			for _, srv in ipairs(data.data) do
				if type(srv) == "table" and srv.id and srv.id ~= game.JobId then
					local cnt = srv.playing or 0
					local maxP = srv.maxPlayers or 12
					local notVisited = (not CFG.AvoidVisitedJobs) or (not Runtime.VisitedJobs[srv.id])
					if notVisited and cnt < maxP and cnt <= CFG.HopMaxPlayers then
						AddLog("Hopping via Public API -> " .. tostring(srv.id))
						pcall(function()
							TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
						end)
						task.wait(4)
					end
				end
			end
		end

		pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
		task.wait(5)
		isHoppingNow = false
	end)
end

-- ============================================================================
--  11. MOVEMENT, FLIGHT & CLEANUP
-- ============================================================================
local FlyState = { on = false, att = nil, lv = nil, ao = nil, conn = nil }

local function StopFlyController()
	FlyState.on = false
	if FlyState.conn then FlyState.conn:Disconnect(); FlyState.conn = nil end
	if FlyState.att then pcall(function() FlyState.att:Destroy() end); FlyState.att = nil end
	FlyState.lv = nil; FlyState.ao = nil
	local hum = GetHumanoid()
	if hum then pcall(function() hum.PlatformStand = false end) end
end

local function StartFlyController()
	if FlyState.on then return end
	local hrp = GetHRP()
	local hum = GetHumanoid()
	if not hrp or not hum then return end
	FlyState.on = true
	hum.PlatformStand = true

	local att = Instance.new("Attachment", hrp)
	local lv = Instance.new("LinearVelocity", att)
	lv.MaxForce = 9e9; lv.VectorVelocity = Vector3.zero; lv.Attachment0 = att; lv.RelativeTo = Enum.ActuatorRelativeTo.World
	local ao = Instance.new("AlignOrientation", att)
	ao.MaxTorque = 9e9; ao.Responsiveness = 200; ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; ao.Attachment0 = att
	FlyState.att = att; FlyState.lv = lv; FlyState.ao = ao

	FlyState.conn = RunService.RenderStepped:Connect(function()
		if not FlyState.on or not FlyState.lv or not FlyState.ao then return end
		local r = GetHRP()
		local cam = workspace.CurrentCamera
		if not r or not cam then return end
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
		local vel = dir.Magnitude > 0.01 and (dir.Unit * CFG.FlySpeed) or Vector3.zero
		FlyState.lv.VectorVelocity = vel
		r.AssemblyLinearVelocity = vel
		FlyState.ao.CFrame = cam.CFrame
	end)
end

local function RestorePhysicsDefaults()
	CancelActiveTween()
	StopFlyController()
	if Runtime.WaterPad and Runtime.WaterPad.Parent then
		pcall(function() Runtime.WaterPad:Destroy() end)
		Runtime.WaterPad = nil
	end
	local hum = GetHumanoid()
	if hum then
		pcall(function()
			hum.PlatformStand = false
			hum.WalkSpeed = 16
			if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
		end)
	end
end

local function RefreshAllUIControls()
	for _, fn in pairs(Runtime.UIControls) do pcall(fn) end
end

local function PanicStopAll()
	local stopKeys = {
		"AutoLevel", "AutoBossHop", "FastAttackMobs", "AutoSkillRotation",
		"MasterySlotRotator", "FruitM1", "VoidFruitM1", "AutoChestFarm",
		"SpeedEnabled", "JumpEnabled", "FlyEnabled", "Noclip", "BoatNoclip", "WalkOnWater",
	}
	for _, k in ipairs(stopKeys) do
		CFG[k] = false
		if Runtime.UIControls[k] then pcall(Runtime.UIControls[k]) end
	end
	SaveBossHopState()
	RestorePhysicsDefaults()
	SetStatus("PANIC STOP — all loops halted")
	AddLog("Panic stop triggered")
end

-- ============================================================================
--  12. BACKGROUND WORKERS (BOSS HOP ENGINE, AUTO LEVEL, COMBAT, ESP)
-- ============================================================================
DiscoverRemotes()
RestoreBossHopState()
if CFG.AutoExecEnabled then
	InstallAutoExecAndCache()
end

Runtime.StartLevel = GetPlayerLevel()
Runtime.StartBeli  = GetPlayerBeli()
Runtime.StartFrags = GetPlayerFrags()

-- Helper to launch a specific Boss Hop immediately from any boss button
local function StartBossHopFor(bossName)
	CFG.BossHopTarget = bossName
	CFG.AutoBossHop = true
	CFG.AutoLevel = false
	Runtime.JoinedServerAt = os.clock()
	SaveBossHopState()
	QueueTeleportReExec()
	RefreshAllUIControls()
	SetStatus("Boss Hop armed -> " .. bossName)
	AddLog("Started Boss Hop target: " .. bossName)
end

-- DEDICATED EVENT & RAID BOSS HOP WORKER
TrackThread(function()
	local engagedBossModel = nil
	local lastKillAuraKick = 0

	while Runtime.Alive do
		JitterWait(0.08)
		if not CFG.AutoBossHop then
			engagedBossModel = nil
			continue
		end

		pcall(function()
			local char = GetChar()
			local hum = GetHumanoid()
			local hrp = GetHRP()
			if not char or not hum or not hrp or hum.Health <= 0 then
				SetStatus("Boss Hop: waiting for character...")
				return
			end

			-- Wait for server entities to finish replicating after join
			local sinceJoin = os.clock() - Runtime.JoinedServerAt
			if sinceJoin < CFG.BossHopJoinGraceSec then
				SetStatus(("Boss Hop [%s]: scanning server (%.1fs)..."):format(
					CFG.BossHopTarget, CFG.BossHopJoinGraceSec - sinceJoin
				))
				return
			end

			local found = FindTargetBossEntity(CFG.BossHopTarget)

			if found then
				-- Ensure Noclip, Kill Aura & Auto Haki are active when flying to / fighting boss
				if not CFG.Noclip then
					CFG.Noclip = true
					if Runtime.UIControls.Noclip then pcall(Runtime.UIControls.Noclip) end
				end
				if CFG.BossHopAutoKillAura and not CFG.FastAttackMobs then
					CFG.FastAttackMobs = true
					if Runtime.UIControls.FastAttackMobs then pcall(Runtime.UIControls.FastAttackMobs) end
				end
				if not CFG.AutoHaki then
					CFG.AutoHaki = true
					if Runtime.UIControls.AutoHaki then pcall(Runtime.UIControls.AutoHaki) end
				end

				if CFG.AutoEquipSlot then
					EquipSlot(CFG.PreferredSlot)
				end

				local targetPos = found.Pos
				local dist = (targetPos - hrp.Position).Magnitude

				if found.State == "StreamedOut" or dist > 90 then
					-- Fly smoothly to the boss's arena / coordinates
					SetStatus(("Boss Hop: flying to %s (%.0fm)"):format(found.Model.Name, dist))
					local flyStep = math.clamp(CFG.BossHopFlySpeed * 0.14, 24, 85)
					FlyStepToCFrame(CFrame.new(targetPos + Vector3.new(0, CFG.FarmHeight, 0)), flyStep)
				else
					-- Engaged in Kill Aura range: hover directly above/behind boss and shred
					engagedBossModel = found.Model
					SetStatus(("Boss Hop: killing %s [%.0f%% HP]"):format(
						found.Model.Name, (found.Hum.Health / math.max(found.Hum.MaxHealth, 1)) * 100
					))
					local hoverPos = found.HRP.Position + Vector3.new(0, CFG.FarmHeight, 0)
					FlyStepToCFrame(CFrame.lookAt(hoverPos, found.HRP.Position), 60)

					if (os.clock() - lastKillAuraKick) >= CFG.AttackDelay then
						lastKillAuraKick = os.clock()
						pcall(PerformFastAttack)
						if CFG.BossHopAutoSkills then
							pcall(RunSkillRotationBurst)
						end
					end

					if CFG.StopOnBossFound then
						CFG.AutoBossHop = false
						SaveBossHopState()
						RefreshAllUIControls()
						SetStatus("Boss located & engaged — hop paused")
					end
				end
				return
			end

			-- If we were fighting the boss and it just died/despawned:
			if engagedBossModel then
				engagedBossModel = nil
				Runtime.BossKillsSession += 1
				SaveBossHopState()
				AddLog("Defeated target boss: " .. CFG.BossHopTarget)
				if not CFG.HopAfterBossKill then
					CFG.AutoBossHop = false
					SaveBossHopState()
					RefreshAllUIControls()
					SetStatus("Boss killed! Hop After Kill is OFF.")
					return
				end
			end

			-- Target boss not in this server -> Hop to next unvisited server
			SmartServerHop(("Boss Hop: %s not found — hopping..."):format(CFG.BossHopTarget))
		end)
	end
end)

-- PRIMARY AUTO-LEVEL & CHEST WORKER (Runs when AutoBossHop is not active)
TrackThread(function()
	local angle = 0
	local trackedMob, trackedHP, trackedSince = nil, 0, 0
	local lastSlotRotateAt = 0
	local rotCursor = 1

	while Runtime.Alive do
		JitterWait(0.08)

		if CFG.ScheduledStopEnabled and (os.clock() - Runtime.StartClock) >= (CFG.ScheduledStopMinutes * 60) then
			PanicStopAll(); SetStatus("Scheduled timer reached"); continue
		end
		if CFG.TargetLevelStop and GetPlayerLevel() >= CFG.TargetLevelGoal then
			PanicStopAll(); SetStatus("Target level goal reached!"); continue
		end
		if CFG.MasteryAutoStop and GetEquippedToolMastery() >= CFG.MasteryGoal then
			PanicStopAll(); SetStatus("Target Mastery goal reached!"); continue
		end

		if CFG.AutoBossHop then continue end
		if not (CFG.AutoLevel or CFG.AutoChestFarm) then continue end

		pcall(function()
			local char = GetChar()
			local hum = GetHumanoid()
			local hrp = GetHRP()
			if not char or not hum or not hrp or hum.Health <= 0 then
				SetStatus("Waiting for respawn...")
				return
			end

			if CFG.AutoFleeLowHP then
				local pct = (hum.Health / math.max(hum.MaxHealth, 1)) * 100
				if pct <= CFG.FleeHPThreshold then
					SetStatus(("Low HP (%.0f%%) — recovering up"):format(pct))
					FlyStepToCFrame(hrp.CFrame + Vector3.new(0, 160, 0), 50)
					return
				end
			end

			if CFG.FruitSpawnScanner and CFG.AutoCollectFruit then
				local fruits = FindSpawnedFruits()
				if #fruits > 0 then
					SetStatus("Collecting fruit: " .. fruits[1].Name)
					FlyStepToCFrame(CFrame.new(fruits[1].Part.Position + Vector3.new(0, 2, 0)), 45)
					return
				end
			end

			if (CFG.AutoSweepDrops or CFG.AutoTouchOrbs) and type(firetouchinterest) == "function" then
				for _, obj in ipairs(workspace:GetChildren()) do
					local low = obj.Name:lower()
					local isDrop = CFG.AutoSweepDrops and obj:IsA("Tool")
					local isOrb  = CFG.AutoTouchOrbs and (low:find("orb", 1, true) or low:find("berry", 1, true))
					if isDrop or isOrb then
						local p = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
						if p and (p.Position - hrp.Position).Magnitude <= 350 then
							pcall(firetouchinterest, hrp, p, 0)
							pcall(firetouchinterest, hrp, p, 1)
						end
					end
				end
			end

			if CFG.AutoChestFarm then
				local chests = FindActiveChests()
				if #chests > 0 then
					local target = chests[1]
					SetStatus(("Collecting %s (%.0fm)"):format(target.Tier, target.Dist))
					FlyStepToCFrame(CFrame.new(target.Part.Position + Vector3.new(0, 2, 0)), 45)
					if type(firetouchinterest) == "function" and (hrp.Position - target.Part.Position).Magnitude < 16 then
						pcall(firetouchinterest, hrp, target.Part, 0)
						pcall(firetouchinterest, hrp, target.Part, 1)
						Runtime.SessionChests += 1
					end
					return
				elseif CFG.ChestHopWhenEmpty then
					SmartServerHop("Chests cleared — hopping...")
					return
				elseif not CFG.ReturnFarmAfterChest then
					SetStatus("No chests in range")
					return
				end
			end

			if not CFG.AutoLevel then return end

			local profile = ResolveQuestProfile()
			local bestKey = GetQuestProfileKey(profile)
			local prefMob = (not CFG.QuestSkipPureMob and profile) and profile.Mob or nil

			if CFG.AutoQuest and not CFG.QuestSkipPureMob and profile then
				if CFG.AutoUpgradeQuest and HasActiveQuest() and Runtime.ActiveQuestKey ~= "" and Runtime.ActiveQuestKey ~= bestKey and Runtime.CommF then
					AddLog("Level up! Upgrading quest to Lv." .. tostring(profile.MinLv) .. " (" .. profile.Mob .. ")")
					pcall(function() Runtime.CommF:InvokeServer("AbandonQuest") end)
					Runtime.ActiveQuestKey = nil
					task.wait(0.15)
				end

				if not HasActiveQuest() then
					if (hrp.Position - profile.QuestPos).Magnitude > 14 then
						SetStatus(("Auto Level [Lv.%d]: Heading to %s"):format(GetPlayerLevel(), profile.QuestNpc))
						FlyStepToCFrame(CFrame.new(profile.QuestPos + Vector3.new(0, 4, 0)), 40)
						return
					elseif Runtime.CommF then
						SetStatus(("Accepting Lv.%d quest (%s)"):format(profile.MinLv, profile.Mob))
						pcall(function()
							Runtime.CommF:InvokeServer("StartQuest", profile.QuestNpc, profile.QuestId)
						end)
						Runtime.ActiveQuestKey = bestKey
					end
				end
			end

			local mob, mHRP, mHum = FindBestMob(prefMob)
			if not mob or not mHRP or not mHum then
				if profile and (hrp.Position - profile.MobPos).Magnitude > 20 then
					SetStatus("Moving to spawn: " .. tostring(prefMob or "Enemies"))
					FlyStepToCFrame(CFrame.new(profile.MobPos + Vector3.new(0, CFG.FarmHeight, 0)), 40)
				else
					SetStatus("Scanning for spawns...")
				end
				return
			end

			if trackedMob ~= mob then
				trackedMob = mob; trackedHP = mHum.Health; trackedSince = os.clock()
			elseif mHum.Health < trackedHP then
				trackedHP = mHum.Health; trackedSince = os.clock()
			elseif CFG.SkipStuckMobs and (os.clock() - trackedSince) > CFG.StuckTimeout then
				Runtime.StuckUntil[mob] = os.clock() + 25
				trackedMob = nil
				return
			end

			if CFG.MasterySlotRotator then
				if (os.clock() - lastSlotRotateAt) >= CFG.MasteryRotateSec then
					lastSlotRotateAt = os.clock()
					local slots = {}
					if CFG.RotSlot1 then table.insert(slots, "1") end
					if CFG.RotSlot2 then table.insert(slots, "2") end
					if CFG.RotSlot3 then table.insert(slots, "3") end
					if CFG.RotSlot4 then table.insert(slots, "4") end
					if #slots > 0 then
						rotCursor = (rotCursor % #slots) + 1
						EquipSlot(slots[rotCursor])
					end
				end
			elseif CFG.AutoEquipSlot then
				EquipSlot(CFG.PreferredSlot)
			end

			SetStatus(("Auto Level [Lv.%d]: %s"):format(GetPlayerLevel(), mob.Name))
			GroupNearbyMobs(mHRP.Position, prefMob)

			angle += CFG.OrbitSpeed
			local h = CFG.FarmHeight
			local offset = Vector3.new(0, h, 0)
			if CFG.FarmPositionMode == "Below" then offset = Vector3.new(0, -h, 0)
			elseif CFG.FarmPositionMode == "Behind" then offset = -mHRP.CFrame.LookVector * (h * 0.7) + Vector3.new(0, 4, 0)
			elseif CFG.FarmPositionMode == "Orbit" then offset = Vector3.new(math.cos(angle) * h, h * 0.6, math.sin(angle) * h) end

			local desiredPos = mHRP.Position + offset
			local cf = CFG.FaceTargetLock and CFrame.lookAt(desiredPos, mHRP.Position) or CFrame.new(desiredPos)
			FlyStepToCFrame(cf, CFG.StepMoveSpeed)
		end)
	end
end)

-- Fast Attack & Skill Rotation Worker
TrackThread(function()
	local lastSkillAt = 0
	while Runtime.Alive do
		if CFG.FastAttackMobs then
			pcall(PerformFastAttack)
			if CFG.AutoSkillRotation and (os.clock() - lastSkillAt) >= CFG.SkillCastDelay then
				lastSkillAt = os.clock()
				pcall(RunSkillRotationBurst)
			end
			JitterWait(CFG.AttackDelay)
		else
			task.wait(0.25)
		end
	end
end)

-- Fruit M1 Worker
TrackThread(function()
	while Runtime.Alive do
		if CFG.VoidFruitM1 then
			pcall(FireFruitM1, true); task.wait(0.25)
		elseif CFG.FruitM1 then
			pcall(FireFruitM1, false); JitterWait(CFG.FruitM1Delay)
		else
			task.wait(0.25)
		end
	end
end)

-- Buffs, Fruits, Raids & Sea Scanners Worker
TrackThread(function()
	while Runtime.Alive do
		task.wait(1.2)
		if not Runtime.Alive then break end
		pcall(function()
			local char = GetChar()
			local hum = GetHumanoid()
			if not char or not hum or hum.Health <= 0 then return end

			if CFG.AutoHaki and Runtime.CommF and not char:FindFirstChild("HasBuso") then
				Runtime.CommF:InvokeServer("Buso")
			end
			if CFG.AutoKen and Runtime.CommE and not char:FindFirstChild("KenDisabled") then
				local blur = Lighting:FindFirstChild("Blur")
				if not (char:GetAttribute("KenActive") or (blur and blur.Enabled)) then
					Runtime.CommE:FireServer("Ken", true)
				end
			end
			if CFG.AutoV3 and Runtime.CommE then
				Runtime.CommE:FireServer("ActivateAbility")
			end
			if CFG.AutoV4 then
				local en = char:FindFirstChild("RaceEnergy")
				local tr = char:FindFirstChild("RaceTransformed")
				local awk = (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Awakening")) or char:FindFirstChild("Awakening")
				if en and en.Value >= 1 and tr and not tr.Value and awk then
					local rf = awk:FindFirstChild("RemoteFunction")
					if rf then rf:InvokeServer(true) end
				end
			end
			if CFG.AutoStoreFruit then StoreAllFruitsNow() end
			if CFG.AutoRollFruit and Runtime.CommF and GetPlayerBeli() >= CFG.MinBeliReserve then
				Runtime.CommF:InvokeServer("Cousin", "Buy")
			end
			if CFG.AutoBoneSurprise and Runtime.CommF then
				Runtime.CommF:InvokeServer("Bones", "Buy", 1, 1)
			end
			if CFG.AutoBuyRaidChip and Runtime.CommF then
				Runtime.CommF:InvokeServer("RaidsNpc", "Select", CFG.RaidChipType)
			end
			if CFG.AutoRaidTrigger then TriggerRaidPedestal() end
			if CFG.AutoAwakenMove and Runtime.CommF then
				Runtime.CommF:InvokeServer("Awakener", "Awaken")
			end
			if CFG.FruitSpawnScanner and CFG.FruitAlertBanner then
				local fruits = FindSpawnedFruits()
				if #fruits > 0 then SetAlert("Fruit spawned: " .. fruits[1].Name) end
			end
			if CFG.SeaAlertBanner then
				local locs = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
				if locs then
					if CFG.DetectMirage and locs:FindFirstChild("Mirage Island") then SetAlert("Mirage Island detected!") end
					if CFG.DetectKitsune and locs:FindFirstChild("Kitsune Island") then SetAlert("Kitsune Island detected!") end
					if CFG.DetectPrehistoric and locs:FindFirstChild("Prehistoric Island") then SetAlert("Prehistoric Island detected!") end
				end
			end
		end)
	end
end)

-- Stepped Physics, Noclip, Water & Anti-Void Hook
TrackConn(RunService.Stepped:Connect(function()
	if not Runtime.Alive then return end
	local char = GetChar()
	local hum = GetHumanoid()
	local hrp = GetHRP()

	if hum and hum.Health > 0 then
		if CFG.SpeedEnabled then hum.WalkSpeed = math.clamp(CFG.SpeedValue, 16, 1000) end
		if CFG.JumpEnabled then
			if hum.UseJumpPower then hum.JumpPower = CFG.JumpValue else hum.JumpHeight = CFG.JumpValue * 0.144 end
		end
	end

	if char and CFG.Noclip then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
		end
	end

	if CFG.BoatNoclip then
		local boats = workspace:FindFirstChild("Boats")
		if boats then
			for _, p in ipairs(boats:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end
	end

	if hrp then
		if hrp.Position.Y > 5 then Runtime.LastSafePos = hrp.CFrame end
		if CFG.AntiVoidGuard and hrp.Position.Y < -250 and Runtime.LastSafePos then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = Runtime.LastSafePos
		end
	end

	if CFG.WalkOnWater and hrp then
		if not Runtime.WaterPad or not Runtime.WaterPad.Parent then
			local pad = Instance.new("Part")
			pad.Name = "ZyvoraWaterPad"; pad.Size = Vector3.new(36, 1, 36); pad.Anchored = true
			pad.CanCollide = true; pad.Transparency = 1; pad.Parent = workspace
			Runtime.WaterPad = pad
		end
		Runtime.WaterPad.Position = Vector3.new(hrp.Position.X, -0.5, hrp.Position.Z)
	elseif Runtime.WaterPad then
		pcall(function() Runtime.WaterPad:Destroy() end)
		Runtime.WaterPad = nil
	end

	if CFG.ExpandWaterPlane then
		pcall(function()
			local wb = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WaterBase-Plane")
			if wb then wb.Size = Vector3.new(1000, 112, 1000) end
		end)
	end

	if char and CFG.SoruInfinite then
		pcall(function() char:SetAttribute("FlashstepCooldown", 1) end)
	end
	LocalPlayer.CameraMaxZoomDistance = CFG.CameraZoom
end))

TrackConn(LocalPlayer.Idled:Connect(function()
	if CFG.AntiAFK then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end))

TrackConn(UserInputService.JumpRequest:Connect(function()
	if not CFG.InfiniteJump then return end
	local hrp = GetHRP()
	local hum = GetHumanoid()
	if hrp and hum and hum.Health > 0 then
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
		hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 65, hrp.AssemblyLinearVelocity.Z)
	end
end))

-- ============================================================================
--  13. FARM ESP OVERLAY MANAGER
-- ============================================================================
local ESPStore = {}

local function ClearAllESP()
	for key, inst in pairs(ESPStore) do
		pcall(function() inst:Destroy() end)
		ESPStore[key] = nil
	end
end

local function SetESPBillboard(key, adornee, text, color)
	if not adornee or not adornee.Parent then return end
	local bb = ESPStore[key]
	if not bb or not bb.Parent then
		bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(220, 60); bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true
		local lbl = Instance.new("TextLabel", bb)
		lbl.Name = "Info"; lbl.Size = UDim2.fromScale(1, 1); lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold; lbl.TextStrokeTransparency = 0
		bb.Parent = adornee
		ESPStore[key] = bb
	end
	local info = bb:FindFirstChild("Info")
	if info then info.TextSize = CFG.ESP_TextSize; info.TextColor3 = color; info.Text = text end
end

TrackThread(function()
	while Runtime.Alive do
		task.wait(0.5)
		if not CFG.ESPEnabled then ClearAllESP(); continue end
		pcall(function()
			local myRoot = GetHRP(); if not myRoot then return end
			if CFG.ESP_Bosses and workspace:FindFirstChild("Enemies") then
				for _, model in ipairs(workspace.Enemies:GetChildren()) do
					local r, h = IsValidEnemyModel(model)
					if r and h then
						local isBoss = ModelMatchesBossTarget(model.Name, "All Bosses")
						if isBoss then
							local dist = (r.Position - myRoot.Position).Magnitude
							if dist <= CFG.ESP_MaxDistance then
								local parts = { "[BOSS] " .. model.Name }
								if CFG.ESP_Distance then table.insert(parts, math.floor(dist) .. "m") end
								if CFG.ESP_HP then table.insert(parts, math.floor((h.Health / math.max(h.MaxHealth, 1)) * 100) .. "% HP") end
								SetESPBillboard(model, r, table.concat(parts, " | "), Color3.fromRGB(255, 55, 85))
							end
						end
					end
				end
			end
			if CFG.ESP_Fruits then
				for _, f in ipairs(FindSpawnedFruits()) do
					local dist = (f.Part.Position - myRoot.Position).Magnitude
					if dist <= CFG.ESP_MaxDistance then
						local label = "[FRUIT] " .. f.Name .. (CFG.ESP_Distance and (" | " .. math.floor(dist) .. "m") or "")
						SetESPBillboard(f.Object, f.Part, label, Color3.fromRGB(255, 195, 70))
					end
				end
			end
			if CFG.ESP_Chests then
				for _, c in ipairs(FindActiveChests()) do
					if c.Dist <= CFG.ESP_MaxDistance then
						local label = "[" .. c.Tier .. "]" .. (CFG.ESP_Distance and (" | " .. math.floor(c.Dist) .. "m") or "")
						SetESPBillboard(c.Part, c.Part, label, Color3.fromRGB(90, 225, 255))
					end
				end
			end
		end)
	end
end)

-- ============================================================================
--  14. FEATURE SPECIFICATION (10 TABS — AUTO LEVEL + FULL EVENT BOSS HOP)
-- ============================================================================
local TAB_NAMES = {
	"1. Auto Level", "2. Boss Hop", "3. Combat", "4. Mastery", "5. Chests/Mat",
	"6. Sea/Raid", "7. Movement", "8. Farm ESP", "9. Hop/Goals", "10. Config"
}

local FEATURE_SPEC = {
	-- TAB 1: AUTO LEVEL
	{ Tab = "1. Auto Level", Kind = "Telemetry", Key = "FarmStats", Label = "Auto Level Telemetry" },
	{ Tab = "1. Auto Level", Kind = "Toggle", Key = "AutoLevel", Label = "Auto Level (Highest Quest Loop)" },
	{ Tab = "1. Auto Level", Kind = "Toggle", Key = "AutoQuest", Label = "Auto Accept Quest Giver" },
	{ Tab = "1. Auto Level", Kind = "Toggle", Key = "AutoUpgradeQuest", Label = "Auto-Upgrade Quest on Level-Up" },
	{ Tab = "1. Auto Level", Kind = "Toggle", Key = "QuestSkipPureMob", Label = "Quest-Skip Pure Mob Grind" },
	{ Tab = "1. Auto Level", Kind = "Toggle", Key = "BringMobs", Label = "Smart Mob Magnet (Bring Mobs)" },
	{ Tab = "1. Auto Level", Kind = "Slider", Key = "BringRadius", Label = "Mob Magnet Radius", Min = 50, Max = 600, Step = 10 },
	{ Tab = "1. Auto Level", Kind = "Slider", Key = "FarmHeight", Label = "Farm Hover Height", Min = 4, Max = 45, Step = 1 },
	{ Tab = "1. Auto Level", Kind = "Cycle",  Key = "FarmPositionMode", Label = "Farm Positioning Mode", Values = { "Above", "Below", "Behind", "Orbit" } },
	{ Tab = "1. Auto Level", Kind = "Slider", Key = "OrbitSpeed", Label = "Orbit Angular Speed", Min = 0.05, Max = 0.50, Step = 0.01 },
	{ Tab = "1. Auto Level", Kind = "Toggle", Key = "ClusterScoring", Label = "High-Density Cluster Scoring" },
	{ Tab = "1. Auto Level", Kind = "Toggle", Key = "BossPriority", Label = "In-Server Boss Priority" },
	{ Tab = "1. Auto Level", Kind = "Toggle", Key = "SkipStuckMobs", Label = "Stuck Mob Blacklist" },
	{ Tab = "1. Auto Level", Kind = "Slider", Key = "StuckTimeout", Label = "Stuck Mob Timeout (s)", Min = 3, Max = 20, Step = 1 },
	{ Tab = "1. Auto Level", Kind = "Slider", Key = "StepMoveSpeed", Label = "Navigation Flight Step Speed", Min = 8, Max = 60, Step = 1 },
	{ Tab = "1. Auto Level", Kind = "Toggle", Key = "AutoEquipSlot", Label = "Auto-Equip Farm Slot" },
	{ Tab = "1. Auto Level", Kind = "Cycle",  Key = "PreferredSlot", Label = "Preferred Farm Slot", Values = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" } },
	{ Tab = "1. Auto Level", Kind = "Action", Label = "Abandon & Re-Evaluate Best Quest Now", Fn = function()
		if Runtime.CommF then pcall(function() Runtime.CommF:InvokeServer("AbandonQuest") end) end
		Runtime.ActiveQuestKey = nil
	end },

	-- TAB 2: EVENT & RAID BOSS HOP
	{ Tab = "2. Boss Hop", Kind = "Telemetry", Key = "BossHopStats", Label = "Boss Hop Telemetry" },
	{ Tab = "2. Boss Hop", Kind = "Toggle", Key = "AutoBossHop", Label = "Auto Boss Hop Master Switch", OnChange = function() SaveBossHopState(); QueueTeleportReExec() end },
	{ Tab = "2. Boss Hop", Kind = "Cycle",  Key = "BossHopTarget", Label = "Selected Boss Target", Values = BOSS_NAME_LIST, OnChange = function() SaveBossHopState() end },
	{ Tab = "2. Boss Hop", Kind = "Toggle", Key = "BossHopAutoKillAura", Label = "Auto-Enable Kill Aura & Noclip on Hunt" },
	{ Tab = "2. Boss Hop", Kind = "Toggle", Key = "BossHopAutoSkills", Label = "Auto-Cast Skills During Boss Kill" },
	{ Tab = "2. Boss Hop", Kind = "Toggle", Key = "HopAfterBossKill", Label = "Keep Hopping After Boss Dies" },
	{ Tab = "2. Boss Hop", Kind = "Toggle", Key = "StopOnBossFound", Label = "Pause Hop Once Boss Is Found" },
	{ Tab = "2. Boss Hop", Kind = "Slider", Key = "BossHopJoinGraceSec", Label = "Server Scan Grace Delay (s)", Min = 2, Max = 12, Step = 0.5 },
	{ Tab = "2. Boss Hop", Kind = "Slider", Key = "BossHopFlySpeed", Label = "Boss Approach Flight Speed", Min = 100, Max = 450, Step = 10 },
	{ Tab = "2. Boss Hop", Kind = "Action", Label = "Hop Server Immediately for Selected Boss", Fn = function()
		StartBossHopFor(CFG.BossHopTarget)
		SmartServerHop("Boss Hop -> " .. CFG.BossHopTarget)
	end },

	-- TAB 3: COMBAT & KILL AURA
	{ Tab = "3. Combat", Kind = "Toggle", Key = "FastAttackMobs", Label = "Kill Aura / Fast Attack (Mobs)" },
	{ Tab = "3. Combat", Kind = "Cycle",  Key = "FastAttackMode", Label = "Kill Aura Remote Mode", Values = { "Mode1", "Mode2" } },
	{ Tab = "3. Combat", Kind = "Slider", Key = "AttackDelay", Label = "Kill Aura Cadence (s)", Min = 0.02, Max = 0.30, Step = 0.01 },
	{ Tab = "3. Combat", Kind = "Slider", Key = "AuraRadius", Label = "Kill Aura Radius (studs)", Min = 30, Max = 500, Step = 10 },
	{ Tab = "3. Combat", Kind = "Slider", Key = "SplashTargetCap", Label = "Multi-Target Splash Cap", Min = 1, Max = 25, Step = 1 },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "AutoSkillRotation", Label = "Auto-Skill Rotation Master" },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "RotSkillZ", Label = "Use Skill Z" },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "RotSkillX", Label = "Use Skill X" },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "RotSkillC", Label = "Use Skill C" },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "RotSkillV", Label = "Use Skill V" },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "RotSkillF", Label = "Use Skill F" },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "AutoHaki", Label = "Auto Buso Haki" },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "AutoKen", Label = "Auto Observation (Ken)" },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "AutoV3", Label = "Auto Race V3 Ability" },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "AutoV4", Label = "Auto Race V4 Awakening" },
	{ Tab = "3. Combat", Kind = "Toggle", Key = "FaceTargetLock", Label = "Face Target Orientation Lock" },

	-- TAB 4: MASTERY & FRUITS
	{ Tab = "4. Mastery", Kind = "Telemetry", Key = "CurrencyStats", Label = "Currency & Mastery" },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "FruitM1", Label = "Fruit M1 Auto-Fire" },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "VoidFruitM1", Label = "Void Fruit M1 Mode" },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "MasteryAutoStop", Label = "Target Mastery Auto-Stop" },
	{ Tab = "4. Mastery", Kind = "Slider", Key = "MasteryGoal", Label = "Target Mastery Goal", Min = 1, Max = 600, Step = 10 },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "MasterySlotRotator", Label = "Multi-Slot Mastery Rotator" },
	{ Tab = "4. Mastery", Kind = "Slider", Key = "MasteryRotateSec", Label = "Slot Rotation Interval (s)", Min = 2, Max = 30, Step = 1 },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "RotSlot1", Label = "Rotate Slot 1 (Melee)" },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "RotSlot2", Label = "Rotate Slot 2 (Fruit)" },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "RotSlot3", Label = "Rotate Slot 3 (Sword)" },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "RotSlot4", Label = "Rotate Slot 4 (Gun)" },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "AutoStoreFruit", Label = "Auto Store Physical Fruits" },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "FruitSpawnScanner", Label = "Spawned Fruit Scanner" },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "AutoCollectFruit", Label = "Auto-Collect Spawned Fruits" },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "AutoRollFruit", Label = "Auto Random Fruit Roll (Cousin)" },
	{ Tab = "4. Mastery", Kind = "Slider", Key = "MinBeliReserve", Label = "Min Beli Reserve for Rolls", Min = 0, Max = 5000000, Step = 50000 },
	{ Tab = "4. Mastery", Kind = "Toggle", Key = "AutoBoneSurprise", Label = "Auto-Buy Bone Surprise" },
	{ Tab = "4. Mastery", Kind = "Action", Label = "Store All Inventory Fruits Now", Fn = StoreAllFruitsNow },

	-- TAB 5: CHESTS & MATERIALS
	{ Tab = "5. Chests/Mat", Kind = "Telemetry", Key = "ChestStats", Label = "Chests & Kills" },
	{ Tab = "5. Chests/Mat", Kind = "Toggle", Key = "AutoChestFarm", Label = "Auto Chest Farm Loop" },
	{ Tab = "5. Chests/Mat", Kind = "Cycle",  Key = "ChestTierFilter", Label = "Chest Priority Tier", Values = { "All", "Diamond+Gold", "Diamond Only" } },
	{ Tab = "5. Chests/Mat", Kind = "Toggle", Key = "ChestHopWhenEmpty", Label = "Chest Hop When Empty" },
	{ Tab = "5. Chests/Mat", Kind = "Cycle",  Key = "MaterialFilter", Label = "Material Target Selector", Values = { "Any", "Bones", "Ectoplasm", "Scrap Metal", "Mystic Droplet", "Vampire Fang", "Angel Wings", "Magma Ore" } },
	{ Tab = "5. Chests/Mat", Kind = "Toggle", Key = "AutoSweepDrops", Label = "Auto-Collect Dropped Tools/Parts" },
	{ Tab = "5. Chests/Mat", Kind = "Toggle", Key = "FactoryCorePriority", Label = "Factory / Pirate Raid Core Priority" },
	{ Tab = "5. Chests/Mat", Kind = "Toggle", Key = "EliteHunterPriority", Label = "Elite Hunter Mob Priority" },
	{ Tab = "5. Chests/Mat", Kind = "Toggle", Key = "AutoTouchOrbs", Label = "Auto-Touch Spawned Orbs" },
	{ Tab = "5. Chests/Mat", Kind = "Toggle", Key = "ReturnFarmAfterChest", Label = "Return to Auto Level After Chests" },
	{ Tab = "5. Chests/Mat", Kind = "Action", Label = "Move to Nearest Chest Now", Fn = function() local c = FindActiveChests(); if c[1] then FlyStepToCFrame(CFrame.new(c[1].Part.Position), 50) end end },

	-- TAB 6: SEA, RAIDS & TP
	{ Tab = "6. Sea/Raid", Kind = "Toggle", Key = "AutoRaidTrigger", Label = "Auto Trigger Raid Pedestal" },
	{ Tab = "6. Sea/Raid", Kind = "Toggle", Key = "AutoAwakenMove", Label = "Auto Awaken Next Move" },
	{ Tab = "6. Sea/Raid", Kind = "Toggle", Key = "AutoBuyRaidChip", Label = "Auto Buy Raid Microchip" },
	{ Tab = "6. Sea/Raid", Kind = "Cycle",  Key = "RaidChipType", Label = "Raid Microchip Element", Values = { "Flame", "Ice", "Quake", "Light", "Dark", "String", "Rumble", "Magma", "Buddha", "Sand", "Phoenix", "Dough" } },
	{ Tab = "6. Sea/Raid", Kind = "Toggle", Key = "DetectMirage", Label = "Mirage Island Detector" },
	{ Tab = "6. Sea/Raid", Kind = "Toggle", Key = "DetectKitsune", Label = "Kitsune Island Detector" },
	{ Tab = "6. Sea/Raid", Kind = "Toggle", Key = "DetectPrehistoric", Label = "Prehistoric Island Detector" },
	{ Tab = "6. Sea/Raid", Kind = "Toggle", Key = "WalkOnWater", Label = "Walk on Water Pad" },
	{ Tab = "6. Sea/Raid", Kind = "Toggle", Key = "ExpandWaterPlane", Label = "Expand WaterBase-Plane" },
	{ Tab = "6. Sea/Raid", Kind = "Slider", Key = "TweenTravelSpeed", Label = "Tween Travel Speed", Min = 50, Max = 450, Step = 10 },
	{ Tab = "6. Sea/Raid", Kind = "Action", Label = "Travel to First Sea", Fn = function() if Runtime.CommF then pcall(function() Runtime.CommF:InvokeServer("TravelMain") end) end end },
	{ Tab = "6. Sea/Raid", Kind = "Action", Label = "Travel to Second Sea", Fn = function() if Runtime.CommF then pcall(function() Runtime.CommF:InvokeServer("TravelDressrosa") end) end end },
	{ Tab = "6. Sea/Raid", Kind = "Action", Label = "Travel to Third Sea", Fn = function() if Runtime.CommF then pcall(function() Runtime.CommF:InvokeServer("TravelZou") end) end end },
	{ Tab = "6. Sea/Raid", Kind = "Action", Label = "Tween TP: Sea 2 Dark Arena (Darkbeard)", Fn = function() TweenMoveTo(Vector3.new(3777, 15, -3498)) end },
	{ Tab = "6. Sea/Raid", Kind = "Action", Label = "Tween TP: Sea 3 Castle on the Sea", Fn = function() TweenMoveTo(Vector3.new(-4999, 314, -3010)) end },
	{ Tab = "6. Sea/Raid", Kind = "Action", Label = "Tween TP: Sea 3 Cake Land (Dough King)", Fn = function() TweenMoveTo(Vector3.new(-2151, 70, -12404)) end },

	-- TAB 7: MOVEMENT & SURVIVABILITY
	{ Tab = "7. Movement", Kind = "Toggle", Key = "SpeedEnabled", Label = "Custom WalkSpeed Override", OnChange = function(on) if not on then RestorePhysicsDefaults() end end },
	{ Tab = "7. Movement", Kind = "Slider", Key = "SpeedValue", Label = "WalkSpeed Value", Min = 16, Max = 500, Step = 2 },
	{ Tab = "7. Movement", Kind = "Toggle", Key = "JumpEnabled", Label = "Custom Jump Power Override", OnChange = function(on) if not on then RestorePhysicsDefaults() end end },
	{ Tab = "7. Movement", Kind = "Slider", Key = "JumpValue", Label = "Jump Power Value", Min = 50, Max = 500, Step = 5 },
	{ Tab = "7. Movement", Kind = "Toggle", Key = "InfiniteJump", Label = "Infinite Skyjump" },
	{ Tab = "7. Movement", Kind = "Toggle", Key = "Noclip", Label = "Noclip (Character)" },
	{ Tab = "7. Movement", Kind = "Toggle", Key = "BoatNoclip", Label = "Boat / Vehicle Noclip" },
	{ Tab = "7. Movement", Kind = "Toggle", Key = "FlyEnabled", Label = "Directional Camera Flight", OnChange = function(on) if on then StartFlyController() else StopFlyController() end end },
	{ Tab = "7. Movement", Kind = "Slider", Key = "FlySpeed", Label = "Flight Speed", Min = 20, Max = 500, Step = 5 },
	{ Tab = "7. Movement", Kind = "Toggle", Key = "SoruInfinite", Label = "Soru Infinite Flashstep" },
	{ Tab = "7. Movement", Kind = "Toggle", Key = "AutoFleeLowHP", Label = "Auto-Recover Sky Hover at Low HP" },
	{ Tab = "7. Movement", Kind = "Slider", Key = "FleeHPThreshold", Label = "Low HP Threshold %", Min = 5, Max = 75, Step = 1 },
	{ Tab = "7. Movement", Kind = "Toggle", Key = "AntiVoidGuard", Label = "Anti-Void Recovery Guard" },
	{ Tab = "7. Movement", Kind = "Toggle", Key = "AntiAFK", Label = "Anti-AFK Idle Keepalive" },
	{ Tab = "7. Movement", Kind = "Toggle", Key = "AutoRejoinError", Label = "Auto-Rejoin on Error / Kick" },

	-- TAB 8: FARM ESP & GFX
	{ Tab = "8. Farm ESP", Kind = "Toggle", Key = "ESPEnabled", Label = "Master Farm ESP Toggle", OnChange = function(on) if not on then ClearAllESP() end end },
	{ Tab = "8. Farm ESP", Kind = "Toggle", Key = "ESP_Bosses", Label = "Boss & Event Boss ESP" },
	{ Tab = "8. Farm ESP", Kind = "Toggle", Key = "ESP_Fruits", Label = "Spawned Devil Fruit ESP" },
	{ Tab = "8. Farm ESP", Kind = "Toggle", Key = "ESP_Chests", Label = "Treasure Chest ESP" },
	{ Tab = "8. Farm ESP", Kind = "Toggle", Key = "ESP_Distance", Label = "ESP Show Distance (m)" },
	{ Tab = "8. Farm ESP", Kind = "Toggle", Key = "ESP_HP", Label = "ESP Show Boss Health %" },
	{ Tab = "8. Farm ESP", Kind = "Slider", Key = "ESP_TextSize", Label = "ESP Text Size (px)", Min = 10, Max = 26, Step = 1 },
	{ Tab = "8. Farm ESP", Kind = "Toggle", Key = "Fullbright", Label = "Fullbright / Night Vision", OnChange = function(on)
		Lighting.Brightness = on and 2.5 or 1
		Lighting.Ambient = on and Color3.fromRGB(160, 160, 160) or Color3.fromRGB(70, 70, 70)
	end },
	{ Tab = "8. Farm ESP", Kind = "Toggle", Key = "Disable3DRender", Label = "3D Rendering Off (Headless AFK)", OnChange = function(on)
		pcall(function() RunService:Set3dRenderingEnabled(not on) end)
	end },
	{ Tab = "8. Farm ESP", Kind = "Cycle",  Key = "FPSCapValue", Label = "FPS Cap Selector", Values = { "60", "120", "240", "999" }, OnChange = function(v)
		if setfpscap then pcall(setfpscap, tonumber(v) or 240) end
	end },

	-- TAB 9: HOP & GOALS
	{ Tab = "9. Hop/Goals", Kind = "Telemetry", Key = "SessionStats", Label = "Session Rates" },
	{ Tab = "9. Hop/Goals", Kind = "Toggle", Key = "UseServerBrowser", Label = "Use __ServerBrowser + Public API" },
	{ Tab = "9. Hop/Goals", Kind = "Cycle",  Key = "HopRegion", Label = "Server Hop Region Filter", Values = { "Any", "Singapore", "Oregon", "Germany", "Hong Kong", "Brazil", "Texas" } },
	{ Tab = "9. Hop/Goals", Kind = "Slider", Key = "HopMaxPlayers", Label = "Max Server Players Filter", Min = 1, Max = 12, Step = 1 },
	{ Tab = "9. Hop/Goals", Kind = "Toggle", Key = "AvoidVisitedJobs", Label = "Avoid Recently Visited JobIds" },
	{ Tab = "9. Hop/Goals", Kind = "Toggle", Key = "ScheduledStopEnabled", Label = "Scheduled Farm Timer Stop" },
	{ Tab = "9. Hop/Goals", Kind = "Slider", Key = "ScheduledStopMinutes", Label = "Scheduled Stop Minutes", Min = 5, Max = 480, Step = 5 },
	{ Tab = "9. Hop/Goals", Kind = "Toggle", Key = "TargetLevelStop", Label = "Target Level Auto-Stop" },
	{ Tab = "9. Hop/Goals", Kind = "Slider", Key = "TargetLevelGoal", Label = "Target Level Goal", Min = 1, Max = 3000, Step = 25 },
	{ Tab = "9. Hop/Goals", Kind = "Action", Label = "Hop to Public Server Now", Fn = function() SmartServerHop("Manual server hop...") end },
	{ Tab = "9. Hop/Goals", Kind = "Action", Label = "Clear Visited Server History", Fn = function() table.clear(Runtime.VisitedJobs); SaveBossHopState(); AddLog("Cleared visited JobIds") end },

	-- TAB 10: CONFIG & AUTO-EXEC
	{ Tab = "10. Config", Kind = "Telemetry", Key = "DiagStats", Label = "Auto-Exec & Diagnostics" },
	{ Tab = "10. Config", Kind = "Toggle", Key = "AutoExecEnabled", Label = "Auto-Execute on Executor Inject", OnChange = function(on)
		if on then
			local ok = InstallAutoExecAndCache()
			AddLog(ok and "Installed autoexec/ZyvoraFarmV1_AutoExec.lua" or "writefile unavailable")
		elseif type(delfile) == "function" and type(isfile) == "function" and isfile(AUTOEXEC_FILE) then
			pcall(delfile, AUTOEXEC_FILE)
			AddLog("Removed autoexec file")
		end
	end },
	{ Tab = "10. Config", Kind = "Action", Label = "Re-Install Auto-Exec & Queue Teleport Now", Fn = function()
		local ok = InstallAutoExecAndCache()
		QueueTeleportReExec()
		AddLog(ok and "Auto-Exec + Teleport Queue refreshed!" or "Executor lacks writefile")
	end },
	{ Tab = "10. Config", Kind = "Cycle",  Key = "UIToggleKey", Label = "UI Toggle Keybind", Values = { "RightShift", "RightControl", "Insert", "End", "K" } },
	{ Tab = "10. Config", Kind = "Toggle", Key = "HotkeyFarmPause", Label = "Auto-Level Hotkey [F6]" },
	{ Tab = "10. Config", Kind = "Toggle", Key = "HotkeyBossHopToggle", Label = "Boss Hop Hotkey [F7]" },
	{ Tab = "10. Config", Kind = "Toggle", Key = "HotkeyServerHop", Label = "Server Hop Hotkey [F8]" },
	{ Tab = "10. Config", Kind = "Toggle", Key = "HotkeyPanicStop", Label = "Panic Stop Hotkey [F9]" },
	{ Tab = "10. Config", Kind = "Toggle", Key = "MiniHudVisible", Label = "Show Floating Crimson Status Strip" },
	{ Tab = "10. Config", Kind = "Action", Label = "PANIC STOP ALL MODULES", Fn = PanicStopAll },
}

-- Append a direct one-click Hunt button for every single Boss & Event Boss in BOSS_CATALOG!
for _, entry in ipairs(BOSS_CATALOG) do
	local seaTag = entry.Sea == 0 and "All Seas" or ("Sea " .. tostring(entry.Sea))
	table.insert(FEATURE_SPEC, {
		Tab = "2. Boss Hop",
		Kind = "Action",
		Label = ("Hunt [%s | %s]: %s"):format(entry.Category, seaTag, entry.Name),
		Fn = function()
			StartBossHopFor(entry.Name)
		end,
	})
end

-- ============================================================================
--  15. CLASSIC CRIMSON RED & BLACK UI RENDERER
-- ============================================================================
local function GetGuiRoot()
	if type(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	local ok, core = pcall(function() return game:GetService("CoreGui") end)
	if ok and core then return core end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local THEME = {
	Void          = Color3.fromRGB(8, 7, 9),
	Panel         = Color3.fromRGB(16, 10, 13),
	Card          = Color3.fromRGB(24, 13, 18),
	Crimson       = Color3.fromRGB(214, 24, 54),
	CrimsonBright = Color3.fromRGB(255, 48, 82),
	CrimsonDim    = Color3.fromRGB(92, 14, 28),
	Text          = Color3.fromRGB(246, 240, 242),
	Muted         = Color3.fromRGB(165, 142, 149),
	Stroke        = Color3.fromRGB(120, 22, 38),
}

local function Make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

local screenGui = Make("ScreenGui", {
	Name = "ZyvoraFarmV1",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 950,
}, GetGuiRoot())

local miniStrip = Make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(460, 26),
	BackgroundColor3 = THEME.Void,
	BorderSizePixel = 0,
}, screenGui)
Make("UICorner", { CornerRadius = UDim.new(0, 8) }, miniStrip)
Make("UIStroke", { Color = THEME.Crimson, Thickness = 1, Transparency = 0.3 }, miniStrip)

local miniLabel = Make("TextLabel", {
	Size = UDim2.new(1, -16, 1, 0),
	Position = UDim2.fromOffset(8, 0),
	BackgroundTransparency = 1,
	Text = "ZYVORA FARM v1 | Ready",
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextColor3 = THEME.Text,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, miniStrip)

local rootFrame = Make("Frame", {
	Name = "MainWindow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(600, 435),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0,
}, screenGui)
Make("UICorner", { CornerRadius = UDim.new(0, 12) }, rootFrame)
Make("UIStroke", { Color = THEME.Crimson, Thickness = 1.5, Transparency = 0.2 }, rootFrame)

local topBar = Make("Frame", {
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundColor3 = THEME.Void,
	BorderSizePixel = 0,
}, rootFrame)
Make("UICorner", { CornerRadius = UDim.new(0, 12) }, topBar)
Make("UIStroke", { Color = THEME.Stroke, Thickness = 1, Transparency = 0.35 }, topBar)

Make("TextLabel", {
	Size = UDim2.new(0, 220, 1, 0),
	Position = UDim2.fromOffset(14, 0),
	BackgroundTransparency = 1,
	Text = "ZYVORA FARM v1",
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = THEME.CrimsonBright,
	TextXAlignment = Enum.TextXAlignment.Left,
}, topBar)

local statusBadge = Make("TextLabel", {
	Size = UDim2.new(0, 285, 1, 0),
	Position = UDim2.new(1, -345, 0, 0),
	BackgroundTransparency = 1,
	Text = Runtime.StatusText,
	Font = Enum.Font.GothamMedium,
	TextSize = 11,
	TextColor3 = THEME.Muted,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, topBar)

local minBtn = Make("TextButton", {
	Size = UDim2.fromOffset(26, 26),
	Position = UDim2.new(1, -50, 0.5, -13),
	BackgroundColor3 = THEME.Card,
	Text = "—",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = THEME.Text,
	AutoButtonColor = false,
}, topBar)
Make("UICorner", { CornerRadius = UDim.new(0, 6) }, minBtn)

local closeBtn = Make("TextButton", {
	Size = UDim2.fromOffset(26, 26),
	Position = UDim2.new(1, -20, 0.5, -13),
	BackgroundColor3 = THEME.CrimsonDim,
	Text = "X",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = THEME.Text,
	AutoButtonColor = false,
}, topBar)
Make("UICorner", { CornerRadius = UDim.new(0, 6) }, closeBtn)

-- Dragging
do
	local dragging, dragOrigin, frameOrigin = false, nil, nil
	TrackConn(topBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragOrigin = inp.Position; frameOrigin = rootFrame.Position
		end
	end))
	TrackConn(UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local d = inp.Position - dragOrigin
			rootFrame.Position = UDim2.new(frameOrigin.X.Scale, frameOrigin.X.Offset + d.X, frameOrigin.Y.Scale, frameOrigin.Y.Offset + d.Y)
		end
	end))
	TrackConn(UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

local tabRail = Make("ScrollingFrame", {
	Size = UDim2.new(0, 136, 1, -54),
	Position = UDim2.fromOffset(8, 50),
	BackgroundColor3 = THEME.Void,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = THEME.Crimson,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, rootFrame)
Make("UICorner", { CornerRadius = UDim.new(0, 8) }, tabRail)
Make("UIStroke", { Color = THEME.Stroke, Thickness = 1, Transparency = 0.5 }, tabRail)
Make("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, tabRail)
Make("UIPadding", {
	PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
	PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
}, tabRail)

local contentArea = Make("Frame", {
	Size = UDim2.new(1, -156, 1, -54),
	Position = UDim2.fromOffset(150, 50),
	BackgroundColor3 = THEME.Void,
	BorderSizePixel = 0,
}, rootFrame)
Make("UICorner", { CornerRadius = UDim.new(0, 8) }, contentArea)
Make("UIStroke", { Color = THEME.Stroke, Thickness = 1, Transparency = 0.5 }, contentArea)

local pages, tabButtons, telemetryLabels = {}, {}, {}

local function SelectTab(name)
	for pName, pFrame in pairs(pages) do
		local active = (pName == name)
		pFrame.Visible = active
		tabButtons[pName].BackgroundColor3 = active and THEME.Crimson or THEME.Card
		tabButtons[pName].TextColor3 = active and THEME.Text or THEME.Muted
	end
end

local function BuildControlRow(page, item, idx)
	local row = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = idx,
		BackgroundColor3 = THEME.Card,
		BorderSizePixel = 0,
	}, page)
	Make("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
	Make("UIStroke", { Color = item.Kind == "Telemetry" and THEME.Crimson or THEME.Stroke, Thickness = 1, Transparency = 0.55 }, row)

	local title = Make("TextLabel", {
		Size = UDim2.new(1, -124, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Text = item.Label,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)

	if item.Kind == "Telemetry" then
		title.Size = UDim2.new(1, -16, 1, 0)
		title.Font = Enum.Font.GothamBold
		title.TextColor3 = THEME.CrimsonBright
		telemetryLabels[item.Key] = title

	elseif item.Kind == "Toggle" then
		local pill = Make("TextButton", {
			Size = UDim2.fromOffset(44, 20),
			Position = UDim2.new(1, -52, 0.5, -10),
			BackgroundColor3 = CFG[item.Key] and THEME.CrimsonBright or THEME.CrimsonDim,
			Text = CFG[item.Key] and "ON" or "OFF",
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = THEME.Text,
			AutoButtonColor = false,
		}, row)
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)

		local function refresh()
			local st = CFG[item.Key]
			pill.Text = st and "ON" or "OFF"
			pill.BackgroundColor3 = st and THEME.CrimsonBright or THEME.CrimsonDim
		end
		Runtime.UIControls[item.Key] = refresh

		TrackConn(pill.MouseButton1Click:Connect(function()
			CFG[item.Key] = not CFG[item.Key]
			refresh()
			if item.OnChange then pcall(item.OnChange, CFG[item.Key]) end
		end))

	elseif item.Kind == "Slider" then
		local minusBtn = Make("TextButton", {
			Size = UDim2.fromOffset(22, 20),
			Position = UDim2.new(1, -106, 0.5, -10),
			BackgroundColor3 = THEME.CrimsonDim,
			Text = "-",
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = THEME.Text,
			AutoButtonColor = false,
		}, row)
		Make("UICorner", { CornerRadius = UDim.new(0, 5) }, minusBtn)

		local valLbl = Make("TextLabel", {
			Size = UDim2.fromOffset(52, 20),
			Position = UDim2.new(1, -82, 0.5, -10),
			BackgroundTransparency = 1,
			Text = tostring(CFG[item.Key]),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = THEME.CrimsonBright,
		}, row)

		local plusBtn = Make("TextButton", {
			Size = UDim2.fromOffset(22, 20),
			Position = UDim2.new(1, -28, 0.5, -10),
			BackgroundColor3 = THEME.CrimsonDim,
			Text = "+",
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = THEME.Text,
			AutoButtonColor = false,
		}, row)
		Make("UICorner", { CornerRadius = UDim.new(0, 5) }, plusBtn)

		local function refresh() valLbl.Text = tostring(CFG[item.Key]) end
		Runtime.UIControls[item.Key] = refresh

		local function nudge(dir)
			local step = item.Step or 1
			local raw = (tonumber(CFG[item.Key]) or item.Min) + (dir * step)
			local rounded = math.floor(raw / step + 0.5) * step
			CFG[item.Key] = math.clamp(tonumber(string.format("%.4f", rounded)), item.Min, item.Max)
			refresh()
		end
		TrackConn(minusBtn.MouseButton1Click:Connect(function() nudge(-1) end))
		TrackConn(plusBtn.MouseButton1Click:Connect(function() nudge(1) end))

	elseif item.Kind == "Cycle" then
		local cycBtn = Make("TextButton", {
			Size = UDim2.fromOffset(112, 20),
			Position = UDim2.new(1, -120, 0.5, -10),
			BackgroundColor3 = THEME.CrimsonDim,
			Text = tostring(CFG[item.Key]),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = THEME.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
		}, row)
		Make("UICorner", { CornerRadius = UDim.new(0, 5) }, cycBtn)

		local function refresh() cycBtn.Text = tostring(CFG[item.Key]) end
		Runtime.UIControls[item.Key] = refresh

		TrackConn(cycBtn.MouseButton1Click:Connect(function()
			local vals = item.Values
			local curIdx = 1
			for i, v in ipairs(vals) do
				if tostring(v) == tostring(CFG[item.Key]) then curIdx = i; break end
			end
			local nextVal = vals[(curIdx % #vals) + 1]
			CFG[item.Key] = nextVal
			refresh()
			if item.OnChange then pcall(item.OnChange, nextVal) end
		end))

	elseif item.Kind == "Action" then
		title.Visible = false
		local actBtn = Make("TextButton", {
			Size = UDim2.new(1, -12, 1, -6),
			Position = UDim2.fromOffset(6, 3),
			BackgroundColor3 = THEME.CrimsonDim,
			Text = item.Label,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = THEME.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
		}, row)
		Make("UICorner", { CornerRadius = UDim.new(0, 5) }, actBtn)
		TrackConn(actBtn.MouseButton1Click:Connect(function()
			if item.Fn then pcall(item.Fn) end
		end))
	end
end

for order, tabName in ipairs(TAB_NAMES) do
	local page = Make("ScrollingFrame", {
		Name = tabName,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = THEME.Crimson,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, contentArea)
	Make("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	Make("UIPadding", {
		PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
	}, page)

	local btn = Make("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = order,
		BackgroundColor3 = THEME.Card,
		Text = tabName,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = THEME.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
	}, tabRail)
	Make("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
	Make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, btn)

	pages[tabName] = page
	tabButtons[tabName] = btn
	TrackConn(btn.MouseButton1Click:Connect(function() SelectTab(tabName) end))
end

for idx, item in ipairs(FEATURE_SPEC) do
	local targetPage = pages[item.Tab]
	if targetPage then BuildControlRow(targetPage, item, idx) end
end
SelectTab(CFG.AutoBossHop and "2. Boss Hop" or TAB_NAMES[1])

-- Live Telemetry & HUD Updater
TrackThread(function()
	while Runtime.Alive do
		task.wait(0.35)
		miniStrip.Visible = CFG.MiniHudVisible
		local banner = Runtime.AlertText ~= "" and (" | " .. Runtime.AlertText) or ""
		statusBadge.Text = Runtime.StatusText
		miniLabel.Text = ("ZYVORA v1 | Sea %d | Lv.%d | %s%s"):format(GetCurrentSea(), GetPlayerLevel(), Runtime.StatusText, banner)

		local prof = ResolveQuestProfile()
		local qInfo = prof and (prof.Mob .. " (Lv." .. prof.MinLv .. "+)") or "None"

		if telemetryLabels.FarmStats then
			telemetryLabels.FarmStats.Text = ("Sea %d | Lv.%d (+%d) | Quest: %s | Kills: %d"):format(
				GetCurrentSea(), GetPlayerLevel(), math.max(0, GetPlayerLevel() - Runtime.StartLevel), qInfo, Runtime.SessionKills
			)
		end
		if telemetryLabels.BossHopStats then
			telemetryLabels.BossHopStats.Text = ("Target: %s | Active: %s | Boss Kills: %d | Hops: %d"):format(
				CFG.BossHopTarget, CFG.AutoBossHop and "YES" or "NO", Runtime.BossKillsSession, CountVisitedJobs()
			)
		end
		if telemetryLabels.CurrencyStats then
			telemetryLabels.CurrencyStats.Text = ("Beli: %d | Frags: %d | Tool Mastery: %d"):format(
				GetPlayerBeli(), GetPlayerFrags(), GetEquippedToolMastery()
			)
		end
		if telemetryLabels.ChestStats then
			telemetryLabels.ChestStats.Text = ("Chests Grabbed: %d | Active Chests: %d | Mat: %s"):format(
				Runtime.SessionChests, #FindActiveChests(), CFG.MaterialFilter
			)
		end
		if telemetryLabels.SessionStats then
			local mins = math.max(1, math.floor((os.clock() - Runtime.StartClock) / 60))
			local beliGain = math.max(0, GetPlayerBeli() - Runtime.StartBeli)
			telemetryLabels.SessionStats.Text = ("Uptime: %dm | +Beli: %d | Visited Servers: %d"):format(
				mins, beliGain, CountVisitedJobs()
			)
		end
		if telemetryLabels.DiagStats then
			local hasAE = (type(isfile) == "function" and isfile(AUTOEXEC_FILE)) and "Installed" or "Memory-Only"
			telemetryLabels.DiagStats.Text = ("AutoExec: %s | Bosses Loaded: %d | Last: %s"):format(
				hasAE, #BOSS_CATALOG, Runtime.Logs[#Runtime.Logs] or "ready"
			)
		end
	end
end)

-- Window Controls & Global Keybinds
local minimized = false
TrackConn(minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	tabRail.Visible = not minimized
	contentArea.Visible = not minimized
	rootFrame.Size = minimized and UDim2.fromOffset(600, 44) or UDim2.fromOffset(600, 435)
end))

TrackConn(UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	local toggleKC = Enum.KeyCode[CFG.UIToggleKey] or Enum.KeyCode.RightShift
	if inp.KeyCode == toggleKC then
		CFG.UIVisible = not CFG.UIVisible
		rootFrame.Visible = CFG.UIVisible
	elseif CFG.HotkeyFarmPause and inp.KeyCode == Enum.KeyCode.F6 then
		CFG.AutoLevel = not CFG.AutoLevel
		RefreshAllUIControls()
		SetStatus(CFG.AutoLevel and "Auto Level resumed [F6]" or "Auto Level paused [F6]")
	elseif CFG.HotkeyBossHopToggle and inp.KeyCode == Enum.KeyCode.F7 then
		CFG.AutoBossHop = not CFG.AutoBossHop
		SaveBossHopState()
		RefreshAllUIControls()
		SetStatus(CFG.AutoBossHop and ("Boss Hop resumed -> " .. CFG.BossHopTarget) or "Boss Hop paused [F7]")
	elseif CFG.HotkeyServerHop and inp.KeyCode == Enum.KeyCode.F8 then
		SmartServerHop("Hotkey server hop [F8]...")
	elseif CFG.HotkeyPanicStop and inp.KeyCode == Enum.KeyCode.F9 then
		PanicStopAll()
	end
end))

TrackConn(GuiService.ErrorMessageChanged:Connect(function(msg)
	if CFG.AutoRejoinError and msg and msg ~= "" then
		QueueTeleportReExec()
		pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
	end
end))

local function CleanupAll()
	if not Runtime.Alive then return end
	Runtime.Alive = false
	for _, c in ipairs(Runtime.Connections) do pcall(function() c:Disconnect() end) end
	table.clear(Runtime.Connections)
	for _, th in ipairs(Runtime.Threads) do pcall(task.cancel, th) end
	table.clear(Runtime.Threads)
	ClearAllESP()
	RestorePhysicsDefaults()
	pcall(function() RunService:Set3dRenderingEnabled(true) end)
	if screenGui and screenGui.Parent then pcall(function() screenGui:Destroy() end) end
end

TrackConn(closeBtn.MouseButton1Click:Connect(CleanupAll))
env.ZYVORA_FARM_V1 = {
	Destroy      = CleanupAll,
	Config       = CFG,
	State        = Runtime,
	BossCatalog  = BOSS_CATALOG,
	StartBossHop = StartBossHopFor,
}
AddLog("Zyvora Farm v1 ready (" .. tostring(#BOSS_CATALOG) .. " bosses indexed)")
