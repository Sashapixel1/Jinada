--========================================================
-- Auto Yama / Auto Tushita (получение мечей) + GUI + ЛОГИ
--========================================================

---------------------
-- НАСТРОЙКИ
---------------------
local WeaponName    = "Godhuman"             -- чем бить боссов
local TeleportSpeed = 300                    -- скорость полёта
local BossOffset    = CFrame.new(0, 10, -3)  -- позиция над целью

---------------------
-- СЕРВИСЫ
---------------------
local Players             = game:GetService("Players")
local TweenService        = game:GetService("TweenService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Workspace           = game:GetService("Workspace")
local RunService          = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local remote      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- ФЛАГИ / СОСТОЯНИЕ
---------------------
local AutoTushita   = false
local AutoYama      = false
local CurrentStatus = "Idle"

local IsTeleporting = false
local StopTween     = false
local NoclipEnabled = false
local IsFighting    = false

local WarnNoThirdSeaForTushita = false
local WarnNoThirdSeaForYama    = false

-- Elite Hunter
local lastEliteRequest       = 0            -- кулдаун запроса квеста
local lastEliteProgressCheck = 0            -- когда последний раз брали прогресс
local cachedEliteProgress    = 0            -- кэш прогресса

-- антиспам логов по Waterfall
local lastWaterfallLog = 0

-- координаты Floating Turtle (как в 12к)
local FloatingTurtlePos   = CFrame.new(-13274.528320313, 531.82073974609, -7579.22265625)
local lastTurtleTeleport  = 0              -- кулдаун телепорта к острову

---------------------
-- NET MODULE (как в 12к)
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
local TushitaButton, YamaButton
local LogsText

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
-- АВТОХАКИ / ЭКИП
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
    local lower = string.lower(name)
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and string.lower(obj.Name) == lower then
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
        if tick() - lastEquipFailLog > 3 then
            AddLog("⚠️ Оружие не найдено: " .. name)
            lastEquipFailLog = tick()
        end
    end
end

---------------------
-- ИНВЕНТАРЬ
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

    local backpack = p:FindChild("Backpack") or p:FindFirstChild("Backpack")
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
    AddLog(string.format("Телепорт к %s (%.0f stud)", label or "цели", distance))

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
    AddLog("HRP найден, продолжаю.")
end)

---------------------
-- ОБЩИЙ БОЙ
---------------------
local function FightBossOnce(target, label)
    if IsFighting then return end
    IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then return end

        local hum  = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not hum or not tHRP or hum.Health <= 0 then return end

        AddLog("Начинаю бой с боссом: " .. (label or target.Name))

        SimpleTeleport(tHRP.CFrame * BossOffset, label or target.Name)

        local fightDeadline = tick() + 120
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while (AutoYama or AutoTushita)
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
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * BossOffset, "далёкий босс " .. (label or target.Name))
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * BossOffset
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

        if engaged then
            if hum and hum.Health <= 0 or not target.Parent then
                AddLog("✅ Босс " .. target.Name .. " убит.")
            else
                AddLog("⚠️ Бой с боссом " .. target.Name .. " прерван.")
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в FightBossOnce: " .. tostring(err))
    end

    IsFighting = false
end

---------------------
-- 3 МОРЕ (для оффлайна просто true)
---------------------
local function IsThirdSea()
    return true
end

---------------------
-- YAMA: Elite Hunter
---------------------
local EliteNPCPos = CFrame.new(-5418.892578125, 313.74130249023, -2826.2260742188)

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
        return "", quest and quest.Visible or false
    end

    local container  = quest.Container
    local questTitle = container:FindFirstChild("QuestTitle")
    if not questTitle then
        return "", quest.Visible
    end

    local titleLabel = questTitle:FindFirstChild("Title")
    if not titleLabel or not titleLabel:IsA("TextLabel") then
        return "", quest.Visible
    end

    return tostring(titleLabel.Text), quest.Visible
end

---------------------
-- TUSHITA: CheckNameBoss / факелы
---------------------
local function CheckNameBoss(a)
    for _, v in next, game.ReplicatedStorage:GetChildren() do
        if v:IsA("Model")
           and v:FindFirstChild("Humanoid")
           and v.Humanoid.Health > 0 then
            if typeof(a) == "table" then
                if table.find(a, v.Name) then
                    return v
                end
            elseif v.Name == a then
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
                if typeof(a) == "table" then
                    if table.find(a, v.Name) then
                        return v
                    end
                elseif v.Name == a then
                    return v
                end
            end
        end
    end
    return nil
end

local function CheckTorch()
    local ws  = Workspace
    local map = ws:FindFirstChild("Map")
    if not map then return nil end

    local turtle = map:FindFirstChild("Turtle") or map:FindFirstChild("Floating Turtle")
    if not turtle then return nil end

    local torches = turtle:FindFirstChild("QuestTorches")
    if not torches then return nil end

    local a
    if not torches.Torch1.Particles.Main.Enabled then
        a = "1"
    elseif not torches.Torch2.Particles.Main.Enabled then
        a = "2"
    elseif not torches.Torch3.Particles.Main.Enabled then
        a = "3"
    elseif not torches.Torch4.Particles.Main.Enabled then
        a = "4"
    elseif not torches.Torch5.Particles.Main.Enabled then
        a = "5"
    end

    if not a then return nil end

    for _, v in next, torches:GetChildren() do
        if v:IsA("MeshPart")
           and string.find(v.Name, a)
           and not v.Particles.Main.Enabled then
            return v
        end
    end

    return nil
end

local function FindEliteBoss()
    return CheckNameBoss({"Diablo","Deandre","Urban"})
end

---------------------
-- ВСПОМОГАТЕЛКА: SealedKatana в Waterfall
---------------------
local function GetSealedKatanaFromWaterfall()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil, nil, nil end

    local waterfall = map:FindFirstChild("Waterfall")
    if not waterfall then return nil, nil, nil end

    -- точка телепорта как в 12к: Map.Waterfall.SecretRoom.Room
    local teleportCFrame
    local secretRoom = waterfall:FindFirstChild("SecretRoom")
    if secretRoom then
        local room = secretRoom:FindFirstChild("Room")
        if room and room:IsA("BasePart") then
            teleportCFrame = room.CFrame
        elseif room then
            local anyPart = room:FindFirstChildWhichIsA("BasePart")
            if anyPart then
                teleportCFrame = anyPart.CFrame
            end
        end
    end

    -- SealedKatana
    local sealed = waterfall:FindFirstChild("SealedKatana")
    if not sealed then
        for _, obj in ipairs(waterfall:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "SealedKatana" then
                sealed = obj
                break
            end
        end
    end

    local handle, cd
    if sealed then
        handle = sealed:FindFirstChild("Handle") or sealed:FindFirstChildWhichIsA("BasePart") or sealed
        if handle then
            cd = handle:FindFirstChildOfClass("ClickDetector") or handle:FindFirstChild("ClickDetector")
        end
    end

    return teleportCFrame, handle, cd
end

---------------------
-- ЛОГИКА YAMA
---------------------
local function RunYamaLogic()
    if not IsThirdSea() then
        if not WarnNoThirdSeaForYama then
            WarnNoThirdSeaForYama = true
            UpdateStatus("Yama: нужно быть в 3-м море (Castle On The Sea / Floating Turtle).")
        end
        return
    end

    if HasSword("Yama") then
        UpdateStatus("Yama уже есть (меч в инвентаре).")
        EquipToolByName("Yama")
        return
    end

    local now = tick()

    -- прогресс Elite Hunter — не чаще 1 раза/мин
    if now - lastEliteProgressCheck >= 60 or cachedEliteProgress == 0 then
        cachedEliteProgress    = GetEliteProgress()
        lastEliteProgressCheck = now
        AddLog("EliteHunter прогресс: " .. tostring(cachedEliteProgress) .. "/30")
    end
    local progress = cachedEliteProgress

    -- 1) 30/30 — идём к Waterfall (Hydra) и кликаем SealedKatana.Handle.ClickDetector
    if progress >= 30 then
        UpdateStatus("Yama: прогресс 30+, лечу к Waterfall (Hydra) и кликаю SealedKatana.")

        local tpCF, handle, cd = GetSealedKatanaFromWaterfall()
        if not tpCF then
            if tick() - lastWaterfallLog > 5 then
                AddLog("❌ Не получилось найти Map.Waterfall.SecretRoom.Room (Hydra Island).")
                lastWaterfallLog = tick()
            end
            return
        end

        SimpleTeleport(tpCF * CFrame.new(0, 4, 2), "Waterfall SecretRoom")
        task.wait(1)

        -- если при телепорте SealedKatana не нашли (или ClickDetector нет), пробуем ещё раз уже из всего Workspace
        if (not handle) or (not cd) then
            local sealedModel
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "SealedKatana" then
                    sealedModel = obj
                    break
                end
            end
            if sealedModel then
                handle = sealedModel:FindFirstChild("Handle") or sealedModel:FindFirstChildWhichIsA("BasePart") or sealedModel
                if handle then
                    cd = handle:FindFirstChildOfClass("ClickDetector") or handle:FindFirstChild("ClickDetector")
                end
            end
        end

        if not cd then
            if tick() - lastWaterfallLog > 5 then
                AddLog("❌ SealedKatana.Handle.ClickDetector не найден. Проверь целостность Waterfall / SealedKatana.")
                lastWaterfallLog = tick()
            end
            return
        end

        AddLog("Нашёл SealedKatana.ClickDetector, начинаю спам кликов (как в 12к).")

        -- спам кликов до появления Yama или тайм-аут
        for i = 1, 80 do -- ≈20 сек
            if HasSword("Yama") then
                AddLog("✅ Yama получена!")
                EquipToolByName("Yama")
                return
            end
            pcall(function()
                fireclickdetector(cd)
            end)
            task.wait(0.25)
        end

        if HasSword("Yama") then
            AddLog("✅ Yama получена после цикла кликов.")
            EquipToolByName("Yama")
        else
            AddLog("⚠️ Не удалось получить Yama у Waterfall. Возможно, не выполнены условия квеста (урон с проклятого, элитки и т.д.).")
        end

        return
    end

    -- 2) фарм элиток, пока прогресс < 30
    UpdateStatus("Yama: фарм Elite Hunter (" .. tostring(progress) .. "/30).")

    local title, visible = GetQuestTitleText()
    local haveQuest = visible and (
        string.find(title, "Diablo")
        or string.find(title, "Deandre")
        or string.find(title, "Urban")
    )

    -- квеста нет — берём
    if not haveQuest then
        local diff = now - lastEliteRequest

        if diff < 60 then
            if math.floor(diff) % 10 == 0 then
                AddLog("Жду кулдаун Elite Hunter: " .. tostring(60 - math.floor(diff)) .. " сек.")
            end
            return
        end

        AddLog("Пробую взять квест Elite Hunter.")
        SimpleTeleport(EliteNPCPos, "Elite Hunter NPC")

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - EliteNPCPos.Position).Magnitude <= 10 then
            pcall(function()
                remote:InvokeServer("EliteHunter")
            end)
            lastEliteRequest       = now
            lastEliteProgressCheck = 0
            AddLog("Квест EliteHunter запрошен.")
        else
            AddLog("Не удалось подойти к Elite Hunter NPC (слишком далеко).")
        end

        return
    end

    -- квест есть — ищем элитку
    local elite = FindEliteBoss()
    if elite then
        AddLog("Нашёл элитного босса: " .. elite.Name .. ", начинаю бой.")
        FightBossOnce(elite, "Elite " .. elite.Name)
        lastEliteProgressCheck = 0
        if AutoYama then
            SimpleTeleport(EliteNPCPos, "Elite Hunter NPC (после боя)")
        end
    else
        AddLog("Yama: квест на элиту есть, но сам босс не найден (жду спавна).")
    end
end

---------------------
-- ЛОГИКА TUSHITA
---------------------
local function RunTushitaLogic()
    if not IsThirdSea() then
        if not WarnNoThirdSeaForTushita then
            WarnNoThirdSeaForTushita = true
            UpdateStatus("Tushita: нужно быть в 3-м море (остров Turtle).")
            AddLog("❌ Не вижу 3-е море — включи Auto Tushita в нужном мире.")
        end
        return
    end

    if HasSword("Tushita") then
        UpdateStatus("Tushita уже есть (меч в инвентаре).")
        EquipToolByName("Tushita")
        return
    end

    local map = Workspace:FindFirstChild("Map")
    if not map then
        AddLog("❌ Map не найден.")
        return
    end

    local turtle = map:FindFirstChild("Turtle") or map:FindFirstChild("Floating Turtle")
    if not turtle then
        local now = tick()
        if now - lastTurtleTeleport > 15 then
            lastTurtleTeleport = now
            UpdateStatus("Tushita: лечу на Floating Turtle.")
            AddLog("Turtle не найден в Map, телепортируюсь на Floating Turtle.")
            SimpleTeleport(FloatingTurtlePos, "Floating Turtle")
        end
        return
    end

    local gate = turtle:FindFirstChild("TushitaGate")

    -- 1) если нет двери → убиваем Longma
    if not gate then
        UpdateStatus("Tushita: убиваю Longma для открытия двери.")
        local longma = CheckNameBoss("Longma [Lv. 2000] [Boss]")
        if longma then
            AddLog("Нашёл Longma, начинаю бой.")
            FightBossOnce(longma, "Longma")
        else
            AddLog("Longma не найден, жду спавна.")
        end
        return
    end

    -- 2) дверь есть → rip_indra / Holy Torch / факелы
    UpdateStatus("Tushita: дверь есть, работаю с rip_indra / Holy Torch / факелами.")

    local indra = CheckNameBoss("rip_indra True Form [Lv. 5000] [Raid Boss]")
    if not indra then
        AddLog("Rip Indra не заспавнен. Жду рейд босса.")
        return
    end

    local hasTorch = HasItemSimple("Holy Torch")

    if not hasTorch then
        AddLog("Нет Holy Torch — лечу к SecretRoom для факела.")
        local waterfall = map:FindFirstChild("Waterfall")
        if not waterfall then
            AddLog("❌ Waterfall не найден.")
            return
        end

        local secretRoom = waterfall:FindFirstChild("SecretRoom")
        if not secretRoom or not secretRoom:FindFirstChild("Room") then
            AddLog("❌ SecretRoom.Room не найден.")
            return
        end

        local doorObj = secretRoom.Room:FindFirstChild("Door")
        local hitbox
        if doorObj then
            if doorObj:FindFirstChild("Door") and doorObj.Door:FindFirstChild("Hitbox") then
                hitbox = doorObj.Door.Hitbox
            else
                hitbox = doorObj:FindFirstChild("Hitbox")
            end
        end

        if hitbox and hitbox:IsA("BasePart") then
            SimpleTeleport(hitbox.CFrame * CFrame.new(0, 4, 2), "SecretRoom (Holy Torch)")
            AddLog("Подлетел к двери SecretRoom, дальше бери Holy Torch по условиям квеста.")
        else
            AddLog("❌ Hitbox двери SecretRoom не найден.")
        end

        return
    end

    -- Holy Torch есть → активируем факелы
    EquipToolByName("Holy Torch")
    UpdateStatus("Tushita: активирую факелы на Turtle (Holy Torch).")

    local torch = CheckTorch()
    if not torch then
        AddLog("Все факелы, похоже, уже зажжены или следующий факел не найден.")
        return
    end

    AddLog("Нашёл неактивный факел: " .. torch.Name .. ", лечу и жму E.")
    SimpleTeleport(torch.CFrame * CFrame.new(0, 4, 2), "QuestTorch "..torch.Name)

    task.wait(0.5)
    VirtualInputManager:SendKeyEvent(true, "E", false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, "E", false, game)

    AddLog("Нажал E у факела " .. torch.Name .. ".")
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
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Title.Text = "Auto Yama / Tushita (мечи)"
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
    LogsFrame.Size = UDim2.new(1, -20, 0, 150)
    LogsFrame.Position = UDim2.new(0, 10, 0, 100)
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

    TushitaButton.MouseButton1Click:Connect(function()
        AutoTushita = not AutoTushita
        if AutoTushita then
            AutoYama = false

            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)

            TushitaButton.Text = "Auto Tushita: ON"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(0,120,0)

            NoclipEnabled = true
            StopTween     = false
            WarnNoThirdSeaForTushita = false
            UpdateStatus("Фарм Tushita / Longma / факелы.")
        else
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            if not AutoYama then
                NoclipEnabled = false
                StopTween     = true
                UpdateStatus("Остановлен")
            end
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
            StopTween     = false
            WarnNoThirdSeaForYama = false
            UpdateStatus("Фарм Yama / Elite Hunter.")
        else
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            if not AutoTushita then
                NoclipEnabled = false
                StopTween     = true
                UpdateStatus("Остановлен")
            end
        end
    end)

    AddLog("GUI Auto Yama / Tushita загружен.")
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
            AddLog("Ошибка в основном цикле: " .. tostring(err))
        end
    end
end)
