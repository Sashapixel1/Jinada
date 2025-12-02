-- Auto Cursed Dual Katana — простая версия без Rayfield
-- Версия 2.2 — без телепорта к CDK altar, с логом ответа StartQuest

---------------------
-- ПЕРЕМЕННЫЕ
---------------------
local AutoCursedKatana = false
local CurrentStatus = "Idle"
local StartTime = os.time()
local TeleportSpeed = 150
local StopTween = false
local IsTeleporting = false

---------------------
-- СЕРВИСЫ
---------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- ЛОКАЦИИ (используются только для Tushita/Yama)
---------------------
local Locations = {
    Tushita = CFrame.new(-10238.8759765625, 389.7912902832, -9549.7939453125),
    Yama    = CFrame.new(-9489.2168, 142.130066, 5567.14697),
}

---------------------
-- ЛОГИ
---------------------
local StatusLogs = {}
local MaxLogs = 60

local ScreenGui, MainFrame, ToggleButton, StatusLabel, UptimeLabel, SpeedLabel, LogsFrame, LogsText

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
-- ПРОВЕРКА ИНВЕНТАРЯ
---------------------
local function HasItemInInventory(itemName)
    local player = LocalPlayer
    if not player then return false end

    -- Backpack
    local backpack = player:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(itemName) then
        return true
    end

    -- В руках
    local char = player.Character
    if char and char:FindFirstChild(itemName) then
        return true
    end

    -- Через getInventory
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
    else
        if not ok then
            AddLog("Ошибка getInventory: "..tostring(invData))
        end
    end

    return false
end

local function HasTushita() return HasItemInInventory("Tushita") end
local function HasYama()    return HasItemInInventory("Yama") end
local function HasCDK()
    return HasItemInInventory("Cursed Dual Katana")
        or HasItemInInventory("Cursed Dual Katana [CDK]")
end

local function CheckCDKQuestProgress()
    local ok, result = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress")
    end)

    if ok and type(result) == "table" then
        return result
    end
    if not ok then
        AddLog("Ошибка CDKQuest Progress: "..tostring(result))
    end
    return nil
end

local function TryLoadItem(itemName)
    local ok, res = pcall(function()
        return remote:InvokeServer("LoadItem", itemName)
    end)

    if ok then
        wait(1)
        return HasItemInInventory(itemName)
    end

    AddLog("Ошибка LoadItem("..itemName.."): "..tostring(res))
    return false
end

---------------------
-- ТЕЛЕПОРТ (для Tushita/Yama)
---------------------
local function SimpleTeleport(targetCFrame, locationName)
    if IsTeleporting then
        AddLog("Уже выполняется телепорт, дождитесь завершения")
        return false
    end

    IsTeleporting = true
    StopTween = false

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        AddLog("Ошибка: Персонаж не найден")
        IsTeleporting = false
        return false
    end

    local hrp = char.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude

    AddLog(string.format("Телепорт к %s (%.0f юнитов)", locationName, distance))

    local travelTime = distance / TeleportSpeed
    if travelTime < 5 then travelTime = 5 end
    if travelTime > 120 then travelTime = 120 end

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
            AddLog("Телепорт отменён")
            IsTeleporting = false
            return false
        end
        wait(0.5)
    end

    tween:Cancel()
    hrp.CFrame = targetCFrame
    AddLog("Телепорт завершён")
    IsTeleporting = false
    return true
end

local function CancelTeleport()
    StopTween = true
end

---------------------
-- ФАРМ TUSHITA
---------------------
local function FarmTushita()
    UpdateStatus("Добыча Tushita...")

    if HasTushita() then
        AddLog("Уже есть Tushita")
        return true
    end

    if TryLoadItem("Tushita") then
        AddLog("Tushita загружена из хранилища")
        return true
    end

    if not SimpleTeleport(Locations.Tushita, "Tushita") then
        return false
    end

    wait(2)
    AddLog("Запуск испытания Tushita...")

    local ok, res = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Tushita")
    end)

    if not ok then
        AddLog("Ошибка StartTrial Tushita: "..tostring(res))
        return false
    end

    UpdateStatus("Испытание Tushita...")
    for i = 1, 120 do
        if HasTushita() then
            AddLog("Получена Tushita!")
            return true
        end
        wait(1)
    end

    return HasTushita()
end

---------------------
-- ФАРМ YAMA
---------------------
local function FarmYama()
    UpdateStatus("Добыча Yama...")

    if HasYama() then
        AddLog("Уже есть Yama")
        return true
    end

    if TryLoadItem("Yama") then
        AddLog("Yama загружена из хранилища")
        return true
    end

    if not SimpleTeleport(Locations.Yama, "Yama") then
        return false
    end

    wait(2)
    AddLog("Запуск испытания Yama...")

    local ok, res = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Yama")
    end)

    if not ok then
        AddLog("Ошибка StartTrial Yama: "..tostring(res))
        return false
    end

    UpdateStatus("Испытание Yama...")
    for i = 1, 120 do
        if HasYama() then
            AddLog("Получена Yama!")
            return true
        end
        wait(1)
    end

    return HasYama()
end

---------------------
-- ФАРМ CDK (БЕЗ ТЕЛЕПОРТА!)
---------------------
local function FarmCDK()
    UpdateStatus("Добыча CDK...")

    if not (HasTushita() and HasYama()) then
        AddLog("Нужны обе катаны: Tushita и Yama")
        AddLog("Tushita: "..tostring(HasTushita()).." | Yama: "..tostring(HasYama()))
        return false
    end

    if HasCDK() then
        AddLog("Уже есть Cursed Dual Katana")
        return true
    end

    AddLog("Запуск квеста CDK (без телепорта)...")

    -- для логов выводим и прогресс, и результат StartQuest
    local progOk, progRes = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "CursedKatana")
    end)
    AddLog("Ответ CDKQuest Progress: "..tostring(progOk and progRes or progRes))

    local ok, res = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartQuest", "CursedKatana")
    end)

    if not ok then
        AddLog("Ошибка StartQuest CDK: "..tostring(res))
        return false
    else
        AddLog("Ответ StartQuest CDK: "..tostring(res))
    end

    UpdateStatus("Квест CDK...")
    for i = 1, 300 do
        if HasCDK() then
            AddLog("ПОЛУЧЕНА CURSED DUAL KATANA!")
            return true
        end
        wait(1)
    end

    return HasCDK()
end

---------------------
-- ПРОСТОЙ GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoCDKGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 320, 0, 260)
    MainFrame.Position = UDim2.new(0, 20, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "Auto Cursed Dual Katana"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 140, 0, 30)
    ToggleButton.Position = UDim2.new(0, 10, 0, 30)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Авто CDK: OFF"
    ToggleButton.Parent = MainFrame

    SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(0, 150, 0, 20)
    SpeedLabel.Position = UDim2.new(0, 170, 0, 35)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.TextColor3 = Color3.new(1,1,1)
    SpeedLabel.Font = Enum.Font.SourceSans
    SpeedLabel.TextSize = 14
    SpeedLabel.TextXAlignment = Enum.TextX_ALIGNMENT.Left
    SpeedLabel.Text = "Скорость: "..TeleportSpeed
    SpeedLabel.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 20)
    StatusLabel.Position = UDim2.new(0, 10, 0, 65)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextX_ALIGNMENT.Left
    StatusLabel.Text = "Статус: "..CurrentStatus
    StatusLabel.Parent = MainFrame

    UptimeLabel = Instance.new("TextLabel")
    UptimeLabel.Size = UDim2.new(1, -20, 0, 20)
    UptimeLabel.Position = UDim2.new(0, 10, 0, 85)
    UptimeLabel.BackgroundTransparency = 1
    UptimeLabel.TextColor3 = Color3.new(1,1,1)
    UptimeLabel.Font = Enum.Font.SourceSans
    UptimeLabel.TextSize = 14
    UptimeLabel.TextXAlignment = Enum.TextX_ALIGNMENT.Left
    UptimeLabel.Text = "Время работы: 00:00:00"
    UptimeLabel.Parent = MainFrame

    LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 140)
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
    LogsText.TextXAlignment = Enum.TextX_ALIGNMENT.Left
    LogsText.TextYAlignment = Enum.TextY_ALIGNMENT.Top
    LogsText.TextWrapped = false
    LogsText.Text = ""
    LogsText.Parent = scroll

    ToggleButton.MouseButton1Click:Connect(function()
        AutoCursedKatana = not AutoCursedKatana
        if AutoCursedKatana then
            StartTime = os.time()
            ToggleButton.Text = "Авто CDK: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            AddLog("Автофарм CDK включен")
            UpdateStatus("Запуск...")
        else
            ToggleButton.Text = "Авто CDK: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            AddLog("Автофарм CDK выключен")
            UpdateStatus("Остановлен")
            CancelTeleport()
        end
    end)
end

---------------------
-- ЛУПЫ
---------------------
CreateGui()
AddLog("Скрипт CDK загружен. Нажми кнопку 'Авто CDK'.")

spawn(function()
    while wait(1) do
        if UptimeLabel then
            UptimeLabel.Text = "Время работы: "..GetUptime()
        end
        if SpeedLabel then
            SpeedLabel.Text = "Скорость: "..TeleportSpeed
        end
    end
end)

spawn(function()
    while wait(2) do
        if AutoCursedKatana then
            pcall(function()
                if HasCDK() then
                    AddLog("Уже есть Cursed Dual Katana — остановка.")
                    AutoCursedKatana = false
                    if ToggleButton then
                        ToggleButton.Text = "Авто CDK: OFF"
                        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    end
                    UpdateStatus("Завершено")
                    return
                end

                AddLog("=== НАЧАЛО ЦИКЛА CDK ===")

                if not HasTushita() then
                    AddLog("--- ФАРМ TUSHITA ---")
                    if not FarmTushita() then
                        AddLog("Не удалось получить Tushita")
                        UpdateStatus("Ошибка Tushita")
                        return
                    end
                else
                    AddLog("Tushita уже есть")
                end

                if not AutoCursedKatana then return end

                if not HasYama() then
                    AddLog("--- ФАРМ YAMA ---")
                    if not FarmYama() then
                        AddLog("Не удалось получить Yama")
                        UpdateStatus("Ошибка Yama")
                        return
                    end
                else
                    AddLog("Yama уже есть")
                end

                if not AutoCursedKatana then return end

                AddLog("--- ФАРМ CDK ---")
                local got = FarmCDK()
                if got then
                    AddLog("CURSED DUAL KATANA ПОЛУЧЕНА!")
                    AutoCursedKatana = false
                    if ToggleButton then
                        ToggleButton.Text = "Авто CDK: OFF"
                        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    end
                    UpdateStatus("Завершено")
                else
                    AddLog("Не удалось получить CDK — повтор через цикл")
                    UpdateStatus("Повтор...")
                end
            end)
        end
    end
end)
