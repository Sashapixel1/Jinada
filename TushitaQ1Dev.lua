--========================================
-- Auto Tushita Quest1
-- Летает по 3 точкам для квеста Tushita:
--  1) -9546.99, 21.13, 4686.11
--  2) -6120.05, 16.45, -2250.69
--  3) -9533.23, 7.25, -8372.69
--========================================

-----------------------
-- НАСТРОЙКИ
-----------------------
local TeleportSpeed = 300  -- скорость полёта (стадов/сек)

-----------------------
-- ПЕРЕМЕННЫЕ
-----------------------
local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")

local LocalPlayer   = Players.LocalPlayer

local AutoTushitaQ1 = false
local IsTeleporting = false
local NoclipEnabled = false
local IsRunningQ1   = false

local CurrentStatus = "Idle"
local StartTime     = os.time()

-- точки маршрута квеста
local TQ1Points = {
    CFrame.new(-9546.990234375, 21.139892578125, 4686.1142578125),
    CFrame.new(-6120.0576171875, 16.455780029296875, -2250.697265625),
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875)
}

-----------------------
-- ЛОГИ / GUI
-----------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame, ToggleButton
local StatusLabel, UptimeLabel, LogsText

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

local function UpdateStatus(text)
    CurrentStatus = text
    AddLog("Статус: " .. text)
    if StatusLabel then
        StatusLabel.Text = "Статус: " .. text
    end
end

local function GetUptime()
    local t = os.time() - StartTime
    local h = math.floor(t / 3600)
    local m = math.floor((t % 3600) / 60)
    local s = t % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

-----------------------
-- NOCLIP
-----------------------
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

-----------------------
-- ТЕЛЕПОРТ
-----------------------
local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting then return end
    IsTeleporting = true

    local char = LocalPlayer.Character
    if not char then
        IsTeleporting = false
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        IsTeleporting = false
        return
    end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    AddLog(string.format("Телепорт к %s (%.0f stud)", label or "цели", distance))

    local travelTime = distance / TeleportSpeed
    if travelTime < 0.5 then travelTime = 0.5 end
    if travelTime > 60 then travelTime = 60 end

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )

    tween:Play()

    local start = tick()
    while tick() - start < travelTime do
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
    AddLog("Персонаж возрождён, жду HRP...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден. Можно продолжать Tushita Quest1.")
end)

-----------------------
-- ЛОГИКА TUSHITA QUEST1
-----------------------
local function RunTushitaQ1Loop()
    if IsRunningQ1 then return end
    IsRunningQ1 = true
    AddLog("Tushita Quest1: цикл запущен.")

    while AutoTushitaQ1 do
        for idx, cf in ipairs(TQ1Points) do
            if not AutoTushitaQ1 then break end
            UpdateStatus("Tushita Quest1: точка "..idx.."/"..#TQ1Points)
            SimpleTeleport(cf, "TushitaQ1 Point "..idx)
            -- ожидание 5 секунд на точке (как в исходном коде)
            local waitEnd = tick() + 5
            while AutoTushitaQ1 and tick() < waitEnd do
                task.wait(0.1)
            end
        end
    end

    UpdateStatus("Остановлен")
    IsRunningQ1 = false
    AddLog("Tushita Quest1: цикл остановлен.")
end

-----------------------
-- GUI
-----------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TushitaQ1Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 420, 0, 260)
    MainFrame.Position = UDim2.new(0, 40, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Title.Text = "Auto Tushita Quest1"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 260, 0, 30)
    ToggleButton.Position = UDim2.new(0, 10, 0, 30)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Auto Tushita Q1: OFF"
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
    LogsFrame.Size = UDim2.new(1, -20, 0, 130)
    LogsFrame.Position = UDim2.new(0, 10, 0, 115)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    LogsFrame.BorderSizePixel = 0
    LogsFrame.Parent = MainFrame

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -4, 1, -4)
    Scroll.Position = UDim2.new(0, 2, 0, 2)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.CanvasSize = UDim2.new(0,0,5,0)
    Scroll.ScrollBarThickness = 4
    Scroll.Parent = LogsFrame

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
    LogsText.Parent = Scroll

    ToggleButton.MouseButton1Click:Connect(function()
        AutoTushitaQ1 = not AutoTushitaQ1
        if AutoTushitaQ1 then
            StartTime = os.time()
            ToggleButton.Text = "Auto Tushita Q1: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            NoclipEnabled = true
            UpdateStatus("Tushita Quest1: запущен")
            AddLog("Auto Tushita Quest1 включен (noclip ON, speed "..TeleportSpeed..")")
            task.spawn(RunTushitaQ1Loop)
        else
            ToggleButton.Text = "Auto Tushita Q1: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            NoclipEnabled = false
            UpdateStatus("Остановлен")
            AddLog("Auto Tushita Quest1 выключен (noclip OFF)")
        end
    end)
end

-----------------------
-- ЗАПУСК GUI + ТАЙМЕРА
-----------------------
CreateGui()
AddLog("Auto Tushita Quest1 загружен. Нажми кнопку, когда будешь готов.")

task.spawn(function()
    while task.wait(1) do
        if UptimeLabel then
            UptimeLabel.Text = "Время работы: " .. GetUptime()
        end
    end
end)
