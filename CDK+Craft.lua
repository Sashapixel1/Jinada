--====================================================
--   AUTO CDK  — VARIANT A (ОРУЖИЕ: TUSHITA / YAMA)
--====================================================

------------------------------------------------------
-- НАСТРОЙКИ
------------------------------------------------------
local SwordTushita = "Tushita"
local SwordYama    = "Yama"

local TeleportSpeed = 300
local FarmOffset    = CFrame.new(0, 10, -3)

local CDKAltarPos = CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875)
local CDKAfterPos = CFrame.new(-12253.54, 598.9, -6546.83)

------------------------------------------------------
-- СЕРВИСЫ
------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local Vim               = game:GetService("VirtualInputManager")

local LocalPlayer       = Players.LocalPlayer
local remote            = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

------------------------------------------------------
-- ПЕРЕМЕННЫЕ
------------------------------------------------------
local AutoCDK       = false
local IsTeleporting = false
local StopTween     = false
local IsFighting    = false

local ScreenGui, MainFrame, ToggleButton
local StatusLabel, LogsText

------------------------------------------------------
-- ЛОГИ
------------------------------------------------------
local StatusLogs = {}
local MaxLogs    = 200
local lastLogMsg = nil

local function AddLog(msg)
    if msg == lastLogMsg then return end
    lastLogMsg = msg

    msg = "["..os.date("%H:%M:%S").."] "..msg
    table.insert(StatusLogs, 1, msg)

    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end

    if LogsText then
        LogsText.Text = table.concat(StatusLogs, "\n")
    end
end

local function UpdateStatus(text)
    if StatusLabel then
        StatusLabel.Text = "Статус: " .. text
    end
    AddLog("Статус: " .. text)
end

------------------------------------------------------
-- STOP
------------------------------------------------------
local function StopCDK()
    AutoCDK   = false
    StopTween = true
    AddLog("CDK! Поздравляю — босс убит, крафт завершён.")
    UpdateStatus("CDK завершён.")

    if ToggleButton then
        ToggleButton.Text = "Auto CDK: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    end
end

------------------------------------------------------
-- ANTI-AFK
------------------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

------------------------------------------------------
-- NET / АТАКИ
------------------------------------------------------
local modules        = ReplicatedStorage:WaitForChild("Modules")
local net            = modules:WaitForChild("Net")
local RegisterAttack = net:WaitForChild("RE"):WaitForChild("RegisterAttack")
local RegisterHit    = net:WaitForChild("RE"):WaitForChild("RegisterHit")

local AttackModule = {}

function AttackModule:AttackEnemy(enemy)
    if not enemy then return end
    local hrp = enemy:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hitTable = {{enemy, hrp}}

    RegisterAttack:FireServer(0)
    RegisterAttack:FireServer(1)
    RegisterHit:FireServer(hrp, hitTable)
end

------------------------------------------------------
-- ХАКИ
------------------------------------------------------
local function AutoHaki()
    local char = LocalPlayer.Character
    if not char then return end
    if not char:FindFirstChild("HasBuso") then
        pcall(function()
            remote:InvokeServer("Buso")
        end)
    end
end

------------------------------------------------------
-- ВЫБОР ОРУЖИЯ (TUSHITA / YAMA)
------------------------------------------------------
local lastEquipFail = 0

local function HasToolEquipped(name)
    local char = LocalPlayer.Character
    if not char then return false end

    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v.Name == name then
            return true
        end
    end
    return false
end

local function EquipSword()
    local char = LocalPlayer.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- приоритет: Tushita → Yama
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    local function find(name)
        if backpack then
            for _, v in ipairs(backpack:GetChildren()) do
                if v:IsA("Tool") and v.Name == name then return v end
            end
        end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v.Name == name then return v end
        end
        return nil
    end

    local tool =
        find(SwordTushita)
        or find(SwordYama)

    if not tool then
        if tick() - lastEquipFail > 3 then
            AddLog("⚠️ Меч не найден: Tushita/Yama")
            lastEquipFail = tick()
        end
        return
    end

    if HasToolEquipped(tool.Name) then return end

    hum:UnequipTools()
    hum:EquipTool(tool)
    AddLog("⚔️ Экипирован меч: " .. tool.Name)
end

------------------------------------------------------
-- ТЕЛЕПОРТ
------------------------------------------------------
local LastGoodPos = nil
local TeleportLocked = false

local function SimpleTeleport(target, label)
    if TeleportLocked or IsTeleporting or not AutoCDK then return end
    IsTeleporting = true
    StopTween     = false

    local char = LocalPlayer.Character
    if not char then IsTeleporting=false return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then IsTeleporting=false return end

    LastGoodPos = hrp.Position

    local dist = (hrp.Position - target.Position).Magnitude
    local t    = math.clamp(dist / TeleportSpeed, 0.5, 60)

    AddLog(string.format("Телепорт к %s (%.0f stud)", label or "точке", dist))

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = target}
    )
    tween:Play()

    local start = tick()
    local lastCheck = tick()

    while tick() - start < t do
        if StopTween or not AutoCDK then
            tween:Cancel()
            IsTeleporting = false
            return
        end

        local c = LocalPlayer.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hrp then
            tween:Cancel()
            IsTeleporting = false
            return
        end

        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide = false

        -- анти-откид
        if tick() - lastCheck > 0.15 then
            lastCheck = tick()

            local delta = (hrp.Position - LastGoodPos).Magnitude
            if delta > 900 then
                tween:Cancel()
                AddLog("⚠️ Обнаружен откид "..math.floor(delta).." — перезапуск ТП")

                TeleportLocked = true
                IsTeleporting  = false

                task.delay(2, function()
                    TeleportLocked=false
                    SimpleTeleport(target, (label or "").." retry")
                end)
                return
            end

            LastGoodPos = hrp.Position
        end

        task.wait(0.05)
    end

    tween:Cancel()
    hrp.CFrame = target
    IsTeleporting = false
end


------------------------------------------------------
-- СБРОС ПОСЛЕ СМЕРТИ
------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = false
    IsFighting    = false
    AddLog("Персонаж возрождён, продолжаю CDK.")
    char:WaitForChild("HumanoidRootPart", 10)
end)

------------------------------------------------------
-- ИНВЕНТАРЬ
------------------------------------------------------
local function GetMaterialCount(name)
    local ok, inv = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if not ok or type(inv) ~= "table" then return 0 end

    for _, item in ipairs(inv) do
        if (item.Name or item.name) == name then
            return item.Count or item.count or 0
        end
    end
    return 0
end

------------------------------------------------------
-- ПОИСК МОНСТРОВ
------------------------------------------------------
local function GetEnemies()
    return Workspace:FindFirstChild("Enemies")
end

local function IsBoss(model)
    if not model then return false end
    return string.find(model.Name, "Cursed Skeleton Boss") ~= nil
end

local function IsCDKMob(model)
    if not model then return false end
    local name = model.Name
    return string.find(name, "Cursed Skeleton") ~= nil
end

------------------------------------------------------
-- НАЙТИ БЛИЖАЙШЕГО БОССА
------------------------------------------------------
local function FindBoss(maxDist)
    maxDist = maxDist or 9999

    local enemies = GetEnemies()
    if not enemies then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, bestDist = nil, maxDist

    for _, v in ipairs(enemies:GetChildren()) do
        if IsBoss(v)
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

------------------------------------------------------
-- ЛИСТ ВСЕХ ЦЕЛЕЙ (босс + скелеты)
------------------------------------------------------
local function GetCDKTargets()
    local enemies = GetEnemies()
    if not enemies then return {} end

    local list = {}
    for _, v in ipairs(enemies:GetChildren()) do
        if IsCDKMob(v)
            and v:FindFirstChild("Humanoid")
            and v:FindFirstChild("HumanoidRootPart")
            and v.Humanoid.Health > 0 then
            table.insert(list, v)
        end
    end
    return list
end

------------------------------------------------------
-- БОЙ
------------------------------------------------------
local function Fight(target, label, maxTime)
    maxTime = maxTime or 90
    if not target then return end
    if IsFighting then return end
    IsFighting = true
    local killedBoss = false

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")

        if not (char and hrp and hum and tHRP) then return end

        UpdateStatus(label or "Бой")
        SimpleTeleport(tHRP.CFrame * FarmOffset, "к цели")

        local deadline      = tick() + maxTime
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoCDK
            and target.Parent
            and hum.Health > 0
            and tick() < deadline do

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and hum and tHRP) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "re-TP")
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
            EquipSword()

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemy(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        if hum.Health <= 0 or not target.Parent then
            AddLog("Убит: " .. target.Name)
            if IsBoss(target) then killedBoss = true end
        end
    end)

    if not ok then
        AddLog("Ошибка Fight: "..tostring(err))
    end

    IsFighting = false

    if killedBoss then StopCDK() end
end

------------------------------------------------------
-- КОНЕЦ ЧАСТИ 1
------------------------------------------------------
------------------------------------------------
-- ТЕЛЕПОРТ (с анти-откидыванием)
------------------------------------------------
local TeleportLocked   = false
local LastGoodPosition = nil

local function SimpleTeleport(targetCFrame, label)
    if TeleportLocked or IsTeleporting or not AutoCDK then return end
    IsTeleporting = true
    StopTween     = false

    local char = LocalPlayer.Character
    if not char then IsTeleporting=false return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then IsTeleporting=false return end

    LastGoodPosition = hrp.Position

    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    local t    = math.clamp(dist / TeleportSpeed, 0.5, 60)

    AddLog(string.format("Телепорт к %s (%.0f stud, t=%.1f)", label or "точке", dist, t))

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()

    local startTick = tick()
    local lastCheck = tick()

    while tick() - startTick < t do
        if StopTween or not AutoCDK then
            tween:Cancel()
            IsTeleporting = false
            AddLog("Телепорт прерван (StopTween/Off).")
            return
        end

        local c = LocalPlayer.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not c or not hrp then tween:Cancel() IsTeleporting=false return end

        hrp.AssemblyLinearVelocity  = Vector3.new()
        hrp.AssemblyAngularVelocity = Vector3.new()
        hrp.CanCollide = false

        -- ===== АНТИ-ОТКИДЫВАНИЕ =====
        if tick() - lastCheck > 0.15 then
            lastCheck = tick()
            local cur = hrp.Position
            if LastGoodPosition then
                local delta = (cur - LastGoodPosition).Magnitude
                if delta > 1000 then
                    tween:Cancel()
                    AddLog("⚠️ Обнаружен откид на " .. math.floor(delta) .. "! Перезапуск ТП...")

                    TeleportLocked = true
                    IsTeleporting = false

                    task.delay(2, function()
                        TeleportLocked = false
                        SimpleTeleport(targetCFrame, (label or "точка") .. " (retry)")
                    end)
                    return
                end
            end
            LastGoodPosition = cur
        end
        -- ============================

        task.wait(0.05)
    end

    tween:Cancel()
    local c2 = LocalPlayer.Character
    hrp = c2 and c2:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.new()
        hrp.AssemblyAngularVelocity = Vector3.new()
        hrp.CanCollide = false
    end

    IsTeleporting = false
end

------------------------------------------------
-- СБРОС ПОСЛЕ СМЕРТИ
------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = false
    IsFighting    = false
    AddLog("Персонаж возрождён для CDK…")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, продолжаю.")
    UpdateStatus("Ожидание / CDK Craft+Boss")
end)

------------------------------------------------
-- МАТЕРИАЛЫ
------------------------------------------------
local function GetMaterialCount(materialName)
    local ok, inv = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if not ok or type(inv) ~= "table" then return 0 end

    for _, item in ipairs(inv) do
        if item.Name == materialName then
            return item.Count or 0
        end
    end
    return 0
end

------------------------------------------------
-- ПОИСК МОНСТРОВ
------------------------------------------------
local function GetEnemies()
    return Workspace:FindFirstChild("Enemies")
end

local function IsBoss(model)
    return model and string.find(model.Name, "Cursed Skeleton Boss")
end

local function IsCDKMob(model)
    if not model then return false end
    local n = model.Name
    return string.find(n,"Cursed Skeleton") ~= nil
end

local function FindNearestBoss(maxDist)
    local enemies = GetEnemies()
    if not enemies then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local best, bestD = nil, maxDist or 9999

    for _,m in ipairs(enemies:GetChildren()) do
        if IsBoss(m) and m:FindFirstChild("HumanoidRootPart") then
            local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < bestD then bestD = d best = m end
        end
    end
    return best
end

local function ListCDKTargets()
    local enemies = GetEnemies()
    if not enemies then return {} end

    local list = {}
    for _,m in ipairs(enemies:GetChildren()) do
        if IsCDKMob(m) and m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Humanoid") then
            if m.Humanoid.Health > 0 then table.insert(list,m) end
        end
    end
    return list
end

------------------------------------------------
-- БОЙ
------------------------------------------------
local function FightMob(target, label, maxTime)
    if IsFighting or not target then return end
    IsFighting = true
    local killedBoss = false

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not (char and hrp and hum and tHRP) then return end

        UpdateStatus(label or "Бой")
        AddLog("Начинаю бой: "..target.Name)
        SimpleTeleport(tHRP.CFrame * FarmOffset, label or "цель")

        local deadline = tick() + (maxTime or 90)
        local lastAdj,lastAtk = 0,0

        while AutoCDK and target.Parent and hum.Health>0 and tick()<deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and hum and tHRP) then break end

            local d = (tHRP.Position - hrp.Position).Magnitude
            if d > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий моб")
            else
                if tick() - lastAdj > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity = Vector3.new()
                    hrp.AssemblyAngularVelocity = Vector3.new()
                    hrp.CanCollide = false
                    lastAdj = tick()
                end
            end

            hum.WalkSpeed = 0
            hum.JumpPower = 0
            pcall(function()
                if not tHRP:FindFirstChild("BodyVelocity") then
                    local bv = Instance.new("BodyVelocity", tHRP)
                    bv.MaxForce = Vector3.new(9e9,9e9,9e9)
                    bv.Velocity = Vector3.new()
                end
            end)

            AutoHaki()
            EquipBestSword()

            if tick() - lastAtk > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAtk = tick()
            end

            RunService.Heartbeat:Wait()
        end

        local dead = hum and hum.Health <= 0
        if dead or not target.Parent then
            AddLog("Убит: "..target.Name)
            if IsBoss(target) then killedBoss=true end
        end
    end)

    if not ok then AddLog("Ошибка FightMob: "..tostring(err)) end

    IsFighting = false
    if killedBoss then StopCDKWithCongrats() end
end

------------------------------------------------
-- ВЗАИМОДЕЙСТВИЕ С АЛТАРЁМ
------------------------------------------------
local function HoldEFor(sec)
    Vim:SendKeyEvent(true,"E",false,game)
    task.wait(sec)
    Vim:SendKeyEvent(false,"E",false,game)
end

local function DoCDKAltarPhase()
    if not AutoCDK then return end

    local bossNear = FindNearestBoss(250)
    if bossNear then
        UpdateStatus("Boss у алтаря → бой")
        FightMob(bossNear,"Boss near altar",180)
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dist = (hrp.Position - CDKAltarPos.Position).Magnitude
    if dist > 150 then
        UpdateStatus("Лечу к алтарю")
        SimpleTeleport(CDKAltarPos,"CDK Altar")
        task.wait(0.5)
        bossNear = FindNearestBoss(250)
        if bossNear then
            FightMob(bossNear,"Boss near altar",180)
        end
        return
    end

    AddLog("Взаимодействие с алтарём…")
    UpdateStatus("Активирую прогресс CDK")

    pcall(function() remote:InvokeServer("CDKQuest","Progress","Good") end)
    task.wait(1)
    pcall(function() remote:InvokeServer("CDKQuest","Progress","Evil") end)

    task.wait(1)
    SimpleTeleport(CDKAltarPos,"CDK Altar")

    HoldEFor(2)
    task.wait(1)

    SimpleTeleport(CDKAfterPos,"After Altar")
    AddLog("Готово → позиция после алтаря")
end

------------------------------------------------
-- ОСНОВНОЙ CDK CYCLE
------------------------------------------------
local function RunCDKCycle()
    if not AutoCDK then return end

    local boss = FindNearestBoss(9999)
    if boss then
        UpdateStatus("Boss обнаружен → бой")
        FightMob(boss,"CDK: Boss",180)
        return
    end

    local frag = GetMaterialCount("Alucard Fragment")
    if frag < 6 then
        UpdateStatus("Жду 6 фрагментов (есть: "..frag..")")
        return
    end

    DoCDKAltarPhase()
end

------------------------------------------------
-- GUI
------------------------------------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CDK_CraftBoss_Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0,520,0,260)
    MainFrame.Position = UDim2.new(0,40,0,160)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,24)
    title.Text = "CDK Craft+Boss (Auto)"
    title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    title.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0,260,0,30)
    ToggleButton.Position = UDim2.new(0,10,0,30)
    ToggleButton.Text = "CDK Craft+Boss: OFF"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1,-20,0,22)
    StatusLabel.Position = UDim.new(0,10), UDim.new(0,65)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Text = "Статус: Остановлен"
    StatusLabel.Parent = MainFrame

    local LogsFrame = Instance.new("ScrollingFrame")
    LogsFrame.Size = UDim2.new(1,-20,0,150)
    LogsFrame.Position = UDim2.new(0,10,0,95)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
    LogsFrame.ScrollBarThickness = 4
    LogsFrame.Parent = MainFrame

    LogsText = Instance.new("TextLabel")
    LogsText.Size = UDim2.new(1,-10,1,-10)
    LogsText.Position = UDim2.new(0,5,0,5)
    LogsText.BackgroundTransparency = 1
    LogsText.TextColor3 = Color3.new(1,1,1)
    LogsText.Font = Enum.Font.Code
    LogsText.TextSize = 12
    LogsText.TextXAlignment = Enum.TextXAlignment.Left
    LogsText.TextYAlignment = Enum.TextYAlignment.Top
    LogsText.Parent = LogsFrame

    ToggleButton.MouseButton1Click:Connect(function()
        AutoCDK = not AutoCDK
        StopTween = false

        if AutoCDK then
            ToggleButton.Text = "CDK Craft+Boss: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0,120,0)
            UpdateStatus("Запущен")
        else
            ToggleButton.Text = "CDK Craft+Boss: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            UpdateStatus("Остановлен")
        end
    end)

    AddLog("GUI загружен.")
end

------------------------------------------------
-- LOOP
------------------------------------------------
spawn(function()
    while task.wait(0.4) do
        if AutoCDK then
            local ok, err = pcall(RunCDKCycle)
            if not ok then AddLog("Ошибка цикла: "..tostring(err)) end
        end
    end
end)

------------------------------------------------
-- СТАРТ
------------------------------------------------
CreateGui()
AddLog("CDK Craft+Boss загружен.")
