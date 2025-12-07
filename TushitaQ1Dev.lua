-- Tushita Quest 1 + Luxury Boat Dealer диалог + GUI + логи
-- 3 точки квеста, на первой точке общаемся с Luxury Boat Dealer:
-- 3 раза "Next", затем "Pardon me".
-- Телепорты останавливаются сразу при OFF.

------------------------
-- НАСТРОЙКИ
------------------------
local TeleportSpeed = 300  -- скорость полёта (stud/sec)

-- точки квеста (как в исходном коде)
local QuestPoints = {
    CFrame.new(-9546.990234375, 21.139892578125, 4686.1142578125),            -- Luxury Boat Dealer
    CFrame.new(-6120.0576171875, 16.455780029296875, -2250.697265625),
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875),
}

------------------------
-- СЕРВИСЫ / ПЕРЕМЕННЫЕ
------------------------
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer      = Players.LocalPlayer
local CommF            = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local AutoTushitaQ1    = false
local IsTeleporting    = false
local StopTween        = false

------------------------
-- ЛОГИ / GUI
------------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame, ToggleButton
local StatusLabel, LogsText

local function AddLog(msg)
    local ts = os.date("%H:%M:%S")
    local line = "[" .. ts .. "] " .. tostring(msg)
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

------------------------
-- GUI
------------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TushitaQuest1Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 380, 0, 260)
    MainFrame.Position = UDim2.new(0, 20, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "Auto Tushita Quest1 (Luxury Boat Dealer)"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 240, 0, 30)
    ToggleButton.Position = UDim2.new(0, 10, 0, 30)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Tushita Q1: OFF"
    ToggleButton.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 20)
    StatusLabel.Position = UDim2.new(0, 10, 0, 65)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: Остановлен"
    StatusLabel.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 150)
    LogsFrame.Position = UDim2.new(0, 10, 0, 95)
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
        StopTween = not AutoTushitaQ1  -- при выключении сразу рвём текущий твинг

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

    AddLog("GUI Tushita Quest1 загружен.")
end

------------------------
-- ТЕЛЕПОРТ
------------------------
local function TweenTo(targetCF, label)
    if not AutoTushitaQ1 or IsTeleporting then return end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

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

------------------------
-- ПОИСК NPC Luxury Boat Dealer
------------------------
local function FindLuxuryBoatDealer()
    local candidate
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Luxury Boat Dealer" then
            candidate = obj
            break
        end
    end
    return candidate
end

------------------------
-- ПОПЫТКИ ОТКРЫТЬ ДИАЛОГ
------------------------
local function TryOpenDealerDialogue(npc)
    if not npc then
        AddLog("❌ Luxury Boat Dealer не найден.")
        return
    end

    AddLog("Нашёл Luxury Boat Dealer, пробую открыть диалог.")

    -- Сдвигаем персонажа ближе к NPC
    local head = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
    if head then
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = head.CFrame * CFrame.new(0, 0, -3)
    end

    -- 1) ProximityPrompt
    pcall(function()
        local prompt
        if head then
            prompt = head:FindFirstChildOfClass("ProximityPrompt")
        end
        if prompt and fireproximityprompt then
            AddLog("Попытка 1: fireproximityprompt(prompt).")
            fireproximityprompt(prompt, 3)
        end
    end)

    -- 2) ClickDetector
    pcall(function()
        local cd
        if head then
            cd = head:FindFirstChildOfClass("ClickDetector")
        end
        if cd and fireclickdetector then
            AddLog("Попытка 2: fireclickdetector(ClickDetector).")
            fireclickdetector(cd)
        end
    end)

    -- 3) Попытки через Remotes (слепые, чтобы увидеть в логах что-то)
    pcall(function()
        AddLog("Попытка 3: CommF_(\"BoatDealer\", \"1\").")
        CommF:InvokeServer("BoatDealer", "1")
    end)

    pcall(function()
        AddLog("Попытка 4: CommF_(\"LuxuryBoatDealer\", \"1\").")
        CommF:InvokeServer("LuxuryBoatDealer", "1")
    end)
end

------------------------
-- ПОПЫТКА НАЖАТЬ КНОПКИ ДИАЛОГА
------------------------
local function PressDialogueButtons()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    local function clickButtonsByText(substrList, label)
        local clicked = 0
        for _, gui in ipairs(pg:GetDescendants()) do
            if gui:IsA("TextButton") then
                local tx = string.lower(gui.Text or "")
                for _, sub in ipairs(substrList) do
                    if tx:find(string.lower(sub)) then
                        clicked = clicked + 1
                        AddLog("Диалог: пробую нажать '"..gui.Text.."' ("..label..").")
                        pcall(function()
                            gui:Activate()
                        end)
                    end
                end
            end
        end
        if clicked == 0 then
            AddLog("Диалог: не нашёл кнопок для "..label..".")
        end
    end

    -- 3 раза Next
    for i = 1,3 do
        clickButtonsByText({"Next", ">>"}, "Next #" .. i)
        task.wait(0.3)
    end

    -- затем Pardon me
    clickButtonsByText({"Pardon", "Pardon me"}, "Pardon me")
end

------------------------
-- КОМПЛЕКСНАЯ ФУНКЦИЯ ДЛЯ LUXURY BOAT DEALER
------------------------
local function HandleLuxuryBoatDealer()
    AddLog("Tushita Q1: взаимодействие с Luxury Boat Dealer (серия попыток).")

    local npc = FindLuxuryBoatDealer()
    if not npc then
        AddLog("❌ Luxury Boat Dealer не найден поблизости.")
        return
    end

    TryOpenDealerDialogue(npc)

    -- небольшая пауза, чтобы диалог открылся
    task.wait(0.5)

    -- серия попыток нажать нужные кнопки
    PressDialogueButtons()
end

------------------------
-- ОСНОВНОЙ ЦИКЛ
------------------------
spawn(function()
    while task.wait(0.3) do
        if AutoTushitaQ1 then
            pcall(function()
                AddLog("Запускаю круг Tushita Quest1.")
                for i, cf in ipairs(QuestPoints) do
                    if not AutoTushitaQ1 then break end

                    UpdateStatus("Tushita Q1: точка " .. i)
                    TweenTo(cf, "точка " .. i)
                    if not AutoTushitaQ1 or StopTween then break end

                    -- на первой точке пытаемся поговорить с Luxury Boat Dealer
                    if i == 1 then
                        HandleLuxuryBoatDealer()
                    end

                    -- короткая задержка для триггеров
                    local waitEnd = tick() + 1
                    while tick() < waitEnd do
                        if not AutoTushitaQ1 or StopTween then
                            break
                        end
                        task.wait(0.1)
                    end
                end

                if AutoTushitaQ1 then
                    AddLog("Круг Tushita Quest1 завершён, повторяю...")
                else
                    AddLog("Tushita Quest1 остановлен пользователем.")
                end
            end)
        end
    end
end)

------------------------
-- СТАРТ
------------------------
CreateGui()
