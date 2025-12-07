--========================================================
-- Auto Evil Trial + Yama Quest 2 (с автозапуском триала перед 2-м квестом)
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

local LocalPlayer = Players.LocalPlayer
local remote      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- МОДУЛЬ CDKTrial (StartTrial Evil)
---------------------
local CDKTrialModule = {}

function CDKTrialModule.StartEvilTrial(logFunc)
    local function Log(msg)
        if logFunc then
            logFunc("[CDKTrial] " .. tostring(msg))
        else
            print("[CDKTrial] " .. tostring(msg))
        end
    end

    Log("Проверяю прогресс триала Evil...")
    local okProgress, progress = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Evil")
    end)

    if okProgress then
        Log("CDKQuest Progress(Evil) = " .. tostring(progress))
    else
        Log("Ошибка Progress(Evil): " .. tostring(progress))
    end

    task.wait(0.3)

    Log("Пробую запустить StartTrial(Evil)...")
    local okStart, resStart = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Evil")
    end)

    if okStart then
        Log("✅ StartTrial(Evil) отправлен. Ответ: " .. tostring(resStart))
    else
        Log("❌ Ошибка StartTrial(Evil): " .. tostring(resStart))
    end
end

---------------------
-- ФЛАГИ / СОСТОЯНИЕ
---------------------
local AutoYamaSystem = false
local CurrentStatus  = "Idle"

local IsTeleporting  = false
local StopTween      = false
local NoclipEnabled  = false

local lastStartTry     = 0          -- антиспам для фазы 0 фрагментов
local StartTryCooldown = 30

local lastTPLog           = ""
local HaveAlucardFragment = false
local CurrentMode         = "None"   -- "Evil", "Yama2", "Done"

---------------------
-- НАСТРОЙКИ
---------------------
local TeleportSpeed     = 300
local CastleOnSeaCFrame = CFrame.new(-5418.892578125, 313.74130249023, -2826.2260742188)

-- настройки Yama Quest 2
local SwordName   = "Yama"
local FarmOffset  = CFrame.new(0, 10, -3)
local PatrolPoints = {
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

local patrolIndex      = 1
local lastPatrol       = 0
local PatrolHoldUntil  = 0

local HazeKillCount    = 0

---------------------
-- NET-АТАКИ
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

    local hitTable = {
        {enemyModel, hrp}
    }

    RegisterAttack:FireServer(0)
    RegisterAttack:FireServer(1)
    RegisterHit:FireServer(hrp, hitTable)
end

---------------------
-- ЛОГИ / GUI
---------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame
local ToggleButton
local StatusLabel
local UptimeLabel
local KillsLabel
local LogsText

local StartTime = os.time()

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
end

local function UpdateStatus(text)
    if text ~= CurrentStatus then
        CurrentStatus = text
        if StatusLabel then
            StatusLabel.Text = "Статус: " .. tostring(text)
        end
        AddLog("Статус: " .. tostring(text))
    else
        CurrentStatus = text
        if StatusLabel then
            StatusLabel.Text = "Статус: " .. tostring(text)
        end
    end
end

local function GetUptime()
    local t = os.time() - StartTime
    local h = math.floor(t / 3600)
    local m = math.floor((t % 3600) / 60)
    local s = t % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function UpdateKillsLabel()
    if KillsLabel then
        KillsLabel.Text = "Убито HazeESP мобов (Yama2): " .. tostring(HazeKillCount)
    end
end

---------------------
-- ANTI AFK
---------------------
spawn(function()
    while task.wait(60) do
        if AutoYamaSystem then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            AddLog("Anti-AFK: фейковый клик, чтобы не кикнуло.")
        end
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
-- ИНВЕНТАРЬ / Alucard / Yama
---------------------
local function GetInventory()
    local ok, invData = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if ok and type(invData) == "table" then
        return invData
    end
    return {}
end

local function HasAlucardFragment()
    local inv = GetInventory()
    for _, item in ipairs(inv) do
        if item.Name == "Alucard Fragment" then
            local count = item.Count or item.count or 0
            if count > 0 then
                return true, count
            end
        end
    end
    return false, 0
end

local function IsToolEquipped(name)
    local char = LocalPlayer.Character
    if not char then return false end
    local lower = string.lower(name)
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and string.lower(obj.Name) == lower then
            return true
        end
    end
    return false
end

local lastEquipFailLog = 0

local function EquipToolByName(name)
    if IsToolEquipped(name) then
        return
    end

    local p = LocalPlayer
    if not p then return end

    local char = p.Character or p.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local lower = string.lower(name)
    local toolFound

    local function findToolIn(container)
        if not container then return nil end
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Tool") and string.lower(obj.Name) == lower then
                return obj
            end
        end
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("Tool") and string.lower(obj.Name) == lower then
                return obj
            end
        end
        return nil
    end

    local backpack = p:FindFirstChild("Backpack")
    if backpack then
        toolFound = findToolIn(backpack)
    end
    if not toolFound then
        toolFound = findToolIn(char)
    end

    if toolFound then
        hum:UnequipTools()
        hum:EquipTool(toolFound)
        AddLog("⚔️ Экипирован: " .. toolFound.Name)
    else
        if tick() - lastEquipFailLog > 5 then
            AddLog("⚠️ Не удалось найти оружие: " .. name)
            lastEquipFailLog = tick()
        end
    end
end

local function BringYamaToBackpack()
    local p = LocalPlayer
    if not p then return end

    if (p.Backpack and p.Backpack:FindFirstChild("Yama"))
        or (p.Character and p.Character:FindFirstChild("Yama")) then
        return
    end

    local inv = GetInventory()
    for _, item in ipairs(inv) do
        if item.Name == "Yama" then
            pcall(function()
                remote:InvokeServer("LoadItem", "Yama")
            end)
            AddLog("Пробую загрузить Yama из инвентаря (LoadItem).")
            break
        end
    end
end

local function EquipYama()
    BringYamaToBackpack()
    EquipToolByName("Yama")
end

---------------------
-- ХАКИ
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
    local logMsg   = string.format("Телепорт к %s (%.0f stud)", label or "цели", distance)

    if logMsg ~= lastTPLog then
        AddLog(logMsg)
        lastTPLog = logMsg
    end

    local travelTime = distance / TeleportSpeed
    if travelTime < 0.5 then travelTime = 0.5 end
    if travelTime > 60  then travelTime = 60  end

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()

    local start = tick()
    while tick() - start < travelTime do
        if StopTween then
            tween:Cancel()
            IsTeleporting = false
            AddLog("Телепорт прерван (StopTween).")
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
    AddLog("Персонаж возрождён, жду HRP...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, продолжу работу скрипта.")
end)

---------------------
-- Evil Trial PHASE (0 фрагментов)
---------------------
local function RunEvilTrialPhase()
    UpdateStatus("Evil Trial: жду смерть с Yama на Castle on the Sea (0 фрагментов).")

    local now = tick()
    if now - lastStartTry >= StartTryCooldown then
        lastStartTry = now
        CDKTrialModule.StartEvilTrial(AddLog)
    end

    EquipYama()

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then
        AddLog("Жду появления персонажа...")
        return
    end

    local dist = (hrp.Position - CastleOnSeaCFrame.Position).Magnitude
    if dist > 300 then
        SimpleTeleport(CastleOnSeaCFrame, "Castle on the Sea")
    end
end

---------------------
-- HazeESP поиск
---------------------
local function GetNearestHazeEnemy(maxDistance)
    maxDistance = maxDistance or 9999
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not enemiesFolder or not hrp then
        return nil
    end

    local nearest
    local bestDist = maxDistance

    for _, v in ipairs(enemiesFolder:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if v:FindFirstChild("HazeESP") then
                local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    nearest = v
                end
            end
        end
    end

    return nearest
end

---------------------
-- Патруль
---------------------
local function PatrolStep()
    if not (AutoYamaSystem and CurrentMode == "Yama2") then return end
    if #PatrolPoints == 0 then return end
    if IsTeleporting then return end

    if tick() < PatrolHoldUntil then
        return
    end

    if tick() - lastPatrol < 2 then
        return
    end

    local idx = patrolIndex
    patrolIndex = patrolIndex + 1
    if patrolIndex > #PatrolPoints then
        patrolIndex = 1
    end
    lastPatrol = tick()

    local targetCF = PatrolPoints[idx] * FarmOffset
    AddLog("Yama2 патруль: лечу на точку #" .. tostring(idx))
    UpdateStatus("Yama2: патруль, поиск Haze-мобов (точка "..tostring(idx)..")")

    SimpleTeleport(targetCF, "патруль Yama2 #" .. tostring(idx))

    PatrolHoldUntil = tick() + 5
    AddLog("Yama2: жду спавна мобов ~5 секунд на точке #" .. tostring(idx))
end

---------------------
-- Бой Yama Quest 2
---------------------
local IsFarming = false

local function FarmYamaQuest2Once()
    if not (AutoYamaSystem and CurrentMode == "Yama2") then return end
    if IsFarming then return end
    IsFarming = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then
            return
        end

        local target = GetNearestHazeEnemy(9999)
        if not target then
            PatrolStep()
            return
        end

        StopTween = true
        task.wait(0.1)
        IsTeleporting = false

        AddLog("Yama2: нашёл моба с HazeESP: " .. tostring(target.Name))
        UpdateStatus("Yama2: бой с " .. tostring(target.Name))

        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if tHRP then
            SimpleTeleport(tHRP.CFrame * FarmOffset, "старт боя с Haze-мобом")
        end

        local fightDeadline = tick() + 35
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoYamaSystem
            and CurrentMode == "Yama2"
            and target.Parent
            and target:FindFirstChild("Humanoid")
            and target.Humanoid.Health > 0
            and tick() < fightDeadline do

            engaged = true

            char = LocalPlayer.Character
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and tHRP) then
                break
            end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий моб Yama2")
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

                tHRP.Transparency = 0
                for _, part in ipairs(target:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = 0
                    end
                end
            end)

            AutoHaki()
            EquipToolByName(SwordName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        if engaged then
            local humanoidOk, hum = pcall(function()
                return target:FindFirstChild("Humanoid")
            end)

            local hazeStillThere = target:FindFirstChild("HazeESP") ~= nil
            local dead = false

            if humanoidOk and hum then
                dead = (hum.Health <= 0)
            end

            if (not target.Parent) or dead or (not hazeStillThere) then
                HazeKillCount = HazeKillCount + 1
                UpdateKillsLabel()
                AddLog("✅ Yama2: засчитан HazeESP моб. Всего: " .. tostring(HazeKillCount))
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в FarmYamaQuest2Once: " .. tostring(err))
    end

    IsFarming = false
end

---------------------
-- HazeESP твик
---------------------
spawn(function()
    while task.wait(0.2) do
        if AutoYamaSystem and CurrentMode == "Yama2" then
            pcall(function()
                local enemiesFolder = Workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    for _, v in ipairs(enemiesFolder:GetChildren()) do
                        if v:FindFirstChild("HazeESP") then
                            v.HazeESP.Size        = UDim2.new(50, 50, 50, 50)
                            v.HazeESP.MaxDistance = "inf"
                        end
                    end
                end
            end)
        end
    end
end)

---------------------
-- ОСНОВНОЙ ЦИКЛ ФАЗ (здесь ДОБАВЛЕН вызов триала перед Yama2)
---------------------
spawn(function()
    while task.wait(0.3) do
        local ok, err = pcall(function()
            if not AutoYamaSystem then
                CurrentMode = "None"
                return
            end

            local hasFrag, count = HasAlucardFragment()

            if hasFrag and count >= 2 then
                if not HaveAlucardFragment or CurrentMode ~= "Done" then
                    HaveAlucardFragment = true
                    CurrentMode = "Done"
                    UpdateStatus("Alucard Fragment >= 2. Всё готово, скрипт ничего больше не делает.")
                    AddLog("🎉 Обнаружено " .. tostring(count) .. " Alucard Fragment. Остановка активных действий.")
                end
                return
            end

            if not hasFrag or count == 0 then
                CurrentMode = "Evil"
                HaveAlucardFragment = false
                RunEvilTrialPhase()
            elseif count == 1 then
                -- ПЕРЕД ВТОРЫМ КВЕСТОМ: ещё раз запускаем StartTrial(Evil), как в первом квесте
                if CurrentMode ~= "Yama2" then
                    AddLog("Есть ровно 1 Alucard Fragment — вызываю триал перед Yama Quest 2.")
                    CDKTrialModule.StartEvilTrial(AddLog)
                    task.wait(1)
                end

                CurrentMode = "Yama2"
                HaveAlucardFragment = true
                UpdateStatus("Yama Quest 2: фарм HazeESP (1 Alucard Fragment).")
                FarmYamaQuest2Once()
            end
        end)

        if not ok then
            AddLog("Ошибка в основном фазовом цикле: " .. tostring(err))
        end
    end
end)

---------------------
-- GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoEvilTrialYama2Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 430, 0, 260)
    MainFrame.Position = UDim2.new(0, 40, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Title.Text = "Auto Evil Trial + Yama Quest 2"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 16
    Title.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 260, 0, 32)
    ToggleButton.Position = UDim2.new(0, 10, 0, 30)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Auto Evil Trial + Yama2: OFF"
    ToggleButton.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 20)
    StatusLabel.Position = UDim2.new(0, 10, 0, 65)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: " .. CurrentStatus
    StatusLabel.Parent = MainFrame

    UptimeLabel = Instance.new("TextLabel")
    UptimeLabel.Size = UDim2.new(1, -20, 0, 20)
    UptimeLabel.Position = UDim2.new(0, 10, 0, 85)
    UptimeLabel.BackgroundTransparency = 1
    UptimeLabel.TextColor3 = Color3.new(1,1,1)
    UptimeLabel.Font = Enum.Font.SourceSans
    UptimeLabel.TextSize = 14
    UptimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    UptimeLabel.Text = "Время работы: 00:00:00"
    UptimeLabel.Parent = MainFrame

    KillsLabel = Instance.new("TextLabel")
    KillsLabel.Size = UDim2.new(1, -20, 0, 20)
    KillsLabel.Position = UDim2.new(0, 10, 0, 105)
    KillsLabel.BackgroundTransparency = 1
    KillsLabel.TextColor3 = Color3.new(1,1,1)
    KillsLabel.Font = Enum.Font.SourceSans
    KillsLabel.TextSize = 14
    KillsLabel.TextXAlignment = Enum.TextXAlignment.Left
    KillsLabel.Text = "Убито HazeESP мобов (Yama2): 0"
    KillsLabel.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 130)
    LogsFrame.Position = UDim2.new(0, 10, 0, 125)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
    LogsFrame.BorderSizePixel = 0
    LogsFrame.Parent = MainFrame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -4)
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 5, 0)
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

    ToggleButton.MouseButton1Click:Connect(function()
        AutoYamaSystem = not AutoYamaSystem
        if AutoYamaSystem then
            StartTime     = os.time()
            NoclipEnabled = true
            StopTween     = false
            HaveAlucardFragment = false
            CurrentMode   = "Evil"
            ToggleButton.Text = "Auto Evil Trial + Yama2: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0,120,0)
            UpdateStatus("Запущен: сначала Evil Trial (0 фрагментов), потом триал+Yama2 (1 фрагмент).")
            AddLog("Auto Evil Trial + Yama Quest 2 включён.")
            -- стартовый пинок для первого триала
            CDKTrialModule.StartEvilTrial(AddLog)
        else
            AutoYamaSystem = false
            NoclipEnabled  = false
            StopTween      = true
            CurrentMode    = "None"
            ToggleButton.Text = "Auto Evil Trial + Yama2: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            UpdateStatus("Остановлен")
            AddLog("Auto Evil Trial + Yama Quest 2 выключен.")
        end
    end)

    UpdateKillsLabel()
    AddLog("GUI Auto Evil Trial + Yama2 загружен.")
end

CreateGui()

spawn(function()
    while task.wait(1) do
        if UptimeLabel then
            UptimeLabel.Text = "Время работы: " .. GetUptime()
        end
    end
end)
