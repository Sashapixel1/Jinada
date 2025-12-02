-- Mini CDK Checker & Teleporter Script
-- Version 1.1 (Fixed CDK Altar & Faster Teleport)

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
local TeleportSpeed = 300 -- Увеличил скорость телепорта
local TweenService = game:GetService("TweenService")
local StopTween = false

-- Правильные координаты (проверенные)
local Locations = {
    Tushita = CFrame.new(-10238.8759765625, 389.7912902832, -9549.7939453125),
    Yama = CFrame.new(-9489.2168, 142.130066, 5567.14697),
    -- Правильные координаты для CDK Altar
    CDKAltar = CFrame.new(-9713.7255859375, 332.039306640625, -10169.1767578125),
    -- Альтернативные координаты для CDK
    CDKAltar2 = CFrame.new(-9709.8876953125, 332.039306640625, -10165.560546875),
    CDKAltar3 = CFrame.new(-9717.33203125, 332.039306640625, -10160.1455078125)
}

-- Status Logs
local StatusLogs = {}
local MaxLogs = 20

-- Функции для работы с инвентарем
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
    
    -- Проверяем через getInventory
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

-- Улучшенный телепорт с отменой
function CancelCurrentTeleport()
    StopTween = true
    wait(0.1)
    StopTween = false
end

-- Функция безопасного телепорта с несколькими попытками для CDK Altar
function SafeTeleportTo(targetCFrame, locationName)
    CancelCurrentTeleport()
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        AddLog("Ошибка: Персонаж не найден")
        return false
    end
    
    local hrp = character.HumanoidRootPart
    local currentPos = hrp.Position
    local targetPos = targetCFrame.Position
    
    local distance = (currentPos - targetPos).Magnitude
    AddLog(string.format("Телепорт к %s: %.0f юнитов", locationName, distance))
    
    -- Для очень дальних локаций используем requestEntrance
    if distance > 5000 then
        AddLog("Большая дистанция, использую fast travel...")
        
        if string.find(locationName, "Tushita") then
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("requestEntrance", 
                Vector3.new(-10238.8759765625, 389.7912902832, -9549.7939453125))
        elseif string.find(locationName, "Yama") then
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("requestEntrance",
                Vector3.new(-9489.2168, 142.130066, 5567.14697))
        elseif string.find(locationName, "CDK") then
            -- Для CDK Altar можно телепортироваться к Sea Beast
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("requestEntrance",
                Vector3.new(-9752.6689453125, 331.55419921875, -10240.32421875))
        end
        
        wait(2)
        distance = (hrp.Position - targetPos).Magnitude
    end
    
    -- Если все еще далеко, используем промежуточные точки
    if distance > 1000 then
        local steps = math.ceil(distance / 800) -- Большие шаги для скорости
        AddLog(string.format("Использую %d шагов", steps))
        
        local direction = (targetPos - hrp.Position).Unit
        
        for step = 1, steps do
            if StopTween then
                AddLog("Телепорт отменен")
                return false
            end
            
            local stepTarget = hrp.Position + (direction * 800)
            local stepCFrame = CFrame.new(stepTarget) * CFrame.Angles(0, hrp.CFrame:ToEulerAnglesXYZ().Y, 0)
            
            local stepTime = 800 / TeleportSpeed
            if stepTime < 0.5 then stepTime = 0.5 end
            
            local tween = TweenService:Create(hrp,
                TweenInfo.new(stepTime, Enum.EasingStyle.Linear),
                {CFrame = stepCFrame}
            )
            
            tween:Play()
            
            local startTime = tick()
            while tick() - startTime < stepTime do
                if StopTween then
                    tween:Cancel()
                    return false
                end
                wait()
            end
            
            tween:Cancel()
        end
    end
    
    -- Финальный точный телепорт
    local finalTime = distance / TeleportSpeed
    if finalTime < 0.5 then finalTime = 0.5 end
    if finalTime > 3 then finalTime = 3 end
    
    AddLog(string.format("Финальный подход: %.1f сек", finalTime))
    
    local tween = TweenService:Create(hrp,
        TweenInfo.new(finalTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {CFrame = targetCFrame}
    )
    
    tween:Play()
    
    local startTime = tick()
    while tick() - startTime < finalTime do
        if StopTween then
            tween:Cancel()
            return false
        end
        wait()
    end
    
    tween:Cancel()
    hrp.CFrame = targetCFrame
    
    AddLog("Телепорт успешно завершен")
    return true
end

-- Специальная функция для телепорта к CDK Altar (пробует несколько точек)
function TeleportToCDKAltar()
    CancelCurrentTeleport()
    
    AddLog("Пытаюсь найти CDK Altar...")
    
    -- Пробуем несколько точек
    local cdkLocations = {
        {name = "Основная точка", cframe = Locations.CDKAltar},
        {name = "Альтернатива 1", cframe = Locations.CDKAltar2},
        {name = "Альтернатива 2", cframe = Locations.CDKAltar3}
    }
    
    for _, location in ipairs(cdkLocations) do
        AddLog("Пробую " .. location.name .. "...")
        
        local success = SafeTeleportTo(location.cframe, "CDK Altar")
        if success then
            wait(1)
            
            -- Проверяем что мы действительно у алтаря
            local playerPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
            local altarPos = location.cframe.Position
            local checkDistance = (playerPos - altarPos).Magnitude
            
            if checkDistance < 50 then
                AddLog("Успешно телепортировался к CDK Altar!")
                return true
            else
                AddLog("Не на месте, пробую следующую точку...")
            end
        end
        
        wait(1)
    end
    
    AddLog("Не удалось найти CDK Altar")
    return false
end

-- Создаем UI элементы

local SpeedSlider = MainTab:CreateSlider({
    Name = "Скорость телепорта",
    Range = {200, 400}, -- Увеличил диапазон
    Increment = 10,
    Suffix = "ед/сек",
    CurrentValue = TeleportSpeed,
    Flag = "TeleportSpeed",
    Callback = function(Value)
        TeleportSpeed = Value
        AddLog("Скорость телепорта установлена: " .. Value)
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

-- Секция телепортов
MainTab:CreateSection("Телепорты")

MainTab:CreateButton({
    Name = "Телепорт к Tushita (Hydra Island)",
    Callback = function()
        CancelCurrentTeleport()
        AddLog("Телепорт к Tushita...")
        
        local success = SafeTeleportTo(Locations.Tushita, "Tushita")
        
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
})

MainTab:CreateButton({
    Name = "Телепорт к Yama (Haunted Castle)",
    Callback = function()
        CancelCurrentTeleport()
        AddLog("Телепорт к Yama...")
        
        local success = SafeTeleportTo(Locations.Yama, "Yama")
        
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
})

MainTab:CreateButton({
    Name = "Телепорт к CDK Altar",
    Callback = function()
        CancelCurrentTeleport()
        AddLog("Телепорт к CDK Altar...")
        
        local success = TeleportToCDKAltar()
        
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
                Content = "Не удалось найти CDK Altar",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

MainTab:CreateButton({
    Name = "Телепорт к Sea Beast (рядом с CDK)",
    Callback = function()
        CancelCurrentTeleport()
        AddLog("Телепорт к Sea Beast...")
        
        local seaBeastPos = CFrame.new(-9752.6689453125, 331.55419921875, -10240.32421875)
        local success = SafeTeleportTo(seaBeastPos, "Sea Beast")
        
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
})

MainTab:CreateButton({
    Name = "Отмена телепорта",
    Callback = function()
        CancelCurrentTeleport()
        AddLog("Текущий телепорт отменен")
        Rayfield:Notify({
            Title = "Телепорт",
            Content = "Телепорт отменен",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- Секция информации
MainTab:CreateSection("Информация")

MainTab:CreateParagraph({
    Title = "Как использовать:",
    Content = "1. Проверьте статус CDK\n2. Загрузите мечи если нужно\n3. Используйте телепорты (скорость 300)\n4. Для CDK Altar используйте Sea Beast если не находит"
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
    Title = "CDK Checker & Teleporter v1.1",
    Content = "Скорость телепорта: " .. TeleportSpeed .. "\nФикс CDK Altar\nУлучшенный телепорт"
})

-- Инициализация
AddLog("Скрипт загружен успешно!")
AddLog("Скорость телепорта: " .. TeleportSpeed)
AddLog("Используйте кнопки телепорта")

-- Загружаем конфигурацию
Rayfield:LoadConfiguration()
