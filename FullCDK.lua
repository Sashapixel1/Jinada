--========================================================
--  AutoCDK
--  1) Сначала: Yama & Tushita Mastery 350 (Reborn Skeleton / Haunted Castle)
--     После 350/350: открывает дверь триала (CDKQuest, OpenDoor)
--  2) Потом: AUTO CDK + TUSHITA (Yama 1/2/3 + Tushita 1/2/3)
--     Алгоритм по Alucard Fragment:
--       0 -> Yama1
--       1 -> Yama2
--       2 -> Yama3 (через Soul Reaper + HellDimension)
--       3 -> Tushita1 (Trial Evil + Trial Good)
--       4 -> Tushita2 (Trial Good)
--       5 -> Tushita3 (Cake Queen + HeavenlyDimension)
--       >=6 -> Готово, AutoCDK OFF
--========================================================

---------------------
-- НАСТРОЙКИ
---------------------
local WeaponName      = "Godhuman"              -- чем бить мобов в квестах CDK
local TeleportSpeed   = 300
local FarmOffset      = CFrame.new(0, 10, -3)

-- Castle on the Sea (Yama1) – точка у Elite Hunter
local CastleOnSeaCFrame = CFrame.new(-5413.14, 313.79, -2827.95)

-- Haunted Castle / Death King (Yama3 и Mastery Farm)
local HauntedFallback = CFrame.new(-9515.129, 142.233, 6200.441)

-- Патруль Yama2 (HazeESP)
local Yama2PatrolPoints = {
    CFrame.new(-187.3301544189453, 86.23987579345703, 6013.513671875),
    CFrame.new(2286.0078125, 73.13391876220703, -7159.80908203125),
    CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875),
    CFrame.new(-13451.46484375, 543.712890625, -6961.0029296875),
    CFrame.new(-13274.478515625, 332.3781433105469, -7769.58056640625),
    CFrame.new(-13680.607421875, 501.08154296875, -6991.189453125),
    CFrame.new(-13457.904296875, 391.545654296875, -9859.177734375),
    CFrame.new(-12256.16015625, 331.73828125, -10485.8369140625),
    CFrame.new(-1887.8099365234375, 77.6185073852539, -12998.3505859375),
    CFrame.new(-21.55328369140625, 80.57499694824219, -12352.3876953125),
    CFrame.new(582.590576171875, 77.18809509277344, -12463.162109375),
    CFrame.new(-16641.6796875, 235.7825469970703, 1031.282958984375),
    CFrame.new(-16587.896484375, 154.21299743652344, 1533.40966796875),
    CFrame.new(-16885.203125, 114.12911224365234, 1627.949951171875),
}

-- Tushita Q1 (BoatQuest)
local TushitaQ1Points = {
    CFrame.new(-9546.990234375, 21.139892578125, 4686.1142578125),
    CFrame.new(-6120.0576171875, 16.455780029296875, -2250.697265625),
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875),
}

-- Tushita Q2 (фарм зона)
local TushitaQ2Center        = CFrame.new(-5539.3115, 313.8005, -2972.3723)
local TushitaQ2InZoneRadius  = 500
local TushitaQ2MaxMobDistance = 2000

-- Tushita Q3 (Cake Queen + HeavenlyDimension)
local CakeQueenIsland = CFrame.new(-709.3132934570312, 381.6005859375, -11011.396484375)
local CakeQueenOffset = CFrame.new(0, 20, -3)

-- Mastery Farm (Reborn Skeleton)
local MasteryTargetName      = "Reborn Skeleton"
local MasteryTargetMastery   = 350
local MasteryCheckInterval   = 10      -- раз в N секунд чекаем мастери

-- Soul Reaper spawn (Yama3)
local SoulReaperSpawnCF = CFrame.new(-9570.033203125, 315.9346923828125, 6726.89306640625)

---------------------
-- СЕРВИСЫ
---------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local VirtualInput      = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local remote      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- СОСТОЯНИЯ
---------------------
local AutoCDK       = false
local CurrentStage  = -1
local IsTeleporting = false
local StopTween     = false
local NoclipEnabled = false

-- мастерка
local AutoMasteryFarm     = false
local MasteryDone         = false
local MasteryWeaponName   = "Tushita"
local YamaMastery, TushitaMastery = nil, nil
local LastLoggedMastery   = {Yama = nil, Tushita = nil}
local lastMasteryCheck    = 0

-- индивидуальные флаги квестов
local AutoYama1     = false
local AutoYama2     = false
local AutoYama3     = false
local AutoTushita1  = false
local AutoTushita2  = false
local AutoTushita3  = false

---------------------
-- ЛОГИ / GUI
---------------------
local StatusLogs = {}
local MaxLogs    = 200

local ScreenGui, MainFrame, BtnCDK
local StatusLabel, AFLabel, LogsText
local YamaLabelGui, TushitaLabelGui

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
    print(line)
end

local function UpdateStatus(text)
    if StatusLabel then
        StatusLabel.Text = "Статус: "..tostring(text)
    end
    AddLog("Статус: "..tostring(text))
end

local function UpdateAFLabel(count)
    if AFLabel then
        AFLabel.Text = "Alucard Fragment: "..tostring(count or 0)
    end
end

local function UpdateMasteryLabels()
    if YamaLabelGui then
        if YamaMastery ~= nil then
            YamaLabelGui.Text = "Yama Mastery: "..tostring(YamaMastery)
        else
            YamaLabelGui.Text = "Yama Mastery: —"
        end
    end
    if TushitaLabelGui then
        if TushitaMastery ~= nil then
            TushitaLabelGui.Text = "Tushita Mastery: "..tostring(TushitaMastery)
        else
            TushitaLabelGui.Text = "Tushita Mastery: —"
        end
    end
end

---------------------
-- GUI
---------------------
local function DisableAllQuests() end -- объявим заранее, реализуем ниже

local function CreateMainGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoCDKGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 520, 0, 340)
    MainFrame.Position = UDim2.new(0, 40, 0, 180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    title.Text = "AutoCDK (Mastery 350 + Yama/Tushita Quests)"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = MainFrame

    BtnCDK = Instance.new("TextButton")
    BtnCDK.Size = UDim2.new(0, 220, 0, 32)
    BtnCDK.Position = UDim2.new(0, 10, 0, 30)
    BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
    BtnCDK.TextColor3 = Color3.new(1,1,1)
    BtnCDK.Font = Enum.Font.SourceSansBold
    BtnCDK.TextSize = 16
    BtnCDK.Text = "Auto CDK: OFF"
    BtnCDK.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 22)
    StatusLabel.Position = UDim2.new(0, 10, 0, 70)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: Остановлен"
    StatusLabel.Parent = MainFrame

    AFLabel = Instance.new("TextLabel")
    AFLabel.Size = UDim2.new(1, -20, 0, 22)
    AFLabel.Position = UDim2.new(0, 10, 0, 92)
    AFLabel.BackgroundTransparency = 1
    AFLabel.TextColor3 = Color3.new(1,1,1)
    AFLabel.Font = Enum.Font.SourceSans
    AFLabel.TextSize = 14
    AFLabel.TextXAlignment = Enum.TextXAlignment.Left
    AFLabel.Text = "Alucard Fragment: 0"
    AFLabel.Parent = MainFrame

    YamaLabelGui = Instance.new("TextLabel")
    YamaLabelGui.Size = UDim2.new(1, -20, 0, 20)
    YamaLabelGui.Position = UDim2.new(0, 10, 0, 114)
    YamaLabelGui.BackgroundTransparency = 1
    YamaLabelGui.TextColor3 = Color3.new(1,1,1)
    YamaLabelGui.Font = Enum.Font.SourceSans
    YamaLabelGui.TextSize = 14
    YamaLabelGui.TextXAlignment = Enum.TextXAlignment.Left
    YamaLabelGui.Text = "Yama Mastery: —"
    YamaLabelGui.Parent = MainFrame

    TushitaLabelGui = Instance.new("TextLabel")
    TushitaLabelGui.Size = UDim2.new(1, -20, 0, 20)
    TushitaLabelGui.Position = UDim2.new(0, 10, 0, 134)
    TushitaLabelGui.BackgroundTransparency = 1
    TushitaLabelGui.TextColor3 = Color3.new(1,1,1)
    TushitaLabelGui.Font = Enum.Font.SourceSans
    TushitaLabelGui.TextSize = 14
    TushitaLabelGui.TextXAlignment = Enum.TextXAlignment.Left
    TushitaLabelGui.Text = "Tushita Mastery: —"
    TushitaLabelGui.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 170)
    LogsFrame.Position = UDim2.new(0, 10, 0, 160)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
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

    BtnCDK.MouseButton1Click:Connect(function()
        AutoCDK = not AutoCDK

        if AutoCDK then
            BtnCDK.Text = "Auto CDK: ON"
            BtnCDK.BackgroundColor3 = Color3.fromRGB(0,120,0)
            NoclipEnabled   = true
            StopTween       = false
            MasteryDone     = false
            AutoMasteryFarm = true
            DisableAllQuests()
            UpdateStatus("AutoCDK включен. Сначала фарм мастери Yama/Tushita до 350.")
            lastMasteryCheck = 0
        else
            BtnCDK.Text = "Auto CDK: OFF"
            BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled   = false
            StopTween       = true
            AutoMasteryFarm = false
            MasteryDone     = false
            DisableAllQuests()
            UpdateStatus("Остановлен")
        end
    end)

    AddLog("GUI AutoCDK загружен.")
    UpdateMasteryLabels()
end

CreateMainGui()

---------------------
-- ANTI-AFK
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
-- NET / FAST ATTACK
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
-- ЭКИП / ХАКИ
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

local function HasToolInCharOrBackpack(name)
    local p = LocalPlayer
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
    if HasToolInCharOrBackpack(name) then return true end

    if HasInAccountInventory(name) then
        pcall(function()
            remote:InvokeServer("LoadItem", name)
        end)
        task.wait(0.5)
        if HasToolInCharOrBackpack(name) then
            AddLog("Загрузил из инвентаря предмет: "..name)
            return true
        end
    end
    return false
end

local function EquipToolByName(name)
    if IsToolEquipped(name) then return end

    local p   = LocalPlayer
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
        AddLog("⚔️ Экипирован: "..toolFound.Name)
    else
        if tick() - lastEquipFailLog > 3 then
            AddLog("⚠️ Не удалось найти оружие: "..name)
            lastEquipFailLog = tick()
        end
    end
end

---------------------
-- ТП
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
    local travelTime = distance / TeleportSpeed
    travelTime = math.clamp(travelTime, 0.5, 60)

    AddLog(string.format("Телепорт к %s (%.0f stud, t=%.1f)", label or "цели", distance, travelTime))

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()

    local start = tick()
    while tick() - start < travelTime do
        if StopTween or not AutoCDK then
            tween:Cancel()
            IsTeleporting = false
            AddLog("Телепорт прерван.")
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
    AddLog("Персонаж возрождён, HRP обновлён.")
    char:WaitForChild("HumanoidRootPart", 10)
end)

---------------------
-- ИНВЕНТАРЬ / МАТЕРИАЛЫ
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
-- ОТКРЫТИЕ ДВЕРИ ТРИАЛА (CDKQuest, OpenDoor)
---------------------
local function OpenTrialDoor()
    AddLog("Пробую открыть дверь триала (CDKQuest, OpenDoor).")

    local ok1, res1 = pcall(function()
        return remote:InvokeServer("CDKQuest", "OpenDoor")
    end)
    if ok1 then
        AddLog("OpenDoor шаг #1 => "..tostring(res1))
    else
        AddLog("Ошибка OpenDoor шаг #1: "..tostring(res1))
    end

    task.wait(0.3)

    local ok2, res2 = pcall(function()
        return remote:InvokeServer("CDKQuest", "OpenDoor", true)
    end)
    if ok2 then
        AddLog("OpenDoor шаг #2 => "..tostring(res2))
    else
        AddLog("Ошибка OpenDoor шаг #2: "..tostring(res2))
    end

    AddLog("✅ Попытка открыть дверь триала завершена.")
end

---------------------
-- Haunted Castle центр
---------------------
local function FindDeathKingModel()
    local candidate
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Death King" then
            if obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") then
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
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return false end

    local center = GetHauntedCenterCFrame()
    local dist   = (hrp.Position - center.Position).Magnitude
    if dist > 600 then
        UpdateStatus("Лечу к Haunted Castle.")
        SimpleTeleport(center * CFrame.new(0,4,3), "Haunted Castle")
        task.wait(1)
        return false
    end
    return true
end

---------------------
-- MASTERy FARM: Reborn Skeleton
---------------------
local function GetNearestRebornSkeleton(maxDistance)
    maxDistance = maxDistance or 9999
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local center = GetHauntedCenterCFrame()
    local best, nearest = maxDistance, nil

    for _, v in ipairs(enemies:GetChildren()) do
        if v.Name == MasteryTargetName
           and v:FindFirstChild("Humanoid")
           and v:FindFirstChild("HumanoidRootPart")
           and v.Humanoid.Health > 0 then

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

local function RefreshMasteries()
    local ok, inv = pcall(function()
        return remote:InvokeServer("getInventory")
    end)

    if not ok or type(inv) ~= "table" then
        AddLog("Ошибка getInventory при обновлении мастери: "..tostring(inv))
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
            AddLog("Yama Mastery: "..tostring(newY))
            LastLoggedMastery.Yama = newY
        end
    end

    if newT ~= nil then
        TushitaMastery = newT
        if LastLoggedMastery.Tushita ~= newT then
            AddLog("Tushita Mastery: "..tostring(newT))
            LastLoggedMastery.Tushita = newT
        end
    end

    UpdateMasteryLabels()
end

local function ChooseMasteryWeapon()
    local t = TushitaMastery or 0
    local y = YamaMastery or 0

    if t < MasteryTargetMastery and (HasToolInCharOrBackpack("Tushita") or HasInAccountInventory("Tushita")) then
        if MasteryWeaponName ~= "Tushita" then
            MasteryWeaponName = "Tushita"
            AddLog("Смена оружия для мастери: Tushita ("..tostring(t)..")")
        end
    elseif y < MasteryTargetMastery and (HasToolInCharOrBackpack("Yama") or HasInAccountInventory("Yama")) then
        if MasteryWeaponName ~= "Yama" then
            MasteryWeaponName = "Yama"
            AddLog("Смена оружия для мастери: Yama ("..tostring(y)..")")
        end
    end
end

local function FarmMasteryOnce()
    local target = GetNearestRebornSkeleton(4000)
    if not target then
        UpdateStatus("Mastery: Reborn Skeleton не найден, жду спавна.")
        return
    end

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        UpdateStatus("Mastery: фарм "..MasteryWeaponName.." на "..MasteryTargetName)
        SimpleTeleport(tHRP.CFrame * FarmOffset, MasteryTargetName)

        local deadline      = tick() + 90
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoMasteryFarm and AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2500 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий "..MasteryTargetName)
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
            EquipToolByName(MasteryWeaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        local dead = not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
        if dead then
            AddLog("✅ "..MasteryTargetName.." убит, мастери "..MasteryWeaponName.." должна была вырасти.")
        end
    end)

    if not ok then
        AddLog("Ошибка FarmMasteryOnce: "..tostring(err))
    end
end

local function RunMasteryLoop()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then
        UpdateStatus("Mastery: жду персонажа...")
        return
    end

    if not (HasToolInCharOrBackpack("Yama") or HasInAccountInventory("Yama")
        or HasToolInCharOrBackpack("Tushita") or HasInAccountInventory("Tushita")) then

        UpdateStatus("Mastery: Yama/Tushita не найдены в инвентаре.")
        AddLog("❌ Mastery: нет Yama/Tushita. Получи мечи перед запуском AutoCDK.")
        return
    end

    if not EnsureOnHauntedIsland() then
        return
    end

    EnsureItemInBackpack(MasteryWeaponName)
    EquipToolByName(MasteryWeaponName)

    FarmMasteryOnce()
end

---------------------
-- FIGHT HELPER
---------------------
local function HoldEFor(seconds)
    seconds = seconds or 2
    AddLog("Зажимаю E на "..tostring(seconds).." сек.")
    VirtualInput:SendKeyEvent(true, "E", false, game)
    task.wait(seconds)
    VirtualInput:SendKeyEvent(false, "E", false, game)
end

local function FightMobSimple(target, label, offsetCF)
    offsetCF = offsetCF or FarmOffset
    if not target then return false end

    local killed = false

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not (char and hrp and hum and tHRP) then return end

        UpdateStatus(label or ("Бой: "..target.Name))
        SimpleTeleport(tHRP.CFrame * offsetCF, label or "цель")

        local deadline      = tick() + 90
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and hum and tHRP) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * offsetCF, "далёкий моб")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * offsetCF
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName(WeaponName)
            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        if hum and (hum.Health <= 0 or not target.Parent) then
            killed = true
        end
    end)

    if not ok then
        AddLog("Ошибка FightMobSimple: "..tostring(err))
    end

    return killed
end

---------------------
-- CDKTrialModule
-- Evil теперь: Progress -> StartTrial -> два клика по Main.Dialogue.Option1
---------------------
local CDKTrialModule = {}

local function ClickDialogueOption1Once(logPrefix)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        AddLog(logPrefix.." Option1: PlayerGui не найден.")
        return false
    end

    local mainGui = pg:FindFirstChild("Main")
    if not mainGui then
        AddLog(logPrefix.." Option1: Main не найден.")
        return false
    end

    local dialogue = mainGui:FindFirstChild("Dialogue")
    if not dialogue then
        AddLog(logPrefix.." Option1: Dialogue не найден.")
        return false
    end

    local option1 = dialogue:FindFirstChild("Option1")
    if not option1 or not option1:IsA("TextButton") then
        AddLog(logPrefix.." Option1: кнопка Option1 не найдена.")
        return false
    end

    AddLog(logPrefix.." Нажимаю Main.Dialogue.Option1")
    local ok, err = pcall(function()
        option1:Activate()
    end)
    if not ok then
        AddLog(logPrefix.." Ошибка при активации Option1: "..tostring(err))
        return false
    end
    return true
end

function CDKTrialModule.StartEvilTrial(logFunc)
    local function Log(msg)
        if logFunc then logFunc("[Trial Evil] "..msg) else AddLog("[Trial Evil] "..msg) end
    end

    Log("Progress Evil...")
    local okP, resP = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Evil")
    end)
    if okP then
        Log("Progress(Evil) = "..tostring(resP))
    else
        Log("Ошибка Progress(Evil): "..tostring(resP))
    end

    task.wait(0.2)

    Log("StartTrial Evil...")
    local okS, resS = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Evil")
    end)
    if okS then
        Log("StartTrial(Evil) => "..tostring(resS))
    else
        Log("Ошибка StartTrial(Evil): "..tostring(resS))
    end

    task.wait(0.2)

    -- имитация двух кликов по Option1 как в логере
    ClickDialogueOption1Once("[Trial Evil]")
    task.wait(0.1)
    ClickDialogueOption1Once("[Trial Evil]")
end

function CDKTrialModule.StartGoodTrial(logFunc)
    local function Log(msg)
        if logFunc then logFunc("[Trial Good] "..msg) else AddLog("[Trial Good] "..msg) end
    end

    Log("Progress Good...")
    local okP, resP = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Good")
    end)
    if okP then
        Log("Progress(Good) = "..tostring(resP))
    else
        Log("Ошибка Progress(Good): "..tostring(resP))
    end

    task.wait(0.2)

    Log("StartTrial Good...")
    local okS, resS = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Good")
    end)
    if okS then
        Log("StartTrial(Good) => "..tostring(resS))
    else
        Log("Ошибка StartTrial(Good): "..tostring(resS))
    end

    task.wait(0.2)

    Log("Option1 Good...")
    local okO, resO = pcall(function()
        return remote:InvokeServer("CDKQuest", "Option", "Good", "Option1")
    end)
    if okO then
        Log("✅ Option(Good, Option1) => "..tostring(resO))
    else
        Log("❌ Ошибка Option(Good, Option1): "..tostring(resO))
    end
end

---------------------
-- YAMA QUEST 1
---------------------
local function YamaQuest1Tick()
    if not AutoYama1 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 1 then
        AutoYama1 = false
        UpdateStatus("Yama1: фрагмент получен, перехожу к Yama2.")
        return
    end

    EquipToolByName("Yama")

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and hrp and hum) then return end

    if hum.Health <= 0 then
        return
    end

    local dist = (hrp.Position - CastleOnSeaCFrame.Position).Magnitude
    if dist > 150 then
        UpdateStatus("Yama1: лечу к Elite Hunter в Castle on the Sea, жду смерти.")
        SimpleTeleport(CastleOnSeaCFrame, "Elite Hunter (Castle on the Sea)")
    else
        UpdateStatus("Yama1: стою у Elite Hunter, жду, пока умру.")
    end
end

---------------------
-- YAMA QUEST 2 (HazeESP)
---------------------
local Yama2PatrolIndex   = 1
local Yama2PatrolHold    = 0
local Yama2LastPatrolHop = 0
local Yama2IsFighting    = false

local function GetNearestHazeEnemy(maxDistance)
    maxDistance = maxDistance or 9999
    local enemies = Workspace:FindFirstChild("Enemies")
    local char    = LocalPlayer.Character
    local hrp     = char and char:FindFirstChild("HumanoidRootPart")
    if not enemies or not hrp then return nil end

    local best, nearest = maxDistance, nil
    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if v:FindFirstChild("HazeESP") then
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

local function Yama2PatrolStep()
    if not AutoYama2 or not AutoCDK then return end
    if IsTeleporting then return end
    if tick() < Yama2PatrolHold then return end
    if tick() - Yama2LastPatrolHop < 2 then return end

    local idx = Yama2PatrolIndex
    Yama2PatrolIndex = Yama2PatrolIndex + 1
    if Yama2PatrolIndex > #Yama2PatrolPoints then
        Yama2PatrolIndex = 1
    end

    Yama2LastPatrolHop = tick()
    local targetCF = Yama2PatrolPoints[idx] * FarmOffset
    AddLog("Yama2: патруль к точке "..idx)
    SimpleTeleport(targetCF, "Yama2 патруль "..idx)
    Yama2PatrolHold = tick() + 5
end

local function YamaQuest2Tick()
    if not AutoYama2 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 2 then
        AutoYama2 = false
        UpdateStatus("Yama2: второй фрагмент получен, перехожу к Yama3.")
        return
    end

    if Yama2IsFighting then return end

    local target = GetNearestHazeEnemy(9999)
    if not target then
        UpdateStatus("Yama2: Haze-мобы не найдены, патрулирую.")
        Yama2PatrolStep()
        return
    end

    Yama2IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        UpdateStatus("Yama2: фарм "..target.Name)
        SimpleTeleport(tHRP.CFrame * FarmOffset, "Yama2 моб")

        local deadline      = tick() + 40
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoYama2 and AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий Haze-моб")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName("Yama")

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка YamaQuest2Tick: "..tostring(err))
    end

    Yama2IsFighting = false
end

---------------------
-- YAMA QUEST 3 (Soul Reaper + HellDimension)
---------------------
local function IsBoneMob(mob)
    local n = tostring(mob.Name)
    if string.find(n, "Skeleton") then return true end
    if string.find(n, "Reborn Skeleton") then return true end
    if string.find(n, "Living Skeleton") then return true end
    return false
end

local function GetNearestBoneMob(maxDistance)
    maxDistance = maxDistance or 9999
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local center = GetHauntedCenterCFrame()
    local best, nearest = maxDistance, nil

    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if IsBoneMob(v) then
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
    end
    return nearest
end

local function FarmBonesOnce()
    local target = GetNearestBoneMob(9999)
    if not target then
        UpdateStatus("Yama3: скелеты не найдены.")
        return
    end

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        UpdateStatus("Yama3: фарм костей ("..target.Name..")")
        SimpleTeleport(tHRP.CFrame * FarmOffset, "скелет")

        local deadline      = tick() + 40
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoYama3 and AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий скелет")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName(WeaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка FarmBonesOnce: "..tostring(err))
    end
end

-- HellDimension: мобы
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
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if IsHellMob(v) then
                FightMobSimple(v, "Yama3: моб HellDimension", FarmOffset)
            end
        end
    end
end

local function HandleHellDimensionYama3()
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local hd = map:FindFirstChild("HellDimension")
    if not hd then return end

    UpdateStatus("Yama3: HellDimension активен.")
    AddLog("Yama3: HellDimension обнаружен, выполняю факела и мобов.")

    local Torch1 = hd:FindFirstChild("Torch1")
    local Torch2 = hd:FindFirstChild("Torch2")
    local Torch3 = hd:FindFirstChild("Torch3")
    local Exit   = hd:FindFirstChild("Exit")

    if Torch1 then
        AddLog("Yama3 Hell: Torch1 -> держу E 2 сек, затем убиваю мобов.")
        SimpleTeleport(Torch1.CFrame, "Hell Torch1")
        task.wait(0.3)
        HoldEFor(2)
        task.wait(0.3)
        FarmHellMobsOnce()
    end

    if Torch2 then
        AddLog("Yama3 Hell: Torch2 -> держу E 2 сек, затем убиваю мобов.")
        SimpleTeleport(Torch2.CFrame, "Hell Torch2")
        task.wait(0.3)
        HoldEFor(2)
        task.wait(0.3)
        FarmHellMobsOnce()
    end

    if Torch3 then
        AddLog("Yama3 Hell: Torch3 -> держу E 2 сек, затем убиваю мобов.")
        SimpleTeleport(Torch3.CFrame, "Hell Torch3")
        task.wait(0.3)
        HoldEFor(2)
        task.wait(0.3)
        FarmHellMobsOnce()
    end

    AddLog("Yama3 Hell: добиваю мобов/босса в измерении.")
    FarmHellMobsOnce()

    if Exit then
        AddLog("Yama3 Hell: телепорт к Exit.")
        SimpleTeleport(Exit.CFrame, "Hell Exit")
    else
        AddLog("Yama3 Hell: Exit не найден.")
    end
end

-- Soul Reaper
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

local function HandleSoulReaperPhaseYama3()
    local map = Workspace:FindFirstChild("Map")
    local hd  = map and map:FindFirstChild("HellDimension")
    if hd then
        return
    end

    local soul, sh, sHRP = FindSoulReaper()
    if not soul then
        AddLog("Yama3: Soul Reaper не найден, лечу на его спавн.")
        SimpleTeleport(SoulReaperSpawnCF, "Soul Reaper spawn")
        return
    end

    UpdateStatus("Yama3: Soul Reaper найден, подлетаю и стою 20 сек.")
    AddLog("Yama3: подлетаю к Soul Reaper, не уклоняюсь и не атакую 20 секунд, жду HellDimension.")

    local prevNoclip = NoclipEnabled
    NoclipEnabled = false   -- даём ударам попадать по персонажу

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    sHRP       = soul:FindFirstChild("HumanoidRootPart")
    sh         = soul:FindFirstChild("Humanoid")

    if hrp and sHRP then
        hrp.CFrame = sHRP.CFrame * CFrame.new(0, 0, -6)
    end

    local waitDeadline = tick() + 20

    while AutoYama3 and AutoCDK and soul.Parent and sh and sh.Health > 0 and tick() < waitDeadline do
        char = LocalPlayer.Character
        hrp  = char and char:FindFirstChild("HumanoidRootPart")
        sHRP = soul:FindFirstChild("HumanoidRootPart")
        sh   = soul:FindFirstChild("Humanoid")

        if not (char and hrp and sHRP and sh) then
            break
        end

        local m = Workspace:FindFirstChild("Map")
        local hDim = m and m:FindFirstChild("HellDimension")
        if hDim then
            AddLog("Yama3: HellDimension появился во время ожидания у Soul Reaper.")
            NoclipEnabled = prevNoclip
            return
        end

        local dist = (hrp.Position - sHRP.Position).Magnitude
        if dist > 120 then
            hrp.CFrame = sHRP.CFrame * CFrame.new(0, 0, -6)
        end

        RunService.Heartbeat:Wait()
    end

    local m2  = Workspace:FindFirstChild("Map")
    local hd2 = m2 and m2:FindFirstChild("HellDimension")
    if hd2 then
        local torch1 = hd2:FindFirstChild("Torch1")
        local exit   = hd2:FindFirstChild("Exit")
        local fallback
        if torch1 and torch1.CFrame then
            fallback = torch1.CFrame
        elseif exit and exit.CFrame then
            fallback = exit.CFrame
        end

        if fallback then
            AddLog("Yama3: 20 сек прошло, HellDimension есть, тп внутрь.")
            SimpleTeleport(fallback, "HellDimension")
        end
    else
        AddLog("Yama3: 20 сек прошло, HellDimension не появился, продолжаю фарм костей.")
    end

    NoclipEnabled = prevNoclip
end

local function YamaQuest3Tick()
    if not AutoYama3 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 3 then
        AutoYama3 = false
        UpdateStatus("Yama3: третий фрагмент получен, перехожу к Tushita.")
        return
    end

    if not EnsureOnHauntedIsland() then
        return
    end

    local map = Workspace:FindFirstChild("Map")
    local hellDim = map and map:FindFirstChild("HellDimension")

    if hellDim then
        HandleHellDimensionYama3()
        return
    end

    local soul = FindSoulReaper()
    if soul then
        HandleSoulReaperPhaseYama3()
        return
    end

    FarmBonesOnce()
end

---------------------
-- TUSHITA QUEST 1 (BoatQuest)
---------------------
local Tushita1Index = 1

local function FindNearestLuxuryBoatDealer(maxDist)
    maxDist = maxDist or 200
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, nearest = maxDist, nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Luxury Boat Dealer" then
            local head = obj:FindFirstChild("HumanoidRootPart") or
                         obj:FindFirstChild("Head") or
                         obj:FindFirstChildWhichIsA("BasePart")
            if head then
                local d = (head.Position - hrp.Position).Magnitude
                if d < best then
                    best    = d
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

local function TushitaQuest1Tick()
    if not AutoTushita1 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 4 then
        AutoTushita1 = false
        UpdateStatus("Tushita1: фрагмент получен, перехожу к Tushita2.")
        return
    end

    local idx = Tushita1Index
    Tushita1Index = Tushita1Index + 1
    if Tushita1Index > #TushitaQ1Points then
        Tushita1Index = 1
    end

    UpdateStatus("Tushita1: точка "..idx)
    SimpleTeleport(TushitaQ1Points[idx], "Tushita Q1 точка "..idx)

    local npc = FindNearestLuxuryBoatDealer(150)
    if not npc then
        AddLog("Tushita1: Luxury Boat Dealer не найден у точки "..idx)
        return
    end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local head = npc:FindFirstChild("HumanoidRootPart") or
                 npc:FindFirstChild("Head") or
                 npc:FindFirstChildWhichIsA("BasePart")

    if head then
        hrp.CFrame = head.CFrame * CFrame.new(0,0,-3)
    end

    local ok1, res1 = pcall(function()
        return remote:InvokeServer("GetUnlockables","BoatDealer")
    end)
    if ok1 then
        AddLog("Tushita1: GetUnlockables/BoatDealer => "..tostring(res1))
    else
        AddLog("Tushita1: ошибка GetUnlockables => "..tostring(res1))
    end

    task.wait(0.3)

    local ok2, res2 = pcall(function()
        return remote:InvokeServer("CDKQuest","BoatQuest", npc)
    end)
    if ok2 then
        AddLog("Tushita1: BoatQuest => "..tostring(res2))
    else
        AddLog("Tushita1: ошибка BoatQuest => "..tostring(res2))
    end
end

---------------------
-- TUSHITA QUEST 2 (фарм в зоне)
---------------------
local Tushita2IsFighting = false

local function IsInTushita2Zone()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, 99999 end
    local dist = (hrp.Position - TushitaQ2Center.Position).Magnitude
    return dist <= TushitaQ2InZoneRadius, dist
end

local function GetNearestMobInTushita2Zone()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, nearest = TushitaQ2MaxMobDistance, nil
    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            local tHRP = v.HumanoidRootPart
            local distToPlayer = (tHRP.Position - hrp.Position).Magnitude
            local distToCenter = (tHRP.Position - TushitaQ2Center.Position).Magnitude
            if distToPlayer <= TushitaQ2MaxMobDistance and distToCenter <= TushitaQ2InZoneRadius + 200 then
                if distToPlayer < best then
                    best    = distToPlayer
                    nearest = v
                end
            end
        end
    end
    return nearest
end

local function TushitaQuest2Tick()
    if not AutoTushita2 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 5 then
        AutoTushita2 = false
        UpdateStatus("Tushita2: фрагмент получен, перехожу к Tushita3.")
        return
    end

    if Tushita2IsFighting then return end

    local inZone, dist = IsInTushita2Zone()
    if not inZone then
        UpdateStatus(string.format("Tushita2: лечу в зону (%.0f stud)", dist or 9999))
        SimpleTeleport(TushitaQ2Center * CFrame.new(0,5,0), "центр Tushita Q2")
        return
    end

    local target = GetNearestMobInTushita2Zone()
    if not target then
        UpdateStatus("Tushita2: враги не найдены, жду...")
        return
    end

    Tushita2IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        UpdateStatus("Tushita2: фарм "..target.Name)
        SimpleTeleport(tHRP.CFrame * FarmOffset, "моб Tushita Q2")

        local deadline      = tick() + 45
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoTushita2 and AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

            local distToMob = (tHRP.Position - hrp.Position).Magnitude
            if distToMob > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий моб Tushita Q2")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName(WeaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка TushitaQuest2Tick: "..tostring(err))
    end

    Tushita2IsFighting = false
end

---------------------
-- TUSHITA QUEST 3 (Cake Queen + HeavenlyDimension)
---------------------
local T3_HeavenlyStage       = 0  -- 0 Torch1, 1 Torch2, 2 Torch3, 3 Exit
local LastCakeQueenKillTime  = 0

local function HeavenlyDimensionFolder()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("HeavenlyDimension")
end

local function FindCakeQueen()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    for _, v in ipairs(enemies:GetChildren()) do
        if v.Name == "Cake Queen"
           and v:FindFirstChild("Humanoid")
           and v:FindFirstChild("HumanoidRootPart")
           and v.Humanoid.Health > 0 then
            return v
        end
    end
    return nil
end

local function FarmHeavenMobsOnce()
    local enemies = Workspace:FindFirstChild("Enemies")
    local dim     = HeavenlyDimensionFolder()
    if not enemies or not dim then return end

    AddLog("Tushita3: убиваю мобов в HeavenlyDimension.")

    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            FightMobSimple(v, "Tushita3: моб в HeavenlyDimension", FarmOffset)
        end
    end
end

local function TushitaQuest3Tick()
    if not AutoTushita3 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af >= 6 then
        AutoTushita3 = false
        UpdateStatus("Tushita3: 6-й фрагмент получен. Готово.")
        AutoCDK       = false
        NoclipEnabled = false
        StopTween     = true
        if BtnCDK then
            BtnCDK.Text = "Auto CDK: OFF"
            BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
        end
        AddLog("Готово: 6 Alucard Fragment. Все квесты завершены.")
        return
    end

    local dim = HeavenlyDimensionFolder()

    if not dim then
        local boss = FindCakeQueen()
        if boss then
            local killed = FightMobSimple(boss, "Tushita3: Cake Queen", CakeQueenOffset)
            if killed then
                LastCakeQueenKillTime = tick()
                AddLog("Tushita3: Cake Queen убита, жду 5 секунд авто-переноса в HeavenlyDimension.")
            end
        else
            if LastCakeQueenKillTime > 0 and tick() - LastCakeQueenKillTime < 5 then
                UpdateStatus("Tushita3: жду переноса в HeavenlyDimension...")
                return
            end
            UpdateStatus("Tushita3: Cake Queen не найдена, лечу на остров.")
            SimpleTeleport(CakeQueenIsland, "остров Cake Queen")
        end
        return
    end

    local torch1 = dim:FindFirstChild("Torch1")
    local torch2 = dim:FindFirstChild("Torch2")
    local torch3 = dim:FindFirstChild("Torch3")
    local exit   = dim:FindFirstChild("Exit")

    if T3_HeavenlyStage == 0 and torch1 then
        UpdateStatus("Tushita3: Torch1.")
        SimpleTeleport(torch1.CFrame * CFrame.new(0,5,0), "Torch1")
        HoldEFor(2)
        FarmHeavenMobsOnce()
        T3_HeavenlyStage = 1
        return
    end

    if T3_HeavenlyStage == 1 and torch2 then
        UpdateStatus("Tushita3: Torch2.")
        SimpleTeleport(torch2.CFrame * CFrame.new(0,5,0), "Torch2")
        HoldEFor(2)
        FarmHeavenMobsOnce()
        T3_HeavenlyStage = 2
        return
    end

    if T3_HeavenlyStage == 2 and torch3 then
        UpdateStatus("Tushita3: Torch3.")
        SimpleTeleport(torch3.CFrame * CFrame.new(0,5,0), "Torch3")
        HoldEFor(2)
        FarmHeavenMobsOnce()
        T3_HeavenlyStage = 3
        return
    end

    if T3_HeavenlyStage == 3 then
        FarmHeavenMobsOnce()
        if exit then
            UpdateStatus("Tushita3: лечу к Exit.")
            SimpleTeleport(exit.CFrame * CFrame.new(0,5,0), "Exit")
            T3_HeavenlyStage = 4
        else
            UpdateStatus("Tushita3: Exit не найден.")
        end
        return
    end

    if T3_HeavenlyStage >= 4 then
        UpdateStatus("Tushita3: жду завершения HeavenlyDimension.")
    end
end

---------------------
-- ПОМОЩЬ: стадия по AF
---------------------
local function GetStageFromAF(count)
    if count <= 0 then
        return 0
    elseif count == 1 then
        return 1
    elseif count == 2 then
        return 2
    elseif count == 3 then
        return 3
    elseif count == 4 then
        return 4
    elseif count == 5 then
        return 5
    else
        return 6
    end
end

function DisableAllQuests()
    AutoYama1,AutoYama2,AutoYama3 = false,false,false
    AutoTushita1,AutoTushita2,AutoTushita3 = false,false,false
end

---------------------
-- ГЛАВНЫЙ ЦИКЛ AutoCDK (после мастери)
---------------------
spawn(function()
    while task.wait(1) do
        if not AutoCDK then
            CurrentStage = -1
        else
            if not MasteryDone then
                -- ждём, мастерка ещё идёт
            else
                local af = GetCountMaterials("Alucard Fragment") or 0
                UpdateAFLabel(af)

                local stage = GetStageFromAF(af)
                if stage ~= CurrentStage then
                    CurrentStage = stage
                    AddLog("CDK: AF="..af.." -> стадия "..stage)
                    DisableAllQuests()
                    StopTween = true
                    task.wait(0.2)
                    StopTween = false

                    if stage == 0 then
                        UpdateStatus("Yama Quest 1")
                        AutoYama1 = true
                        AddLog("Перед Yama1: запускаю Trial Evil.")
                        CDKTrialModule.StartEvilTrial(AddLog)

                    elseif stage == 1 then
                        UpdateStatus("Yama Quest 2")
                        AutoYama2 = true
                        AddLog("Перед Yama2: запускаю Trial Evil.")
                        CDKTrialModule.StartEvilTrial(AddLog)

                    elseif stage == 2 then
                        UpdateStatus("Yama Quest 3")
                        AutoYama3 = true
                        AddLog("Перед Yama3: запускаю Trial Evil.")
                        CDKTrialModule.StartEvilTrial(AddLog)

                    elseif stage == 3 then
                        UpdateStatus("Tushita Quest 1 (BoatQuest)")
                        AutoTushita1 = true
                        AddLog("Перед Tushita1: запускаю Trial Evil.")
                        CDKTrialModule.StartEvilTrial(AddLog)
                        task.wait(0.3)
                        AddLog("Перед Tushita1: запускаю Trial Good.")
                        CDKTrialModule.StartGoodTrial(AddLog)

                    elseif stage == 4 then
                        UpdateStatus("Tushita Quest 2")
                        AutoTushita2 = true
                        AddLog("Перед Tushita2: запускаю Trial Good.")
                        CDKTrialModule.StartGoodTrial(AddLog)

                    elseif stage == 5 then
                        UpdateStatus("Tushita Quest 3")
                        AutoTushita3 = true
                        T3_HeavenlyStage = 0
                        LastCakeQueenKillTime = 0
                        AddLog("Перед Tushita3: запускаю Trial Good.")
                        CDKTrialModule.StartGoodTrial(AddLog)

                    elseif stage == 6 then
                        UpdateStatus("Готово (6+ Alucard Fragment)")
                        AddLog("Все 6 фрагментов уже есть, выключаю AutoCDK.")
                        AutoCDK       = false
                        NoclipEnabled = false
                        StopTween     = true
                        if BtnCDK then
                            BtnCDK.Text = "Auto CDK: OFF"
                            BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
                        end
                    end
                end
            end
        end
    end
end)

---------------------
-- ТИКИ КВЕСТОВ
---------------------
spawn(function()
    while task.wait(0.4) do
        if AutoYama1    then pcall(YamaQuest1Tick)    end
        if AutoYama2    then pcall(YamaQuest2Tick)    end
        if AutoYama3    then pcall(YamaQuest3Tick)    end
        if AutoTushita1 then pcall(TushitaQuest1Tick) end
        if AutoTushita2 then pcall(TushitaQuest2Tick) end
        if AutoTushita3 then pcall(TushitaQuest3Tick) end
    end
end)

---------------------
-- ЦИКЛ MASTERy FARM (идёт первым этапом AutoCDK)
---------------------
spawn(function()
    while task.wait(0.4) do
        if AutoCDK and AutoMasteryFarm then
            local ok, err = pcall(function()
                if tick() - lastMasteryCheck >= MasteryCheckInterval then
                    lastMasteryCheck = tick()
                    RefreshMasteries()

                    if YamaMastery and YamaMastery >= MasteryTargetMastery
                       and TushitaMastery and TushitaMastery >= MasteryTargetMastery then

                        UpdateStatus("Готово: Yama/Tushita мастери >= "..MasteryTargetMastery..". Открываю дверь триала.")
                        AddLog("✅ Mastery Farm завершён. Yama="..tostring(YamaMastery)
                            ..", Tushita="..tostring(TushitaMastery))

                        OpenTrialDoor()

                        AutoMasteryFarm = false
                        MasteryDone     = true
                        AddLog("Переход к AutoCDK квестам (Yama1-3, Tushita1-3).")
                        return
                    end

                    ChooseMasteryWeapon()
                end

                RunMasteryLoop()
            end)
            if not ok then
                AddLog("Ошибка в цикле MasteryFarm: "..tostring(err))
            end
        end
    end
end)
