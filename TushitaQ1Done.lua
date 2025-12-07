-- Auto Tushita Quest1 (BoatQuest через Lux Boat Dealer)
-- Логика:
--   Для каждой из 3 точек:
--     - телепорт к координате
--     - поиск ближайшего "Luxury Boat Dealer"
--     - CommF_("GetUnlockables","BoatDealer")
--     - потом CommF_("CDKQuest","BoatQuest", npcModel)

------------------------------------------------
-- НАСТРОЙКИ
------------------------------------------------
local TeleportSpeed = 300 -- скорость полёта (stud/сек)

local QuestPoints = {
    CFrame.new(-9546.990234375, 21.139892578125, 4686.1142578125),          -- точка 1
    CFrame.new(-6120.0576171875, 16.455780029296875, -2250.697265625),      -- точка 2
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875),        -- точка 3
}

------------------------------------------------
-- СЕРВИСЫ / ПЕРЕМЕННЫЕ
------------------------------------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer       = Players.LocalPlayer
local CommF             = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local AutoTushitaQ1     = false
local IsTeleporting     = false
local StopTween         = false

------------------------------------------------
-- ЛОГИ + GUI
------------------------------------------------
local StatusLogs = {}
local MaxLogs    = 200

local ScreenGui, MainFrame, ToggleButton
local StatusLabel, LogsText

local function AddLog(msg)
    local ts = os.date("%H:%M:%S")
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
    if StatusLabel then
        StatusLabel.Text = "Статус: " .. text
    end
    AddLog("Статус: " .. text)
end

local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoTushitaQ1Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 520, 0, 280)
    MainFrame.Position = UDim2.new(0, 20, 0, 180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "Auto Tushita Quest1 (BoatQuest)"
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
    ToggleButton.Text = "Tushita Q1: OFF"
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
        AutoTushitaQ1 = not AutoTushitaQ1
        StopTween = not AutoTushitaQ1

        if AutoTushitaQ1 then
            ToggleButton.Text = "Tushita Q1: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            StopTween = false
            UpdateStatus("Запуск Tushita Quest1")
        else
            ToggleButton.Text = "Tushita Q1: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            UpdateStatus("Остановлен")
        end
    end)

    AddLog("GUI Auto Tushita Q1 загружен.")
end

------------------------------------------------
-- ТЕЛЕПОРТ
------------------------------------------------
local function TweenTo(targetCF, label)
    if not AutoTushitaQ1 or IsTeleporting then return end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")

    local dist = (hrp.Position - targetCF.Position).Magnitude
    local t = math.clamp(dist / TeleportSpeed, 0.5, 60)

    AddLog(string.format("Телепорт к %s (%.0f stud, t=%.1f)", label or "точке", dist, t))

    IsTeleporting = true
    StopTween = false

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = targetCF}
    )
    tween:Play()

    local start = tick()
    while tick() - start < t do
        if not AutoTushitaQ1 or StopTween then
            tween:Cancel()
            IsTeleporting = false
            AddLog("Телепорт прерван (OFF / StopTween).")
            return
        end

        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide = false

        RunService.Heartbeat:Wait()
    end

    tween:Cancel()
    hrp.CFrame = targetCF
    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
    hrp.CanCollide = false

    IsTeleporting = false
end

------------------------------------------------
-- ПОИСК LUXURY BOAT DEALER
------------------------------------------------
local function FindNearestLuxuryBoatDealer(maxDist)
    maxDist = maxDist or 200
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, best = nil, maxDist
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Luxury Boat Dealer" then
            local head = obj:FindFirstChild("HumanoidRootPart") or
                         obj:FindFirstChild("Head") or
                         obj:FindFirstChildWhichIsA("BasePart")
            if head then
                local d = (head.Position - hrp.Position).Magnitude
                if d < best then
                    best = d
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

------------------------------------------------
-- РАБОТА С ОДНИМ ДИЛЕРОМ
------------------------------------------------
local function HandleDealerAtPoint(index)
    UpdateStatus("Tushita Q1: точка "..index)
    TweenTo(QuestPoints[index], "точка "..index)
    if not AutoTushitaQ1 or StopTween then return end

    local npc = FindNearestLuxuryBoatDealer(150)
    if not npc then
        AddLog("❌ Luxury Boat Dealer не найден в радиусе 150 stud у точки "..index..".")
        return
    end

    AddLog("Нашёл Luxury Boat Dealer у точки "..index..". Посылаю GetUnlockables / BoatQuest.")

    -- подойдём вплотную (как при нормальном диалоге)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local head = npc:FindFirstChild("HumanoidRootPart") or
                 npc:FindFirstChild("Head") or
                 npc:FindFirstChildWhichIsA("BasePart")

    if head then
        hrp.CFrame = head.CFrame * CFrame.new(0, 0, -3)
    end

    -- шаг 1: GetUnlockables / BoatDealer
    local ok1, res1 = pcall(function()
        return CommF:InvokeServer("GetUnlockables", "BoatDealer")
    end)
    if ok1 then
        AddLog("✅ CommF_(\"GetUnlockables\",\"BoatDealer\") => "..tostring(res1))
    else
        AddLog("❌ Ошибка GetUnlockables/BoatDealer: "..tostring(res1))
    end

    task.wait(0.3)

    -- шаг 2: CDKQuest / BoatQuest / npc
    local ok2, res2 = pcall(function()
        return CommF:InvokeServer("CDKQuest", "BoatQuest", npc)
    end)
    if ok2 then
        AddLog("✅ CommF_(\"CDKQuest\",\"BoatQuest\", npc) => "..tostring(res2))
    else
        AddLog("❌ Ошибка CDKQuest/BoatQuest: "..tostring(res2))
    end

    local tEnd = tick() + 1.0
    while tick() < tEnd do
        if not AutoTushitaQ1 or StopTween then break end
        task.wait(0.1)
    end
end

------------------------------------------------
-- ОСНОВНОЙ ЦИКЛ
------------------------------------------------
spawn(function()
    while task.wait(0.4) do
        if AutoTushitaQ1 then
            local ok, err = pcall(function()
                for idx = 1, #QuestPoints do
                    if not AutoTushitaQ1 then break end
                    HandleDealerAtPoint(idx)
                end
                if AutoTushitaQ1 then
                    AddLog("Круг по трём дилерам завершён, повторяю...")
                end
            end)
            if not ok then
                AddLog("⚠️ Ошибка в основном цикле: "..tostring(err))
            end
        end
    end
end)

------------------------------------------------
-- СТАРТ
------------------------------------------------
CreateGui()
