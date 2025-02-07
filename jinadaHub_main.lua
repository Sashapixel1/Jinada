spawn(function()
	while task.wait() do
		if _25msShared.AlwaysDay then
			L_8_.Heartbeat:wait()
			do
				game:GetService("Lighting").ClockTime = 5
			end
		end
	end
end)
