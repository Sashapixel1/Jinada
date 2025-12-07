--========================================
--  Open Door Trial  (модуль)
--  вызывать OpenDoorTrial.Run()
--========================================

local OpenDoorTrial = {}

-- addLog(msg) — опциональная функция логирования
-- если не передать, будет использоваться print
function OpenDoorTrial.Run(addLog)
    local log = typeof(addLog) == "function" and addLog or function(msg)
        print("[OpenDoorTrial] " .. tostring(msg))
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

    log("Пробую открыть дверь: шаг 1 (OpenDoor).")
    local ok1, res1 = pcall(function()
        return CommF:InvokeServer("CDKQuest", "OpenDoor")
    end)

    if not ok1 then
        log("Ошибка на шаге 1: " .. tostring(res1))
        return false, res1
    end

    -- небольшая пауза между вызовами, как в реальном диалоге
    task.wait(0.3)

    log("Пробую открыть дверь: шаг 2 (OpenDoor, true).")
    local ok2, res2 = pcall(function()
        return CommF:InvokeServer("CDKQuest", "OpenDoor", true)
    end)

    if not ok2 then
        log("Ошибка на шаге 2: " .. tostring(res2))
        return false, res2
    end

    log("✅ Дверь триала должна быть открыта.")
    return true, res2
end
-- дальше инструкция по встраиванию
return OpenDoorTrial
-- если ты вставляешь модуль прямо в файл,
-- просто убери последнюю строку `return OpenDoorTrial`
-- и вместо этого снизу где надо зови:

OpenDoorTrial.Run(AddLog)  -- если есть функция AddLog из твоего GUI
-- или так, без логов:
OpenDoorTrial.Run()
