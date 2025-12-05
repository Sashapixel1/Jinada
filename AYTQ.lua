--========================================================
--  Auto Yama / Auto Tushita (каркас + логика из 12к)
--========================================================

-----------------------------
-- НАСТРОЙКИ
-----------------------------
local WeaponName   = "Godhuman"           -- чем бить боссов
local TeleportSpeed = 300                 -- макс. скорость твина (юнитов/сек)
local FarmOffset    = CFrame.new(0, 10, 0)

-----------------------------
-- СЕРВИСЫ
-----------------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local remote      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-----------------------------
-- NET / АТАКА (как в AutoBones)
-----------------------------
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

-----------------------------
-- ФЛАГИ / СОСТОЯНИЕ
-----------------------------
local AutoTushita = false
local AutoYama    = false

local CurrentStatus = "Idle"

local IsTeleporting = false
local StopTween     = false
local NoclipEnabled = false

-- Elite Hunter (Yama)
local lastEliteQuestRequest   = 0
local ELITE_QUEST_INTERVAL    = 60
local lastEliteProgressCheck  = 10
local ELITE_PROGRESS_INTERVAL = 10
local CachedEliteProgress     = 0

-- Rip Indra Summon
local lastRipSummonAttempt = 0
local RIP_SUMMON_INTERVAL  = 30
local lastRipNotSpawnLog   = 0
local RIP_LOG_INTERVAL     = 10

-- точки
local FloatingTurtlePos = CFrame.new(-9552, 392, -9537)
local LongmaSpawnPos    = CFrame.new(-10238.8759, 389.7913, -9549.7939)
local CastleOnSeaPos    = CFrame.new(-5037, 316, -3154)

-----------------------------
-- ЛОГИ / GUI
-----------------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame
local StatusLabel, LogsText
local TushitaButton, YamaButton

local function AddLog(msg)
    local timestamp = os.date("%H:%M:%S")
    local entry = "["..timestamp.."] "..tostring(msg)

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
    AddLog("Статус: "..text)
    if StatusLabel then
        StatusLabel.Text = "Статус: "..text
    end
end

-----------------------------
-- NOCLIP
-----------------------------
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

-----------------------------
-- ВСПОМОГАТЕЛЬНОЕ
-----------------------------
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
    local nameLower = string.lower(name)
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and string.lower(obj.Name) == nameLower then
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
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local nameLower = string.lower(name)
    local function findTool(container)
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

    local toolFound
    local backpack = p:FindFirstChild("Backpack")
    if backpack then
        toolFound = findTool(backpack)
    end
    if not toolFound and char then
        toolFound = findTool(char)
    end

    if toolFound then
        hum:UnequipTools()
        hum:EquipTool(toolFound)
        AddLog("⚔️ Экипирован: "..toolFound.Name)
    else
        if tick() - lastEquipFailLog > 3 then
            AddLog("⚠️ Не удалось найти оружие: "..name)
            lastEquipFailLog = tick()
        end
    end
end

local function HasSword(swordName)
    local p = LocalPlayer
    if not p then return false end

    local backpack = p:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(swordName) then
        return true
    end
    local char = p.Character
    if char and char:FindFirstChild(swordName) then
        return true
    end
    return false
end

-----------------------------
-- ТЕЛЕПОРТ (ограничение 300 скорости)
-----------------------------
local function SimpleTeleport(targetCFrame, label)
    label = label or "цели"
    if IsTeleporting then return end
    IsTeleporting = true
    StopTween = false

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then
        IsTeleporting = false
        return
    end

    local distance   = (hrp.Position - targetCFrame.Position).Magnitude
    local travelTime = distance / TeleportSpeed
    if travelTime < 0.5 then travelTime = 0.5 end
    if travelTime > 60  then travelTime = 60  end

    AddLog(string.format("Телепорт к %s (%.0f stud, speed=%d)", label, distance, TeleportSpeed))

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

        char = LocalPlayer.Character
        hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and hrp) then
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
    char = LocalPlayer.Character
    hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide = false
    end
    IsTeleporting = false
end

LocalPlayer.CharacterAdded:Connect(function()
    IsTeleporting = false
    StopTween     = false
    AddLog("Персонаж возрождён, телепорты / фарм можно продолжать.")
end)

-----------------------------
-- УТИЛИТЫ ДЛЯ КАРТЫ / БОССОВ
-----------------------------
local function GetTurtleMap()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("Turtle")
end

local function GetSealedKatanaHandle()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil, nil end
    local waterfall = map:FindFirstChild("Waterfall")
    if not waterfall then return nil, nil end
    local sealed = waterfall:FindFirstChild("SealedKatana")
    if not sealed then return nil, nil end
    local handle = sealed:FindFirstChild("Handle")
    if not handle then return nil, nil end
    local cd = handle:FindFirstChildOfClass("ClickDetector")
    return handle, cd
end

local function CheckNameBoss(nameOrList)
    local function checkContainer(container)
        for _, v in ipairs(container:GetChildren()) do
            if v:IsA("Model")
                and v:FindFirstChild("Humanoid")
                and v.Humanoid.Health > 0
            then
                if typeof(nameOrList) == "table" then
                    if table.find(nameOrList, v.Name) then
                        return v
                    end
                else
                    if v.Name == nameOrList then
                        return v
                    end
                end
            end
        end
    end

    local rep     = ReplicatedStorage
    local enemies = Workspace:FindFirstChild("Enemies")

    local found = checkContainer(rep)
    if found then return found end
    if enemies then
        found = checkContainer(enemies)
        if found then return found end
    end
    return nil
end

local function CheckTorch()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    local turtle = map:FindFirstChild("Turtle")
    if not turtle then return nil end
    local torchesFolder = turtle:FindFirstChild("QuestTorches")
    if not torchesFolder then return nil end

    local idx
    if not torchesFolder.Torch1.Particles.Main.Enabled then
        idx = "1"
    elseif not torchesFolder.Torch2.Particles.Main.Enabled then
        idx = "2"
    elseif not torchesFolder.Torch3.Particles.Main.Enabled then
        idx = "3"
    elseif not torchesFolder.Torch4.Particles.Main.Enabled then
        idx = "4"
    elseif not torchesFolder.Torch5.Particles.Main.Enabled then
        idx = "5"
    end

    if not idx then return nil end

    for _, v in ipairs(torchesFolder:GetChildren()) do
        if v:IsA("MeshPart") and string.find(v.Name, idx) and (not v.Particles.Main.Enabled) then
            return v
        end
    end
    return nil
end

-----------------------------
-- ELITE HUNTER (Yama)
-----------------------------
local function GetEliteHunterProgress()
    if tick() - lastEliteProgressCheck < ELITE_PROGRESS_INTERVAL then
        return CachedEliteProgress
    end
    lastEliteProgressCheck = tick()

    local ok, res = pcall(function()
        return remote:InvokeServer("EliteHunter", "Progress")
    end)
    if ok and type(res) == "number" then
        CachedEliteProgress = res
        AddLog("EliteHunter прогресс: "..tostring(res).."/30")
    else
        AddLog("⚠️ Не удалось получить прогресс EliteHunter: "..tostring(res))
    end
    return CachedEliteProgress
end

local function TeleportToEliteHunterNpc()
    SimpleTeleport(CastleOnSeaPos, "Elite Hunter NPC")
end

local function RequestEliteHunterQuestIfNeeded()
    local now = tick()
    if now - lastEliteQuestRequest < ELITE_QUEST_INTERVAL then
        return
    end
    lastEliteQuestRequest = now

    TeleportToEliteHunterNpc()
    task.wait(1)

    AddLog("Пробую взять квест Elite Hunter.")
    local ok, res = pcall(function()
        return remote:InvokeServer("EliteHunter")
    end)
    if ok then
        AddLog("Квест EliteHunter запрошен.")
    else
        AddLog("⚠️ Ошибка при запросе квеста EliteHunter: "..tostring(res))
    end
end

-----------------------------
-- ФАЙТ С БОССОМ (общий)
-----------------------------
local function FightBossOnce(bossModel, bossLabel)
    if not bossModel then return end
    local hum = bossModel:FindFirstChild("Humanoid")
    local hrp = bossModel:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then
        return
    end

    bossLabel = bossLabel or bossModel.Name
    AddLog("Начинаю бой с "..bossLabel..".")

    local deadline     = tick() + 90
    local lastAttack   = 0
    local lastRecenter = 0

    while AutoTushita or AutoYama do
        if not bossModel.Parent then break end
        hum = bossModel:FindFirstChild("Humanoid")
        hrp = bossModel:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then
            break
        end
        if tick() > deadline then
            AddLog("⚠️ Бой с "..bossLabel.." затянулся, выхожу.")
            break
        end

        local char = LocalPlayer.Character
        local chrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and chrp) then break end

        if tick() - lastRecenter > 0.05 then
            chrp.CFrame = hrp.CFrame * FarmOffset
            chrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
            chrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
            chrp.CanCollide              = false
            lastRecenter = tick()
        end

        pcall(function()
            hrp.CanCollide = false
            hum.WalkSpeed  = 0
            hum.JumpPower  = 0
        end)

        AutoHaki()
        EquipToolByName(WeaponName)

        if tick() - lastAttack > 0.15 then
            AttackModule:AttackEnemyModel(bossModel)
            lastAttack = tick()
        end

        RunService.Heartbeat:Wait()
    end

    hum = bossModel:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then
        AddLog("✅ "..bossLabel.." убит.")
    else
        AddLog("⚠️ Бой с "..bossLabel.." завершён неудачно или прерван.")
    end
end

-----------------------------
-- SUMMON RIP INDRA (через ZQuestProgress)
-----------------------------
local function SummonRipIndra()
    lastRipSummonAttempt = tick()
    AddLog("Статус: Tushita: пытаюсь призвать rip_indra.")

    -- 1. Проверяем состояние ZQuest
    local okCheck, checkState = pcall(function()
        return remote:InvokeServer("ZQuestProgress", "Check")
    end)

    if not okCheck then
        AddLog("Ошибка ZQuestProgress Check: "..tostring(checkState))
        return
    end

    AddLog("ZQuestProgress Check: "..tostring(checkState))

    if checkState == 0 then
        -- Квест ещё не начат, запускаем
        local okBegin, beginRes = pcall(function()
            return remote:InvokeServer("ZQuestProgress", "Begin")
        end)
        if okBegin then
            AddLog("Пробую призвать rip_indra через ZQuestProgress Begin: "..tostring(beginRes))
        else
            AddLog("Ошибка при ZQuestProgress Begin: "..tostring(beginRes))
        end
    else
        -- Уже есть какой-то прогресс, смотрим General
        local okGen, gen = pcall(function()
            return remote:InvokeServer("ZQuestProgress", "Progress", "General")
        end)
        if okGen then
            AddLog("ZQuestProgress General: "..tostring(gen))
            if gen ~= 0 and gen ~= nil then
                AddLog("ZQuestProgress General != 0 (nil), ивент уже активен или в процессе.")
            end
        else
            AddLog("Ошибка ZQuestProgress Progress General: "..tostring(gen))
        end
    end
end

-----------------------------
-- ЛОГИКА YAMA
-----------------------------
local function RunYamaLogic()
    if HasSword("Yama") then
        UpdateStatus("Yama уже есть.")
        return
    end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return end

    local distToCastle = (hrp.Position - CastleOnSeaPos.Position).Magnitude
    if distToCastle > 1500 then
        UpdateStatus("Yama: нужно быть в 3-м море (Castle On The Sea).")
        SimpleTeleport(CastleOnSeaPos, "Castle On The Sea")
        return
    end

    local progress = GetEliteHunterProgress()
    if progress < 30 then
        UpdateStatus(string.format("Yama: фарм Elite Hunter (%d/30).", progress))
        RequestEliteHunterQuestIfNeeded()
        return
    end

    UpdateStatus("Yama: прогресс 30/30, кликаю SealedKatana.")

    local handle, cd = GetSealedKatanaHandle()
    if not handle or not cd then
        AddLog("❌ Waterfall / SealedKatana не найден.")
        return
    end

    SimpleTeleport(handle.CFrame * CFrame.new(0, 4, 2), "Waterfall SealedKatana")
    task.wait(1)

    local attempts = 0
    repeat
        if HasSword("Yama") or not AutoYama then break end
        attempts = attempts + 1
        AddLog("Yama: клик по SealedKatana (#"..attempts..").")
        pcall(function()
            fireclickdetector(cd)
        end)
        task.wait(0.4)
    until HasSword("Yama") or not AutoYama

    if HasSword("Yama") then
        UpdateStatus("✅ Yama получена.")
    else
        UpdateStatus("Yama: клик по мечу завершён, меч не найден (проверь условия).")
    end
end

-----------------------------
-- ЛОГИКА TUSHITA
-----------------------------
local function RunTushitaLogic()
    if HasSword("Tushita") then
        UpdateStatus("Tushita уже есть.")
        return
    end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return end

    local turtleMap = GetTurtleMap()
    if not turtleMap then
        UpdateStatus("Tushita: лечу на Floating Turtle.")
        SimpleTeleport(FloatingTurtlePos, "Floating Turtle")
        return
    end

    -- 1) Если двери ещё нет — фарм Longma
    if not turtleMap:FindFirstChild("TushitaGate") then
        UpdateStatus("Tushita: фарм Longma для открытия двери.")

        local longma = CheckNameBoss("Longma [Lv. 2000] [Boss]") or CheckNameBoss("Longma")
        if longma then
            FightBossOnce(longma, "Longma")
        else
            AddLog("❌ Longma не найден, жду спавна (ТП к споту).")
            SimpleTeleport(LongmaSpawnPos, "Longma spawn")
        end
        return
    end

    -- 2) Дверь уже есть => работаем с rip_indra / Holy Torch
    local ripIndra = CheckNameBoss("rip_indra True Form [Lv. 5000] [Raid Boss]") or
                     CheckNameBoss("rip_indra True Form") or
                     CheckNameBoss("rip_indra")

    if ripIndra then
        -- rip_indra есть
        if not LocalPlayer.Character:FindFirstChild("Holy Torch")
           and not LocalPlayer.Backpack:FindFirstChild("Holy Torch") then
            UpdateStatus("Tushita: нужен Holy Torch, иду к секретной комнате Waterfall.")
            local map = Workspace:FindFirstChild("Map")
            local wf  = map and map:FindFirstChild("Waterfall")
            local secret = wf and wf:FindFirstChild("SecretRoom")
            local room   = secret and secret:FindFirstChild("Room")
            local door   = room and room:FindFirstChild("Door")
            local hitbox = door and door:FindFirstChild("Door") and door.Door:FindFirstChild("Hitbox")

            if hitbox then
                SimpleTeleport(hitbox.CFrame, "Waterfall Secret Room door")
            else
                AddLog("❌ Не удалось найти Hitbox двери SecretRoom.")
            end
        else
            UpdateStatus("Tushita: есть Holy Torch, ищу незажжённый факел.")
            EquipToolByName("Holy Torch")
            local torch = CheckTorch()
            if torch then
                SimpleTeleport(torch.CFrame, "Quest Torch")
            else
                AddLog("Все факелы выглядят зажжёнными, возможно, этап завершён.")
            end
        end
        return
    else
        -- rip_indra ещё нет: логируем не чаще, чем раз в RIP_LOG_INTERVAL,
        -- и раз в RIP_SUMMON_INTERVAL пробуем его призвать.
        local now = tick()

        if now - lastRipNotSpawnLog > RIP_LOG_INTERVAL then
            lastRipNotSpawnLog = now
            AddLog("Rip Indra не заспавнен, жду и/или проверь квест Summon.")
        end

        if now - lastRipSummonAttempt > RIP_SUMMON_INTERVAL then
            UpdateStatus("Tushita: дверь есть, пытаюсь призвать rip_indra.")
            SummonRipIndra()
        else
            UpdateStatus("Tushita: дверь есть, работаю с rip_indra / Holy Torch.")
        end

        return
    end
end

-----------------------------
-- GUI (высота 600)
-----------------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaTushitaGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 420, 0, 600)
    MainFrame.Position = UDim2.new(0, 40, 0, 100)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Title.Text = "Auto Yama / Tushita (12k логика)"
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
    StatusLabel.Text = "Статус: "..CurrentStatus
    StatusLabel.Parent = MainFrame

    TushitaButton = Instance.new("TextButton")
    TushitaButton.Size = UDim2.new(0, 180, 0, 32)
    TushitaButton.Position = UDim2.new(0, 10, 0, 60)
    TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TushitaButton.TextColor3 = Color3.new(1,1,1)
    TushitaButton.Font = Enum.Font.SourceSansBold
    TushitaButton.TextSize = 16
    TushitaButton.Text = "Auto Tushita: OFF"
    TushitaButton.Parent = MainFrame

    YamaButton = Instance.new("TextButton")
    YamaButton.Size = UDim2.new(0, 180, 0, 32)
    YamaButton.Position = UDim2.new(0, 210, 0, 60)
    YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    YamaButton.TextColor3 = Color3.new(1,1,1)
    YamaButton.Font = Enum.Font.SourceSansBold
    YamaButton.TextSize = 16
    YamaButton.Text = "Auto Yama: OFF"
    YamaButton.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 480)
    LogsFrame.Position = UDim2.new(0, 10, 0, 100)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    LogsFrame.BorderSizePixel = 0
    LogsFrame.Parent = MainFrame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -4)
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0,0,8,0)
    scroll.ScrollBarThickness = 6
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
            NoclipEnabled = true
            UpdateStatus("Фарм Tushita / Longma / факелы.")
        else
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled = false
            UpdateStatus("Остановлен")
            StopTween = true
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
            NoclipEnabled = true
            UpdateStatus("Фарм Yama / Elite Hunter.")
        else
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled = false
            UpdateStatus("Остановлен")
            StopTween = true
        end
    end)
end

CreateGui()
AddLog("Auto Yama / Tushita загружен. Включай нужный режим в 3-м море.")

-----------------------------
-- ОСНОВНОЙ ЦИКЛ
-----------------------------
task.spawn(function()
    while task.wait(0.5) do
        local ok, err = pcall(function()
            if AutoTushita then
                RunTushitaLogic()
            elseif AutoYama then
                RunYamaLogic()
            end
        end)
        if not ok then
            AddLog("❌ Ошибка в основном цикле: "..tostring(err))
        end
    end
end)
