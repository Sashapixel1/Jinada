-- Mini CDK Teleporter Script
-- Version 2.0 (Simple Teleport)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "CDK Teleporter",
    LoadingTitle = "Cursed Katana Teleport",
    LoadingSubtitle = "by NoxHub",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NoxHub",
        FileName = "CDKTeleporter"
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
local TeleportSpeed = 300
local TweenService = game:GetService("TweenService")
local StopTween = false

-- Правильные координаты
local Locations = {
    Tushita = CFrame.new(-10238.8759765625, 389.7912902832, -9549.7939453125),
    Yama = CFrame.new(-9489.2168, 142.130066, 5567.14697),
    CDKAltar = CFrame.new(-9713.7255859375, 332.039306640625, -10169.1767578125),
    SeaBeast = CFrame.new(-9752.6689453125, 331.55419921875, -10240.32421875)
}

-- Status Logs
local StatusLogs = {}
local MaxLogs = 15

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

-- Упрощенный телепорт без разделения на части
function SimpleTeleport(targetCFrame, locationName)
    if StopTween then
        StopTween = false
    end
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        AddLog("Ошибка: Персонаж не найден")
        return false
    end
    
    local hrp = character.HumanoidRootPart
    local currentPos = hrp.Position
    local targetPos = targetCFrame.Position
    
    -- Проверяем дистанцию
    local distance = (currentPos - targetPos).Magnitude
    AddLog(string.format("Дистанция до %s: %.0f юнитов", locationName, distance))
    
    -- Если слишком далеко, используем requestEntrance
    if distance > 5000 then
        AddLog("Большая дистанция, использую fast travel...")
        
        local entranceVector = Vector3.new(targetPos.X, targetPos.Y, targetPos.Z)
        
        if string.find(locationName, "Tushita") then
            entranceVector = Vector3.new(-10238.8759765625, 389.7912902832, -9549.7939453125)
        elseif string.find(locationName, "Yama") then
            entranceVector = Vector3.new(-9489.2168, 142.130066, 5567.14697)
        elseif string.find(locationName, "CDK") or string.find(locationName, "Sea") then
            entranceVector = Vector3.new(-9752.6689453125, 331.55419921875, -10240.32421875)
        end
        
        local success = pcall(function()
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("requestEntrance", entranceVector)
        end)
        
        if success then
            AddLog("Fast travel выполнен успешно")
            wait(2) -- Даем время для телепорта
        else
            AddLog("Ошибка fast travel")
        end
        
        -- Обновляем позицию после fast travel
        currentPos = hrp.Position
        distance = (currentPos - targetPos).Magnitude
        AddLog(string.format("Новая дистанция: %.0f юнитов", distance))
    end
    
    -- Вычисляем время твина
    local travelTime = distance / TeleportSpeed
    
    -- Ограничиваем время твина
    if travelTime < 1 then travelTime = 1 end
    if travelTime > 10 then travelTime = 10 end
    
    AddLog(string.format("Начинаю телепорт: %.1f секунд", travelTime))
    
    -- Создаем твин
    local tween = TweenService:Create(hrp,
        TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    
    -- Запускаем твин
    tween:Play()
    
    -- Ждем завершения или отмены
    local startTime = tick()
    while tick() - startTime < travelTime do
        if StopTween then
            tween:Cancel()
            AddLog("Телепорт отменен")
            return false
        end
        wait(0.1)
    end
    
    -- Принудительно устанавливаем конечную позицию
    tween:Cancel()
    pcall(function()
        hrp.CFrame = targetCFrame
    end)
    
    AddLog("Телепорт завершен успешно")
    return true
end

-- Телепорт к Tushita
function TeleportToTushita()
    StopTween = false
    AddLog("Телепорт к Tushita...")
    
    local success = SimpleTeleport(Locations.Tushita, "Tushita")
    
    if success then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Успешно телепортирован к Tushita",
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Ошибка телепорта к Tushita",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Телепорт к Yama
function TeleportToYama()
    StopTween = false
    AddLog("Телепорт к Yama...")
    
    local success = SimpleTeleport(Locations.Yama, "Yama")
    
    if success then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Успешно телепортирован к Yama",
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Ошибка телепорта к Yama",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Телепорт к CDK Altar
function TeleportToCDKAltar()
    StopTween = false
    AddLog("Телепорт к CDK Altar...")
    
    local success = SimpleTeleport(Locations.CDKAltar, "CDK Altar")
    
    if success then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Успешно телепортирован к CDK Altar",
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Ошибка телепорта к CDK Altar",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Телепорт к Sea Beast
function TeleportToSeaBeast()
    StopTween = false
    AddLog("Телепорт к Sea Beast...")
    
    local success = SimpleTeleport(Locations.SeaBeast, "Sea Beast")
    
    if success then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Успешно телепортирован к Sea Beast",
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Ошибка телепорта к Sea Beast",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Отмена телепорта
function CancelTeleport()
    StopTween = true
    AddLog("Телепорт отменен")
    
    Rayfield:Notify({
        Title = "Телепорт",
        Content = "Текущий телепорт отменен",
        Duration = 2,
        Image = 4483362458
    })
end

-- Создаем UI элементы

local SpeedSlider = MainTab:CreateSlider({
    Name = "Скорость телепорта",
    Range = {200, 400},
    Increment = 10,
    Suffix = "ед/сек",
    CurrentValue = TeleportSpeed,
    Flag = "TeleportSpeed",
    Callback = function(Value)
        TeleportSpeed = Value
        AddLog("Скорость телепорта: " .. Value)
    end,
})

-- Секция телепортов
MainTab:CreateSection("Телепорты CDK")

MainTab:CreateButton({
    Name = "Телепорт к Tushita",
    Callback = TeleportToTushita
})

MainTab:CreateButton({
    Name = "Телепорт к Yama",
    Callback = TeleportToYama
})

MainTab:CreateButton({
    Name = "Телепорт к CDK Altar",
    Callback = TeleportToCDKAltar
})

MainTab:CreateButton({
    Name = "Телепорт к Sea Beast",
    Callback = TeleportToSeaBeast
})

MainTab:CreateButton({
    Name = "Отмена телепорта",
    Callback = CancelTeleport
})

-- Информация
MainTab:CreateSection("Информация")

MainTab:CreateParagraph({
    Title = "Как использовать:",
    Content = "1. Выберите цель телепорта\n2. Настройте скорость (рекомендуется 300)\n3. Нажмите кнопку телепорта\n4. Используйте 'Отмена' если нужно\n\nСкорость 300 юнитов/сек безопасна для античита"
})

-- Создаем статус панель
StatusTab:CreateLabel("Статус: Готов к телепорту")
local LogsSection = StatusTab:CreateSection("Логи телепорта")
local LogsContainer = StatusTab:CreateParagraph({Title = "Логи действий", Content = "Ожидание..."})

function UpdateLogDisplay()
    local logText = ""
    for i, log in ipairs(StatusLogs) do
        logText = logText .. log .. "\n"
    end
    
    LogsContainer:Set({Title = "Логи (" .. #StatusLogs .. " записей)", Content = logText})
end

-- Кнопка очистки логов
StatusTab:CreateButton({
    Name = "Очистить логи",
    Callback = function()
        StatusLogs = {}
        UpdateLogDisplay()
        AddLog("Логи очищены")
    end
})

-- Автообновление логов
spawn(function()
    while wait(1) do
        UpdateLogDisplay()
    end
end)

-- Информация о скрипте
StatusTab:CreateSection("Информация")
StatusTab:CreateParagraph({
    Title = "CDK Teleporter v2.0",
    Content = "Упрощенный телепорт\nСкорость: " .. TeleportSpeed .. "\nБезопасно для античита"
})

-- Инициализация
AddLog("Скрипт загружен успешно!")
AddLog("Текущая скорость телепорта: " .. TeleportSpeed)
AddLog("Готов к телепорту")

-- Загружаем конфигурацию
Rayfield:LoadConfiguration()
