local Intervals = {}
SetInterval = function(id, msec, callback, onclear)
	if Intervals[id] and msec then
		Intervals[id] = msec
	else
		CreateThread(function()
			Intervals[id] = msec
			repeat
				Wait(Intervals[id])
				callback(Intervals[id])
			until Intervals[id] == -1 and (onclear and onclear() or true)
			Intervals[id] = nil
		end)
	end
end

ClearInterval = function(id)
	if Intervals[id] then Intervals[id] = -1 end
end