--========================================================
--  AutoCDK
--  1) Сначала качает Yama и Tushita до 350 мастери на Reborn Skeleton
--     в Haunted Castle, затем делает CommF_("CDKQuest","OpenDoor")
--  2) После открытия двери запускает связку:
--        AF 0 -> Yama1
--        AF 1 -> Yama2
--        AF 2 -> Yama3 (полный скрипт Bones+Hallow+HellDimension)
--        AF 3 -> Tushita1 (Trial Evil + Trial Good + BoatQuest)
--        AF 4 -> Tushita2 (Trial Good)
--        AF 5 -> Tushita3 (Trial Good + Cake Queen + HeavenlyDimension)
--        AF >=6 -> всё готово, AutoCDK выключается
--========================================================

---------------------
-- НАСТРОЙКИ
---------------------
local WeaponName         = "Godhuman"       -- чем бить мобов
local SwordYamaName      = "Yama"
local SwordTushitaName   = "Tushita"
local MasteryTarget      = 350

local TeleportSpeed      = 300
local FarmOffset         = CFrame.new(0, 10, -3)

-- Castle on the Sea (Elite Hunter) для Yama1
local CastleOnSeaCFrame  = CFrame.new(-5494.08154, 313.794739, -2874.36621)

-- Haunted Castle / Death King (для мастери и Yama3)
local HauntedFallback    = CFrame.new(-9515.129, 142.233, 6200.441)

-- Soul Reaper spawn (Yama3)
local SoulReaperSpawnCF  = CFrame.new(-9570.033203125, 315.9346923828125, 6726.89306640625)

-- Максимум роллов костей в Yama3 (как в AutoBones)
local MaxRollsPerWindow  = 10
local RollWindowDuration = 2*60*60 + 5*60
local MinBonesToRoll     = 500

-- Патруль Yama2 (HazeESP)
-- Патруль Yama2 (HazeESP)
local Yama2PatrolPoints = {
    -- старые точки
    CFrame.new(-187.3301544189453, 86.23987579345703, 6013.513671875),
    CFrame.new(2286.0078125, 73.13391876220703, -7159.80908203125),
    CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875),
    CFrame.new(-13451.46484375, 543.712890625, -6961.0029296875),
    CFrame.new(-13274.478515625, 332.3781433105469, -7769.58056640625),
    CFrame.new(-13680.607421875, 501.08154296875, -6991.189453125),
    CFrame.new(-13457.904296875, 391.545654296875, -9859.177734375),
    CFrame.new(-12256.16015625, 331.73828125, -10485.8369140625),
    CFrame.new(-1887.8099365234375, 77.6185073852539, -12998.3505859375),
    CFrame.new(-21.55328369140625, 80.57499694824219, -12352.3876953125),
    CFrame.new(582.590576171875, 77.18809509277344, -12463.162109375),
    CFrame.new(-16641.6796875, 235.7825469970703, 1031.282958984375),
    CFrame.new(-16587.896484375, 154.21299743652344, 1533.40966796875),
    CFrame.new(-16885.203125, 114.12911224365234, 1627.949951171875),

    -- новые точки – в основном кемпы и острова
    -- Кемп Isle Champion около Castle on the Sea
    CFrame.new(-16641.6796875, 235.7825469970703, 1031.282958984375), -- ещё раз центр кемпа
    CFrame.new(-16540.1201171875, 236.10000610351562, 950.552734375),
    CFrame.new(-16720.5546875, 230.39999389648438, 1120.77490234375),

    -- Castle on the Sea / пристань
    CFrame.new(-5472.1201171875, 313.3000183105469, -2931.77001953125),
    CFrame.new(-4618.22021484375, 452.1000061035156, -1820.77001953125),
    CFrame.new(-4890.1103515625, 320.0, -2980.210205078125),
    CFrame.new(-5180.330078125, 316.70001220703125, -3400.880126953125),

    -- Haunted Castle – центр и кемпы Reborn Skeleton
    CFrame.new(-9515.129, 142.233, 6200.441),
    CFrame.new(-9450.55078125, 144.0, 6025.1103515625),
    CFrame.new(-9605.98046875, 144.5, 6350.27001953125),
    CFrame.new(-9705.443359375, 146.2, 6150.88916015625),

    -- Остров Cake Queen / Cake Island
    CFrame.new(-709.3132934570312, 381.6005859375, -11011.396484375),
    CFrame.new(-580.552734375, 380.90057373046875, -10840.220703125),
    CFrame.new(-840.77490234375, 382.2005615234375, -11180.552734375),

    -- Sea of Treats / сахарные острова
    CFrame.new(2356.440185546875, 72.80000305175781, -12890.6005859375),
    CFrame.new(1331.7000732421875, 72.80000305175781, -13550.2001953125),
    CFrame.new(920.77001953125, 78.5, -12880.330078125),
    CFrame.new(555.4400024414062, 77.2, -11980.220703125),

    -- Разные точки на главном острове Mansion / Hydra
    CFrame.new(-12240.55078125, 332.0, -9850.7705078125),
    CFrame.new(-11980.330078125, 332.0, -9450.880859375),
    CFrame.new(-11800.7744140625, 332.0, -10120.552734375),

    -- Доп. точки возле Hydra Island
    CFrame.new(-17020.150390625, 180.0, 1240.6600341796875),
    CFrame.new(-17310.5107421875, 140.0, 1760.330078125),
    CFrame.new(-16950.220703125, 260.0, 530.4400024414062),

    -- Пара разбросанных точек между островами
    CFrame.new(-1920.77001953125, 72.0, -14050.330078125),
    CFrame.new(-350.1100158691406, 80.0, -12150.990234375)
}


-- Tushita Q1 (BoatQuest)
local TushitaQ1Points = {
    CFrame.new(-9546.990234375, 21.139892578125, 4686.1142578125),
    CFrame.new(-6120.0576171875, 16.455780029296875, -2250.697265625),
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875),
}

-- Tushita Q2
local TushitaQ2Center         = CFrame.new(-5539.3115, 313.8005, -2972.3723)
local TushitaQ2InZoneRadius   = 500
local TushitaQ2MaxMobDistance = 2000

-- Tushita Q3 (Cake Queen + HeavenlyDimension)
local CakeQueenIsland = CFrame.new(-709.3132934570312, 381.6005859375, -11011.396484375)
local CakeQueenOffset = CFrame.new(0, 20, -3)

---------------------
-- СЕРВИСЫ
---------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local VirtualInput      = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local remote      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- СОСТОЯНИЯ
---------------------
local AutoCDK        = false
local CurrentStage   = -1           -- стадия по Alucard Fragment (0..6)
local NeedMastery    = true         -- пока не прокачали 350/350
local DoorOpened     = false

local IsTeleporting  = false
local StopTween      = false
local NoclipEnabled  = false

-- флаги квестов
local AutoYama1      = false
local AutoYama2      = false
local AutoYama3      = false
local AutoTushita1   = false
local AutoTushita2   = false
local AutoTushita3   = false

-- мастери
local LastMasteryCheck = 0

-- Yama2
local Yama2PatrolIndex   = 1
local Yama2PatrolHold    = 0
local Yama2LastPatrolHop = 0
local Yama2IsFighting    = false

-- Yama3 (Bones/Hallow)
local BonesCount      = 0
local RollsUsed       = 0
local HasHallow       = false
local RollWindowStart = os.time()
local IsFightingBones = false
local lastRollAttempt = 0

-- HeavenlyDimension (Tushita3)
local T3_HeavenlyStage = 0

---------------------
-- ЛОГИ / GUI
---------------------
local StatusLogs = {}
local MaxLogs    = 250

local ScreenGui, MainFrame, BtnCDK
local StatusLabel, AFLabel, LogsText
local MasteryLabel

local function AddLog(msg)
    local ts   = os.date("%H:%M:%S")
    local line = "["..ts.."] "..tostring(msg)
    table.insert(StatusLogs, 1, line)
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
    if LogsText then
        LogsText.Text = table.concat(StatusLogs, "\n")
    end
    print(line)
end

local function UpdateStatus(text)
    if StatusLabel then
        StatusLabel.Text = "Статус: "..tostring(text)
    end
    AddLog("Статус: "..tostring(text))
end

local function UpdateAFLabel(count)
    if AFLabel then
        AFLabel.Text = "Alucard Fragment: "..tostring(count or 0)
    end
end

local function UpdateMasteryLabel(yamaM, tushM)
    if MasteryLabel then
        MasteryLabel.Text = string.format("Mastery Yama/Tushita: %d / %d (цель %d)",
            yamaM or 0, tushM or 0, MasteryTarget)
    end
end

---------------------
-- GUI
---------------------
local function CreateMainGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoCDKGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 540, 0, 330)
    MainFrame.Position = UDim2.new(0, 40, 0, 180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    title.Text = "Auto CDK (Mastery -> Yama/Tushita Quests)"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = MainFrame

    BtnCDK = Instance.new("TextButton")
    BtnCDK.Size = UDim2.new(0, 220, 0, 32)
    BtnCDK.Position = UDim2.new(0, 10, 0, 30)
    BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
    BtnCDK.TextColor3 = Color3.new(1,1,1)
    BtnCDK.Font = Enum.Font.SourceSansBold
    BtnCDK.TextSize = 16
    BtnCDK.Text = "Auto CDK: OFF"
    BtnCDK.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 22)
    StatusLabel.Position = UDim2.new(0, 10, 0, 70)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: Остановлен"
    StatusLabel.Parent = MainFrame

    AFLabel = Instance.new("TextLabel")
    AFLabel.Size = UDim2.new(1, -20, 0, 22)
    AFLabel.Position = UDim2.new(0, 10, 0, 92)
    AFLabel.BackgroundTransparency = 1
    AFLabel.TextColor3 = Color3.new(1,1,1)
    AFLabel.Font = Enum.Font.SourceSans
    AFLabel.TextSize = 14
    AFLabel.TextXAlignment = Enum.TextXAlignment.Left
    AFLabel.Text = "Alucard Fragment: 0"
    AFLabel.Parent = MainFrame

    MasteryLabel = Instance.new("TextLabel")
    MasteryLabel.Size = UDim2.new(1, -20, 0, 22)
    MasteryLabel.Position = UDim2.new(0, 10, 0, 114)
    MasteryLabel.BackgroundTransparency = 1
    MasteryLabel.TextColor3 = Color3.new(1,1,1)
    MasteryLabel.Font = Enum.Font.SourceSans
    MasteryLabel.TextSize = 14
    MasteryLabel.TextXAlignment = Enum.TextXAlignment.Left
    MasteryLabel.Text = "Mastery Yama/Tushita: 0 / 0"
    MasteryLabel.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 180)
    LogsFrame.Position = UDim2.new(0, 10, 0, 140)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
    LogsFrame.BorderSizePixel = 0
    LogsFrame.Parent = MainFrame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -4)
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0,0,5,0)
    scroll.ScrollBarThickness = 4
    scroll.Parent = LogsFrame

    LogsText = Instance.new("TextLabel")
    LogsText.Size = UDim2.new(1, -4, 0, 20)
    LogsText.Position = UDim2.new(0, 0, 0, 0)
    LogsText.BackgroundTransparency = 1
    LogsText.TextColor3 = Color3.new(1,1,1)
    LogsText.Font = Enum.Font.Code
    LogsText.TextSize = 12
    LogsText.TextXAlignment = Enum.TextXAlignment.Left
    LogsText.TextYAlignment = Enum.TextYAlignment.Top
    LogsText.TextWrapped = false
    LogsText.Text = ""
    LogsText.Parent = scroll

    BtnCDK.MouseButton1Click:Connect(function()
        AutoCDK = not AutoCDK
        if AutoCDK then
            BtnCDK.Text = "Auto CDK: ON"
            BtnCDK.BackgroundColor3 = Color3.fromRGB(0,120,0)
            NoclipEnabled = true
            StopTween = false
            UpdateStatus("Auto CDK включен. Сначала мастери, потом квесты.")
        else
            BtnCDK.Text = "Auto CDK: OFF"
            BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled = false
            StopTween = true
            UpdateStatus("Остановлен")
            AutoYama1,AutoYama2,AutoYama3=false,false,false
            AutoTushita1,AutoTushita2,AutoTushita3=false,false,false
        end
    end)

    AddLog("GUI AutoCDK загружен.")
end

CreateMainGui()

---------------------
-- ANTI-AFK
---------------------
spawn(function()
    while task.wait(60) do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

---------------------
-- NOCLIP
---------------------
spawn(function()
    while task.wait(0.1) do
        if NoclipEnabled then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

---------------------
-- NET / FAST ATTACK
---------------------
local modules        = ReplicatedStorage:WaitForChild("Modules")
local net            = modules:WaitForChild("Net")
local RegisterAttack = net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = net:WaitForChild("RE/RegisterHit")

local AttackModule = {}

function AttackModule:AttackEnemyModel(enemyModel)
    if not enemyModel then return end
    local hrp = enemyModel:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hitTable = { {enemyModel, hrp} }

    RegisterAttack:FireServer(0)
    RegisterAttack:FireServer(1)
    RegisterHit:FireServer(hrp, hitTable)
end

---------------------
-- ЭКИП / ХАКИ
---------------------
local function AutoHaki()
    local char = LocalPlayer.Character
    if not char then return end
    if not char:FindFirstChild("HasBuso") then
        pcall(function()
            remote:InvokeServer("Buso")
        end)
    end
end

local lastEquipFailLog = 0

local function IsToolEquipped(name)
    local char = LocalPlayer.Character
    if not char then return false end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and string.lower(obj.Name) == string.lower(name) then
            return true
        end
    end
    return false
end

local function EquipToolByName(name)
    if IsToolEquipped(name) then return end

    local p   = LocalPlayer
    if not p then return end

    local char = p.Character or p.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local nameLower = string.lower(name)
    local toolFound

    local function findToolIn(container)
        if not container then return nil end
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Tool") and string.lower(obj.Name) == nameLower then
                return obj
            end
        end
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("Tool") and string.lower(obj.Name) == nameLower then
                return obj
            end
        end
        return nil
    end

    local backpack = p:FindFirstChild("Backpack")
    if backpack then
        toolFound = findToolIn(backpack)
    end
    if not toolFound and char then
        toolFound = findToolIn(char)
    end

    if toolFound then
        hum:UnequipTools()
        hum:EquipTool(toolFound)
        AddLog("⚔️ Экипирован: "..toolFound.Name)
    else
        if tick() - lastEquipFailLog > 3 then
            AddLog("⚠️ Не удалось найти оружие: "..name)
            lastEquipFailLog = tick()
        end
    end
end

---------------------
-- ТП
---------------------
local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting then return end
    IsTeleporting = true
    StopTween     = false

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        IsTeleporting = false
        return
    end

    local hrp      = char.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local travelTime = distance / TeleportSpeed
    travelTime = math.clamp(travelTime, 0.5, 60)

    AddLog(string.format("Телепорт к %s (%.0f stud, t=%.1f)", label or "цели", distance, travelTime))

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()

    local start = tick()
    while tick() - start < travelTime do
        if StopTween or not AutoCDK then
            tween:Cancel()
            IsTeleporting = false
            AddLog("Телепорт прерван.")
            return
        end

        local c = LocalPlayer.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not c or not hrp then
            tween:Cancel()
            IsTeleporting = false
            return
        end

        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide = false

        task.wait(0.2)
    end

    tween:Cancel()
    local c = LocalPlayer.Character
    hrp = c and c:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide = false
    end

    IsTeleporting = false
end

LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = false
    AddLog("Персонаж возрождён, HRP обновлён.")
    char:WaitForChild("HumanoidRootPart", 10)
end)

---------------------
-- ИНВЕНТАРЬ / МАТЕРИАЛЫ / МАСТЕРИ
---------------------
local function GetInventory()
    local ok, inv = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then
        return inv
    end
    return {}
end

local function GetCountMaterials(MaterialName)
    local Inventory = GetInventory()
    for _, v in pairs(Inventory) do
        if v.Name == MaterialName then
            return v.Count or v.count or 0
        end
    end
    return 0
end

local function GetWeaponMastery(name)
    local inv = GetInventory()
    for _, v in ipairs(inv) do
        if v.Name == name then
            return v.Mastery or v.Level or v.MasteryLevel or 0
        end
    end
    return 0
end

---------------------
-- CDKTrialModule (StartTrial Evil / Good с Option1)
---------------------
local function ClickDialogueOption1(tag)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    local main = pg:FindFirstChild("Main")
    if not main then return end
    local dialogue = main:FindFirstChild("Dialogue")
    if not dialogue then return end
    local opt1 = dialogue:FindFirstChild("Option1")
    if opt1 and opt1:IsA("TextButton") then
        AddLog((tag or "").." Нажимаю Dialogue.Option1 два раза.")
        if typeof(firesignal) == "function" then
            pcall(firesignal, opt1.MouseButton1Click)
            pcall(firesignal, opt1.MouseButton1Click)
        else
            -- fallback: имитация клика через VirtualInput по центру кнопки
            local absPos = opt1.AbsolutePosition
            local absSize = opt1.AbsoluteSize
            local cx = absPos.X + absSize.X/2
            local cy = absPos.Y + absSize.Y/2
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
        end
    else
        AddLog((tag or "").." Dialogue.Option1 не найден.")
    end
end

local CDKTrialModule = {}

function CDKTrialModule.StartGoodTrial()
    AddLog("[Trial Good] Progress...")
    local okP, resP = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Good")
    end)
    AddLog("[Trial Good] Progress => "..tostring(resP))

    task.wait(0.2)

    AddLog("[Trial Good] StartTrial...")
    local okS, resS = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Good")
    end)
    AddLog("[Trial Good] StartTrial => "..tostring(resS))

    task.wait(0.1)
    ClickDialogueOption1("[Trial Good]")
end

function CDKTrialModule.StartEvilTrial()
    AddLog("[Trial Evil] Progress...")
    local okP, resP = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Evil")
    end)
    AddLog("[Trial Evil] Progress => "..tostring(resP))

    task.wait(0.2)

    AddLog("[Trial Evil] StartTrial...")
    local okS, resS = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Evil")
    end)
    AddLog("[Trial Evil] StartTrial => "..tostring(resS))

    task.wait(0.1)
    ClickDialogueOption1("[Trial Evil]")
end

---------------------
-- HAUNTED / SKELETON HELPERS (общие)
---------------------
local function FindDeathKingModel()
    local candidate
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Death King" then
            if obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") then
                candidate = obj
                break
            end
        end
    end
    return candidate
end

local function GetHauntedCenterCFrame()
    local dk = FindDeathKingModel()
    if dk then
        local hrp = dk:FindFirstChild("HumanoidRootPart") or dk:FindFirstChild("Head")
        if hrp then
            return hrp.CFrame
        end
    end
    return HauntedFallback
end

local function IsSkeletonMob(mob)
    local n = tostring(mob.Name)
    if string.find(n, "Reborn Skeleton") then return true end
    if string.find(n, "Skeleton") then return true end
    if string.find(n, "Living Skeleton") then return true end
    return false
end

local function GetNearestSkeleton(maxDistance)
    maxDistance = maxDistance or 9999
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local center = GetHauntedCenterCFrame()
    local best, nearest = maxDistance, nil

    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if IsSkeletonMob(v) then
                local distFromCenter = (v.HumanoidRootPart.Position - center.Position).Magnitude
                if distFromCenter < 800 then
                    local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < best then
                        best    = d
                        nearest = v
                    end
                end
            end
        end
    end
    return nearest
end

local function EnsureOnHauntedIsland()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return false end

    local center = GetHauntedCenterCFrame()
    local dist   = (hrp.Position - center.Position).Magnitude
    if dist > 600 then
        UpdateStatus("Лечу к Haunted Castle.")
        SimpleTeleport(center * CFrame.new(0,4,3), "Haunted Castle")
        task.wait(1)
        return false
    end
    return true
end

---------------------
-- МАСТЕРИ-ФАРМ (Reborn Skeleton)
---------------------
local function FightMobForWeapon(target, weaponName, label)
    if not target then return end
    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        UpdateStatus(label or ("Фарм мастери: "..weaponName.." по "..target.Name))
        SimpleTeleport(tHRP.CFrame * FarmOffset, label or "мастери моб")

        local deadline      = tick() + 60
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoCDK and NeedMastery and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий моб мастери")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName(weaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка FightMobForWeapon: "..tostring(err))
    end
end

local function MasteryTick()
    if not AutoCDK or not NeedMastery then return end

    if not EnsureOnHauntedIsland() then return end

    local yamaM  = GetWeaponMastery(SwordYamaName)
    local tushM  = GetWeaponMastery(SwordTushitaName)
    UpdateMasteryLabel(yamaM, tushM)

    if yamaM >= MasteryTarget and tushM >= MasteryTarget then
        if not DoorOpened then
            UpdateStatus("Мастери достигнуты, открываю дверь CDK.")
            local ok, res = pcall(function()
                return remote:InvokeServer("CDKQuest","OpenDoor")
            end)
            AddLog("OpenDoor => "..tostring(res))
            DoorOpened = true
        end
        NeedMastery = false
        UpdateStatus("Мастери готовы, перехожу к Yama/Tushita квестам.")
        return
    end

    local target = GetNearestSkeleton(9999)
    if not target then
        UpdateStatus("Mastery: скелеты не найдены, жду спавна.")
        return
    end

    if yamaM < MasteryTarget then
        FightMobForWeapon(target, SwordYamaName, "Mastery: Yama")
    elseif tushM < MasteryTarget then
        FightMobForWeapon(target, SwordTushitaName, "Mastery: Tushita")
    end
end

---------------------
-- YAMA QUEST 1
---------------------
local function YamaQuest1Tick()
    if not AutoYama1 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 1 then
        AutoYama1 = false
        UpdateStatus("Yama1: фрагмент получен, перехожу к Yama2.")
        return
    end

    EquipToolByName("Yama")

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and hrp and hum) then return end

    if hum.Health <= 0 then return end

    local dist = (hrp.Position - CastleOnSeaCFrame.Position).Magnitude
    if dist > 150 then
        UpdateStatus("Yama1: лечу к Elite Hunter (Castle on the Sea), жду смерти.")
        SimpleTeleport(CastleOnSeaCFrame, "Elite Hunter (Castle on the Sea)")
    else
        UpdateStatus("Yama1: стою у Elite Hunter, жду смерти.")
    end
end

---------------------
-- YAMA QUEST 2 (HazeESP)
---------------------
local function GetNearestHazeEnemy(maxDistance)
    maxDistance = maxDistance or 9999
    local enemies = Workspace:FindFirstChild("Enemies")
    local char    = LocalPlayer.Character
    local hrp     = char and char:FindFirstChild("HumanoidRootPart")
    if not enemies or not hrp then return nil end

    local best, nearest = maxDistance, nil
    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if v:FindFirstChild("HazeESP") then
                local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < best then
                    best    = d
                    nearest = v
                end
            end
        end
    end
    return nearest
end

local function Yama2PatrolStep()
    if not AutoYama2 or not AutoCDK then return end
    if IsTeleporting then return end
    if tick() < Yama2PatrolHold then return end
    if tick() - Yama2LastPatrolHop < 2 then return end

    local idx = Yama2PatrolIndex
    Yama2PatrolIndex = Yama2PatrolIndex + 1
    if Yama2PatrolIndex > #Yama2PatrolPoints then
        Yama2PatrolIndex = 1
    end

    Yama2LastPatrolHop = tick()
    local targetCF = Yama2PatrolPoints[idx] * FarmOffset
    AddLog("Yama2: патруль к точке "..idx)
    SimpleTeleport(targetCF, "Yama2 патруль "..idx)
    Yama2PatrolHold = tick() + 5
end

local function YamaQuest2Tick()
    if not AutoYama2 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 2 then
        AutoYama2 = false
        UpdateStatus("Yama2: второй фрагмент получен, перехожу к Yama3.")
        return
    end

    if Yama2IsFighting then return end

    local target = GetNearestHazeEnemy(9999)
    if not target then
        UpdateStatus("Yama2: Haze-мобы не найдены, патрулирую.")
        Yama2PatrolStep()
        return
    end

    Yama2IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        UpdateStatus("Yama2: фарм "..target.Name)
        SimpleTeleport(tHRP.CFrame * FarmOffset, "Yama2 моб")

        local deadline      = tick() + 40
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoYama2 and AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий Haze-моб")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName("Yama")

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка YamaQuest2Tick: "..tostring(err))
    end

    Yama2IsFighting = false
end

---------------------
-- YAMA QUEST 3  (ПОЛНЫЙ, как AutoBones, но под AutoYama3/AutoCDK)
---------------------
local function HasItemInInventory(itemName)
    local p = LocalPlayer
    if not p then return false end

    local backpack = p:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(itemName) then
        return true
    end

    local char = p.Character
    if char and char:FindFirstChild(itemName) then
        return true
    end

    local invData = GetInventory()
    for _, item in ipairs(invData) do
        local name = item.Name or item.name or tostring(item)
        if name == itemName then
            return true
        end
    end
    return false
end

local function UpdateHallowStatus()
    HasHallow = HasItemInInventory("Hallow Essence")
end

local function RefreshBonesCount()
    local c = GetCountMaterials("Bones")
    BonesCount = c or 0
end

local function RefreshRollWindow()
    local now = os.time()
    if now - RollWindowStart > RollWindowDuration then
        RollWindowStart = now
        RollsUsed = 0
        AddLog("Yama3: окно роллов обновлено, RollsUsed = 0.")
    end
end

local function DoDeathKingRolls()
    UpdateHallowStatus()
    if HasHallow then
        AddLog("Yama3: Hallow Essence уже есть, роллы не нужны.")
        return
    end

    RefreshBonesCount()
    if BonesCount < MinBonesToRoll then
        AddLog("Yama3: костей меньше "..MinBonesToRoll..", ролл откладывается.")
        return
    end

    RefreshRollWindow()
    if RollsUsed >= MaxRollsPerWindow then
        AddLog("Yama3: лимит роллов ("..MaxRollsPerWindow..") достигнут.")
        return
    end

    if tick() - lastRollAttempt < 5 then
        return
    end
    lastRollAttempt = tick()

    UpdateStatus("Yama3: роллы у Death King.")
    local center = GetHauntedCenterCFrame()
    SimpleTeleport(center * CFrame.new(0,4,3), "Death King")
    task.wait(1.2)

    local rollsToDo = MaxRollsPerWindow - RollsUsed
    for i = 1, rollsToDo do
        RefreshBonesCount()
        if BonesCount < 50 then
            AddLog("Yama3: костей <50, остановка роллов.")
            break
        end

        RefreshRollWindow()
        if RollsUsed >= MaxRollsPerWindow then
            AddLog("Yama3: достигнут лимит роллов.")
            break
        end

        local ok, res = pcall(function()
            return remote:InvokeServer("Bones", "Buy", 1, 1)
        end)
        RollsUsed = RollsUsed + 1
        AddLog("Yama3: ролл #"..RollsUsed.." => "..tostring(res))

        UpdateHallowStatus()
        if HasHallow then
            AddLog("Yama3: Hallow Essence получена, останавливаю роллы.")
            break
        end

        task.wait(1.5)
    end
end

local function FarmBonesOnceYama3()
    if IsFightingBones then return end
    IsFightingBones = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then return end

        local target = GetNearestSkeleton(9999)
        if not target then
            UpdateStatus("Yama3: скелеты не найдены.")
            return
        end

        UpdateStatus("Yama3: фарм костей по "..target.Name)
        AddLog("Yama3: нашёл скелета "..target.Name)

        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if tHRP then
            SimpleTeleport(tHRP.CFrame * FarmOffset, "Yama3 скелет")
        end

        local fightDeadline = tick() + 40
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoYama3
            and AutoCDK
            and target.Parent
            and target:FindFirstChild("Humanoid")
            and target.Humanoid.Health > 0
            and tick() < fightDeadline do

            engaged = true

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and tHRP) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий скелет")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            pcall(function()
                tHRP.CanCollide = false
                target.Humanoid.WalkSpeed = 0
                target.Humanoid.JumpPower = 0
                if not tHRP:FindFirstChild("BodyVelocity") then
                    local bv = Instance.new("BodyVelocity", tHRP)
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Vector3.new(0,0,0)
                end
            end)

            AutoHaki()
            EquipToolByName(WeaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        if engaged then
            local hum = target:FindFirstChild("Humanoid")
            local dead = hum and hum.Health <= 0
            if dead or not target.Parent then
                AddLog("Yama3: скелет убит, кости начислены.")
                RefreshBonesCount()
            else
                AddLog("Yama3: бой со скелетом прерван.")
            end
        end
    end)

    if not ok then
        AddLog("Ошибка Yama3 FarmBonesOnce: "..tostring(err))
    end

    IsFightingBones = false
end

---------------------
-- HELL DIMENSION (Yama3): удержание E = 2 сек + мобы
---------------------
local function HoldEFor(seconds)
    AddLog("Зажимаю E на "..tostring(seconds).." сек.")
    VirtualInput:SendKeyEvent(true, "E", false, game)
    task.wait(seconds)
    VirtualInput:SendKeyEvent(false, "E", false, game)
end

local function IsHellMob(v)
    local n = tostring(v.Name)
    if string.find(n, "Cursed Skeleton") then return true end
    if string.find(n, "Hell's Messenger") then return true end
    return false
end

local function FarmHellMobsOnce()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end

    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 and IsHellMob(v) then
                local hum  = v.Humanoid
                local tHRP = v.HumanoidRootPart
                local deadline = tick() + 45
                AddLog("HellDimension: атакую моба "..tostring(v.Name))

                while AutoYama3
                    and AutoCDK
                    and hum.Health > 0
                    and v.Parent
                    and tick() < deadline do

                    local char = LocalPlayer.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if not (char and hrp and tHRP) then break end

                    local dist = (tHRP.Position - hrp.Position).Magnitude
                    if dist > 2000 then
                        SimpleTeleport(tHRP.CFrame * FarmOffset, "Hell mob (далеко)")
                    else
                        hrp.CFrame = tHRP.CFrame * FarmOffset
                        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                        hrp.CanCollide = false
                    end

                    pcall(function()
                        tHRP.CanCollide = false
                        hum.WalkSpeed   = 0
                        hum.JumpPower   = 0
                    end)

                    AutoHaki()
                    EquipToolByName(WeaponName)
                    AttackModule:AttackEnemyModel(v)

                    RunService.Heartbeat:Wait()
                end
            end
        end
    end
end

local function HandleHellDimensionYama3()
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local hd = map:FindFirstChild("HellDimension")
    if not hd then return end

    UpdateStatus("Yama3: HellDimension активен.")
    AddLog("Yama3: HellDimension обнаружен, выполняю факела и мобов.")

    local Torch1 = hd:FindFirstChild("Torch1")
    local Torch2 = hd:FindFirstChild("Torch2")
    local Torch3 = hd:FindFirstChild("Torch3")
    local Exit   = hd:FindFirstChild("Exit")

    if Torch1 then
        AddLog("Yama3 Hell: Torch1 -> E на 2 сек, затем мобы.")
        SimpleTeleport(Torch1.CFrame, "Hell Torch1")
        task.wait(0.3)
        HoldEFor(2)
        task.wait(0.3)
        FarmHellMobsOnce()
    end

    if Torch2 then
        AddLog("Yama3 Hell: Torch2 -> E на 2 сек, затем мобы.")
        SimpleTeleport(Torch2.CFrame, "Hell Torch2")
        task.wait(0.3)
        HoldEFor(2)
        task.wait(0.3)
        FarmHellMobsOnce()
    end

    if Torch3 then
        AddLog("Yama3 Hell: Torch3 -> E на 2 сек, затем мобы.")
        SimpleTeleport(Torch3.CFrame, "Hell Torch3")
        task.wait(0.3)
        HoldEFor(2)
        task.wait(0.3)
        FarmHellMobsOnce()
    end

    AddLog("Yama3 Hell: добиваю мобов/босса.")
    FarmHellMobsOnce()

    if Exit then
        AddLog("Yama3 Hell: телепорт к Exit.")
        SimpleTeleport(Exit.CFrame, "Hell Exit")
    else
        AddLog("Yama3 Hell: Exit не найден.")
    end
end

---------------------
-- SOUL REAPER -> HellDimension (Yama3): ждать 10 сек
---------------------
local function FindSoulReaper()
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, v in ipairs(enemies:GetChildren()) do
            if tostring(v.Name) == "Soul Reaper" then
                local hum = v:FindFirstChild("Humanoid")
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp then
                    return v, hum, hrp
                end
            end
        end
    end
    return nil
end

local function HandleSoulReaperPhaseYama3()
    local map = Workspace:FindFirstChild("Map")
    local hd  = map and map:FindFirstChild("HellDimension")
    if hd then
        return
    end

    local soul, sh, sHRP = FindSoulReaper()
    if not soul then
        AddLog("Yama3: Soul Reaper не найден, лечу к спавну.")
        SimpleTeleport(SoulReaperSpawnCF, "Soul Reaper spawn")
        return
    end

    UpdateStatus("Yama3: Soul Reaper найден, подлетаю и жду урона.")
    AddLog("Yama3: подлетаю к Soul Reaper, не атакую, жду HP <= 500, затем ещё 10 сек стою.")

    local prevNoclip = NoclipEnabled
    NoclipEnabled = false

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    sHRP       = soul:FindFirstChild("HumanoidRootPart")
    sh         = soul:FindFirstChild("Humanoid")

    if hrp and sHRP then
        hrp.CFrame = sHRP.CFrame * CFrame.new(0,0,-6)
    end

    local waitDeadline = tick() + 120

    while AutoYama3
        and AutoCDK
        and soul.Parent
        and sh
        and sh.Health > 0
        and tick() < waitDeadline do

        char = LocalPlayer.Character
        hrp  = char and char:FindFirstChild("HumanoidRootPart")
        sHRP = soul:FindFirstChild("HumanoidRootPart")
        sh   = soul:FindFirstChild("Humanoid")

        if not (char and hrp and sHRP and sh) then
            break
        end

        local mapNow = Workspace:FindFirstChild("Map")
        local hDimNow = mapNow and mapNow:FindFirstChild("HellDimension")
        if hDimNow then
            AddLog("Yama3: HellDimension уже появился, жду авто-переноса.")
            NoclipEnabled = prevNoclip
            return
        end

        local dist = (hrp.Position - sHRP.Position).Magnitude
        if dist > 120 then
            AddLog("Yama3: меня откинуло от Soul Reaper, подлетаю обратно.")
            hrp.CFrame = sHRP.CFrame * CFrame.new(0,0,-6)
        end

        local phum = char:FindFirstChild("Humanoid")
        if phum and phum.Health <= 500 then
            AddLog("Yama3: HP <= 500, стою 10 секунд и жду HellDimension.")
            UpdateStatus("Yama3: жду 10 секунд перед HellDimension.")

            local t0 = tick()
            local hellDetected = false

            while AutoYama3 and AutoCDK and tick() - t0 < 10 do
                local m  = Workspace:FindFirstChild("Map")
                local hD = m and m:FindFirstChild("HellDimension")
                if hD and not hellDetected then
                    hellDetected = true
                    AddLog("Yama3: HellDimension появился, но тп будет после полного таймера 10 сек.")
                end
                task.wait(0.1)
            end

            local m2  = Workspace:FindFirstChild("Map")
            local hDim2 = m2 and m2:FindFirstChild("HellDimension")
            if hDim2 then
                local torch1 = hDim2:FindFirstChild("Torch1")
                local exit   = hDim2:FindFirstChild("Exit")
                local fallbackCf
                if torch1 and torch1.CFrame then
                    fallbackCf = torch1.CFrame
                elseif exit and exit.CFrame then
                    fallbackCf = exit.CFrame
                elseif hDim2:IsA("Model") and hDim2.PrimaryPart then
                    fallbackCf = hDim2.PrimaryPart.CFrame
                end

                if fallbackCf then
                    AddLog("Yama3: 10 секунд прошли, HellDimension есть — телепорт внутрь.")
                    SimpleTeleport(fallbackCf, "HellDimension")
                else
                    AddLog("Yama3: HellDimension есть, но нет Torch1/Exit для тп.")
                end
            else
                AddLog("Yama3: 10 секунд прошло, HellDimension не появился.")
            end

            NoclipEnabled = prevNoclip
            return
        end

        RunService.Heartbeat:Wait()
    end

    NoclipEnabled = prevNoclip
end

local function HandleSummonerIfHasHallow()
    if not HasHallow then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local hc = map:FindFirstChild("Haunted Castle")
    if not hc then return end
    local summonerModel = hc:FindFirstChild("Summoner")
    if not summonerModel then return end
    local detection = summonerModel:FindFirstChild("Detection")
    if not detection then return end

    UpdateStatus("Yama3: есть Hallow Essence, лечу к Summoner.")
    SimpleTeleport(detection.CFrame, "Summoner Detection")
    task.wait(1.0)
end

local function YamaQuest3Tick()
    if not AutoYama3 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 3 then
        AutoYama3 = false
        UpdateStatus("Yama3: третий фрагмент получен, перехожу к Tushita.")
        return
    end

    if not EnsureOnHauntedIsland() then
        return
    end

    RefreshBonesCount()
    UpdateHallowStatus()
    RefreshRollWindow()

    local map = Workspace:FindFirstChild("Map")
    local hellDim = map and map:FindFirstChild("HellDimension")
    if hellDim then
        HandleHellDimensionYama3()
        return
    end

    local alucardCount = GetCountMaterials("Alucard Fragment") or 0
    if alucardCount >= 3 then
        UpdateStatus("Yama3: 3 фрагмента уже есть, просто фармлю кости.")
        FarmBonesOnceYama3()
        return
    end

    if HasHallow then
        HandleSummonerIfHasHallow()
        HandleSoulReaperPhaseYama3()
        return
    end

    local soul = FindSoulReaper()
    if soul then
        HandleSoulReaperPhaseYama3()
        return
    end

    if BonesCount >= MinBonesToRoll and RollsUsed < MaxRollsPerWindow then
        DoDeathKingRolls()
        return
    end

    UpdateStatus("Yama3: фарм скелетов для костей.")
    FarmBonesOnceYama3()
end

---------------------
-- TUSHITA QUEST 1 (BoatQuest через Lux Boat Dealer)
---------------------
local Tushita1Index = 1

local function FindNearestLuxuryBoatDealer(maxDist)
    maxDist = maxDist or 200
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, nearest = maxDist, nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Luxury Boat Dealer" then
            local head = obj:FindFirstChild("HumanoidRootPart")
                or obj:FindFirstChild("Head")
                or obj:FindFirstChildWhichIsA("BasePart")
            if head then
                local d = (head.Position - hrp.Position).Magnitude
                if d < best then
                    best    = d
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

local function TushitaQuest1Tick()
    if not AutoTushita1 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 4 then
        AutoTushita1 = false
        UpdateStatus("Tushita1: фрагмент получен, перехожу к Tushita2.")
        return
    end

    local idx = Tushita1Index
    Tushita1Index = Tushita1Index + 1
    if Tushita1Index > #TushitaQ1Points then
        Tushita1Index = 1
    end

    UpdateStatus("Tushita1: точка "..idx)
    SimpleTeleport(TushitaQ1Points[idx], "Tushita Q1 точка "..idx)

    local npc = FindNearestLuxuryBoatDealer(150)
    if not npc then
        AddLog("Tushita1: Luxury Boat Dealer не найден у точки "..idx)
        return
    end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local head = npc:FindFirstChild("HumanoidRootPart")
        or npc:FindFirstChild("Head")
        or npc:FindFirstChildWhichIsA("BasePart")

    if head then
        hrp.CFrame = head.CFrame * CFrame.new(0,0,-3)
    end

    local ok1, res1 = pcall(function()
        return remote:InvokeServer("GetUnlockables","BoatDealer")
    end)
    AddLog("Tushita1: GetUnlockables/BoatDealer => "..tostring(res1))

    task.wait(0.3)

    local ok2, res2 = pcall(function()
        return remote:InvokeServer("CDKQuest","BoatQuest", npc)
    end)
    AddLog("Tushita1: BoatQuest => "..tostring(res2))
end

---------------------
-- TUSHITA QUEST 2
---------------------
local Tushita2IsFighting = false

local function IsInTushita2Zone()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, 99999 end
    local dist = (hrp.Position - TushitaQ2Center.Position).Magnitude
    return dist <= TushitaQ2InZoneRadius, dist
end

local function GetNearestMobInTushita2Zone()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, nearest = TushitaQ2MaxMobDistance, nil
    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            local tHRP = v.HumanoidRootPart
            local distToPlayer = (tHRP.Position - hrp.Position).Magnitude
            local distToCenter = (tHRP.Position - TushitaQ2Center.Position).Magnitude
            if distToPlayer <= TushitaQ2MaxMobDistance and distToCenter <= TushitaQ2InZoneRadius + 200 then
                if distToPlayer < best then
                    best    = distToPlayer
                    nearest = v
                end
            end
        end
    end
    return nearest
end

local function TushitaQuest2Tick()
    if not AutoTushita2 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 5 then
        AutoTushita2 = false
        UpdateStatus("Tushita2: фрагмент получен, перехожу к Tushita3.")
        return
    end

    if Tushita2IsFighting then return end

    local inZone, dist = IsInTushita2Zone()
    if not inZone then
        UpdateStatus(string.format("Tushita2: лечу в зону (%.0f stud)", dist or 9999))
        SimpleTeleport(TushitaQ2Center * CFrame.new(0,5,0), "центр Tushita Q2")
        return
    end

    local target = GetNearestMobInTushita2Zone()
    if not target then
        UpdateStatus("Tushita2: враги не найдены, жду...")
        return
    end

    Tushita2IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        UpdateStatus("Tushita2: фарм "..target.Name)
        SimpleTeleport(tHRP.CFrame * FarmOffset, "моб Tushita Q2")

        local deadline      = tick() + 45
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoTushita2 and AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

            local distToMob = (tHRP.Position - hrp.Position).Magnitude
            if distToMob > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий моб Tushita Q2")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName(WeaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка TushitaQuest2Tick: "..tostring(err))
    end

    Tushita2IsFighting = false
end

---------------------
-- TUSHITA QUEST 3 (Cake Queen + HeavenlyDimension)
---------------------
local function HeavenlyDimensionFolder()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("HeavenlyDimension")
end

local function FindCakeQueen()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    for _, v in ipairs(enemies:GetChildren()) do
        if v.Name == "Cake Queen"
            and v:FindFirstChild("Humanoid")
            and v:FindFirstChild("HumanoidRootPart")
            and v.Humanoid.Health > 0 then
            return v
        end
    end
    return nil
end

local function FightMobSimple(target, label, offsetCF)
    offsetCF = offsetCF or FarmOffset
    if not target then return end

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not (char and hrp and hum and tHRP) then return end

        UpdateStatus(label or ("Бой: "..target.Name))
        SimpleTeleport(tHRP.CFrame * offsetCF, label or "цель")

        local deadline      = tick() + 90
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoTushita3 and AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and hum and tHRP) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * offsetCF, "далёкий моб")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * offsetCF
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName(WeaponName)
            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка FightMobSimple: "..tostring(err))
    end
end

local function TushitaQuest3Tick()
    if not AutoTushita3 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 6 then
        AutoTushita3 = false
        UpdateStatus("Tushita3: 6-й фрагмент получен. Готово.")
        AutoCDK = false
        NoclipEnabled = false
        StopTween = true
        if BtnCDK then
            BtnCDK.Text = "Auto CDK: OFF"
            BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
        end
        AddLog("Готово: 6 Alucard Fragment. Все квесты завершены.")
        return
    end

    local dim = HeavenlyDimensionFolder()
    if not dim then
        local boss = FindCakeQueen()
        if boss then
            -- после убийства Cake Queen просто ждём 5 сек, игра сама переносит в HeavenlyDimension
            FightMobSimple(boss, "Tushita3: Cake Queen", CakeQueenOffset)
            AddLog("Tushita3: жду 5 сек авто-переноса в HeavenlyDimension.")
            task.wait(5)
        else
            UpdateStatus("Tushita3: Cake Queen не найдена, лечу на остров.")
            SimpleTeleport(CakeQueenIsland, "остров Cake Queen")
        end
        return
    end

    local torch1 = dim:FindFirstChild("Torch1")
    local torch2 = dim:FindFirstChild("Torch2")
    local torch3 = dim:FindFirstChild("Torch3")
    local exit   = dim:FindFirstChild("Exit")

    -- Каждый факел: E на 2 сек, потом мобы, потом следующий
    if T3_HeavenlyStage == 0 and torch1 then
        UpdateStatus("Tushita3: Torch1.")
        SimpleTeleport(torch1.CFrame * CFrame.new(0,5,0), "Torch1")
        HoldEFor(2)
        FarmHellMobsOnce()
        T3_HeavenlyStage = 1
        return
    end

    if T3_HeavenlyStage == 1 and torch2 then
        UpdateStatus("Tushita3: Torch2.")
        SimpleTeleport(torch2.CFrame * CFrame.new(0,5,0), "Torch2")
        HoldEFor(2)
        FarmHellMobsOnce()
        T3_HeavenlyStage = 2
        return
    end

    if T3_HeavenlyStage == 2 and torch3 then
        UpdateStatus("Tushita3: Torch3.")
        SimpleTeleport(torch3.CFrame * CFrame.new(0,5,0), "Torch3")
        HoldEFor(2)
        FarmHellMobsOnce()
        T3_HeavenlyStage = 3
        return
    end

    if T3_HeavenlyStage == 3 then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, v in ipairs(enemies:GetChildren()) do
                if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                    FightMobSimple(v, "Tushita3: бой в HeavenlyDimension")
                end
            end
        end
        if exit then
            UpdateStatus("Tushita3: лечу к Exit.")
            SimpleTeleport(exit.CFrame * CFrame.new(0,5,0), "Exit")
            T3_HeavenlyStage = 4
        end
        return
    end

    if T3_HeavenlyStage >= 4 then
        UpdateStatus("Tushita3: жду завершения HeavenlyDimension.")
    end
end

---------------------
-- ПОМОЩЬ: стадия по AF
---------------------
local function GetStageFromAF(count)
    if count <= 0 then
        return 0
    elseif count == 1 then
        return 1
    elseif count == 2 then
        return 2
    elseif count == 3 then
        return 3
    elseif count == 4 then
        return 4
    elseif count == 5 then
        return 5
    else
        return 6
    end
end

local function DisableAllQuests()
    AutoYama1,AutoYama2,AutoYama3 = false,false,false
    AutoTushita1,AutoTushita2,AutoTushita3 = false,false,false
end

---------------------
-- ГЛАВНЫЙ ЦИКЛ AutoCDK (мастери -> квесты)
---------------------
spawn(function()
    while task.wait(1) do
        if not AutoCDK then
            CurrentStage = -1
        else
            if NeedMastery then
                -- просто обновляем мастери, стадий квестов не трогаем
                local yM = GetWeaponMastery(SwordYamaName)
                local tM = GetWeaponMastery(SwordTushitaName)
                UpdateMasteryLabel(yM, tM)
            else
                local af = GetCountMaterials("Alucard Fragment") or 0
                UpdateAFLabel(af)

                local stage = GetStageFromAF(af)
                if stage ~= CurrentStage then
                    CurrentStage = stage
                    AddLog("CDK: AF="..af.." -> стадия "..stage)
                    DisableAllQuests()
                    StopTween = true
                    task.wait(0.2)
                    StopTween = false

                    if stage == 0 then
                        UpdateStatus("Yama Quest 1")
                        AutoYama1 = true
                        AddLog("Перед Yama1: запускаю Trial Evil.")
                        CDKTrialModule.StartEvilTrial()

                    elseif stage == 1 then
                        UpdateStatus("Yama Quest 2")
                        AutoYama2 = true
                        AddLog("Перед Yama2: запускаю Trial Evil.")
                        CDKTrialModule.StartEvilTrial()

                    elseif stage == 2 then
                        UpdateStatus("Yama Quest 3")
                        AutoYama3 = true
                        AddLog("Перед Yama3: запускаю Trial Evil.")
                        CDKTrialModule.StartEvilTrial()

                    elseif stage == 3 then
                        UpdateStatus("Tushita Quest 1 (BoatQuest)")
                        AutoTushita1 = true
                        AddLog("Перед Tushita1: Trial Evil + Trial Good.")
                        CDKTrialModule.StartEvilTrial()
                        task.wait(0.3)
                        CDKTrialModule.StartGoodTrial()

                    elseif stage == 4 then
                        UpdateStatus("Tushita Quest 2")
                        AutoTushita2 = true
                        AddLog("Перед Tushita2: Trial Good.")
                        CDKTrialModule.StartGoodTrial()

                    elseif stage == 5 then
                        UpdateStatus("Tushita Quest 3")
                        AutoTushita3 = true
                        T3_HeavenlyStage = 0
                        AddLog("Перед Tushita3: Trial Good.")
                        CDKTrialModule.StartGoodTrial()

                    elseif stage == 6 then
                        UpdateStatus("Готово (6+ Alucard Fragment)")
                        AddLog("Все 6 фрагментов уже есть, выключаю AutoCDK.")
                        AutoCDK = false
                        NoclipEnabled = false
                        StopTween = true
                        if BtnCDK then
                            BtnCDK.Text = "Auto CDK: OFF"
                            BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
                        end
                    end
                end
            end
        end
    end
end)

---------------------
-- ТИКИ КВЕСТОВ / МАСТЕРИ
---------------------
spawn(function()
    while task.wait(0.4) do
        if AutoCDK then
            if NeedMastery then
                pcall(MasteryTick)
            else
                if AutoYama1    then pcall(YamaQuest1Tick)    end
                if AutoYama2    then pcall(YamaQuest2Tick)    end
                if AutoYama3    then pcall(YamaQuest3Tick)    end
                if AutoTushita1 then pcall(TushitaQuest1Tick) end
                if AutoTushita2 then pcall(TushitaQuest2Tick) end
                if AutoTushita3 then pcall(TushitaQuest3Tick) end
            end
        end
    end
end)

AddLog("AutoCDK загружен. Включай кнопку в 3-м море (Haunted Castle / Castle on the Sea / Cake Queen).")
