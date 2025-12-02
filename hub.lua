-- Mini CDK Checker & Teleporter Script
-- Version 1.0

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "CDK Checker & Teleporter",
    LoadingTitle = "Cursed Katana Tools",
    LoadingSubtitle = "by NoxHub",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NoxHub",
        FileName = "CDKChecker"
    },
    Discord = {
        Enabled = false,
        Invite = "noxhub",
        RememberJoins = true
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local StatusTab = Window:CreateTab("Status", 4483362458)

-- Variables
local TeleportSpeed = 180
local TweenService = game:GetService("TweenService")

-- Locations
local Locations = {
    Tushita = CFrame.new(-10238.8759765625, 389.7912902832, -9549.7939453125),
    Yama = CFrame.new(-9489.2168, 142.130066, 5567.14697),
    CDKAltar = CFrame.new(-9717.33203125, 375.1759338378906, -10160.1455078125)
}

-- Status Logs
local StatusLogs = {}
local MaxLogs = 20

-- Функции для работы с инвентарем (как в примере)
function GetInventoryData()
    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
    local inventoryData = {}
    
    local success, result = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    
    if success and type(result) == "table" then
        for _, item in ipairs(result) do
            local itemName = item.Name or tostring(item)
            inventoryData[itemName] = true
        end
    end
    
    return inventoryData
end

function GetItemFromStorage(itemName)
    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
    local success = pcall(function()
        return remote:InvokeServer("LoadItem", itemName)
    end)
    return success
end

-- Правильная проверка наличия предметов
function HasItemInInventory(itemName)
    -- Проверяем в бэкпаке
    if game.Players.LocalPlayer.Backpack:FindFirstChild(itemName) then
        return true
    end
    
    -- Проверяем в руках
    if game.Players.LocalPlayer.Character:FindFirstChild(itemName) then
        return true
    end
    
    -- Проверяем через getInventory (как в примере)
    local inventory = GetInventoryData()
    if inventory[itemName] then
        return true
    end
    
    return false
end

function HasTushita()
    return HasItemInInventory("Tushita")
end

function HasYama()
    return HasItemInInventory("Yama")
end

function HasCDK()
    return HasItemInInventory("Cursed Dual Katana") or HasItemInInventory("Cursed Dual Katana [CDK]")
end

-- Функция для проверки прогресса CDKQuest
function GetCDKProgress()
    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
    local success, result = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress")
    end)
    
    if success and type(result) == "table" then
        return result
    end
    return nil
end

-- Логирование
function AddLog(message)
    local timestamp = os.date("%H:%M:%S")
    local logEntry = "["..timestamp.."] "..message
    table.insert(StatusLogs, 1, logEntry)
    
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
    
    UpdateLogDisplay()
end

-- Простой телепорт
local function SimpleTeleport(targetCFrame)
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        AddLog("Ошибка: Персонаж не найден")
        return false
    end
    
    local hrp = character.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    
    AddLog(string.format("Телепорт на %.0f юнитов", distance))
    
    -- Для больших дистанций используем промежуточные точки
    if distance > 1000 then
        AddLog("Большая дистанция, использую промежуточные точки")
        
        -- Используем requestEntrance для дальних локаций
        if targetCFrame.Position.Z < -9000 then -- Tushita area
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("requestEntrance", 
                Vector3.new(-10238.8759765625, 389.7912902832, -9549.7939453125))
        elseif targetCFrame.Position.Z > 5000 then -- Yama area  
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("requestEntrance",
                Vector3.new(-9489.2168, 142.130066, 5567.14697))
        end
        
        wait(2)
        distance = (hrp.Position - targetCFrame.Position).Magnitude
    end
    
    -- Плавный телепорт
    local teleportTime = distance / TeleportSpeed
    if teleportTime < 1 then teleportTime = 1 end
    if teleportTime > 5 then teleportTime = 5 end
    
    local tween = TweenService:Create(hrp,
        TweenInfo.new(teleportTime, Enum.EasingStyle.Quad),
        {CFrame = targetCFrame}
    )
    
    tween:Play()
    
    local startTime = tick()
    while tick() - startTime < teleportTime do
        wait()
    end
    
    tween:Cancel()
    hrp.CFrame = targetCFrame
    
    AddLog("Телепорт завершен")
    return true
end

-- Создаем UI элементы

local SpeedSlider = MainTab:CreateSlider({
    Name = "Скорость телепорта",
    Range = {100, 250},
    Increment = 10,
    Suffix = "ед/сек",
    CurrentValue = TeleportSpeed,
    Flag = "TeleportSpeed",
    Callback = function(Value)
        TeleportSpeed = Value
        AddLog("Скорость телепорта: " .. Value)
    end,
})

-- Секция проверки инвентаря
MainTab:CreateSection("Проверка CDK")

-- Функция для проверки CDK
local function CheckCDKStatus()
    AddLog("=== Проверка CDK ===")
    
    -- Проверяем через инвентарь
    local hasTushitaInv = HasTushita()
    local hasYamaInv = HasYama()
    local hasCDKInv = HasCDK()
    
    -- Проверяем через CDKQuest
    local progress = GetCDKProgress()
    
    AddLog("Через инвентарь:")
    AddLog("  Tushita: " .. tostring(hasTushitaInv))
    AddLog("  Yama: " .. tostring(hasYamaInv))
    AddLog("  CDK: " .. tostring(hasCDKInv))
    
    if progress then
        AddLog("Через CDKQuest:")
        AddLog("  Tushita: " .. tostring(progress[1]))
        AddLog("  Yama: " .. tostring(progress[2]))
        AddLog("  CDK: " .. tostring(progress[3]))
    else
        AddLog("CDKQuest не отвечает или недоступен")
    end
    
    -- Определяем окончательный статус
    local finalStatus = {}
    finalStatus.Tushita = hasTushitaInv or (progress and progress[1] == true)
    finalStatus.Yama = hasYamaInv or (progress and progress[2] == true)
    finalStatus.CDK = hasCDKInv or (progress and progress[3] == true)
    
    AddLog("=== Окончательный статус ===")
    AddLog("Tushita: " .. tostring(finalStatus.Tushita))
    AddLog("Yama: " .. tostring(finalStatus.Yama))
    AddLog("CDK: " .. tostring(finalStatus.CDK))
    
    if finalStatus.CDK then
        Rayfield:Notify({
            Title = "CDK Статус",
            Content = "✅ У вас уже есть Cursed Dual Katana!",
            Duration = 5,
            Image = 4483362458
        })
    elseif finalStatus.Tushita and finalStatus.Yama then
        Rayfield:Notify({
            Title = "CDK Статус",
            Content = "📋 Есть Tushita и Yama, можно фармить CDK",
            Duration = 5,
            Image = 4483362458
        })
    else
        local missing = {}
        if not finalStatus.Tushita then table.insert(missing, "Tushita") end
        if not finalStatus.Yama then table.insert(missing, "Yama") end
        
        Rayfield:Notify({
            Title = "CDK Статус",
            Content = "❌ Отсутствует: " .. table.concat(missing, ", "),
            Duration = 5,
            Image = 4483362458
        })
    end
end

-- Кнопки проверки
MainTab:CreateButton({
    Name = "Проверить CDK статус",
    Callback = CheckCDKStatus
})

MainTab:CreateButton({
    Name = "Загрузить Tushita из хранилища",
    Callback = function()
        AddLog("Загружаю Tushita...")
        if GetItemFromStorage("Tushita") then
            wait(1)
            if HasTushita() then
                AddLog("Tushita загружена успешно")
                Rayfield:Notify({
                    Title = "Загрузка",
                    Content = "Tushita загружена из хранилища",
                    Duration = 3,
                    Image = 4483362458
                })
            else
                AddLog("Tushita не найдена в хранилище")
            end
        else
            AddLog("Ошибка загрузки Tushita")
        end
    end
})

MainTab:CreateButton({
    Name = "Загрузить Yama из хранилища",
    Callback = function()
        AddLog("Загружаю Yama...")
        if GetItemFromStorage("Yama") then
            wait(1)
            if HasYama() then
                AddLog("Yama загружена успешно")
                Rayfield:Notify({
                    Title = "Загрузка",
                    Content = "Yama загружена из хранилища",
                    Duration = 3,
                    Image = 4483362458
                })
            else
                AddLog("Yama не найдена в хранилище")
            end
        else
            AddLog("Ошибка загрузки Yama")
        end
    end
})

MainTab:CreateButton({
    Name = "Проверить весь инвентарь",
    Callback = function()
        AddLog("=== Полная проверка инвентаря ===")
        
        local inventory = GetInventoryData()
        local swordCount = 0
        
        for itemName, _ in pairs(inventory) do
            if itemName == "Tushita" or itemName == "Yama" or itemName == "Cursed Dual Katana" then
                AddLog("Найден: " .. itemName)
                swordCount = swordCount + 1
            end
        end
        
        AddLog("Всего мечей CDK: " .. swordCount)
        
        if swordCount > 0 then
            Rayfield:Notify({
                Title = "Инвентарь",
                Content = "Найдено " .. swordCount .. " мечей CDK",
                Duration = 5,
                Image = 4483362458
            })
        end
    end
})

-- Секция телепортов
MainTab:CreateSection("Телепорты")

MainTab:CreateButton({
    Name = "Телепорт к Tushita (Hydra Island)",
    Callback = function()
        AddLog("Телепорт к Tushita...")
        SimpleTeleport(Locations.Tushita)
    end
})

MainTab:CreateButton({
    Name = "Телепорт к Yama (Haunted Castle)",
    Callback = function()
        AddLog("Телепорт к Yama...")
        SimpleTeleport(Locations.Yama)
    end
})

MainTab:CreateButton({
    Name = "Телепорт к CDK Altar",
    Callback = function()
        AddLog("Телепорт к CDK Altar...")
        SimpleTeleport(Locations.CDKAltar)
    end
})

MainTab:CreateButton({
    Name = "Тест телепорта (50 юнитов)",
    Callback = function()
        AddLog("Тестирую телепорт...")
        local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
        local testPos = hrp.CFrame * CFrame.new(0, 0, -50)
        SimpleTeleport(testPos)
    end
})

-- Секция информации
MainTab:CreateSection("Информация")

MainTab:CreateParagraph({
    Title = "Как использовать:",
    Content = "1. Проверьте статус CDK\n2. Загрузите мечи из хранилища если нужно\n3. Используйте телепорты\n4. Скорость телепорта 150-200 безопасно"
})

-- Создаем статус панель
local StatusLabel = StatusTab:CreateLabel("Статус: Готов")
local LogsSection = StatusTab:CreateSection("Логи")
local LogsContainer = StatusTab:CreateParagraph({Title = "Лог действий", Content = "Ожидание..."})

function UpdateLogDisplay()
    local logText = ""
    for i, log in ipairs(StatusLogs) do
        logText = logText .. log .. "\n"
    end
    
    LogsContainer:Set({Title = "Логи (" .. #StatusLogs .. " записей)", Content = logText})
end

-- Автообновление логов
spawn(function()
    while wait(1) do
        UpdateLogDisplay()
    end
end)

-- Кнопка очистки логов
StatusTab:CreateButton({
    Name = "Очистить логи",
    Callback = function()
        StatusLogs = {}
        UpdateLogDisplay()
        AddLog("Логи очищены")
    end
})

-- Информация о скрипте
StatusTab:CreateSection("Информация о скрипте")
StatusTab:CreateParagraph({
    Title = "CDK Checker & Teleporter",
    Content = "Версия: 1.0\nАвтор: NoxHub\nФункции: Проверка инвентаря + телепорты\nСкорость: " .. TeleportSpeed
})

-- Инициализация
AddLog("Скрипт загружен успешно!")
AddLog("Скорость телепорта: " .. TeleportSpeed)
AddLog("Используйте 'Проверить CDK статус' для начала")

-- Загружаем конфигурацию
Rayfield:LoadConfiguration()
