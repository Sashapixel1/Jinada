--========================================================
-- Auto Yama (Elite Hunter из 12к, расширенный поиск элиток)
-- GUI + лог-панель, телепорт 300 speed, Anti-AFK
--========================================================

task.wait(2)

------------------------------------------------
-- НАСТРОЙКИ
------------------------------------------------
local WeaponName    = "Godhuman"            -- чем бить элиток
local TeleportSpeed = 300                   -- скорость полёта
local FarmOffset    = CFrame.new(0, 12, -3) -- позиция над боссом

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
-- NET-модуль
------------------------------------------------
local modules        = ReplicatedStorage:WaitForChild("Modules")
local net            = modules:WaitForChild("Net")
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
local AutoYama      = false
local CurrentStatus = "Idle"

------------------------------------------------
-- ЛОГИ / GUI
------------------------------------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame
local StatusLabel, LogsText, ToggleButton

local function AddLog(msg)
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
    AddLog("Статус: "..text)
    if StatusLabel then
        StatusLabel.Text = "Статус: "..text
    end
end

------------------------------------------------
-- Anti-AFK
------------------------------------------------
task.spawn(function()
    while task.wait(55) do
        if AutoYama then
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
    local lower = string.lower(name)
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and string.lower(obj.Name) == lower then
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

    local lower = string.lower(name)

    local function findTool(container)
        if not container then return nil end
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("Tool") and string.lower(obj.Name) == lower then
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
        task.wait(0.15)
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
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (инвентарь / квест)
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

local function GetQuestTitle()
    local ok, txt = pcall(function()
        return LocalPlayer.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
    end)
    if ok and type(txt) == "string" then
        return txt
    end
    return ""
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
local EliteQuestCooldown    = 60  -- раз в минуту

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
-- ЭЛИТКИ: поиск и бой
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

-- >>> ГЛАВНЫЙ ФИКС: ищем элитку во ВСЁМ Workspace
local function FindEliteInWorkspace()
    -- сначала пробуем стандартную папку Enemies (если есть)
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, v in ipairs(enemiesFolder:GetChildren()) do
            if v:IsA("Model") and IsEliteName(v.Name) then
                local hum = v:FindFirstChildOfClass("Humanoid")
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    AddLog("Нашёл элитку в Enemies: "..v.Name)
                    return v
                end
            end
        end
    end

    -- если в Enemies нет — сканируем весь Workspace
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and IsEliteName(v.Name) then
            local hum = v:FindFirstChildOfClass("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                AddLog("Нашёл элитку в Workspace: "..v.Name.." ("..v:GetFullName()..")")
                return v
            end
        end
    end

    return nil
end
-- <<< КОНЕЦ ФИКСА

local function FightElite(target)
    if not target then return end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local tHRP = target:FindFirstChild("HumanoidRootPart")
    local hum  = target:FindFirstChildOfClass("Humanoid")
    if not (char and hrp and tHRP and hum) then return end

    -- Сначала один раз телепортируемся к элитке
    SimpleTeleport(tHRP.CFrame * FarmOffset, "элитный босс")

    local fightDeadline = tick() + 120
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

        if not (char and hrp and tHRP and hum) then
            break
        end

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
local WaterfallCFrame = CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875)

local function ClickSealedKatana()
    pcall(function()
        local map    = Workspace:FindFirstChild("Map")
        local wf     = map and map:FindFirstChild("Waterfall")
        local sword  = wf and wf:FindFirstChild("SealedKatana")
        local handle = sword and sword:FindFirstChild("Handle")
        local cd     = handle and handle:FindFirstChildOfClass("ClickDetector")
        if cd then
            for i = 1, 5 do
                fireclickdetector(cd)
                task.wait(0.2)
            end
            AddLog("Клик по SealedKatana (водопад) отправлен.")
        else
            AddLog("Waterfall / SealedKatana не найден.")
        end
    end)
end

local function RunYamaStep()
    if HasItemInInventory("Yama") then
        UpdateStatus("Yama уже есть, скрипт остановлен.")
        AutoYama = false
        if ToggleButton then
            ToggleButton.Text = "Auto Yama: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        return
    end

    local progress = GetEliteProgress()
    AddLog("Yama: прогресс Elite Hunter = "..tostring(progress).."/30.")

    if progress >= 30 then
        UpdateStatus("Yama: прогресс 30/30, иду к водопаду.")
        SimpleTeleport(WaterfallCFrame, "Waterfall / SealedKatana")
        task.wait(1.5)
        ClickSealedKatana()
        return
    end

    local questTitle = GetQuestTitle()
    if questTitle ~= "" then
        AddLog("Yama: квест = '"..questTitle.."'.")
    end

    local hasEliteQuest = false
    if questTitle ~= "" then
        if string.find(questTitle, "Diablo") or string.find(questTitle, "Deandre") or string.find(questTitle, "Urban") then
            hasEliteQuest = true
        end
    end

    if hasEliteQuest then
        UpdateStatus("Yama: квест на элиту активен, ищу босса.")
        local elite = FindEliteInWorkspace()
        if elite then
            UpdateStatus("Yama: элитка "..elite.Name..", атакую.")
            FightElite(elite)
        else
            AddLog("Yama: квест на элиту есть, но сам босс не найден (жду спавна).")
        end
    else
        UpdateStatus("Yama: элитный квест не активен, беру/обновляю Elite Hunter.")
        RequestEliteQuest()
    end
end

------------------------------------------------
-- GUI
------------------------------------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaGui"
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
    Title.Text = "Auto Yama (Elite Hunter, deep scan)"
    Title.TextColor3 = Color3.new(1, 1, 1)
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

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 250, 0, 32)
    ToggleButton.Position = UDim2.new(0, 10, 0, 60)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Auto Yama: OFF"
    ToggleButton.Parent = MainFrame

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

    ToggleButton.MouseButton1Click:Connect(function()
        AutoYama = not AutoYama
        if AutoYama then
            ToggleButton.Text = "Auto Yama: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            NoclipEnabled = true
            StopTween     = false
            UpdateStatus("Фарм Yama / Elite Hunter.")
        else
            ToggleButton.Text = "Auto Yama: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            NoclipEnabled = false
            StopTween     = true
            UpdateStatus("Остановлен")
        end
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if AutoYama then
                local ok, err = pcall(RunYamaStep)
                if not ok then
                    AddLog("Ошибка в цикле AutoYama: "..tostring(err))
                end
            end
        end
    end)

    AddLog("Auto Yama GUI загружен. Нажми кнопку, когда будешь в 3-м море (Castle On The Sea / Floating Turtle).")
end

CreateGui()
