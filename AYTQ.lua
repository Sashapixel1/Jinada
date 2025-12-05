--========================================================
-- Auto Yama / Auto Tushita
-- CDK-flow + лог-панель
--========================================================

---------------------
-- НАСТРОЙКИ
---------------------
local WeaponName    = "Godhuman"             -- базовое оружие ближнего боя
local TeleportSpeed = 300                    -- скорость твин-полёта
local FarmOffset    = CFrame.new(0, 10, -3)  -- позиция над мобом

---------------------
-- ФЛАГИ GUI
---------------------
local AutoTushita   = false
local AutoYama      = false
local CurrentStatus = "Idle"

---------------------
-- ЛОГИ
---------------------
local StatusLogs   = {}
local MaxLogs      = 100
local LogsText     = nil
local StatusLabel  = nil

local function AddLog(msg)
    local timestamp = os.date("%H:%M:%S")
    local entry = "[" .. timestamp .. "] " .. tostring(msg)
    table.insert(StatusLogs, 1, entry)
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
    if LogsText then
        LogsText.Text = table.concat(StatusLogs, "\n")
        -- можно при желании подстраивать CanvasSize тут
    end
end

local function UpdateStatus(text)
    CurrentStatus = text
    AddLog("Статус: " .. text)
    if StatusLabel then
        StatusLabel.Text = "Статус: " .. CurrentStatus
    end
end

---------------------
-- СЕРВИСЫ
---------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualInput      = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local remote     = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- NET MODULE (FAST ATTACK)
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
-- Noclip
---------------------
local NoclipEnabled = false

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

---------------------
-- АВТО-ХАКИ / ЭКИП
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

local function IsToolEquipped(name)
    local char = LocalPlayer.Character
    if not char then return false end
    local targetLower = string.lower(name)
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and string.lower(obj.Name) == targetLower then
            return true
        end
    end
    return false
end

local lastEquipFailLog = 0
local function EquipToolByName(name)
    if IsToolEquipped(name) then
        return
    end

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

---------------------
-- ТЕЛЕПОРТ (SimpleTeleport)
---------------------
local IsTeleporting = false
local StopTween     = false

local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting then return end
    IsTeleporting = true
    StopTween     = false

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        IsTeleporting = false
        return
    end

    local hrp = char.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    AddLog(string.format("Телепорт к %s (%.0f юнитов)", label or "цели", distance))

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
            AddLog("Телепорт прерван (StopTween)")
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
        hrp.CanCollide = false

        task.wait(0.2)
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

-- фикс после смерти
LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = false
    AddLog("Персонаж возрождён, HRP ожидается...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, можно продолжать.")
end)

---------------------
-- ИНВЕНТАРЬ / МАТЕРИАЛЫ
---------------------
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
    end
    return false
end

local function GetMaterial(matName)
    local ok, invData = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if ok and type(invData) == "table" then
        for _, item in ipairs(invData) do
            local name  = item.Name or item.name or tostring(item)
            local count = item.Count or item.count or 0
            if name == matName then
                return count
            end
        end
    end
    return 0
end

local function HasYama()
    return HasItemInInventory("Yama")
end

local function HasTushita()
    return HasItemInInventory("Tushita")
end

---------------------
-- Alucard Fragment стейджи
---------------------
local function NeedYamaQuest2()
    return GetMaterial("Alucard Fragment") == 1
end

local function NeedYamaQuest3()
    return GetMaterial("Alucard Fragment") == 2
end

local function NeedTushitaTorchRoute()
    return GetMaterial("Alucard Fragment") == 3
end

local function NeedTushitaHeaven()
    return GetMaterial("Alucard Fragment") == 5
end

---------------------
-- ХЕЛПЕР БОЯ
---------------------
local function FightMobModel(target, label, timeout)
    timeout = timeout or 40

    if not target then return end

    local startTime = tick()
    local engaged   = false

    AddLog(string.format("Начинаю бой с %s (%s)", target.Name or "?", label or "mob"))

    while tick() - startTime < timeout do
        if not target or not target.Parent then break end

        local hum = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not hum or not tHRP or hum.Health <= 0 then break end

        engaged = true

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then break end

        local dist = (tHRP.Position - hrp.Position).Magnitude
        if dist > 2000 then
            SimpleTeleport(tHRP.CFrame * FarmOffset, label or "mob")
        else
            hrp.CFrame = tHRP.CFrame * FarmOffset
            hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
            hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
            hrp.CanCollide = false
        end

        -- фиксим моба
        pcall(function()
            tHRP.CanCollide = false
            tHRP.Transparency = 0
            hum.WalkSpeed = 0
            hum.JumpPower = 0

            if not tHRP:FindFirstChild("BodyVelocity") then
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = Vector3.new(0,0,0)
                bv.Parent = tHRP
            end

            for _, part in ipairs(target:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                end
            end
        end)

        AutoHaki()
        EquipToolByName(WeaponName)
        AttackModule:AttackEnemyModel(target)

        RunService.Heartbeat:Wait()
    end

    if engaged then
        local hum = target:FindFirstChild("Humanoid")
        if hum and hum.Health <= 0 then
            AddLog("✅ Моб " .. (target.Name or "?") .. " убит.")
        else
            AddLog("⚠️ Бой с " .. (target.Name or "?") .. " прерван.")
        end
    else
        AddLog("⚠️ Не удалось начать бой с " .. (target and target.Name or "?"))
    end
end

---------------------
-- YAMA QUEST 2 (HazeESP)
---------------------
local function FindNearestHazeMob(maxDistance)
    maxDistance = maxDistance or 9999
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then return nil end

    local nearest, bestDist = nil, maxDistance

    for _, v in ipairs(enemies:GetChildren()) do
        local hum  = v:FindFirstChild("Humanoid")
        local tHRP = v:FindFirstChild("HumanoidRootPart")
        if hum and tHRP and hum.Health > 0 and v:FindFirstChild("HazeESP") then
            local d = (tHRP.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                nearest  = v
            end
        end
    end

    return nearest
end

local function BoostHazeESP()
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, v in ipairs(enemies:GetChildren()) do
            local gui = v:FindFirstChild("HazeESP")
            if gui then
                gui.Size        = UDim2.new(50, 50, 50, 50)
                gui.MaxDistance = "inf"
            end
        end
    end

    for _, v in ipairs(ReplicatedStorage:GetChildren()) do
        local gui = v:FindFirstChild("HazeESP")
        if gui then
            gui.Size        = UDim2.new(50, 50, 50, 50)
            gui.MaxDistance = "inf"
        end
    end
end

local function RunYamaQuest2()
    if not NeedYamaQuest2() then
        return
    end

    local af = GetMaterial("Alucard Fragment")
    AddLog("YamaQuest2: Alucard Fragment = " .. tostring(af))

    UpdateStatus("Yama Quest 2: поиск HazeESP")
    BoostHazeESP()

    local target = FindNearestHazeMob(9999)
    if not target then
        AddLog("YamaQuest2: HazeESP моб не найден, жду...")
        task.wait(2)
        return
    end

    AddLog("YamaQuest2: цель " .. target.Name)
    UpdateStatus("Yama Quest 2: бой с " .. target.Name)
    FightMobModel(target, "YamaQuest2", 60)
end

---------------------
-- YAMA QUEST 3 (HellDimension)
---------------------
local function RunYamaQuest3()
    if not NeedYamaQuest3() then
        return
    end

    local af = GetMaterial("Alucard Fragment")
    AddLog("YamaQuest3: Alucard Fragment = " .. tostring(af))

    local map = Workspace:FindFirstChild("Map")

    -- 1) если Hallow Essence в рюкзаке -> идём к Summoner
    if HasItemInInventory("Hallow Essence") and map and map:FindFirstChild("Haunted Castle") then
        local summoner = map["Haunted Castle"]:FindFirstChild("Summoner")
        if summoner and summoner:FindFirstChild("Detection") then
            UpdateStatus("Yama Quest 3: Summoner (Haunted Castle)")
            SimpleTeleport(summoner.Detection.CFrame, "Summoner")
            task.wait(1.5)
        end
    end

    map = Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("HellDimension") then
        UpdateStatus("Yama Quest 3: HellDimension")
        AddLog("YamaQuest3: HellDimension найден.")

        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then
            AddLog("YamaQuest3: enemies не найдены.")
            return
        end

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then
            AddLog("YamaQuest3: нет персонажа / HRP.")
            return
        end

        local function pickHellMob()
            local best, bestDist = nil, 9999
            for _, v in ipairs(enemies:GetChildren()) do
                local name = v.Name
                if name == "Cursed Skeleton" or name == "Cursed Skeleton Boss" or name == "Hell's Messenger" then
                    local hum  = v:FindFirstChild("Humanoid")
                    local tHRP = v:FindFirstChild("HumanoidRootPart")
                    if hum and tHRP and hum.Health > 0 then
                        local d = (tHRP.Position - hrp.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
                            best     = v
                        end
                    end
                end
            end
            return best
        end

        while NeedYamaQuest3() do
            local mob = pickHellMob()
            if not mob then
                AddLog("YamaQuest3: мобов в аду нет, жду...")
                task.wait(2)
            else
                AddLog("YamaQuest3: бой с " .. mob.Name)
                FightMobModel(mob, "HellDimension", 60)
            end

            if GetMaterial("Alucard Fragment") >= 3 then
                AddLog("YamaQuest3: Alucard Fragment >= 3, этап ада закончен.")
                break
            end
        end

        return
    end

    -- 3) попытка активировать HellDimension
    if map and map:FindFirstChild("HellDimension") and map.HellDimension:FindFirstChild("Torch1") then
        UpdateStatus("Yama Quest 3: активация ада (Torch1)")
        SimpleTeleport(map.HellDimension.Torch1.CFrame, "Hell Torch1")
        task.wait(1.5)
        AddLog("YamaQuest3: пробую нажать E у факела.")
        VirtualInput:SendKeyEvent(true, "E", false, game)
        task.wait(0.3)
        VirtualInput:SendKeyEvent(false, "E", false, game)
    else
        AddLog("YamaQuest3: HellDimension / Torch1 не найдены в карте.")
    end
end

---------------------
-- TUSHITA TRIAL
---------------------

-- Координаты факелов (Tushita_1)
local TorchRoute = {
    CFrame.new(-9546.990234375, 21.139892578125, 4686.1142578125),
    CFrame.new(-6120.0576171875, 16.455780029296875, -2250.697265625),
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875),
}

local function RunTushitaTorchRoute()
    UpdateStatus("Tushita: маршрут факелов")
    AddLog("Tushita: старт маршрута факелов (этап 3).")

    for i, cf in ipairs(TorchRoute) do
        SimpleTeleport(cf, "Torch " .. i)
        AddLog("Tushita: Torch " .. i .. " достигнут, жду 5 сек.")
        task.wait(5)
    end
end

local function RunTushitaHeaven()
    local map = Workspace:FindFirstChild("Map")
    if not map then
        AddLog("Tushita: Map не найден.")
        return
    end

    if not map:FindFirstChild("HeavenlyDimension") then
        UpdateStatus("Tushita: ищу портал в небесное измерение")
        AddLog("Tushita: HeavenlyDimension ещё не открыт, лечу к порталу.")
        SimpleTeleport(CFrame.new(-709.3132934570312, 381.6005859375, -11011.396484375), "Heaven portal")
        task.wait(3)
        return
    end

    UpdateStatus("Tushita: HeavenlyDimension")
    AddLog("Tushita: HeavenlyDimension найден.")

    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then
        AddLog("Tushita: enemies не найдены.")
        return
    end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then
        AddLog("Tushita: нет персонажа / HRP.")
        return
    end

    local function pickHeavenMob()
        local best, bestDist = nil, 9999
        for _, v in ipairs(enemies:GetChildren()) do
            local name = v.Name
            if name == "Cursed Skeleton" or name == "Cursed Skeleton Boss" or name == "Heaven's Guardian" then
                local hum  = v:FindFirstChild("Humanoid")
                local tHRP = v:FindFirstChild("HumanoidRootPart")
                if hum and tHRP and hum.Health > 0 then
                    local d = (tHRP.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best     = v
                    end
                end
            end
        end
        return best
    end

    while NeedTushitaHeaven() do
        local mob = pickHeavenMob()
        if not mob then
            AddLog("Tushita: мобов в небесном измерении нет, жду...")
            task.wait(2)
        else
            AddLog("Tushita: бой с " .. mob.Name)
            FightMobModel(mob, "HeavenlyDimension", 60)
        end

        if GetMaterial("Alucard Fragment") >= 6 then
            AddLog("Tushita: Alucard Fragment >= 6, HeavenlyDimension-этап закончен.")
            break
        end
    end
end

local function RunTushitaTrial()
    local af = GetMaterial("Alucard Fragment")
    AddLog("TushitaTrial: Alucard Fragment = " .. tostring(af))

    if NeedTushitaTorchRoute() then
        AddLog("TushitaTrial: активен этап факелов (3).")
        RunTushitaTorchRoute()
    elseif NeedTushitaHeaven() then
        AddLog("TushitaTrial: активен этап HeavenlyDimension (5).")
        RunTushitaHeaven()
    else
        AddLog("TushitaTrial: сейчас не Tushita-этап (нужны AF=3 или AF=5).")
    end
end

---------------------
-- КРЮЧКИ ДЛЯ GUI
---------------------
local function RunTushitaLogic()
    if HasTushita() then
        UpdateStatus("Tushita уже есть")
        AddLog("TushitaLogic: меч уже в инвентаре.")
        return
    end

    UpdateStatus("Фарм Tushita / фрагментов")
    RunTushitaTrial()
end

local function RunYamaLogic()
    if HasYama() then
        UpdateStatus("Yama уже есть")
        AddLog("YamaLogic: меч уже в инвентаре.")
        return
    end

    local af = GetMaterial("Alucard Fragment")
    AddLog("YamaLogic: Alucard Fragment = " .. tostring(af))

    if NeedYamaQuest2() then
        UpdateStatus("Yama Quest 2 (HazeESP)")
        RunYamaQuest2()
    elseif NeedYamaQuest3() then
        UpdateStatus("Yama Quest 3 (HellDimension)")
        RunYamaQuest3()
    else
        UpdateStatus("Жду подходящий этап (Alucard Fragment)")
        AddLog("YamaLogic: сейчас не 2/3 этап по фрагментам (нужны AF=1 или AF=2).")
    end
end

---------------------
-- GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaTushitaGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 380, 0, 260)
    Frame.Position = UDim2.new(0, 40, 0, 200)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Title.Text = "Auto Yama / Tushita (CDK flow)"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.Parent = Frame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 22)
    StatusLabel.Position = UDim2.new(0, 10, 0, 32)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: " .. CurrentStatus
    StatusLabel.Parent = Frame

    local TushitaButton = Instance.new("TextButton")
    TushitaButton.Size = UDim2.new(0, 145, 0, 32)
    TushitaButton.Position = UDim2.new(0, 10, 0, 65)
    TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TushitaButton.TextColor3 = Color3.new(1,1,1)
    TushitaButton.Font = Enum.Font.SourceSansBold
    TushitaButton.TextSize = 16
    TushitaButton.Text = "Auto Tushita: OFF"
    TushitaButton.Parent = Frame

    local YamaButton = Instance.new("TextButton")
    YamaButton.Size = UDim2.new(0, 145, 0, 32)
    YamaButton.Position = UDim2.new(0, 200, 0, 65)
    YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    YamaButton.TextColor3 = Color3.new(1,1,1)
    YamaButton.Font = Enum.Font.SourceSansBold
    YamaButton.TextSize = 16
    YamaButton.Text = "Auto Yama: OFF"
    YamaButton.Parent = Frame

    -- Лог-панель
    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 130)
    LogsFrame.Position = UDim2.new(0, 10, 0, 105)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    LogsFrame.BorderSizePixel = 0
    LogsFrame.Parent = Frame

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

    -- Кнопки
    TushitaButton.MouseButton1Click:Connect(function()
        AutoTushita = not AutoTushita
        if AutoTushita then
            AutoYama = false
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            TushitaButton.Text = "Auto Tushita: ON"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)

            NoclipEnabled = true
            StopTween     = false
            UpdateStatus("Фарм Tushita / фрагментов")
        else
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            NoclipEnabled = false
            StopTween     = true
            UpdateStatus("Остановлен")
        end
    end)

    YamaButton.MouseButton1Click:Connect(function()
        AutoYama = not AutoYama
        if AutoYama then
            AutoTushita = false
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            YamaButton.Text = "Auto Yama: ON"
            YamaButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)

            NoclipEnabled = true
            StopTween     = false
            UpdateStatus("Фарм Yama...")
        else
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            NoclipEnabled = false
            StopTween     = true
            UpdateStatus("Остановлен")
        end
    end)

    -- Основной цикл
    task.spawn(function()
        while task.wait(0.5) do
            if AutoTushita then
                pcall(function()
                    RunTushitaLogic()
                end)
            elseif AutoYama then
                pcall(function()
                    RunYamaLogic()
                end)
            end
        end
    end)

    -- стартовый лог
    AddLog("Auto Yama / Tushita загружен. Использует CDK-фрагменты и Hell/Heaven Dimension.")
end

CreateGui()
