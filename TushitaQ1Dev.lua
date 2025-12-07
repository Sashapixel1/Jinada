-- Auto Tushita Quest1: 3 Luxury Boat Dealer
-- Для каждого дилера: открыть диалог, 3x Option3 (Next), 1x Option1 (Pardon me)

------------------------------------------------
-- НАСТРОЙКИ / ТОЧКИ
------------------------------------------------
local TeleportSpeed = 300 -- скорость полёта (stud/sec)

-- Координаты трёх Luxury Boat Dealer / точек квеста
local QuestPoints = {
    CFrame.new(-9546.990234375, 21.139892578125, 4686.1142578125),
    CFrame.new(-6120.0576171875, 16.455780029296875, -2250.697265625),
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875),
}

------------------------------------------------
-- СЕРВИСЫ / ПЕРЕМЕННЫЕ
------------------------------------------------
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer      = Players.LocalPlayer

local AutoTushitaQ1    = false
local IsTeleporting    = false
local StopTween        = false

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
    title.Text = "Auto Tushita Quest1 (3xOption3 + 1xOption1)"
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
-- ПОИСК Luxury Boat Dealer + ОТКРЫТИЕ ДИАЛОГА
------------------------------------------------
local function FindNearestLuxuryBoatDealer(maxDist)
    maxDist = maxDist or 200
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, best = nil, maxDist
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Luxury Boat Dealer" then
            local head = obj:FindFirstChild("HumanoidRootPart") or obj:FindChild("Head") or obj:FindFirstChildWhichIsA("BasePart")
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

local function TryOpenDialogue(npc)
    if not npc then
        AddLog("❌ Luxury Boat Dealer не найден рядом.")
        return
    end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")

    local head = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head") or npc:FindFirstChildWhichIsA("BasePart")
    if head then
        hrp.CFrame = head.CFrame * CFrame.new(0, 0, -3)
    end

    AddLog("Нашёл Luxury Boat Dealer, пробую открыть диалог.")

    -- ProximityPrompt
    pcall(function()
        if head then
            local prompt = head:FindFirstChildOfClass("ProximityPrompt")
            if prompt and fireproximityprompt then
                AddLog(" fireproximityprompt(prompt)")
                fireproximityprompt(prompt, 2)
            end
        end
    end)

    -- ClickDetector
    pcall(function()
        if head then
            local cd = head:FindFirstChildOfClass("ClickDetector")
            if cd and fireclickdetector then
                AddLog(" fireclickdetector(ClickDetector)")
                fireclickdetector(cd)
            end
        end
    end)
end

------------------------------------------------
-- НАЖАТИЕ Option3 / Option1 В ДИАЛОГЕ
------------------------------------------------
local function ClickDialogueOption(optionName, times)
    times = times or 1
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    local main = pg:FindFirstChild("Main")
    local dialogue = main and main:FindFirstChild("Dialogue")
    if not dialogue then
        AddLog("Диалог не найден (Main.Dialogue отсутствует).")
        return
    end

    local btn = dialogue:FindFirstChild(optionName)
    if not (btn and btn:IsA("TextButton")) then
        AddLog("Кнопка "..optionName.." не найдена в диалоге.")
        return
    end

    for i = 1, times do
        AddLog("Нажимаю "..optionName.." (#"..i..")")
        pcall(function()
            btn:Activate()
        end)
        task.wait(0.25)
    end
end

local function HandleDealerAtCurrentPoint(index)
    AddLog("Tushita Q1: точка "..index.." — ищу Luxury Boat Dealer.")
    local npc = FindNearestLuxuryBoatDealer(120)
    if not npc then
        AddLog("❌ Dealer не найден в радиусе 120 stud.")
        return
    end

    TryOpenDialogue(npc)

    -- ждём появления GUI диалога
    local appeared = false
    for _ = 1, 20 do -- до ~2 секунд
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local main = pg:FindFirstChild("Main")
            local dialogue = main and main:FindFirstChild("Dialogue")
            if dialogue then
                appeared = true
                break
            end
        end
        task.wait(0.1)
    end

    if not appeared then
        AddLog("Диалог так и не появился (Main.Dialogue).")
        return
    end

    -- 3 раза Option3 (Next)
    ClickDialogueOption("Option3", 3)
    -- 1 раз Option1 (Pardon me)
    ClickDialogueOption("Option1", 1)

    AddLog("Последовательность 3xOption3 + 1xOption1 выполнена для точки "..index..".")
end

------------------------------------------------
-- ОСНОВНОЙ ЦИКЛ
------------------------------------------------
spawn(function()
    while task.wait(0.4) do
        if AutoTushitaQ1 then
            pcall(function()
                for idx, cf in ipairs(QuestPoints) do
                    if not AutoTushitaQ1 then break end

                    UpdateStatus("Tushita Q1: точка "..idx)
                    TweenTo(cf, "точка "..idx)
                    if not AutoTushitaQ1 or StopTween then break end

                    HandleDealerAtCurrentPoint(idx)

                    -- небольшая пауза после работы с дилером / точкой
                    local tEnd = tick() + 1.0
                    while tick() < tEnd do
                        if not AutoTushitaQ1 or StopTween then break end
                        task.wait(0.1)
                    end
                end

                if AutoTushitaQ1 then
                    AddLog("Круг по трём дилерам завершён, повторяю...")
                else
                    AddLog("Tushita Q1 остановлен пользователем.")
                end
            end)
        end
    end
end)

------------------------------------------------
-- СТАРТ
------------------------------------------------
CreateGui()
