--========================================================
-- Auto Yama / Tushita (получение мечей) + GUI + ЛОГИ
-- Основано на:
--   - логике боя/телепортов из Auto Bones (Godhuman)
--   - логике Auto Yama / Auto Get Tushita из 12к (NoxHub)
--========================================================

---------------------
-- НАСТРОЙКИ
---------------------
local WeaponName = "Godhuman"            -- чем бить боссов
local TeleportSpeed = 300                -- скорость полёта
local BossOffset = CFrame.new(0, 10, -3) -- позиция над боссом

---------------------
-- СЕРВИСЫ
---------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- ФЛАГИ / СОСТОЯНИЕ
---------------------
local AutoTushita = false
local AutoYama = false
local CurrentStatus = "Idle"

local IsTeleporting = false
local StopTween = false
local NoclipEnabled = false
local IsFighting = false

---------------------
-- NET MODULE ДЛЯ FAST ATTACK (как в bones)
---------------------
local modules = ReplicatedStorage:WaitForChild("Modules")
local net = modules:WaitForChild("Net")
local RegisterAttack = net:WaitForChild("RE"):WaitForChild("RegisterAttack")
local RegisterHit = net:WaitForChild("RE"):WaitForChild("RegisterHit")

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
local MaxLogs = 120

local ScreenGui, MainFrame
local StatusLabel
local TushitaButton, YamaButton
local LogsText

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
    if StatusLabel then
        StatusLabel.Text = "Статус: "..tostring(text)
    end
    AddLog(text)
end

---------------------
-- NOCLIP
---------------------
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
-- ХАКИ / ЭКИП
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

    local p = LocalPlayer
    if not p then return end

    local char = p.Character or p.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
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

---------------------
-- ЧЕКЕР ИНВЕНТАРЯ
---------------------
local function HasSword(name)
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

    -- пробуем через getInventory (как в bones)
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

local function HasItemSimple(name)
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

---------------------
-- ТЕЛЕПОРТ (как в bones)
---------------------
local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting then return end
    IsTeleporting = true
    StopTween = false

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        IsTeleporting = false
        return
    end

    local hrp = char.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    AddLog(string.format("Телепорт к %s (%.0f студ.)", label or "цели", distance))

    local travelTime = distance / TeleportSpeed
    if travelTime < 0.5 then travelTime = 0.5 end
    if travelTime > 60 then travelTime = 60 end

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

-- ФИКС ПОСЛЕ СМЕРТИ
LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween = false
    IsFighting = false
    AddLog("Персонаж возрождён, ожидание HRP...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, можно продолжать логики Yama/Tushita.")
end)

---------------------
-- ОБЩИЙ БОЙ С БОССОМ (на основе FarmBonesOnce)
---------------------
local function FightBossOnce(target, label)
    if IsFighting then return end
    IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then
            return
        end

        local hum = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not hum or not tHRP or hum.Health <= 0 then
            return
        end

        UpdateStatus("Бой с боссом: "..(label or target.Name))
        AddLog("Нашёл босса: "..tostring(target.Name))

        SimpleTeleport(tHRP.CFrame * BossOffset, label or target.Name)

        local fightDeadline = tick() + 120
        local lastPosAdjust = 0
        local lastAttack = 0
        local engaged = false

        while (AutoYama or AutoTushita)
            and target.Parent
            and hum
            and hum.Health > 0
            and tick() < fightDeadline do

            engaged = true

            char = LocalPlayer.Character
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")

            if not (char and hrp and tHRP and hum) then
                break
            end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * BossOffset, "далёкий босс "..(label or target.Name))
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * BossOffset
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            pcall(function()
                tHRP.CanCollide = false
                hum.WalkSpeed = 0
                hum.JumpPower = 0

                if not tHRP:FindFirstChild("BodyVelocity") then
                    local bv = Instance.new("BodyVelocity", tHRP)
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Vector3.new(0,0,0)
                end

                tHRP.Transparency = 0
                for _, part in ipairs(target:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = 0
                    end
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

        local dead = hum and hum.Health <= 0
        if engaged then
            if dead or not target.Parent then
                AddLog("✅ Босс "..tostring(target.Name).." убит.")
            else
                AddLog("⚠️ Бой с боссом "..tostring(target.Name).." прерван.")
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в FightBossOnce: "..tostring(err))
    end

    IsFighting = false
end

---------------------
-- ВСПОМОГАТЕЛЬНОЕ ДЛЯ YAMA
---------------------
local EliteNPCPos = CFrame.new(-5418.892578125, 313.74130249023, -2826.2260742188)
local EliteNames = {
    ["Diablo"] = true,
    ["Deandre"] = true,
    ["Urban"] = true
}

local function GetEliteProgress()
    local ok, res = pcall(function()
        return remote:InvokeServer("EliteHunter", "Progress")
    end)
    if ok and type(res) == "number" then
        return res
    end
    return 0
end

local function GetQuestTitleText()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return "", false end

    local main = gui:FindFirstChild("Main")
    if not main then return "", false end

    local quest = main:FindFirstChild("Quest")
    if not quest or not quest:FindFirstChild("Container") then
        return "", false
    end

    local container = quest.Container
    local titleGui = container:FindFirstChild("QuestTitle")
    if not titleGui then return "", quest.Visible end

    local titleLabel = titleGui:FindFirstChild("Title")
    if not titleLabel or not titleLabel:IsA("TextLabel") then
        return "", quest.Visible
    end

    return tostring(titleLabel.Text), quest.Visible
end

local function FindEliteBoss()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end

    for _, v in ipairs(enemiesFolder:GetChildren()) do
        if EliteNames[v.Name] then
            local hum = v:FindFirstChild("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                return v
            end
        end
    end
    return nil
end

---------------------
-- ВСПОМОГАТЕЛЬНОЕ ДЛЯ TUSHITA
---------------------
local function CheckNameBoss(nameOrList)
    -- из 12к, но адаптировано
    for _, v in next, game.ReplicatedStorage:GetChildren() do
        if v:IsA("Model")
            and v:FindFirstChild("Humanoid")
            and v.Humanoid.Health > 0 then
            if typeof(nameOrList) == "table" then
                if table.find(nameOrList, v.Name) then
                    return v
                end
            elseif v.Name == nameOrList then
                return v
            end
        end
    end
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, v in next, enemiesFolder:GetChildren() do
            if v:IsA("Model")
                and v:FindFirstChild("Humanoid")
                and v.Humanoid.Health > 0 then
                if typeof(nameOrList) == "table" then
                    if table.find(nameOrList, v.Name) then
                        return v
                    end
                elseif v.Name == nameOrList then
                    return v
                end
            end
        end
    end
    return nil
end

local function CheckTorch()
    -- портированно из 12к (QuestTorches)
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    local turtle = map:FindFirstChild("Turtle")
    if not turtle then return nil end
    local torchesFolder = turtle:FindFirstChild("QuestTorches")
    if not torchesFolder then return nil end

    local a
    if not torchesFolder.Torch1.Particles.Main.Enabled then
        a = "1"
    elseif not torchesFolder.Torch2.Particles.Main.Enabled then
        a = "2"
    elseif not torchesFolder.Torch3.Particles.Main.Enabled then
        a = "3"
    elseif not torchesFolder.Torch4.Particles.Main.Enabled then
        a = "4"
    elseif not torchesFolder.Torch5.Particles.Main.Enabled then
        a = "5"
    end

    if not a then return nil end

    for _, v in next, torchesFolder:GetChildren() do
        if v:IsA("MeshPart") and string.find(v.Name, a) and (not v.Particles.Main.Enabled) then
            return v
        end
    end
    return nil
end

---------------------
-- ЛОГИКА YAMA (получение меча)
---------------------
local function RunYamaLogic()
    -- уже есть меч
    if HasSword("Yama") then
        UpdateStatus("Yama уже есть — скрипт ничего не делает.")
        return
    end

    local progress = GetEliteProgress()
    AddLog("EliteHunter прогресс: "..tostring(progress).."/30")

    -- если прогресс >= 30 — идём к SealedKatana
    if progress >= 30 then
        UpdateStatus("Yama: прогресс 30/30, открываю SealedKatana.")

        local map = Workspace:FindFirstChild("Map")
        if not map then
            AddLog("❌ Не найден Workspace.Map для SealedKatana.")
            return
        end
        local waterfall = map:FindFirstChild("Waterfall")
        if not waterfall then
            AddLog("❌ Не найден Waterfall в карте.")
            return
        end

        local sealed = waterfall:FindFirstChild("SealedKatana")
        if not sealed then
            AddLog("❌ Не найден объект SealedKatana.")
            return
        end

        local handle = sealed:FindFirstChild("Handle") or sealed
        local cd = handle:FindFirstChildOfClass("ClickDetector") or handle:FindFirstChild("ClickDetector")

        SimpleTeleport(handle.CFrame * CFrame.new(0, 4, 3), "SealedKatana")

        for i = 1, 40 do
            if HasSword("Yama") then
                AddLog("✅ Yama получена (меч в инвентаре).")
                return
            end
            if cd then
                pcall(function()
                    fireclickdetector(cd)
                end)
            end
            task.wait(0.25)
        end

        if HasSword("Yama") then
            AddLog("✅ Yama получена после кликов по SealedKatana.")
        else
            AddLog("⚠️ Не удалось получить Yama: проверь условия (урон/киллы элитов и т.п.).")
        end

        return
    end

    -- иначе фарм элитных для EliteHunter
    UpdateStatus("Yama: фарм Elite Hunter ("..tostring(progress).."/30)")

    local title, visible = GetQuestTitleText()
    local eliteAlive = FindEliteBoss()

    if not visible or not (string.find(title, "Diablo") or string.find(title, "Deandre") or string.find(title, "Urban")) then
        -- берём квест
        AddLog("Пробую взять квест Elite Hunter.")
        SimpleTeleport(EliteNPCPos, "Elite Hunter NPC")

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - EliteNPCPos.Position).Magnitude <= 8 then
            pcall(function()
                remote:InvokeServer("EliteHunter")
            end)
            AddLog("Запрошен квест EliteHunter.")
        end
        return
    end

    -- если квест есть и элитный заспавнен — бьём
    eliteAlive = eliteAlive or FindEliteBoss()
    if eliteAlive then
        AddLog("Нашёл элитного босса "..eliteAlive.Name..", начинаю бой для прогресса Yama.")
        FightBossOnce(eliteAlive, "Elite "..eliteAlive.Name)
    else
        AddLog("Элитный босс не найден, жду спавна.")
    end
end

---------------------
-- ЛОГИКА TUSHITA (получение меча)
---------------------
local function RunTushitaLogic()
    -- уже есть меч
    if HasSword("Tushita") then
        UpdateStatus("Tushita уже есть — скрипт ничего не делает.")
        return
    end

    local map = Workspace:FindFirstChild("Map")
    if not map then
        AddLog("❌ Не найден Workspace.Map для логики Tushita.")
        return
    end
    local turtle = map:FindFirstChild("Turtle")
    if not turtle then
        AddLog("❌ Не найден остров Turtle в карте.")
        return
    end

    local gate = turtle:FindFirstChild("TushitaGate")

    -- 1) если дверь TushitaGate ЕЩЁ НЕ появилась — убиваем Longma
    if not gate then
        UpdateStatus("Tushita: ищу и убиваю Longma для открытия двери.")

        local longma = CheckNameBoss("Longma [Lv. 2000] [Boss]")
        if longma then
            AddLog("Нашёл Longma, начинаю бой.")
            FightBossOnce(longma, "Longma")
        else
            AddLog("Longma не найден. Жду его спавна.")
        end
        return
    end

    -- 2) дверь уже есть — работаем с rip_indra + Holy Torch
    UpdateStatus("Tushita: TushitaGate уже есть, работаю с rip_indra / факелами.")

    local indra = CheckNameBoss("rip_indra True Form [Lv. 5000] [Raid Boss]")
    if not indra then
        AddLog("rip_indra не заспавнен. Скрипт ждёт появления рейд босса.")
        return
    end

    local hasTorch = HasItemSimple("Holy Torch")

    -- 2.1) нет Holy Torch — идём в секретную комнату за факелом
    if not hasTorch then
        AddLog("Нет Holy Torch — лечу к секретной комнате Waterfall.")
        local waterfall = map:FindFirstChild("Waterfall")
        if not waterfall then
            AddLog("❌ Не найден Waterfall в карте.")
            return
        end

        local secretRoom = waterfall:FindFirstChild("SecretRoom")
        if not secretRoom or not secretRoom:FindFirstChild("Room") then
            AddLog("❌ Не найден SecretRoom.Room для Holy Torch.")
            return
        end

        local doorRoom = secretRoom.Room
        local doorObj = doorRoom:FindFirstChild("Door")
        local finalHitbox
        if doorObj then
            finalHitbox = doorObj:FindFirstChild("Door") and doorObj.Door:FindFirstChild("Hitbox") or doorObj:FindFirstChild("Hitbox")
        end

        if finalHitbox and finalHitbox:IsA("BasePart") then
            SimpleTeleport(finalHitbox.CFrame * CFrame.new(0, 4, 2), "SecretRoom (Holy Torch)")
            AddLog("Подлетел к двери SecretRoom — дальше получай Holy Torch по своим условиям.")
        else
            AddLog("❌ Не найден Hitbox для двери SecretRoom (Holy Torch).")
        end

        return
    end

    -- 2.2) Holy Torch уже есть — включаем факелы на Turtle
    UpdateStatus("Tushita: Holy Torch есть, активирую QuestTorches.")
    EquipToolByName("Holy Torch")

    local torch = CheckTorch()
    if not torch then
        AddLog("Все факелы, похоже, уже зажжены или не найден следующий факел.")
        return
    end

    AddLog("Нашёл неактивный факел: "..torch.Name..", лечу и жму E.")
    SimpleTeleport(torch.CFrame * CFrame.new(0, 4, 2), "QuestTorch "..torch.Name)

    -- жмём E как в 12к
    task.wait(0.5)
    VirtualInputManager:SendKeyEvent(true, "E", false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, "E", false, game)

    AddLog("Нажал E у факела "..torch.Name..". Скрипт продолжит проверять следующий факел в цикле.")
end

---------------------
-- GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaTushitaGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 420, 0, 260)
    MainFrame.Position = UDim2.new(0, 40, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Title.Text = "Auto Yama / Tushita (получение мечей)"
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

    -- ЛОГИ (скролл)
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

    -- ПЕРЕКЛЮЧАТЕЛИ
    TushitaButton.MouseButton1Click:Connect(function()
        AutoTushita = not AutoTushita
        if AutoTushita then
            AutoYama = false

            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            TushitaButton.Text = "Auto Tushita: ON"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)

            NoclipEnabled = true
            StopTween = false
            UpdateStatus("Фарм Tushita / Longma / факелы.")
        else
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            if not AutoYama then
                NoclipEnabled = false
                StopTween = true
                UpdateStatus("Остановлен")
            end
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
            StopTween = false
            UpdateStatus("Фарм Yama / Elite Hunter.")
        else
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            if not AutoTushita then
                NoclipEnabled = false
                StopTween = true
                UpdateStatus("Остановлен")
            end
        end
    end)

    AddLog("GUI Auto Yama / Tushita загружен. Включай нужный режим.")
end

CreateGui()

---------------------
-- ОСНОВНОЙ ЦИКЛ
---------------------
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
            AddLog("Ошибка в основном цикле: "..tostring(err))
        end
    end
end)
