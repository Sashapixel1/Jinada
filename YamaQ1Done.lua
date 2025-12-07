--========================================================
-- Auto Evil Trial (Yama / Alucard Fragment)
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
-- МОДУЛЬ CDKTrial (StartEvilTrial)
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

    -- Проверка прогресса Evil (не обязательно, но полезно для логов)
    Log("Проверяю прогресс триала Evil...")
    local okProgress, progress = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Evil")
    end)

    if okProgress then
        Log("CDKQuest Progress(Evil) = " .. tostring(progress))
    else
        Log("Ошибка при Progress(Evil): " .. tostring(progress))
    end

    task.wait(0.3)

    -- Стартуем триал
    Log("Пробую запустить StartTrial(Evil)...")
    local okStart, resStart = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Evil")
    end)

    if okStart then
        Log("✅ StartTrial(Evil) отправлен. Ответ: " .. tostring(resStart))
    else
        Log("❌ Ошибка при StartTrial(Evil): " .. tostring(resStart))
    end
end

---------------------
-- ФЛАГИ / СОСТОЯНИЕ
---------------------
local AutoEvilTrial = false
local CurrentStatus = "Idle"

local IsTeleporting = false
local StopTween     = false
local NoclipEnabled = false

local lastStartTry        = 0      -- антиспам StartTrial(Evil)
local StartTryCooldown    = 30     -- раз в 30 секунд

local lastTPLog           = ""     -- чтобы не спамить одинаковыми логами
local HaveAlucardFragment = false

---------------------
-- НАСТРОЙКИ
---------------------
local TeleportSpeed  = 300
-- Точка на Castle on the Sea (берём позицию возле Elite Hunter NPC,
-- её мы уже использовали в прошлых скриптах)
local CastleOnSeaCFrame = CFrame.new(-5418.892578125, 313.74130249023, -2826.2260742188)

---------------------
-- ЛОГИ / GUI
---------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame
local StatusLabel
local ToggleButton
local LogsText

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

---------------------
-- ANTI AFK
---------------------
spawn(function()
    while task.wait(60) do
        if AutoEvilTrial then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                AddLog("Anti-AFK: фейковый клик, чтобы не кикнуло.")
            end)
        end
    end
end)

---------------------
-- NOCLIP (чтобы не застревать)
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
-- ИНВЕНТАРЬ / ALCUARD FRAGMENT / YAMA
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
    local p = LocalPlayer
    if not p then return end

    if IsToolEquipped("Yama") then
        return
    end

    local char = p.Character or p.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local backpack = p:FindFirstChild("Backpack")
    local tool

    if backpack then
        tool = backpack:FindFirstChild("Yama")
    end
    if not tool then
        tool = char:FindFirstChild("Yama")
    end

    if tool then
        hum:UnequipTools()
        hum:EquipTool(tool)
        AddLog("⚔️ Экипирована Yama.")
    else
        if tick() - lastEquipFailLog > 5 then
            AddLog("⚠️ Не удалось найти Yama в Backpack/Character.")
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
    AddLog("HRP найден, продолжаю цикл триала (если включен).")
end)

---------------------
-- ОСНОВНАЯ ЛОГИКА ТРИАЛА
---------------------
local function RunEvilTrialLoop()
    -- 1. Проверяем Alucard Fragment
    local hasFrag, count = HasAlucardFragment()
    if hasFrag then
        if not HaveAlucardFragment then
            HaveAlucardFragment = true
            UpdateStatus("Alucard Fragment получен! (" .. tostring(count) .. ")")
            AddLog("🎉 Alucard Fragment найден в инвентаре. Скрипт прекращает активные действия.")
        end
        return  -- больше ничего не делаем
    end

    -- если фрагмента нет – продолжаем умирать
    HaveAlucardFragment = false
    UpdateStatus("Evil Trial: жду смерть с Yama на Castle on the Sea (Alucard Fragment ещё нет).")

    -- 2. Пробуем периодически запускать StartTrial(Evil)
    local now = tick()
    if now - lastStartTry >= StartTryCooldown then
        lastStartTry = now
        CDKTrialModule.StartEvilTrial(AddLog)
    end

    -- 3. Гарантируем, что Yama есть и экипнута
    BringYamaToBackpack()
    EquipYama()

    -- 4. Стоим на Castle on the Sea и ждём смерти
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

    -- дальше ничего не делаем, просто стоим и ждём пока нас убьют
end

---------------------
-- GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoEvilTrialGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 420, 0, 260)
    MainFrame.Position = UDim2.new(0, 40, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Title.Text = "Auto Evil Trial (Yama → Alucard Fragment)"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 16
    Title.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 22)
    StatusLabel.Position = UDim2.new(0, 10, 0, 30)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: " .. CurrentStatus
    StatusLabel.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 260, 0, 32)
    ToggleButton.Position = UDim2.new(0, 10, 0, 60)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Auto Evil Trial: OFF"
    ToggleButton.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 150)
    LogsFrame.Position = UDim2.new(0, 10, 0, 100)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
    LogsFrame.BorderSizePixel = 0
    LogsFrame.Parent = MainFrame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -4)
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 4, 0)
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
        AutoEvilTrial = not AutoEvilTrial
        if AutoEvilTrial then
            ToggleButton.Text = "Auto Evil Trial: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0,120,0)
            NoclipEnabled = true
            StopTween     = false
            HaveAlucardFragment = false
            UpdateStatus("Evil Trial активен: стартую триал, эквип Yama, жду смерть.")
            AddLog("Auto Evil Trial включён.")
            -- Однократный старт при включении
            CDKTrialModule.StartEvilTrial(AddLog)
        else
            ToggleButton.Text = "Auto Evil Trial: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled = false
            StopTween     = true
            UpdateStatus("Остановлен")
            AddLog("Auto Evil Trial выключен.")
        end
    end)

    AddLog("GUI Auto Evil Trial загружен.")
end

CreateGui()

---------------------
-- ОСНОВНОЙ ЦИКЛ
---------------------
spawn(function()
    while task.wait(0.5) do
        local ok, err = pcall(function()
            if AutoEvilTrial then
                RunEvilTrialLoop()
            end
        end)
        if not ok then
            AddLog("Ошибка в основном цикле: " .. tostring(err))
        end
    end
end)
