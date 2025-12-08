--========================================================
-- Yama & Tushita Mastery Farm (Reborn Skeleton, Haunted Castle)
-- Мобы: Reborn Skeleton
-- Кемп: Haunted Castle (центр у Death King / fallback)
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
-- НАСТРОЙКИ
---------------------
local TeleportSpeed = 300
local FarmOffset    = CFrame.new(0, 10, -3)        -- зависание над мобом

-- Haunted Castle центр (из скрипта Auto Bones)
local HauntedFallback = CFrame.new(-9515.129, 142.233, 6200.441)
local TargetName      = "Reborn Skeleton"

-- Меч, которым прямо сейчас фармим (переключается между Tushita и Yama)
local WeaponName    = "Tushita"

-- Целевая мастери
local TargetMastery          = 350
local MasteryCheckInterval   = 10 -- раз в 10 секунд чекаем мастери
local lastMasteryCheck       = 0
local YamaMastery, TushitaMastery = nil, nil
local LastLoggedMastery      = {Yama = nil, Tushita = nil}

---------------------
-- ФЛАГИ / СОСТОЯНИЕ
---------------------
local AutoMasteryFarm = false      -- общий флаг авто-фарма
local CurrentStatus   = "Idle"

local IsTeleporting   = false
local StopTween       = false
local NoclipEnabled   = false
local IsFighting      = false

local lastTPLog       = ""
local lastEquipFail   = 0

---------------------
-- NET MODULE (fast attack)
---------------------
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

---------------------
-- ЛОГИ / GUI
---------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame
local StatusLabel
local ToggleButton
local LogsText
local YamaLabelGui
local TushitaLabelGui

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

local function UpdateMasteryLabels()
    if YamaLabelGui then
        if YamaMastery ~= nil then
            YamaLabelGui.Text = "Yama Mastery: " .. tostring(YamaMastery)
        else
            YamaLabelGui.Text = "Yama Mastery: —"
        end
    end
    if TushitaLabelGui then
        if TushitaMastery ~= nil then
            TushitaLabelGui.Text = "Tushita Mastery: " .. tostring(TushitaMastery)
        else
            TushitaLabelGui.Text = "Tushita Mastery: —"
        end
    end
end

---------------------
-- ANTI AFK
---------------------
spawn(function()
    while task.wait(60) do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

---------------------
-- NOCLIP
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
-- АВТО ХАКИ
---------------------
local function AutoHaki()
    local char = LocalPlayer.Character
    if not char then return end
    if not char:FindFirstChild("HasBuso") then
        pcall(function()
            remote:InvokeServer("Buso")
        end)
    end
end

---------------------
-- ИНВЕНТАРЬ / МЕЧИ
---------------------
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

local function HasToolInCharOrBackpack(name)
    local p    = LocalPlayer
    if not p then return false end

    local lower = string.lower(name)

    local backpack = p:FindFirstChild("Backpack")
    if backpack then
        for _, v in ipairs(backpack:GetChildren()) do
            if v:IsA("Tool") and string.lower(v.Name) == lower then
                return true
            end
        end
    end

    local char = p.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and string.lower(v.Name) == lower then
                return true
            end
        end
    end

    return false
end

local function HasInAccountInventory(name)
    local ok, invData = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if ok and type(invData) == "table" then
        for _, item in ipairs(invData) do
            local n = item.Name or item.name or tostring(item)
            if n == name then
                return true
            end
        end
    end
    return false
end

local function EnsureItemInBackpack(name)
    -- если уже есть в руках или в Backpack – ок
    if HasToolInCharOrBackpack(name) then return true end

    -- если в аккаунт-инвенте есть, пробуем загрузить
    if HasInAccountInventory(name) then
        pcall(function()
            remote:InvokeServer("LoadItem", name)
        end)
        task.wait(0.5)
        if HasToolInCharOrBackpack(name) then
            AddLog("Загрузил из инвентаря предмет: " .. name)
            return true
        end
    end

    return false
end

local function EquipToolByName(name)
    if IsToolEquipped(name) then
        return
    end

    local p = LocalPlayer
    if not p then return end

    local char = p.Character or p.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local lower = string.lower(name)
    local toolFound

    local function findToolIn(container)
        if not container then return nil end
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Tool") and string.lower(obj.Name) == lower then
                return obj
            end
        end
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("Tool") and string.lower(obj.Name) == lower then
                return obj
            end
        end
        return nil
    end

    local backpack = p:FindFirstChild("Backpack")
    if backpack then
        toolFound = findToolIn(backpack)
    end
    if not toolFound then
        toolFound = findToolIn(char)
    end

    if toolFound then
        hum:UnequipTools()
        hum:EquipTool(toolFound)
        AddLog("⚔️ Экипирован: " .. toolFound.Name)
    else
        if tick() - lastEquipFail > 3 then
            AddLog("⚠️ Не удалось найти оружие: " .. name)
            lastEquipFail = tick()
        end
    end
end

---------------------
-- ЧЕКЕР МАСТЕРИ (getInventory.Mastery)
---------------------
local function RefreshMasteries()
    local ok, inv = pcall(function()
        return remote:InvokeServer("getInventory")
    end)

    if not ok or type(inv) ~= "table" then
        AddLog("Ошибка getInventory при обновлении мастери: " .. tostring(inv))
        return
    end

    local newY, newT

    for _, item in ipairs(inv) do
        if item and item.Type == "Sword" then
            if item.Name == "Yama" then
                newY = item.Mastery
            elseif item.Name == "Tushita" then
                newT = item.Mastery
            end
        end
    end

    if newY ~= nil then
        YamaMastery = newY
        if LastLoggedMastery.Yama ~= newY then
            AddLog("Yama Mastery: " .. tostring(newY))
            LastLoggedMastery.Yama = newY
        end
    end

    if newT ~= nil then
        TushitaMastery = newT
        if LastLoggedMastery.Tushita ~= newT then
            AddLog("Tushita Mastery: " .. tostring(newT))
            LastLoggedMastery.Tushita = newT
        end
    end

    UpdateMasteryLabels()
end

-- выбор, какой меч сейчас качать
local function ChooseWeaponForFarm()
    local t = TushitaMastery or 0
    local y = YamaMastery or 0

    -- приоритет: сначала Tushita до 350, потом Yama до 350
    if t < TargetMastery and (HasToolInCharOrBackpack("Tushita") or HasInAccountInventory("Tushita")) then
        if WeaponName ~= "Tushita" then
            WeaponName = "Tushita"
            AddLog("Смена оружия для фарма: Tushita (Mastery: " .. tostring(t) .. ")")
        end
    elseif y < TargetMastery and (HasToolInCharOrBackpack("Yama") or HasInAccountInventory("Yama")) then
        if WeaponName ~= "Yama" then
            WeaponName = "Yama"
            AddLog("Смена оружия для фарма: Yama (Mastery: " .. tostring(y) .. ")")
        end
    else
        -- мечей нет или уже оба 350 – обработаем это выше
    end
end

---------------------
-- Haunted Castle центр (как в AutoBones: GetHauntedCenterCFrame)
---------------------
local function FindDeathKingModel()
    local candidate = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Death King" then
            if obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Humanoid") then
                candidate = obj
                break
            end
        end
    end
    return candidate
end

local function GetHauntedCenterCFrame()
    local dk = FindDeathKingModel()
    if dk then
        local hrp = dk:FindFirstChild("HumanoidRootPart") or dk:FindFirstChild("Head")
        if hrp then
            return hrp.CFrame
        end
    end
    return HauntedFallback
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
    IsFighting    = false
    AddLog("Персонаж возрождён, жду HRP...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, продолжаю фарм мастери (если включен).")
end)

---------------------
-- ПРОВЕРКА, ЧТО МЫ У HAUNTED CASTLE
---------------------
local function EnsureOnHaunted()
    local char = LocalPlayer.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local center = GetHauntedCenterCFrame()
    local dist   = (hrp.Position - center.Position).Magnitude

    if dist > 600 then
        UpdateStatus("Лечу к Haunted Castle...")
        AddLog("Персонаж далеко от Haunted Castle (" .. math.floor(dist) .. " stud), лечу обратно...")
        SimpleTeleport(center * CFrame.new(0, 4, 3), "Haunted Castle")
        task.wait(1.2)
        return false
    end

    return true
end

---------------------
-- ПОИСК Reborn Skeleton
---------------------
local function GetNearestRebornSkeleton(maxDistance)
    maxDistance = maxDistance or 9999
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return nil end

    local center = GetHauntedCenterCFrame()

    local nearest
    local best = maxDistance

    for _, v in ipairs(enemiesFolder:GetChildren()) do
        if v.Name == TargetName
           and v:FindFirstChild("Humanoid")
           and v:FindFirstChild("HumanoidRootPart")
           and v.Humanoid.Health > 0 then

            -- мобы, близко к замку
            local distFromCenter = (v.HumanoidRootPart.Position - center.Position).Magnitude
            if distFromCenter < 800 then
                local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < best then
                    best    = d
                    nearest = v
                end
            end
        end
    end

    return nearest
end

---------------------
-- БОЙ / ФАРМ МАСТЕРИ
---------------------
local function FarmOnce()
    if IsFighting then return end
    IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and hrp) then return end

        -- ищем моба рядом (после тп к кемпу)
        local target = GetNearestRebornSkeleton(4000)
        if not target then
            UpdateStatus("Reborn Skeleton рядом не найден, жду спавна.")
            return
        end

        local hum  = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not (hum and tHRP and hum.Health > 0) then
            return
        end

        UpdateStatus("Фарм мастери " .. WeaponName .. ": " .. TargetName)
        AddLog("Нашёл " .. TargetName .. ", начинаю фарм мастери (" .. WeaponName .. ").")

        -- тп над мобом
        SimpleTeleport(tHRP.CFrame * FarmOffset, TargetName)

        local fightDeadline = tick() + 90
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoMasteryFarm
          and target.Parent
          and hum
          and hum.Health > 0
          and tick() < fightDeadline do

            engaged = true

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and tHRP and hum) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2500 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий " .. TargetName)
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            pcall(function()
                tHRP.CanCollide = false
                hum.WalkSpeed   = 0
                hum.JumpPower   = 0

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
            if hum and hum.Health <= 0 or not target.Parent then
                AddLog("✅ " .. TargetName .. " убит, мастери " .. WeaponName .. " должна была вырасти.")
            else
                AddLog("⚠️ Бой с " .. TargetName .. " прерван.")
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в FarmOnce: " .. tostring(err))
    end

    IsFighting = false
end

---------------------
-- ОСНОВНОЙ ЦИКЛ ЛОГИКИ
---------------------
local function RunMasteryLoop()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then
        UpdateStatus("Жду персонажа...")
        return
    end

    -- проверяем наличие мечей вообще
    if not (HasToolInCharOrBackpack("Tushita") or HasInAccountInventory("Tushita")
        or HasToolInCharOrBackpack("Yama") or HasInAccountInventory("Yama")) then

        UpdateStatus("Yama/Tushita не найдены ни в рюкзаке, ни в инвентаре аккаунта.")
        AddLog("❌ Yama и Tushita отсутствуют. Сначала получи мечи, потом включай фарм мастери.")
        return
    end

    -- убеждаемся, что мы у Haunted Castle
    if not EnsureOnHaunted() then
        return
    end

    -- загружаем текущий WeaponName в Backpack (если лежит в инвентаре)
    EnsureItemInBackpack(WeaponName)
    EquipToolByName(WeaponName)

    -- уже на духовке – фармим
    FarmOnce()
end

---------------------
-- GUI (твой стиль, немного переписан заголовок)
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TushitaMasteryGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 420, 0, 280)
    MainFrame.Position = UDim2.new(0, 40, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Title.Text = "Yama & Tushita Mastery Farm (Reborn Skeleton / Haunted Castle)"
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
    ToggleButton.Size = UDim2.new(0, 280, 0, 32)
    ToggleButton.Position = UDim2.new(0, 10, 0, 60)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Yama & Tushita Mastery Farm: OFF"
    ToggleButton.Parent = MainFrame

    -- строки мастери
    YamaLabelGui = Instance.new("TextLabel")
    YamaLabelGui.Size = UDim2.new(1, -20, 0, 20)
    YamaLabelGui.Position = UDim2.new(0, 10, 0, 96)
    YamaLabelGui.BackgroundTransparency = 1
    YamaLabelGui.TextColor3 = Color3.new(1,1,1)
    YamaLabelGui.Font = Enum.Font.SourceSans
    YamaLabelGui.TextSize = 14
    YamaLabelGui.TextXAlignment = Enum.TextXAlignment.Left
    YamaLabelGui.Text = "Yama Mastery: —"
    YamaLabelGui.Parent = MainFrame

    TushitaLabelGui = Instance.new("TextLabel")
    TushitaLabelGui.Size = UDim2.new(1, -20, 0, 20)
    TushitaLabelGui.Position = UDim2.new(0, 10, 0, 116)
    TushitaLabelGui.BackgroundTransparency = 1
    TushitaLabelGui.TextColor3 = Color3.new(1,1,1)
    TushitaLabelGui.Font = Enum.Font.SourceSans
    TushitaLabelGui.TextSize = 14
    TushitaLabelGui.TextXAlignment = Enum.TextXAlignment.Left
    TushitaLabelGui.Text = "Tushita Mastery: —"
    TushitaLabelGui.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 130)
    LogsFrame.Position = UDim2.new(0, 10, 0, 140)
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
        AutoMasteryFarm = not AutoMasteryFarm
        if AutoMasteryFarm then
            ToggleButton.Text = "Yama & Tushita Mastery Farm: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0,120,0)
            NoclipEnabled = true
            StopTween     = false
            UpdateStatus("Фарм мастери Yama/Tushita на Reborn Skeleton (Haunted Castle).")
            AddLog("Mastery Farm включён.")
            -- сразу обновим мастери при старте
            lastMasteryCheck = 0
        else
            ToggleButton.Text = "Yama & Tushita Mastery Farm: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled = false
            StopTween     = true
            UpdateStatus("Остановлен")
            AddLog("Mastery Farm выключен.")
        end
    end)

    AddLog("GUI Mastery Farm (Reborn Skeleton) загружен.")
    UpdateMasteryLabels()
end

CreateGui()

---------------------
-- ОСНОВНОЙ ЦИКЛ
---------------------
spawn(function()
    while task.wait(0.4) do
        local ok, err = pcall(function()
            if AutoMasteryFarm then
                -- периодически обновляем мастери
                if tick() - lastMasteryCheck >= MasteryCheckInterval then
                    lastMasteryCheck = tick()
                    RefreshMasteries()

                    -- если обе мастери уже >= TargetMastery — выключаемся
                    if YamaMastery and YamaMastery >= TargetMastery
                       and TushitaMastery and TushitaMastery >= TargetMastery then

                        AutoMasteryFarm = false
                        NoclipEnabled   = false
                        StopTween       = true

                        if ToggleButton then
                            ToggleButton.Text = "Yama & Tushita Mastery Farm: OFF"
                            ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
                        end

                        UpdateStatus("Готово: мастери Yama и Tushita >= " .. TargetMastery)
                        AddLog("✅ Фарм мастери завершён. Yama=" .. tostring(YamaMastery)
                            .. ", Tushita=" .. tostring(TushitaMastery))
                        return
                    end

                    -- выбираем, какой меч качать дальше
                    ChooseWeaponForFarm()
                end

                RunMasteryLoop()
            end
        end)
        if not ok then
            AddLog("Ошибка в основном цикле: " .. tostring(err))
        end
    end
end)
