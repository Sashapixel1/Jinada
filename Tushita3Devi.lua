-- Auto Tushita Quest3
-- Этапы:
-- 1) Ищем / убиваем Cake Queen.
-- 2) Как только появляется HeavenlyDimension:
--    Torch1 -> зажать E 2 сек -> фарм мобов
--    Torch2 -> зажать E 2 сек -> фарм мобов
--    Torch3 -> зажать E 2 сек -> фарм мобов + Heaven's Guardian
--    Затем TP к Exit.

------------------------------------------------
-- НАСТРОЙКИ
------------------------------------------------
local WeaponName    = "Godhuman"                -- оружие для боя
local TeleportSpeed = 300                       -- скорость полёта
local FarmOffset    = CFrame.new(0, 10, -3)     -- базовая позиция над мобом

-- отдельный оффсет конкретно для Cake Queen (выше)
local CakeQueenOffset = CFrame.new(0, 20, -3)

-- позиция Cake Queen (из 12к)
local CakeQueenIsland = CFrame.new(-709.3132934570312, 381.6005859375, -11011.396484375)

------------------------------------------------
-- СЕРВИСЫ / ПЕРЕМЕННЫЕ
------------------------------------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local Vim               = game:GetService("VirtualInputManager")

local LocalPlayer       = Players.LocalPlayer
local remote            = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local AutoTushitaQ3     = false
local IsTeleporting     = false
local StopTween         = false
local IsFighting        = false
local CurrentStatus     = "Idle"

-- стадия внутри HeavenlyDimension:
-- 0 -Torch1, 1 -Torch2, 2 -Torch3, 3 -добиваем мобов, 4 - Exit
local HeavenlyStage     = 0

-- антиспам логов
local lastCakeLogTime       = 0
local lastHeavenlyFoundTime = 0

------------------------------------------------
-- ЛОГИ / GUI
------------------------------------------------
local StatusLogs = {}
local MaxLogs    = 200

local ScreenGui, MainFrame, ToggleButton
local StatusLabel, LogsText

-- запоминаем последний текст лог-сообщения, чтобы не спамить одинаковыми подряд
local lastLogMsgText = nil

local function AddLog(msg)
    -- если это то же самое сообщение, что и прошлое, не логируем
    if lastLogMsgText == msg then
        return
    end
    lastLogMsgText = msg

    local ts   = os.date("%H:%M:%S")
    local line = "["..ts.."] "..tostring(msg)
    table.insert(StatusLogs, 1, line)
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
    if LogsText then
        LogsText.Text = table.concat(StatusLogs, "\n")
    end
end

local function UpdateStatus(text)
    CurrentStatus = text
    if StatusLabel then
        StatusLabel.Text = "Статус: " .. text
    end
    AddLog("Статус: " .. text)
end

------------------------------------------------
-- ANTI-AFK
------------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    AddLog("Anti-AFK: отправлен фейковый клик.")
end)

------------------------------------------------
-- NET / ATTACK
------------------------------------------------
local modules        = ReplicatedStorage:WaitForChild("Modules")
local net            = modules:WaitForChild("Net")
local RegisterAttack = net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = net:WaitForChild("RE/RegisterHit")

local AttackModule = {}

function AttackModule:AttackEnemyModel(enemyModel)
    if not enemyModel then return end
    local hrp = enemyModel:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hitTable = {{enemyModel, hrp}}

    RegisterAttack:FireServer(0)
    RegisterAttack:FireServer(1)
    RegisterHit:FireServer(hrp, hitTable)
end

------------------------------------------------
-- ХАКИ / ЭКИП
------------------------------------------------
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
    if IsToolEquipped(name) then
        return
    end

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
        AddLog("⚔️ Экипирован: " .. toolFound.Name)
    else
        if tick() - lastEquipFailLog > 3 then
            AddLog("⚠️ Не удалось найти оружие: " .. name)
            lastEquipFailLog = tick()
        end
    end
end

------------------------------------------------
-- ТЕЛЕПОРТ
------------------------------------------------
local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting or not AutoTushitaQ3 then return end
    IsTeleporting = true
    StopTween     = false

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        IsTeleporting = false
        return
    end

    local hrp  = char.HumanoidRootPart
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    local t    = math.clamp(dist / TeleportSpeed, 0.5, 60)

    -- отдельное сообщение для острова Cake Queen, без цифр, чтобы не спамить
    if label == "остров Cake Queen" then
        AddLog("Телепорт к острову Cake Queen")
    else
        AddLog(string.format("Телепорт к %s (%.0f stud, t=%.1f)", label or "точке", dist, t))
    end

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()

    local start = tick()
    while tick() - start < t do
        if StopTween or (not AutoTushitaQ3) then
            tween:Cancel()
            IsTeleporting = false
            AddLog("Телепорт прерван (OFF / StopTween).")
            return
        end

        local c = LocalPlayer.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not c or not hrp then
            tween:Cancel()
            IsTeleporting = false
            return
        end

        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide = false

        RunService.Heartbeat:Wait()
    end

    tween:Cancel()
    local c = LocalPlayer.Character
    hrp = c and c:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide = false
    end

    IsTeleporting = false
end

-- сброс после смерти
LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = false
    IsFighting    = false
    AddLog("Персонаж возрождён, жду HRP для Tushita Q3...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, фарм Tushita Q3 можно продолжать.")
    UpdateStatus("Ожидание / Tushita Q3")
end)

------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
------------------------------------------------
local function GetEnemiesFolder()
    return Workspace:FindFirstChild("Enemies")
end

local function FindCakeQueen()
    local enemies = GetEnemiesFolder()
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

local function HeavenlyDimensionFolder()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("HeavenlyDimension")
end

local function EnsureInsideHeavenlyDimension(dim)
    dim = dim or HeavenlyDimensionFolder()
    if not dim then return false end

    local torch1 = dim:FindFirstChild("Torch1")
    if not torch1 then return true end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local dist = (hrp.Position - torch1.Position).Magnitude
    if dist > 600 then
        UpdateStatus("Tushita3: лечу в HeavenlyDimension.")
        SimpleTeleport(torch1.CFrame * CFrame.new(0, 5, 0), "HeavenlyDimension Torch1")
        return false
    end

    return true
end

local function IsHeavenlyMob(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name
    if name == "Cursed Skeleton" then return true end
    if name == "Heaven's Guardian" then return true end
    return false
end

local function GetHeavenlyMob()
    local enemies = GetEnemiesFolder()
    if not enemies then return nil end
    for _, v in ipairs(enemies:GetChildren()) do
        if IsHeavenlyMob(v)
            and v:FindFirstChild("Humanoid")
            and v:FindFirstChild("HumanoidRootPart")
            and v.Humanoid.Health > 0 then
            return v
        end
    end
    return nil
end

-- FightMob: добавлен параметр customOffset (по умолчанию FarmOffset)
local function FightMob(target, label, maxTime, customOffset)
    maxTime = maxTime or 60
    if not target then return end
    if IsFighting then return end
    IsFighting = true

    local offsetCF = customOffset or FarmOffset

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not (char and hrp and hum and tHRP) then return end

        UpdateStatus(label or "Бой")
        AddLog("Начинаю бой: "..tostring(target.Name))

        SimpleTeleport(tHRP.CFrame * offsetCF, label or "цель")

        local deadline      = tick() + maxTime
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoTushitaQ3
            and target.Parent
            and hum.Health > 0
            and tick() < deadline do

            engaged = true

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and hum and tHRP) then
                break
            end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * offsetCF, "далёкий моб")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * offsetCF
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
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
            EquipToolByName(WeaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        if engaged then
            hum = target:FindFirstChild("Humanoid")
            local dead = hum and hum.Health <= 0
            if dead or not target.Parent then
                AddLog("✅ Цель убита: "..tostring(target.Name))
            else
                AddLog("⚠️ Бой прерван: "..tostring(target.Name))
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в FightMob: "..tostring(err))
    end

    IsFighting = false
end

local function HoldEFor(seconds, label)
    label = label or "E"
    AddLog("Зажимаю "..label.." на "..tostring(seconds).." сек.")
    Vim:SendKeyEvent(true, "E", false, game)
    task.wait(seconds)
    Vim:SendKeyEvent(false, "E", false, game)
end

local function FarmHeavenlyMobsFor(duration)
    local deadline = tick() + duration
    while AutoTushitaQ3 and tick() < deadline do
        local mob = GetHeavenlyMob()
        if not mob then break end
        FightMob(mob, "Tushita3: Heavenly mob "..mob.Name, 40)
        task.wait(0.1)
    end
end

------------------------------------------------
-- ЛОГИКА ЭТАПОВ
------------------------------------------------

local function RunCakeQueenPhase()
    -- если уже появилось измерение - Cake Queen не трогаем
    if HeavenlyDimensionFolder() then
        return
    end

    local boss = FindCakeQueen()
    if boss then
        -- тут используем повышенный оффсет CakeQueenOffset
        FightMob(boss, "Tushita3: Cake Queen", 120, CakeQueenOffset)
    else
        -- антиспам логов "не найдена" раз в минуту
        if tick() - lastCakeLogTime > 60 then
            lastCakeLogTime = tick()
            UpdateStatus("Tushita3: Cake Queen не найдена, лечу к острову.")
        end
        SimpleTeleport(CakeQueenIsland, "остров Cake Queen")
    end
end

local function RunHeavenlyDimensionPhase(dim)
    dim = dim or HeavenlyDimensionFolder()
    if not dim then return end

    if not EnsureInsideHeavenlyDimension(dim) then
        return
    end

    -- всегда сначала пробуем подраться с мобами
    local currentMob = GetHeavenlyMob()
    if currentMob then
        FightMob(currentMob, "Tushita3: бой в HeavenlyDimension", 60)
        return
    end

    local torch1 = dim:FindFirstChild("Torch1")
    local torch2 = dim:FindFirstChild("Torch2")
    local torch3 = dim:FindFirstChild("Torch3")
    local exit   = dim:FindFirstChild("Exit")

    if HeavenlyStage == 0 then
        if torch1 then
            UpdateStatus("Tushita3: Torch1.")
            SimpleTeleport(torch1.CFrame * CFrame.new(0, 5, 0), "Torch1")
            HoldEFor(2, "Torch1")
            HeavenlyStage = 1
            AddLog("Torch1 активирован, фарм скелетов.")
            FarmHeavenlyMobsFor(25)
        end
        return
    end

    if HeavenlyStage == 1 then
        if torch2 then
            UpdateStatus("Tushita3: Torch2.")
            SimpleTeleport(torch2.CFrame * CFrame.new(0, 5, 0), "Torch2")
            HoldEFor(2, "Torch2")
            HeavenlyStage = 2
            AddLog("Torch2 активирован, фарм скелетов.")
            FarmHeavenlyMobsFor(25)
        end
        return
    end

    if HeavenlyStage == 2 then
        if torch3 then
            UpdateStatus("Tushita3: Torch3.")
            SimpleTeleport(torch3.CFrame * CFrame.new(0, 5, 0), "Torch3")
            HoldEFor(2, "Torch3")
            HeavenlyStage = 3
            AddLog("Torch3 активирован, фарм скелетов и Heaven's Guardian.")
            FarmHeavenlyMobsFor(40)
        end
        return
    end

    if HeavenlyStage == 3 then
        local mob = GetHeavenlyMob()
        if mob then
            FightMob(mob, "Tushita3: добиваю мобов / Heaven's Guardian", 60)
            return
        end

        if exit then
            UpdateStatus("Tushita3: все мобы убиты, лечу к Exit.")
            SimpleTeleport(exit.CFrame * CFrame.new(0, 5, 0), "Exit")
            HeavenlyStage = 4
            AddLog("Tushita3: этап HeavenlyDimension завершён (Teleport Exit).")
        end
        return
    end

    if HeavenlyStage >= 4 then
        UpdateStatus("Tushita3: HeavenlyDimension завершён, жду завершения квеста.")
    end
end

local function RunTushitaQ3Cycle()
    local dim = HeavenlyDimensionFolder()

    if dim then
        -- один раз логируем факт появления измерения
        if tick() - lastHeavenlyFoundTime > 5 then
            lastHeavenlyFoundTime = tick()
            AddLog("HeavenlyDimension обнаружен, переключаюсь на фазу измерения.")
        end
        RunHeavenlyDimensionPhase(dim)
    else
        HeavenlyStage = 0 -- если измерение пропало/ещё не появилось
        RunCakeQueenPhase()
    end
end

------------------------------------------------
-- GUI
------------------------------------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoTushitaQ3Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 520, 0, 280)
    MainFrame.Position = UDim2.new(0, 40, 0, 460)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "Auto Tushita Quest3 (Cake Queen + HeavenlyDimension)"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 260, 0, 30)
    ToggleButton.Position = UDim2.new(0, 10, 0, 30)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Tushita Q3: OFF"
    ToggleButton.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 22)
    StatusLabel.Position = UDim2.new(0, 10, 0, 65)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: Остановлен"
    StatusLabel.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 190)
    LogsFrame.Position = UDim2.new(0, 10, 0, 90)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
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

    ToggleButton.MouseButton1Click:Connect(function()
        AutoTushitaQ3 = not AutoTushitaQ3
        StopTween     = not AutoTushitaQ3

        if AutoTushitaQ3 then
            ToggleButton.Text = "Tushita Q3: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            StopTween     = false
            HeavenlyStage = 0
            UpdateStatus("Фарм Tushita Q3")
        else
            ToggleButton.Text = "Tushita Q3: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            UpdateStatus("Остановлен")
        end
    end)

    AddLog("GUI Auto Tushita Q3 загружен.")
end

------------------------------------------------
-- ОСНОВНОЙ ЦИКЛ
------------------------------------------------
spawn(function()
    while task.wait(0.4) do
        if AutoTushitaQ3 then
            local ok, err = pcall(RunTushitaQ3Cycle)
            if not ok then
                AddLog("Ошибка в основном цикле AutoTushitaQ3: "..tostring(err))
            end
        end
    end
end)

------------------------------------------------
-- СТАРТ
------------------------------------------------
CreateGui()
