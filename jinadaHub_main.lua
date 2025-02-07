getgenv().Jinada=true


local L_8_ = game:GetService("RunService")
spawn(function()
	while task.wait() do
		if _25msShared.AlwaysDay then
			L_8_.Heartbeat:wait()
			do
				game:GetService("Lighting").ClockTime = 12
			end
		end
	end
end)
