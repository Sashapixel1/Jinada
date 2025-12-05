-- Auto Yama Quest 2 (отдельный скрипт под твой оффлайн BF-проект)
-- Только второй квест Yama (HazeESP), без мастери и без полного CDK.

---------------------
-- НАСТРОЙКИ
---------------------
local SwordName = "Yama"                      -- каким мечом бить
local TeleportSpeed = 150                     -- скорость телепорта при подлёте
local FarmOffset = CFrame.new(0, 10, -3)      -- позиция над мобом

-- точки патруля по карте (координаты из большого скрипта)
local PatrolPoints = {
    -- Pirate Port – Pistol Billionaire
    CFrame.new(-187.3301544189453, 86.23987579345703, 6013.513671875),
    -- Marine Tree Island – Marine Commodore
    CFrame.new(2286.0078125, 73.13391876220703, -7159.80908203125),
    -- Haunted Castle район
    CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875),
    CFrame.new(-13451.46484375, 543.712890625, -6961.0029296875),
}

---------------------
-- ПЕРЕМЕННЫЕ
---------------------
local AutoYamaQuest2 = false
local CurrentStatus = "Idle"
local StartTime = os.time()
local IsTeleporting = false
local StopTween = false
local NoclipEnabled = false
local IsFarming = false

local patrolIndex = 1
local lastPatrol = 0         -- cooldown патруля

---------------------
-- СЕРВИСЫ
---------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- MODULE NET ATTACK
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
-- ЛОГИ
---------------------
local StatusLogs = {}
local MaxLogs = 60

local ScreenGui, MainFrame, ToggleButton, StatusLabel, UptimeLabel, LogsText

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
    IsFarming = false
    AddLog("Персонаж возрождён, жду появления HRP...")

    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, фарм можно продолжать")
    UpdateStatus("Ожидание Haze-мобов / патруль")
end)

---------------------
-- ПОИСК HazeESP МОБОВ
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
-- ПАТРУЛЬ, ЕСЛИ HazeESP НЕТ
---------------------
local function PatrolStep()
    if not AutoYamaQuest2 then return end
    if #PatrolPoints == 0 then return end
    if IsTeleporting then return end             -- не стартуем новый полёт, если ещё летим
    if tick() - lastPatrol < 8 then return end   -- cooldown 8 секунд

    local idx = patrolIndex
    patrolIndex = patrolIndex + 1
    if patrolIndex > #PatrolPoints then
        patrolIndex = 1
    end
    lastPatrol = tick()

    local targetCF = PatrolPoints[idx] * FarmOffset
    AddLog("Патруль: лечу на точку #" .. tostring(idx))
    UpdateStatus("Патруль, поиск Haze-мобов (точка "..tostring(idx)..")")
    SimpleTeleport(targetCF, "патруль Yama2 #" .. tostring(idx))
end

---------------------
-- ОСНОВНОЙ БОЙ ДЛЯ YAMA QUEST 2
---------------------
local function FarmYamaQuest2Once()
    if IsFarming then return end
    IsFarming = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then
            return
        end

        local target = GetNearestHazeEnemy(9999)

        -- если HazeESP-мобов нет рядом, патрулируем карту
        if not target then
            AddLog("HazeESP мобов рядом нет, запускаю патруль...")
            PatrolStep()
            return
        end

        -- нашли цель: прерываем патрульный телепорт
        StopTween = true
        task.wait(0.1)
        IsTeleporting = false

        AddLog("Нашёл моба с HazeESP: "..tostring(target.Name))
        UpdateStatus("Yama Quest 2: бой с "..tostring(target.Name))

        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if tHRP then
            -- гарантированно подлетаем к мобу перед началом боя
            SimpleTeleport(tHRP.CFrame * FarmOffset, "старт боя с Haze-мобом")
        end

        local fightDeadline = tick() + 35
        local lastPosAdjust = 0
        local lastAttack = 0

        while AutoYamaQuest2
            and target.Parent
            and target:FindFirstChild("Humanoid")
            and target.Humanoid.Health > 0
            and tick() < fightDeadline do

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
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            -- фиксы коллизии/видимости
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

            if target.Humanoid.Health <= 0 and target.Humanoid:FindFirstChild("Animator") then
                target.Humanoid.Animator:Destroy()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка в FarmYamaQuest2Once: "..tostring(err))
    end

    IsFarming = false
end

---------------------
-- HazeESP TWEAK (увеличиваем рамку)
---------------------
spawn(function()
    while task.wait(0.2) do
        if AutoYamaQuest2 then
            pcall(function()
                local enemiesFolder = Workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    for _, v in ipairs(enemiesFolder:GetChildren()) do
                        if v:FindFirstChild("HazeESP") then
                            v.HazeESP.Size = UDim2.new(50, 50, 50, 50)
                            v.HazeESP.MaxDistance = "inf"
                        end
                    end
                end
            end)
        end
    end
end)

---------------------
-- ОСНОВНОЙ ЦИКЛ
---------------------
spawn(function()
    while task.wait(0.2) do
        if AutoYamaQuest2 then
            FarmYamaQuest2Once()
        end
    end
end)

---------------------
-- GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaQuest2Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 320, 0, 230)
    MainFrame.Position = UDim2.new(0, 20, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "Auto Yama Quest 2"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 200, 0, 30)
    ToggleButton.Position = UDim2.new(0, 10, 0, 30)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Auto Yama Quest 2: OFF"
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

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 110)
    LogsFrame.Position = UDim2.new(0, 10, 0, 110)
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
        AutoYamaQuest2 = not AutoYamaQuest2
        if AutoYamaQuest2 then
            StartTime = os.time()
            ToggleButton.Text = "Auto Yama Quest 2: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            NoclipEnabled = true
            AddLog("Auto Yama Quest 2 включен (noclip ON)")
            UpdateStatus("Патруль / поиск Haze-мобов")
        else
            ToggleButton.Text = "Auto Yama Quest 2: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            NoclipEnabled = false
            AddLog("Auto Yama Quest 2 выключен (noclip OFF)")
            UpdateStatus("Остановлен")
            StopTween = true
        end
    end)
end

---------------------
-- ЗАПУСК GUI + ТАЙМЕР
---------------------
CreateGui()
AddLog("Скрипт Yama Quest 2 загружен. Включи кнопку, когда испытание уже запущено у NPC.")

spawn(function()
    while task.wait(1) do
        if UptimeLabel then
            UptimeLabel.Text = "Время работы: "..GetUptime()
        end
    end
end)
