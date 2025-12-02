-- Auto Cursed Dual Katana Script by NoxHub
-- Version 2.0 (Combined Teleport & Auto Farm)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables
local AutoCursedKatana = false
local CurrentStatus = "Idle"
local LastUpdate = os.time()
local StartTime = os.time()
local TeleportSpeed = 150
local StopTween = false
local IsTeleporting = false

-- Services
local TweenService = game:GetService("TweenService")

-- Locations
local Locations = {
    Tushita = CFrame.new(-10238.8759765625, 389.7912902832, -9549.7939453125),
    Yama = CFrame.new(-9489.2168, 142.130066, 5567.14697),
    CDKAltar = CFrame.new(-9717.33203125, 375.1759338378906, -10160.1455078125),
    SeaBeast = CFrame.new(-9752.6689453125, 331.55419921875, -10240.32421875)
}

-- Status Logs
local StatusLogs = {}
local MaxLogs = 20

-- Логирование
function AddLog(message)
    local timestamp = os.date("%H:%M:%S")
    local logEntry = "["..timestamp.."] "..message
    table.insert(StatusLogs, 1, logEntry)
    
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
end

function UpdateStatus(newStatus)
    CurrentStatus = newStatus
    AddLog("Статус: "..newStatus)
    LastUpdate = os.time()
end

function GetUptime()
    local totalSeconds = os.time() - StartTime
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Телепорт функция (из нашего рабочего скрипта)
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
            AddLog("❌ Телепорт отменен")
            IsTeleporting = false
            return false
        end
        
        -- Периодически обновляем прогресс
        local elapsed = tick() - startTime
        local progress = math.floor((elapsed / travelTime) * 100)
        local remaining = math.floor(travelTime - elapsed)
        
        if progress % 20 == 0 then -- Обновляем каждые 20%
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

function CancelTeleport()
    StopTween = true
    AddLog("⏸️ Запрошена отмена телепорта")
end

-- Inventory Functions
function HasItem(itemName)
    local success = pcall(function()
        if game.Players.LocalPlayer.Character:FindFirstChild(itemName) then
            return true
        end
        
        if game.Players.LocalPlayer.Backpack:FindFirstChild(itemName) then
            return true
        end
        
        return false
    end)
    
    return success or false
end

function HasTushita()
    return HasItem("Tushita")
end

function HasYama()
    return HasItem("Yama")
end

function HasCDK()
    return HasItem("Cursed Dual Katana") or HasItem("Cursed Dual Katana [CDK]")
end

function TryLoadItem(itemName)
    local success = pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("LoadItem", itemName)
    end)
    
    if success then
        wait(1)
        return HasItem(itemName)
    end
    
    return false
end

-- Combat Functions
function Attack()
    game:GetService("VirtualUser"):Button1Down(Vector2.new(0,0))
    wait(0.1)
    game:GetService("VirtualUser"):Button1Up(Vector2.new(0,0))
end

function AutoHaki()
    if not game.Players.LocalPlayer.Character:FindFirstChild("HasBuso") then
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso")
    end
end

-- Farming Functions
function FarmTushita()
    UpdateStatus("Добыча Tushita...")
    
    -- Проверяем, есть ли уже
    if HasTushita() or TryLoadItem("Tushita") then
        AddLog("✅ Уже есть Tushita")
        return true
    end
    
    -- Телепорт
    local success = SimpleTeleport(Locations.Tushita, "Tushita")
    if not success then
        AddLog("❌ Ошибка телепорта к Tushita")
        return false
    end
    
    wait(2)
    
    -- Начинаем испытание
    AddLog("Начинаю испытание Tushita...")
    local trialSuccess = pcall(function()
        return game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("CDKQuest", "StartTrial", "Tushita")
    end)
    
    if trialSuccess then
        AddLog("✅ Испытание Tushita начато")
        UpdateStatus("Прохождение испытания Tushita...")
        
        -- Ждем получения Tushita
        for i = 1, 60 do
            if HasTushita() then
                AddLog("✅ Получена Tushita!")
                return true
            end
            wait(1)
        end
    else
        AddLog("❌ Ошибка начала испытания Tushita")
    end
    
    return HasTushita()
end

function FarmYama()
    UpdateStatus("Добыча Yama...")
    
    -- Проверяем, есть ли уже
    if HasYama() or TryLoadItem("Yama") then
        AddLog("✅ Уже есть Yama")
        return true
    end
    
    -- Телепорт
    local success = SimpleTeleport(Locations.Yama, "Yama")
    if not success then
        AddLog("❌ Ошибка телепорта к Yama")
        return false
    end
    
    wait(2)
    
    -- Начинаем испытание
    AddLog("Начинаю испытание Yama...")
    local trialSuccess = pcall(function()
        return game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("CDKQuest", "StartTrial", "Yama")
    end)
    
    if trialSuccess then
        AddLog("✅ Испытание Yama начато")
        UpdateStatus("Прохождение испытания Yama...")
        
        -- Ждем получения Yama
        for i = 1, 60 do
            if HasYama() then
                AddLog("✅ Получена Yama!")
                return true
            end
            wait(1)
        end
    else
        AddLog("❌ Ошибка начала испытания Yama")
    end
    
    return HasYama()
end

function FarmCDK()
    UpdateStatus("Добыча CDK...")
    
    -- Проверяем, есть ли обе катаны
    if not (HasTushita() and HasYama()) then
        AddLog("❌ Нужны обе катаны: Tushita и Yama")
        return false
    end
    
    -- Проверяем, есть ли уже CDK
    if HasCDK() then
        AddLog("✅ Уже есть Cursed Dual Katana!")
        return true
    end
    
    -- Телепорт
    local success = SimpleTeleport(Locations.CDKAltar, "CDK Altar")
    if not success then
        AddLog("❌ Ошибка телепорта к CDK Altar")
        return false
    end
    
    wait(2)
    
    -- Начинаем квест
    AddLog("Начинаю квест CDK...")
    local questSuccess = pcall(function()
        return game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("CDKQuest", "StartQuest", "CursedKatana")
    end)
    
    if questSuccess then
        AddLog("✅ Квест CDK начат")
        UpdateStatus("Прохождение квеста CDK...")
        
        -- Ждем получения CDK
        for i = 1, 120 do
            if HasCDK() then
                AddLog("🎉 ПОЛУЧЕНА CURSED DUAL KATANA!")
                return true
            end
            wait(1)
        end
    else
        AddLog("❌ Ошибка начала квеста CDK")
    end
    
    return HasCDK()
end

-- Теперь создаем окно и UI элементы

local Window = Rayfield:CreateWindow({
    Name = "Auto Cursed Dual Katana",
    LoadingTitle = "Cursed Katana Farm",
    LoadingSubtitle = "by NoxHub",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NoxHub",
        FileName = "CursedKatana"
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

-- UI Update Function
function UpdateLogDisplay()
    if StatusLabel then
        StatusLabel:Set("Статус: " .. CurrentStatus)
    end
    if UptimeLabel then
        UptimeLabel:Set("Время работы: " .. GetUptime())
    end
    
    if LogsContainer then
        local logText = ""
        for i, log in ipairs(StatusLogs) do
            logText = logText .. log .. "\n"
        end
        LogsContainer:Set({Title = "Логи (" .. #StatusLogs .. " записей)", Content = logText})
    end
end

-- Main Toggle
local Toggle = MainTab:CreateToggle({
    Name = "Автофарм CDK",
    CurrentValue = false,
    Flag = "AutoCDK",
    Callback = function(Value)
        AutoCursedKatana = Value
        if Value then
            StartTime = os.time()
            AddLog("🚀 Автофарм CDK ЗАПУЩЕН")
            UpdateStatus("Запуск...")
            Rayfield:Notify({
                Title = "Автофарм CDK",
                Content = "Начинаю фарм Cursed Dual Katana",
                Duration = 5,
                Image = 4483362458
            })
        else
            CancelTeleport()
            AddLog("🛑 Автофарм CDK ОСТАНОВЛЕН")
            UpdateStatus("Остановлен")
            Rayfield:Notify({
                Title = "Автофарм CDK",
                Content = "Фарм остановлен",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

-- Speed Slider (используется в SimpleTeleport)
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

-- Ручное управление
MainTab:CreateSection("Ручное управление")

-- Ручные телепорты
MainTab:CreateButton({
    Name = "Телепорт к Tushita",
    Callback = function()
        CancelTeleport()
        UpdateStatus("Ручной телепорт к Tushita")
        local success = SimpleTeleport(Locations.Tushita, "Tushita")
        
        if success then
            Rayfield:Notify({
                Title = "Телепорт",
                Content = "Успешно телепортирован к Tushita",
                Duration = 3,
                Image = 4483362458
            })
        end
        UpdateStatus("Готов")
    end
})

MainTab:CreateButton({
    Name = "Телепорт к Yama",
    Callback = function()
        CancelTeleport()
        UpdateStatus("Ручной телепорт к Yama")
        local success = SimpleTeleport(Locations.Yama, "Yama")
        
        if success then
            Rayfield:Notify({
                Title = "Телепорт",
                Content = "Успешно телепортирован к Yama",
                Duration = 3,
                Image = 4483362458
            })
        end
        UpdateStatus("Готов")
    end
})

MainTab:CreateButton({
    Name = "Телепорт к CDK Altar",
    Callback = function()
        CancelTeleport()
        UpdateStatus("Ручной телепорт к CDK Altar")
        local success = SimpleTeleport(Locations.CDKAltar, "CDK Altar")
        
        if success then
            Rayfield:Notify({
                Title = "Телепорт",
                Content = "Успешно телепортирован к CDK Altar",
                Duration = 3,
                Image = 4483362458
            })
        end
        UpdateStatus("Готов")
    end
})

MainTab:CreateButton({
    Name = "Телепорт к Sea Beast",
    Callback = function()
        CancelTeleport()
        UpdateStatus("Ручной телепорт к Sea Beast")
        local success = SimpleTeleport(Locations.SeaBeast, "Sea Beast")
        
        if success then
            Rayfield:Notify({
                Title = "Телепорт",
                Content = "Успешно телепортирован к Sea Beast",
                Duration = 3,
                Image = 4483362458
            })
        end
        UpdateStatus("Готов")
    end
})

-- Инвентарь
MainTab:CreateButton({
    Name = "Проверить инвентарь",
    Callback = function()
        local hasT = HasTushita()
        local hasY = HasYama()
        local hasC = HasCDK()
        
        local message = string.format("Tushita: %s, Yama: %s, CDK: %s", 
            tostring(hasT), tostring(hasY), tostring(hasC))
        
        AddLog("📦 Проверка инвентаря: " .. message)
        Rayfield:Notify({
            Title = "Инвентарь",
            Content = message,
            Duration = 5,
            Image = 4483362458
        })
    end
})

MainTab:CreateButton({
    Name = "Загрузить Tushita из хранилища",
    Callback = function()
        AddLog("📥 Загружаю Tushita из хранилища...")
        if TryLoadItem("Tushita") then
            AddLog("✅ Tushita загружена успешно")
            Rayfield:Notify({
                Title = "Загрузка",
                Content = "Tushita загружена из хранилища",
                Duration = 3,
                Image = 4483362458
            })
        else
            AddLog("❌ Ошибка загрузки Tushita")
            Rayfield:Notify({
                Title = "Загрузка",
                Content = "Ошибка загрузки Tushita",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

MainTab:CreateButton({
    Name = "Загрузить Yama из хранилища",
    Callback = function()
        AddLog("📥 Загружаю Yama из хранилища...")
        if TryLoadItem("Yama") then
            AddLog("✅ Yama загружена успешно")
            Rayfield:Notify({
                Title = "Загрузка",
                Content = "Yama загружена из хранилища",
                Duration = 3,
                Image = 4483362458
            })
        else
            AddLog("❌ Ошибка загрузки Yama")
            Rayfield:Notify({
                Title = "Загрузка",
                Content = "Ошибка загрузки Yama",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

MainTab:CreateButton({
    Name = "Отмена телепорта",
    Callback = function()
        CancelTeleport()
        AddLog("⏸️ Отмена телепорта")
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Телепорт отменен",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- Информация
MainTab:CreateSection("Информация")

MainTab:CreateParagraph({
    Title = "Как использовать:",
    Content = "1. Установите скорость 100-150 (безопасно)\n2. Включите автофарм CDK\n3. Используйте ручные кнопки для тестов\n4. Требуется: 2000+ уровень, Third Sea"
})

MainTab:CreateParagraph({
    Title = "Процесс фарма:",
    Content = "1. Получить Tushita (испытание)\n2. Получить Yama (испытание)\n3. Объединить в CDK Altar\n4. Получить Cursed Dual Katana"
})

-- Создаем статус панель
local StatusLabel = StatusTab:CreateLabel("Статус: " .. CurrentStatus)
local UptimeLabel = StatusTab:CreateLabel("Время работы: " .. GetUptime())
local SpeedLabel = StatusTab:CreateLabel("Скорость: " .. TeleportSpeed .. " юнитов/сек")

StatusTab:CreateSection("Логи")
local LogsContainer = StatusTab:CreateParagraph({Title = "Логи действий", Content = "Ожидание..."})

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
        
        if IsTeleporting then
            StatusLabel:Set("Статус: Телепортируется...")
        else
            StatusLabel:Set("Статус: " .. CurrentStatus)
        end
        UptimeLabel:Set("Время работы: " .. GetUptime())
        SpeedLabel:Set("Скорость: " .. TeleportSpeed .. " юнитов/сек")
    end
end)

-- Main Auto Farm Loop
spawn(function()
    while wait(2) do
        if AutoCursedKatana then
            pcall(function()
                -- Проверяем, есть ли уже CDK
                if HasCDK() then
                    AddLog("🎉 УЖЕ ЕСТЬ CURSED DUAL KATANA!")
                    AutoCursedKatana = false
                    Toggle:Set(false)
                    UpdateStatus("Завершено")
                    Rayfield:Notify({
                        Title = "Автофарм CDK",
                        Content = "Уже есть Cursed Dual Katana!",
                        Duration = 5,
                        Image = 4483362458
                    })
                    return
                end
                
                AddLog("=== НАЧАЛО ФАРМА CDK ===")
                
                -- Фармим Tushita
                if not HasTushita() then
                    AddLog("--- ФАРМ TUSHITA ---")
                    local gotTushita = FarmTushita()
                    
                    if not gotTushita then
                        AddLog("❌ Не удалось получить Tushita")
                        UpdateStatus("Ошибка Tushita")
                        return
                    end
                else
                    AddLog("✅ Уже есть Tushita")
                end
                
                if not AutoCursedKatana then return end
                
                -- Фармим Yama
                if not HasYama() then
                    AddLog("--- ФАРМ YAMA ---")
                    local gotYama = FarmYama()
                    
                    if not gotYama then
                        AddLog("❌ Не удалось получить Yama")
                        UpdateStatus("Ошибка Yama")
                        return
                    end
                else
                    AddLog("✅ Уже есть Yama")
                end
                
                if not AutoCursedKatana then return end
                
                -- Фармим CDK
                if HasTushita() and HasYama() then
                    AddLog("--- ФАРМ CDK ---")
                    local gotCDK = FarmCDK()
                    
                    if gotCDK then
                        AddLog("🎉 CURSED DUAL KATANA ПОЛУЧЕНА!")
                        AutoCursedKatana = false
                        Toggle:Set(false)
                        UpdateStatus("Завершено")
                        Rayfield:Notify({
                            Title = "Автофарм CDK",
                            Content = "ПОЛУЧЕНА Cursed Dual Katana!",
                            Duration = 10,
                            Image = 4483362458
                        })
                    else
                        AddLog("⚠️ Не удалось получить CDK, пробую снова...")
                        UpdateStatus("Повтор CDK...")
                    end
                else
                    AddLog("❌ Отсутствует Tushita или Yama")
                    UpdateStatus("Нет катаны")
                end
            end)
        end
    end
end)

-- Информация о скрипте
StatusTab:CreateSection("Информация")
StatusTab:CreateParagraph({
    Title = "Auto CDK Farm v2.0",
    Content = "Объединенный телепорт и автофарм\nРабочий телепорт из версии 3.1\nБезопасная скорость 100-150\nМакс время телепорта: 120 сек"
})

-- Инициализация
AddLog("✅ Скрипт загружен успешно!")
AddLog("⚡ Начальная скорость: " .. TeleportSpeed .. " юнитов/сек")
AddLog("📍 Доступно 4 точки телепорта")
AddLog("⚠️ Рекомендуемая скорость: 100-150 для безопасности")
UpdateStatus("Готов")

-- Загружаем конфигурацию
Rayfield:LoadConfiguration()
