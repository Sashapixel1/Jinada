-- Simple CDK Teleporter
-- Version 3.1 (2 Minute Max Teleport)

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
local IsTeleporting = false

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

-- Простой безопасный телепорт
function SimpleTeleport(targetCFrame, locationName)
    if IsTeleporting then
        AddLog("Уже выполняется телепорт, дождитесь завершения")
        return false
    end
    
    IsTeleporting = true
    StopTween = false
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        AddLog("Ошибка: Персонаж не найден")
        IsTeleporting = false
        return false
    end
    
    local hrp = character.HumanoidRootPart
    local currentPos = hrp.Position
    local targetPos = targetCFrame.Position
    
    -- Проверяем дистанцию
    local distance = (currentPos - targetPos).Magnitude
    AddLog(string.format("Начинаю телепорт к %s", locationName))
    AddLog(string.format("Дистанция: %.0f юнитов", distance))
    AddLog(string.format("Скорость: %d юнитов/сек", TeleportSpeed))
    
    -- Вычисляем время телепорта
    local travelTime = distance / TeleportSpeed
    
    -- Ограничиваем время для безопасности
    if travelTime < 5 then travelTime = 5 end  -- Минимум 5 секунд
    if travelTime > 120 then travelTime = 120 end -- Максимум 120 секунд (2 минуты)
    
    AddLog(string.format("Время телепорта: %.1f секунд (макс: 2 минуты)", travelTime))
    
    -- Создаем и запускаем твин
    local success, tween = pcall(function()
        return TweenService:Create(hrp,
            TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
            {CFrame = targetCFrame}
        )
    end)
    
    if not success then
        AddLog("Ошибка создания твина")
        IsTeleporting = false
        return false
    end
    
    tween:Play()
    
    -- Отображаем прогресс
    AddLog("⏳ Телепорт начался...")
    
    -- Ждем завершения
    local startTime = tick()
    while tick() - startTime < travelTime do
        if StopTween then
            tween:Cancel()
            AddLog("❌ Телепорт отменен пользователем")
            IsTeleporting = false
            return false
        end
        
        -- Периодически обновляем прогресс
        local elapsed = tick() - startTime
        local progress = math.floor((elapsed / travelTime) * 100)
        local remaining = math.floor(travelTime - elapsed)
        
        if progress % 10 == 0 then -- Обновляем каждые 10%
            AddLog(string.format("📊 Прогресс: %d%% (осталось: %d сек)", progress, remaining))
        end
        
        wait(1) -- Проверяем каждую секунду
    end
    
    -- Завершаем телепорт
    tween:Cancel()
    
    -- Плавно устанавливаем конечную позицию
    AddLog("🎯 Точная настройка позиции...")
    local finalTween = TweenService:Create(hrp,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {CFrame = targetCFrame}
    )
    
    finalTween:Play()
    wait(1)
    finalTween:Cancel()
    
    hrp.CFrame = targetCFrame
    
    AddLog("✅ Телепорт успешно завершен!")
    IsTeleporting = false
    return true
end

-- Функции телепорта (используют глобальную TeleportSpeed)
function TeleportToTushita()
    AddLog("🚀 Запуск телепорта к Tushita...")
    
    local success = SimpleTeleport(Locations.Tushita, "Tushita")
    
    if success then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Успешно телепортирован к Tushita",
            Duration = 5,
            Image = 4483362458
        })
    elseif not IsTeleporting then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Ошибка телепорта к Tushita",
            Duration = 5,
            Image = 4483362458
        })
    end
end

function TeleportToYama()
    AddLog("🚀 Запуск телепорта к Yama...")
    
    local success = SimpleTeleport(Locations.Yama, "Yama")
    
    if success then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Успешно телепортирован к Yama",
            Duration = 5,
            Image = 4483362458
        })
    elseif not IsTeleporting then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Ошибка телепорта к Yama",
            Duration = 5,
            Image = 4483362458
        })
    end
end

function TeleportToCDKAltar()
    AddLog("🚀 Запуск телепорта к CDK Altar...")
    
    local success = SimpleTeleport(Locations.CDKAltar, "CDK Altar")
    
    if success then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Успешно телепортирован к CDK Altar",
            Duration = 5,
            Image = 4483362458
        })
    elseif not IsTeleporting then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Ошибка телепорта к CDK Altar",
            Duration = 5,
            Image = 4483362458
        })
    end
end

function TeleportToSeaBeast()
    AddLog("🚀 Запуск телепорта к Sea Beast...")
    
    local success = SimpleTeleport(Locations.SeaBeast, "Sea Beast")
    
    if success then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Успешно телепортирован к Sea Beast",
            Duration = 5,
            Image = 4483362458
        })
    elseif not IsTeleporting then
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Ошибка телепорта к Sea Beast",
            Duration = 5,
            Image = 4483362458
        })
    end
end

function CancelTeleport()
    StopTween = true
    AddLog("⏸️ Запрошена отмена телепорта")
    
    Rayfield:Notify({
        Title = "Телепорт",
        Content = "Отмена текущего телепорта",
        Duration = 3,
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
        AddLog("⚡ Скорость телепорта: " .. Value .. " юнитов/сек")
        
        Rayfield:Notify({
            Title = "Скорость",
            Content = "Новая скорость: " .. Value .. " юнитов/сек",
            Duration = 3,
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
    Content = "1. Установите скорость (рекомендуется 100-150)\n2. Нажмите кнопку нужного телепорта\n3. Ждите завершения (макс 2 минуты)\n4. Используйте 'Отмена' при необходимости\n\n📊 Скорость влияет на все телепорты!"
})

MainTab:CreateParagraph({
    Title = "Важные настройки:",
    Content = "• Скорость: 100-400 юнитов/сек\n• Минимальное время: 5 секунд\n• Максимальное время: 120 секунд (2 минуты)\n• Рекомендуемая скорость: 100-150"
})

-- Создаем статус панель
local StatusLabel = StatusTab:CreateLabel("Статус: Ожидание")
local SpeedLabel = StatusTab:CreateLabel("Текущая скорость: " .. TeleportSpeed .. " юнитов/сек")

local LogsSection = StatusTab:CreateSection("Логи телепорта")
local LogsContainer = StatusTab:CreateParagraph({Title = "Логи действий", Content = "Ожидание..."})

function UpdateLogDisplay()
    local logText = ""
    for i, log in ipairs(StatusLogs) do
        logText = logText .. log .. "\n"
    end
    
    LogsContainer:Set({Title = "Логи (" .. #StatusLogs .. " записей)", Content = logText})
end

-- Функция обновления статуса
function UpdateStatus()
    if IsTeleporting then
        StatusLabel:Set("Статус: Телепортируется...")
    else
        StatusLabel:Set("Статус: Готов к телепорту")
    end
    SpeedLabel:Set("Текущая скорость: " .. TeleportSpeed .. " юнитов/сек")
end

-- Кнопка очистки логов
StatusTab:CreateButton({
    Name = "Очистить логи",
    Callback = function()
        StatusLogs = {}
        UpdateLogDisplay()
        AddLog("🧹 Логи очищены")
    end
})

-- Автообновление интерфейса
spawn(function()
    while wait(0.5) do
        UpdateLogDisplay()
        UpdateStatus()
    end
end)

-- Информация о скрипте
StatusTab:CreateSection("Информация")
StatusTab:CreateParagraph({
    Title = "Simple CDK Teleporter v3.1",
    Content = "Чистый телепорт без fast travel\nМакс время: 120 секунд\nСкорость: 100-400 юнитов/сек"
})

-- Инициализация
AddLog("✅ Скрипт загружен успешно!")
AddLog("⚡ Начальная скорость: " .. TeleportSpeed .. " юнитов/сек")
AddLog("⏰ Максимальное время телепорта: 120 секунд")
AddLog("📍 Доступно 4 точки телепорта")
AddLog("⚠️ Рекомендуемая скорость: 100-150 для безопасности")

-- Загружаем конфигурацию
Rayfield:LoadConfiguration()
