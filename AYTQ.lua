-- Auto Tushita / Auto Yama (GUI + логика)
-- С фиксами Auto Yama: учитывается активный квест по QuestTitle

------------------------------------------------
-- СТАРТ: команда Marines
------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local Vim               = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local remote      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

pcall(function()
    remote:InvokeServer("SetTeam","Marines")
end)
task.wait(5)

------------------------------------------------
-- НАСТРОЙКИ
------------------------------------------------
local WeaponName       = "Godhuman"                    -- чем биться
local TeleportSpeed    = 300                           -- скорость полёта
local HoverOffsetY     = 15                            -- высота зависания над мобом
local EliteNPCFallback = CFrame.new(-5554, 143, -3016) -- Castle on the Sea (Elite Hunter) ПРИМЕР, поправь
local YamaKatanaPos    = CFrame.new(-9545, 251, 6049)  -- Sealed Katana (водопад) ПРИМЕР, поправь

-- Holy Torch точки (из 12к-примера)
local HolyTorchRoute = {
    CFrame.new(-10752, 417, -9366),
    CFrame.new(-11672, 334, -9474),
    CFrame.new(-12132, 521, -10655),
    CFrame.new(-13336, 486, -6985),
    CFrame.new(-13489, 332, -7925),
}

-- Longma остров (Tushita)
local LongmaIslandPos = CFrame.new(-10238.875976563, 389.7912902832, -9549.7939453125)

------------------------------------------------
-- ФЛАГИ
------------------------------------------------
local AutoTushita = false
local AutoYama    = false

local CurrentStatus = "Idle"
local IsTeleporting = false
local IsFighting    = false
local StopTween     = false

------------------------------------------------
-- ЛОГИ / GUI
------------------------------------------------
local StatusLogs      = {}
local MaxLogs         = 200
local lastLogMessage  = nil

local ScreenGui, MainFrame
local StatusLabel, LogsText
local TushitaButton, YamaButton

local function AddLog(msg)
    if lastLogMessage == msg then return end
    lastLogMessage = msg

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
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    AddLog("Anti-AFK: фейковый клик, чтобы не кикнуло.")
end)

------------------------------------------------
-- NET / FAST ATTACK (как в Auto Bones)
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
    if IsToolEquipped(name) then return end

    local p = LocalPlayer
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
            AddLog("⚠️ Не найдено оружие: " .. name)
            lastEquipFailLog = tick()
        end
    end
end

------------------------------------------------
-- ТЕЛЕПОРТ (speed=300)
------------------------------------------------
local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting then return end
    IsTeleporting = true
    StopTween     = false

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        IsTeleporting = false
        return
    end

    local hrp  = char.HumanoidRootPart
    local dist = (hrp.Position - targetCFrame.Position).Magnitude

    local travelTime = dist / TeleportSpeed
    if travelTime < 0.5 then travelTime = 0.5 end
    if travelTime > 60  then travelTime = 60  end

    AddLog(string.format("Телепорт к %s (%.0f stud, t=%.1f)", label or "точке", dist, travelTime))

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()

    local start = tick()
    while tick() - start < travelTime do
        if StopTween or (not AutoTushita and not AutoYama) then
            tween:Cancel()
            IsTeleporting = false
            AddLog("Телепорт прерван (OFF/StopTween).")
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
        hrp.AssemblyAngularVelocity= Vector3.new(0,0,0)
        hrp.CanCollide             = false

        RunService.Heartbeat:Wait()
    end

    tween:Cancel()
    local c2 = LocalPlayer.Character
    hrp = c2 and c2:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame                 = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity= Vector3.new(0,0,0)
        hrp.CanCollide             = false
    end

    IsTeleporting = false
end

LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    IsFighting    = false
    StopTween     = false
    AddLog("Персонаж возрожден, жду HRP...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, скрипт можно продолжать.")
end)

------------------------------------------------
-- ВСПОМ. ФУНКЦИИ
------------------------------------------------
local function HasTool(name)
    local p = LocalPlayer
    if not p then return false end

    local backpack = p:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(name) then
        return true
    end

    local char = p.Character
    if char and char:FindFirstChild(name) then
        return true
    end

    return false
end

local function GetEnemiesFolder()
    return Workspace:FindFirstChild("Enemies")
end

local function IsEliteName(name)
    return name == "Diablo" or name == "Deandre" or name == "Urban"
end

local function FindEliteTarget()
    local enemies = GetEnemiesFolder()
    if not enemies then return nil end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, bestDist = nil, 99999
    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if IsEliteName(v.Name) then
                local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    nearest  = v
                end
            end
        end
    end
    return nearest
end

local function FindLongma()
    local enemies = GetEnemiesFolder()
    if not enemies then return nil end
    for _, v in ipairs(enemies:GetChildren()) do
        if v.Name == "Longma"
            and v:FindFirstChild("Humanoid")
            and v:FindFirstChild("HumanoidRootPart")
            and v.Humanoid.Health > 0 then
            return v
        end
    end
    return nil
end

local function HoldEFor(seconds, label)
    label = label or "E"
    AddLog("Зажимаю "..label.." на "..tostring(seconds).." сек.")
    Vim:SendKeyEvent(true, "E", false, game)
    task.wait(seconds)
    Vim:SendKeyEvent(false, "E", false, game)
end

------------------------------------------------
-- БОЙ С МОДЕЛЬЮ
------------------------------------------------
local function FightMob(target, label, maxTime)
    maxTime = maxTime or 90
    if not target then return end
    if IsFighting then return end
    IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not (char and hrp and hum and tHRP) then
            return
        end

        UpdateStatus(label or "Бой")
        AddLog("Начинаю бой с: "..tostring(target.Name))

        SimpleTeleport(tHRP.CFrame * CFrame.new(0, HoverOffsetY, -3), label or "моб")

        local deadline      = tick() + maxTime
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while (AutoTushita or AutoYama)
            and target.Parent
            and hum.Health > 0
            and tick() < deadline do

            engaged = true

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and hum and tHRP) then
                break
            end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * CFrame.new(0, HoverOffsetY, -3), "далёкий моб")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame                 = tHRP.CFrame * CFrame.new(0, HoverOffsetY, -3)
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity= Vector3.new(0,0,0)
                    hrp.CanCollide             = false
                    lastPosAdjust              = tick()
                end
            end

            pcall(function()
                tHRP.CanCollide       = false
                hum.WalkSpeed         = 0
                hum.JumpPower         = 0
                if not tHRP:FindChild("BodyVelocity") and not tHRP:FindFirstChild("BodyVelocity") then
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
                AddLog("✅ Моб убит: "..tostring(target.Name))
            else
                AddLog("⚠️ Бой прерван: "..tostring(target.Name))
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в FightMob: "..tostring(err))
    end

    IsFighting = false
end

------------------------------------------------
-- Yama / Elite Hunter ЛОГИКА
------------------------------------------------
local lastQuestRequestTime   = 0
local questRequestCooldown   = 60 -- раз в минуту просим квест
local lastStatusProgressTime = 0
local statusCooldown         = 60 -- раз в минуту лог про прогресс

local function FindEliteHunterModel()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Elite Hunter" then
            if obj:FindFirstChild("HumanoidRootPart") then
                return obj
            end
        end
    end
    return nil
end

local function GetEliteHunterPos()
    local elite = FindEliteHunterModel()
    if elite and elite:FindFirstChild("HumanoidRootPart") then
        return elite.HumanoidRootPart.CFrame
    end
    return EliteNPCFallback
end

local function EnsureAtEliteHunter()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return false end

    local target = GetEliteHunterPos()
    local dist   = (hrp.Position - target.Position).Magnitude
    if dist > 70 then
        UpdateStatus("Лечу к Elite Hunter...")
        SimpleTeleport(target * CFrame.new(0, 5, 3), "Elite Hunter")
        task.wait(1.0)
        return false
    end
    return true
end

local function ClickSealedKatana()
    UpdateStatus("Yama: кликаю Sealed Katana...")
    SimpleTeleport(YamaKatanaPos * CFrame.new(0, 3, 0), "Sealed Katana")
    task.wait(0.5)

    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local waterfall = map:FindFirstChild("Waterfall")
    if not waterfall then return end
    local sealed = waterfall:FindFirstChild("SealedKatana") or waterfall:FindFirstChild("Sealed Katana")
    if not sealed then return end

    local handle = sealed:FindFirstChild("Handle")
    if not handle then return end

    for _, cd in ipairs(handle:GetDescendants()) do
        if cd:IsA("ClickDetector") then
            AddLog("Yama: кликаю по ClickDetector меча.")
            fireclickdetector(cd)
            break
        end
    end
end

-- ЧТЕНИЕ АКТИВНОГО КВЕСТА (из UI)
local function GetQuestTitle()
    local ok, title = pcall(function()
        return LocalPlayer.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
    end)
    if ok and type(title) == "string" then
        return title
    end
    return ""
end

local function QuestHasEliteTarget()
    local qt = GetQuestTitle()
    if qt == "" then return false, nil end

    for _, name in ipairs({"Diablo","Deandre","Urban"}) do
        if string.find(qt, name) then
            return true, name
        end
    end

    return false, nil
end

local function RunYamaLogic()
    if HasTool("Yama") then
        UpdateStatus("Yama уже есть.")
        return
    end

    if not EnsureAtEliteHunter() then
        return
    end

    local progress = 0
    local ok, res = pcall(function()
        return remote:InvokeServer("EliteHunter", "Progress")
    end)
    if ok and type(res) == "number" then
        progress = res
    end

    local now = tick()
    if now - lastStatusProgressTime > statusCooldown then
        AddLog("Yama: прогресс Elite Hunter = "..tostring(progress).."/30")
        lastStatusProgressTime = now
    end

    if progress >= 30 then
        UpdateStatus("Yama: прогресс >=30, лечу к мечу.")
        ClickSealedKatana()
        return
    end

    -- Проверяем, взят ли уже элит-квест по QuestTitle
    local hasQuest, questTargetName = QuestHasEliteTarget()

    if hasQuest then
        local elite = FindEliteTarget()
        if elite then
            local labelName = questTargetName or elite.Name
            UpdateStatus("Yama: активен квест на "..labelName..", фарм элитки.")
            FightMob(elite, "Elite "..labelName, 120)
            EnsureAtEliteHunter()
        else
            UpdateStatus("Yama: квест '"..GetQuestTitle().."' активен, жду появления элитки.")
        end
        return
    end

    -- сюда попадаем, когда квеста ещё нет
    local elite = FindEliteTarget()
    if elite then
        UpdateStatus("Yama: элитка найдена без квеста, фармлю "..elite.Name)
        FightMob(elite, "Elite "..elite.Name, 120)
        EnsureAtEliteHunter()
        return
    end

    if now - lastQuestRequestTime >= questRequestCooldown then
        lastQuestRequestTime = now
        UpdateStatus("Yama: запрашиваю НОВЫЙ квест у NPC.")
        pcall(function()
            remote:InvokeServer("EliteHunter")
        end)
    else
        UpdateStatus("Yama: жду кулдаун запроса квеста.")
    end
end

------------------------------------------------
-- Tushita (Holy Torch + Longma)
------------------------------------------------
local function DoHolyTorchRoute()
    UpdateStatus("Tushita: маршрут Holy Torch...")
    for idx, cf in ipairs(HolyTorchRoute) do
        if not AutoTushita then return end
        AddLog("Tushita: точка Holy Torch "..idx)
        SimpleTeleport(cf * CFrame.new(0, 3, 0), "Holy Torch "..idx)
        task.wait(0.5)
        HoldEFor(2, "Torch "..idx)
        task.wait(0.5)
    end
end

local function ClickTushitaBladeOrDoor()
    AddLog("Tushita: кликаю по мечу/двери (дополни под оффлайн-проект, если нужно конкретно).")
end

local function RunTushitaLogic()
    if HasTool("Tushita") then
        UpdateStatus("Tushita уже есть.")
        return
    end

    DoHolyTorchRoute()

    local longma = FindLongma()
    if longma then
        UpdateStatus("Tushita: найден Longma, начинаю бой.")
        FightMob(longma, "Longma", 120)
        ClickTushitaBladeOrDoor()
    else
        UpdateStatus("Tushita: Longma не найден, лечу на остров.")
        SimpleTeleport(LongmaIslandPos, "Longma Island")
    end
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
    MainFrame.Size = UDim2.new(0, 600, 0, 280)
    MainFrame.Position = UDim2.new(0, 40, 0, 180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Title.Text = "Auto Yama / Auto Tushita"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
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

    TushitaButton = Instance.new("TextButton")
    TushitaButton.Size = UDim2.new(0, 180, 0, 32)
    TushitaButton.Position = UDim2.new(0, 10, 0, 60)
    TushitaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    TushitaButton.TextColor3 = Color3.new(1,1,1)
    TushitaButton.Font = Enum.Font.SourceSansBold
    TushitaButton.TextSize = 16
    TushitaButton.Text = "Auto Tushita: OFF"
    TushitaButton.Parent = MainFrame

    YamaButton = Instance.new("TextButton")
    YamaButton.Size = UDim2.new(0, 180, 0, 32)
    YamaButton.Position = UDim2.new(0, 210, 0, 60)
    YamaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    YamaButton.TextColor3 = Color3.new(1,1,1)
    YamaButton.Font = Enum.Font.SourceSansBold
    YamaButton.TextSize = 16
    YamaButton.Text = "Auto Yama: OFF"
    YamaButton.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 170)
    LogsFrame.Position = UDim2.new(0, 10, 0, 100)
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

    TushitaButton.MouseButton1Click:Connect(function()
        AutoTushita = not AutoTushita
        if AutoTushita then
            AutoYama = false
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)

            TushitaButton.Text = "Auto Tushita: ON"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(0,120,0)

            StopTween = false
            UpdateStatus("Фарм Tushita...")
        else
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            StopTween = true
            UpdateStatus("Остановлен")
        end
    end)

    YamaButton.MouseButton1Click:Connect(function()
        AutoYama = not AutoYama
        if AutoYama then
            AutoTushita = false
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)

            YamaButton.Text = "Auto Yama: ON"
            YamaButton.BackgroundColor3 = Color3.fromRGB(0,120,0)

            StopTween = false
            UpdateStatus("Фарм Yama...")
        else
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            StopTween = true
            UpdateStatus("Остановлен")
        end
    end)

    AddLog("GUI Auto Yama/Tushita загружен.")
end

------------------------------------------------
-- ОСНОВНОЙ ЦИКЛ
------------------------------------------------
task.spawn(function()
    while task.wait(0.5) do
        if AutoTushita then
            local ok, err = pcall(RunTushitaLogic)
            if not ok then
                AddLog("Ошибка в RunTushitaLogic: "..tostring(err))
            end
        elseif AutoYama then
            local ok, err = pcall(RunYamaLogic)
            if not ok then
                AddLog("Ошибка в RunYamaLogic: "..tostring(err))
            end
        end
    end
end)

CreateGui()
UpdateStatus("Ожидание...")
