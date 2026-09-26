-- ==========================================================
-- Yokai Hub (Full Features + Named Animation Dropdown & Speed Max 10)
-- ==========================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "Yokai Hub",
	Footer = "version: 5.2.8 - Named Animation Dropdown & Speed Max 10",
	Icon = "sparkles",
	NotifySide = "Right",
	ShowCustomCursor = true,
	ToggleKeybind = "RightShift",
})

local Tabs = {
	Main = Window:AddTab("Main", "user"),
	Combat = Window:AddTab("Combat", "crosshair"),
	Character = Window:AddTab("Character", "activity"),
	Visuals = Window:AddTab("Visuals", "eye"),
	World = Window:AddTab("World", "globe"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- ==================== Global Variables & Settings ====================
local cloneref = cloneref or function(v) return v end
local P, RS, UIS = cloneref(game:GetService("Players")), cloneref(game:GetService("RunService")), cloneref(game:GetService("UserInputService"))
local LP = P.LocalPlayer
local repS = cloneref(game:GetService("ReplicatedStorage"))
local ws = cloneref(game:GetService("Workspace"))
local lighting = cloneref(game:GetService("Lighting"))

getgenv().YokaiConfig = {
	-- Ragebot Configs
	RagebotEnabled = true,
	FireRate = 0.0005,
	WeaponSlot = "Melee",
	
	-- Void & Orbit & Anti-Aim Configs
	VoidEnabled = false,
	OrbitEnabled = false,
	TeamCheck = false,
	AntiAimEnabled = false,
	TargetMode = "Closest Enemy",
	MinDisplay = 50000,
	MaxDisplay = 50000,
	OrbitDist = 10000000,
	OrbitSpeed = 5000000,

	-- World / Lighting Configs
	WeatherEnabled = false,
	WeatherType = "Snow",
	WeatherIntensity = 1,
	WeatherVolume = 0.35,
	WeatherMoodTint = false,
	TimeLockEnabled = false,
	LockedClockTime = 14,
	GlobalShadows = true,
	NightVisionEnabled = false,
	ExposureValue = 0,

	-- Custom Animation Config
	CustomAnimEnabled = false,
	CustomAnimSpeed = 1,
	CustomAnimId = "102820461604639", -- Default: Solar System

	-- Triggerbot Configs
	TriggerbotEnabled = false,
	TriggerActivation = "Always",
	TriggerHeadOnly = false,
	TriggerScopeCheck = false,
	TriggerReactionDelay = 0,
	TriggerRefireDelay = 500,
	TriggerMaxDistance = 400,

	-- Aimbot Configs
	AimbotEnabled = false,
	AimbotSmoothness = 1,
	AimbotFOV = 600,
	AimbotFOVVisible = false,
	AimbotFilled = false,
	AimbotColor1 = Color3.fromRGB(255, 0, 0),
	AimbotColor2 = Color3.fromRGB(0, 255, 0),
	AimbotColor3 = Color3.fromRGB(0, 0, 255),

	-- Silent Aim Configs
	SilentAimEnabled = false,
	SilentFOVVisible = false,
	SilentFull = false,
	SilentFOV = 600,
	SilentColor1 = Color3.fromRGB(255, 255, 0),
	SilentColor2 = Color3.fromRGB(255, 0, 255),
	SilentColor3 = Color3.fromRGB(0, 255, 255),

	-- Character & Movement Configs
	FlyEnabled = false,
	FlySpeed = 50,
	NoclipEnabled = false,
	InfJumpEnabled = false,
	WalkSpeedEnabled = false,
	WalkSpeedValue = 20,
	AuraEnabled = false,
	AuraRange = 15,

	-- Weapons & Extra Configs
	WallbangEnabled = false,
	RapidFireEnabled = false,

	-- Crosshair Configs
	CrosshairEnabled = false,
	CrosshairSize = 10,
	CrosshairGap = 4,
	CrosshairRainbow = true,
	CrosshairDynamic = true,
	CrosshairText = "YOKAI HUB",
	CrosshairTextEnabled = true,
	CrosshairColor = Color3.fromRGB(0, 255, 128),
}

local _isFiringOrDesyncing = false

local function gH()
	if getgenv().YokaiConfig.VoidEnabled and _isFiringOrDesyncing then
		return nil
	end
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function isTeammate(p)
	if p.Team and LP.Team and p.Team == LP.Team then return true end
	if p.Character and LP.Character then
		local tC = p:GetAttribute("TeamColor") or p:GetAttribute("Team")
		local lC = LP.GetAttribute and LP:GetAttribute("TeamColor") or LP:GetAttribute("Team")
		if tC and lC and tC == lC then return true end
	end
	return false
end

local function getCustomRotatingColor(c1, c2, c3, speed)
	local t = (tick() * (speed or 2)) % 3
	if t < 1 then
		return c1:Lerp(c2, t)
	elseif t < 2 then
		return c2:Lerp(c3, t - 1)
	else
		return c3:Lerp(c1, c2, t - 2)
	end
end

-- ==================== Custom Animation & Asset Setup ====================
local function anim2track(asset_id)
	local success, objs = pcall(function()
		return game:GetObjects(asset_id)
	end)
	if success and objs then
		for i = 1, #objs do
			if objs[i]:IsA("Animation") then
				return objs[i].AnimationId
			end
		end
	end
	return asset_id
end

local function getProcessedAnimId()
	local rawId = getgenv().YokaiConfig.CustomAnimId or "102820461604639"
	if not rawId:find("rbxassetid://") then
		rawId = "rbxassetid://" .. rawId
	end
	return anim2track(rawId)
end

local function stopCustomAnim(character)
	local Hum = character and character:FindFirstChildWhichIsA("Humanoid")
	if Hum then
		for _, track in next, Hum:GetPlayingAnimationTracks() do
			track:Stop()
		end
	end
end

local function playCustomAnim(character)
	if not getgenv().YokaiConfig.CustomAnimEnabled then return end
	local Hum = character:FindFirstChildWhichIsA("Humanoid")
	if not Hum then return end
	
	stopCustomAnim(character)
	
	local animId = getProcessedAnimId()
	local animation = Instance.new("Animation")
	animation.AnimationId = animId
	
	local anim = Hum:LoadAnimation(animation)
	anim.Priority = Enum.AnimationPriority.Action4
	anim:Play()
	anim:AdjustSpeed(getgenv().YokaiConfig.CustomAnimSpeed)
	
	anim.Stopped:Connect(function()
		if getgenv().YokaiConfig.CustomAnimEnabled then
			playCustomAnim(character)
		end
	end)
end

P.LocalPlayer.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid")
	if getgenv().YokaiConfig.CustomAnimEnabled then
		playCustomAnim(character)
	end
end)

-- ==================== ESP Library & Drawing Setup ====================
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/linemaster2/esp-library/main/library.lua"))();
ESP.Enabled = false;
ESP.ShowBox = false;
ESP.ShowName = false;
ESP.ShowHealth = false;
ESP.ShowTracer = false;
ESP.ShowDistance = false;
ESP.ShowSkeletons = false;

local aimbotCircle = Drawing.new("Circle")
aimbotCircle.Thickness = 2; aimbotCircle.Visible = false; aimbotCircle.Transparency = 0.5; aimbotCircle.NumSides = 64; aimbotCircle.Filled = false

local silentCircle = Drawing.new("Circle")
silentCircle.Thickness = 2; silentCircle.Visible = false; silentCircle.Transparency = 0.5; silentCircle.NumSides = 64; silentCircle.Filled = false

local chLines = {
	Top = Drawing.new("Line"),
	Bottom = Drawing.new("Line"),
	Left = Drawing.new("Line"),
	Right = Drawing.new("Line")
}
for _, line in pairs(chLines) do line.Thickness = 2; line.Visible = false end

local chText = Drawing.new("Text")
chText.Size = 15; chText.Center = true; chText.Outline = true; chText.Visible = false

-- ==================== MAIN Tab ====================
local RagebotGroup = Tabs.Main:AddLeftGroupbox("Ragebot", "crosshair")
RagebotGroup:AddToggle("RagebotEnabled", { Text = "Enable Ragebot", Default = true, Callback = function(Value) getgenv().YokaiConfig.RagebotEnabled = Value end })
RagebotGroup:AddDropdown("WeaponSlotDropdown", { Values = { "Primary", "Secondary", "Melee" }, Default = 3, Text = "Weapon Slot", Callback = function(Value) getgenv().YokaiConfig.WeaponSlot = Value end })
RagebotGroup:AddSlider("FireRateSlider", { Text = "Fire Rate", Default = 0.0005, Min = 0.0001, Max = 0.01, Rounding = 4, Callback = function(Value) getgenv().YokaiConfig.FireRate = Value end })

local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Lua Settings", "boxes")
LeftGroupBox:AddToggle("VoidToggle", {
	Text = "Enable Void",
	Default = false,
	Callback = function(Value)
		getgenv().YokaiConfig.VoidEnabled = Value
		if Value then
			task.spawn(function()
				while getgenv().YokaiConfig.VoidEnabled do
					local h = gH()
					if h then
						h.CFrame = h.CFrame + Vector3.new(0, 1e7, 0)
						h.Velocity = Vector3.new(0, 0, 0)
					end
					task.wait()
				end
			end)
		end
	end,
})
LeftGroupBox:AddSlider("MinDisplaySlider", { Text = "Min Distance (Display)", Default = 50000, Min = 0, Max = 100000, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.MinDisplay = Value end })
LeftGroupBox:AddSlider("MaxDisplaySlider", { Text = "Max Distance (Display)", Default = 50000, Min = 0, Max = 100000, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.MaxDisplay = Value end })

local OrbitGroup = Tabs.Main:AddLeftGroupbox("Directions to a fosterhome", "globe")
OrbitGroup:AddToggle("OrbitToggle", {
	Text = "Enable Orbit Loop",
	Default = false,
	Callback = function(Value)
		getgenv().YokaiConfig.OrbitEnabled = Value
		if Value then
			task.spawn(function()
				local a = 0
				while getgenv().YokaiConfig.OrbitEnabled do
					local h = gH()
					local t, cD, fD = nil, math.huge, -1
					local plrs = {}
					
					for _, p in ipairs(P:GetPlayers()) do
						if p ~= LP and p.Character then
							if getgenv().YokaiConfig.TeamCheck and isTeammate(p) then continue end
							local th = p.Character:FindFirstChild("HumanoidRootPart")
							local tm = p.Character:FindFirstChildOfClass("Humanoid")
							if th and tm and tm.Health > 0 then
								table.insert(plrs, { h = th, d = LP:DistanceFromCharacter(th.Position) })
							end
						end
					end
					
					if #plrs > 0 then
						local tMode = getgenv().YokaiConfig.TargetMode
						if tMode == "Closest Enemy" then
							for _, v in ipairs(plrs) do
								if v.d < cD then cD = v.d; t = v.h end
							end
						elseif tMode == "Farthest Enemy" then
							for _, v in ipairs(plrs) do
								if v.d > fD then fD = v.d; t = v.h end
							end
						else
							t = plrs[math.random(1, #plrs)].h
						end
					end
					
					if t and h then
						a = a + getgenv().YokaiConfig.OrbitSpeed
						h.Velocity = Vector3.new(0, 0, 0)
						local targetY = getgenv().YokaiConfig.VoidEnabled and h.Position.Y or (t.Position.Y + 2)
						h.CFrame = CFrame.new(t.Position.X + math.cos(a) * getgenv().YokaiConfig.OrbitDist, targetY, t.Position.Z + math.sin(a) * getgenv().YokaiConfig.OrbitDist)
					end
					task.wait()
				end
			end)
		end
	end,
})
OrbitGroup:AddToggle("TeamCheckToggle", { Text = "Team Check", Default = false, Callback = function(Value) getgenv().YokaiConfig.TeamCheck = Value end })
OrbitGroup:AddSlider("OrbitDistSlider", { Text = "Orbit Radius Distance", Default = 10000000, Min = 0, Max = 10000000, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.OrbitDist = Value end })
OrbitGroup:AddSlider("OrbitSpeedSlider", { Text = "Orbit Rotate Speed Rate", Default = 5000000, Min = 0, Max = 10000000, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.OrbitSpeed = Value end })

local RightGroupBox = Tabs.Main:AddRightGroupbox("Target Selector & Anti-Aim", "target")
RightGroupBox:AddDropdown("TargetModeDropdown", { Values = { "Closest Enemy", "Farthest Enemy", "Random Target" }, Default = 1, Text = "Target Selector", Callback = function(Value) getgenv().YokaiConfig.TargetMode = Value end })
RightGroupBox:AddToggle("AntiAimToggle", {
	Text = "Enable Anti Aim (Glitch)",
	Default = false,
	Callback = function(Value)
		getgenv().YokaiConfig.AntiAimEnabled = Value
		if Value then
			task.spawn(function()
				while getgenv().YokaiConfig.AntiAimEnabled do
					local h = gH()
					if h then
						local r = math.random
						h.CFrame = (h.CFrame + Vector3.new(r(-5, 5)/10, r(-2, 2)/10, r(-5, 5)/10)) * CFrame.Angles(math.rad(r(-180, 180)), math.rad(r(-180, 180)), math.rad(r(-180, 180)))
					end
					RS.RenderStepped:Wait()
				end
			end)
		end
	end,
})

-- ==================== COMBAT Tab ====================
local TriggerGroup = Tabs.Combat:AddLeftGroupbox("Triggerbot", "crosshair")
TriggerGroup:AddToggle("TriggerbotEnabled", { Text = "Trigger bot", Default = false, Callback = function(Value) getgenv().YokaiConfig.TriggerbotEnabled = Value end })
TriggerGroup:AddDropdown("TriggerActivationDropdown", { Values = { "Always", "Hold", "Toggle" }, Default = 1, Text = "Activation", Callback = function(Value) getgenv().YokaiConfig.TriggerActivation = Value end })
TriggerGroup:AddToggle("TriggerHeadOnlyToggle", { Text = "Head only", Default = false, Callback = function(Value) getgenv().YokaiConfig.TriggerHeadOnly = Value end })
TriggerGroup:AddToggle("TriggerScopeCheckToggle", { Text = "Scope check", Default = false, Callback = function(Value) getgenv().YokaiConfig.TriggerScopeCheck = Value end })
TriggerGroup:AddSlider("ReactionDelaySlider", { Text = "Reaction delay (ms)", Default = 0, Min = 0, Max = 300, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.TriggerReactionDelay = Value end })
TriggerGroup:AddSlider("RefireDelaySlider", { Text = "Refire delay (ms)", Default = 500, Min = 0, Max = 500, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.TriggerRefireDelay = Value end })
TriggerGroup:AddSlider("MaxDistanceSlider", { Text = "Max distance", Default = 400, Min = 0, Max = 400, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.TriggerMaxDistance = Value end })

local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Aimbot", "target")
AimbotGroup:AddToggle("AimbotEnabled", { Text = "Enable aimbot", Default = false, Callback = function(Value) getgenv().YokaiConfig.AimbotEnabled = Value end })
AimbotGroup:AddToggle("AimbotFOVToggle", { Text = "FOV (Show Circle)", Default = false, Callback = function(Value) getgenv().YokaiConfig.AimbotFOVVisible = Value end })
AimbotGroup:AddToggle("AimbotFullToggle", { Text = "Full (Fill Inside)", Default = false, Callback = function(Value) getgenv().YokaiConfig.AimbotFilled = Value end })
AimbotGroup:AddSlider("AimbotFOV", { Text = "FOV Radius", Default = 600, Min = 50, Max = 1000, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.AimbotFOV = Value end })
AimbotGroup:AddSlider("AimbotSmoothness", { Text = "Smoothness", Default = 1, Min = 0.1, Max = 5, Rounding = 1, Callback = function(Value) getgenv().YokaiConfig.AimbotSmoothness = Value end })
AimbotGroup:AddLabel("FOV Color 1"):AddColorPicker("AimCol1", { Default = Color3.fromRGB(255, 0, 0), Callback = function(Value) getgenv().YokaiConfig.AimbotColor1 = Value end })
AimbotGroup:AddLabel("FOV Color 2"):AddColorPicker("AimCol2", { Default = Color3.fromRGB(0, 255, 0), Callback = function(Value) getgenv().YokaiConfig.AimbotColor2 = Value end })
AimbotGroup:AddLabel("FOV Color 3"):AddColorPicker("AimCol3", { Default = Color3.fromRGB(0, 0, 255), Callback = function(Value) getgenv().YokaiConfig.AimbotColor3 = Value end })

local SilentGroup = Tabs.Combat:AddRightGroupbox("Silent Aim", "shield")
SilentGroup:AddToggle("SilentAimToggle", { Text = "Enable Silent Aim", Default = false, Callback = function(Value) getgenv().YokaiConfig.SilentAimEnabled = Value end })
SilentGroup:AddToggle("SilentFOVToggle", { Text = "FOV (Show Circle)", Default = false, Callback = function(Value) getgenv().YokaiConfig.SilentFOVVisible = Value end })
SilentGroup:AddToggle("SilentFullToggle", { Text = "Full (Fill Inside)", Default = false, Callback = function(Value) getgenv().YokaiConfig.SilentFull = Value end })
SilentGroup:AddSlider("SilentFOVSlider", { Text = "Silent Aim FOV Radius", Default = 600, Min = 50, Max = 1000, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.SilentFOV = Value end })
SilentGroup:AddLabel("Silent Color 1"):AddColorPicker("SilentCol1", { Default = Color3.fromRGB(255, 255, 0), Callback = function(Value) getgenv().YokaiConfig.SilentColor1 = Value end })
SilentGroup:AddLabel("Silent Color 2"):AddColorPicker("SilentCol2", { Default = Color3.fromRGB(255, 0, 255), Callback = function(Value) getgenv().YokaiConfig.SilentColor2 = Value end })
SilentGroup:AddLabel("Silent Color 3"):AddColorPicker("SilentCol3", { Default = Color3.fromRGB(0, 255, 255), Callback = function(Value) getgenv().YokaiConfig.SilentColor3 = Value end })

local WeaponsGroup = Tabs.Combat:AddRightGroupbox("Weapons Mod", "sword")
WeaponsGroup:AddToggle("WallbangToggle", { Text = "Enable Wallbang", Default = false, Callback = function(Value) getgenv().YokaiConfig.WallbangEnabled = Value end })
WeaponsGroup:AddToggle("RapidFireToggle", {
	Text = "Enable Rapid Fire",
	Default = false,
	Callback = function(Value)
		getgenv().YokaiConfig.RapidFireEnabled = Value
		if Value then
			loadstring([[
			if game.GameId == 6035872082 then
				local Storage = game:GetService("ReplicatedStorage")
				local Items = require(Storage.Modules.ItemLibrary).Items
				for name, data in pairs(Items) do
					if typeof(data) == "table" then
						if data.ShootSpread then data.ShootSpread = 0 end
						if data.ShootCooldown then data.ShootCooldown = 0.001 end
						if data.AttackCooldown then data.AttackCooldown = 0.001 end
						if data.SwingCooldown then data.SwingCooldown = 0.001 end
					end
				end
			end
			]])()
		end
	end,
})

local CrosshairGroup = Tabs.Combat:AddRightGroupbox("Crosshair Settings", "plus")
CrosshairGroup:AddToggle("CrosshairToggle", { Text = "Enable Crosshair", Default = false, Callback = function(Value) getgenv().YokaiConfig.CrosshairEnabled = Value end })
CrosshairGroup:AddToggle("CrosshairRainbowToggle", { Text = "Rainbow Effect", Default = true, Callback = function(Value) getgenv().YokaiConfig.CrosshairRainbow = Value end })
CrosshairGroup:AddToggle("CrosshairDynamicToggle", { Text = "Dynamic Size Animation", Default = true, Callback = function(Value) getgenv().YokaiConfig.CrosshairDynamic = Value end })
CrosshairGroup:AddToggle("CrosshairTextToggle", { Text = "Show Watermark Text", Default = true, Callback = function(Value) getgenv().YokaiConfig.CrosshairTextEnabled = Value end })
CrosshairGroup:AddInput("CrosshairTextInput", { Default = "YOKAI HUB", Numeric = false, Finished = true, Text = "Crosshair Text", Callback = function(Value) getgenv().YokaiConfig.CrosshairText = Value end })
CrosshairGroup:AddSlider("CrosshairSizeSlider", { Text = "Crosshair Size", Default = 10, Min = 2, Max = 30, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.CrosshairSize = Value end })
CrosshairGroup:AddSlider("CrosshairGapSlider", { Text = "Crosshair Gap", Default = 4, Min = 0, Max = 15, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.CrosshairGap = Value end })
CrosshairGroup:AddLabel("Crosshair Color"):AddColorPicker("CrosshairColorPicker", { Default = Color3.fromRGB(0, 255, 128), Callback = function(Value) getgenv().YokaiConfig.CrosshairColor = Value end })

-- ==================== CHARACTER Tab ====================
local MovementGroup = Tabs.Character:AddLeftGroupbox("Movement & Physics", "activity")
MovementGroup:AddToggle("FlyToggle", { Text = "Enable Fly", Default = false, Callback = function(Value) getgenv().YokaiConfig.FlyEnabled = Value end })
MovementGroup:AddSlider("FlySpeedSlider", { Text = "Fly Speed", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.FlySpeed = Value end })
MovementGroup:AddToggle("NoclipToggle", { Text = "Enable Noclip", Default = false, Callback = function(Value) getgenv().YokaiConfig.NoclipEnabled = Value end })
MovementGroup:AddToggle("InfJumpToggle", { Text = "Infinite Jump", Default = false, Callback = function(Value) getgenv().YokaiConfig.InfJumpEnabled = Value end })
MovementGroup:AddToggle("WalkSpeedToggle", { Text = "Custom WalkSpeed", Default = false, Callback = function(Value) getgenv().YokaiConfig.WalkSpeedEnabled = Value end })
MovementGroup:AddSlider("WalkSpeedSlider", { Text = "WalkSpeed Value", Default = 20, Min = 16, Max = 120, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.WalkSpeedValue = Value end })

local CombatCharGroup = Tabs.Character:AddRightGroupbox("Combat Enhancements", "sword")
CombatCharGroup:AddToggle("AuraToggle", { Text = "Enable Aura", Default = false, Callback = function(Value) getgenv().YokaiConfig.AuraEnabled = Value end })
CombatCharGroup:AddSlider("AuraRangeSlider", { Text = "Aura Range", Default = 15, Min = 5, Max = 40, Rounding = 0, Callback = function(Value) getgenv().YokaiConfig.AuraRange = Value end })

-- Character탭 내 커스텀 애니메이션 그룹박스 (Solar System ID: 102820461604639, Hip Bounce ID: 123707883238483)
local CustomAnimGroup = Tabs.Character:AddRightGroupbox("Custom Animation", "play")
CustomAnimGroup:AddToggle("CustomAnimToggle", {
	Text = "Enable Custom Anim Loop",
	Default = false,
	Callback = function(Value)
		getgenv().YokaiConfig.CustomAnimEnabled = Value
		if Value then
			if LP.Character then
				playCustomAnim(LP.Character)
			end
		else
			if LP.Character then
				stopCustomAnim(LP.Character)
			end
		end
	end
})

local animMap = {
	["Solar System"] = "102820461604639",
	["Hip Bounce"] = "123707883238483"
}

CustomAnimGroup:AddDropdown("CustomAnimDropdown", {
	Values = { "Solar System", "Hip Bounce" },
	Default = 1,
	Text = "Animation",
	Callback = function(Value)
		getgenv().YokaiConfig.CustomAnimId = animMap[Value] or "102820461604639"
		if getgenv().YokaiConfig.CustomAnimEnabled and LP.Character then
			playCustomAnim(LP.Character)
		end
	end
})

CustomAnimGroup:AddSlider("CustomAnimSpeedSlider", {
	Text = "Animation Speed",
	Default = 1,
	Min = 0.1,
	Max = 10,
	Rounding = 1,
	Callback = function(Value)
		getgenv().YokaiConfig.CustomAnimSpeed = Value
		local char = LP.Character
		local Hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if Hum then
			for _, track in next, Hum:GetPlayingAnimationTracks() do
				track:AdjustSpeed(Value)
			end
		end
	end
})

-- ==================== VISUALS Tab ====================
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP Settings", "eye")
ESPGroup:AddToggle("ESPEnabled", { Text = "Enabled ESP", Default = false, Callback = function(Value) ESP.Enabled = Value end })
ESPGroup:AddToggle("ESPName", { Text = "Show Name", Default = false, Callback = function(Value) ESP.ShowName = Value end })
ESPGroup:AddToggle("ESPBox", { Text = "Show Box", Default = false, Callback = function(Value) ESP.ShowBox = Value end })
ESPGroup:AddToggle("ESPTracer", { Text = "Show Tracer", Default = false, Callback = function(Value) ESP.ShowTracer = Value end })
ESPGroup:AddToggle("ESPHealth", { Text = "Show Health", Default = false, Callback = function(Value) ESP.ShowHealth = Value end })
ESPGroup:AddToggle("ESPSkeletons", { Text = "Show Skeletons", Default = false, Callback = function(Value) ESP.ShowSkeletons = Value end })
ESPGroup:AddToggle("ESPDistance", { Text = "Show Distance", Default = false, Callback = function(Value) ESP.ShowDistance = Value end })
ESPGroup:AddToggle("ESPTeamCheck", { Text = "Team Check", Default = false, Callback = function(Value) ESP.Teamcheck = Value end })
ESPGroup:AddToggle("ESPWallCheck", { Text = "Wall Check", Default = false, Callback = function(Value) ESP.WallCheck = Value end })

-- ==================== WORLD Tab (Expanded) ====================
local LightingGroup = Tabs.World:AddLeftGroupbox("Lighting & Atmosphere", "sun")
LightingGroup:AddSlider("ClockTimeSlider", { Text = "Clock Time", Default = 14, Min = 0, Max = 24, Rounding = 1, Callback = function(Value) 
	lighting.ClockTime = Value 
	getgenv().YokaiConfig.LockedClockTime = Value
end })
LightingGroup:AddToggle("TimeLockToggle", { Text = "Time Lock", Default = false, Callback = function(Value) getgenv().YokaiConfig.TimeLockEnabled = Value end })
LightingGroup:AddSlider("BrightnessSlider", { Text = "Global Brightness", Default = 2, Min = 0, Max = 10, Rounding = 1, Callback = function(Value) lighting.Brightness = Value end })
LightingGroup:AddToggle("FullBrightToggle", { Text = "Fullbright", Default = false, Callback = function(Value) if Value then lighting.Ambient = Color3.fromRGB(255, 255, 255); lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255) else lighting.Ambient = Color3.fromRGB(127, 127, 127); lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127) end end })
LightingGroup:AddToggle("NightVisionToggle", { Text = "Night Vision", Default = false, Callback = function(Value)
	getgenv().YokaiConfig.NightVisionEnabled = Value
	if Value then
		lighting.Ambient = Color3.fromRGB(50, 255, 50)
		lighting.OutdoorAmbient = Color3.fromRGB(50, 255, 50)
		lighting.Brightness = 5
	else
		lighting.Ambient = Color3.fromRGB(127, 127, 127)
		lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
		lighting.Brightness = 2
	end
end })

local EnvironmentGroup = Tabs.World:AddRightGroupbox("Environment & Fog", "cloud-rain")
EnvironmentGroup:AddToggle("RemoveFogToggle", { Text = "Remove Fog", Default = false, Callback = function(Value) if Value then lighting.FogEnd = 999999 else lighting.FogEnd = 1000 end end })
EnvironmentGroup:AddToggle("ShadowsToggle", { Text = "Global Shadows", Default = true, Callback = function(Value) lighting.GlobalShadows = Value end })
EnvironmentGroup:AddSlider("GravitySlider", { Text = "World Gravity", Default = 196.2, Min = 0, Max = 300, Rounding = 1, Callback = function(Value) ws.Gravity = Value end })
EnvironmentGroup:AddSlider("ExposureSlider", { Text = "Exposure Compensation", Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(Value) lighting.ExposureCompensation = Value end })

local WeatherGroup = Tabs.World:AddRightGroupbox("Weather Settings", "cloud-snow")
WeatherGroup:AddToggle("WeatherEnabled", { Text = "Enable", Default = false, Callback = function(Value) getgenv().YokaiConfig.WeatherEnabled = Value end })
WeatherGroup:AddDropdown("WeatherTypeDropdown", { Values = { "Snow", "Petals", "Autumn", "Mist", "Ash", "Sandstorm", "Embers", "Fireflies" }, Default = 1, Text = "Precipitation", Callback = function(Value) getgenv().YokaiConfig.WeatherType = Value end })
WeatherGroup:AddSlider("WeatherIntensitySlider", { Text = "Intensity", Default = 1, Min = 0.1, Max = 5, Rounding = 2, Callback = function(Value) getgenv().YokaiConfig.WeatherIntensity = Value end })
WeatherGroup:AddSlider("WeatherVolumeSlider", { Text = "Volume", Default = 0.35, Min = 0, Max = 1, Rounding = 2, Callback = function(Value) getgenv().YokaiConfig.WeatherVolume = Value end })
WeatherGroup:AddToggle("WeatherMoodTint", { Text = "Mood tint", Default = false, Callback = function(Value) getgenv().YokaiConfig.WeatherMoodTint = Value end })

-- ==================== UI SETTINGS Tab ====================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end })
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = true, Callback = function(Value) Library.ShowCustomCursor = Value end })
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function()
	aimbotCircle:Remove(); silentCircle:Remove(); for _, line in pairs(chLines) do line:Remove() end; chText:Remove()
	ESP.Enabled = false; Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("YokaiHub")
SaveManager:SetFolder("YokaiHub/config")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

Library:Notify({
	Title = "Yokai Hub",
	Description = "Yokai Hub successfully loaded with Solar System Animation ID!",
	Time = 4,
})

-- ==================== Weather & World Background Logic ====================
local weatherPart = Instance.new("Part")
weatherPart.Name = "YokaiWeatherEffect"
weatherPart.Size = Vector3.new(1, 1, 1)
weatherPart.Transparency = 1
weatherPart.Anchored = true
weatherPart.CanCollide = false

local weatherEmitter = Instance.new("ParticleEmitter")
weatherEmitter.Rate = 50
weatherEmitter.Speed = NumberRange.new(2, 6)
weatherEmitter.Lifetime = NumberRange.new(4, 8)
weatherEmitter.Parent = weatherPart

local weatherSound = Instance.new("Sound")
weatherSound.Name = "YokaiWeatherSound"
weatherSound.SoundId = "rbxassetid://9114221315"
weatherSound.Looped = true
weatherSound.Volume = 0.35
weatherSound.Parent = weatherPart

task.spawn(function()
	while true do
		task.wait(0.2)
		local cfg = getgenv().YokaiConfig
		
		if cfg.TimeLockEnabled then
			lighting.ClockTime = cfg.LockedClockTime
		end

		if cfg.WeatherEnabled and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
			weatherPart.Parent = ws
			weatherPart.Position = LP.Character.HumanoidRootPart.Position + Vector3.new(0, 25, 0)
			weatherEmitter.Rate = math.floor(40 * cfg.WeatherIntensity)
			weatherSound.Volume = cfg.WeatherVolume
			if not weatherSound.IsPlaying then
				weatherSound:Play()
			end
			
			local wType = cfg.WeatherType
			if wType == "Snow" then
				weatherEmitter.Texture = "rbxassetid://258129756"
				weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
				weatherEmitter.Size = NumberSequence.new(0.4, 0.8)
			elseif wType == "Petals" then
				weatherEmitter.Texture = "rbxassetid://1084991217"
				weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 182, 193))
				weatherEmitter.Size = NumberSequence.new(0.8, 1.2)
			elseif wType == "Autumn" then
				weatherEmitter.Texture = "rbxassetid://1084991217"
				weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(218, 165, 32))
				weatherEmitter.Size = NumberSequence.new(0.7, 1.1)
			elseif wType == "Mist" then
				weatherEmitter.Texture = "rbxassetid://243557551"
				weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
				weatherEmitter.Size = NumberSequence.new(3, 6)
			elseif wType == "Ash" then
				weatherEmitter.Texture = "rbxassetid://258129756"
				weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(50, 50, 50))
				weatherEmitter.Size = NumberSequence.new(0.3, 0.7)
			elseif wType == "Sandstorm" then
				weatherEmitter.Texture = "rbxassetid://258129756"
				weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(210, 180, 140))
				weatherEmitter.Size = NumberSequence.new(1, 2)
			elseif wType == "Embers" then
				weatherEmitter.Texture = "rbxassetid://1084991217"
				weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 69, 0))
				weatherEmitter.Size = NumberSequence.new(0.4, 0.8)
			elseif wType == "Fireflies" then
				weatherEmitter.Texture = "rbxassetid://1084991217"
				weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(173, 255, 47))
				weatherEmitter.Size = NumberSequence.new(0.2, 0.5)
			end
			
			if cfg.WeatherMoodTint then
				if wType == "Snow" or wType == "Mist" then
					lighting.Ambient = Color3.fromRGB(180, 200, 220)
				elseif wType == "Sandstorm" or wType == "Autumn" then
					lighting.Ambient = Color3.fromRGB(220, 190, 150)
				elseif wType == "Embers" or wType == "Ash" then
					lighting.Ambient = Color3.fromRGB(220, 150, 150)
				else
					lighting.Ambient = Color3.fromRGB(160, 160, 160)
				end
			end
		else
			weatherPart.Parent = nil
			if weatherSound.IsPlaying then
				weatherSound:Stop()
			end
		end
	end
end)

-- ==================== Rendering & Combat/Triggerbot Logic ====================
local function get_aimbot_target()
	local target, dist = nil, getgenv().YokaiConfig.AimbotFOV
	local mouse = UIS:GetMouseLocation()
	for _, v in pairs(P:GetPlayers()) do
		if v ~= LP and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
			local part = v.Character:FindFirstChild("HeadHB") or v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("UpperTorso")
			if part then
				local pos, on_screen = ws.CurrentCamera:WorldToViewportPoint(part.Position)
				if on_screen then
					local mag = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
					if mag < dist then dist = mag; target = part end
				end
			end
		end
	end
	return target
end

local lastTriggerFire = 0

RS.RenderStepped:Connect(function()
	local camera = ws.CurrentCamera
	local mousePos = UIS:GetMouseLocation()
	local viewportSize = camera.ViewportSize
	local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

	if getgenv().YokaiConfig.AimbotFOVVisible then
		aimbotCircle.Visible = true; aimbotCircle.Radius = getgenv().YokaiConfig.AimbotFOV; aimbotCircle.Position = mousePos; aimbotCircle.Filled = getgenv().YokaiConfig.AimbotFilled
		aimbotCircle.Color = getCustomRotatingColor(getgenv().YokaiConfig.AimbotColor1, getgenv().YokaiConfig.AimbotColor2, getgenv().YokaiConfig.AimbotColor3, 2)
	else aimbotCircle.Visible = false end

	if getgenv().YokaiConfig.SilentFOVVisible then
		silentCircle.Visible = true; silentCircle.Radius = getgenv().YokaiConfig.SilentFOV; silentCircle.Position = center; silentCircle.Filled = getgenv().YokaiConfig.SilentFull
		silentCircle.Color = getCustomRotatingColor(getgenv().YokaiConfig.SilentColor1, getgenv().YokaiConfig.SilentColor2, getgenv().YokaiConfig.SilentColor3, 2)
	else silentCircle.Visible = false end

	if getgenv().YokaiConfig.CrosshairEnabled then
		local cfg = getgenv().YokaiConfig
		local currentSize = cfg.CrosshairSize
		if cfg.CrosshairDynamic then currentSize = currentSize + math.sin(tick() * 6) * 3 end
		local gap = cfg.CrosshairGap
		local col = cfg.CrosshairRainbow and getCustomRotatingColor(Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255), 3) or cfg.CrosshairColor

		chLines.Top.Visible = true; chLines.Top.From = Vector2.new(center.X, center.Y - gap - currentSize); chLines.Top.To = Vector2.new(center.X, center.Y - gap); chLines.Top.Color = col
		chLines.Bottom.Visible = true; chLines.Bottom.From = Vector2.new(center.X, center.Y + gap); chLines.Bottom.To = Vector2.new(center.X, center.Y + gap + currentSize); chLines.Bottom.Color = col
		chLines.Left.Visible = true; chLines.Left.From = Vector2.new(center.X - gap - currentSize, center.Y); chLines.Left.To = Vector2.new(center.X - gap, center.Y); chLines.Left.Color = col
		chLines.Right.Visible = true; chLines.Right.From = Vector2.new(center.X + gap, center.Y); chLines.Right.To = Vector2.new(center.X + gap + currentSize, center.Y); chLines.Right.Color = col

		if cfg.CrosshairTextEnabled then
			chText.Visible = true; chText.Text = cfg.CrosshairText; chText.Position = Vector2.new(center.X, center.Y + gap + currentSize + 5); chText.Color = col
		else chText.Visible = false end
	else
		for _, line in pairs(chLines) do line.Visible = false end
		chText.Visible = false
	end

	if getgenv().YokaiConfig.AimbotEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		local target = get_aimbot_target()
		if target then
			local pos, _ = camera:WorldToViewportPoint(target.Position)
			local x = (pos.X - mousePos.X) * getgenv().YokaiConfig.AimbotSmoothness
			local y = (pos.Y - mousePos.Y) * getgenv().YokaiConfig.AimbotSmoothness
			if mousemoverel then mousemoverel(x, y) end
		end
	end

	local tCfg = getgenv().YokaiConfig
	if tCfg.TriggerbotEnabled then
		local activationOk = true
		if tCfg.TriggerActivation == "Hold" and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			activationOk = false
		elseif tCfg.TriggerActivation == "Toggle" and not tCfg.TriggerbotEnabled then
			activationOk = false
		end

		if activationOk then
			local mouse = LP:GetMouse()
			local targetObj = mouse.Target
			if targetObj and targetObj.Parent then
				local char = targetObj.Parent
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					local enemyPlr = P:GetPlayerFromCharacter(char)
					if enemyPlr and enemyPlr ~= LP then
						local dist = (camera.CFrame.Position - targetObj.Position).Magnitude
						if dist <= tCfg.TriggerMaxDistance then
							local headCheckOk = not tCfg.TriggerHeadOnly or (targetObj.Name == "Head" or targetObj.Name == "HeadHB")
							if headCheckOk then
								local currTick = tick() * 1000
								if currTick - lastTriggerFire >= tCfg.TriggerRefireDelay then
									if tCfg.TriggerReactionDelay > 0 then
										task.wait(tCfg.TriggerReactionDelay / 1000)
									end
									lastTriggerFire = tick() * 1000
									mouse1click()
								end
							end
						end
					end
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.01)
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if hum and getgenv().YokaiConfig.WalkSpeedEnabled then hum.WalkSpeed = getgenv().YokaiConfig.WalkSpeedValue end

		if getgenv().YokaiConfig.NoclipEnabled and char then
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	end
end)

UIS.JumpRequest:Connect(function()
	if getgenv().YokaiConfig.InfJumpEnabled then
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

task.spawn(function()
	while true do
		local char = LP.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChild("Humanoid")
		local camera = ws.CurrentCamera

		if getgenv().YokaiConfig.FlyEnabled and root and hum then
			pcall(function()
				hum.PlatformStand = true
				local moveDir = Vector3.new(0, 0, 0)
				if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
				if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

				root.Velocity = moveDir * getgenv().YokaiConfig.FlySpeed
				root.CFrame = CFrame.new(root.Position, root.Position + camera.CFrame.LookVector)
			end)
		elseif hum and not getgenv().YokaiConfig.VoidEnabled and not getgenv().YokaiConfig.RagebotEnabled then
			hum.PlatformStand = false
		end
		RS.Heartbeat:Wait()
	end
end)

-- ==================== Ragebot & Void Hit Fix Background Logic ====================
task.spawn(function()
	local success, utilModule = pcall(function() return require(repS.Modules.Utility) end)
	local success2, enumModule = pcall(function() return require(repS.Modules.EnumLibrary) end)
	local success3, FighterController = pcall(function() return require(LP.PlayerScripts.Controllers.FighterController) end)
	local success4, SpectateController = pcall(function() return require(LP.PlayerScripts.Controllers:WaitForChild("SpectateController")) end)

	if not (success and success2 and success3 and success4) then
		warn("[Yokai Hub] Ragebot modules could not be loaded for this game.")
		return
	end

	local util = utilModule
	local enum = enumModule

	local slots = { Primary = 1, Secondary = 2, Melee = 3 }
	local function getSlotNumber()
		return slots[getgenv().YokaiConfig.WeaponSlot] or 3
	end

	task.spawn(function()
		local localFighter = FighterController.LocalFighter
		while not localFighter do
			task.wait(0.1)
			localFighter = FighterController.LocalFighter
		end
		pcall(function() localFighter:EquipItem(getSlotNumber()) end)
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			if not getgenv().YokaiConfig.RagebotEnabled then continue end
			local localFighter = FighterController.LocalFighter
			if localFighter then
				pcall(function() localFighter:EquipItem(getSlotNumber()) end)
			end
		end
	end)

	local lastFire = 0
	local deflecting = {}
	P.PlayerRemoving:Connect(function(player) deflecting[player] = nil end)

	local function updateDeflection()
		if not FighterController or not FighterController.Objects then return end
		for _, fighterObj in FighterController.Objects do
			local player = fighterObj.Player
			if not player then continue end
			if not fighterObj.Entity or not fighterObj.Entity:IsAlive() or fighterObj:Get("IsSpectating") then
				deflecting[player] = false
				continue
			end
			local equipped = fighterObj.EquippedItem
			local isKatana = equipped and equipped.ViewModel and equipped.ViewModel.Name == "Katana"
			local isDeflecting = false
			if isKatana then
				isDeflecting = (equipped._attack_cooldown and equipped._attack_cooldown > tick()) or false
			end
			deflecting[player] = isDeflecting
		end
	end

	local function isEnemy(player)
		if player == LP then return false end
		local duel = SpectateController.CurrentDuelSubject
		local localDueler = duel and duel:GetDueler(LP)
		local localTeam = localDueler and localDueler:Get("TeamID") or nil
		if localTeam and duel and duel.Duelers then
			for _, dueler in duel.Duelers do
				if dueler.Player == player then
					local team = dueler:Get("TeamID")
					return team ~= localTeam
				end
			end
		end
		local pTeam = player:GetAttribute("TeamID")
		local lTeam = LP:GetAttribute("TeamID")
		if pTeam and lTeam then return pTeam ~= lTeam end
		return true
	end

	local function getClosestTarget()
		local char = LP.Character
		if not char then return nil, nil, nil end
		local myRoot = char:FindFirstChild("HumanoidRootPart")
		if not myRoot then return nil, nil, nil end
		local closestPlayer, closestRoot, closestHead = nil, nil, nil
		local closestDist = math.huge
		for _, player in P:GetPlayers() do
			if not isEnemy(player) then continue end
			local pChar = player.Character
			if not pChar then continue end
			local pRoot = pChar:FindFirstChild("HumanoidRootPart")
			local pHead = pChar:FindFirstChild("Head")
			local pHum = pChar:FindFirstChildWhichIsA("Humanoid")
			if not (pRoot and pHead and pHum and pHum.Health > 0) then continue end
			local dist = (myRoot.Position - pRoot.Position).Magnitude
			if dist < closestDist then
				closestDist = dist; closestPlayer = player; closestRoot = pRoot; closestHead = pHead
			end
		end
		return closestPlayer, closestRoot, closestHead
	end

	local function hasKnifeViewModel(targetPlayer)
		if not targetPlayer then return false end
		local viewModels = ws:FindFirstChild("ViewModels")
		if not viewModels then return false end
		local targetName = targetPlayer.Name
		for _, model in viewModels:GetChildren() do
			if model:IsA("Model") and string.find(model.Name, targetName, 1, true) and string.find(model.Name, "Knife", 1, true) then
				return true
			end
		end
		return false
	end

	RS.Heartbeat:Connect(function()
		if not getgenv().YokaiConfig.RagebotEnabled then
			_isFiringOrDesyncing = false
			return
		end

		updateDeflection()
		local targetPlayer, targetRoot, targetHead = getClosestTarget()
		local desyncCF = nil
		
		if targetRoot and targetHead then
			local desyncPos
			if hasKnifeViewModel(targetPlayer) then
				desyncPos = (targetRoot.CFrame * CFrame.new(0, 6, 0)).Position
			else
				desyncPos = (targetRoot.CFrame * CFrame.new(0, 1, 2)).Position
			end
			desyncCF = CFrame.lookAt(desyncPos, targetHead.Position)
		end

		_isFiringOrDesyncing = true

		if desyncCF and LP.Character then
			local myRoot = LP.Character:FindFirstChild("HumanoidRootPart")
			if myRoot then
				local oldCF = myRoot.CFrame
				local oldVel = myRoot.Velocity
				local oldRotVel = myRoot.RotVelocity
				myRoot.CFrame = desyncCF
				myRoot.Velocity = Vector3.new(0, 0, 0)
				RS:BindToRenderStep("__restore", 101, function()
					if myRoot then
						myRoot.CFrame = oldCF
						myRoot.Velocity = oldVel
						myRoot.RotVelocity = oldRotVel
					end
					RS:UnbindFromRenderStep("__restore")
					_isFiringOrDesyncing = false
				end)
			end
		else
			_isFiringOrDesyncing = false
		end

		if not targetPlayer or not targetHead or not targetRoot then return end
		if deflecting[targetPlayer] then return end
		if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
		if not FighterController or not FighterController.LocalFighter then return end
		local item = FighterController.LocalFighter.EquippedItem
		if not item then return end
		if tick() - lastFire < getgenv().YokaiConfig.FireRate then return end
		lastFire = tick()

		local originPos = desyncCF and desyncCF.Position or targetRoot.Position
		local targetPos = targetHead.Position
		local aimCF = CFrame.lookAt(originPos, targetPos)
		local targetCF = targetHead.CFrame
		local randomOffset = Vector3.new((math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.1)
		local aimedPos = targetPos + randomOffset
		local objSpaceHeadOffset = targetHead.CFrame:ToObjectSpace(CFrame.new(aimedPos))
		
		local cameradata = {}
		cameradata[utf8.char(1)] = {
			[utf8.char(0)] = util:EncodeCFrame(aimCF),
			[utf8.char(1)] = util:EncodeCFrame(targetCF),
			[utf8.char(2)] = targetHead,
			[utf8.char(3)] = util:EncodeCFrame(objSpaceHeadOffset)
		}
		repS.Remotes.Replication.Fighter.UseItem:FireServer(item:Get("ObjectID"), enum:ToEnum("StartShooting"), cameradata, nil)
	end)
end)
