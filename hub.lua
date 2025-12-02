-- Mini CDK Teleporter Script
-- Version 2.1 (Safe Speed & Working Slider)

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
local TeleportSpeed = 150 -- Начальная безопасная скорость
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

-- Безопасный телепорт с автоматическим requestEntrance
function SafeTeleport(targetCFrame, locationName)
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
    AddLog(string.format("Скорость телепорта: %d юнитов/сек", TeleportSpeed))
    
    -- Если слишком далеко, используем requestEntrance
    if distance > 2000 then
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
    
    -- Если все еще далеко, используем промежуточный телепорт
    if distance > 1000 then
        AddLog("Дистанция большая, использую промежуточный телепорт...")
        
        -- Вычисляем направление
        local direction = (targetPos - currentPos).Unit
        local intermediatePos = currentPos + (direction * 800)
        local intermediateCFrame = CFrame.new(intermediatePos) * CFrame.Angles(0, hrp.CFrame:ToEulerAnglesXYZ().Y, 0)
        
        local intermediateTime = 800 / TeleportSpeed
        if intermediateTime < 2 then intermediateTime = 2 end
        
        AddLog(string.format("Промежуточный телепорт: %.1f сек", intermediateTime))
        
        local tween1 = TweenService:Create(hrp,
            TweenInfo.new(intermediateTime, Enum.EasingStyle.Linear),
            {CFrame = intermediateCFrame}
        )
        
        tween1:Play()
        
        local startTime1 = tick()
        while tick() - startTime1 < intermediateTime do
            if StopTween then
                tween1:Cancel()
                AddLog("Телепорт отменен на этапе 1")
                return false
            end
            wait(0.1)
        end
        
        tween1:Cancel()
        wait(0.5) -- Пауза между этапами
        
        -- Обновляем дистанцию
        currentPos = hrp.Position
        distance = (currentPos - targetPos).Magnitude
        AddLog(string.format("Осталось: %.0f юнитов", distance))
    end
    
    -- Финальный телепорт
    local travelTime = distance / TeleportSpeed
    
    -- Ограничиваем время твина для безопасности
    if travelTime < 2 then travelTime = 2 end  -- Минимум 2 секунды
    if travelTime > 15 then travelTime = 15 end -- Максимум 15 секунд
    
    AddLog(string.format("Финальный телепорт: %.1f секунд", travelTime))
    
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
    
    AddLog("Телепорт завершен успешно!")
    return true
end

-- Телепорт к Tushita
function TeleportToTushita()
    StopTween = false
    AddLog("Начинаю телепорт к Tushita...")
    
    local success = SafeTeleport(Locations.Tushita, "Tushita")
    
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
            Content = "Телепорт к Tushita отменен",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Телепорт к Yama
function TeleportToYama()
    StopTween = false
    AddLog("Начинаю телепорт к Yama...")
    
    local success = SafeTeleport(Locations.Yama, "Yama")
    
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
            Content = "Телепорт к Yama отменен",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Телепорт к CDK Altar
function TeleportToCDKAltar()
    StopTween = false
    AddLog("Начинаю телепорт к CDK Altar...")
    
    local success = SafeTeleport(Locations.CDKAltar, "CDK Altar")
    
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
            Content = "Телепорт к CDK Altar отменен",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Телепорт к Sea Beast
function TeleportToSeaBeast()
    StopTween = false
    AddLog("Начинаю телепорт к Sea Beast...")
    
    local success = SafeTeleport(Locations.SeaBeast, "Sea Beast")
    
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
            Content = "Телепорт к Sea Beast отменен",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Отмена телепорта
function CancelTeleport()
    StopTween = true
    AddLog("Запрошена отмена телепорта...")
    
    Rayfield:Notify({
        Title = "Телепорт",
        Content = "Отмена текущего телепорта",
        Duration = 2,
        Image = 4483362458
    })
end

-- Создаем UI элементы

-- Ползунок скорости
local SpeedSlider = MainTab:CreateSlider({
    Name = "Скорость телепорта",
    Range = {100, 400},
    Increment = 10,
    Suffix = "юнитов/сек",
    CurrentValue = TeleportSpeed,
    Flag = "TeleportSpeed",
    Callback = function(Value)
        TeleportSpeed = Value
        AddLog("Скорость телепорта изменена: " .. Value .. " юнитов/сек")
        
        -- Сохраняем в конфиг
        Rayfield:Notify({
            Title = "Скорость",
            Content = "Установлена скорость: " .. Value .. " юнитов/сек",
            Duration = 2,
            Image = 4483362458
        })
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
    Content = "1. Настройте скорость телепорта (рекомендуется 100-150)\n2. Выберите цель телепорта\n3. Нажмите кнопку телепорта\n4. Используйте 'Отмена' если нужно\n\n⚠️ Советы:\n• Низкая скорость безопаснее\n• Используйте fast travel для далеких точек\n• Отмена работает в любой момент"
})

MainTab:CreateParagraph({
    Title = "Рекомендации по скорости:",
    Content = "• 100-150: Безопасно (античит не сработает)\n• 150-250: Средняя скорость\n• 250-350: Быстро (риск античита)\n• 350-400: Очень быстро (античит может сработать)"
})

-- Создаем статус панель
local StatusLabel = StatusTab:CreateLabel("Статус: Готов к телепорту")
StatusTab:CreateLabel("Текущая скорость: " .. TeleportSpeed .. " юнитов/сек")

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

-- Автообновление логов и скорости
spawn(function()
    while wait(1) do
        UpdateLogDisplay()
        
        -- Обновляем отображение скорости
        StatusLabel:Set("Скорость: " .. TeleportSpeed .. " юнитов/сек | Готов к телепорту")
    end
end)

-- Информация о скрипте
StatusTab:CreateSection("Информация о скрипте")
StatusTab:CreateParagraph({
    Title = "CDK Teleporter v2.1",
    Content = "Безопасный телепорт\nДиапазон скорости: 100-400\nСовместимость с античитом"
})

-- Инициализация
AddLog("Скрипт загружен успешно!")
AddLog("Текущая скорость телепорта: " .. TeleportSpeed .. " юнитов/сек")
AddLog("Рекомендуемая скорость: 100-150 для безопасности")
AddLog("Готов к телепорту")

-- Загружаем конфигурацию
Rayfield:LoadConfiguration()
