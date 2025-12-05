-- Auto Yama Quest 3 (отдельный скрипт под твой оффлайн BF-проект)
-- Логика:
-- 1) Если открыт HellDimension -> заходим и прожимаем Torch1, Torch2, Torch3, Exit.
-- 2) Иначе, если есть Soul Reaper -> убиваем его.
-- 3) Иначе -> летим к NPC Bones и покупаем спавн Soul Reaper ("Bones","Buy",1,1).

---------------------
-- НАСТРОЙКИ
---------------------
local SwordName = "Yama"                         -- каким мечом бить
local TeleportSpeed = 150                        -- скорость твина при перелёте
local FarmOffset = CFrame.new(0, 10, -3)         -- позиция над целью

-- локация к NPC "Bones" (где покупается Soul Reaper / Hallow Essence)
local BonesNPCPos = CFrame.new(-9570.033203125, 315.9346923828125, 6726.89306640625)

---------------------
-- ПЕРЕМЕННЫЕ
---------------------
local AutoYamaQuest3 = false
local CurrentStatus = "Idle"
local StartTime = os.time()
local IsTeleporting = false
local StopTween = false
local NoclipEnabled = false
local IsFighting = false

local SoulReaperKillCount = 0

---------------------
-- СЕРВИСЫ
---------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- MODULE NET ATTACK (как в YamaQuest2)
---------------------
local modules = ReplicatedStorage:WaitForChild("Modules")
local net = modules:WaitForChild("Net")
local RegisterAttack = net:WaitForChild("RE/RegisterAttack")
local RegisterHit = net:WaitForChild("RE/RegisterHit")

local AttackModule = {}

function AttackModule:AttackEnemyModel(enemyModel)
    if not enemyModel then return end
    local hrp = enemyModel:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hitTable = {
        {enemyModel, hrp}
    }

    -- мягкий fast-attack
    RegisterAttack:FireServer(0)
    RegisterAttack:FireServer(1)
    RegisterHit:FireServer(hrp, hitTable)
end

---------------------
-- ЛОГИ / GUI-ПЕРЕМЕННЫЕ
---------------------
local StatusLogs = {}
local MaxLogs = 80

local ScreenGui, MainFrame, ToggleButton, StatusLabel, UptimeLabel, KillsLabel, LogsText

local function AddLog(msg)
    local timestamp = os.date("%H:%M:%S")
    local entry = "["..timestamp.."] "..tostring(msg)
    table.insert(StatusLogs, 1, entry)
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
    if LogsText then
        LogsText.Text = table.concat(StatusLogs, "\n")
    end
end

local function UpdateStatus(newStatus)
    CurrentStatus = newStatus
    AddLog("Статус: "..newStatus)
    if StatusLabel then
        StatusLabel.Text = "Статус: "..newStatus
    end
end

local function UpdateKillsLabel()
    if KillsLabel then
        KillsLabel.Text = "Убито Soul Reaper: " .. tostring(SoulReaperKillCount)
    end
end

local function GetUptime()
    local t = os.time() - StartTime
    local h = math.floor(t/3600)
    local m = math.floor((t%3600)/60)
    local s = t%60
    return string.format("%02d:%02d:%02d", h, m, s)
end

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
-- ХАКИ / ЭКИП
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
    if IsToolEquipped(name) then
        return
    end

    local p = LocalPlayer
    if not p then return end

    local char = p.Character or p.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
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

---------------------
-- ТЕЛЕПОРТ
---------------------
local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting then return end
    IsTeleporting = true
    StopTween = false

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        IsTeleporting = false
        return
    end

    local hrp = char.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    AddLog(string.format("Телепорт к %s (%.0f юнитов)", label or "цели", distance))

    local travelTime = distance / TeleportSpeed
    if travelTime < 3 then travelTime = 3 end
    if travelTime > 60 then travelTime = 60 end

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
            AddLog("Телепорт прерван (StopTween)")
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

        task.wait(0.3)
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

-- ФИКС ПОСЛЕ СМЕРТИ
LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween = false
    IsFighting = false
    AddLog("Персонаж возрождён, жду HRP...")

    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, AutoYamaQuest3 может продолжаться.")
    UpdateStatus("Ожидание Soul Reaper / HellDimension")
end)

---------------------
-- ПОИСК ОБЪЕКТОВ
---------------------
local function GetSoulReaper()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, v in ipairs(enemiesFolder:GetChildren()) do
            if v.Name == "Soul Reaper" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                if v.Humanoid.Health > 0 then
                    return v
                end
            end
        end
    end
    -- если в воркспейсе нет, но в реплике есть модель рейд-босса
    local rs = ReplicatedStorage
    for _, v in ipairs(rs:GetChildren()) do
        if string.find(v.Name, "Soul Reaper") then
            return nil -- он ещё в реплике, ждём пока заспавнится в Workspace
        end
    end
    return nil
end

local function GetHellDimension()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("HellDimension")
end

---------------------
-- RUNTIME: HellDimension
---------------------
local function RunHellDimension()
    local hell = GetHellDimension()
    if not hell then
        return
    end

    UpdateStatus("HellDimension: факелы")
    AddLog("HellDimension найден, начинаю прожимать факелы...")

    local function tpAndPressE(partName)
        local part = hell:FindFirstChild(partName)
        if not part or not part:IsA("BasePart") then
            AddLog("⚠️ В HellDimension не найдено: "..partName)
            return
        end

        SimpleTeleport(part.CFrame * CFrame.new(0, 5, 0), "HellDimension "..partName)
        task.wait(1.5)

        pcall(function()
            VirtualInputManager:SendKeyEvent(true, "E", false, game)
            VirtualInputManager:SendKeyEvent(false, "E", false, game)
        end)

        task.wait(1.0)
    end

    -- Torch1 → Torch2 → Torch3 → Exit
    tpAndPressE("Torch1")
    tpAndPressE("Torch2")
    tpAndPressE("Torch3")

    local exitPart = hell:FindFirstChild("Exit")
    if exitPart and exitPart:IsA("BasePart") then
        SimpleTeleport(exitPart.CFrame * CFrame.new(0, 5, 0), "HellDimension Exit")
        AddLog("HellDimension: вышел через Exit.")
    else
        AddLog("⚠️ В HellDimension не найден Exit, пропускаю.")
    end
end

---------------------
-- ПОКУПКА Soul Reaper через Bones
---------------------
local lastBonesBuy = 0

local function BuySoulReaper()
    if tick() - lastBonesBuy < 5 then
        return
    end
    lastBonesBuy = tick()

    UpdateStatus("Покупка Soul Reaper у Bones")
    AddLog("Лечу к Bones NPC для покупки Soul Reaper...")

    SimpleTeleport(BonesNPCPos, "Bones NPC")
    task.wait(1)

    pcall(function()
        remote:InvokeServer("Bones", "Buy", 1, 1)
    end)

    AddLog("Запрос на покупку Soul Reaper отправлен (Bones, Buy, 1, 1).")
end

---------------------
-- БОЙ С Soul Reaper
---------------------
local function FightSoulReaperOnce()
    if IsFighting then return end
    IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then
            return
        end

        local target = GetSoulReaper()
        if not target then
            AddLog("Soul Reaper сейчас не найден в Workspace.")
            return
        end

        AddLog("Найден Soul Reaper, начинаю бой...")
        UpdateStatus("Бой с Soul Reaper")

        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if tHRP then
            SimpleTeleport(tHRP.CFrame * FarmOffset, "старт боя с Soul Reaper")
        end

        local fightDeadline = tick() + 60   -- максимум 60 секунд на одну попытку
        local lastPosAdjust = 0
        local lastAttack = 0
        local engaged = false

        while AutoYamaQuest3
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

            if dist > 2500 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий Soul Reaper")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            -- фиксы коллизии/скорости босса
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
            local hum = target:FindFirstChild("Humanoid")
            local dead = hum and hum.Health <= 0
            if dead or not target.Parent then
                SoulReaperKillCount = SoulReaperKillCount + 1
                UpdateKillsLabel()
                AddLog("✅ Soul Reaper повержен. Всего киллов: " .. tostring(SoulReaperKillCount))
            else
                AddLog("⚠️ Бой с Soul Reaper прерван (вышли из цикла).")
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в FightSoulReaperOnce: "..tostring(err))
    end

    IsFighting = false
end

---------------------
-- ОСНОВНОЙ ЦИКЛ AUTOYAMAQUEST3
---------------------
spawn(function()
    while task.wait(0.4) do
        if AutoYamaQuest3 then
            local ok, err = pcall(function()
                local hell = GetHellDimension()
                if hell then
                    -- если уже есть HellDimension, не трогаем Soul Reaper и Bones,
                    -- просто завершаем пазл с факелами.
                    RunHellDimension()
                    return
                end

                -- HellDimension нет, проверяем Soul Reaper
                local sr = GetSoulReaper()
                if sr then
                    FightSoulReaperOnce()
                    return
                end

                -- Нет ни портала, ни босса -> пытаемся купить Soul Reaper через Bones
                BuySoulReaper()
                UpdateStatus("Ожидание спавна Soul Reaper / HellDimension")
            end)

            if not ok then
                AddLog("Ошибка в основном цикле AutoYamaQuest3: "..tostring(err))
            end
        end
    end
end)

---------------------
-- GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaQuest3Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 360, 0, 260)
    MainFrame.Position = UDim2.new(0, 20, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "Auto Yama Quest 3"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 220, 0, 30)
    ToggleButton.Position = UDim2.new(0, 10, 0, 30)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Auto Yama Quest 3: OFF"
    ToggleButton.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 20)
    StatusLabel.Position = UDim2.new(0, 10, 0, 65)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: "..CurrentStatus
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
    KillsLabel.Text = "Убито Soul Reaper: 0"
    KillsLabel.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 120)
    LogsFrame.Position = UDim2.new(0, 10, 0, 135)
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
        AutoYamaQuest3 = not AutoYamaQuest3
        if AutoYamaQuest3 then
            StartTime = os.time()
            ToggleButton.Text = "Auto Yama Quest 3: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            NoclipEnabled = true
            AddLog("Auto Yama Quest 3 включен (noclip ON)")
            UpdateStatus("Ожидание Soul Reaper / HellDimension")
        else
            ToggleButton.Text = "Auto Yama Quest 3: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            NoclipEnabled = false
            AddLog("Auto Yama Quest 3 выключен (noclip OFF)")
            UpdateStatus("Остановлен")
            StopTween = true
        end
    end)

    UpdateKillsLabel()
end

---------------------
-- ЗАПУСК GUI + ТАЙМЕР
---------------------
CreateGui()
AddLog("Скрипт AutoYamaQuest3 загружен. Включи его, когда начал 3-е испытание Yama у NPC.")

spawn(function()
    while task.wait(1) do
        if UptimeLabel then
            UptimeLabel.Text = "Время работы: "..GetUptime()
        end
    end
end)
