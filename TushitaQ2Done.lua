-- Auto Tushita Quest2
-- Фарм мобов в зоне Tushita Q2 (координаты из 12к) + Anti-AFK

------------------------------------------------
-- НАСТРОЙКИ
------------------------------------------------
local WeaponName    = "Godhuman"                -- чем бить
local TeleportSpeed = 300                       -- скорость полёта
local FarmOffset    = CFrame.new(0, 10, -3)     -- позиция над мобом

-- центр зоны квеста (из 12к)
local TushitaQ2Center = CFrame.new(-5539.3115, 313.8005, -2972.3723)
local InZoneRadius    = 500                     -- когда считаем, что мы "в зоне"
local MaxMobDistance  = 2000                    -- максимальная дистанция до моба

------------------------------------------------
-- СЕРВИСЫ / ПЕРЕМЕННЫЕ
------------------------------------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser") -- для Anti-AFK

local LocalPlayer       = Players.LocalPlayer
local remote            = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local AutoTushitaQ2     = false
local IsTeleporting     = false
local StopTween         = false
local IsFighting        = false
local CurrentStatus     = "Idle"

------------------------------------------------
-- ЛОГИ / GUI (создаём сразу, чтобы Anti-AFK мог писать лог)
------------------------------------------------
local StatusLogs = {}
local MaxLogs    = 200

local ScreenGui, MainFrame, ToggleButton
local StatusLabel, LogsText

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
    -- этот ивент триггерится, когда игрок долго ничего не делает
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

    local hitTable = {
        {enemyModel, hrp}
    }

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
    if IsTeleporting or not AutoTushitaQ2 then return end
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

    AddLog(string.format("Телепорт к %s (%.0f stud, t=%.1f)", label or "точке", dist, t))

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()

    local start = tick()
    while tick() - start < t do
        if StopTween or (not AutoTushitaQ2) then
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

-- сброс флагов после смерти
LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = false
    IsFighting    = false
    AddLog("Персонаж возрождён, жду HRP для Tushita Q2...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, фарм Tushita Q2 можно продолжать.")
    UpdateStatus("Ожидание / Tushita Q2")
end)

------------------------------------------------
-- ВСПОМОГАТЕЛЬНОЕ
------------------------------------------------
local function IsInQuestZone()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local dist = (hrp.Position - TushitaQ2Center.Position).Magnitude
    return dist <= InZoneRadius, dist
end

local function GetNearestMobInZone()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, best = nil, MaxMobDistance

    for _, v in ipairs(enemiesFolder:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            local hum  = v.Humanoid
            local tHRP = v.HumanoidRootPart
            if hum.Health > 0 then
                local distToPlayer = (tHRP.Position - hrp.Position).Magnitude
                if distToPlayer <= MaxMobDistance then
                    local distToCenter = (tHRP.Position - TushitaQ2Center.Position).Magnitude
                    if distToCenter <= InZoneRadius + 200 then
                        if distToPlayer < best then
                            best    = distToPlayer
                            nearest = v
                        end
                    end
                end
            end
        end
    end

    return nearest
end

------------------------------------------------
-- БОЙ
------------------------------------------------
local function RunTushitaQ2Once()
    if IsFighting then return end

    local inZone, dist = IsInQuestZone()
    if not inZone then
        UpdateStatus(string.format("Tushita Q2: лечу в зону (%.0f stud)", dist or 9999))
        SimpleTeleport(TushitaQ2Center * CFrame.new(0, 5, 0), "центр Tushita Q2")
        return
    end

    local target = GetNearestMobInZone()
    if not target then
        UpdateStatus("Tushita Q2: враги рядом не найдены, жду...")
        return
    end

    IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then
            return
        end

        UpdateStatus("Tushita Q2: фарм "..tostring(target.Name))
        AddLog("Нашёл цель: "..tostring(target.Name))

        SimpleTeleport(tHRP.CFrame * FarmOffset, "моб Tushita Q2")

        local fightDeadline = tick() + 45
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoTushitaQ2
            and target.Parent
            and hum.Health > 0
            and tick() < fightDeadline do

            engaged = true

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then
                break
            end

            local distToMob = (tHRP.Position - hrp.Position).Magnitude
            if distToMob > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий моб Tushita Q2")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
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
                AddLog("✅ Моб убит (Tushita Q2).")
            else
                AddLog("⚠️ Бой прерван (Tushita Q2).")
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в RunTushitaQ2Once: "..tostring(err))
    end

    IsFighting = false
end

------------------------------------------------
-- GUI
------------------------------------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoTushitaQ2Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 520, 0, 280)
    MainFrame.Position = UDim2.new(0, 560, 0, 180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "Auto Tushita Quest2"
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
    ToggleButton.Text = "Tushita Q2: OFF"
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
        AutoTushitaQ2 = not AutoTushitaQ2
        StopTween     = not AutoTushitaQ2

        if AutoTushitaQ2 then
            ToggleButton.Text = "Tushita Q2: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            StopTween = false
            UpdateStatus("Фарм Tushita Q2")
        else
            ToggleButton.Text = "Tushita Q2: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            UpdateStatus("Остановлен")
        end
    end)

    AddLog("GUI Auto Tushita Q2 загружен.")
end

------------------------------------------------
-- ОСНОВНОЙ ЦИКЛ
------------------------------------------------
spawn(function()
    while task.wait(0.4) do
        if AutoTushitaQ2 then
            local ok, err = pcall(RunTushitaQ2Once)
            if not ok then
                AddLog("Ошибка в основном цикле AutoTushitaQ2: "..tostring(err))
            end
        end
    end
end)

------------------------------------------------
-- СТАРТ
------------------------------------------------
CreateGui()
