ESX = exports['es_extended']:getSharedObject()
------------------------------------------------------------------------
-- SHARED
------------------------------------------------------------------------
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

------------------------------------------------------------------------
if IsDuplicityVersion() then
------------------------------------------------------------------------

------------------------------------------------------------------------
else -- CLIENT
------------------------------------------------------------------------
	ESX.UI.RegisteredTypes, ESX.PlayerData.inventory = nil, {}

	AddEventHandler('esx:setPlayerData', function(key, val, last)
		if GetInvokingResource() == 'es_extended' then
			ESX.PlayerData[key] = val
			if OnPlayerData ~= nil then OnPlayerData(key, val, last) end
		end
	end)

------------------------------------------------------------------------
end
------------------------------------------------------------------------
