--========================================================
--  Auto Yama / Auto Tushita (GUI + Логи + Server Hop + Holy Torch + Longma)
--========================================================

-----------------------------
-- СЕРВИСЫ
-----------------------------
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

-----------------------------
-- ФЛАГИ / НАСТРОЙКИ
-----------------------------
local AutoTushita      = false
local AutoYama         = false

local CurrentStatus     = "Idle"
local TeleportSpeed     = 300                       -- скорость полёта
local FarmOffset        = CFrame.new(0, 10, -3)     -- позиция над мобом
local TushitaWeaponName = "Godhuman"               -- чем бить Longma (поменяй если хочешь)

local IsTeleporting     = false
local StopTween         = false

local HolyTorchDone     = false   -- маршрут Holy Torch пройден?
-----------------------------
-- ЛОГИ
-----------------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame
local StatusLabel, LogsText
local TushitaButton, YamaButton

local function AddLog(msg)
    local timestamp = os.date("%H:%M:%S")
    local entry = "[" .. timestamp .. "] " .. tostring(msg)
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
    AddLog("Статус: " .. newStatus)
    if StatusLabel then
        StatusLabel.Text = "Статус: " .. newStatus
    end
end

-----------------------------
-- SERVER HOP
-----------------------------
local function Hop()
    local placeId = game.PlaceId
    local jobId   = game.JobId
    local url     = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"

    AddLog("Server Hop: запрашиваю список серверов...")

    local ok, result = pcall(function()
        local body = game:HttpGet(url)
        return HttpService:JSONDecode(body)
    end)

    if not ok then
        AddLog("Server Hop: ошибка запроса: " .. tostring(result))
        return
    end

    local data   = result.data or {}
    local chosen = nil

    for _, server in ipairs(data) do
        if type(server) == "table" and server.id and server.maxPlayers and server.playing then
            if server.id ~= jobId and server.playing < server.maxPlayers then
                chosen = server
                break
            end
        end
    end

    if not chosen then
        AddLog("Server Hop: подходящий сервер не найден (в этой пачке).")
        return
    end

    AddLog(string.format(
        "Server Hop: прыгаю на сервер %s (%d/%d)",
        tostring(chosen.id),
        tonumber(chosen.playing) or -1,
        tonumber(chosen.maxPlayers) or -1
    ))

    TeleportService:TeleportToPlaceInstance(placeId, chosen.id, LocalPlayer)
end

-----------------------------
-- NET-МОДУЛЬ FAST ATTACK
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
-- ХАКИ / ЭКИП
-----------------------------
local function AutoHaki()
    local char = LocalPlayer.Character
    if not char then return end

    if not char:FindFirstChild("HasBuso") then
        local rem = ReplicatedStorage:FindFirstChild("Remotes")
        local r   = rem and rem:FindFirstChild("CommF_")
        if r then
            pcall(function()
                r:InvokeServer("Buso")
            end)
        end
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
    local toolFound = nil

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

-----------------------------
-- ТЕЛЕПОРТ
-----------------------------
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

        task.wait(0.15)
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

-----------------------------
-- ИНВЕНТАРЬ / МЕЧИ
-----------------------------
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

    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    local r   = rem and rem:FindFirstChild("CommF_")
    if r then
        local ok, invData = pcall(function()
            return r:InvokeServer("getInventory")
        end)
        if ok and type(invData) == "table" then
            for _, item in ipairs(invData) do
                local name = item.Name or item.name or tostring(item)
                if name == itemName then
                    return true
                end
            end
        end
    end

    return false
end

local function HasSword(name)
    return HasItemInInventory(name)
end

local function HasHolyTorch()
    return HasItemInInventory("Holy Torch")
end

-----------------------------
-- ПОИСК RIP INDRA
-----------------------------
local function FindRipIndra()
    local enemies = Workspace:FindFirstChild("Enemies")

    if enemies then
        for _, v in ipairs(enemies:GetChildren()) do
            if v:IsA("Model") then
                local nm = tostring(v.Name)
                if string.find(nm, "rip_indra") or string.find(nm, "Rip_Indra") or string.find(nm, "Rip Indra") then
                    local hum = v:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        return v, "Workspace"
                    end
                end
            end
        end
    end

    for _, v in ipairs(ReplicatedStorage:GetChildren()) do
        if v:IsA("Model") then
            local nm = tostring(v.Name)
            if string.find(nm, "rip_indra") or string.find(nm, "Rip_Indra") or string.find(nm, "Rip Indra") then
                return v, "ReplicatedStorage"
            end
        end
    end

    return nil, nil
end

-----------------------------
-- АВТО-КЛИК ПО ДВЕРИ / МЕЧУ (ClickDetector)
-----------------------------
local function ClickNearbyClickDetectors(radius)
    radius = radius or 25
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                local d = (part.Position - hrp.Position).Magnitude
                if d <= radius then
                    count += 1
                    pcall(function()
                        fireclickdetector(obj)
                    end)
                end
            end
        end
    end

    AddLog("Auto Tushita: кликнул ClickDetector'ов рядом: " .. tostring(count))
end

-----------------------------
-- HOLY TORCH МАРШРУТ
-----------------------------
local HolyTorchRoute = {
    CFrame.new(-10752.7695, 412.229523, -9366.36328),
    CFrame.new(-11673.4111, 331.749023, -9474.34668),
    CFrame.new(-12133.3389, 519.47522, -10653.1904),
    CFrame.new(-13336.5,    485.280396, -6983.35254),
    CFrame.new(-13487.4131, 334.84845,  -7926.34863),
}

local function DoHolyTorchRoute()
    if HolyTorchDone then return end

    if not HasHolyTorch() then
        AddLog("Auto Tushita: Holy Torch не найден в инвентаре, маршрут пропускаю.")
        HolyTorchDone = true -- чтобы не спамить
        return
    end

    UpdateStatus("Auto Tushita: маршрут Holy Torch.")
    AddLog("Auto Tushita: запускаю обход факелов с Holy Torch.")
    EquipToolByName("Holy Torch")
    task.wait(0.5)

    for idx, cf in ipairs(HolyTorchRoute) do
        if not AutoTushita then break end
        UpdateStatus("Auto Tushita: Holy Torch → факел #" .. idx)
        SimpleTeleport(cf, "Holy Torch факел #" .. idx)
        task.wait(1.0)

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local t0   = tick()
        while AutoTushita and hrp and (hrp.Position - cf.Position).Magnitude > 15 and tick() - t0 < 8 do
            task.wait(0.3)
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
        end

        task.wait(0.5)
    end

    AddLog("Auto Tushita: маршрут Holy Torch завершён.")
    HolyTorchDone = true
end

-----------------------------
-- БОЙ С LONGMA
-----------------------------
local LongmaSpawnCFrame  = CFrame.new(-10238.875976563, 389.7912902832, -9549.7939453125)
local TushitaDoorCFrame  = CFrame.new(-10171.7051, 406.981995, -9552.31738) -- позиция у двери/меча

local function FightBossOnce(target)
    if not target then return end

    local hum  = target:FindFirstChild("Humanoid")
    local tHRP = target:FindFirstChild("HumanoidRootPart")
    if not hum or not tHRP or hum.Health <= 0 then
        return
    end

    AddLog("Auto Tushita: начинаю бой с Longma.")
    local deadline      = tick() + 180
    local lastPosAdjust = 0
    local lastAttack    = 0

    while AutoTushita
        and target.Parent
        and hum.Health > 0
        and tick() < deadline do

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        tHRP       = target:FindFirstChild("HumanoidRootPart")
        hum        = target:FindFirstChild("Humanoid")

        if not (char and hrp and tHRP and hum) then
            break
        end

        local dist = (tHRP.Position - hrp.Position).Magnitude
        if dist > 2000 then
            SimpleTeleport(tHRP.CFrame * FarmOffset, "Longma (далеко)")
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
            hum.WalkSpeed   = 0
            hum.JumpPower   = 0
        end)

        AutoHaki()
        EquipToolByName(TushitaWeaponName)

        if tick() - lastAttack > 0.15 then
            AttackModule:AttackEnemyModel(target)
            lastAttack = tick()
        end

        RunService.Heartbeat:Wait()
    end

    hum = target:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then
        AddLog("✅ Auto Tushita: Longma убит. Пытаюсь взять Tushita.")
        task.wait(2)
        AddLog("Auto Tushita: телепорт к двери/мечу и автоклик.")
        SimpleTeleport(TushitaDoorCFrame, "Tushita дверь/меч")
        task.wait(1.0)
        ClickNearbyClickDetectors(50)
    else
        AddLog("⚠️ Auto Tushita: бой с Longma завершён/прерван.")
    end
end

-----------------------------
-- ЛОГИКА КВЕСТА TUSHITA
-----------------------------
local function FindLongma()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    for _, mob in ipairs(enemies:GetChildren()) do
        if mob.Name == "Longma" then
            local hum  = mob:FindFirstChild("Humanoid")
            local tHRP = mob:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and tHRP then
                return mob
            end
        end
    end
    return nil
end

local function RunTushitaQuest(ripIndraModel, ripLocation)
    -- 1) Уже есть Tushita?
    if HasSword("Tushita") then
        UpdateStatus("Tushita уже есть, авто-квест выключен.")
        AutoTushita = false
        if TushitaButton then
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        return
    end

    -- 2) Пытаемся найти Longma
    local longma = FindLongma()
    if longma then
        UpdateStatus("Auto Tushita: бой с Longma.")
        FightBossOnce(longma)
        return
    end

    -- 3) Если Longma ещё нет — сначала делаем маршрут Holy Torch (один раз)
    if not HolyTorchDone then
        DoHolyTorchRoute()
        return
    end

    -- 4) После маршрута Holy Torch просто держимся на его спавне и ждём
    UpdateStatus("Auto Tushita: Longma не найден, лечу к его спавну.")
    AddLog("Auto Tushita: телепорт к LongmaSpawnCFrame и ожидание спавна Longma.")
    SimpleTeleport(LongmaSpawnCFrame, "Longma spawn")
end

-----------------------------
-- ЛОГИКА AUTO YAMA (крючок)
-----------------------------
local function RunYamaLogic()
    -- Сюда потом вставишь свою Yama-квест логику (YamaQuest2 / YamaQuest3 / Elite Hunter).
    AddLog("Auto Yama: крючок RunYamaLogic, вставь сюда свою логику квестов Yama.")
end

-----------------------------
-- ОБЩИЙ ВХОД ДЛЯ Auto TUSHITA
-----------------------------
local function RunTushitaLogic()
    local ripIndraModel, ripLocation = FindRipIndra()

    if not ripIndraModel then
        UpdateStatus("Auto Tushita: Rip Indra не найден, делаю server hop...")
        AddLog("Auto Tushita: Rip Indra отсутствует в Workspace/ReplicatedStorage. Переходим на другой сервер.")
        Hop()
        return
    end

    UpdateStatus("Auto Tushita: Rip Indra найден (" .. tostring(ripLocation) .. "), запускаю квест.")
    AddLog("Auto Tushita: найден Rip Indra, выполняю RunTushitaQuest.")
    RunTushitaQuest(ripIndraModel, ripLocation)
end

-----------------------------
-- GUI
-----------------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaTushitaGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 600, 0, 260)  -- ширина 600
    MainFrame.Position = UDim2.new(0, 40, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Title.Text = "Auto Yama / Auto Tushita + Server Hop + Holy Torch + Longma"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 22)
    StatusLabel.Position = UDim2.new(0, 10, 0, 32)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: " .. CurrentStatus
    StatusLabel.Parent = MainFrame

    TushitaButton = Instance.new("TextButton")
    TushitaButton.Size = UDim2.new(0, 180, 0, 32)
    TushitaButton.Position = UDim2.new(0, 10, 0, 65)
    TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TushitaButton.TextColor3 = Color3.new(1,1,1)
    TushitaButton.Font = Enum.Font.SourceSansBold
    TushitaButton.TextSize = 16
    TushitaButton.Text = "Auto Tushita: OFF"
    TushitaButton.Parent = MainFrame

    YamaButton = Instance.new("TextButton")
    YamaButton.Size = UDim2.new(0, 180, 0, 32)
    YamaButton.Position = UDim2.new(0, 210, 0, 65)
    YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    YamaButton.TextColor3 = Color3.new(1,1,1)
    YamaButton.Font = Enum.Font.SourceSansBold
    YamaButton.TextSize = 16
    YamaButton.Text = "Auto Yama: OFF"
    YamaButton.Parent = MainFrame

    TushitaButton.MouseButton1Click:Connect(function()
        AutoTushita  = not AutoTushita
        HolyTorchDone = false  -- при включении AutoTushita маршрут Holy Torch заново

        if AutoTushita then
            AutoYama = false
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

            TushitaButton.Text = "Auto Tushita: ON"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)

            UpdateStatus("Фарм / квест Tushita...")
        else
            TushitaButton.Text = "Auto Tushita: OFF"
            TushitaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            UpdateStatus("Остановлен")
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

            UpdateStatus("Фарм / квест Yama...")
        else
            YamaButton.Text = "Auto Yama: OFF"
            YamaButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            UpdateStatus("Остановлен")
        end
    end)

    -- Логи
    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 140)
    LogsFrame.Position = UDim2.new(0, 10, 0, 110)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
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
end

-----------------------------
-- ЗАПУСК
-----------------------------
CreateGui()
AddLog("Auto Yama / Auto Tushita (Rip Indra + Holy Torch + Longma) загружен.")

task.spawn(function()
    while task.wait(0.5) do
        if AutoTushita then
            pcall(function()
                RunTushitaLogic()
            end)
        elseif AutoYama then
            pcall(function()
                RunYamaLogic()
            end)
        end
    end
end)
