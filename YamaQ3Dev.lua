-- Auto Bones Farm + Hallow Essence + Yama Quest 3 (Alucard Fragment)
-- Фарм костей в Haunted Castle + роллы у Death King
-- После получения Hallow Essence автоматически запускает этап Auto_Quest_Yama_3
-- Использует MELEE "Godhuman", скорость полёта 300

---------------------
-- НАСТРОЙКИ
---------------------
local WeaponName    = "Godhuman"             -- чем бить скелетов / мобов
local TeleportSpeed = 300                    -- скорость полёта
local FarmOffset    = CFrame.new(0, 10, -3)  -- позиция над мобом

local MaxRollsPerSession = 10                -- максимум роллов за окно
local MinBonesToRoll     = 500               -- минимум костей, чтобы пойти роллить
local RollCooldown       = 7500             -- 2 часа 5 минут в секундах

-- точки для Yama Quest 3 / Soul Reaper
local SoulReaperSpawnCFrame = CFrame.new(-9570.033203125, 315.9346923828125, 6726.89306640625)

---------------------
-- ПЕРЕМЕННЫЕ
---------------------
local AutoBones      = false
local StartTime      = os.time()
local CurrentStatus  = "Idle"

local IsTeleporting  = false
local StopTween      = false
local NoclipEnabled  = false
local IsFighting     = false

local BonesCount     = 0
local RollsUsed      = 0
local HasHallow      = false

local RollSessionStartTime = os.time()  -- когда начались текущие роллы
local YamaModeActive       = false      -- сейчас в стадии Yama3 или нет

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
local remote      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

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
local StatusLogs = {}
local MaxLogs    = 80

local ScreenGui, MainFrame, ToggleButton
local StatusLabel, UptimeLabel, BonesLabel, RollsLabel, HallowLabel, LogsText

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

local function UpdateStatus(newStatus)
    CurrentStatus = newStatus
    AddLog("Статус: "..newStatus)
    if StatusLabel then
        StatusLabel.Text = "Статус: "..newStatus
    end
end

local function UpdateBonesLabel()
    if BonesLabel then
        BonesLabel.Text = "Костей (stash): " .. tostring(BonesCount or 0)
    end
end

local function UpdateRollsLabel()
    if RollsLabel then
        RollsLabel.Text = "Роллов в сессию: " .. tostring(RollsUsed) .. "/" .. tostring(MaxRollsPerSession)
    end
end

local function UpdateHallowLabel()
    if HallowLabel then
        HallowLabel.Text = "Hallow Essence: " .. (HasHallow and "есть" or "нет")
    end
end

local function GetUptime()
    local t = os.time() - StartTime
    local h = math.floor(t / 3600)
    local m = math.floor((t % 3600) / 60)
    local s = t % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

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
        hrp     = c and c:FindFirstChild("HumanoidRootPart")
        if not c or not hrp then
            tween:Cancel()
            IsTeleporting = false
            return
        end

        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide              = false

        task.wait(0.2)
    end

    tween:Cancel()
    local c = LocalPlayer.Character
    hrp     = c and c:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame                  = targetCFrame
        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide              = false
    end

    IsTeleporting = false
end

-- ФИКС ПОСЛЕ СМЕРТИ
LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = false
    IsFighting    = false
    AddLog("Персонаж возрождён, жду HRP...")

    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, фарм можно продолжать.")
    UpdateStatus("Ожидание / фарм костей")
end)

---------------------
-- ЧЕКЕР ИНВЕНТАРЯ + HALLOW ESSENCE
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

local function UpdateHallowStatus()
    HasHallow = HasItemInInventory("Hallow Essence")
    UpdateHallowLabel()
end

---------------------
-- GetCountMaterials (универсальный)
---------------------
local function GetCountMaterials(MaterialName)
    local ok, Inventory = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if ok and type(Inventory) == "table" then
        for _, v in pairs(Inventory) do
            if v.Name == MaterialName then
                return v.Count or v.count or 0
            end
        end
    end
    return 0
end

---------------------
-- ЧЕКЕР КОСТЕЙ
---------------------
local function RefreshBonesCount()
    local c = GetCountMaterials("Bones")
    BonesCount = c or 0
    UpdateBonesLabel()
end

---------------------
-- ПОИСК DEATH KING
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

-- центр Haunted Castle = Death King (динамически)
local HauntedFallback = CFrame.new(-9515.129, 142.233, 6200.441) -- запасной вариант
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
-- РОЛЛЫ У DEATH KING (10 за 2 часа)
---------------------
local lastRollAttempt = 0

local function MaybeResetRollsSession()
    local now = os.time()
    if now - RollSessionStartTime > RollCooldown then
        RollsUsed = 0
        RollSessionStartTime = now
        AddLog("⏱ Лимит роллов сброшен — прошло больше 2ч 5мин.")
        UpdateRollsLabel()
    end
end

local function DoDeathKingRolls()
    MaybeResetRollsSession()

    UpdateHallowStatus()
    if HasHallow then
        AddLog("Hallow Essence уже есть, роллить не нужно.")
        return
    end

    RefreshBonesCount()
    if BonesCount < MinBonesToRoll then
        AddLog("Костей меньше "..MinBonesToRoll..", ролл откладывается.")
        return
    end

    if RollsUsed >= MaxRollsPerSession then
        AddLog("Лимит роллов ("..MaxRollsPerSession..") исчерпан, ждём отката 2 часа.")
        return
    end

    if tick() - lastRollAttempt < 5 then
        return
    end
    lastRollAttempt = tick()

    UpdateStatus("Ролл у Death King")
    AddLog("Пытаюсь сделать роллы у Death King...")

    local center = GetHauntedCenterCFrame()
    SimpleTeleport(center * CFrame.new(0, 4, 3), "Death King")
    task.wait(1.5)

    local rollsToDo = MaxRollsPerSession - RollsUsed
    for _ = 1, rollsToDo do
        MaybeResetRollsSession()
        if RollsUsed >= MaxRollsPerSession then
            AddLog("Лимит роллов достигнут во время серии.")
            break
        end

        RefreshBonesCount()
        if BonesCount < 50 then
            AddLog("Костей меньше 50, остановка роллов.")
            break
        end

        local ok, res = pcall(function()
            return remote:InvokeServer("Bones", "Buy", 1, 1)
        end)

        RollsUsed = RollsUsed + 1
        UpdateRollsLabel()

        if ok then
            AddLog("Ролл #"..tostring(RollsUsed).." отправлен. Ответ: "..tostring(res))
        else
            AddLog("Ошибка при ролле #"..tostring(RollsUsed)..": "..tostring(res))
        end

        UpdateHallowStatus()
        if HasHallow then
            AddLog("🎃 Hallow Essence ПОЛУЧЕНА! Останавливаю роллы.")
            break
        end

        task.wait(1.5)
    end
end

---------------------
-- ПРОВЕРКА, ЧТО МЫ У DEATH KING
---------------------
local function EnsureOnHauntedIsland()
    local char = LocalPlayer.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local center = GetHauntedCenterCFrame()
    local dist   = (hrp.Position - center.Position).Magnitude

    if dist > 600 then
        UpdateStatus("Лечу к Death King (Haunted Castle)...")
        AddLog("Персонаж далеко от Death King ("..math.floor(dist).." stud), лечу обратно...")
        SimpleTeleport(center * CFrame.new(0, 4, 3), "Death King")
        task.wait(1.2)
        return false
    end

    return true
end

---------------------
-- ПОИСК СКЕЛЕТОВ ВОКРУГ DEATH KING
---------------------
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
        local hum  = v:FindFirstChild("Humanoid")
        local tHRP = v:FindFirstChild("HumanoidRootPart")
        if hum and tHRP and hum.Health > 0 and IsBoneMob(v) then
            local distFromCenter = (tHRP.Position - center.Position).Magnitude
            if distFromCenter < 800 then
                local d = (tHRP.Position - hrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    nearest  = v
                end
            end
        end
    end

    return nearest
end

---------------------
-- ФАЙТ ОБЩИЙ ДЛЯ YAMA3 (Hell / Soul Reaper)
---------------------
local function FightYamaMobOnce(target, label)
    if not target then return end
    local hum  = target:FindFirstChild("Humanoid")
    local tHRP = target:FindFirstChild("HumanoidRootPart")
    if not hum or not tHRP or hum.Health <= 0 then
        return
    end

    label = label or tostring(target.Name)
    AddLog("Yama3: бой с "..label..".")

    local fightDeadline = tick() + 90
    local lastPosAdjust = 0
    local lastAttack    = 0

    while AutoBones
        and target.Parent
        and target:FindFirstChild("Humanoid")
        and target.Humanoid.Health > 0
        and tick() < fightDeadline do

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        tHRP       = target:FindFirstChild("HumanoidRootPart")
        if not (char and hrp and tHRP) then break end

        local dist = (tHRP.Position - hrp.Position).Magnitude
        if dist > 2000 then
            SimpleTeleport(tHRP.CFrame * FarmOffset, label)
        else
            if tick() - lastPosAdjust > 0.05 then
                hrp.CFrame                  = tHRP.CFrame * FarmOffset
                hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                hrp.CanCollide              = false
                lastPosAdjust               = tick()
            end
        end

        pcall(function()
            tHRP.CanCollide             = false
            target.Humanoid.WalkSpeed   = 0
            target.Humanoid.JumpPower   = 0
        end)

        AutoHaki()
        EquipToolByName(WeaponName)

        if tick() - lastAttack > 0.15 then
            AttackModule:AttackEnemyModel(target)
            lastAttack = tick()
        end

        RunService.Heartbeat:Wait()
    end

    hum = target:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then
        AddLog("✅ "..label.." убит в рамках Yama3.")
    else
        AddLog("⚠️ Бой с "..label.." завершён/прерван.")
    end
end

---------------------
-- Yama Quest 3: вспомогательные
---------------------
local function GetHellDimension()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("HellDimension")
end

local function IsHellMob(model)
    if not model then return false end
    local name = tostring(model.Name)
    if string.find(name, "Cursed Skeleton") then return true end
    if string.find(name, "Hell's Messenger") then return true end
    return false
end

local function ShouldRunYamaQuest3(alucardCount)
    alucardCount = alucardCount or 0
    if alucardCount >= 3 then
        return false
    end

    -- 1) если уже открыт HellDimension или заспавнен Soul Reaper / его копия в RepStorage
    local map      = Workspace:FindFirstChild("Map")
    local hell     = map and map:FindFirstChild("HellDimension")
    local enemies  = Workspace:FindFirstChild("Enemies")
    local hasSoul  = enemies and enemies:FindFirstChild("Soul Reaper")
    local repSoul  = ReplicatedStorage:FindFirstChild("Soul Reaper [Lv. 2100] [Raid Boss]")

    if hell or hasSoul or repSoul then
        return true
    end

    -- 2) или просто есть Hallow Essence (ещё не использована)
    if HasItemInInventory("Hallow Essence") then
        return true
    end

    return false
end

---------------------
-- Yama Quest 3: основной цикл
---------------------
local function RunYamaQuest3(alucardCount)
    alucardCount = alucardCount or GetCountMaterials("Alucard Fragment") or 0

    if alucardCount >= 3 then
        UpdateStatus("Yama3: уже есть "..tostring(alucardCount).." Alucard Fragment (>=3).")
        return
    end

    -- 1) Hallow Essence есть -> использовать у Summoner (как в 12к)
    if HasItemInInventory("Hallow Essence") then
        local map   = Workspace:FindFirstChild("Map")
        local hc    = map and map:FindFirstChild("Haunted Castle")
        local summ  = hc and hc:FindFirstChild("Summoner")
        local detect = summ and summ:FindFirstChild("Detection")
        if detect then
            UpdateStatus("Yama3: не использован Hallow Essence, лечу к Summoner.")
            SimpleTeleport(detect.CFrame, "Summoner Hallow Essence")
        else
            AddLog("Yama3: Summoner.Detection не найден.")
        end
        return
    end

    -- 2) В аду (HellDimension) — приоритет, если он уже существует
    local hell = GetHellDimension()
    if hell then
        local enemies = Workspace:FindFirstChild("Enemies")
        local target  = nil

        if enemies then
            for _, v in ipairs(enemies:GetChildren()) do
                local hum  = v:FindFirstChild("Humanoid")
                local tHRP = v:FindFirstChild("HumanoidRootPart")
                if hum and tHRP and hum.Health > 0 and IsHellMob(v) then
                    target = v
                    break
                end
            end
        end

        if target then
            UpdateStatus("Yama3: HellDimension, бой с "..target.Name..".")
            FightYamaMobOnce(target, target.Name)
            return
        else
            -- факела (Torch1/2/3) + Exit
            UpdateStatus("Yama3: HellDimension, зажигаю факелы и иду к Exit.")
            local function tpAndPressE(partName)
                local part = hell:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    SimpleTeleport(part.CFrame, "Hell "..partName)
                    task.wait(1.5)
                    pcall(function()
                        VirtualInput:SendKeyEvent(true, "E", false, game)
                        VirtualInput:SendKeyEvent(false, "E", false, game)
                    end)
                    task.wait(1.0)
                else
                    AddLog("Yama3: "..partName.." не найден в HellDimension.")
                end
            end

            tpAndPressE("Torch1")
            tpAndPressE("Torch2")
            tpAndPressE("Torch3")

            local exitPart = hell:FindFirstChild("Exit")
            if exitPart and exitPart:IsA("BasePart") then
                SimpleTeleport(exitPart.CFrame, "Hell Exit")
            else
                AddLog("Yama3: Exit не найден в HellDimension.")
            end
            return
        end
    end

    -- 3) Soul Reaper (до ада)
    local enemies = Workspace:FindFirstChild("Enemies")
    local soul    = enemies and enemies:FindFirstChild("Soul Reaper") or nil
    if soul then
        UpdateStatus("Yama3: бой с Soul Reaper.")
        FightYamaMobOnce(soul, "Soul Reaper")
        return
    end

    local repSoul = ReplicatedStorage:FindFirstChild("Soul Reaper [Lv. 2100] [Raid Boss]")
    if repSoul then
        UpdateStatus("Yama3: Soul Reaper ещё в ReplicatedStorage, лечу к спавну.")
        SimpleTeleport(SoulReaperSpawnCFrame, "Soul Reaper spawn")
        return
    end

    -- 4) Ничего из стадий не найдено
    AddLog("Yama3: стадия не определена (нет Hallow, HellDimension, Soul Reaper). Возвращаюсь к фарму костей.")
end

---------------------
-- ФАРМ КОСТЕЙ (БОЙ СО СКЕЛЕТОМ)
---------------------
local function FarmBonesOnce()
    if IsFighting then return end
    IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then
            return
        end

        local target = GetNearestBoneMob(9999)
        if not target then
            UpdateStatus("Скелеты рядом с Haunted Castle не найдены")
            return
        end

        UpdateStatus("Фарм костей: "..tostring(target.Name))
        AddLog("Нашёл скелета: "..tostring(target.Name))

        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if tHRP then
            SimpleTeleport(tHRP.CFrame * FarmOffset, "скелет")
        end

        local fightDeadline = tick() + 40
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoBones
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
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий скелет")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame                  = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide              = false
                    lastPosAdjust               = tick()
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
            EquipToolByName(WeaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        if engaged then
            local hum  = target:FindFirstChild("Humanoid")
            local dead = hum and hum.Health <= 0
            if dead or not target.Parent then
                AddLog("✅ Скелет убит, кости должны были начислиться.")
                RefreshBonesCount()
            else
                AddLog("⚠️ Бой со скелетом прерван.")
            end
        end
    end)

    if not ok then
        AddLog("Ошибка в FarmBonesOnce: "..tostring(err))
    end

    IsFighting = false
end

---------------------
-- ОСНОВНОЙ ЦИКЛ
---------------------
spawn(function()
    while task.wait(0.4) do
        if AutoBones then
            local ok, err = pcall(function()
                RefreshBonesCount()
                UpdateHallowStatus()
                MaybeResetRollsSession()

                local alucardCount = GetCountMaterials("Alucard Fragment") or 0

                -- Сначала проверяем HellDimension / Soul Reaper / Hallow Essence
                local needYama = ShouldRunYamaQuest3(alucardCount)
                if needYama then
                    if not YamaModeActive then
                        YamaModeActive = true
                        AddLog("Переключаюсь на режим Yama Quest 3 (обнаружены HellDimension / Soul Reaper / Hallow Essence).")
                    end
                    UpdateStatus("Yama3: выполнение квеста (Alucard Fragment "..tostring(alucardCount).."/3).")
                    RunYamaQuest3(alucardCount)
                    return
                else
                    if YamaModeActive then
                        YamaModeActive = false
                        AddLog("Yama Quest 3: стадия завершена/недоступна, возвращаюсь к фарму костей.")
                    end
                end

                -- 1. Всегда сначала летим к Death King
                if not EnsureOnHauntedIsland() then
                    return
                end

                -- 2. Если Hallow Essence уже есть и Yama3 не нужен — просто фармим кости
                if HasHallow then
                    UpdateStatus("Hallow Essence уже есть, фармлю кости")
                    FarmBonesOnce()
                    return
                end

                -- 3. Если костей >=500 — роллим у Death King
                if BonesCount >= MinBonesToRoll and RollsUsed < MaxRollsPerSession then
                    DoDeathKingRolls()
                    return
                end

                -- 4. Иначе просто фармим скелетов вокруг Haunted Castle
                UpdateStatus("Фарм скелетов на Haunted Castle")
                FarmBonesOnce()
            end)

            if not ok then
                AddLog("Ошибка в основном цикле AutoBones: "..tostring(err))
            end
        end
    end
end)

---------------------
-- GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoBonesGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 380, 0, 270)
    MainFrame.Position = UDim2.new(0, 20, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active   = true
    MainFrame.Draggable = true
    MainFrame.Parent   = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "Auto Bones + Hallow + Yama3 (10 roll / 2h)"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 240, 0, 30)
    ToggleButton.Position = UDim2.new(0, 10, 0, 30)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Auto Bones: OFF"
    ToggleButton.Parent = MainFrame

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

    BonesLabel = Instance.new("TextLabel")
    BonesLabel.Size = UDim2.new(1, -20, 0, 20)
    BonesLabel.Position = UDim2.new(0, 10, 0, 105)
    BonesLabel.BackgroundTransparency = 1
    BonesLabel.TextColor3 = Color3.new(1,1,1)
    BonesLabel.Font = Enum.Font.SourceSans
    BonesLabel.TextSize = 14
    BonesLabel.TextXAlignment = Enum.TextXAlignment.Left
    BonesLabel.Text = "Костей (stash): 0"
    BonesLabel.Parent = MainFrame

    RollsLabel = Instance.new("TextLabel")
    RollsLabel.Size = UDim2.new(1, -20, 0, 20)
    RollsLabel.Position = UDim2.new(0, 10, 0, 125)
    RollsLabel.BackgroundTransparency = 1
    RollsLabel.TextColor3 = Color3.new(1,1,1)
    RollsLabel.Font = Enum.Font.SourceSans
    RollsLabel.TextSize = 14
    RollsLabel.TextXAlignment = Enum.TextXAlignment.Left
    RollsLabel.Text = "Роллов в сессию: 0/"..tostring(MaxRollsPerSession)
    RollsLabel.Parent = MainFrame

    HallowLabel = Instance.new("TextLabel")
    HallowLabel.Size = UDim2.new(1, -20, 0, 20)
    HallowLabel.Position = UDim2.new(0, 10, 0, 145)
    HallowLabel.BackgroundTransparency = 1
    HallowLabel.TextColor3 = Color3.new(1,1,1)
    HallowLabel.Font = Enum.Font.SourceSans
    HallowLabel.TextSize = 14
    HallowLabel.TextXAlignment = Enum.TextXAlignment.Left
    HallowLabel.Text = "Hallow Essence: нет"
    HallowLabel.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 100)
    LogsFrame.Position = UDim2.new(0, 10, 0, 170)
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
        AutoBones = not AutoBones
        if AutoBones then
            StartTime = os.time()
            ToggleButton.Text = "Auto Bones: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            NoclipEnabled = true
            AddLog("Auto Bones включен (noclip ON, Godhuman, speed 300)")
            UpdateStatus("Фарм костей (Haunted Castle)")
        else
            ToggleButton.Text = "Auto Bones: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            NoclipEnabled = false
            AddLog("Auto Bones выключен (noclip OFF)")
            UpdateStatus("Остановлен")
            StopTween = true
        end
    end)

    UpdateBonesLabel()
    UpdateRollsLabel()
    UpdateHallowLabel()
end

---------------------
-- ЗАПУСК GUI + ТАЙМЕР
---------------------
CreateGui()
AddLog("Auto Bones + Hallow + Yama Quest 3 (10 roll / 2h) загружен. Включай кнопку в 3-м море (Haunted Castle).")

spawn(function()
    while task.wait(1) do
        if UptimeLabel then
            UptimeLabel.Text = "Время работы: "..GetUptime()
        end
    end
end)
