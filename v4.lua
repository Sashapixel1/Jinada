-- DEBUG CommF_ Logger
-- Помести в StarterPlayerScripts, чтобы он подцепился раньше интерфейса

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("===== DEBUG CommF_ HOOK START =====")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 9e9)
local commF = remotesFolder:WaitForChild("CommF_", 9e9)

-- Оборачиваем InvokeServer
local oldInvoke = commF.InvokeServer
commF.InvokeServer = function(self, ...)
	local args = {...}
	print("\n[CommF_ Invoke Detected]")
	for i, v in ipairs(args) do
		print(string.format("  arg[%d]: %s", i, tostring(v)))
	end
	-- возвращаем оригинальное поведение, чтобы не ломать игру
	local result = oldInvoke(self, unpack(args))
	print("[CommF_ Result]:", result)
	return result
end

print("Hook installed! Открой инвентарь и взаимодействуй с фруктами (перемещение, выкладывание и т.д.)")
