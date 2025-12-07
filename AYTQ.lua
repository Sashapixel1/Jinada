--[[
    Auto Yama / Elite Hunter (патруль островов, без завязки на QuestTitle)
    - Берёт / обновляет квест у Elite Hunter (раз в 60 сек)
    - Если прогресс < 30:
        * ищет Diablo / Deandre / Urban в Workspace.Enemies
        * если нашёл — атакует
        * если не нашёл — патрулирует Port Town / Hydra / Great Tree / Floating Turtle
    - Если прогресс >= 30:
        * летит к водопаду и кликает по SealedKatana, чтобы взять Yama
    - GUI: кнопка ON/OFF + лог-панель
]]

--------------------------------
-- НАСТРОЙКИ
--------------------------------
local WeaponName    = "Godhuman"           -- твой основной дамагер
local TeleportSpeed = 300                  -- скорость полёта
local HoverOffset   = CFrame.new(0, 10, -3) -- позиция над элиткой во время боя

--------------------------------
-- СОСТОЯНИЕ
--------------------------------
local AutoYama      = false
local CurrentStatus = "Idle"

--------------------------------
-- СЕРВИСЫ
--------------------------------
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local RunService         = game:GetService("RunService")
local VirtualInputManager= game:GetService("VirtualInputManager")

local LocalPlayer        = Players.LocalPlayer
local remote             = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

--------------------------------
-- NET MODULE (fast attack)
--------------------------------
local modules        = ReplicatedStorage:WaitForChild("Modules")
local net            = modules:WaitForChild("Net")
local RegisterAttack = net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = net:WaitForChild("RE/RegisterHit")

local AttackModule   = {}

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

--------------------------------
-- ЛОГИ / GUI
--------------------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame
local ToggleYamaButton
local StatusLabel, LogsText

local function AddLog(msg)
    local timestamp = os.date("%H:%M:%S")
    local entry = "[" .. timestamp .. "] " .. tostring(msg)

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
    AddLog("Статус: " .. newStatus)
    if StatusLabel then
        StatusLabel.Text = "Статус: " .. newStatus
    end
end

--------------------------------
-- Noclip
--------------------------------
local NoclipEnabled = false

task.spawn(function()
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

--------------------------------
-- ХАКИ / ЭКИП
--------------------------------
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

    local p    = LocalPlayer
    local char = p.Character or p.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local nameLower = string.lower(name)
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

    local toolFound
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

--------------------------------
-- ТЕЛЕПОРТ
--------------------------------
local IsTeleporting = false
local StopTween     = false

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
    AddLog(string.format("Телепорт к %s (%.0f stud)", label or "цели", distance))

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

        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide             = false

        task.wait(0.2)
    end

    tween:Cancel()
    local c = LocalPlayer.Character
    hrp = c and c:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame                 = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity= Vector3.new(0,0,0)
        hrp.CanCollide             = false
    end

    IsTeleporting = false
end

-- Фикс после смерти
LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = false
    AddLog("Персонаж возрождён, жду HRP...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, фарм можно продолжать.")
end)

--------------------------------
-- ЭЛИТКИ + ПАТРУЛЬ ОСТРОВОВ
--------------------------------
local EliteNames = {
    Diablo  = true,
    Deandre = true,
    Urban   = true,
}

local EliteIslands = {
    {
        name   = "Port Town",
        cframe = CFrame.new(-290.73767089844, 6.72995281219, 5343.5537109375),
    },
    {
        name   = "Hydra Island",
        cframe = CFrame.new(5291.24951171875, 1005.443359375, 393.7624206542969),
    },
    {
        name   = "Great Tree",
        cframe = CFrame.new(2681.2736816406, 1682.8092041016, -7190.9853515625),
    },
    {
        name   = "Floating Turtle",
        cframe = CFrame.new(-13274.528320313, 531.82073974609, -7579.22265625),
    },
}

local EliteIslandIndex = 1
local LastIslandHop    = 0
local IslandHopDelay   = 12 -- сек между прыжками по островам

local function FindEliteInWorkspace()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    for _, mob in ipairs(enemies:GetChildren()) do
        if mob:IsA("Model") and EliteNames[mob.Name] then
            local hum = mob:FindFirstChild("Humanoid")
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                return mob, hum, hrp
            end
        end
    end
    return nil
end

local function PatrolEliteIslands()
    if tick() - LastIslandHop < IslandHopDelay then
        return
    end
    LastIslandHop = tick()

    local isl = EliteIslands[EliteIslandIndex]
    EliteIslandIndex = EliteIslandIndex + 1
    if EliteIslandIndex > #EliteIslands then
        EliteIslandIndex = 1
    end

    if isl and isl.cframe then
        AddLog(("Yama: патруль, лечу на %s."):format(isl.name))
        SimpleTeleport(isl.cframe, "Патруль элитки: " .. isl.name)
    end
end

--------------------------------
-- ЧТЕНИЕ QuestTitle (только для логов)
--------------------------------
local function GetQuestTitle()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return "" end

    local main = pg:FindFirstChild("Main")
    if not main then return "" end

    local questGui = main:FindFirstChild("Quest")
    if not questGui then return "" end

    local cont = questGui:FindFirstChild("Container")
    if not cont then return "" end

    local label = cont:FindFirstChild("QuestTitle")
    if not label or not label:IsA("TextLabel") then return "" end

    return label.Text or ""
end

--------------------------------
-- ОСНОВНАЯ ЛОГИКА Yama
--------------------------------
_G._LastEliteQuestRequest = _G._LastEliteQuestRequest or 0

local function RunYamaLogic()
    if not AutoYama then return end

    -- 1) прогресс EliteHunter
    local okProg, progress = pcall(function()
        return remote:InvokeServer("EliteHunter", "Progress")
    end)
    if not okProg then progress = 0 end

    -- 2) если 30/30 — открываем водопад и пытаемся взять Yama
    if progress >= 30 then
        UpdateStatus("Yama: прогресс 30/30, пробую открыть водопад.")
        AddLog("Yama: прогресс Elite Hunter = " .. tostring(progress) .. "/30.")

        local map = Workspace:FindFirstChild("Map")
        local waterfall = map and map:FindFirstChild("Waterfall")
        local sealed = waterfall and waterfall:FindFirstChild("SealedKatana")
        local handle = sealed and sealed:FindFirstChild("Handle")
        local click  = handle and handle:FindFirstChild("ClickDetector")

        if handle and click then
            SimpleTeleport(handle.CFrame * CFrame.new(0, 3, 6), "Waterfall / Yama")
            task.wait(0.5)
            pcall(function()
                fireclickdetector(click)
            end)
        else
            AddLog("Yama: не нашёл SealedKatana в Waterfall, проверь карту.")
        end
        return
    end

    -- 3) пытаемся найти элитку в мире
    local boss, hum, hrp = FindEliteInWorkspace()

    if boss and hum and hrp then
        local qTitle = GetQuestTitle()
        if qTitle ~= "" then
            AddLog("Yama: квест = '" .. qTitle .. "'. Босс найден: " .. boss.Name)
        else
            AddLog("Yama: элитка найдена: " .. boss.Name .. " (QuestTitle не прочитан).")
        end
        UpdateStatus("Yama: элитка '" .. boss.Name .. "', атакую.")

        local fightDeadline = tick() + 90

        while AutoYama and hum.Health > 0 and boss.Parent and tick() < fightDeadline do
            local char   = LocalPlayer.Character
            local chrHrp = char and char:FindFirstChild("HumanoidRootPart")
            if not char or not chrHrp then break end

            chrHrp.CFrame                 = hrp.CFrame * HoverOffset
            chrHrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            chrHrp.AssemblyAngularVelocity= Vector3.new(0,0,0)
            chrHrp.CanCollide             = false

            hrp.CanCollide = false

            AutoHaki()
            EquipToolByName(WeaponName)
            AttackModule:AttackEnemyModel(boss)

            RunService.Heartbeat:Wait()
        end

        if hum.Health <= 0 or not boss.Parent then
            AddLog("Yama: элитка '" .. boss.Name .. "' убита.")
        else
            AddLog("Yama: бой с элиткой прерван или вышел по таймеру.")
        end

        return
    end

    -- 4) элитки нет в мире — патрулируем острова и периодически жмём EliteHunter
    local qTitle = GetQuestTitle()
    if qTitle ~= "" then
        UpdateStatus("Yama: квест '" .. qTitle .. "', элитка не найдена, патрулирую острова.")
    else
        UpdateStatus("Yama: квест на элиту не виден, патрулирую острова и жду откат квеста.")
    end

    if tick() - _G._LastEliteQuestRequest > 60 then
        _G._LastEliteQuestRequest = tick()
        AddLog("Yama: отправляю запрос EliteHunter (новый / повторный квест).")
        pcall(function()
            remote:InvokeServer("EliteHunter")
        end)
    end

    PatrolEliteIslands()
end

--------------------------------
-- GUI
--------------------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaEliteGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 600, 0, 280)
    MainFrame.Position = UDim2.new(0, 40, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 26)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Title.Text = "Auto Yama / Elite Hunter (патруль островов)"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.Parent = MainFrame

    ToggleYamaButton = Instance.new("TextButton")
    ToggleYamaButton.Size = UDim2.new(0, 260, 0, 32)
    ToggleYamaButton.Position = UDim2.new(0, 10, 0, 34)
    ToggleYamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleYamaButton.TextColor3 = Color3.new(1,1,1)
    ToggleYamaButton.Font = Enum.Font.SourceSansBold
    ToggleYamaButton.TextSize = 16
    ToggleYamaButton.Text = "Auto Yama: OFF"
    ToggleYamaButton.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 22)
    StatusLabel.Position = UDim2.new(0, 10, 0, 70)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: " .. CurrentStatus
    StatusLabel.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 190)
    LogsFrame.Position = UDim2.new(0, 10, 0, 90)
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

    ToggleYamaButton.MouseButton1Click:Connect(function()
        AutoYama = not AutoYama
        if AutoYama then
            ToggleYamaButton.Text = "Auto Yama: ON"
            ToggleYamaButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            NoclipEnabled = true
            UpdateStatus("Фарм Yama / Elite Hunter.")
            AddLog("AutoYama включен.")
        else
            ToggleYamaButton.Text = "Auto Yama: OFF"
            ToggleYamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            NoclipEnabled = false
            StopTween = true
            UpdateStatus("Остановлен")
            AddLog("AutoYama выключен пользователем.")
        end
    end)
end

--------------------------------
-- ЗАПУСК
--------------------------------
CreateGui()
AddLog("Auto Yama / Elite Hunter загружен. Включай кнопку в 3-м море (Castle on the Sea / элитки).")

task.spawn(function()
    while task.wait(0.7) do
        if AutoYama then
            local ok, err = pcall(RunYamaLogic)
            if not ok then
                AddLog("Ошибка в цикле AutoYama: " .. tostring(err))
            end
        end
    end
end)
