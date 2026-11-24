-- ============================================================================
--  ZYVORA FARM v1  |  Complete 208-Feature Modular Farming Engine
--  Theme: Classic Crimson Red & Obsidian Black
-- ============================================================================

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

local LocalPlayer = Players.LocalPlayer

local WORLD_1 = game.PlaceId == 2753915549 or game.PlaceId == 85211729168715
local WORLD_2 = game.PlaceId == 4442272183 or game.PlaceId == 79091703265657
local WORLD_3 = game.PlaceId == 7449423635 or game.PlaceId == 100117331123089

local env = (type(getgenv) == "function" and getgenv()) or _G
if env.ZYVORA_FARM_V1 then
	pcall(function() env.ZYVORA_FARM_V1.Destroy() end)
end

-- ============================================================================
--  1. CONFIGURATION TABLE
-- ============================================================================
local CFG = {
	-- Tab 1: Auto Farm (24)
	AutoFarm             = false,
	AutoQuest            = true,
	QuestSkipPureMob     = false,
	BringMobs            = true,
	BringRadius          = 250,
	FarmHeight           = 18,
	FarmPositionMode     = "Above", -- "Above" | "Below" | "Behind" | "Orbit"
	OrbitSpeed           = 0.16,
	ClusterScoring       = true,
	BossPriority         = true,
	LowHPFinish          = true,
	LowHPFinishPct       = 18,
	SkipStuckMobs        = true,
	StuckTimeout         = 8,
	KnockbackSnapBack    = true,
	SmoothStepMove       = true,
	StepMoveSpeed        = 22,
	LevelCapFilter       = false,
	MaxLevelDelta        = 50,
	AutoEquipSlot        = true,
	PreferredSlot        = "1",
	ZoneAnchorLock       = false,

	-- Tab 2: Combat & Skills (24)
	FastAttackMobs       = false,
	FastAttackPlayers    = false,
	FastAttackMode       = "Mode2", -- "Mode1" | "Mode2"
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
	ReactiveKenDodge     = false,
	AutoV3               = false,
	AutoV4               = false,
	StackUD              = false,
	StackUDHeight        = 8,
	FaceTargetLock       = true,

	-- Tab 3: Mastery & Fruits (22)
	FruitM1              = false,
	VoidFruitM1          = false,
	FruitM1Delay         = 0.12,
	MasteryAutoStop      = false,
	MasteryGoal          = 400,
	MasterySlotRotator   = false,
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
	DropSafeFruitGuard   = true,

	-- Tab 4: Chests & Materials (18)
	AutoChestFarm        = false,
	ChestTierFilter      = "All", -- "All" | "Diamond+Gold" | "Diamond Only"
	ChestHopWhenEmpty    = false,
	ChestStepDelay       = 0.18,
	MaterialFilter       = "Any", -- "Any" | "Bones" | "Ectoplasm" | "Scrap Metal" | "Mystic Droplet" | "Vampire Fang"
	MaterialGoalCount    = 100,
	AutoSweepDrops       = false,
	FactoryCorePriority  = true,
	EliteHunterPriority  = true,
	SessionKillCounter   = true,
	AutoTouchOrbs        = false,
	ChestBoundsGuard     = true,
	ReturnFarmAfterChest = true,
	MaxChestRange        = 8000,

	-- Tab 5: Sea, Raids & TP (22)
	AutoRaidTrigger      = false,
	AutoRaidIslandClear  = false,
	AutoAwakenMove       = false,
	SeaBeastScanner      = false,
	AutoAttackSeaBeast   = false,
	DetectMirage         = true,
	DetectKitsune        = true,
	DetectPrehistoric    = true,
	SeaAlertBanner       = true,
	WalkOnWater          = false,
	ExpandWaterPlane     = false,
	TweenTravelSpeed     = 220,

	-- Tab 6: Movement & Physics (22)
	SpeedEnabled         = false,
	SpeedValue           = 65,
	JumpEnabled          = false,
	JumpValue            = 65,
	InfiniteJump         = false,
	Noclip               = false,
	BoatNoclip           = false,
	FlyEnabled           = false,
	FlySpeed             = 85,
	DodgeNoCooldown      = false,
	DashLengthEnabled    = false,
	DashLength           = 4,
	SoruInfinite         = false,
	SoruDistance         = false,
	SoruDistMult         = 2.0,
	ClickJump            = false,
	AntiVoidGuard        = true,
	CameraZoom           = 128,

	-- Tab 7: Safety & Anti-PvP (20)
	PlayerProximityAlert = false,
	ThreatRadius         = 220,
	AutoFleeLowHP        = false,
	FleeHPThreshold      = 28,
	RetreatOnPlayerNear  = false,
	HopOnPvPDamage       = false,
	IgnoreAllies         = true,
	WhitelistSelected    = "",
	PvPSafeMonitor       = true,
	AntiAFK              = true,
	HumanizedJitter      = true,
	PingAutoThrottle     = true,
	PingThrottleMs       = 250,
	RespawnBufferEnabled = true,
	RespawnBufferSec     = 1.5,

	-- Tab 8: ESP & Graphics (20)
	ESPEnabled           = false,
	ESP_Players          = true,
	ESP_Highlight        = false,
	ESP_Bosses           = true,
	ESP_Fruits           = true,
	ESP_Chests           = false,
	ESP_QuestNPC         = false,
	ESP_Distance         = true,
	ESP_HP               = true,
	ESP_FruitName        = true,
	ESP_Bounty           = true,
	ESP_TextSize         = 13,
	ESP_MaxDistance      = 3500,
	Fullbright           = false,
	PotatoGFX            = false,
	Disable3DRender      = false,
	FPSCapValue          = "240",

	-- Tab 9: Hop & Scheduler (18)
	SmartLowPopHop       = true,
	UseServerBrowser     = false,
	HopRegion            = "Any",
	HopMaxPlayers        = 8,
	AvoidVisitedJobs     = true,
	HopOnIdleTimeout     = false,
	IdleHopSeconds       = 60,
	AutoRejoinError      = false,
	ScheduledStopEnabled = false,
	ScheduledStopMinutes = 120,
	TargetLevelStop      = false,
	TargetLevelGoal      = 2600,
	TargetBeliStop       = false,
	TargetFragStop       = false,

	-- Tab 10: Config & Diagnostics (18)
	AutoSaveConfig       = false,
	UIToggleKey          = "RightShift",
	HotkeyFarmPause      = true,
	HotkeyRetreat        = true,
	HotkeyServerHop      = true,
	HotkeyPanicStop      = true,
	MiniHudVisible       = true,
	UIVisible            = true,
}

-- ============================================================================
--  2. RUNTIME STATE, LOGGING & TELEMETRY
-- ============================================================================
local Runtime = {
	Alive            = true,
	Connections      = {},
	Threads          = {},
	Whitelist        = {},
	VisitedJobs      = {},
	StuckUntil       = {},
	TargetDamageLog  = {},
	Logs             = {},
	UIControls       = {},
	WaterPad         = nil,
	ActiveTween      = nil,
	AnchorPos        = nil,
	LastSafePos      = nil,
	LastHealth       = nil,
	SpawnedAt        = 0,
	LastProgressAt   = os.clock(),
	StartClock       = os.clock(),
	StartBeli        = 0,
	StartFrags       = 0,
	StartLevel       = 1,
	SessionKills     = 0,
	SessionChests    = 0,
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

local CONFIG_DIR  = "ZyvoraFarmV1"
local CONFIG_FILE = CONFIG_DIR .. "/default.json"

local function AddLog(msg)
	local stamp = os.date("%H:%M:%S")
	local line = ("[%s] %s"):format(stamp, tostring(msg))
	table.insert(Runtime.Logs, line)
	if #Runtime.Logs > 80 then
		table.remove(Runtime.Logs, 1)
	end
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

local function JitterWait(baseSec)
	local jitter = CFG.HumanizedJitter and (math.random(0, 45) / 1000) or 0
	local pingScale = 1
	if CFG.PingAutoThrottle then
		pcall(function()
			local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			if ping > CFG.PingThrottleMs then pingScale = 1.6 end
		end)
	end
	task.wait(math.max(baseSec * pingScale + jitter, 0.01))
end

-- ============================================================================
--  3. PLAYER, DATA, WORLD & REMOTE HELPERS
-- ============================================================================
local function GetChar()
	return LocalPlayer.Character
end

local function GetHumanoid()
	local c = GetChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetHRP()
	local c = GetChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetCurrentSea()
	if WORLD_1 then return 1 end
	if WORLD_2 then return 2 end
	if WORLD_3 then return 3 end
	return 0
end

local function GetStatValue(name, fallback)
	local data = LocalPlayer:FindFirstChild("Data")
	local obj = data and data:FindFirstChild(name)
	if obj and (typeof(obj.Value) == "number" or typeof(obj.Value) == "string") then
		return obj.Value
	end
	return fallback
end

local function GetPlayerLevel()
	return tonumber(GetStatValue("Level", 1)) or 1
end

local function GetPlayerBeli()
	return tonumber(GetStatValue("Beli", 0)) or 0
end

local function GetPlayerFrags()
	return tonumber(GetStatValue("Fragments", 0)) or 0
end

local function IsValidEnemyModel(model)
	local char = GetChar()
	if not model or model == char or not model:IsA("Model") then return nil, nil end
	if Players:GetPlayerFromCharacter(model) then return nil, nil end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hrp and hrp:IsA("BasePart") and hum and hum.Health > 0 then
		return hrp, hum
	end
	return nil, nil
end

local function IsAllyPlayer(pl)
	if not CFG.IgnoreAllies then return false end
	local sc = LocalPlayer:FindFirstChild("PlayerGui")
		and LocalPlayer.PlayerGui:FindFirstChild("Main")
		and LocalPlayer.PlayerGui.Main:FindFirstChild("Allies")
		and LocalPlayer.PlayerGui.Main.Allies:FindFirstChild("ScrollingFrame")
	if not sc then return false end
	for _, f in ipairs(sc:GetChildren()) do
		if f:IsA("ImageButton") and f.Name == pl.Name then return true end
	end
	return false
end

local function IsHostilePlayer(pl)
	if not pl or pl == LocalPlayer then return false end
	if Runtime.Whitelist[pl.Name] then return false end
	if IsAllyPlayer(pl) then return false end
	return true
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
	AddLog("Remote discovery complete (CommF=" .. tostring(Runtime.CommF ~= nil) .. ", Hit=" .. tostring(Runtime.RegisterHit ~= nil) .. ")")
end

-- ============================================================================
--  4. QUEST, MOB, MATERIAL, CHEST & FRUIT RESOLVERS
-- ============================================================================
local QUEST_PROFILES = {
	{ Sea = 1, MinLv = 1,    QuestNpc = "Bandit Quest Giver",    QuestId = 1, Mob = "Bandit",             QuestPos = Vector3.new(1059, 16, 1544),  MobPos = Vector3.new(1145, 17, 1632) },
	{ Sea = 1, MinLv = 10,   QuestNpc = "Bandit Quest Giver",    QuestId = 2, Mob = "Monkey",             QuestPos = Vector3.new(1059, 16, 1544),  MobPos = Vector3.new(-1598, 36, 153) },
	{ Sea = 2, MinLv = 700,  QuestNpc = "Area Master",           QuestId = 1, Mob = "Raider",             QuestPos = Vector3.new(-427, 73, 1836),  MobPos = Vector3.new(-746, 39, 2331) },
	{ Sea = 3, MinLv = 1500, QuestNpc = "Port Town Quest Giver", QuestId = 1, Mob = "Pirate Millionaire", QuestPos = Vector3.new(-290, 44, 5580),  MobPos = Vector3.new(-46, 44, 5638) },
}

local MATERIAL_MOB_HINTS = {
	["Bones"]          = { "reborn", "living zombie", "demonic soul", "posessed" },
	["Ectoplasm"]      = { "ship deckhand", "ship engineer", "ship steward", "ship officer" },
	["Scrap Metal"]    = { "pirate", "brute", "gladiator", "mercenary" },
	["Mystic Droplet"] = { "water fighter", "sea soldier", "tide keeper" },
	["Vampire Fang"]   = { "vampire" },
}

local function ResolveQuestProfile()
	local sea = GetCurrentSea()
	local lv = GetPlayerLevel()
	local best = nil
	for _, entry in ipairs(QUEST_PROFILES) do
		if entry.Sea == sea and lv >= entry.MinLv then
			best = entry
		end
	end
	return best
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
	local myLv = GetPlayerLevel()

	local allMobs = enemies:GetChildren()
	local bestModel, bestHRP, bestHum, bestScore = nil, nil, nil, math.huge

	for _, model in ipairs(allMobs) do
		if CFG.SkipStuckMobs and Runtime.StuckUntil[model] and now < Runtime.StuckUntil[model] then
			continue
		end
		local mHRP, mHum = IsValidEnemyModel(model)
		if mHRP and mHum then
			if CFG.ZoneAnchorLock and Runtime.AnchorPos and (mHRP.Position - Runtime.AnchorPos).Magnitude > 900 then
				continue
			end
			if CFG.LevelCapFilter then
				local lvNum = tonumber(model.Name:match("%[Lv%.%s*(%d+)%]"))
				if lvNum and lvNum > (myLv + CFG.MaxLevelDelta) then continue end
			end

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

				local score = dist - clusterBonus
					- (isBoss and 500 or 0)
					- (isCore and 700 or 0)
					- (isElite and 650 or 0)

				if score < bestScore then
					bestScore = score
					bestModel = model
					bestHRP   = mHRP
					bestHum   = mHum
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
			if part then
				table.insert(found, { Object = obj, Part = part, Name = obj.Name })
			end
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
			if CFG.ChestBoundsGuard and obj.Position.Y < -200 then continue end
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
--  5. NAVIGATION, TWEEN, SLOT EQUIP & MOB GROUPING
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

local function StepMoveTo(targetCF)
	local hrp = GetHRP()
	local hum = GetHumanoid()
	if not hrp or not hum or hum.Health <= 0 then return end

	local cur = hrp.CFrame
	local dist = (targetCF.Position - cur.Position).Magnitude
	local step = math.clamp(CFG.StepMoveSpeed, 6, 60)
	local nextCF = (CFG.SmoothStepMove and dist > step)
		and cur:Lerp(targetCF, math.clamp(step / dist, 0.1, 0.9))
		or targetCF

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = nextCF
end

local function CancelActiveTween()
	if Runtime.ActiveTween then
		pcall(function() Runtime.ActiveTween:Cancel() end)
		Runtime.ActiveTween = nil
	end
end

local function TweenMoveTo(targetPos)
	local hrp = GetHRP()
	local hum = GetHumanoid()
	if not hrp or not hum or hum.Health <= 0 then return end
	CancelActiveTween()

	local dist = (targetPos - hrp.Position).Magnitude
	local spd = math.max(CFG.TweenTravelSpeed, 40)
	local tw = TweenService:Create(hrp, TweenInfo.new(dist / spd, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(targetPos),
	})
	Runtime.ActiveTween = tw
	tw:Play()
	AddLog(("Tweening %.0f studs at %d speed"):format(dist, spd))
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
--  6. COMBAT: FAST ATTACK, SKILLS, FRUITS & BUFFS
-- ============================================================================
local function CollectAuraTargets()
	local hrp = GetHRP()
	if not hrp then return {} end
	local list = {}

	local function scan(container, enabled)
		if not container or not enabled then return end
		for _, model in ipairs(container:GetChildren()) do
			if model ~= GetChar() then
				local r = model:FindFirstChild("HumanoidRootPart")
				local h = model:FindFirstChildOfClass("Humanoid")
				if r and h and h.Health > 0 and (r.Position - hrp.Position).Magnitude <= CFG.AuraRadius then
					table.insert(list, { Model = model, Root = r, Head = model:FindFirstChild("Head") or r })
					if #list >= CFG.SplashTargetCap then break end
				end
			end
		end
	end

	scan(workspace:FindFirstChild("Enemies"), CFG.FastAttackMobs)
	scan(workspace:FindFirstChild("Characters"), CFG.FastAttackPlayers)
	return list
end

local function PerformFastAttack()
	local char = GetChar()
	if not char or not (char:FindFirstChildOfClass("Tool") or char:FindFirstChild("EquippedWeapon")) then return end

	local targets = CollectAuraTargets()
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
	if cd and cd:IsA("Frame") then
		return cd.Size.X.Scale <= 0.01
	end
	return true
end

local function RunSkillRotationBurst()
	local char = GetChar()
	if not char then return end
	if CFG.LowEnergyPause then
		local energy = char:FindFirstChild("Energy")
		if energy and typeof(energy.Value) == "number" and energy.Value < 150 then
			return
		end
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
	local count = 0
	for _, cont in ipairs({ GetChar(), LocalPlayer:FindFirstChild("Backpack") }) do
		if cont then
			for _, item in ipairs(cont:GetChildren()) do
				if item:IsA("Tool") and (item.Name:lower():find("fruit", 1, true) or item.ToolTip == "Blox Fruit") then
					pcall(function()
						Runtime.CommF:InvokeServer("StoreFruit", item:GetAttribute("OriginalName") or item.Name, item)
						count += 1
					end)
				end
			end
		end
	end
	if count > 0 then AddLog("Stored " .. count .. " fruit(s)") end
end

-- ============================================================================
--  7. MOVEMENT, FLIGHT, WATER & SERVER HOP
-- ============================================================================
local function RestorePhysicsDefaults()
	CancelActiveTween()
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

local function TriggerAirStall()
	local hrp = GetHRP()
	if not hrp then return end
	local att = Instance.new("Attachment", hrp)
	local lv = Instance.new("LinearVelocity", att)
	lv.MaxForce = 5e4
	lv.VectorVelocity = Vector3.zero
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	task.delay(3, function()
		pcall(function() lv:Destroy(); att:Destroy() end)
	end)
end

local function TriggerSuperJump()
	local hrp = GetHRP()
	local hum = GetHumanoid()
	if not hrp or not hum or hum.Health <= 0 then return end
	pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
	local vy = math.sqrt(math.max(2 * workspace.Gravity * 280, 100))
	hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, vy, hrp.AssemblyLinearVelocity.Z)
end

local function SmartServerHop()
	SetStatus("Hopping server...")
	AddLog("Initiating server hop (JobId=" .. tostring(game.JobId) .. ")")
	Runtime.VisitedJobs[game.JobId] = true

	if CFG.UseServerBrowser then
		local browser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
		if browser and browser:IsA("RemoteFunction") then
			local ok, res = pcall(function() return browser:InvokeServer(1) end)
			if ok and type(res) == "table" then
				for job, info in pairs(res) do
					if job ~= game.JobId and type(info) == "table" then
						local cnt = tonumber(info.Count) or 0
						local reg = tostring(info.Region or "")
						local regOk = (CFG.HopRegion == "Any") or (reg:lower():find(CFG.HopRegion:lower(), 1, true) ~= nil)
						if regOk and cnt <= CFG.HopMaxPlayers and (not CFG.AvoidVisitedJobs or not Runtime.VisitedJobs[job]) then
							pcall(function() browser:InvokeServer("teleport", job) end)
							return
						end
					end
				end
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
					pcall(function()
						TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
					end)
					return
				end
			end
		end
	end

	pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end

local function PanicStopAll()
	local stopKeys = {
		"AutoFarm", "FastAttackMobs", "FastAttackPlayers", "AutoSkillRotation",
		"FruitM1", "VoidFruitM1", "AutoChestFarm", "AutoRaidIslandClear",
		"AutoAttackSeaBeast", "SpeedEnabled", "JumpEnabled", "FlyEnabled",
		"Noclip", "WalkOnWater", "ClickJump",
	}
	for _, k in ipairs(stopKeys) do
		CFG[k] = false
		if Runtime.UIControls[k] then pcall(Runtime.UIControls[k]) end
	end
	RestorePhysicsDefaults()
	SetStatus("PANIC STOP — all loops halted")
	AddLog("Panic stop triggered")
end

-- ============================================================================
--  8. CONFIG PERSISTENCE & PRESETS
-- ============================================================================
local function RefreshAllUIControls()
	for _, refreshFn in pairs(Runtime.UIControls) do
		pcall(refreshFn)
	end
end

local function SaveConfigFile()
	if type(writefile) ~= "function" then
		AddLog("writefile unavailable in this executor")
		return
	end
	pcall(function()
		if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(CONFIG_DIR) then
			makefolder(CONFIG_DIR)
		end
		writefile(CONFIG_FILE, HttpService:JSONEncode(CFG))
		AddLog("Saved config to " .. CONFIG_FILE)
	end)
end

local function LoadConfigFile()
	if type(readfile) ~= "function" or type(isfile) ~= "function" or not isfile(CONFIG_FILE) then
		AddLog("No saved config file found")
		return
	end
	pcall(function()
		local parsed = HttpService:JSONDecode(readfile(CONFIG_FILE))
		if type(parsed) == "table" then
			for k, v in pairs(parsed) do
				if CFG[k] ~= nil and type(CFG[k]) == type(v) then
					CFG[k] = v
				end
			end
			RefreshAllUIControls()
			AddLog("Loaded config from " .. CONFIG_FILE)
		end
	end)
end

local function ApplyPreset(name)
	if name == "LevelGrind" then
		CFG.AutoFarm = true; CFG.AutoQuest = true; CFG.QuestSkipPureMob = false
		CFG.BringMobs = true; CFG.FastAttackMobs = true; CFG.AutoHaki = true
		CFG.AutoChestFarm = false; CFG.FruitSpawnScanner = true
	elseif name == "MasteryFarm" then
		CFG.AutoFarm = true; CFG.AutoQuest = false; CFG.QuestSkipPureMob = true
		CFG.MasteryAutoStop = true; CFG.MasterySlotRotator = true
		CFG.FastAttackMobs = true; CFG.AutoSkillRotation = true
	elseif name == "ChestAndFruit" then
		CFG.AutoFarm = false; CFG.AutoChestFarm = true; CFG.ChestHopWhenEmpty = true
		CFG.FruitSpawnScanner = true; CFG.AutoCollectFruit = true; CFG.AutoStoreFruit = true
	elseif name == "SafeAFK" then
		CFG.AntiAFK = true; CFG.RetreatOnPlayerNear = true; CFG.AutoFleeLowHP = true
		CFG.PotatoGFX = true; CFG.PingAutoThrottle = true
	end
	RefreshAllUIControls()
	AddLog("Applied preset: " .. name)
end

-- ============================================================================
--  9. BACKGROUND WORKERS (FARM, COMBAT, BUFFS, WORLD, ESP)
-- ============================================================================
DiscoverRemotes()
Runtime.StartLevel = GetPlayerLevel()
Runtime.StartBeli  = GetPlayerBeli()
Runtime.StartFrags = GetPlayerFrags()

-- Primary Farm, Chest & Sea Worker
TrackThread(function()
	local angle = 0
	local trackedMob, trackedHP, trackedSince = nil, 0, 0

	while Runtime.Alive do
		JitterWait(0.08)

		-- Stop goals check
		if CFG.ScheduledStopEnabled and (os.clock() - Runtime.StartClock) >= (CFG.ScheduledStopMinutes * 60) then
			PanicStopAll()
			SetStatus("Scheduled timer reached")
			continue
		end
		if CFG.TargetLevelStop and GetPlayerLevel() >= CFG.TargetLevelGoal then
			PanicStopAll()
			SetStatus("Target level goal reached!")
			continue
		end

		if not (CFG.AutoFarm or CFG.AutoChestFarm or CFG.AutoAttackSeaBeast) then
			if CFG.HopOnIdleTimeout and (os.clock() - Runtime.LastProgressAt) > CFG.IdleHopSeconds then
				Runtime.LastProgressAt = os.clock()
				SmartServerHop()
			end
			continue
		end

		pcall(function()
			local char = GetChar()
			local hum = GetHumanoid()
			local hrp = GetHRP()
			if not char or not hum or not hrp or hum.Health <= 0 then
				SetStatus("Waiting for respawn...")
				return
			end

			if CFG.RespawnBufferEnabled and (os.clock() - Runtime.SpawnedAt) < CFG.RespawnBufferSec then
				SetStatus("Respawn safety buffer...")
				return
			end

			-- Low HP Flee
			if CFG.AutoFleeLowHP then
				local pct = (hum.Health / math.max(hum.MaxHealth, 1)) * 100
				if pct <= CFG.FleeHPThreshold then
					SetStatus(("Low HP (%.0f%%) — retreating"):format(pct))
					StepMoveTo(hrp.CFrame + Vector3.new(0, 160, 0))
					return
				end
			end

			-- Player Proximity Retreat
			if CFG.RetreatOnPlayerNear then
				for _, pl in ipairs(Players:GetPlayers()) do
					if IsHostilePlayer(pl) and pl.Character then
						local pHRP = pl.Character:FindFirstChild("HumanoidRootPart")
						if pHRP and (pHRP.Position - hrp.Position).Magnitude <= CFG.ThreatRadius then
							SetStatus("Player nearby — holding sky altitude")
							StepMoveTo(hrp.CFrame + Vector3.new(0, 140, 0))
							return
						end
					end
				end
			end

			-- Fruit Spawn Auto-Collect
			if CFG.FruitSpawnScanner and CFG.AutoCollectFruit then
				local fruits = FindSpawnedFruits()
				if #fruits > 0 then
					SetStatus("Collecting fruit: " .. fruits[1].Name)
					StepMoveTo(CFrame.new(fruits[1].Part.Position + Vector3.new(0, 2, 0)))
					Runtime.LastProgressAt = os.clock()
					return
				end
			end

			-- Auto Chest Sweep
			if CFG.AutoChestFarm then
				local chests = FindActiveChests()
				if #chests > 0 then
					local target = chests[1]
					SetStatus(("Collecting %s (%.0fm)"):format(target.Tier, target.Dist))
					StepMoveTo(CFrame.new(target.Part.Position + Vector3.new(0, 2, 0)))
					if firetouchinterest and (hrp.Position - target.Part.Position).Magnitude < 16 then
						pcall(firetouchinterest, hrp, target.Part, 0)
						pcall(firetouchinterest, hrp, target.Part, 1)
						Runtime.SessionChests += 1
					end
					Runtime.LastProgressAt = os.clock()
					return
				elseif CFG.ChestHopWhenEmpty then
					SmartServerHop()
					return
				elseif not CFG.ReturnFarmAfterChest then
					SetStatus("No chests in range")
					return
				end
			end

			if not CFG.AutoFarm then return end

			-- Quest Handling
			local profile = ResolveQuestProfile()
			local prefMob = (not CFG.QuestSkipPureMob and profile) and profile.Mob or nil

			if CFG.AutoQuest and not CFG.QuestSkipPureMob and profile and not HasActiveQuest() then
				if (hrp.Position - profile.QuestPos).Magnitude > 14 then
					SetStatus("Heading to quest: " .. profile.QuestNpc)
					StepMoveTo(CFrame.new(profile.QuestPos + Vector3.new(0, 4, 0)))
					return
				elseif Runtime.CommF then
					SetStatus("Accepting quest #" .. tostring(profile.QuestId))
					pcall(function() Runtime.CommF:InvokeServer("StartQuest", profile.QuestNpc, profile.QuestId) end)
				end
			end

			local mob, mHRP, mHum = FindBestMob(prefMob)
			if not mob or not mHRP or not mHum then
				if profile and (hrp.Position - profile.MobPos).Magnitude > 20 then
					SetStatus("Moving to spawn: " .. tostring(prefMob or "Enemies"))
					StepMoveTo(CFrame.new(profile.MobPos + Vector3.new(0, CFG.FarmHeight, 0)))
				else
					SetStatus("Scanning for spawns...")
				end
				return
			end

			-- Stuck Detection
			if trackedMob ~= mob then
				trackedMob = mob
				trackedHP = mHum.Health
				trackedSince = os.clock()
			elseif mHum.Health < trackedHP then
				trackedHP = mHum.Health
				trackedSince = os.clock()
				Runtime.LastProgressAt = os.clock()
			elseif CFG.SkipStuckMobs and (os.clock() - trackedSince) > CFG.StuckTimeout then
				Runtime.StuckUntil[mob] = os.clock() + 25
				AddLog("Blacklisted stuck mob: " .. mob.Name)
				trackedMob = nil
				return
			end

			if CFG.AutoEquipSlot then
				EquipSlot(CFG.PreferredSlot)
			end

			SetStatus("Farming: " .. mob.Name)
			GroupNearbyMobs(mHRP.Position, prefMob)

			angle += CFG.OrbitSpeed
			local h = CFG.FarmHeight
			local offset = Vector3.new(0, h, 0)
			if CFG.FarmPositionMode == "Below" then
				offset = Vector3.new(0, -h, 0)
			elseif CFG.FarmPositionMode == "Behind" then
				offset = -mHRP.CFrame.LookVector * (h * 0.7) + Vector3.new(0, 4, 0)
			elseif CFG.FarmPositionMode == "Orbit" then
				offset = Vector3.new(math.cos(angle) * h, h * 0.6, math.sin(angle) * h)
			end

			local desiredPos = mHRP.Position + offset
			local cf = CFG.FaceTargetLock and CFrame.lookAt(desiredPos, mHRP.Position) or CFrame.new(desiredPos)
			StepMoveTo(cf)
		end)
	end
end)

-- Fast Attack & Skill Rotation Worker
TrackThread(function()
	local lastSkillAt = 0
	while Runtime.Alive do
		if CFG.FastAttackMobs or CFG.FastAttackPlayers then
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
			pcall(FireFruitM1, true)
			task.wait(0.25)
		elseif CFG.FruitM1 then
			pcall(FireFruitM1, false)
			JitterWait(CFG.FruitM1Delay)
		else
			task.wait(0.25)
		end
	end
end)

-- Buffs, Fruits, Raids, Mirage & Threat Scanner Worker
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
			if CFG.AutoStoreFruit then
				StoreAllFruitsNow()
			end
			if CFG.AutoRollFruit and Runtime.CommF and GetPlayerBeli() >= CFG.MinBeliReserve then
				Runtime.CommF:InvokeServer("Cousin", "Buy")
			end
			if CFG.AutoBoneSurprise and Runtime.CommF then
				Runtime.CommF:InvokeServer("Bones", "Buy", 1, 1)
			end
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

-- Physics, Noclip, Water, Anti-Void & Camera Stepped Hook
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
			pad.Name = "ZyvoraWaterPad"
			pad.Size = Vector3.new(36, 1, 36)
			pad.Anchored = true
			pad.CanCollide = true
			pad.Transparency = 1
			pad.Parent = workspace
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
	if char and CFG.DashLengthEnabled then
		pcall(function()
			char:SetAttribute("DashLength", CFG.DashLength)
			char:SetAttribute("DashLengthAir", CFG.DashLength)
		end)
	end

	LocalPlayer.CameraMaxZoomDistance = CFG.CameraZoom
end))

-- Anti-AFK & Character Respawn Tracking
TrackConn(LocalPlayer.Idled:Connect(function()
	if CFG.AntiAFK then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end))

TrackConn(LocalPlayer.CharacterAdded:Connect(function()
	Runtime.SpawnedAt = os.clock()
	Runtime.AnchorPos = nil
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

TrackConn(UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe or inp.UserInputType ~= Enum.UserInputType.MouseButton1 or not CFG.ClickJump then return end
	local hrp = GetHRP()
	local cam = workspace.CurrentCamera
	if hrp and cam then
		local loc = UserInputService:GetMouseLocation()
		local ray = cam:ViewportPointToRay(loc.X, loc.Y)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = CFrame.new(hrp.Position + ray.Direction.Unit * 300)
	end
end))

-- ============================================================================
--  10. ESP OVERLAY MANAGER
-- ============================================================================
local ESPStore = {}

local function ClearAllESP()
	for key, inst in pairs(ESPStore) do
		pcall(function() inst:Destroy() end)
		ESPStore[key] = nil
	end
end

TrackThread(function()
	while Runtime.Alive do
		task.wait(0.4)
		if not CFG.ESPEnabled then
			ClearAllESP()
			continue
		end

		pcall(function()
			local myRoot = GetHRP()
			if not myRoot then return end

			if CFG.ESP_Players then
				for _, pl in ipairs(Players:GetPlayers()) do
					if pl ~= LocalPlayer and pl.Character then
						local head = pl.Character:FindFirstChild("Head")
						local r = pl.Character:FindFirstChild("HumanoidRootPart")
						local h = pl.Character:FindFirstChildOfClass("Humanoid")
						if head and r and h and h.Health > 0 then
							local dist = (r.Position - myRoot.Position).Magnitude
							if dist <= CFG.ESP_MaxDistance then
								local bb = ESPStore[pl]
								if not bb or not bb.Parent then
									bb = Instance.new("BillboardGui")
									bb.Size = UDim2.fromOffset(200, 70)
									bb.StudsOffset = Vector3.new(0, 3, 0)
									bb.AlwaysOnTop = true
									local lbl = Instance.new("TextLabel", bb)
									lbl.Name = "Info"
									lbl.Size = UDim2.fromScale(1, 1)
									lbl.BackgroundTransparency = 1
									lbl.Font = Enum.Font.GothamBold
									lbl.TextColor3 = Color3.fromRGB(255, 65, 95)
									lbl.TextStrokeTransparency = 0
									bb.Parent = head
									ESPStore[pl] = bb
								end
								local info = bb:FindFirstChild("Info")
								if info then
									info.TextSize = CFG.ESP_TextSize
									local parts = { pl.Name }
									if CFG.ESP_Distance then table.insert(parts, math.floor(dist) .. "m") end
									if CFG.ESP_HP then table.insert(parts, math.floor((h.Health / math.max(h.MaxHealth, 1)) * 100) .. "% HP") end
									info.Text = table.concat(parts, " | ")
								end
							end
						end
					end
				end
			end
		end)
	end
end)

-- ============================================================================
--  11. DECLARATIVE 208-FEATURE CATALOG (10 TABS)
-- ============================================================================
local TAB_NAMES = {
	"1. Farm", "2. Combat", "3. Mastery", "4. Chests", "5. Sea/Raid",
	"6. Move", "7. Safety", "8. ESP/GFX", "9. Hop/Stop", "10. Config"
}

local FEATURE_SPEC = {
	-- TAB 1: FARM (24)
	{ Tab = "1. Farm", Kind = "Telemetry", Key = "FarmStats", Label = "Farm Telemetry" },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "AutoFarm", Label = "Auto Farm Master Toggle" },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "AutoQuest", Label = "Auto Quest Giver Loop" },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "QuestSkipPureMob", Label = "Quest-Skip Pure Mob Mode" },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "BringMobs", Label = "Smart Mob Magnet (Bring Mobs)" },
	{ Tab = "1. Farm", Kind = "Slider", Key = "BringRadius", Label = "Mob Magnet Radius", Min = 50, Max = 600, Step = 10 },
	{ Tab = "1. Farm", Kind = "Slider", Key = "FarmHeight", Label = "Farm Hover Height", Min = 4, Max = 45, Step = 1 },
	{ Tab = "1. Farm", Kind = "Cycle",  Key = "FarmPositionMode", Label = "Farm Positioning Mode", Values = { "Above", "Below", "Behind", "Orbit" } },
	{ Tab = "1. Farm", Kind = "Slider", Key = "OrbitSpeed", Label = "Orbit Angular Speed", Min = 0.05, Max = 0.50, Step = 0.01 },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "ClusterScoring", Label = "High-Density Cluster Scoring" },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "BossPriority", Label = "Boss Priority Interrupt" },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "LowHPFinish", Label = "Low-HP Target Finish Mode" },
	{ Tab = "1. Farm", Kind = "Slider", Key = "LowHPFinishPct", Label = "Low-HP Finish Threshold %", Min = 5, Max = 40, Step = 1 },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "SkipStuckMobs", Label = "Stuck / Unreachable Mob Blacklist" },
	{ Tab = "1. Farm", Kind = "Slider", Key = "StuckTimeout", Label = "Stuck Mob Timeout (s)", Min = 3, Max = 20, Step = 1 },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "KnockbackSnapBack", Label = "Knockback Anchor Snap-Back" },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "SmoothStepMove", Label = "Smooth Step-Lerp Navigation" },
	{ Tab = "1. Farm", Kind = "Slider", Key = "StepMoveSpeed", Label = "Navigation Step Speed", Min = 8, Max = 45, Step = 1 },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "LevelCapFilter", Label = "Target Level Cap Filter" },
	{ Tab = "1. Farm", Kind = "Slider", Key = "MaxLevelDelta", Label = "Max Level Delta", Min = 0, Max = 200, Step = 5 },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "AutoEquipSlot", Label = "Auto-Equip Farm Slot" },
	{ Tab = "1. Farm", Kind = "Cycle",  Key = "PreferredSlot", Label = "Preferred Farm Slot", Values = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" } },
	{ Tab = "1. Farm", Kind = "Toggle", Key = "ZoneAnchorLock", Label = "Farm Anchor Zone Lock" },
	{ Tab = "1. Farm", Kind = "Action", Label = "Reset Stuck Mob Blacklist", Fn = function() table.clear(Runtime.StuckUntil); AddLog("Cleared stuck mob blacklist") end },

	-- TAB 2: COMBAT (24)
	{ Tab = "2. Combat", Kind = "Toggle", Key = "FastAttackMobs", Label = "Fast Attack Aura (Mobs)" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "FastAttackPlayers", Label = "Fast Attack Aura (Players)" },
	{ Tab = "2. Combat", Kind = "Cycle",  Key = "FastAttackMode", Label = "Fast Attack Remote Mode", Values = { "Mode1", "Mode2" } },
	{ Tab = "2. Combat", Kind = "Slider", Key = "AttackDelay", Label = "Attack Cadence Delay (s)", Min = 0.02, Max = 0.30, Step = 0.01 },
	{ Tab = "2. Combat", Kind = "Slider", Key = "AuraRadius", Label = "Aura Hit Radius (studs)", Min = 30, Max = 500, Step = 10 },
	{ Tab = "2. Combat", Kind = "Slider", Key = "SplashTargetCap", Label = "Multi-Target Splash Cap", Min = 1, Max = 25, Step = 1 },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "AutoSkillRotation", Label = "Auto-Skill Rotation Master" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "RotSkillZ", Label = "Use Skill Z in Rotation" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "RotSkillX", Label = "Use Skill X in Rotation" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "RotSkillC", Label = "Use Skill C in Rotation" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "RotSkillV", Label = "Use Skill V in Rotation" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "RotSkillF", Label = "Use Skill F in Rotation" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "CheckSkillCooldownUI", Label = "Read Skill Cooldown UI" },
	{ Tab = "2. Combat", Kind = "Slider", Key = "SkillCastDelay", Label = "Skill Cast Interval (s)", Min = 0.15, Max = 1.50, Step = 0.05 },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "LowEnergyPause", Label = "Low-Energy Skill Pause" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "AutoHaki", Label = "Auto Buso Haki" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "AutoKen", Label = "Auto Observation (Ken)" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "ReactiveKenDodge", Label = "Reactive Ken Dodge" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "AutoV3", Label = "Auto Race V3 Ability" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "AutoV4", Label = "Auto Race V4 Awakening" },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "StackUD", Label = "Stack UD Micro-Hop" },
	{ Tab = "2. Combat", Kind = "Slider", Key = "StackUDHeight", Label = "Stack UD Height (studs)", Min = 2, Max = 20, Step = 1 },
	{ Tab = "2. Combat", Kind = "Toggle", Key = "FaceTargetLock", Label = "Face Target Orientation Lock" },
	{ Tab = "2. Combat", Kind = "Action", Label = "Trigger Manual Skill Burst Now", Fn = RunSkillRotationBurst },

	-- TAB 3: MASTERY & FRUITS (22)
	{ Tab = "3. Mastery", Kind = "Telemetry", Key = "CurrencyStats", Label = "Currency & Mastery" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "FruitM1", Label = "Fruit M1 Auto-Fire" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "VoidFruitM1", Label = "Void Fruit M1 Mode" },
	{ Tab = "3. Mastery", Kind = "Slider", Key = "FruitM1Delay", Label = "Fruit M1 Delay (s)", Min = 0.05, Max = 0.50, Step = 0.01 },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "MasteryAutoStop", Label = "Target Mastery Auto-Stop" },
	{ Tab = "3. Mastery", Kind = "Slider", Key = "MasteryGoal", Label = "Target Mastery Goal", Min = 1, Max = 600, Step = 10 },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "MasterySlotRotator", Label = "Multi-Slot Mastery Rotator" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "RotSlot1", Label = "Include Slot 1 (Melee)" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "RotSlot2", Label = "Include Slot 2 (Fruit)" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "RotSlot3", Label = "Include Slot 3 (Sword)" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "RotSlot4", Label = "Include Slot 4 (Gun)" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "AutoStoreFruit", Label = "Auto Store Physical Fruits" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "FruitSpawnScanner", Label = "Spawned Fruit Scanner" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "AutoCollectFruit", Label = "Auto-Collect Spawned Fruits" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "FruitAlertBanner", Label = "Fruit Spawn Alert Banner" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "AutoRollFruit", Label = "Auto Random Fruit Roll (Cousin)" },
	{ Tab = "3. Mastery", Kind = "Slider", Key = "MinBeliReserve", Label = "Min Beli Reserve for Rolls", Min = 0, Max = 5000000, Step = 50000 },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "AutoBoneSurprise", Label = "Auto-Buy Bone Surprise" },
	{ Tab = "3. Mastery", Kind = "Toggle", Key = "DropSafeFruitGuard", Label = "Drop-Safe Fruit Guard" },
	{ Tab = "3. Mastery", Kind = "Action", Label = "Store All Inventory Fruits Now", Fn = StoreAllFruitsNow },
	{ Tab = "3. Mastery", Kind = "Action", Label = "Scan Workspace Fruits Now", Fn = function() AddLog("Active world fruits: " .. #FindSpawnedFruits()) end },
	{ Tab = "3. Mastery", Kind = "Action", Label = "Equip Preferred Farm Slot Now", Fn = function() EquipSlot(CFG.PreferredSlot) end },

	-- TAB 4: CHESTS & MATERIALS (18)
	{ Tab = "4. Chests", Kind = "Telemetry", Key = "ChestStats", Label = "Chests & Kills" },
	{ Tab = "4. Chests", Kind = "Toggle", Key = "AutoChestFarm", Label = "Auto Chest Farm Loop" },
	{ Tab = "4. Chests", Kind = "Cycle",  Key = "ChestTierFilter", Label = "Chest Priority Tier", Values = { "All", "Diamond+Gold", "Diamond Only" } },
	{ Tab = "4. Chests", Kind = "Toggle", Key = "ChestHopWhenEmpty", Label = "Chest Hop When Empty" },
	{ Tab = "4. Chests", Kind = "Slider", Key = "ChestStepDelay", Label = "Chest Collection Delay (s)", Min = 0.05, Max = 0.60, Step = 0.01 },
	{ Tab = "4. Chests", Kind = "Cycle",  Key = "MaterialFilter", Label = "Material Target Selector", Values = { "Any", "Bones", "Ectoplasm", "Scrap Metal", "Mystic Droplet", "Vampire Fang" } },
	{ Tab = "4. Chests", Kind = "Slider", Key = "MaterialGoalCount", Label = "Material Target Count", Min = 1, Max = 500, Step = 5 },
	{ Tab = "4. Chests", Kind = "Toggle", Key = "AutoSweepDrops", Label = "Auto-Collect Dropped Tools/Parts" },
	{ Tab = "4. Chests", Kind = "Toggle", Key = "FactoryCorePriority", Label = "Factory / Pirate Raid Core Priority" },
	{ Tab = "4. Chests", Kind = "Toggle", Key = "EliteHunterPriority", Label = "Elite Hunter Mob Priority" },
	{ Tab = "4. Chests", Kind = "Toggle", Key = "SessionKillCounter", Label = "Session Kill Milestone Counter" },
	{ Tab = "4. Chests", Kind = "Toggle", Key = "AutoTouchOrbs", Label = "Auto-Touch Spawned Orbs" },
	{ Tab = "4. Chests", Kind = "Toggle", Key = "ChestBoundsGuard", Label = "Safe Chest Bounds Guard" },
	{ Tab = "4. Chests", Kind = "Toggle", Key = "ReturnFarmAfterChest", Label = "Auto-Return to Farm After Chests" },
	{ Tab = "4. Chests", Kind = "Slider", Key = "MaxChestRange", Label = "Max Chest Search Range", Min = 200, Max = 15000, Step = 200 },
	{ Tab = "4. Chests", Kind = "Action", Label = "Move to Nearest Chest Now", Fn = function() local c = FindActiveChests(); if c[1] then StepMoveTo(CFrame.new(c[1].Part.Position)) end end },
	{ Tab = "4. Chests", Kind = "Action", Label = "Scan Active Chest Count", Fn = function() AddLog("Active chests found: " .. #FindActiveChests()) end },
	{ Tab = "4. Chests", Kind = "Action", Label = "Reset Kill & Chest Counters", Fn = function() Runtime.SessionKills = 0; Runtime.SessionChests = 0 end },

	-- TAB 5: SEA, RAIDS & TP (22)
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "AutoRaidTrigger", Label = "Auto Trigger Raid Pedestal" },
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "AutoRaidIslandClear", Label = "Auto Raid Island Clearer" },
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "AutoAwakenMove", Label = "Auto Awaken Next Move" },
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "SeaBeastScanner", Label = "Sea Beast / Sea Threat Scanner" },
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "AutoAttackSeaBeast", Label = "Auto-Attack Sea Beasts" },
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "DetectMirage", Label = "Mirage Island Detector" },
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "DetectKitsune", Label = "Kitsune Island Detector" },
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "DetectPrehistoric", Label = "Prehistoric Island Detector" },
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "SeaAlertBanner", Label = "Sea Event Alert Banner" },
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "WalkOnWater", Label = "Walk on Water Pad" },
	{ Tab = "5. Sea/Raid", Kind = "Toggle", Key = "ExpandWaterPlane", Label = "Expand WaterBase-Plane" },
	{ Tab = "5. Sea/Raid", Kind = "Slider", Key = "TweenTravelSpeed", Label = "Tween Travel Speed", Min = 50, Max = 450, Step = 10 },
	{ Tab = "5. Sea/Raid", Kind = "Action", Label = "Remove Water Surface", Fn = function() pcall(function() local w = workspace.Map:FindFirstChild("WaterBase-Plane"); if w then w:Destroy() end end) end },
	{ Tab = "5. Sea/Raid", Kind = "Action", Label = "Remove Lava Hazards", Fn = function() pcall(function() for _, v in ipairs(workspace:GetDescendants()) do if v.Name == "Lava" then v:Destroy() end end end) end },
	{ Tab = "5. Sea/Raid", Kind = "Action", Label = "Remove Fog & Lighting Layers", Fn = function() pcall(function() Lighting.FogEnd = 9e9; local l = Lighting:FindFirstChild("LightingLayers"); if l then l:Destroy() end end) end },
	{ Tab = "5. Sea/Raid", Kind = "Action", Label = "Travel to First Sea", Fn = function() if Runtime.CommF then pcall(function() Runtime.CommF:InvokeServer("TravelMain") end) end end },
	{ Tab = "5. Sea/Raid", Kind = "Action", Label = "Travel to Second Sea", Fn = function() if Runtime.CommF then pcall(function() Runtime.CommF:InvokeServer("TravelDressrosa") end) end end },
	{ Tab = "5. Sea/Raid", Kind = "Action", Label = "Travel to Third Sea", Fn = function() if Runtime.CommF then pcall(function() Runtime.CommF:InvokeServer("TravelZou") end) end end },
	{ Tab = "5. Sea/Raid", Kind = "Action", Label = "Tween TP: Sea 2 Mansion", Fn = function() TweenMoveTo(Vector3.new(-390, 332, 673)) end },
	{ Tab = "5. Sea/Raid", Kind = "Action", Label = "Tween TP: Sea 3 Castle on Sea", Fn = function() TweenMoveTo(Vector3.new(-4999, 314, -3010)) end },
	{ Tab = "5. Sea/Raid", Kind = "Action", Label = "Tween TP: Sea 3 Floating Turtle", Fn = function() TweenMoveTo(Vector3.new(-11352, 331, -10368)) end },
	{ Tab = "5. Sea/Raid", Kind = "Action", Label = "Cancel Active Tween", Fn = CancelActiveTween },

	-- TAB 6: MOVEMENT & PHYSICS (22)
	{ Tab = "6. Move", Kind = "Telemetry", Key = "MoveStats", Label = "Position & Speed" },
	{ Tab = "6. Move", Kind = "Toggle", Key = "SpeedEnabled", Label = "Custom WalkSpeed Override", OnChange = function(on) if not on then RestorePhysicsDefaults() end end },
	{ Tab = "6. Move", Kind = "Slider", Key = "SpeedValue", Label = "WalkSpeed Value", Min = 16, Max = 500, Step = 2 },
	{ Tab = "6. Move", Kind = "Toggle", Key = "JumpEnabled", Label = "Custom Jump Power Override", OnChange = function(on) if not on then RestorePhysicsDefaults() end end },
	{ Tab = "6. Move", Kind = "Slider", Key = "JumpValue", Label = "Jump Power Value", Min = 50, Max = 500, Step = 5 },
	{ Tab = "6. Move", Kind = "Toggle", Key = "InfiniteJump", Label = "Infinite Skyjump" },
	{ Tab = "6. Move", Kind = "Toggle", Key = "Noclip", Label = "Noclip (Character)" },
	{ Tab = "6. Move", Kind = "Toggle", Key = "BoatNoclip", Label = "Boat / Vehicle Noclip" },
	{ Tab = "6. Move", Kind = "Toggle", Key = "FlyEnabled", Label = "Directional Camera Flight" },
	{ Tab = "6. Move", Kind = "Slider", Key = "FlySpeed", Label = "Flight Speed", Min = 20, Max = 500, Step = 5 },
	{ Tab = "6. Move", Kind = "Toggle", Key = "DodgeNoCooldown", Label = "Dodge No-Cooldown" },
	{ Tab = "6. Move", Kind = "Toggle", Key = "DashLengthEnabled", Label = "Dash Length Multiplier Toggle" },
	{ Tab = "6. Move", Kind = "Slider", Key = "DashLength", Label = "Dash Length Multiplier", Min = 1, Max = 20, Step = 1 },
	{ Tab = "6. Move", Kind = "Toggle", Key = "SoruInfinite", Label = "Soru Infinite Flashstep" },
	{ Tab = "6. Move", Kind = "Toggle", Key = "SoruDistance", Label = "Soru Distance Boost" },
	{ Tab = "6. Move", Kind = "Slider", Key = "SoruDistMult", Label = "Soru Distance Multiplier", Min = 1, Max = 5, Step = 0.1 },
	{ Tab = "6. Move", Kind = "Toggle", Key = "ClickJump", Label = "Click-to-Dash (300 Studs)" },
	{ Tab = "6. Move", Kind = "Toggle", Key = "AntiVoidGuard", Label = "Anti-Void Recovery Guard" },
	{ Tab = "6. Move", Kind = "Slider", Key = "CameraZoom", Label = "Camera Max Zoom Distance", Min = 16, Max = 2000, Step = 16 },
	{ Tab = "6. Move", Kind = "Action", Label = "Trigger Air Stall (3s Zero-Drop)", Fn = TriggerAirStall },
	{ Tab = "6. Move", Kind = "Action", Label = "Trigger Super Launch Jump", Fn = TriggerSuperJump },
	{ Tab = "6. Move", Kind = "Action", Label = "Reset Physics & WalkSpeed", Fn = RestorePhysicsDefaults },

	-- TAB 7: SAFETY & ANTI-PVP (20)
	{ Tab = "7. Safety", Kind = "Telemetry", Key = "SafetyStats", Label = "Threat & Ping" },
	{ Tab = "7. Safety", Kind = "Toggle", Key = "PlayerProximityAlert", Label = "Nearby Player Proximity Alert" },
	{ Tab = "7. Safety", Kind = "Slider", Key = "ThreatRadius", Label = "Player Threat Alert Radius", Min = 50, Max = 1000, Step = 10 },
	{ Tab = "7. Safety", Kind = "Toggle", Key = "AutoFleeLowHP", Label = "Auto-Flee at Low HP" },
	{ Tab = "7. Safety", Kind = "Slider", Key = "FleeHPThreshold", Label = "Low HP Flee Threshold %", Min = 5, Max = 75, Step = 1 },
	{ Tab = "7. Safety", Kind = "Toggle", Key = "RetreatOnPlayerNear", Label = "Auto-Retreat on Player Approach" },
	{ Tab = "7. Safety", Kind = "Toggle", Key = "HopOnPvPDamage", Label = "Auto-Hop on PvP Attack" },
	{ Tab = "7. Safety", Kind = "Toggle", Key = "IgnoreAllies", Label = "Ignore Allies & Crew" },
	{ Tab = "7. Safety", Kind = "Toggle", Key = "PvPSafeMonitor", Label = "PvP / Safe State Monitor" },
	{ Tab = "7. Safety", Kind = "Toggle", Key = "AntiAFK", Label = "Anti-AFK Idle Keepalive" },
	{ Tab = "7. Safety", Kind = "Toggle", Key = "HumanizedJitter", Label = "Humanized Action Jitter" },
	{ Tab = "7. Safety", Kind = "Toggle", Key = "PingAutoThrottle", Label = "Ping Spike Auto-Throttle" },
	{ Tab = "7. Safety", Kind = "Slider", Key = "PingThrottleMs", Label = "Ping Throttle Threshold (ms)", Min = 100, Max = 600, Step = 10 },
	{ Tab = "7. Safety", Kind = "Toggle", Key = "RespawnBufferEnabled", Label = "Respawn Cooldown Buffer" },
	{ Tab = "7. Safety", Kind = "Slider", Key = "RespawnBufferSec", Label = "Respawn Buffer Delay (s)", Min = 0.5, Max = 5.0, Step = 0.5 },
	{ Tab = "7. Safety", Kind = "Action", Label = "Whitelist Nearest Player", Fn = function()
		local r = GetHRP(); if not r then return end
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
				Runtime.Whitelist[pl.Name] = true
				AddLog("Whitelisted: " .. pl.Name)
				break
			end
		end
	end },
	{ Tab = "7. Safety", Kind = "Action", Label = "Whitelist All Current Players", Fn = function()
		for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LocalPlayer then Runtime.Whitelist[pl.Name] = true end end
		AddLog("Whitelisted all players in server")
	end },
	{ Tab = "7. Safety", Kind = "Action", Label = "Clear Player Whitelist", Fn = function() table.clear(Runtime.Whitelist); AddLog("Cleared whitelist") end },
	{ Tab = "7. Safety", Kind = "Action", Label = "Emergency Safe-Sky Lift (+350)", Fn = function()
		local r = GetHRP(); if r then r.AssemblyLinearVelocity = Vector3.zero; r.CFrame = r.CFrame + Vector3.new(0, 350, 0) end
	end },
	{ Tab = "7. Safety", Kind = "Action", Label = "Clear Alert Banner", Fn = function() SetAlert("") end },

	-- TAB 8: ESP & GRAPHICS (20)
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESPEnabled", Label = "Master ESP Toggle", OnChange = function(on) if not on then ClearAllESP() end end },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESP_Players", Label = "Player ESP" },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESP_Highlight", Label = "Player Chams / Highlight" },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESP_Bosses", Label = "Boss & Elite ESP" },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESP_Fruits", Label = "Spawned Fruit ESP" },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESP_Chests", Label = "Chest ESP" },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESP_QuestNPC", Label = "Quest NPC Waypoint Beacon" },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESP_Distance", Label = "ESP Show Distance" },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESP_HP", Label = "ESP Show Health %" },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESP_FruitName", Label = "ESP Show Devil Fruit" },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "ESP_Bounty", Label = "ESP Show Bounty/Honor" },
	{ Tab = "8. ESP/GFX", Kind = "Slider", Key = "ESP_TextSize", Label = "ESP Text Size (px)", Min = 10, Max = 26, Step = 1 },
	{ Tab = "8. ESP/GFX", Kind = "Slider", Key = "ESP_MaxDistance", Label = "ESP Max Render Distance", Min = 250, Max = 10000, Step = 250 },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "Fullbright", Label = "Fullbright / Night Vision", OnChange = function(on)
		Lighting.Brightness = on and 2.5 or 1
		Lighting.Ambient = on and Color3.fromRGB(160, 160, 160) or Color3.fromRGB(70, 70, 70)
	end },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "PotatoGFX", Label = "Potato / Low-GFX AFK Mode" },
	{ Tab = "8. ESP/GFX", Kind = "Toggle", Key = "Disable3DRender", Label = "3D Rendering Off (Headless AFK)", OnChange = function(on)
		pcall(function() RunService:Set3dRenderingEnabled(not on) end)
	end },
	{ Tab = "8. ESP/GFX", Kind = "Cycle",  Key = "FPSCapValue", Label = "FPS Cap Selector", Values = { "60", "120", "240", "999" }, OnChange = function(v)
		if setfpscap then pcall(setfpscap, tonumber(v) or 240) end
	end },
	{ Tab = "8. ESP/GFX", Kind = "Action", Label = "Unlock FPS Cap (999) Now", Fn = function() if setfpscap then pcall(setfpscap, 999) end end },
	{ Tab = "8. ESP/GFX", Kind = "Action", Label = "Strip Particles & Decals Now", Fn = function()
		pcall(function()
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("ParticleEmitter") or d:IsA("Trail") then d.Enabled = false
				elseif d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1 end
			end
		end)
	end },
	{ Tab = "8. ESP/GFX", Kind = "Action", Label = "Clear All ESP Objects Now", Fn = ClearAllESP },

	-- TAB 9: HOP & SCHEDULER (18)
	{ Tab = "9. Hop/Stop", Kind = "Telemetry", Key = "SessionStats", Label = "Session Rates" },
	{ Tab = "9. Hop/Stop", Kind = "Toggle", Key = "SmartLowPopHop", Label = "Smart Low-Pop Server Hop" },
	{ Tab = "9. Hop/Stop", Kind = "Toggle", Key = "UseServerBrowser", Label = "Use __ServerBrowser Remote" },
	{ Tab = "9. Hop/Stop", Kind = "Cycle",  Key = "HopRegion", Label = "Server Hop Region Filter", Values = { "Any", "Singapore", "Oregon", "Germany", "Hong Kong", "Brazil", "Texas" } },
	{ Tab = "9. Hop/Stop", Kind = "Slider", Key = "HopMaxPlayers", Label = "Max Server Players Filter", Min = 1, Max = 12, Step = 1 },
	{ Tab = "9. Hop/Stop", Kind = "Toggle", Key = "AvoidVisitedJobs", Label = "Avoid Recently Visited JobIds" },
	{ Tab = "9. Hop/Stop", Kind = "Toggle", Key = "HopOnIdleTimeout", Label = "Hop When Farm Idle Timeout" },
	{ Tab = "9. Hop/Stop", Kind = "Slider", Key = "IdleHopSeconds", Label = "Idle Hop Timeout (s)", Min = 15, Max = 180, Step = 5 },
	{ Tab = "9. Hop/Stop", Kind = "Toggle", Key = "AutoRejoinError", Label = "Auto-Rejoin on Error / Kick" },
	{ Tab = "9. Hop/Stop", Kind = "Toggle", Key = "ScheduledStopEnabled", Label = "Scheduled Farm Timer Stop" },
	{ Tab = "9. Hop/Stop", Kind = "Slider", Key = "ScheduledStopMinutes", Label = "Scheduled Stop Minutes", Min = 5, Max = 480, Step = 5 },
	{ Tab = "9. Hop/Stop", Kind = "Toggle", Key = "TargetLevelStop", Label = "Target Level Auto-Stop" },
	{ Tab = "9. Hop/Stop", Kind = "Slider", Key = "TargetLevelGoal", Label = "Target Level Goal", Min = 1, Max = 3000, Step = 25 },
	{ Tab = "9. Hop/Stop", Kind = "Toggle", Key = "TargetBeliStop", Label = "Target Beli Auto-Stop" },
	{ Tab = "9. Hop/Stop", Kind = "Toggle", Key = "TargetFragStop", Label = "Target Fragments Auto-Stop" },
	{ Tab = "9. Hop/Stop", Kind = "Action", Label = "Hop to Public Server Now", Fn = SmartServerHop },
	{ Tab = "9. Hop/Stop", Kind = "Action", Label = "Rejoin Current Server Now", Fn = function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end) end },
	{ Tab = "9. Hop/Stop", Kind = "Action", Label = "Clear Visited Server History", Fn = function() table.clear(Runtime.VisitedJobs); AddLog("Cleared visited JobIds") end },

	-- TAB 10: CONFIG & DIAGNOSTICS (18)
	{ Tab = "10. Config", Kind = "Telemetry", Key = "DiagStats", Label = "Diagnostics" },
	{ Tab = "10. Config", Kind = "Action", Label = "Save Config Profile (default.json)", Fn = SaveConfigFile },
	{ Tab = "10. Config", Kind = "Action", Label = "Load Config Profile (default.json)", Fn = LoadConfigFile },
	{ Tab = "10. Config", Kind = "Action", Label = "Load Preset: LevelGrind", Fn = function() ApplyPreset("LevelGrind") end },
	{ Tab = "10. Config", Kind = "Action", Label = "Load Preset: MasteryFarm", Fn = function() ApplyPreset("MasteryFarm") end },
	{ Tab = "10. Config", Kind = "Action", Label = "Load Preset: ChestAndFruit", Fn = function() ApplyPreset("ChestAndFruit") end },
	{ Tab = "10. Config", Kind = "Action", Label = "Load Preset: SafeAFK", Fn = function() ApplyPreset("SafeAFK") end },
	{ Tab = "10. Config", Kind = "Toggle", Key = "AutoSaveConfig", Label = "Auto-Save Config on Change" },
	{ Tab = "10. Config", Kind = "Cycle",  Key = "UIToggleKey", Label = "UI Toggle Keybind", Values = { "RightShift", "RightControl", "Insert", "End", "K" } },
	{ Tab = "10. Config", Kind = "Toggle", Key = "HotkeyFarmPause", Label = "Enable Farm Pause Hotkey [F6]" },
	{ Tab = "10. Config", Kind = "Toggle", Key = "HotkeyRetreat", Label = "Enable Sky Retreat Hotkey [F7]" },
	{ Tab = "10. Config", Kind = "Toggle", Key = "HotkeyServerHop", Label = "Enable Server Hop Hotkey [F8]" },
	{ Tab = "10. Config", Kind = "Toggle", Key = "HotkeyPanicStop", Label = "Enable Panic Stop Hotkey [F9]" },
	{ Tab = "10. Config", Kind = "Toggle", Key = "MiniHudVisible", Label = "Show Floating Crimson Status Strip" },
	{ Tab = "10. Config", Kind = "Action", Label = "Copy Diagnostic Log to Clipboard", Fn = function()
		local cp = setclipboard or toclipboard
		if cp then pcall(cp, table.concat(Runtime.Logs, "\n")); AddLog("Copied logs to clipboard") end
	end },
	{ Tab = "10. Config", Kind = "Action", Label = "Re-Scan Game Remotes Now", Fn = DiscoverRemotes },
	{ Tab = "10. Config", Kind = "Action", Label = "Verify Executor Capabilities", Fn = function()
		AddLog(("Caps: gethui=%s writefile=%s touch=%s gc=%s"):format(
			tostring(type(gethui) == "function"),
			tostring(type(writefile) == "function"),
			tostring(type(firetouchinterest) == "function"),
			tostring(type(getgc) == "function")
		))
	end },
	{ Tab = "10. Config", Kind = "Action", Label = "PANIC STOP ALL MODULES", Fn = PanicStopAll },
}

-- ============================================================================
--  12. CLASSIC CRIMSON RED & BLACK UI RENDERER
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

-- Floating Mini Status Strip (visible even when main window is toggled)
local miniStrip = Make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(420, 26),
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

-- Main Window
local rootFrame = Make("Frame", {
	Name = "MainWindow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(590, 430),
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
	Size = UDim2.new(0, 210, 1, 0),
	Position = UDim2.fromOffset(14, 0),
	BackgroundTransparency = 1,
	Text = "ZYVORA FARM v1 (208)",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = THEME.CrimsonBright,
	TextXAlignment = Enum.TextXAlignment.Left,
}, topBar)

local statusBadge = Make("TextLabel", {
	Size = UDim2.new(0, 275, 1, 0),
	Position = UDim2.new(1, -335, 0, 0),
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

-- Scrollable Left Tab Rail
local tabRail = Make("ScrollingFrame", {
	Size = UDim2.new(0, 134, 1, -54),
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
	Size = UDim2.new(1, -154, 1, -54),
	Position = UDim2.fromOffset(148, 50),
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
		Size = UDim2.new(1, -110, 1, 0),
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
			if CFG.AutoSaveConfig then SaveConfigFile() end
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

		local function refresh()
			valLbl.Text = tostring(CFG[item.Key])
		end
		Runtime.UIControls[item.Key] = refresh

		local function nudge(dir)
			local step = item.Step or 1
			local raw = (tonumber(CFG[item.Key]) or item.Min) + (dir * step)
			local rounded = math.floor(raw / step + 0.5) * step
			CFG[item.Key] = math.clamp(tonumber(string.format("%.4f", rounded)), item.Min, item.Max)
			refresh()
			if CFG.AutoSaveConfig then SaveConfigFile() end
		end
		TrackConn(minusBtn.MouseButton1Click:Connect(function() nudge(-1) end))
		TrackConn(plusBtn.MouseButton1Click:Connect(function() nudge(1) end))

	elseif item.Kind == "Cycle" then
		local cycBtn = Make("TextButton", {
			Size = UDim2.fromOffset(96, 20),
			Position = UDim2.new(1, -104, 0.5, -10),
			BackgroundColor3 = THEME.CrimsonDim,
			Text = tostring(CFG[item.Key]),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = THEME.Text,
			AutoButtonColor = false,
		}, row)
		Make("UICorner", { CornerRadius = UDim.new(0, 5) }, cycBtn)

		local function refresh()
			cycBtn.Text = tostring(CFG[item.Key])
		end
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
			if CFG.AutoSaveConfig then SaveConfigFile() end
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
	if targetPage then
		BuildControlRow(targetPage, item, idx)
	end
end
SelectTab(TAB_NAMES[1])

-- Live Telemetry & HUD Updater
TrackThread(function()
	while Runtime.Alive do
		task.wait(0.35)
		miniStrip.Visible = CFG.MiniHudVisible
		local banner = Runtime.AlertText ~= "" and (" | " .. Runtime.AlertText) or ""
		statusBadge.Text = Runtime.StatusText
		miniLabel.Text = ("ZYVORA v1 | Sea %d | Lv.%d | %s%s"):format(GetCurrentSea(), GetPlayerLevel(), Runtime.StatusText, banner)

		if telemetryLabels.FarmStats then
			telemetryLabels.FarmStats.Text = ("Sea %d | Lv.%d | Mode: %s | Kills: %d"):format(GetCurrentSea(), GetPlayerLevel(), CFG.FarmPositionMode, Runtime.SessionKills)
		end
		if telemetryLabels.CurrencyStats then
			telemetryLabels.CurrencyStats.Text = ("Beli: %d | Frags: %d | World Fruits: %d"):format(GetPlayerBeli(), GetPlayerFrags(), #FindSpawnedFruits())
		end
		if telemetryLabels.ChestStats then
			telemetryLabels.ChestStats.Text = ("Chests Grabbed: %d | Active Chests: %d | Filter: %s"):format(Runtime.SessionChests, #FindActiveChests(), CFG.MaterialFilter)
		end
		if telemetryLabels.MoveStats then
			local r = GetHRP()
			local posY = r and math.floor(r.Position.Y) or 0
			local spd = r and math.floor(r.AssemblyLinearVelocity.Magnitude) or 0
			telemetryLabels.MoveStats.Text = ("Altitude Y: %d | Velocity: %d | WalkSpeed: %d"):format(posY, spd, CFG.SpeedEnabled and CFG.SpeedValue or 16)
		end
		if telemetryLabels.SafetyStats then
			local ping = 0
			pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
			telemetryLabels.SafetyStats.Text = ("Ping: %dms | FleeHP: %d%% | AlertRadius: %d"):format(ping, CFG.FleeHPThreshold, CFG.ThreatRadius)
		end
		if telemetryLabels.SessionStats then
			local mins = math.max(1, math.floor((os.clock() - Runtime.StartClock) / 60))
			local beliGain = math.max(0, GetPlayerBeli() - Runtime.StartBeli)
			telemetryLabels.SessionStats.Text = ("Uptime: %dm | +Beli: %d | Visited Jobs: %d"):format(mins, beliGain, 0)
		end
		if telemetryLabels.DiagStats then
			telemetryLabels.DiagStats.Text = ("Logs: %d | Last: %s"):format(#Runtime.Logs, Runtime.Logs[#Runtime.Logs] or "none")
		end
	end
end)

-- Window Controls & Global Keybinds
local minimized = false
TrackConn(minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	tabRail.Visible = not minimized
	contentArea.Visible = not minimized
	rootFrame.Size = minimized and UDim2.fromOffset(590, 44) or UDim2.fromOffset(590, 430)
end))

TrackConn(UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	local toggleKC = Enum.KeyCode[CFG.UIToggleKey] or Enum.KeyCode.RightShift
	if inp.KeyCode == toggleKC then
		CFG.UIVisible = not CFG.UIVisible
		rootFrame.Visible = CFG.UIVisible
	elseif CFG.HotkeyFarmPause and inp.KeyCode == Enum.KeyCode.F6 then
		CFG.AutoFarm = not CFG.AutoFarm
		RefreshAllUIControls()
		SetStatus(CFG.AutoFarm and "Farm resumed [F6]" or "Farm paused [F6]")
	elseif CFG.HotkeyRetreat and inp.KeyCode == Enum.KeyCode.F7 then
		local r = GetHRP()
		if r then r.AssemblyLinearVelocity = Vector3.zero; r.CFrame = r.CFrame + Vector3.new(0, 350, 0) end
	elseif CFG.HotkeyServerHop and inp.KeyCode == Enum.KeyCode.F8 then
		SmartServerHop()
	elseif CFG.HotkeyPanicStop and inp.KeyCode == Enum.KeyCode.F9 then
		PanicStopAll()
	end
end))

TrackConn(GuiService.ErrorMessageChanged:Connect(function(msg)
	if CFG.AutoRejoinError and msg and msg ~= "" then
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
env.ZYVORA_FARM_V1 = { Destroy = CleanupAll, Config = CFG, State = Runtime, FeatureCount = #FEATURE_SPEC }
AddLog("Zyvora Farm v1 initialized with " .. tostring(#FEATURE_SPEC) .. " features")
