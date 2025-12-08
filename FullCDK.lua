--========================================================
--  AUTO CDK + TUSHITA (Yama 1/2/3 + Tushita 1/2/3)
--  Один GUI, одна кнопка "Auto CDK"
--========================================================

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
-- ГЛОБАЛЬНЫЕ НАСТРОЙКИ
---------------------
local TeleportSpeed = 300
local FarmOffset    = CFrame.new(0, 10, -3)

-- подправь при необходимости на центр Castle on the Sea
local CastleOnSeaCFrame = CFrame.new(-5074.7, 315.6, -3158.58)

-- Yama Quest2 (HazeESP зона, патруль взят из твоего скрипта)
local Yama2PatrolPoints = {
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
}

-- Haunted Castle / Death King
local HauntedFallback = CFrame.new(-9515.129, 142.233, 6200.441)

-- Tushita 1: точки Lux Boat Dealer
local TushitaQ1Points = {
    CFrame.new(-9546.990234375, 21.139892578125, 4686.1142578125),
    CFrame.new(-6120.0576171875, 16.455780029296875, -2250.697265625),
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875),
}

-- Tushita 2: центр зоны
local TushitaQ2Center = CFrame.new(-5539.3115, 313.8005, -2972.3723)
local TushitaQ2InZoneRadius   = 500
local TushitaQ2MaxMobDistance = 2000

-- Tushita 3: Cake Queen + HeavenlyDimension
local CakeQueenIsland   = CFrame.new(-709.3132934570312, 381.6005859375, -11011.396484375)
local CakeQueenOffset   = CFrame.new(0, 20, -3)

---------------------
-- ФЛАГИ / СОСТОЯНИЯ
---------------------
local AutoCDK        = false
local CurrentStage   = -1  -- -1 = не определено
local IsTeleporting  = false
local StopTween      = false
local NoclipEnabled  = false

-- отдельные квест-флаги (управляет только AutoCDK)
local AutoYama1   = false
local AutoYama2   = false
local AutoYama3   = false
local AutoTushita1 = false
local AutoTushita2 = false
local AutoTushita3 = false

---------------------
-- ЛОГИ / GUI
---------------------
local StatusLogs = {}
local MaxLogs    = 200

local ScreenGui, MainFrame, BtnCDK
local StatusLabel, AFLabel, LogsText

local function AddLog(msg)
    local timestamp = os.date("%H:%M:%S")
    local entry     = "[" .. timestamp .. "] " .. tostring(msg)
    table.insert(StatusLogs, 1, entry)
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
    if LogsText then
        LogsText.Text = table.concat(StatusLogs, "\n")
    end
    print(entry)
end

local function UpdateStatus(text)
    if StatusLabel then
        StatusLabel.Text = "Статус: " .. tostring(text)
    end
    AddLog("Статус: " .. tostring(text))
end

local function UpdateAFLabel(count)
    if AFLabel then
        AFLabel.Text = "Alucard Fragment: " .. tostring(count or 0)
    end
end

---------------------
-- GUI СОЗДАНИЕ
---------------------
local function CreateMainGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoCDKGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 520, 0, 320)
    MainFrame.Position = UDim2.new(0, 40, 0, 180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Title.Text = "Auto CDK + Tushita (1 кнопка)"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.Parent = MainFrame

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

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 190)
    LogsFrame.Position = UDim2.new(0, 10, 0, 120)
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
            UpdateStatus("Auto CDK включен.")
            AddLog("Алгоритм CDK/Tushita запущен.")
        else
            BtnCDK.Text = "Auto CDK: OFF"
            BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled = false
            StopTween = true
            UpdateStatus("Остановлен")
            AddLog("Auto CDK выключен. Все авто-квесты остановлены.")
            AutoYama1, AutoYama2, AutoYama3 = false, false, false
            AutoTushita1, AutoTushita2, AutoTushita3 = false, false, false
        end
    end)

    AddLog("GUI Auto CDK загружен.")
end

CreateMainGui()

---------------------
-- ANTI AFK
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
local RegisterAttack = net:WaitForChild("RE"):WaitForChild("RegisterAttack")
local RegisterHit    = net:WaitForChild("RE"):WaitForChild("RegisterHit")

local AttackModule = {}

function AttackModule.AttackEnemyModel(enemyModel)
    if not enemyModel then return end
    local hrp = enemyModel:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hitTable = {
        {enemyModel, hrp}
    }

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

    local p = LocalPlayer
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
        AddLog("⚔️ Экипирован: " .. toolFound.Name)
    else
        if tick() - lastEquipFailLog > 3 then
            AddLog("⚠️ Не найдено оружие: " .. name)
            lastEquipFailLog = tick()
        end
    end
end

---------------------
-- ИНВЕНТАРЬ / МАТЕРИАЛЫ
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

    local ok, invData = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if ok and type(invData) == "table" then
        for _, item in ipairs(invData) do
            local name = item.Name or item.name or tostring(item)
            if name == itemName then
                return true
            end
        end
    end

    return false
end

local function GetCountMaterials(MaterialName)
    local ok, Inventory = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if ok and type(Inventory) == "table" then
        for _, v in pairs(Inventory) do
            if v.Name == MaterialName then
                return v.Count or v.count or 0
            end
        end
    end
    return 0
end

---------------------
-- ТЕЛЕПОРТ
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
    if travelTime < 0.5 then travelTime = 0.5 end
    if travelTime > 60  then travelTime = 60  end

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
-- CDKTrialModule (Evil / Good)
---------------------
local CDKTrialModule = {}

function CDKTrialModule.StartEvilTrial(logFunc)
    local function Log(msg)
        if logFunc then logFunc("[CDKTrial Evil] "..tostring(msg))
        else print("[CDKTrial Evil] "..tostring(msg)) end
    end

    Log("Проверяю Progress 'Evil'...")
    local okP, progress = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Evil")
    end)
    if okP then
        Log("Progress(Evil) = "..tostring(progress))
    else
        Log("Ошибка Progress(Evil): "..tostring(progress))
    end

    task.wait(0.2)

    Log("Отправляю StartTrial 'Evil'...")
    local okS, resS = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Evil")
    end)
    if okS then
        Log("✅ StartTrial(Evil) => "..tostring(resS))
    else
        Log("❌ Ошибка StartTrial(Evil): "..tostring(resS))
    end
end

function CDKTrialModule.StartGoodTrial(logFunc)
    local function Log(msg)
        if logFunc then logFunc("[CDKTrial Good] "..tostring(msg))
        else print("[CDKTrial Good] "..tostring(msg)) end
    end

    Log("Проверяю Progress 'Good'...")
    local okP, progress = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Good")
    end)
    if okP then
        Log("Progress(Good) = "..tostring(progress))
    else
        Log("Ошибка Progress(Good): "..tostring(progress))
    end

    task.wait(0.2)

    Log("Отправляю StartTrial 'Good'...")
    local okS, resS = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Good")
    end)
    if okS then
        Log("✅ StartTrial(Good) => "..tostring(resS))
    else
        Log("❌ Ошибка StartTrial(Good): "..tostring(resS))
    end
end

---------------------
-- YAMA QUEST 1
-- Стоим на Castle on the Sea с Yama в руках,
-- умираем, ресаемся и снова летим на остров,
-- пока Alucard Fragment < 1
---------------------
local function YamaQuest1Tick()
    if not AutoYama1 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 1 then
        AutoYama1 = false
        UpdateStatus("Yama1: Alucard Fragment получен, перехожу к следующей стадии.")
        return
    end

    EquipToolByName("Yama")

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and hrp and hum) then return end

    if hum.Health <= 0 then
        -- просто ждём респаун CharacterAdded
        return
    end

    local dist = (hrp.Position - CastleOnSeaCFrame.Position).Magnitude
    if dist > 150 then
        UpdateStatus("Yama1: лечу к Castle on the Sea, жду смерти.")
        SimpleTeleport(CastleOnSeaCFrame, "Castle on the Sea")
    else
        UpdateStatus("Yama1: жду, пока мобы/игра меня убьют.")
    end
end

---------------------
-- YAMA QUEST 2 (HazeESP)
---------------------
local Yama2PatrolIndex   = 1
local Yama2PatrolHold    = 0
local Yama2LastPatrolHop = 0
local Yama2IsFighting    = false

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
                    best = d
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
    AddLog("Yama2: патруль к точке #" .. tostring(idx))
    SimpleTeleport(targetCF, "Yama2 патруль #" .. tostring(idx))
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
        UpdateStatus("Yama2: Haze-мобы не найдены, патрулирую карту.")
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

        UpdateStatus("Yama2: фарм Haze-моба " .. target.Name)
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

            pcall(function()
                tHRP.CanCollide = false
                hum.WalkSpeed   = 0
                hum.JumpPower   = 0
                if not tHRP:FindFirstChild("BodyVelocity") then
                    local bv = Instance.new("BodyVelocity", tHRP)
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Vector3.new(0,0,0)
                end
            end)

            AutoHaki()
            EquipToolByName("Yama")

            if tick() - lastAttack > 0.15 then
                AttackModule.AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        AddLog("Yama2: бой с Haze-мобом завершён (моб мёртв или прерван).")
    end)

    if not ok then
        AddLog("Ошибка YamaQuest2Tick: " .. tostring(err))
    end

    Yama2IsFighting = false
end

---------------------
-- YAMA QUEST 3 (Bones + Hallow + HellDimension)
-- Упрощённая версия на базе твоего большого скрипта.
---------------------
local AutoYama3_HasHallow = false

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

local function RefreshHallowStatus()
    AutoYama3_HasHallow = HasItemInInventory("Hallow Essence")
end

local function EnsureOnHauntedIsland()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return false end

    local center = GetHauntedCenterCFrame()
    local dist   = (hrp.Position - center.Position).Magnitude
    if dist > 600 then
        UpdateStatus("Yama3: лечу к Haunted Castle / Death King.")
        SimpleTeleport(center * CFrame.new(0,4,3), "Death King")
        task.wait(1)
        return false
    end
    return true
end

local function IsBoneMob(mob)
    local n = tostring(mob.Name)
    if string.find(n, "Skeleton") then return true end
    if string.find(n, "Reborn Skeleton") then return true end
    if string.find(n, "Living Skeleton") then return true end
    return false
end

local function GetNearestBoneMob(maxDistance)
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
            if IsBoneMob(v) then
                local distFromCenter = (v.HumanoidRootPart.Position - center.Position).Magnitude
                if distFromCenter < 800 then
                    local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < best then
                        best = d
                        nearest = v
                    end
                end
            end
        end
    end
    return nearest
end

local function FarmBonesOnce()
    local target = GetNearestBoneMob(9999)
    if not target then
        UpdateStatus("Yama3: скелеты возле Haunted Castle не найдены.")
        return
    end

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        UpdateStatus("Yama3: фарм костей (" .. target.Name .. ")")
        SimpleTeleport(tHRP.CFrame * FarmOffset, "скелет")

        local deadline      = tick() + 40
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoYama3 and AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

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

            AutoHaki()
            EquipToolByName("Godhuman")

            if tick() - lastAttack > 0.15 then
                AttackModule.AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка FarmBonesOnce: " .. tostring(err))
    end
end

-- HellDimension + Soul Reaper логика сильно упрощена:
-- будем считать, что она уже реализована в твоём оффлайн-коде.
-- Здесь только каркас: если HellDimension существует -> телепорт и фарм мобов.
local function HandleHellDimensionSimple()
    local map = Workspace:FindFirstChild("Map")
    local hd  = map and map:FindFirstChild("HellDimension")
    if not hd then return end

    UpdateStatus("Yama3: HellDimension активен (упрощённая логика).")
    local torch1 = hd:FindFirstChild("Torch1") or hd:FindFirstChild("Exit")
    if torch1 then
        SimpleTeleport(torch1.CFrame, "HellDimension")
    end
end

local function YamaQuest3Tick()
    if not AutoYama3 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 3 then
        AutoYama3 = false
        UpdateStatus("Yama3: третий фрагмент получен, дальше Tushita.")
        return
    end

    if not EnsureOnHauntedIsland() then
        return
    end

    HandleHellDimensionSimple()

    RefreshHallowStatus()

    -- если нет HellDimension и нет Hallow Essence -> фарм костей
    FarmBonesOnce()
end

---------------------
-- TUSHITA QUEST 1 (BoatQuest через Lux Boat Dealer)
---------------------
local Tushita1CurrentIndex = 1

local function FindNearestLuxuryBoatDealer(maxDist)
    maxDist = maxDist or 200
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, nearest = maxDist, nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Luxury Boat Dealer" then
            local head = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj:FindFirstChildWhichIsA("BasePart")
            if head then
                local d = (head.Position - hrp.Position).Magnitude
                if d < best then
                    best = d
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

    local idx = Tushita1CurrentIndex
    Tushita1CurrentIndex = Tushita1CurrentIndex + 1
    if Tushita1CurrentIndex > #TushitaQ1Points then
        Tushita1CurrentIndex = 1
    end

    UpdateStatus("Tushita1: точка " .. idx)
    SimpleTeleport(TushitaQ1Points[idx], "Tushita Q1 точка " .. idx)

    local npc = FindNearestLuxuryBoatDealer(150)
    if not npc then
        AddLog("Tushita1: Luxury Boat Dealer не найден около точки " .. idx)
        return
    end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local head = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head") or npc:FindFirstChildWhichIsA("BasePart")
    if head then
        hrp.CFrame = head.CFrame * CFrame.new(0, 0, -3)
    end

    local ok1, res1 = pcall(function()
        return remote:InvokeServer("GetUnlockables", "BoatDealer")
    end)
    if ok1 then
        AddLog("Tushita1: GetUnlockables/BoatDealer => " .. tostring(res1))
    else
        AddLog("Tushita1: ошибка GetUnlockables/BoatDealer: " .. tostring(res1))
    end

    task.wait(0.3)

    local ok2, res2 = pcall(function()
        return remote:InvokeServer("CDKQuest", "BoatQuest", npc)
    end)
    if ok2 then
        AddLog("Tushita1: BoatQuest для NPC => " .. tostring(res2))
    else
        AddLog("Tushita1: ошибка BoatQuest => " .. tostring(res2))
    end
end

---------------------
-- TUSHITA QUEST 2 (фарм в зоне)
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

        UpdateStatus("Tushita2: фарм " .. target.Name)
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
            EquipToolByName("Godhuman")

            if tick() - lastAttack > 0.15 then
                AttackModule.AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка TushitaQuest2Tick: " .. tostring(err))
    end

    Tushita2IsFighting = false
end

---------------------
-- TUSHITA QUEST 3 (Cake Queen + HeavenlyDimension, упрощённо)
---------------------
local T3_HeavenlyStage = 0  -- 0->Torch1, 1->Torch2, 2->Torch3, 3->Exit

local function HeavenlyDimensionFolder()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("HeavenlyDimension")
end

local function FindCakeQueen()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    for _, v in ipairs(enemies:GetChildren()) do
        if v.Name == "Cake Queen" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
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

        UpdateStatus(label or ("Бой: " .. target.Name))
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
            EquipToolByName("Godhuman")
            if tick() - lastAttack > 0.15 then
                AttackModule.AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка FightMobSimple: " .. tostring(err))
    end
end

local function HoldEFor(seconds)
    AddLog("Зажимаю E на " .. tostring(seconds) .. " сек.")
    VirtualInput:SendKeyEvent(true, "E", false, game)
    task.wait(seconds)
    VirtualInput:SendKeyEvent(false, "E", false, game)
end

local function TushitaQuest3Tick()
    if not AutoTushita3 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 6 then
        AutoTushita3 = false
        UpdateStatus("Tushita3: получен 6-й фрагмент. Готово.")
        AutoCDK = false
        NoclipEnabled = false
        StopTween = true
        if BtnCDK then
            BtnCDK.Text = "Auto CDK: OFF"
            BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
        end
        AddLog("Готово: CDK + Tushita полностью завершены (6 Alucard Fragment).")
        return
    end

    local dim = HeavenlyDimensionFolder()
    if not dim then
        -- фазы Cake Queen до спавна измерения
        local boss = FindCakeQueen()
        if boss then
            FightMobSimple(boss, "Tushita3: Cake Queen", CakeQueenOffset)
        else
            UpdateStatus("Tushita3: Cake Queen не найдена, лечу на остров.")
            SimpleTeleport(CakeQueenIsland, "остров Cake Queen")
        end
        return
    end

    -- Внутри HeavenlyDimension (упрощённый вариант Torch1-3 + Exit)
    local torch1 = dim:FindFirstChild("Torch1")
    local torch2 = dim:FindFirstChild("Torch2")
    local torch3 = dim:FindFirstChild("Torch3")
    local exit   = dim:FindFirstChild("Exit")

    if T3_HeavenlyStage == 0 and torch1 then
        UpdateStatus("Tushita3: Torch1.")
        SimpleTeleport(torch1.CFrame * CFrame.new(0,5,0), "Torch1")
        HoldEFor(2)
        T3_HeavenlyStage = 1
        return
    end

    if T3_HeavenlyStage == 1 and torch2 then
        UpdateStatus("Tushita3: Torch2.")
        SimpleTeleport(torch2.CFrame * CFrame.new(0,5,0), "Torch2")
        HoldEFor(2)
        T3_HeavenlyStage = 2
        return
    end

    if T3_HeavenlyStage == 2 and torch3 then
        UpdateStatus("Tushita3: Torch3.")
        SimpleTeleport(torch3.CFrame * CFrame.new(0,5,0), "Torch3")
        HoldEFor(2)
        T3_HeavenlyStage = 3
        return
    end

    if T3_HeavenlyStage == 3 then
        -- добиваем любых мобов (Cursed Skeleton / Heaven's Guardian)
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
        UpdateStatus("Tushita3: жду завершения квеста/выхода.")
    end
end

---------------------
-- ВСПОМОГАТЕЛЬНОЕ: СТАДИЯ ПО КОЛ-ВУ ФРАГМЕНТОВ
---------------------
local function GetStageFromAlucardCount(count)
    if count <= 0 then
        return 0 -- Yama1
    elseif count == 1 then
        return 1 -- Yama2
    elseif count == 2 then
        return 2 -- Yama3
    elseif count == 3 then
        return 3 -- Tushita1
    elseif count == 4 then
        return 4 -- Tushita2
    elseif count == 5 then
        return 5 -- Tushita3
    else
        return 6 -- Готово
    end
end

local function DisableAllQuests()
    AutoYama1, AutoYama2, AutoYama3 = false, false, false
    AutoTushita1, AutoTushita2, AutoTushita3 = false, false, false
end

---------------------
-- ГЛАВНЫЙ ЦИКЛ AUTO CDK
---------------------
spawn(function()
    while task.wait(1) do
        if not AutoCDK then
            CurrentStage = -1
        else
            local af = GetCountMaterials("Alucard Fragment") or 0
            UpdateAFLabel(af)

            local stage = GetStageFromAlucardCount(af)
            if stage ~= CurrentStage then
                CurrentStage = stage
                AddLog("CDK: Alucard Fragment = " .. tostring(af) .. " → стадия " .. tostring(stage))
                DisableAllQuests()
                StopTween = true
                task.wait(0.2)
                StopTween = false

                if stage == 0 then
                    UpdateStatus("Yama Quest 1 (Castle on the Sea, смерть)")
                    AutoYama1 = true
                    CDKTrialModule.StartEvilTrial(AddLog)
                elseif stage == 1 then
                    UpdateStatus("Yama Quest 2 (HazeESP)")
                    AutoYama2 = true
                    CDKTrialModule.StartEvilTrial(AddLog)
                elseif stage == 2 then
                    UpdateStatus("Yama Quest 3 (Bones / Hallow / HellDimension)")
                    AutoYama3 = true
                    CDKTrialModule.StartEvilTrial(AddLog)
                elseif stage == 3 then
                    UpdateStatus("Tushita Quest 1 (BoatQuest)")
                    AutoTushita1 = true
                    AddLog("Перед Tushita Q1: запускаю Evil trial один раз.")
                    CDKTrialModule.StartEvilTrial(AddLog)
                    task.wait(0.3)
                    AddLog("Перед Tushita Q1: запускаю Good trial.")
                    CDKTrialModule.StartGoodTrial(AddLog)
                elseif stage == 4 then
                    UpdateStatus("Tushita Quest 2 (зона фарма)")
                    AutoTushita2 = true
                    AddLog("Перед Tushita Q2: запускаю Good trial.")
                    CDKTrialModule.StartGoodTrial(AddLog)
                elseif stage == 5 then
                    UpdateStatus("Tushita Quest 3 (Cake Queen + HeavenlyDimension)")
                    AutoTushita3 = true
                    T3_HeavenlyStage = 0
                    AddLog("Перед Tushita Q3: запускаю Good trial.")
                    CDKTrialModule.StartGoodTrial(AddLog)
                elseif stage == 6 then
                    UpdateStatus("Готово: 6+ Alucard Fragment.")
                    AddLog("CDK + Tushita: все 6 фрагментов есть, выключаю Auto CDK.")
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
end)

---------------------
-- ЦИКЛИЧЕСКИЕ ВЫЗОВЫ КВЕСТОВ
---------------------
spawn(function()
    while task.wait(0.4) do
        if AutoYama1 then pcall(YamaQuest1Tick) end
        if AutoYama2 then pcall(YamaQuest2Tick) end
        if AutoYama3 then pcall(YamaQuest3Tick) end
        if AutoTushita1 then pcall(TushitaQuest1Tick) end
        if AutoTushita2 then pcall(TushitaQuest2Tick) end
        if AutoTushita3 then pcall(TushitaQuest3Tick) end
    end
end)
