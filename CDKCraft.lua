-- CDK Craft + Boss
-- Авто-крафт CDK после получения 6 Alucard Fragment + убийство Cursed Skeleton Boss
-- Использует нашу механику телепортов и атаки, свой GUI с логами и тумблером ON/OFF

------------------------------------------------
-- НАСТРОЙКИ
------------------------------------------------
local WeaponName    = "Godhuman"                -- оружие для боя
local TeleportSpeed = 300                       -- скорость полёта
local FarmOffset    = CFrame.new(0, 10, -3)     -- позиция над мобом

-- Алтарь CDK (из 12к)
local CDKAltarPos   = CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875)
local CDKAfterPos   = CFrame.new(-12253.5419921875, 598.8999633789062, -6546.8388671875)

------------------------------------------------
-- СЕРВИСЫ / ПЕРЕМЕННЫЕ
------------------------------------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local Vim               = game:GetService("VirtualInputManager")

local LocalPlayer       = Players.LocalPlayer
local remote            = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local AutoCDK           = false
local IsTeleporting     = false
local StopTween         = false
local IsFighting        = false
local CurrentStatus     = "Idle"

------------------------------------------------
-- ЛОГИ / GUI
------------------------------------------------
local StatusLogs = {}
local MaxLogs    = 200

local ScreenGui, MainFrame, ToggleButton
local StatusLabel, LogsText

local lastLogMsgText = nil

local function AddLog(msg)
    if lastLogMsgText == msg then
        return
    end
    lastLogMsgText = msg

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
    AddLog("Anti-AFK: фейковый клик для защиты от кика.")
end)

------------------------------------------------
-- NET / ATTACK (как в наших скриптах)
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

    local hitTable = {{enemyModel, hrp}}

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
-- ТЕЛЕПОРТ (наша механика)
------------------------------------------------
local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting or not AutoCDK then return end
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
        if StopTween or (not AutoCDK) then
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

-- сброс после смерти
LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = false
    IsFighting    = false
    AddLog("Персонаж возрождён, жду HRP для CDK Craft+Boss...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, продолжение CDK Craft+Boss возможно.")
    UpdateStatus("Ожидание / CDK Craft+Boss")
end)

------------------------------------------------
-- ИНВЕНТАРЬ / МАТЕРИАЛЫ
------------------------------------------------
local function GetMaterialCount(materialName)
    local ok, inv = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if not ok or type(inv) ~= "table" then
        return 0
    end

    for _, item in ipairs(inv) do
        local name  = item.Name or item.name or ""
        local count = item.Count or item.count or 0
        if name == materialName then
            return count
        end
    end
    return 0
end

------------------------------------------------
-- ПОИСК МОНСТРОВ
------------------------------------------------
local function GetEnemiesFolder()
    return Workspace:FindFirstChild("Enemies")
end

local function IsCDKBossMob(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name
    -- В 12к проверяли "Cursed Skeleton Boss" и "Cursed Skeleton"
    if string.find(name, "Cursed Skeleton Boss") then return true end
    if string.find(name, "Cursed Skeleton") then return true end
    return false
end

local function GetCDKBossTargets()
    local enemies = GetEnemiesFolder()
    if not enemies then return {} end
    local list = {}
    for _, v in ipairs(enemies:GetChildren()) do
        if IsCDKBossMob(v)
            and v:FindFirstChild("Humanoid")
            and v:FindFirstChild("HumanoidRootPart")
            and v.Humanoid.Health > 0 then
            table.insert(list, v)
        end
    end
    return list
end

------------------------------------------------
-- БОЙ С МОНСТРОМ (наша механика)
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
        if not (char and hrp and hum and tHRP) then return end

        UpdateStatus(label or "Бой")
        AddLog("Начинаю бой: "..tostring(target.Name))

        SimpleTeleport(tHRP.CFrame * FarmOffset, label or "цель")

        local deadline      = tick() + maxTime
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoCDK
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
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий моб CDK")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame                 = tHRP.CFrame * FarmOffset
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
                AddLog("✅ Цель убита: "..tostring(target.Name))
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
-- ВЗАИМОДЕЙСТВИЕ С АЛТАРЁМ CDK
------------------------------------------------
local function HoldEFor(seconds, label)
    label = label or "E"
    AddLog("Зажимаю "..label.." на "..tostring(seconds).." сек.")
    Vim:SendKeyEvent(true, "E", false, game)
    task.wait(seconds)
    Vim:SendKeyEvent(false, "E", false, game)
end

local function DoCDKAltarPhase()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return end

    local dist = (hrp.Position - CDKAltarPos.Position).Magnitude
    if dist <= 100 then
        UpdateStatus("CDK: взаимодействие с алтарём.")
        AddLog("CDK: отправляю CDKQuest Progress Good/Evil...")

        pcall(function()
            remote:InvokeServer("CDKQuest", "Progress", "Good")
        end)
        task.wait(1)
        pcall(function()
            remote:InvokeServer("CDKQuest", "Progress", "Evil")
        end)
        task.wait(1)

        SimpleTeleport(CDKAltarPos, "CDK Altar")
        task.wait(1.0)

        HoldEFor(2, "Алтарь CDK")

        task.wait(1.0)
        SimpleTeleport(CDKAfterPos, "CDK After Pos")
        AddLog("CDK: крафт/диалог завершён, перемещение на позицию после алтаря.")
    else
        UpdateStatus("CDK: лечу к алтарю.")
        SimpleTeleport(CDKAltarPos, "CDK Altar")
    end
end

------------------------------------------------
-- ЛОГИКА CDK Craft+Boss
------------------------------------------------
local function RunCDKCycle()
    -- проверяем количество Alucard Fragment
    local fragments = GetMaterialCount("Alucard Fragment")
    if fragments < 6 then
        UpdateStatus("Жду 6 Alucard Fragment (есть: "..tostring(fragments)..")")
        return
    end

    -- есть 6+ фрагментов -> сначала ищем босса
    local bossInWorkspace = false
    do
        local enemies = GetEnemiesFolder()
        if enemies and enemies:FindFirstChild("Cursed Skeleton Boss [Lv. 2025] [Boss]") then
            bossInWorkspace = true
        end
    end

    local bossInRep = ReplicatedStorage:FindFirstChild("Cursed Skeleton Boss [Lv. 2025] [Boss]") ~= nil

    if bossInWorkspace or bossInRep then
        -- как в 12к: отключаем прочие квесты, если глобалы существуют
        pcall(function()
            if typeof(Auto_Quest_Yama_1) ~= "nil" then Auto_Quest_Yama_1 = false end
            if typeof(Auto_Quest_Yama_2) ~= "nil" then Auto_Quest_Yama_2 = false end
            if typeof(Auto_Quest_Yama_3) ~= "nil" then Auto_Quest_Yama_3 = false end
            if typeof(Auto_Quest_Tushita_1) ~= "nil" then Auto_Quest_Tushita_1 = false end
            if typeof(Auto_Quest_Tushita_2) ~= "nil" then Auto_Quest_Tushita_2 = false end
            if typeof(Auto_Quest_Tushita_3) ~= "nil" then Auto_Quest_Tushita_3 = false end
        end)

        UpdateStatus("CDK: босс / скелеты найдены, начинаю бой.")
        local targets = GetCDKBossTargets()
        if #targets == 0 then
            AddLog("CDK: босс ещё в ReplicatedStorage, жду появления в мире...")
            return
        end

        for _, mob in ipairs(targets) do
            if not AutoCDK then break end
            FightMob(mob, "CDK: "..mob.Name, 120)
        end
    else
        -- босса нет ни в мире, ни в репе -> работаем с алтарём
        DoCDKAltarPhase()
    end
end

------------------------------------------------
-- GUI "CDK Craft+Boss"
------------------------------------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CDK_CraftBoss_Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 520, 0, 260)
    MainFrame.Position = UDim2.new(0, 40, 0, 160)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "CDK Craft+Boss (Alucard Fragment x6 -> Boss + Алтарь)"
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
    ToggleButton.Text = "CDK Craft+Boss: OFF"
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
    LogsFrame.Size = UDim2.new(1, -20, 0, 160)
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
        AutoCDK   = not AutoCDK
        StopTween = not AutoCDK

        if AutoCDK then
            ToggleButton.Text = "CDK Craft+Boss: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            StopTween = false
            UpdateStatus("CDK Craft+Boss запущен")
        else
            ToggleButton.Text = "CDK Craft+Boss: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            UpdateStatus("Остановлен")
        end
    end)

    AddLog("GUI CDK Craft+Boss загружен.")
end

------------------------------------------------
-- ОСНОВНОЙ ЦИКЛ
------------------------------------------------
spawn(function()
    while task.wait(0.4) do
        if AutoCDK then
            local ok, err = pcall(RunCDKCycle)
            if not ok then
                AddLog("Ошибка в основном цикле CDK Craft+Boss: "..tostring(err))
            end
        end
    end
end)

------------------------------------------------
-- СТАРТ
------------------------------------------------
CreateGui()
