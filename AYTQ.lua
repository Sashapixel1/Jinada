--========================================================
-- Auto Yama / Auto Tushita
-- Каркас + логика боёв/перемещений на основе:
--  - Auto Bones (fast attack / SimpleTeleport / AutoHaki / EquipToolByName)
--  - CDK-квеста из 12к (Alucard Fragment, HellDimension / HeavenlyDimension)
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
-- NET MODULE (FAST ATTACK, как в Auto Bones)
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
        print("[Equip] " .. toolFound.Name)
    else
        if tick() - lastEquipFailLog > 3 then
            print("[Equip] Не найдено оружие: " .. name)
            lastEquipFailLog = tick()
        end
    end
end

---------------------
-- ТЕЛЕПОРТ (SimpleTeleport по образцу Auto Bones)
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
    print(string.format("[TP] К %s (%.0f)", label or "цели", distance))

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
            print("[TP] Прерван (StopTween)")
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
    print("[Char] Персонаж возрождён, жду HRP...")
    char:WaitForChild("HumanoidRootPart", 10)
    print("[Char] HRP найден.")
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
-- СТАТУСЫ Alucard Fragment (как в 12к)
-- 0 -> Yama_1
-- 1 -> Yama_2
-- 2 -> Yama_3
-- 3 -> Tushita_1
-- 4 -> Tushita_2
-- 5 -> Tushita_3
-- 6 -> финал CDK
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
-- ХЕЛПЕР БОЯ ПО МОДЕЛИ МОНСТРА
---------------------
local function FightMobModel(target, label, timeout)
    timeout = timeout or 40

    local startTime = tick()
    local engaged   = false

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
            print("[Fight] " .. (target.Name or "?") .. " убит.")
        else
            print("[Fight] бой прерван: " .. (target.Name or "?"))
        end
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
    if not hrp then return nil end

    local nearest, bestDist
    bestDist = maxDistance

    for _, v in ipairs(enemies:GetChildren()) do
        local hum = v:FindFirstChild("Humanoid")
        local tHRP = v:FindFirstChild("HumanoidRootPart")
        if hum and tHRP and hum.Health > 0 and v:FindFirstChild("HazeESP") then
            local d = (tHRP.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                nearest = v
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

    BoostHazeESP()

    local target = FindNearestHazeMob(9999)
    if not target then
        CurrentStatus = "Yama Quest 2: HazeESP не найден"
        print("[Yama2] HazeESP моб не найден.")
        return
    end

    CurrentStatus = "Yama Quest 2: бой с " .. target.Name
    print("[Yama2] Цель: " .. target.Name)
    FightMobModel(target, "YamaQuest2", 60)
end

---------------------
-- YAMA QUEST 3 (HellDimension)
---------------------
local function RunYamaQuest3()
    if not NeedYamaQuest3() then
        return
    end

    -- 1) если Hallow Essence в рюкзаке -> идём к Summoner
    if HasItemInInventory("Hallow Essence") then
        local map = Workspace:FindFirstChild("Map")
        if map and map:FindFirstChild("Haunted Castle") then
            local summoner = map["Haunted Castle"]:FindFirstChild("Summoner")
            if summoner and summoner:FindFirstChild("Detection") then
                CurrentStatus = "Yama Quest 3: Summoner (Haunted Castle)"
                SimpleTeleport(summoner.Detection.CFrame, "Summoner")
                return
            end
        end
    end

    -- 2) если открыт HellDimension -> фармим Cursed Skeleton / Hell's Messenger
    local map = Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("HellDimension") then
        CurrentStatus = "Yama Quest 3: HellDimension"
        print("[Yama3] HellDimension найден.")

        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return end

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then return end

        local function pickHellMob()
            local best, bestDist
            bestDist = 9999
            for _, v in ipairs(enemies:GetChildren()) do
                local name = v.Name
                if name == "Cursed Skeleton" or name == "Cursed Skeleton Boss" or name == "Hell's Messenger" then
                    local hum = v:FindFirstChild("Humanoid")
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

        -- крутим до тех пор, пока Alucard Fragment не станет 3
        while NeedYamaQuest3() do
            local mob = pickHellMob()
            if not mob then
                print("[Yama3] Мобов в аду нет, жду...")
                task.wait(2)
            else
                print("[Yama3] Бой: " .. mob.Name)
                FightMobModel(mob, "HellDimension", 60)
            end
            if GetMaterial("Alucard Fragment") >= 3 then
                print("[Yama3] Alucard Fragment >= 3, выхожу из ада.")
                break
            end
        end

        return
    end

    -- 3) иначе пытаемся зайти в HellDimension (активируем факел/свиток в 12к это через Torch)
    -- тут просто телепорт к Torch1 HellDimension, и жмём "E"
    if map and map:FindFirstChild("HellDimension") and map.HellDimension:FindFirstChild("Torch1") then
        CurrentStatus = "Yama Quest 3: активация ада"
        SimpleTeleport(map.HellDimension.Torch1.CFrame, "Hell Torch1")
        task.wait(1.5)
        VirtualInput:SendKeyEvent(true, "E", false, game)
        task.wait(0.5)
        VirtualInput:SendKeyEvent(false, "E", false, game)
    end
end

---------------------
-- TUSHITA TRIAL (факела + HeavenlyDimension)
---------------------

-- Координаты факелов из 12к (Auto_Quest_Tushita_1)
local TorchRoute = {
    CFrame.new(-9546.990234375, 21.139892578125, 4686.1142578125),
    CFrame.new(-6120.0576171875, 16.455780029296875, -2250.697265625),
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875),
}

local function RunTushitaTorchRoute()
    CurrentStatus = "Tushita Trial: маршрут факелов"
    print("[Tushita] Старт маршрута факелов.")
    for i, cf in ipairs(TorchRoute) do
        SimpleTeleport(cf, "Torch " .. i)
        print("[Tushita] Torch " .. i)
        task.wait(5)
    end
end

local function RunTushitaHeaven()
    local map = Workspace:FindFirstChild("Map")
    if not map then return end

    if not map:FindFirstChild("HeavenlyDimension") then
        -- пробуем подлететь к порталу (из 12к телепорт был в этот район)
        CurrentStatus = "Tushita Trial: ищу портал в небесное измерение"
        SimpleTeleport(CFrame.new(-709.3132934570312, 381.6005859375, -11011.396484375), "Heaven portal")
        task.wait(3)
        return
    end

    CurrentStatus = "Tushita Trial: HeavenlyDimension"
    print("[Tushita] HeavenlyDimension найден.")

    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then return end

    local function pickHeavenMob()
        local best, bestDist
        bestDist = 9999
        for _, v in ipairs(enemies:GetChildren()) do
            local name = v.Name
            if name == "Cursed Skeleton" or name == "Cursed Skeleton Boss" or name == "Heaven's Guardian" then
                local hum = v:FindFirstChild("Humanoid")
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
            print("[Tushita] Мобов в небесном измерении нет, жду...")
            task.wait(2)
        else
            print("[Tushita] Бой: " .. mob.Name)
            FightMobModel(mob, "HeavenlyDimension", 60)
        end
        if GetMaterial("Alucard Fragment") >= 6 then
            print("[Tushita] Alucard Fragment >= 6, выходим из небесного измерения.")
            break
        end
    end
end

local function RunTushitaTrial()
    -- Структура по Alucard Fragment:
    if NeedTushitaTorchRoute() then
        RunTushitaTorchRoute()
    end
    if NeedTushitaHeaven() then
        RunTushitaHeaven()
    end
end

---------------------
-- КРЮЧКИ ДЛЯ GUI
---------------------
local function RunTushitaLogic()
    if HasTushita() then
        CurrentStatus = "Tushita уже есть"
        print("[Tushita] Меч уже в инвентаре.")
        return
    end

    CurrentStatus = "Фарм Tushita / фрагментов"
    -- основной сценарий: двигаем CDK-прогресс в части Тушиты
    RunTushitaTrial()
end

local function RunYamaLogic()
    if HasYama() then
        CurrentStatus = "Yama уже есть"
        print("[Yama] Меч уже в инвентаре.")
        return
    end

    if NeedYamaQuest2() then
        RunYamaQuest2()
    elseif NeedYamaQuest3() then
        RunYamaQuest3()
    else
        CurrentStatus = "Жду подходящий этап (Alucard Fragment)"
        print("[Yama] Сейчас не этап 2/3 по фрагментам.")
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
    Frame.Size = UDim2.new(0, 340, 0, 180)
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

    local StatusLabel = Instance.new("TextLabel")
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
    YamaButton.Position = UDim2.new(0, 180, 0, 65)
    YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    YamaButton.TextColor3 = Color3.new(1,1,1)
    YamaButton.Font = Enum.Font.SourceSansBold
    YamaButton.TextSize = 16
    YamaButton.Text = "Auto Yama: OFF"
    YamaButton.Parent = Frame

    TushitaButton.MouseButton1Click:Connect(function()
        AutoTushita = not AutoTushita
        if AutoTushita then
            AutoYama = false
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            TushitaButton.Text = "Auto Tushita: ON"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)

            CurrentStatus  = "Фарм Tushita..."
            NoclipEnabled  = true
            StopTween      = false
        else
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            CurrentStatus  = "Остановлен"
            NoclipEnabled  = false
            StopTween      = true
        end
        StatusLabel.Text = "Статус: " .. CurrentStatus
    end)

    YamaButton.MouseButton1Click:Connect(function()
        AutoYama = not AutoYama
        if AutoYama then
            AutoTushita = false
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            YamaButton.Text = "Auto Yama: ON"
            YamaButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)

            CurrentStatus  = "Фарм Yama..."
            NoclipEnabled  = true
            StopTween      = false
        else
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            CurrentStatus  = "Остановлен"
            NoclipEnabled  = false
            StopTween      = true
        end
        StatusLabel.Text = "Статус: " .. CurrentStatus
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if AutoTushita then
                pcall(RunTushitaLogic)
            elseif AutoYama then
                pcall(RunYamaLogic)
            end
            StatusLabel.Text = "Статус: " .. CurrentStatus
        end
    end)
end

CreateGui()
