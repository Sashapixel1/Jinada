--========================================================
-- Auto Yama Quests 1 / 2 / 3 + Evil Trial (CDK)
-- Для твоего оффлайн BF-проекта
--========================================================

---------------------
-- НАСТРОЙКИ / КОНСТАНТЫ
---------------------
local TeleportSpeed = 300

-- Q1: Mythological Pirate (запуск Evil Trial у НПС)
local MythPirateName          = "Mythological Pirate"
local MythPirateIslandCFrame  = CFrame.new(-13451.46484375, 543.712890625, -6961.0029296875)
local MythPirateStandOffset   = CFrame.new(0, 0, -2) -- как в 12к (сзади НПС)

-- Q2: Yama Quest 2 (HazeESP)
local Yama2SwordName          = "Yama"
local Yama2FarmOffset         = CFrame.new(0, 10, -3)

-- Q3: Bones + Hallow + Yama3 (HellDimension)
local Yama3WeaponName         = "Godhuman"
local Yama3FarmOffset         = CFrame.new(0, 10, -3)
local MaxRollsPerWindow       = 10
local RollWindowDuration      = 2 * 60 * 60 + 5 * 60 -- 2 часа 5 минут
local MinBonesToRoll          = 500

-- Haunted Castle fallback-центр (возле Death King)
local HauntedFallback         = CFrame.new(-9515.129, 142.233, 6200.441)

---------------------
-- ПЕРЕМЕННЫЕ
---------------------
local AutoYamaQuest1   = false
local AutoYamaQuest2   = false
local AutoYamaQuest3   = false

local CurrentStatus    = "Idle"
local StartTime        = os.time()

local IsTeleporting    = false
local StopTween        = false
local NoclipEnabled    = false

-- Q1
local lastTrial1Try      = 0
local Trial1Cooldown     = 5

-- Q2
local patrolIndex        = 1
local lastPatrol         = 0
local PatrolHoldUntil    = 0
local HazeKillCount      = 0
local IsFarmingYama2     = false

-- Q3
local AutoYama3Started   = false
local BonesCount         = 0
local RollsUsed          = 0
local HasHallow          = false
local RollWindowStart    = os.time()
local IsFightingYama3    = false

---------------------
-- ПАТРУЛЬНЫЕ ТОЧКИ (Yama Quest 2)
---------------------
local PatrolPoints = {
    -- Pirate Port – Pistol Billionaire
    CFrame.new(-187.3301544189453, 86.23987579345703, 6013.513671875),

    -- Great Tree / Marine Tree
    CFrame.new(2286.0078125, 73.13391876220703, -7159.80908203125),

    -- Haunted Castle район
    CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875),
    CFrame.new(-13451.46484375, 543.712890625, -6961.0029296875),

    -- Hydra / Deep Forest кластеры
    CFrame.new(-13274.478515625, 332.3781433105469, -7769.58056640625),
    CFrame.new(-13680.607421875, 501.08154296875, -6991.189453125),
    CFrame.new(-13457.904296875, 391.545654296875, -9859.177734375),
    CFrame.new(-12256.16015625, 331.73828125, -10485.8369140625),

    -- Sea of Treats (основные кластеры)
    CFrame.new(-1887.8099365234375, 77.6185073852539, -12998.3505859375),
    CFrame.new(-21.55328369140625, 80.57499694824219, -12352.3876953125),
    CFrame.new(582.590576171875, 77.18809509277344, -12463.162109375),

    -- Дальний кластер (Isle Champion)
    CFrame.new(-16641.6796875, 235.7825469970703, 1031.282958984375),
    CFrame.new(-16587.896484375, 154.21299743652344, 1533.40966796875),
    CFrame.new(-16885.203125, 114.12911224365234, 1627.949951171875),

    -- Доп. точки
    CFrame.new(-14050.21484375, 470.1129150390625, -7450.38427734375),
    CFrame.new(-13020.5576171875, 430.2214660644531, -9205.337890625),
    CFrame.new(-760.9874267578125, 90.44319915771484, -12840.1171875),
    CFrame.new(2490.224365234375, 350.77459716796875, -7150.5517578125),
    CFrame.new(-13274.528320313, 531.82073974609, -7579.22265625),
}

---------------------
-- СЕРВИСЫ
---------------------
local Players             = game:GetService("Players")
local TweenService        = game:GetService("TweenService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Workspace           = game:GetService("Workspace")
local RunService          = game:GetService("RunService")
local VirtualUser         = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer         = Players.LocalPlayer
local remote              = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- NET MODULE ДЛЯ FAST ATTACK
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
local StatusLogs  = {}
local MaxLogs     = 200

local ScreenGui, MainFrame
local BtnQ1, BtnQ2, BtnQ3
local StatusLabel, UptimeLabel, HazeLabel, BonesLabel, RollsLabel, HallowLabel, LogsText

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

local function GetUptime()
    local t = os.time() - StartTime
    local h = math.floor(t / 3600)
    local m = math.floor((t % 3600) / 60)
    local s = t % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function UpdateHazeLabel()
    if HazeLabel then
        HazeLabel.Text = "Yama2 HazeESP kills: " .. tostring(HazeKillCount)
    end
end

local function UpdateBonesLabel()
    if BonesLabel then
        BonesLabel.Text = "Yama3 Bones (stash): " .. tostring(BonesCount or 0)
    end
end

local function UpdateRollsLabel()
    if RollsLabel then
        RollsLabel.Text = "Yama3 Rolls (2h window): " .. tostring(RollsUsed) .. "/" .. tostring(MaxRollsPerWindow)
    end
end

local function UpdateHallowLabel()
    if HallowLabel then
        HallowLabel.Text = "Yama3 Hallow Essence: " .. (HasHallow and "есть" or "нет")
    end
end

---------------------
-- ANTI AFK
---------------------
spawn(function()
    while task.wait(60) do
        if AutoYamaQuest1 or AutoYamaQuest2 or AutoYamaQuest3 then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            AddLog("Anti-AFK: клик по экрану.")
        end
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
-- AUTO HAKI / ЭКИП
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

local function GetInventory()
    local ok, invData = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if ok and type(invData) == "table" then
        return invData
    end
    return {}
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
        if tick() - lastEquipFailLog > 5 then
            AddLog("⚠️ Не удалось найти оружие: " .. name)
            lastEquipFailLog = tick()
        end
    end
end

local function BringYamaToBackpack()
    local p = LocalPlayer
    if not p then return end

    if (p.Backpack and p.Backpack:FindFirstChild("Yama"))
        or (p.Character and p.Character:FindFirstChild("Yama")) then
        return
    end

    local inv = GetInventory()
    for _, item in ipairs(inv) do
        if item.Name == "Yama" then
            pcall(function()
                remote:InvokeServer("LoadItem", "Yama")
            end)
            AddLog("Пробую загрузить Yama через LoadItem.")
            break
        end
    end
end

local function EquipYama()
    BringYamaToBackpack()
    EquipToolByName("Yama")
end

---------------------
-- ТЕЛЕПОРТ
---------------------
local lastTPLog = ""

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
    IsFightingYama3 = false
    IsFarmingYama2  = false
    AddLog("Персонаж возрождён, жду HRP...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, продолжаю (если квест включен).")
end)

---------------------
-- CDKTrialModule (StartTrial Evil)
---------------------
local CDKTrialModule = {}

function CDKTrialModule.StartEvilTrial(logFunc)
    local function Log(msg)
        if logFunc then
            logFunc("[CDKTrial] " .. tostring(msg))
        else
            print("[CDKTrial] " .. tostring(msg))
        end
    end

    Log("Проверяю CDKQuest Progress 'Evil'...")
    local okP, progress = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Evil")
    end)

    if okP then
        Log("Progress(Evil) = " .. tostring(progress))
    else
        Log("Ошибка Progress(Evil): " .. tostring(progress))
    end

    task.wait(0.3)

    Log("Отправляю StartTrial 'Evil'...")
    local okS, resS = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Evil")
    end)

    if okS then
        Log("✅ StartTrial(Evil) отправлен, ответ: " .. tostring(resS))
    else
        Log("❌ Ошибка StartTrial(Evil): " .. tostring(resS))
    end
end

---------------------
-- ВСПОМОГАТЕЛЬНОЕ ДЛЯ Q3
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

    local invData = GetInventory()
    for _, item in ipairs(invData) do
        local name = item.Name or item.name or tostring(item)
        if name == itemName then
            return true
        end
    end

    return false
end

local function GetCountMaterials(MaterialName)
    local inv = GetInventory()
    for _, v in pairs(inv) do
        if v.Name == MaterialName then
            return v.Count or v.count or 0
        end
    end
    return 0
end

local function RefreshBonesCount()
    BonesCount = GetCountMaterials("Bones") or 0
    UpdateBonesLabel()
end

local function RefreshHallowStatus()
    HasHallow = HasItemInInventory("Hallow Essence")
    UpdateHallowLabel()
end

local function RefreshRollWindow()
    local now = os.time()
    if now - RollWindowStart > RollWindowDuration then
        RollWindowStart = now
        RollsUsed = 0
        AddLog("Окно роллов (2ч5м) обновлено, RollsUsed сброшен.")
        UpdateRollsLabel()
    end
end

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

local function EnsureOnHauntedIsland()
    local char = LocalPlayer.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local center = GetHauntedCenterCFrame()
    local dist = (hrp.Position - center.Position).Magnitude

    if dist > 600 then
        UpdateStatus("Yama3: лечу к Haunted Castle / Death King.")
        AddLog("Yama3: персонаж далеко от Haunted Castle ("..math.floor(dist).." stud), лечу обратно.")
        SimpleTeleport(center * CFrame.new(0, 4, 3), "Death King")
        task.wait(1.0)
        return false
    end

    return true
end

---------------------
-- Q1: Yama Quest 1 (Mythological Pirate → StartTrial Evil)
---------------------
local function GetMythologicalPirate()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end

    for _, v in ipairs(enemiesFolder:GetChildren()) do
        if v.Name == MythPirateName
           and v:FindFirstChild("Humanoid")
           and v:FindFirstChild("HumanoidRootPart")
           and v.Humanoid.Health > 0 then
            return v
        end
    end

    return nil
end

local function RunYamaQuest1()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then
        UpdateStatus("Yama Quest 1: жду появления персонажа...")
        return
    end

    local pirate = GetMythologicalPirate()

    if pirate then
        UpdateStatus("Yama Quest 1: Mythological Pirate найден, подлетаю.")
        local pHRP = pirate:FindFirstChild("HumanoidRootPart")
        if pHRP then
            SimpleTeleport(pHRP.CFrame * MythPirateStandOffset, MythPirateName)
            task.wait(0.5)

            local dist = (pHRP.Position - hrp.Position).Magnitude
            if dist > 5 then
                hrp.CFrame = pHRP.CFrame * MythPirateStandOffset
            end

            local now = tick()
            if now - lastTrial1Try >= Trial1Cooldown then
                lastTrial1Try = now
                AddLog("Yama1: вызываю CDKTrialModule.StartEvilTrial.")
                CDKTrialModule.StartEvilTrial(AddLog)
            end
        end
    else
        UpdateStatus("Yama Quest 1: Mythological Pirate не найден, лечу на его остров.")
        SimpleTeleport(MythPirateIslandCFrame, "Island Mythological Pirate")
    end
end

---------------------
-- Q2: HazeESP (Yama Quest 2)
---------------------
local function GetNearestHazeEnemy(maxDistance)
    maxDistance = maxDistance or 9999
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not enemiesFolder or not hrp then
        return nil
    end

    local nearest
    local bestDist = maxDistance

    for _, v in ipairs(enemiesFolder:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if v:FindFirstChild("HazeESP") then
                local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    nearest = v
                end
            end
        end
    end

    return nearest
end

local function PatrolStepYama2()
    if not AutoYamaQuest2 then return end
    if #PatrolPoints == 0 then return end
    if IsTeleporting then return end
    if tick() < PatrolHoldUntil then return end
    if tick() - lastPatrol < 2 then return end

    local idx = patrolIndex
    patrolIndex = patrolIndex + 1
    if patrolIndex > #PatrolPoints then
        patrolIndex = 1
    end
    lastPatrol = tick()

    local targetCF = PatrolPoints[idx] * Yama2FarmOffset
    AddLog("Yama2: патруль, точка #" .. tostring(idx))
    UpdateStatus("Yama Quest 2: патруль (точка "..tostring(idx)..")")

    SimpleTeleport(targetCF, "Yama2 патруль #" .. tostring(idx))
    PatrolHoldUntil = tick() + 5
    AddLog("Yama2: жду спавна мобов ~5 сек на точке #" .. tostring(idx))
end

local function FarmYamaQuest2Once()
    if not AutoYamaQuest2 then return end
    if IsFarmingYama2 then return end
    IsFarmingYama2 = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then
            return
        end

        local target = GetNearestHazeEnemy(9999)
        if not target then
            PatrolStepYama2()
            return
        end

        StopTween = true
        task.wait(0.1)
        IsTeleporting = false

        AddLog("Yama2: нашёл моба с HazeESP: "..tostring(target.Name))
        UpdateStatus("Yama Quest 2: бой с "..tostring(target.Name))

        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if tHRP then
            SimpleTeleport(tHRP.CFrame * Yama2FarmOffset, "Yama2 бой старт")
        end

        local fightDeadline = tick() + 35
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoYamaQuest2
            and target.Parent
            and target:FindFirstChild("Humanoid")
            and target.Humanoid.Health > 0
            and tick() < fightDeadline do

            engaged = true

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and tHRP) then
                break
            end

            local dist = (tHRP.Position - hrp.Position).Magnitude

            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * Yama2FarmOffset, "Yama2 дальний моб")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * Yama2FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            pcall(function()
                tHRP.CanCollide            = false
                target.Humanoid.WalkSpeed  = 0
                target.Humanoid.JumpPower  = 0

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
            EquipToolByName(Yama2SwordName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        if engaged then
            local humanoidOk, hum = pcall(function()
                return target:FindFirstChild("Humanoid")
            end)

            local hazeStillThere = target:FindFirstChild("HazeESP") ~= nil
            local dead = false

            if humanoidOk and hum then
                dead = (hum.Health <= 0)
            end

            if (not target.Parent) or dead or (not hazeStillThere) then
                HazeKillCount = HazeKillCount + 1
                UpdateHazeLabel()
                AddLog("✅ Yama2: засчитан HazeESP моб. Всего: " .. tostring(HazeKillCount))
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в FarmYamaQuest2Once: "..tostring(err))
    end

    IsFarmingYama2 = false
end

-- HazeESP твик (рамка)
spawn(function()
    while task.wait(0.2) do
        if AutoYamaQuest2 then
            pcall(function()
                local enemiesFolder = Workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    for _, v in ipairs(enemiesFolder:GetChildren()) do
                        if v:FindFirstChild("HazeESP") then
                            v.HazeESP.Size        = UDim2.new(50, 50, 50, 50)
                            v.HazeESP.MaxDistance = "inf"
                        end
                    end
                end
            end)
        end
    end
end)

---------------------
-- Q3: Bones + Hallow + Yama3 (HellDimension)
---------------------
local lastRollAttempt = 0

local function DoDeathKingRollsIfNeeded()
    RefreshHallowStatus()
    if HasHallow then
        AddLog("Yama3: Hallow Essence уже есть, роллить не нужно.")
        return
    end

    RefreshBonesCount()
    if BonesCount < MinBonesToRoll then
        AddLog("Yama3: костей меньше "..MinBonesToRoll..", ролл откладывается.")
        return
    end

    RefreshRollWindow()
    if RollsUsed >= MaxRollsPerWindow then
        AddLog("Yama3: лимит роллов ("..MaxRollsPerWindow..") в текущем окне достигнут.")
        return
    end

    if tick() - lastRollAttempt < 5 then
        return
    end
    lastRollAttempt = tick()

    UpdateStatus("Yama3: ролл у Death King")
    AddLog("Yama3: делаю роллы у Death King...")

    local center = GetHauntedCenterCFrame()
    SimpleTeleport(center * CFrame.new(0, 4, 3), "Death King")
    task.wait(1.5)

    local rollsToDo = MaxRollsPerWindow - RollsUsed
    for i = 1, rollsToDo do
        RefreshBonesCount()
        if BonesCount < 50 then
            AddLog("Yama3: костей меньше 50, остановка роллов.")
            break
        end

        RefreshRollWindow()
        if RollsUsed >= MaxRollsPerWindow then
            AddLog("Yama3: достигнут лимит роллов, выхожу.")
            break
        end

        local ok, res = pcall(function()
            return remote:InvokeServer("Bones", "Buy", 1, 1)
        end)

        RollsUsed = RollsUsed + 1
        UpdateRollsLabel()

        if ok then
            AddLog("Yama3: ролл #"..tostring(RollsUsed).." отправлен. Ответ: "..tostring(res))
        else
            AddLog("Yama3: ошибка при ролле #"..tostring(RollsUsed)..": "..tostring(res))
        end

        RefreshHallowStatus()
        if HasHallow then
            AddLog("🎃 Yama3: Hallow Essence получена, останавливаю роллы.")
            break
        end

        task.wait(1.5)
    end

    if RollsUsed >= MaxRollsPerWindow then
        AddLog("Yama3: лимит роллов в окне достигнут, дальше только фарм костей.")
    end
end

local function IsBoneMob(mob)
    local name = tostring(mob.Name)
    if string.find(name, "Skeleton") then return true end
    if string.find(name, "Reborn Skeleton") then return true end
    if string.find(name, "Living Skeleton") then return true end
    return false
end

local function GetNearestBoneMob(maxDistance)
    maxDistance = maxDistance or 9999
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local center   = GetHauntedCenterCFrame()
    local nearest  = nil
    local bestDist = maxDistance

    for _, v in ipairs(enemiesFolder:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 and IsBoneMob(v) then
                local distFromCenter = (v.HumanoidRootPart.Position - center.Position).Magnitude
                if distFromCenter < 800 then
                    local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        nearest  = v
                    end
                end
            end
        end
    end

    return nearest
end

local function FarmBonesOnce()
    if IsFightingYama3 then return end
    IsFightingYama3 = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then
            return
        end

        local target = GetNearestBoneMob(9999)
        if not target then
            UpdateStatus("Yama3: скелеты возле Haunted Castle не найдены.")
            return
        end

        UpdateStatus("Yama3: фарм костей: "..tostring(target.Name))
        AddLog("Yama3: нашёл скелета: "..tostring(target.Name))

        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if tHRP then
            SimpleTeleport(tHRP.CFrame * Yama3FarmOffset, "Yama3 скелет")
        end

        local fightDeadline = tick() + 40
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoYamaQuest3
            and target.Parent
            and target:FindFirstChild("Humanoid")
            and target.Humanoid.Health > 0
            and tick() < fightDeadline do

            engaged = true

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and tHRP) then
                break
            end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * Yama3FarmOffset, "Yama3 дальний скелет")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * Yama3FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            pcall(function()
                tHRP.CanCollide = false
                target.Humanoid.WalkSpeed = 0
                target.Humanoid.JumpPower = 0

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
            EquipToolByName(Yama3WeaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        if engaged then
            local hum = target:FindFirstChild("Humanoid")
            local dead = hum and hum.Health <= 0
            if dead or not target.Parent then
                AddLog("✅ Yama3: скелет убит, кости должны были начислиться.")
                RefreshBonesCount()
            else
                AddLog("⚠️ Yama3: бой со скелетом прерван.")
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в FarmBonesOnce: "..tostring(err))
    end

    IsFightingYama3 = false
end

-- HellDimension: утилиты
local function HoldE(seconds)
    seconds = seconds or 5
    VirtualInputManager:SendKeyEvent(true, "E", false, game)
    task.wait(seconds)
    VirtualInputManager:SendKeyEvent(false, "E", false, game)
end

local function IsHellMob(v)
    local n = tostring(v.Name)
    if string.find(n, "Cursed Skeleton") then return true end
    if string.find(n, "Hell's Messenger") then return true end
    return false
end

local function FarmHellMobsOnce()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end

    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 and IsHellMob(v) then
                local hum  = v.Humanoid
                local tHRP = v.HumanoidRootPart
                local deadline = tick() + 45
                AddLog("Yama3 HellDimension: атакую моба "..tostring(v.Name))

                while AutoYamaQuest3
                    and hum.Health > 0
                    and v.Parent
                    and tick() < deadline do

                    local char = LocalPlayer.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if not (char and hrp and tHRP) then break end

                    local dist = (tHRP.Position - hrp.Position).Magnitude
                    if dist > 2000 then
                        SimpleTeleport(tHRP.CFrame * Yama3FarmOffset, "Yama3 Hell mob (далеко)")
                    else
                        hrp.CFrame = tHRP.CFrame * Yama3FarmOffset
                        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                        hrp.CanCollide = false
                    end

                    pcall(function()
                        tHRP.CanCollide = false
                        hum.WalkSpeed   = 0
                        hum.JumpPower   = 0
                    end)

                    AutoHaki()
                    EquipToolByName(Yama3WeaponName)
                    AttackModule:AttackEnemyModel(v)

                    RunService.Heartbeat:Wait()
                end
            end
        end
    end
end

local function HandleHellDimension()
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local hd  = map:FindFirstChild("HellDimension")
    if not hd then return end

    UpdateStatus("Yama3: HellDimension активен, выполняю квест.")
    AddLog("Yama3: HellDimension найден, выполняю Torch1-3 + босс + Exit.")

    local Torch1 = hd:FindFirstChild("Torch1")
    local Torch2 = hd:FindFirstChild("Torch2")
    local Torch3 = hd:FindFirstChild("Torch3")
    local Exit   = hd:FindFirstChild("Exit")

    if Torch1 then
        AddLog("Yama3 Hell: Torch1 — зажимаю E и убиваю мобов.")
        SimpleTeleport(Torch1.CFrame, "Hell Torch1")
        task.wait(0.5)
        HoldE(3)
        task.wait(0.5)
        FarmHellMobsOnce()
    end

    if Torch2 then
        AddLog("Yama3 Hell: Torch2 — зажимаю E и убиваю мобов.")
        SimpleTeleport(Torch2.CFrame, "Hell Torch2")
        task.wait(0.5)
        HoldE(3)
        task.wait(0.5)
        FarmHellMobsOnce()
    end

    if Torch3 then
        AddLog("Yama3 Hell: Torch3 — зажимаю E и убиваю мобов.")
        SimpleTeleport(Torch3.CFrame, "Hell Torch3")
        task.wait(0.5)
        HoldE(3)
        task.wait(0.5)
        FarmHellMobsOnce()
    end

    AddLog("Yama3 Hell: ищу босса Hell's Messenger.")
    FarmHellMobsOnce()

    if Exit then
        AddLog("Yama3 Hell: факелы и босс готовы, тп к Exit.")
        SimpleTeleport(Exit.CFrame, "Hell Exit")
    else
        AddLog("Yama3 Hell: Exit не найден.")
    end
end

-- Soul Reaper поиск
local function FindSoulReaper()
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, v in ipairs(enemies:GetChildren()) do
            if tostring(v.Name) == "Soul Reaper" then
                local hum = v:FindFirstChild("Humanoid")
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp then
                    return v, hum, hrp
                end
            end
        end
    end
    return nil
end

local function HandleSummonerIfHasHallow()
    if not HasHallow then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local hc  = map:FindFirstChild("Haunted Castle")
    if not hc then return end
    local summonerModel = hc:FindFirstChild("Summoner")
    if not summonerModel then return end
    local detection = summonerModel:FindFirstChild("Detection")
    if not detection then return end

    UpdateStatus("Yama3: есть Hallow Essence, лечу к Summoner.")
    AddLog("Yama3: Summoner (Haunted Castle) — подготовка к Soul Reaper.")

    SimpleTeleport(detection.CFrame, "Summoner Detection")
    task.wait(1.0)
end

local function HandleSoulReaperPhase()
    local map = Workspace:FindFirstChild("Map")
    local hd  = map and map:FindFirstChild("HellDimension")
    if hd then
        return
    end

    local soul, sh, sHRP = FindSoulReaper()
    if not soul then
        AddLog("Yama3: Soul Reaper не найден, лечу к его спавну.")
        SimpleTeleport(CFrame.new(-9570.033203125, 315.9346923828125, 6726.89306640625), "Soul Reaper spawn")
        return
    end

    UpdateStatus("Yama3: Soul Reaper найден, подлетаю и жду урона.")
    AddLog("Yama3: подлетаю к Soul Reaper, не атакую, жду пока он снимет HP ≤ 500.")

    local prevNoclip = NoclipEnabled
    NoclipEnabled = false

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    sHRP       = soul:FindFirstChild("HumanoidRootPart")
    if hrp and sHRP then
        hrp.CFrame = sHRP.CFrame * CFrame.new(0, 0, -6)
    end

    local waitDeadline = tick() + 120
    while AutoYamaQuest3
        and soul.Parent
        and sh.Health > 0
        and tick() < waitDeadline
        and not (Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("HellDimension")) do

        char  = LocalPlayer.Character
        hrp   = char and char:FindFirstChild("HumanoidRootPart")
        sHRP  = soul:FindFirstChild("HumanoidRootPart")
        sh    = soul:FindFirstChild("Humanoid")

        if not (char and hrp and sHRP and sh) then
            break
        end

        local dist = (hrp.Position - sHRP.Position).Magnitude
        if dist > 120 then
            AddLog("Yama3: меня откинуло от Soul Reaper, подлетаю обратно.")
            hrp.CFrame = sHRP.CFrame * CFrame.new(0, 0, -6)
        end

        local phum = char:FindFirstChild("Humanoid")
        if phum and phum.Health <= 500 then
            AddLog("Yama3: HP персонажа ≤ 500, стою 5 сек, жду HellDimension.")
            UpdateStatus("Yama3: жду авто-переноса в HellDimension (5 сек).")

            local t0 = tick()
            while AutoYamaQuest3 and tick() - t0 < 5 do
                local m = Workspace:FindFirstChild("Map")
                local hDim = m and m:FindFirstChild("HellDimension")
                if hDim then
                    AddLog("Yama3: HellDimension появился во время ожидания.")
                    NoclipEnabled = prevNoclip
                    return
                end
                task.wait(0.1)
            end

            local m2 = Workspace:FindFirstChild("Map")
            local hDim2 = m2 and m2:FindFirstChild("HellDimension")
            if hDim2 then
                local torch1 = hDim2:FindFirstChild("Torch1")
                local exit   = hDim2:FindFirstChild("Exit")
                local fallbackCf
                if torch1 and torch1.CFrame then
                    fallbackCf = torch1.CFrame
                elseif exit and exit.CFrame then
                    fallbackCf = exit.CFrame
                elseif hDim2:IsA("Model") and hDim2:GetPrimaryPartCFrame() then
                    fallbackCf = hDim2:GetPrimaryPartCFrame()
                end

                if fallbackCf then
                    AddLog("Yama3: HellDimension есть, тп туда вручную (fallback).")
                    SimpleTeleport(fallbackCf, "HellDimension fallback")
                else
                    AddLog("Yama3: HellDimension есть, но нет Torch1/Exit.")
                end
            else
                AddLog("Yama3: 5 сек прошло, HellDimension так и не появился.")
            end

            NoclipEnabled = prevNoclip
            return
        end

        RunService.Heartbeat:Wait()
    end

    NoclipEnabled = prevNoclip
end

local function RunYamaQuest3Tick()
    if not AutoYamaQuest3 then return end

    RefreshBonesCount()
    RefreshHallowStatus()
    RefreshRollWindow()

    if not EnsureOnHauntedIsland() then
        return
    end

    local map = Workspace:FindFirstChild("Map")
    local hellDim = map and map:FindFirstChild("HellDimension")

    if hellDim then
        HandleHellDimension()
        return
    end

    local alucardCount = GetCountMaterials("Alucard Fragment") or 0
    if alucardCount >= 3 then
        UpdateStatus("Yama3: 3 Alucard Fragment уже есть, просто фармлю кости.")
        FarmBonesOnce()
        return
    end

    if HasHallow then
        HandleSummonerIfHasHallow()
        HandleSoulReaperPhase()
        return
    end

    local soul = FindSoulReaper()
    if soul then
        HandleSoulReaperPhase()
        return
    end

    if BonesCount >= MinBonesToRoll and RollsUsed < MaxRollsPerWindow then
        DoDeathKingRollsIfNeeded()
        return
    end

    UpdateStatus("Yama3: фарм скелетов на Haunted Castle.")
    FarmBonesOnce()
end

---------------------
-- ОСНОВНОЙ ЦИКЛ ДЛЯ ВСЕХ КВЕСТОВ
---------------------
spawn(function()
    while task.wait(0.3) do
        local ok, err = pcall(function()
            if AutoYamaQuest1 then
                RunYamaQuest1()
            elseif AutoYamaQuest2 then
                -- Yama2: перед началом можно иногда дёргать триал, если надо
                FarmYamaQuest2Once()
            elseif AutoYamaQuest3 then
                RunYamaQuest3Tick()
            end
        end)

        if not ok then
            AddLog("Ошибка в общем цикле: " .. tostring(err))
        end
    end
end)

---------------------
-- GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaQuestsGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 480, 0, 320)
    MainFrame.Position = UDim2.new(0, 40, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Title.Text = "Auto Yama Quest 1 / 2 / 3 + CDK Evil Trial"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 16
    Title.Parent = MainFrame

    BtnQ1 = Instance.new("TextButton")
    BtnQ1.Size = UDim2.new(0, 140, 0, 28)
    BtnQ1.Position = UDim2.new(0, 10, 0, 30)
    BtnQ1.BackgroundColor3 = Color3.fromRGB(60,60,60)
    BtnQ1.TextColor3 = Color3.new(1,1,1)
    BtnQ1.Font = Enum.Font.SourceSansBold
    BtnQ1.TextSize = 14
    BtnQ1.Text = "Yama Quest 1: OFF"
    BtnQ1.Parent = MainFrame

    BtnQ2 = Instance.new("TextButton")
    BtnQ2.Size = UDim2.new(0, 140, 0, 28)
    BtnQ2.Position = UDim2.new(0, 170, 0, 30)
    BtnQ2.BackgroundColor3 = Color3.fromRGB(60,60,60)
    BtnQ2.TextColor3 = Color3.new(1,1,1)
    BtnQ2.Font = Enum.Font.SourceSansBold
    BtnQ2.TextSize = 14
    BtnQ2.Text = "Yama Quest 2: OFF"
    BtnQ2.Parent = MainFrame

    BtnQ3 = Instance.new("TextButton")
    BtnQ3.Size = UDim2.new(0, 140, 0, 28)
    BtnQ3.Position = UDim2.new(0, 330, 0, 30)
    BtnQ3.BackgroundColor3 = Color3.fromRGB(60,60,60)
    BtnQ3.TextColor3 = Color3.new(1,1,1)
    BtnQ3.Font = Enum.Font.SourceSansBold
    BtnQ3.TextSize = 14
    BtnQ3.Text = "Yama Quest 3: OFF"
    BtnQ3.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 20)
    StatusLabel.Position = UDim2.new(0, 10, 0, 65)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: "..CurrentStatus
    StatusLabel.Parent = MainFrame

    UptimeLabel = Instance.new("TextLabel")
    UptimeLabel.Size = UDim2.new(1, -20, 0, 20)
    UptimeLabel.Position = UDim2.new(0, 10, 0, 85)
    UptimeLabel.BackgroundTransparency = 1
    UptimeLabel.TextColor3 = Color3.new(1,1,1)
    UptimeLabel.Font = Enum.Font.SourceSans
    UptimeLabel.TextSize = 14
    UptimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    UptimeLabel.Text = "Время работы: 00:00:00"
    UptimeLabel.Parent = MainFrame

    HazeLabel = Instance.new("TextLabel")
    HazeLabel.Size = UDim2.new(1, -20, 0, 20)
    HazeLabel.Position = UDim2.new(0, 10, 0, 105)
    HazeLabel.BackgroundTransparency = 1
    HazeLabel.TextColor3 = Color3.new(1,1,1)
    HazeLabel.Font = Enum.Font.SourceSans
    HazeLabel.TextSize = 14
    HazeLabel.TextXAlignment = Enum.TextXAlignment.Left
    HazeLabel.Text = "Yama2 HazeESP kills: 0"
    HazeLabel.Parent = MainFrame

    BonesLabel = Instance.new("TextLabel")
    BonesLabel.Size = UDim2.new(1, -20, 0, 20)
    BonesLabel.Position = UDim2.new(0, 10, 0, 125)
    BonesLabel.BackgroundTransparency = 1
    BonesLabel.TextColor3 = Color3.new(1,1,1)
    BonesLabel.Font = Enum.Font.SourceSans
    BonesLabel.TextSize = 14
    BonesLabel.TextXAlignment = Enum.TextXAlignment.Left
    BonesLabel.Text = "Yama3 Bones (stash): 0"
    BonesLabel.Parent = MainFrame

    RollsLabel = Instance.new("TextLabel")
    RollsLabel.Size = UDim2.new(1, -20, 0, 20)
    RollsLabel.Position = UDim2.new(0, 10, 0, 145)
    RollsLabel.BackgroundTransparency = 1
    RollsLabel.TextColor3 = Color3.new(1,1,1)
    RollsLabel.Font = Enum.Font.SourceSans
    RollsLabel.TextSize = 14
    RollsLabel.TextXAlignment = Enum.TextXAlignment.Left
    RollsLabel.Text = "Yama3 Rolls (2h window): 0/"..tostring(MaxRollsPerWindow)
    RollsLabel.Parent = MainFrame

    HallowLabel = Instance.new("TextLabel")
    HallowLabel.Size = UDim2.new(1, -20, 0, 20)
    HallowLabel.Position = UDim2.new(0, 10, 0, 165)
    HallowLabel.BackgroundTransparency = 1
    HallowLabel.TextColor3 = Color3.new(1,1,1)
    HallowLabel.Font = Enum.Font.SourceSans
    HallowLabel.TextSize = 14
    HallowLabel.TextXAlignment = Enum.TextXAlignment.Left
    HallowLabel.Text = "Yama3 Hallow Essence: нет"
    HallowLabel.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 130)
    LogsFrame.Position = UDim2.new(0, 10, 0, 185)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
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

    -- КНОПКА Q1
    BtnQ1.MouseButton1Click:Connect(function()
        AutoYamaQuest1 = not AutoYamaQuest1
        if AutoYamaQuest1 then
            AutoYamaQuest2 = false
            AutoYamaQuest3 = false
            BtnQ1.Text = "Yama Quest 1: ON"
            BtnQ1.BackgroundColor3 = Color3.fromRGB(0,120,0)

            BtnQ2.Text = "Yama Quest 2: OFF"
            BtnQ2.BackgroundColor3 = Color3.fromRGB(60,60,60)
            BtnQ3.Text = "Yama Quest 3: OFF"
            BtnQ3.BackgroundColor3 = Color3.fromRGB(60,60,60)

            StartTime = os.time()
            NoclipEnabled = true
            StopTween     = false
            AddLog("Yama Quest 1 включён. (Mythological Pirate → Evil Trial)")
            UpdateStatus("Yama Quest 1: ищу Mythological Pirate / триггерю триал.")
            CDKTrialModule.StartEvilTrial(AddLog)
        else
            BtnQ1.Text = "Yama Quest 1: OFF"
            BtnQ1.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled = false
            StopTween     = true
            UpdateStatus("Остановлен")
            AddLog("Yama Quest 1 выключен.")
        end
    end)

    -- КНОПКА Q2
    BtnQ2.MouseButton1Click:Connect(function()
        AutoYamaQuest2 = not AutoYamaQuest2
        if AutoYamaQuest2 then
            AutoYamaQuest1 = false
            AutoYamaQuest3 = false
            BtnQ2.Text = "Yama Quest 2: ON"
            BtnQ2.BackgroundColor3 = Color3.fromRGB(0,120,0)

            BtnQ1.Text = "Yama Quest 1: OFF"
            BtnQ1.BackgroundColor3 = Color3.fromRGB(60,60,60)
            BtnQ3.Text = "Yama Quest 3: OFF"
            BtnQ3.BackgroundColor3 = Color3.fromRGB(60,60,60)

            StartTime = os.time()
            NoclipEnabled = true
            StopTween     = false
            HazeKillCount = 0
            UpdateHazeLabel()
            AddLog("Yama Quest 2 включён. (HazeESP патруль)")
            UpdateStatus("Yama Quest 2: патруль / поиск Haze-мобов.")
            CDKTrialModule.StartEvilTrial(AddLog) -- активация триала перед 2 квестом
        else
            BtnQ2.Text = "Yama Quest 2: OFF"
            BtnQ2.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled = false
            StopTween     = true
            UpdateStatus("Остановлен")
            AddLog("Yama Quest 2 выключен.")
        end
    end)

    -- КНОПКА Q3
    BtnQ3.MouseButton1Click:Connect(function()
        AutoYamaQuest3 = not AutoYamaQuest3
        if AutoYamaQuest3 then
            AutoYamaQuest1 = false
            AutoYamaQuest2 = false
            BtnQ3.Text = "Yama Quest 3: ON"
            BtnQ3.BackgroundColor3 = Color3.fromRGB(0,120,0)

            BtnQ1.Text = "Yama Quest 1: OFF"
            BtnQ1.BackgroundColor3 = Color3.fromRGB(60,60,60)
            BtnQ2.Text = "Yama Quest 2: OFF"
            BtnQ2.BackgroundColor3 = Color3.fromRGB(60,60,60)

            StartTime = os.time()
            NoclipEnabled = true
            StopTween     = false
            HazeKillCount = 0
            RollsUsed     = 0
            RollWindowStart = os.time()
            RefreshBonesCount()
            RefreshHallowStatus()
            UpdateHazeLabel()
            UpdateRollsLabel()
            AddLog("Yama Quest 3 включён. (Bones + Hallow + HellDimension).")
            UpdateStatus("Yama Quest 3: фарм костей / Hallow / HellDimension.")
            CDKTrialModule.StartEvilTrial(AddLog) -- активация триала перед 3 квестом
        else
            BtnQ3.Text = "Yama Quest 3: OFF"
            BtnQ3.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled = false
            StopTween     = true
            UpdateStatus("Остановлен")
            AddLog("Yama Quest 3 выключен.")
        end
    end)

    UpdateHazeLabel()
    UpdateBonesLabel()
    UpdateRollsLabel()
    UpdateHallowLabel()
    AddLog("GUI Auto Yama Quest 1/2/3 загружен.")
end

CreateGui()

spawn(function()
    while task.wait(1) do
        if UptimeLabel then
            UptimeLabel.Text = "Время работы: "..GetUptime()
        end
    end
end)
