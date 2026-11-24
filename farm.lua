-- ============================================================================
--  ZYVORA FARM v1  |  Blox Fruits Farming Module (Fixed Build)
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

local LocalPlayer = Players.LocalPlayer

local WORLD_1 = game.PlaceId == 2753915549 or game.PlaceId == 85211729168715
local WORLD_2 = game.PlaceId == 4442272183 or game.PlaceId == 79091703265657
local WORLD_3 = game.PlaceId == 7449423635 or game.PlaceId == 100117331123089

local env = (type(getgenv) == "function" and getgenv()) or _G
if env.ZYVORA_FARM_V1 then
	pcall(function() env.ZYVORA_FARM_V1.Destroy() end)
end

-- ============================================================================
--  CONFIG & RUNTIME STATE
-- ============================================================================
local CFG = {
	-- Core Farm
	AutoFarm          = false,
	AutoQuest         = true,
	BringMobs         = true,
	BringRadius       = 250,
	FarmHeight        = 18,
	FarmMode          = "Above", -- "Above" | "Orbit"
	BossPriority      = true,
	SkipStuckMobs     = true,
	AutoEquipTool     = true,
	PreferredSlot     = "1",

	-- Combat, Mastery & Fruits
	FastAttack        = false,
	FastAttackMode    = "Mode2", -- "Mode1" | "Mode2"
	AttackDelay       = 0.06,
	FruitM1           = false,
	VoidFruitM1       = false,
	AutoHaki          = false,
	AutoKen           = false,
	AutoV3            = false,
	AutoV4            = false,
	AutoStoreFruit    = false,
	FruitScanner      = false,

	-- Raids, Safety & Server Hop
	AutoRaidTrigger   = false,
	AutoFleeLowHP     = false,
	FleeHPThreshold   = 28,
	AntiAFK           = true,
	HopAvoidRepeats   = true,

	-- Movement & World
	SpeedEnabled      = false,
	SpeedValue        = 65,
	JumpEnabled       = false,
	JumpValue        = 65,
	Noclip            = false,
	WalkOnWater       = false,

	-- UI
	UIVisible         = true,
	ToggleKey         = Enum.KeyCode.RightShift,
}

local Runtime = {
	Alive          = true,
	Connections    = {},
	Threads        = {},
	VisitedJobs    = {},
	StuckUntil     = {},
	WaterPad       = nil,
	FoundRemote    = nil,
	FoundRemoteId  = nil,
	NetFolder      = nil,
	RegisterAttack = nil,
	RegisterHit    = nil,
	CommF          = nil,
	CommE          = nil,
	StatusText     = "Idle — ready",
	StartClock     = os.clock(),
}

local function TrackConn(conn)
	if conn then table.insert(Runtime.Connections, conn) end
	return conn
end

local function TrackThread(fn)
	local th = task.spawn(fn)
	table.insert(Runtime.Threads, th)
	return th
end

local function SetStatus(msg)
	Runtime.StatusText = tostring(msg)
end

-- ============================================================================
--  CHARACTER, WORLD & REMOTE HELPERS
-- ============================================================================
local function GetChar()
	return LocalPlayer.Character
end

local function GetHumanoid()
	local char = GetChar()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetHRP()
	local char = GetChar()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsValidLivingModel(model)
	local char = GetChar()
	if not model or model == char then return false end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hrp and hrp:IsA("BasePart") and hum and hum.Health > 0 then
		return hrp, hum
	end
	return nil, nil
end

local function GetCurrentSea()
	if WORLD_1 then return 1 end
	if WORLD_2 then return 2 end
	if WORLD_3 then return 3 end
	return 0
end

local function GetPlayerLevel()
	local data = LocalPlayer:FindFirstChild("Data")
	local lvl = data and data:FindFirstChild("Level")
	return (lvl and typeof(lvl.Value) == "number" and lvl.Value) or 1
end

local function FormatUptime()
	local sec = math.max(0, math.floor(os.clock() - Runtime.StartClock))
	local m = math.floor(sec / 60)
	local s = sec % 60
	return ("%02dm:%02ds"):format(m, s)
end

local function DiscoverRemotes()
	pcall(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes then
			Runtime.CommF = remotes:FindFirstChild("CommF_")
			Runtime.CommE = remotes:FindFirstChild("CommE")
			Runtime.RegisterAttack = remotes:FindFirstChild("RegisterAttack", true)
			Runtime.RegisterHit = remotes:FindFirstChild("RegisterHit", true)
		end
		Runtime.NetFolder = ReplicatedStorage:FindFirstChild("Net", true)

		local function inspect(obj)
			if obj:IsA("RemoteEvent") and obj:GetAttribute("Id") ~= nil then
				Runtime.FoundRemote = obj
				Runtime.FoundRemoteId = obj:GetAttribute("Id")
			end
		end

		for _, name in ipairs({ "Util", "Common", "Remotes", "Assets", "FX", "Net" }) do
			local f = ReplicatedStorage:FindFirstChild(name)
			if f then
				for _, desc in ipairs(f:GetDescendants()) do inspect(desc) end
				TrackConn(f.DescendantAdded:Connect(inspect))
			end
		end
	end)
end

-- ============================================================================
--  QUEST, MOB & FRUIT SCANNER HELPERS [VERIFY ON BUILD]
-- ============================================================================
local QUEST_PROFILES = {
	{ Sea = 1, MinLv = 1,    MaxLv = 9,    QuestNpc = "Bandit Quest Giver",       QuestId = 1, Mob = "Bandit",            QuestPos = Vector3.new(1059, 16, 1544),   MobPos = Vector3.new(1145, 17, 1632) },
	{ Sea = 1, MinLv = 10,   MaxLv = 14,   QuestNpc = "Bandit Quest Giver",       QuestId = 2, Mob = "Monkey",            QuestPos = Vector3.new(1059, 16, 1544),   MobPos = Vector3.new(-1598, 36, 153) },
	{ Sea = 2, MinLv = 700,  MaxLv = 724,  QuestNpc = "Area Master",              QuestId = 1, Mob = "Raider",            QuestPos = Vector3.new(-427, 73, 1836),    MobPos = Vector3.new(-746, 39, 2331) },
	{ Sea = 3, MinLv = 1500, MaxLv = 1524, QuestNpc = "Port Town Quest Giver",    QuestId = 1, Mob = "Pirate Millionaire", QuestPos = Vector3.new(-290, 44, 5580),   MobPos = Vector3.new(-46, 44, 5638) },
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
	local gui = LocalPlayer:FindFirstChild("PlayerGui")
	local main = gui and gui:FindFirstChild("Main")
	local qFrame = main and main:FindFirstChild("Quest")
	return qFrame and qFrame.Visible == true
end

local function FindBestMob(preferredName)
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return nil end

	local hrp = GetHRP()
	local origin = hrp and hrp.Position or Vector3.zero
	local now = os.clock()

	local bestModel, bestHRP, bestHum, bestScore = nil, nil, nil, math.huge

	for _, model in ipairs(enemies:GetChildren()) do
		local stuckUntil = Runtime.StuckUntil[model]
		if CFG.SkipStuckMobs and stuckUntil and now < stuckUntil then
			continue
		end

		local mHRP, mHum = IsValidLivingModel(model)
		if mHRP and mHum then
			local nameMatch = (not preferredName) or (model.Name:lower():find(preferredName:lower(), 1, true) ~= nil)
			if nameMatch then
				local dist = (mHRP.Position - origin).Magnitude
				local lowName = model.Name:lower()
				local isBoss = CFG.BossPriority and (lowName:find("boss", 1, true) or lowName:find("admiral", 1, true) or lowName:find("king", 1, true))
				local score = dist - (isBoss and 400 or 0)
				if score < bestScore then
					bestScore = score
					bestModel = model
					bestHRP = mHRP
					bestHum = mHum
				end
			end
		end
	end

	if not bestModel and preferredName then
		return FindBestMob(nil)
	end

	return bestModel, bestHRP, bestHum
end

local function FindSpawnedFruitPart()
	for _, obj in ipairs(workspace:GetChildren()) do
		local n = obj.Name:lower()
		if n:find("fruit", 1, true) then
			if obj:IsA("BasePart") then return obj end
			if obj:IsA("Model") then
				return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
			end
			if obj:IsA("Tool") then
				return obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
			end
		end
	end
	return nil
end

-- ============================================================================
--  MOVEMENT, AUTO-EQUIP & MOB GROUPING
-- ============================================================================
local function EnsureFarmToolEquipped()
	if not CFG.AutoEquipTool then return end
	local char = GetChar()
	local hum = GetHumanoid()
	local bp = LocalPlayer:FindFirstChild("Backpack")
	if not char or not hum or not bp or hum.Health <= 0 then return end
	if char:FindFirstChildOfClass("Tool") then return end

	local chosen = nil
	for _, t in ipairs(bp:GetChildren()) do
		if t:IsA("Tool") then
			chosen = t
			if CFG.PreferredSlot ~= "" and t.Name:lower():find(CFG.PreferredSlot:lower(), 1, true) then
				break
			end
		end
	end
	if chosen then
		pcall(function() hum:EquipTool(chosen) end)
	end
end

local function MoveToCFrame(targetCF)
	local hrp = GetHRP()
	local hum = GetHumanoid()
	if not hrp or not hum or hum.Health <= 0 then return end

	local current = hrp.CFrame
	local dist = (targetCF.Position - current.Position).Magnitude
	local nextCF = dist > 18 and current:Lerp(targetCF, math.clamp(18 / dist, 0.15, 0.85)) or targetCF

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = nextCF
end

local function GroupNearbyMobs(anchorPos, targetName)
	if not CFG.BringMobs then return end
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return end

	local pullTargetPos = anchorPos - Vector3.new(0, CFG.FarmHeight, 0)
	for _, model in ipairs(enemies:GetChildren()) do
		local mHRP, mHum = IsValidLivingModel(model)
		if mHRP and mHum then
			local matches = (not targetName) or (model.Name:lower():find(targetName:lower(), 1, true) ~= nil)
			if matches and (mHRP.Position - anchorPos).Magnitude <= CFG.BringRadius then
				pcall(function()
					if sethiddenproperty then
						sethiddenproperty(mHRP, "NetworkIsSleeping", false)
					end
					mHRP.CanCollide = false
					mHRP.AssemblyLinearVelocity = Vector3.zero
					mHRP.CFrame = CFrame.new(pullTargetPos)
				end)
			end
		end
	end
end

-- ============================================================================
--  COMBAT, FRUITS, RAIDS & SERVER HOP
-- ============================================================================
local function CollectAttackTargets()
	local hrp = GetHRP()
	if not hrp then return {} end

	local list = {}
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		for _, model in ipairs(enemies:GetChildren()) do
			local mHRP, mHum = IsValidLivingModel(model)
			if mHRP and mHum and (mHRP.Position - hrp.Position).Magnitude <= 500 then
				table.insert(list, {
					Model = model,
					Root  = mHRP,
					Head  = model:FindFirstChild("Head") or mHRP,
				})
			end
		end
	end
	return list
end

local function PerformFastAttack()
	local char = GetChar()
	if not char then return end
	if not (char:FindFirstChildOfClass("Tool") or char:FindFirstChild("EquippedWeapon")) then return end

	local targets = CollectAttackTargets()
	if #targets == 0 then return end

	local main = targets[1]
	local hitList = {}
	for _, t in ipairs(targets) do
		table.insert(hitList, { t.Model, t.Root })
	end

	if Runtime.RegisterAttack and Runtime.RegisterHit then
		pcall(function()
			Runtime.RegisterAttack:FireServer(0)
			Runtime.RegisterHit:FireServer(main.Head, hitList)
		end)
	end

	if CFG.FastAttackMode == "Mode2" and Runtime.FoundRemote and Runtime.FoundRemoteId ~= nil then
		pcall(function()
			local seedVal = 1
			local seedRemote = Runtime.NetFolder and Runtime.NetFolder:FindFirstChild("seed")
			if seedRemote and seedRemote:IsA("RemoteFunction") then
				local ok, res = pcall(function() return seedRemote:InvokeServer() end)
				if ok and type(res) == "number" then seedVal = res end
			end

			local encId = bit32.bxor(tonumber(Runtime.FoundRemoteId) + 909090, seedVal * 2)
			local rawName = "RE/RegisterHit"
			local shift = math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
			local encName = rawName:gsub(".", function(ch)
				return string.char(bit32.bxor(string.byte(ch), shift))
			end)

			Runtime.FoundRemote:FireServer(encName, encId, main.Head, hitList)
		end)
	end
end

local function GetEquippedOrOwnedFruit()
	for _, cont in ipairs({ GetChar(), LocalPlayer:FindFirstChild("Backpack") }) do
		if cont then
			for _, tool in ipairs(cont:GetChildren()) do
				if tool:IsA("Tool") and tool.ToolTip == "Blox Fruit" then
					return tool
				end
			end
		end
	end
	return nil
end

local function FireFruitM1(voidMode)
	local hrp = GetHRP()
	local fruit = GetEquippedOrOwnedFruit()
	if not hrp or not fruit then return end

	local remote = fruit:FindFirstChild("LeftClickRemote") or fruit:FindFirstChildWhichIsA("RemoteEvent", true)
	if not remote or not remote:IsA("RemoteEvent") then return end

	if voidMode then
		pcall(function() remote:FireServer(Vector3.new(9e30, 9e30, 9e30), 5, true) end)
		return
	end

	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return end

	for _, npc in ipairs(enemies:GetChildren()) do
		local nHRP, nHum = IsValidLivingModel(npc)
		if nHRP and nHum and (nHRP.Position - hrp.Position).Magnitude <= 500 then
			local dir = (nHRP.Position - hrp.Position).Unit
			pcall(function() remote:FireServer(dir, 1, true) end)
		end
	end
end

local function StorePhysicalFruits()
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

local function HasRaidChip()
	for _, cont in ipairs({ GetChar(), LocalPlayer:FindFirstChild("Backpack") }) do
		if cont then
			for _, t in ipairs(cont:GetChildren()) do
				if t:IsA("Tool") then
					local n = t.Name:lower()
					if n:find("chip", 1, true) or n:find("micro", 1, true) then
						return true
					end
				end
			end
		end
	end
	return false
end

local function TriggerRaidPedestal()
	local map = workspace:FindFirstChild("Map")
	if not map then return false end

	local holder = (WORLD_3 and map:FindFirstChild("Boat Castle")) or (WORLD_2 and map:FindFirstChild("CircleIsland"))
	local btn = holder and holder:FindFirstChild("RaidSummon2")
	if not btn then return false end

	btn = btn:FindFirstChild("Button") or btn:FindFirstChild("Main") or btn
	local det = btn:FindFirstChild("ClickDetector")
	if det and type(fireclickdetector) == "function" then
		pcall(fireclickdetector, det)
		return true
	end
	local pr = btn:FindFirstChild("ProximityPrompt")
	if pr and type(fireproximityprompt) == "function" then
		pcall(fireproximityprompt, pr)
		return true
	end
	return false
end

local function ApplyMovementState()
	local hum = GetHumanoid()
	if not hum or hum.Health <= 0 then return end

	if CFG.SpeedEnabled then
		local sp = math.clamp(CFG.SpeedValue, 16, 2000)
		if hum.WalkSpeed ~= sp then hum.WalkSpeed = sp end
	end

	if CFG.JumpEnabled then
		local jp = math.clamp(CFG.JumpValue, 16, 2000)
		if hum.UseJumpPower then
			if hum.JumpPower ~= jp then hum.JumpPower = jp end
		else
			local jh = math.clamp(CFG.JumpValue * 0.144, 7.2, 300)
			if hum.JumpHeight ~= jh then hum.JumpHeight = jh end
		end
	end
end

local function RestoreMovementDefaults()
	local hum = GetHumanoid()
	if not hum then return end
	pcall(function()
		hum.WalkSpeed = 16
		if hum.UseJumpPower then
			hum.JumpPower = 50
		else
			hum.JumpHeight = 7.2
		end
	end)
end

local function SetWalkOnWater(enabled)
	if not enabled then
		if Runtime.WaterPad and Runtime.WaterPad.Parent then
			pcall(function() Runtime.WaterPad:Destroy() end)
		end
		Runtime.WaterPad = nil
		return
	end

	local hrp = GetHRP()
	if not hrp then return end

	local pad = Runtime.WaterPad
	if not pad or not pad.Parent then
		pad = Instance.new("Part")
		pad.Name = "ZyvoraWaterPad"
		pad.Size = Vector3.new(36, 1, 36)
		pad.Anchored = true
		pad.CanCollide = true
		pad.Transparency = 1
		pad.Parent = workspace
		Runtime.WaterPad = pad
	end
	pad.Position = Vector3.new(hrp.Position.X, -0.5, hrp.Position.Z)
end

local function SmartServerHop()
	SetStatus("Server hopping...")
	Runtime.VisitedJobs[game.JobId] = true

	local ok, body = pcall(function()
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
		return HttpService:JSONDecode(game:HttpGet(url))
	end)

	if ok and type(body) == "table" and type(body.data) == "table" then
		for _, srv in ipairs(body.data) do
			if type(srv) == "table" and srv.id and srv.id ~= game.JobId then
				local notVisited = (not CFG.HopAvoidRepeats) or (not Runtime.VisitedJobs[srv.id])
				local hasRoom = (srv.playing or 0) < (srv.maxPlayers or 12)
				if notVisited and hasRoom then
					pcall(function()
						TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
					end)
					return
				end
			end
		end
	end

	pcall(function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end)
end

-- ============================================================================
--  BACKGROUND LOOPS
-- ============================================================================
DiscoverRemotes()

TrackThread(function()
	local angle = 0
	while Runtime.Alive do
		task.wait(0.08)
		if not CFG.AutoFarm then continue end

		local ok, err = pcall(function()
			local char = GetChar()
			local hum = GetHumanoid()
			local hrp = GetHRP()
			if not char or not hum or not hrp or hum.Health <= 0 then
				SetStatus("Waiting for character...")
				return
			end

			if CFG.FruitScanner then
				local fruitPart = FindSpawnedFruitPart()
				if fruitPart then
					SetStatus("Collecting spawned fruit...")
					MoveToCFrame(CFrame.new(fruitPart.Position + Vector3.new(0, 2, 0)))
					return
				end
			end

			if CFG.AutoFleeLowHP then
				local hpPct = (hum.Health / math.max(hum.MaxHealth, 1)) * 100
				if hpPct <= CFG.FleeHPThreshold then
					SetStatus(("Low HP (%.0f%%) — escaping up"):format(hpPct))
					MoveToCFrame(hrp.CFrame + Vector3.new(0, 140, 0))
					return
				end
			end

			local profile = ResolveQuestProfile()
			local preferredMob = profile and profile.Mob or nil

			if CFG.AutoQuest and profile and not HasActiveQuest() then
				if (hrp.Position - profile.QuestPos).Magnitude > 14 then
					SetStatus("Moving to quest: " .. profile.QuestNpc)
					MoveToCFrame(CFrame.new(profile.QuestPos + Vector3.new(0, 4, 0)))
					return
				elseif Runtime.CommF then
					SetStatus("Accepting quest #" .. tostring(profile.QuestId))
					pcall(function()
						Runtime.CommF:InvokeServer("StartQuest", profile.QuestNpc, profile.QuestId)
					end)
				end
			end

			local mobModel, mobHRP, mobHum = FindBestMob(preferredMob)
			if not mobModel or not mobHRP or not mobHum then
				if profile and (hrp.Position - profile.MobPos).Magnitude > 18 then
					SetStatus("Roaming to spawn: " .. tostring(preferredMob or "Mobs"))
					MoveToCFrame(CFrame.new(profile.MobPos + Vector3.new(0, CFG.FarmHeight, 0)))
				else
					SetStatus("Waiting for mob spawns...")
				end
				return
			end

			EnsureFarmToolEquipped()
			SetStatus("Farming: " .. mobModel.Name)
			GroupNearbyMobs(mobHRP.Position, preferredMob)

			angle += 0.14
			local offset = CFG.FarmMode == "Orbit"
				and Vector3.new(math.cos(angle) * CFG.FarmHeight, CFG.FarmHeight * 0.5, math.sin(angle) * CFG.FarmHeight)
				or Vector3.new(0, CFG.FarmHeight, 0)

			MoveToCFrame(CFrame.lookAt(mobHRP.Position + offset, mobHRP.Position))
		end)

		if not ok then
			SetStatus("Farm loop warning: " .. tostring(err))
			task.wait(0.4)
		end
	end
end)

TrackThread(function()
	while Runtime.Alive do
		if CFG.FastAttack then
			local t0 = os.clock()
			pcall(PerformFastAttack)
			task.wait(math.max(CFG.AttackDelay - (os.clock() - t0), 0.01))
		else
			task.wait(0.25)
		end
	end
end)

TrackThread(function()
	while Runtime.Alive do
		if CFG.VoidFruitM1 then
			pcall(FireFruitM1, true)
			task.wait(0.25)
		elseif CFG.FruitM1 then
			pcall(FireFruitM1, false)
			task.wait(0.12)
		else
			task.wait(0.25)
		end
	end
end)

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
				local blur = game:GetService("Lighting"):FindFirstChild("Blur")
				local active = char:GetAttribute("KenActive") or (blur and blur.Enabled)
				if not active then
					Runtime.CommE:FireServer("Ken", true)
				end
			end

			if CFG.AutoV3 and Runtime.CommE then
				Runtime.CommE:FireServer("ActivateAbility")
			end

			if CFG.AutoV4 then
				local energy = char:FindFirstChild("RaceEnergy")
				local transformed = char:FindFirstChild("RaceTransformed")
				local awk = (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Awakening"))
					or char:FindFirstChild("Awakening")
				if energy and energy.Value >= 1 and transformed and not transformed.Value and awk then
					local rf = awk:FindFirstChild("RemoteFunction")
					if rf and rf:IsA("RemoteFunction") then
						rf:InvokeServer(true)
					end
				end
			end

			if CFG.AutoStoreFruit then
				StorePhysicalFruits()
			end

			if CFG.AutoRaidTrigger and HasRaidChip() then
				TriggerRaidPedestal()
			end
		end)
	end
end)

TrackConn(RunService.Stepped:Connect(function()
	if not Runtime.Alive then return end
	ApplyMovementState()

	if CFG.Noclip then
		local char = GetChar()
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
	end

	SetWalkOnWater(CFG.WalkOnWater)
end))

TrackConn(LocalPlayer.Idled:Connect(function()
	if CFG.AntiAFK then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end))

-- ============================================================================
--  CLASSIC CRIMSON & BLACK UI (ZYVORA FARM v1)
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

local rootFrame = Make("Frame", {
	Name = "MainWindow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(530, 390),
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
	Size = UDim2.new(0, 155, 1, 0),
	Position = UDim2.fromOffset(14, 0),
	BackgroundTransparency = 1,
	Text = "ZYVORA FARM v1",
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = THEME.CrimsonBright,
	TextXAlignment = Enum.TextXAlignment.Left,
}, topBar)

local statusBadge = Make("TextLabel", {
	Size = UDim2.new(0, 275, 1, 0),
	Position = UDim2.new(1, -333, 0, 0),
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
			dragging = true
			dragOrigin = inp.Position
			frameOrigin = rootFrame.Position
		end
	end))
	TrackConn(UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local delta = inp.Position - dragOrigin
			rootFrame.Position = UDim2.new(
				frameOrigin.X.Scale, frameOrigin.X.Offset + delta.X,
				frameOrigin.Y.Scale, frameOrigin.Y.Offset + delta.Y
			)
		end
	end))
	TrackConn(UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

local tabRail = Make("Frame", {
	Size = UDim2.new(0, 128, 1, -54),
	Position = UDim2.fromOffset(8, 50),
	BackgroundColor3 = THEME.Void,
	BorderSizePixel = 0,
}, rootFrame)
Make("UICorner", { CornerRadius = UDim.new(0, 8) }, tabRail)
Make("UIStroke", { Color = THEME.Stroke, Thickness = 1, Transparency = 0.5 }, tabRail)
Make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tabRail)
Make("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
}, tabRail)

local contentArea = Make("Frame", {
	Size = UDim2.new(1, -148, 1, -54),
	Position = UDim2.fromOffset(142, 50),
	BackgroundColor3 = THEME.Void,
	BorderSizePixel = 0,
}, rootFrame)
Make("UICorner", { CornerRadius = UDim.new(0, 8) }, contentArea)
Make("UIStroke", { Color = THEME.Stroke, Thickness = 1, Transparency = 0.5 }, contentArea)

local pages = {}
local tabButtons = {}

local function CreatePage(name, order)
	local page = Make("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = THEME.Crimson,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, contentArea)

	Make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	Make("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}, page)

	local btn = Make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = order,
		BackgroundColor3 = THEME.Card,
		Text = name,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = THEME.Muted,
		AutoButtonColor = false,
	}, tabRail)
	Make("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)

	pages[name] = page
	tabButtons[name] = btn

	TrackConn(btn.MouseButton1Click:Connect(function()
		for pName, pFrame in pairs(pages) do
			local active = (pName == name)
			pFrame.Visible = active
			tabButtons[pName].BackgroundColor3 = active and THEME.Crimson or THEME.Card
			tabButtons[pName].TextColor3 = active and THEME.Text or THEME.Muted
		end
	end))

	return page
end

local function AddInfoCard(page, initialText)
	local card = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = THEME.Card,
		BorderSizePixel = 0,
	}, page)
	Make("UICorner", { CornerRadius = UDim.new(0, 6) }, card)
	Make("UIStroke", { Color = THEME.Crimson, Thickness = 1, Transparency = 0.5 }, card)

	local lbl = Make("TextLabel", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1,
		Text = initialText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, card)
	return lbl
end

local function AddToggle(page, labelText, cfgKey, onChanged)
	local row = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = THEME.Card,
		BorderSizePixel = 0,
	}, page)
	Make("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
	Make("UIStroke", { Color = THEME.Stroke, Thickness = 1, Transparency = 0.6 }, row)

	Make("TextLabel", {
		Size = UDim2.new(1, -66, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local pill = Make("TextButton", {
		Size = UDim2.fromOffset(44, 22),
		Position = UDim2.new(1, -52, 0.5, -11),
		BackgroundColor3 = CFG[cfgKey] and THEME.Crimson or THEME.CrimsonDim,
		Text = CFG[cfgKey] and "ON" or "OFF",
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = THEME.Text,
		AutoButtonColor = false,
	}, row)
	Make("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)

	TrackConn(pill.MouseButton1Click:Connect(function()
		CFG[cfgKey] = not CFG[cfgKey]
		local state = CFG[cfgKey]
		pill.Text = state and "ON" or "OFF"
		TweenService:Create(pill, TweenInfo.new(0.15), {
			BackgroundColor3 = state and THEME.CrimsonBright or THEME.CrimsonDim,
		}):Play()
		if onChanged then pcall(onChanged, state) end
	end))
end

local function AddActionButton(page, labelText, onClick)
	local btn = Make("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = THEME.CrimsonDim,
		Text = labelText,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = THEME.Text,
		AutoButtonColor = false,
	}, page)
	Make("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
	Make("UIStroke", { Color = THEME.Crimson, Thickness = 1, Transparency = 0.4 }, btn)

	TrackConn(btn.MouseButton1Click:Connect(function()
		if onClick then pcall(onClick) end
	end))
end

local pFarm   = CreatePage("Auto Farm", 1)
local pCombat = CreatePage("Combat", 2)
local pMove   = CreatePage("Movement", 3)
local pWorld  = CreatePage("Hop & Misc", 4)

local telemetryCard = AddInfoCard(pFarm, "Sea 0 | Lv.1 | Uptime 00m:00s")
AddToggle(pFarm, "Auto Farm Loop", "AutoFarm")
AddToggle(pFarm, "Auto Quest Giver", "AutoQuest")
AddToggle(pFarm, "Bring / Group Mobs", "BringMobs")
AddToggle(pFarm, "Auto-Equip Farm Tool", "AutoEquipTool")
AddToggle(pFarm, "Orbit Farm Mode (Off = Above)", "FarmMode", function(v)
	CFG.FarmMode = v and "Orbit" or "Above"
end)
AddToggle(pFarm, "Boss Priority", "BossPriority")
AddToggle(pFarm, "Skip Stuck Mobs", "SkipStuckMobs")
AddToggle(pFarm, "Fruit Spawn Scanner", "FruitScanner")
AddToggle(pFarm, "Auto Flee at Low HP", "AutoFleeLowHP")

AddToggle(pCombat, "Fast Attack / Aura", "FastAttack")
AddToggle(pCombat, "Fruit M1", "FruitM1")
AddToggle(pCombat, "Void Fruit M1", "VoidFruitM1")
AddToggle(pCombat, "Auto Haki (Buso)", "AutoHaki")
AddToggle(pCombat, "Auto Observation (Ken)", "AutoKen")
AddToggle(pCombat, "Auto Race V3", "AutoV3")
AddToggle(pCombat, "Auto Race V4", "AutoV4")
AddToggle(pCombat, "Auto Store Fruits", "AutoStoreFruit")
AddToggle(pCombat, "Auto Trigger Raid Chip", "AutoRaidTrigger")

AddToggle(pMove, "Custom WalkSpeed (" .. tostring(CFG.SpeedValue) .. ")", "SpeedEnabled", function(on)
	if not on then RestoreMovementDefaults() end
end)
AddToggle(pMove, "Custom Jump (" .. tostring(CFG.JumpValue) .. ")", "JumpEnabled", function(on)
	if not on then RestoreMovementDefaults() end
end)
AddToggle(pMove, "Noclip", "Noclip")
AddToggle(pMove, "Walk On Water", "WalkOnWater", function(on)
	if not on then SetWalkOnWater(false) end
end)

AddToggle(pWorld, "Anti-AFK", "AntiAFK")
AddToggle(pWorld, "Avoid Visited Servers on Hop", "HopAvoidRepeats")
AddActionButton(pWorld, "Smart Server Hop Now", SmartServerHop)
AddActionButton(pWorld, "Store Inventory Fruits Now", StorePhysicalFruits)

pFarm.Visible = true
tabButtons["Auto Farm"].BackgroundColor3 = THEME.Crimson
tabButtons["Auto Farm"].TextColor3 = THEME.Text

TrackThread(function()
	while Runtime.Alive do
		task.wait(0.25)
		if statusBadge and statusBadge.Parent then
			statusBadge.Text = Runtime.StatusText
		end
		if telemetryCard and telemetryCard.Parent then
			telemetryCard.Text = ("Sea %d | Lv.%d | Uptime %s"):format(GetCurrentSea(), GetPlayerLevel(), FormatUptime())
		end
	end
end)

local minimized = false
TrackConn(minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	tabRail.Visible = not minimized
	contentArea.Visible = not minimized
	rootFrame.Size = minimized and UDim2.fromOffset(530, 44) or UDim2.fromOffset(530, 390)
end))

TrackConn(UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	if inp.KeyCode == CFG.ToggleKey then
		CFG.UIVisible = not CFG.UIVisible
		rootFrame.Visible = CFG.UIVisible
	end
end))

local function CleanupAll()
	if not Runtime.Alive then return end
	Runtime.Alive = false

	for _, c in ipairs(Runtime.Connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(Runtime.Connections)

	for _, th in ipairs(Runtime.Threads) do
		pcall(task.cancel, th)
	end
	table.clear(Runtime.Threads)

	SetWalkOnWater(false)
	RestoreMovementDefaults()

	if screenGui and screenGui.Parent then
		pcall(function() screenGui:Destroy() end)
	end
end

TrackConn(closeBtn.MouseButton1Click:Connect(CleanupAll))
env.ZYVORA_FARM_V1 = { Destroy = CleanupAll, Config = CFG, State = Runtime }
