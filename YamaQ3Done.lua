--========================================================
-- Auto Bones + Hallow Essence + YamaQuest3 (CDK)
-- Фарм костей в Haunted Castle, роллы у Death King (10 роллов / 2ч)
-- Авто Hallow Essence -> Soul Reaper -> HellDimension (Torch1-3, скелеты, босс, Exit)
--========================================================

---------------------
-- НАСТРОЙКИ
---------------------
local WeaponName = "Godhuman"            -- чем бить скелетов/мобов
local TeleportSpeed = 300                -- скорость полёта
local FarmOffset = CFrame.new(0, 10, -3) -- позиция над мобом

local MaxRollsPerWindow = 10             -- максимум роллов за окно
local RollWindowDuration = 2 * 60 * 60 + 5 * 60 -- 2 часа 5 минут

local MinBonesToRoll = 500               -- минимум костей, чтобы пойти роллить

---------------------
-- ПЕРЕМЕННЫЕ
---------------------
local AutoBones = false
local StartTime = os.time()
local CurrentStatus = "Idle"

local IsTeleporting = false
local StopTween = false
local NoclipEnabled = false
local IsFighting = false

local BonesCount = 0
local RollsUsed = 0
local HasHallow = false

local RollWindowStart = os.time()

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
-- NET MODULE ДЛЯ FAST ATTACK
---------------------
local modules = ReplicatedStorage:WaitForChild("Modules")
local net = modules:WaitForChild("Net")
local RegisterAttack = net:WaitForChild("RE/RegisterAttack")
local RegisterHit = net:WaitForChild("RE/RegisterHit")

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
        RollsLabel.Text = "Роллов (2ч окно): " .. tostring(RollsUsed) .. "/" .. tostring(MaxRollsPerWindow)
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
-- ТЕЛЕПОРТ
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
    AddLog(string.format("Телепорт к %s (%.0f юнитов)", label or "цели", distance))

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
    AddLog("Персонаж возрождён, жду HRP...")

    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, фарм можно продолжать.")
    UpdateStatus("Ожидание / фарм костей")
end)

---------------------
-- ЧЕКЕР ИНВЕНТАРЯ / МАТЕРИАЛОВ
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

-- GetCountMaterials (Bones / Alucard Fragment в stash/inventory)
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

local function RefreshRollWindow()
    local now = os.time()
    if now - RollWindowStart > RollWindowDuration then
        RollWindowStart = now
        RollsUsed = 0
        AddLog("Окно роллов (2ч5м) обновлено, RollsUsed сброшен.")
        UpdateRollsLabel()
    end
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
-- РОЛЛЫ У DEATH KING (10 за окно / 2ч5м)
---------------------
local lastRollAttempt = 0

local function DoDeathKingRolls()
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

    RefreshRollWindow()
    if RollsUsed >= MaxRollsPerWindow then
        AddLog("Лимит роллов в текущем окне ("..MaxRollsPerWindow..") достигнут. Жду новый 2ч интервал.")
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

    local rollsToDo = MaxRollsPerWindow - RollsUsed
    for i = 1, rollsToDo do
        RefreshBonesCount()
        if BonesCount < 50 then
            AddLog("Костей меньше 50, остановка роллов.")
            break
        end

        RefreshRollWindow()
        if RollsUsed >= MaxRollsPerWindow then
            AddLog("Достигнут лимит роллов в окне, завершение.")
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

    if RollsUsed >= MaxRollsPerWindow then
        AddLog("Лимит роллов в этом 2ч окне достигнут, далее только фарм костей.")
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
    local dist = (hrp.Position - center.Position).Magnitude

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
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local center = GetHauntedCenterCFrame()
    local nearest
    local bestDist = maxDistance

    for _, v in ipairs(enemiesFolder:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 and IsBoneMob(v) then
                -- Берём только тех, кто в радиусе от Death King
                local distFromCenter = (v.HumanoidRootPart.Position - center.Position).Magnitude
                if distFromCenter < 800 then
                    local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        nearest = v
                    end
                end
            end
        end
    end

    return nearest
end

---------------------
-- ФАРМ КОСТЕЙ (БОЙ СО СКЕЛЕТОМ)
---------------------
local function FarmBonesOnce()
    if IsFighting then return end
    IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
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
        local lastAttack = 0
        local engaged = false

        while AutoBones
            and target.Parent
            and target:FindFirstChild("Humanoid")
            and target.Humanoid.Health > 0
            and tick() < fightDeadline do

            engaged = true

            char = LocalPlayer.Character
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and tHRP) then
                break
            end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий скелет")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
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
            EquipToolByName(WeaponName)

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
-- HELL DIMENSION: УДЕРЖАНИЕ E
---------------------
local function HoldE(seconds)
    seconds = seconds or 2
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
                local hum = v.Humanoid
                local tHRP = v.HumanoidRootPart
                local deadline = tick() + 45
                AddLog("HellDimension: атакую моба "..tostring(v.Name))

                while AutoBones
                    and hum.Health > 0
                    and v.Parent
                    and tick() < deadline do

                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not (char and hrp and tHRP) then break end

                    local dist = (tHRP.Position - hrp.Position).Magnitude
                    if dist > 2000 then
                        SimpleTeleport(tHRP.CFrame * FarmOffset, "Hell mob (далеко)")
                    else
                        hrp.CFrame = tHRP.CFrame * FarmOffset
                        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                        hrp.CanCollide = false
                    end

                    pcall(function()
                        tHRP.CanCollide = false
                        hum.WalkSpeed   = 0
                        hum.JumpPower   = 0
                    end)

                    AutoHaki()
                    EquipToolByName(WeaponName)
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
    local hd = map:FindFirstChild("HellDimension")
    if not hd then return end

    UpdateStatus("Yama3: HellDimension активен.")
    AddLog("Yama3: HellDimension обнаружен, выполняю квест.")

    local Torch1 = hd:FindFirstChild("Torch1")
    local Torch2 = hd:FindFirstChild("Torch2")
    local Torch3 = hd:FindFirstChild("Torch3")
    local Exit   = hd:FindFirstChild("Exit")

    -- Torch1
    if Torch1 then
        AddLog("HellDimension: Torch1 -> зажимаю E на 3 секунды, затем убиваю скелетов.")
        SimpleTeleport(Torch1.CFrame, "HellDimension Torch1")
        task.wait(0.5)
        HoldE(2)
        task.wait(0.5)
        FarmHellMobsOnce()
    end

    -- Torch2
    if Torch2 then
        AddLog("HellDimension: Torch2 -> зажимаю E на 3 секунды, затем убиваю скелетов.")
        SimpleTeleport(Torch2.CFrame, "HellDimension Torch2")
        task.wait(0.5)
        HoldE(2)
        task.wait(0.5)
        FarmHellMobsOnce()
    end

    -- Torch3
    if Torch3 then
        AddLog("HellDimension: Torch3 -> зажимаю E на 3 секунды, затем убиваю скелетов.")
        SimpleTeleport(Torch3.CFrame, "HellDimension Torch3")
        task.wait(0.5)
        HoldE(2)
        task.wait(0.5)
        FarmHellMobsOnce()
    end

    -- Босс (Hell's Messenger) после факелов
    AddLog("HellDimension: ищу босса Hell's Messenger.")
    FarmHellMobsOnce()

    -- Exit
    if Exit then
        AddLog("HellDimension: все факелы и босс обработаны, телепорт к Exit.")
        SimpleTeleport(Exit.CFrame, "HellDimension Exit")
    else
        AddLog("HellDimension: Exit не найден, пропускаю тп.")
    end
end

---------------------
-- SOUL REAPER: ПОЛУЧИТЬ УРОН И ЖДАТЬ 5 СЕК
---------------------
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

local function HandleSoulReaperPhase()
    local map = Workspace:FindFirstChild("Map")
    local hd = map and map:FindFirstChild("HellDimension")
    if hd then
        -- Уже есть HellDimension, пусть основной цикл его обработает
        return
    end

    local soul, sh, sHRP = FindSoulReaper()
    if not soul then
        AddLog("Yama3: Soul Reaper не найден в Workspace, лечу к его спавну.")
        SimpleTeleport(CFrame.new(-9570.033203125, 315.9346923828125, 6726.89306640625), "Soul Reaper spawn")
        return
    end

    UpdateStatus("Yama3: Soul Reaper найден, подлетаю и жду урона.")
    AddLog("Yama3: подлетаю к Soul Reaper и НЕ атакую, жду, пока он снимет HP до 500 или ниже.")

    local prevNoclip = NoclipEnabled
    NoclipEnabled = false   -- позволяем ударам нормально попадать

    -- один раз подлетаем близко
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    sHRP       = soul:FindFirstChild("HumanoidRootPart")
    if hrp and sHRP then
        hrp.CFrame = sHRP.CFrame * CFrame.new(0, 0, -6)
    end

    local waitDeadline = tick() + 120
    while AutoBones
        and soul.Parent
        and sh.Health > 0
        and tick() < waitDeadline
        and not (Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("HellDimension")) do

        char = LocalPlayer.Character
        hrp  = char and char:FindFirstChild("HumanoidRootPart")
        sHRP = soul:FindFirstChild("HumanoidRootPart")
        sh   = soul:FindFirstChild("Humanoid")

        if not (char and hrp and sHRP and sh) then
            break
        end

        -- если нас откинуло далеко (>120), один раз снова подлетаем
        local dist = (hrp.Position - sHRP.Position).Magnitude
        if dist > 120 then
            AddLog("Yama3: меня откинуло от Soul Reaper, подлетаю обратно.")
            hrp.CFrame = sHRP.CFrame * CFrame.new(0, 0, -6)
        end

        -- никакой атаки, просто стоим
        local phum = char:FindFirstChild("Humanoid")
        if phum and phum.Health <= 500 then
            AddLog("Yama3: HP персонажа <= 500, стою на месте 5 сек и жду переноса в HellDimension.")
            UpdateStatus("Yama3: жду авто-переноса в HellDimension (5 сек)...")

            local t0 = tick()
            while AutoBones and tick() - t0 < 5 do
                local m = Workspace:FindFirstChild("Map")
                local hDim = m and m:FindFirstChild("HellDimension")
                if hDim then
                    AddLog("Yama3: HellDimension появился во время ожидания, не тпшусь принудительно.")
                    NoclipEnabled = prevNoclip
                    return
                end
                task.wait(0.1)
            end

            -- 5 сек прошло, проверяем HellDimension
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
                    AddLog("Yama3: 5 сек прошло, HellDimension есть, тп туда вручную (fallback).")
                    SimpleTeleport(fallbackCf, "HellDimension fallback")
                else
                    AddLog("Yama3: HellDimension есть, но нет Torch1/Exit, пропускаю тп.")
                end
            else
                AddLog("Yama3: 5 сек прошло, HellDimension так и не появился, возвращаюсь к обычной логике.")
            end

            NoclipEnabled = prevNoclip
            return
        end

        RunService.Heartbeat:Wait()
    end

    NoclipEnabled = prevNoclip
end

---------------------
-- SUMMONER (использовать Hallow Essence)
---------------------
local function HandleSummonerIfHasHallow()
    if not HasHallow then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local hc = map:FindFirstChild("Haunted Castle")
    if not hc then return end
    local summonerModel = hc:FindFirstChild("Summoner")
    if not summonerModel then return end
    local detection = summonerModel:FindFirstChild("Detection")
    if not detection then return end

    UpdateStatus("Yama3: есть Hallow Essence, лечу к Summoner.")
    AddLog("Yama3: телепорт к Summoner (Haunted Castle) для вызова Soul Reaper.")

    SimpleTeleport(detection.CFrame, "Summoner Detection")
    task.wait(1.0)
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
                RefreshRollWindow()

                -- 0. Всегда сначала летим к Haunted Castle / Death King
                if not EnsureOnHauntedIsland() then
                    return
                end

                local map = Workspace:FindFirstChild("Map")
                local hellDim = map and map:FindFirstChild("HellDimension")

                -- 1. Если HellDimension уже существует — выполняем Yama3 внутри
                if hellDim then
                    UpdateStatus("Yama3: HellDimension активен.")
                    HandleHellDimension()
                    return
                end

                local alucardCount = GetCountMaterials("Alucard Fragment") or 0

                -- 2. Если Alucard Fragment уже 3 — квест завершён, просто фармим кости / Hallow для следующего
                if alucardCount >= 3 then
                    UpdateStatus("Yama3: 3 Alucard Fragment уже есть, просто фармлю кости.")
                    FarmBonesOnce()
                    return
                end

                -- 3. Если есть Hallow Essence, но HellDimension ещё нет — идём к Summoner и ждём Soul Reaper
                if HasHallow then
                    HandleSummonerIfHasHallow()
                    HandleSoulReaperPhase()
                    return
                end

                -- 4. Если нет Hallow Essence, но Soul Reaper уже активен — тоже обрабатываем
                local soul = FindSoulReaper()
                if soul then
                    HandleSoulReaperPhase()
                    return
                end

                -- 5. Иначе: логика Bones + Hallow Essence (роллы)
                if BonesCount >= MinBonesToRoll and RollsUsed < MaxRollsPerWindow then
                    DoDeathKingRolls()
                    return
                end

                -- 6. Если роллить не можем/не нужно — просто фармим скелетов
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
    MainFrame.Size = UDim2.new(0, 420, 0, 300)
    MainFrame.Position = UDim2.new(0, 20, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "Auto Bones + Hallow + Yama3 (10 roll / 2h)"
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
    ToggleButton.Text = "Auto Bones + Yama3: OFF"
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
    RollsLabel.Text = "Роллов (2ч окно): 0/"..tostring(MaxRollsPerWindow)
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
    LogsFrame.Size = UDim2.new(1, -20, 0, 120)
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
            ToggleButton.Text = "Auto Bones + Yama3: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            NoclipEnabled = true
            AddLog("Auto Bones + Yama3 включен (noclip ON, Godhuman, speed 300)")
            UpdateStatus("Фарм костей (Haunted Castle)")
        else
            ToggleButton.Text = "Auto Bones + Yama3: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            NoclipEnabled = false
            AddLog("Auto Bones + Yama3 выключен (noclip OFF)")
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
AddLog("Auto Bones + Hallow + Yama3 (10 roll / 2h) загружен. Включай кнопку в 3-м море (Haunted Castle).")

spawn(function()
    while task.wait(1) do
        if UptimeLabel then
            UptimeLabel.Text = "Время работы: "..GetUptime()
        end
    end
end)
