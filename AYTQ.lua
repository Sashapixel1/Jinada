--========================================================
-- Auto Yama / Tushita (GUI + Elite Hunter fix)
--========================================================

task.wait(2)

------------------------------------------------
-- НАСТРОЙКИ
------------------------------------------------
local WeaponName     = "Godhuman"              -- чем бить элиту
local TeleportSpeed  = 300                     -- скорость полёта (stud/сек)
local FarmOffset     = CFrame.new(0, 12, -3)   -- позиция над мобом

------------------------------------------------
-- СЕРВИСЫ
------------------------------------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local remote      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

------------------------------------------------
-- NET-модуль для фаст-атаки (ИСПРАВЛЕНО)
------------------------------------------------
local modules        = ReplicatedStorage:WaitForChild("Modules")
local net            = modules:WaitForChild("Net")

-- В 12к и в игре используются ИМЕНА с '/', а не папка RE.
local RegisterAttack = net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = net:WaitForChild("RE/RegisterHit")

local AttackModule = {}

function AttackModule:AttackEnemyModel(enemyModel)
    if not enemyModel then return end
    local hrp = enemyModel:FindFirstChild("HumanoidRootPart")
    local hum = enemyModel:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then return end

    local hitTable = {
        {enemyModel, hrp}
    }

    RegisterAttack:FireServer(0)
    RegisterAttack:FireServer(1)
    RegisterHit:FireServer(hrp, hitTable)
end

------------------------------------------------
-- ГЛОБАЛЬНЫЕ ФЛАГИ
------------------------------------------------
local AutoTushita   = false
local AutoYama      = false
local CurrentStatus = "Idle"

------------------------------------------------
-- ЛОГИ / GUI
------------------------------------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame
local StatusLabel, LogsText
local TushitaButton, YamaButton

local function AddLog(msg)
    local ts = os.date("%H:%M:%S")
    local line = string.format("[%s] %s", ts, tostring(msg))
    table.insert(StatusLogs, 1, line)
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

------------------------------------------------
-- Anti-AFK
------------------------------------------------
task.spawn(function()
    while task.wait(55) do
        if AutoYama or AutoTushita then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
                AddLog("Anti-AFK: фейковый клик, чтобы не кикнуло.")
            end)
        end
    end
end)

------------------------------------------------
-- Noclip
------------------------------------------------
local NoclipEnabled = false
task.spawn(function()
    while task.wait(0.2) do
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
    local nameLower = string.lower(name)
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and string.lower(obj.Name) == nameLower then
            return true
        end
    end
    return false
end

local function EquipToolByName(name)
    if IsToolEquipped(name) then return end

    local p   = LocalPlayer
    local char = p.Character or p.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local nameLower = string.lower(name)
    local function findTool(container)
        if not container then return nil end
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("Tool") and string.lower(obj.Name) == nameLower then
                return obj
            end
        end
        return nil
    end

    local tool = findTool(p:FindFirstChild("Backpack")) or findTool(char)
    if tool then
        hum:UnequipTools()
        hum:EquipTool(tool)
        AddLog("Экипирован: "..tool.Name)
    else
        if tick() - lastEquipFailLog > 3 then
            AddLog("Не нашёл оружие: "..name)
            lastEquipFailLog = tick()
        end
    end
end

------------------------------------------------
-- ТЕЛЕПОРТ
------------------------------------------------
local IsTeleporting = false
local StopTween     = false

local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting then return end
    IsTeleporting = true
    StopTween     = false

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then
        IsTeleporting = false
        return
    end

    local distance   = (hrp.Position - targetCFrame.Position).Magnitude
    local travelTime = math.clamp(distance / TeleportSpeed, 0.5, 60)

    AddLog(string.format("Телепорт к %s (%.0f stud, t=%.1f)", label or "цели", distance, travelTime))

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
        if not (c and hrp) then
            tween:Cancel()
            IsTeleporting = false
            return
        end
        hrp.AssemblyLinearVelocity = Vector3.new()
        hrp.AssemblyAngularVelocity = Vector3.new()
        hrp.CanCollide = false
        task.wait(0.1)
    end

    tween:Cancel()
    local c = LocalPlayer.Character
    hrp = c and c:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.new()
        hrp.AssemblyAngularVelocity = Vector3.new()
        hrp.CanCollide = false
    end
    IsTeleporting = false
end

LocalPlayer.CharacterAdded:Connect(function()
    IsTeleporting = false
    StopTween     = false
    AddLog("Персонаж возрождён, телепорт можно продолжать.")
end)

------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
------------------------------------------------
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

    local ok, inv = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then
        for _, item in ipairs(inv) do
            local name = item.Name or item.name
            if name == itemName then
                return true
            end
        end
    end

    return false
end

local function GetEliteProgress()
    local ok, res = pcall(function()
        return remote:InvokeServer("EliteHunter", "Progress")
    end)
    if ok then
        return tonumber(res) or 0
    end
    return 0
end

------------------------------------------------
-- ЭЛИТКИ
------------------------------------------------
local EliteNames = { "Diablo", "Deandre", "Urban" }

local function IsEliteName(name)
    name = tostring(name)
    for _, base in ipairs(EliteNames) do
        if name == base or string.find(name, base, 1, true) then
            return true
        end
    end
    return false
end

local function FindEliteTarget()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return nil end

    local nearest, bestDist = nil, math.huge

    local function consider(model)
        if not model:IsA("Model") then return end
        if not IsEliteName(model.Name) then return end

        local hum  = model:FindFirstChildOfClass("Humanoid")
        local tHRP = model:FindFirstChild("HumanoidRootPart")
        if not (hum and tHRP and hum.Health > 0) then return end

        local d = (tHRP.Position - hrp.Position).Magnitude
        if d < bestDist then
            bestDist = d
            nearest  = model
        end
    end

    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, v in ipairs(enemiesFolder:GetDescendants()) do
            consider(v)
        end
    end

    if not nearest then
        for _, v in ipairs(Workspace:GetDescendants()) do
            consider(v)
        end
    end

    return nearest
end

------------------------------------------------
-- Elite Hunter NPC
------------------------------------------------
local CastleOnSeaCFrame = CFrame.new(-5500, 313, -2975)

local function FindEliteHunterNPC()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Elite Hunter" then
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if hrp then
                return hrp
            end
        end
    end
    return nil
end

local lastEliteQuestRequest = 0
local EliteQuestCooldown    = 60

local function RequestEliteQuest()
    local now = tick()
    if now - lastEliteQuestRequest < EliteQuestCooldown then
        return
    end
    lastEliteQuestRequest = now

    local npcHrp = FindEliteHunterNPC()
    if npcHrp then
        SimpleTeleport(npcHrp.CFrame * CFrame.new(0, 4, 3), "Elite Hunter NPC")
    else
        SimpleTeleport(CastleOnSeaCFrame, "Castle On The Sea")
    end

    task.wait(1.5)
    AddLog("Пробую взять квест Elite Hunter.")
    local ok, res = pcall(function()
        return remote:InvokeServer("EliteHunter")
    end)
    AddLog("Квест EliteHunter запрошен. Ответ: "..tostring(res))
end

------------------------------------------------
-- БОЙ С ЭЛИТКОЙ
------------------------------------------------
local function FightElite(target)
    if not target then return end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local tHRP = target:FindFirstChild("HumanoidRootPart")
    local hum  = target:FindFirstChildOfClass("Humanoid")
    if not (char and hrp and tHRP and hum) then return end

    local fightDeadline = tick() + 90
    local lastAdjust    = 0
    local lastHit       = 0

    AddLog("Нашёл элитку: "..tostring(target.Name)..", начинаю бой.")

    while AutoYama
        and target.Parent
        and hum.Health > 0
        and tick() < fightDeadline do

        char = LocalPlayer.Character
        hrp  = char and char:FindFirstChild("HumanoidRootPart")
        tHRP = target:FindFirstChild("HumanoidRootPart")
        hum  = target:FindFirstChildOfClass("Humanoid")

        if not (char and hrp and tHRP and hum) then break end

        local dist = (tHRP.Position - hrp.Position).Magnitude
        if dist > 2500 then
            SimpleTeleport(tHRP.CFrame * FarmOffset, "элитный босс (далеко)")
        else
            if tick() - lastAdjust > 0.05 then
                hrp.CFrame = tHRP.CFrame * FarmOffset
                hrp.AssemblyLinearVelocity = Vector3.new()
                hrp.AssemblyAngularVelocity = Vector3.new()
                hrp.CanCollide = false
                lastAdjust = tick()
            end
        end

        AutoHaki()
        EquipToolByName(WeaponName)

        pcall(function()
            tHRP.CanCollide   = false
            hum.WalkSpeed     = 0
            hum.JumpPower     = 0
        end)

        if tick() - lastHit > 0.15 then
            AttackModule:AttackEnemyModel(target)
            lastHit = tick()
        end

        RunService.Heartbeat:Wait()
    end

    if not hum or hum.Health <= 0 or not target.Parent then
        AddLog("Элитный босс убит.")
    else
        AddLog("Бой с элиткой прерван.")
    end
end

------------------------------------------------
-- ЛОГИКА Yama
------------------------------------------------
local function RunYamaLogic()
    if HasItemInInventory("Yama") then
        UpdateStatus("Yama: меч уже есть, остановлен.")
        AutoYama = false
        return
    end

    local progress = GetEliteProgress()
    AddLog("Yama: прогресс Elite Hunter = "..tostring(progress).."/30.")

    if progress >= 30 then
        UpdateStatus("Yama: открываю водопад / забираю меч.")
        local waterfall = CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875)
        SimpleTeleport(waterfall, "Waterfall / Sealed Katana")

        task.wait(1.5)
        AddLog("Пробую кликнуть по SealedKatana (водопад).")

        pcall(function()
            local map    = Workspace:FindFirstChild("Map")
            local wf     = map and map:FindFirstChild("Waterfall")
            local sword  = wf and wf:FindFirstChild("SealedKatana")
            local handle = sword and sword:FindFirstChild("Handle")
            local cd     = handle and handle:FindFirstChildOfClass("ClickDetector")
            if cd then
                fireclickdetector(cd)
                AddLog("Клик по SealedKatana отправлен.")
            else
                AddLog("ClickDetector водопада (SealedKatana) не найден.")
            end
        end)

        return
    end

    local elite = FindEliteTarget()
    if elite then
        UpdateStatus("Yama: элитка найдена, атакую ("..elite.Name..").")
        FightElite(elite)
        return
    end

    UpdateStatus("Yama: квест активен или нет элитки, беру/обновляю квест.")
    RequestEliteQuest()
end

------------------------------------------------
-- ЛОГИКА Tushita (пока заглушка)
------------------------------------------------
local function RunTushitaLogic()
    UpdateStatus("Tushita: логика пока не реализована в этом файле.")
end

------------------------------------------------
-- GUI
------------------------------------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaTushitaGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 600, 0, 260)
    MainFrame.Position = UDim2.new(0, 40, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 26)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Title.Text = "Auto Yama / Tushita (EliteHunter fix)"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 20
    Title.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 22)
    StatusLabel.Position = UDim2.new(0, 10, 0, 30)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: "..CurrentStatus
    StatusLabel.Parent = MainFrame

    TushitaButton = Instance.new("TextButton")
    TushitaButton.Size = UDim2.new(0, 180, 0, 32)
    TushitaButton.Position = UDim2.new(0, 10, 0, 60)
    TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TushitaButton.TextColor3 = Color3.new(1,1,1)
    TushitaButton.Font = Enum.Font.SourceSansBold
    TushitaButton.TextSize = 16
    TushitaButton.Text = "Auto Tushita: OFF"
    TushitaButton.Parent = MainFrame

    YamaButton = Instance.new("TextButton")
    YamaButton.Size = UDim2.new(0, 180, 0, 32)
    YamaButton.Position = UDim2.new(0, 210, 0, 60)
    YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    YamaButton.TextColor3 = Color3.new(1,1,1)
    YamaButton.Font = Enum.Font.SourceSansBold
    YamaButton.TextSize = 16
    YamaButton.Text = "Auto Yama: OFF"
    YamaButton.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 150)
    LogsFrame.Position = UDim2.new(0, 10, 0, 100)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
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

    TushitaButton.MouseButton1Click:Connect(function()
        AutoTushita = not AutoTushita
        if AutoTushita then
            AutoYama = false
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            TushitaButton.Text = "Auto Tushita: ON"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            NoclipEnabled = true
            UpdateStatus("Фарм Tushita...")
        else
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            NoclipEnabled = false
            StopTween = true
            UpdateStatus("Остановлен")
        end
    end)

    YamaButton.MouseButton1Click:Connect(function()
        AutoYama = not AutoYama
        if AutoYama then
            AutoTushita = false
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            YamaButton.Text = "Auto Yama: ON"
            YamaButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            NoclipEnabled = true
            UpdateStatus("Фарм Yama...")
        else
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            NoclipEnabled = false
            StopTween = true
            UpdateStatus("Остановлен")
        end
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if AutoTushita then
                pcall(RunTushitaLogic)
            elseif AutoYama then
                pcall(RunYamaLogic)
            end
        end
    end)

    AddLog("GUI Auto Yama / Tushita загружен.")
end

CreateGui()
