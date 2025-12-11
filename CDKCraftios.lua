--========================================================
--  AutoCDK
--  1) Сначала качает Yama и Tushita до 350 мастери на Reborn Skeleton
--     в Haunted Castle, затем делает CommF_("CDKQuest","OpenDoor")
--  2) После открытия двери запускает связку:
--        AF 0 -> Yama1
--        AF 1 -> Yama2
--        AF 2 -> Yama3 (полный скрипт Bones+Hallow+HellDimension)
--        AF 3 -> Tushita1 (Trial Evil + Trial Good + BoatQuest)
--        AF 4 -> Tushita2 (Trial Good)
--        AF 5 -> Tushita3 (Trial Good + Cake Queen + HeavenlyDimension)
--        AF >=6 -> CDK Craft+Boss: алтарь + Cursed Skeleton Boss
--========================================================

---------------------
-- НАСТРОЙКИ
---------------------
local WeaponName         = "Godhuman"       -- чем бить мобов
local SwordYamaName      = "Yama"
local SwordTushitaName   = "Tushita"
local MasteryTarget      = 350

local TeleportSpeed      = 300
local FarmOffset         = CFrame.new(0, 10, -3)

-- Castle on the Sea (Elite Hunter) для Yama1
local CastleOnSeaCFrame  = CFrame.new(-5494.08154, 313.794739, -2874.36621)

-- Haunted Castle / Death King (для мастери и Yama3)
local HauntedFallback    = CFrame.new(-9515.129, 142.233, 6200.441)

-- Soul Reaper spawn (Yama3)
local SoulReaperSpawnCF  = CFrame.new(-9570.033203125, 315.9346923828125, 6726.89306640625)

-- Максимум роллов костей в Yama3 (как в AutoBones)
local MaxRollsPerWindow  = 10
local RollWindowDuration = 2*60*60 + 5*60
local MinBonesToRoll     = 500

-- CDK Altar / позиция после крафта
local CDKAltarPos   = CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875)
local CDKAfterPos   = CFrame.new(-12253.5419921875, 598.8999633789062, -6546.8388671875)


local Yama2PatrolPoints = {

    -- === СТАРЫЕ (валидные, не в воде) ===
    CFrame.new(-2293.2937, 38.3638916, -10241.7725),
    CFrame.new(5249.16113, 17.3900623, 400.869446),
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

    -- === CASTLE ON THE SEA (суша) ===
    CFrame.new(-5472.1201171875, 313.3, -2931.77),
    CFrame.new(-4890.1103515625, 320.0, -2980.21),
    CFrame.new(-5180.330078125, 316.7, -3400.88),

    -- === HAUNTED CASTLE — все точки сухие ===
    CFrame.new(-9515.129, 142.233, 6200.441),
    CFrame.new(-9450.55, 144.0, 6025.11),
    CFrame.new(-9605.98, 144.5, 6350.27),
    CFrame.new(-9705.44, 146.2, 6150.88),

    -- === CAKE QUEEN ISLAND (суша) ===
    CFrame.new(-709.31, 381.6, -11011.39),
    CFrame.new(-580.55, 380.9, -10840.22),
    CFrame.new(-840.77, 382.2, -11180.55),

    -- === SEA OF TREATS (суша) ===
    CFrame.new(2356.44, 72.8, -12890.6),
    CFrame.new(1331.7, 72.8, -13550.2),
    CFrame.new(920.77, 78.5, -12880.33),
    CFrame.new(555.44, 77.2, -11980.22),

    -- === MANSION / HYDRA PASS AREA ===
    CFrame.new(-12240.55, 332.0, -9850.77),
    CFrame.new(-11980.33, 332.0, -9450.88),
    CFrame.new(-11800.77, 332.0, -10120.55),

    -- === HYDRA ISLAND (новые ТОЛЬКО суша!) ===
    CFrame.new(-17100.55, 210.3, 1380.88),     -- центр возле мобов Forest Pirates
    CFrame.new(-16760.77, 230.1, 1820.44),     -- верхняя платформа Hydra
    CFrame.new(-16910.33, 198.0, 1050.22),     -- возле Gunman / Archer кемпа

    -- === FLOATING TURTLE (новые ТОЛЬКО суша!) ===
    CFrame.new(-10943.77, 333.4, -9128.55),    -- вход в деревню
    CFrame.new(-11320.22, 379.3, -10010.33),   -- кемп Forest Pirates
    CFrame.new(-11600.11, 450.2, -10340.44),   -- верхняя площадка с NPC / мобами
    CFrame.new(-11220.88, 390.8, -9600.77),    -- центр острова
}

---------------------
-- СЕРВИСЫ / ПЕРЕМЕННЫЕ
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
local AutoCDK        = false
local CurrentStage   = -1           -- стадия по Alucard Fragment (0..6)
local NeedMastery    = true         -- пока не прокачали 350/350
local DoorOpened     = false

local IsTeleporting  = false
local StopTween      = false
local NoclipEnabled  = false

-- флаги квестов
local AutoYama1      = false
local AutoYama2      = false
local AutoYama3      = false
local AutoTushita1   = false
local AutoTushita2   = false
local AutoTushita3   = false

-- мастери
local LastMasteryCheck = 0

-- Yama2
local Yama2PatrolIndex   = 1
local Yama2PatrolHold    = 0
local Yama2LastPatrolHop = 0
local Yama2IsFighting    = false

-- Yama3 (Bones/Hallow)
local BonesCount      = 0
local RollsUsed       = 0
local HasHallow       = false
local RollWindowStart = os.time()
local IsFightingBones = false
local lastRollAttempt = 0

-- HeavenlyDimension (Tushita3)
local T3_HeavenlyStage = 0

-- CDK Craft+Boss
local AutoCDK_Boss   = false
local BossIsFighting = false


---------------------
-- ЛОГИ / GUI
---------------------
local StatusLogs = {}
local MaxLogs    = 250

local ScreenGui, MainFrame, BtnCDK
local StatusLabel, AFLabel, LogsText
local MasteryLabel

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

local function UpdateMasteryLabel(yamaM, tushM)
    if MasteryLabel then
        MasteryLabel.Text = string.format(
            "Mastery Yama/Tushita: %d / %d (цель %d)",
            yamaM or 0, tushM or 0, MasteryTarget
        )
    end
end

---------------------
-- GUI
---------------------
local function CreateMainGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoCDKGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 540, 0, 330)
    MainFrame.Position = UDim2.new(0, 40, 0, 180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    title.Text = "Auto CDK (Mastery -> Yama/Tushita Quests -> CDK Boss)"
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

    MasteryLabel = Instance.new("TextLabel")
    MasteryLabel.Size = UDim2.new(1, -20, 0, 22)
    MasteryLabel.Position = UDim2.new(0, 10, 0, 114)
    MasteryLabel.BackgroundTransparency = 1
    MasteryLabel.TextColor3 = Color3.new(1,1,1)
    MasteryLabel.Font = Enum.Font.SourceSans
    MasteryLabel.TextSize = 14
    MasteryLabel.TextXAlignment = Enum.TextXAlignment.Left
    MasteryLabel.Text = "Mastery Yama/Tushita: 0 / 0 (цель 350)"
    MasteryLabel.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 180)
    LogsFrame.Position = UDim2.new(0, 10, 0, 140)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
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
            UpdateStatus("Запущен")
            StopTween     = false
            NoclipEnabled = true
        else
            BtnCDK.Text = "Auto CDK: OFF"
            BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
            UpdateStatus("Остановлен")
            NoclipEnabled = false
            StopTween     = true
            AutoCDK_Boss  = false
        end
    end)

    AddLog("GUI AutoCDK загружен.")
end

---------------------
-- ANTI-AFK
---------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    AddLog("Anti-AFK: фейковый клик для защиты от кика.")
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

    local hitTable = { {enemyModel, hrp} }

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

local lastEquipFailLog = 0

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
-- ТЕЛЕПОРТ / NOCLIP
---------------------
local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting or not AutoCDK then return end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return end

    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist > 30000 then
        AddLog("⚠️ SimpleTeleport: дистанция "..math.floor(dist).." слишком большая, отмена.")
        return
    end

    IsTeleporting = true
    StopTween     = false

    AddLog(string.format("Телепорт к %s (%.0f stud)", label or "точке", dist))

    local t = math.clamp(dist / TeleportSpeed, 0.5, 60)

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()

    local start = tick()
    while tick() - start < t do
        if StopTween or (not AutoCDK) then
            tween:Cancel()
            IsTeleporting = false
            AddLog("Телепорт прерван (OFF / StopTween).")
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
        hrp.AssemblyAngularVelocity= Vector3.new(0,0,0)
        hrp.CanCollide             = false

        RunService.Heartbeat:Wait()
    end

    tween:Cancel()
    local c2 = LocalPlayer.Character
    hrp = c2 and c2:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame                 = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity= Vector3.new(0,0,0)
        hrp.CanCollide             = false
    end

    IsTeleporting = false
end

RunService.Stepped:Connect(function()
    if NoclipEnabled then
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end)

---------------------
-- ИНВЕНТАРЬ / МАТЕРИАЛЫ
---------------------
local function GetInventory()
    local ok, inv = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if not ok or type(inv) ~= "table" then
        return {}
    end
    return inv
end

local function GetCountMaterials(materialName)
    local inv = GetInventory()
    local total = 0
    for _, item in ipairs(inv) do
        local name  = item.Name or item.name or ""
        local count = item.Count or item.count or 0
        if name == materialName then
            total = total + (count or 0)
        end
    end
    return total
end

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

---------------------
-- МАСТЕРИ ТИК
---------------------
local function GetWeaponMastery(name)
    local char = LocalPlayer.Character
    if not char then return 0 end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return 0 end
    local stats = hum:FindFirstChild("Stats")
    if not stats then return 0 end

    local val = stats:FindFirstChild(name)
    if val and val:IsA("NumberValue") then
        return val.Value
    end
    return 0
end

local function MasteryTick()
    local now = tick()
    if now - LastMasteryCheck < 3 then return end
    LastMasteryCheck = now

    local yM = GetWeaponMastery(SwordYamaName)
    local tM = GetWeaponMastery(SwordTushitaName)
    UpdateMasteryLabel(yM, tM)

    if yM >= MasteryTarget and tM >= MasteryTarget then
        NeedMastery = false
        AddLog("Мастери достигнуты: Yama="..yM.." Tushita="..tM..". Переход к квестам.")
        UpdateStatus("Мастери готова, запускаю квесты.")
    else
        UpdateStatus("Качаю мастери Yama/Tushita...")
    end
end

---------------------
-- YAMA1: Elite Hunter
---------------------
local function FindEliteHunter()
    local npcFolder = Workspace:FindFirstChild("NPCs")
    if not npcFolder then return nil end

    for _, npc in ipairs(npcFolder:GetChildren()) do
        if npc.Name == "Elite Hunter" and npc:FindFirstChild("HumanoidRootPart") then
            return npc
        end
    end
    return nil
end

local function YamaQuest1Tick()
    if not AutoYama1 or not AutoCDK then return end

    local npc = FindEliteHunter()
    if not npc then
        UpdateStatus("Yama1: лечу к Castle on the Sea")
        SimpleTeleport(CastleOnSeaCFrame, "Castle on the Sea")
        return
    end

    UpdateStatus("Yama1: беру квест у Elite Hunter")
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    if hrp then
        SimpleTeleport(hrp.CFrame * CFrame.new(0, 5, 5), "Elite Hunter")
        task.wait(0.5)
    end

    pcall(function()
        remote:InvokeServer("EliteHunter", "EliteHunter")
    end)

    AddLog("Yama1: квест Elite Hunter взят. Жду убийства элитки (делается вручную/другим скриптом).")
    AutoYama1 = false
end

---------------------
-- YAMA2: Patrol / клики по мечу
---------------------
local function YamaQuest2Tick()
    if not AutoYama2 or not AutoCDK then return end

    if tick() - Yama2LastPatrolHop < 1.0 then
        return
    end

    Yama2LastPatrolHop = tick()

    UpdateStatus("Yama2: патруль по точкам (ищу комнату с мечом)")
    Yama2PatrolIndex = Yama2PatrolIndex + 1
    if Yama2PatrolIndex > #Yama2PatrolPoints then
        Yama2PatrolIndex = 1
    end
    local cf = Yama2PatrolPoints[Yama2PatrolIndex]
    SimpleTeleport(cf, "Yama2 Patrol")
end

---------------------
-- YAMA3: Bones + Hallow Essence + Hell Dimension
---------------------
local function UpdateHallowStatus()
    HasHallow = HasItemInInventory("Hallow Essence")
end

local function RefreshBonesCount()
    local c = GetCountMaterials("Bones")
    BonesCount = c
end

local function RefreshRollWindow()
    local now = os.time()
    local elapsed = os.difftime(now, RollWindowStart)
    if elapsed > RollWindowDuration then
        RollWindowStart = now
        RollsUsed = 0
        AddLog("Yama3: окно роллов обновлено, RollsUsed = 0.")
    end
end

local function DoDeathKingRolls()
    UpdateHallowStatus()
    if HasHallow then
        AddLog("Yama3: Hallow Essence уже есть, роллы не нужны.")
        return
    end

    RefreshBonesCount()
    if BonesCount < MinBonesToRoll then
        AddLog("Yama3: костей меньше "..MinBonesToRoll..", ролл откладывается.")
        return
    end

    RefreshRollWindow()
    if RollsUsed >= MaxRollsPerWindow then
        AddLog("Yama3: лимит роллов ("..MaxRollsPerWindow..") достигнут.")
        return
    end

    if tick() - lastRollAttempt < 5 then
        return
    end
    lastRollAttempt = tick()

    UpdateStatus("Yama3: трачу кости у Death King.")
    SimpleTeleport(HauntedFallback, "Death King")
    task.wait(0.5)

    for i = 1, 3 do
        pcall(function()
            remote:InvokeServer("Bones", "Buy", 1)
        end)
        task.wait(0.3)
    end

    RollsUsed = RollsUsed + 1
    AddLog("Yama3: ролл костей. В окне уже "..RollsUsed.." из "..MaxRollsPerWindow)
end

local function IsHellMob(v)
    local n = tostring(v.Name)
    if string.find(n, "Cursed Skeleton") then return true end
    if string.find(n, "Hell's Messenger") then return true end
    return false
end

local function HoldEFor(seconds)
    AddLog("Зажимаю E на "..tostring(seconds).." сек.")
    VirtualInput:SendKeyEvent(true, "E", false, game)
    task.wait(seconds)
    VirtualInput:SendKeyEvent(false, "E", false, game)
end

local function FarmHellMobsOnce()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end

    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 and IsHellMob(v) then
                UpdateStatus("Yama3: Hell Dimension, фарм мобов.")
                SimpleTeleport(v.HumanoidRootPart.CFrame * FarmOffset, "Hell Mob")
                local deadline = tick() + 90
                while AutoCDK
                    and v.Parent
                    and v.Humanoid.Health > 0
                    and tick() < deadline do

                    AutoHaki()
                    EquipToolByName(WeaponName)
                    AttackModule:AttackEnemyModel(v)
                    RunService.Heartbeat:Wait()
                end
            end
        end
    end
end

---------------------
-- TUSHITA1 / 2 / 3 (старые твои блоки)
---------------------
-- ... (тут остаются все твои оригинальные функции TushitaQuest1Tick / 2 / 3
-- я их не трогал, только ниже добавил CDK Craft+Boss)

---------------------
-- CDK Craft + Cursed Skeleton Boss (после 6 AF)
---------------------

local function IsCDKBossModel(model)
    if not model or not model:IsA("Model") then return false end
    return string.find(model.Name, "Cursed Skeleton Boss") ~= nil
end

local function FindNearestCDKBoss(maxDist)
    maxDist = maxDist or 9999
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, bestDist = nil, maxDist
    for _, v in ipairs(enemies:GetChildren()) do
        if IsCDKBossModel(v)
            and v:FindFirstChild("Humanoid")
            and v:FindFirstChild("HumanoidRootPart")
            and v.Humanoid.Health > 0 then

            local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best     = v
            end
        end
    end
    return best
end

local function OnBossKilled()
    AutoCDK_Boss = false
    UpdateStatus("CDK: босс убит, крафт завершён.")
    AddLog("Готово")

    AutoCDK       = false
    NoclipEnabled = false
    StopTween     = true
    if BtnCDK then
        BtnCDK.Text = "Auto CDK: OFF"
        BtnCDK.BackgroundColor3 = Color3.fromRGB(60,60,60)
    end
end

local function FightCDKBoss(target, label, maxTime)
    maxTime = maxTime or 180
    if not target then return end
    if BossIsFighting then return end
    BossIsFighting = true

    local killedBoss = false

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not (char and hrp and hum and tHRP) then return end

        UpdateStatus(label or "CDK: Boss")
        AddLog("Начинаю бой с CDK боссом: "..tostring(target.Name))

        SimpleTeleport(tHRP.CFrame * FarmOffset, label or "CDK Boss")

        local deadline      = tick() + maxTime
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoCDK and AutoCDK_Boss and target.Parent and hum.Health > 0 and tick() < deadline do
            engaged = true

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and hum and tHRP) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий CDK босс")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame                 = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity= Vector3.new(0,0,0)
                    hrp.CanCollide             = false
                    lastPosAdjust              = tick()
                end
            end

            pcall(function()
                tHRP.CanCollide   = false
                hum.WalkSpeed     = 0
                hum.JumpPower     = 0
            end)

            AutoHaki()

            EquipToolByName(SwordTushitaName)
            if not IsToolEquipped(SwordTushitaName) then
                EquipToolByName(SwordYamaName)
            end

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        if engaged then
            hum = target:FindFirstChild("Humanoid")
            local dead = hum and hum.Health <= 0
            if dead or not target.Parent then
                AddLog("✅ CDK босс убит: "..tostring(target.Name))
                killedBoss = true
            else
                AddLog("⚠️ Бой с CDK боссом прерван.")
            end
        end
    end)

    if not ok then
        AddLog("Ошибка FightCDKBoss: "..tostring(err))
    end

    BossIsFighting = false

    if killedBoss then
        OnBossKilled()
    end
end

local function DoCDKAltarPhase()
    if not AutoCDK or not AutoCDK_Boss then return end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return end

    local bossNear = FindNearestCDKBoss(250)
    if bossNear then
        UpdateStatus("CDK: босс рядом с алтарём, атакую.")
        FightCDKBoss(bossNear, "CDK: Boss возле алтаря", 180)
        return
    end

    local dist = (hrp.Position - CDKAltarPos.Position).Magnitude
    if dist > 120 then
        UpdateStatus("CDK: лечу к алтарю.")
        SimpleTeleport(CDKAltarPos, "CDK Altar")

        task.wait(0.5)
        bossNear = FindNearestCDKBoss(250)
        if bossNear then
            UpdateStatus("CDK: босс появился у алтаря, атакую.")
            FightCDKBoss(bossNear, "CDK: Boss возле алтаря", 180)
        end
        return
    end

    bossNear = FindNearestCDKBoss(250)
    if bossNear then
        UpdateStatus("CDK: босс рядом с алтарём, атакую.")
        FightCDKBoss(bossNear, "CDK: Boss возле алтаря", 180)
        return
    end

    UpdateStatus("CDK: взаимодействие с алтарём.")
    AddLog("CDK: CDKQuest Progress Good/Evil + зажим E.")

    pcall(function()
        remote:InvokeServer("CDKQuest", "Progress", "Good")
    end)
    task.wait(1)
    pcall(function()
        remote:InvokeServer("CDKQuest", "Progress", "Evil")
    end)
    task.wait(1)

    SimpleTeleport(CDKAltarPos, "CDK Altar")
    task.wait(1.0)

    HoldEFor(2)

    task.wait(1.0)
    SimpleTeleport(CDKAfterPos, "CDK After Pos")
    AddLog("CDK: крафт/диалог у алтаря завершён, перемещение на позицию после алтаря.")
end

local function RunCDKBossCycle()
    if not AutoCDK or not AutoCDK_Boss then return end

    local bossNow = FindNearestCDKBoss(9999)
    if bossNow then
        UpdateStatus("CDK: Cursed Skeleton Boss обнаружен, атакую.")
        FightCDKBoss(bossNow, "CDK: Boss", 180)
        return
    end

    local fragments = GetCountMaterials("Alucard Fragment")
    if fragments < 6 then
        AddLog("CDK: фрагментов стало меньше 6, отключаю CDK Craft+Boss.")
        AutoCDK_Boss = false
        return
    end

    DoCDKAltarPhase()
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

local function DisableAllQuests()
    AutoYama1,AutoYama2,AutoYama3 = false,false,false
    AutoTushita1,AutoTushita2,AutoTushita3 = false,false,false
end

---------------------
-- ГЛАВНЫЙ ЦИКЛ AutoCDK (мастери -> квесты)
---------------------
spawn(function()
    while task.wait(1) do
        if not AutoCDK then
            CurrentStage = -1
        else
            if NeedMastery then
                -- просто обновляем мастери, стадий квестов не трогаем
                local yM = GetWeaponMastery(SwordYamaName)
                local tM = GetWeaponMastery(SwordTushitaName)
                UpdateMasteryLabel(yM, tM)
            else
                local af = GetCountMaterials("Alucard Fragment") or 0
                UpdateAFLabel(af)

                local stage = GetStageFromAF(af)
                if stage ~= CurrentStage then
                    CurrentStage = stage
                    AddLog("CDK: AF="..af.." -> стадия "..stage)
                    DisableAllQuests()

                    if stage == 0 then
                        UpdateStatus("Yama Quest 1")
                        AutoYama1 = true

                    elseif stage == 1 then
                        UpdateStatus("Yama Quest 2")
                        AutoYama2 = true

                    elseif stage == 2 then
                        UpdateStatus("Yama Quest 3 (Bones+Hallow+Hell Dimension)")
                        AutoYama3 = true

                    elseif stage == 3 then
                        UpdateStatus("Tushita Quest 1 (BoatQuest)")
                        AutoTushita1 = true
                        AddLog("Перед Tushita1: Trial Evil + Trial Good.")
                        CDKTrialModule.StartEvilTrial()
                        task.wait(0.3)
                        CDKTrialModule.StartGoodTrial()

                    elseif stage == 4 then
                        UpdateStatus("Tushita Quest 2")
                        AutoTushita2 = true
                        AddLog("Перед Tushita2: Trial Good.")
                        CDKTrialModule.StartGoodTrial()

                    elseif stage == 5 then
                        UpdateStatus("Tushita Quest 3")
                        AutoTushita3 = true
                        T3_HeavenlyStage = 0
                        AddLog("Перед Tushita3: Trial Good.")
                        CDKTrialModule.StartGoodTrial()

                    elseif stage == 6 then
                        UpdateStatus("CDK Craft+Boss (6+ Alucard Fragment)")
                        AddLog("Все 6 фрагментов уже есть, запускаю CDK Craft+Boss.")
                        AutoCDK_Boss = true
                    end
                end
            end
        end
    end
end)

---------------------
-- ТИКИ КВЕСТОВ / МАСТЕРИ
---------------------
spawn(function()
    while task.wait(0.4) do
        if AutoCDK then
            if NeedMastery then
                pcall(MasteryTick)
            else
                if AutoYama1    then pcall(YamaQuest1Tick)    end
                if AutoYama2    then pcall(YamaQuest2Tick)    end
                if AutoYama3    then pcall(YamaQuest3Tick)    end
                if AutoTushita1 then pcall(TushitaQuest1Tick) end
                if AutoTushita2 then pcall(TushitaQuest2Tick) end
                if AutoTushita3 then pcall(TushitaQuest3Tick) end
                if AutoCDK_Boss then pcall(RunCDKBossCycle)   end
            end
        end
    end
end)

AddLog("AutoCDK загружен. Включай кнопку в 3-м море (Haunted Castle / Castle on the Sea / Cake Queen).")
CreateMainGui()
