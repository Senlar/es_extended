ESX.OneSync = {}

ESX.OneSync.Players = function(playerId, closest, coords, distance)
	local players = {}
	local distance = distance or 100
	local playerPed = playerId and GetPlayerPed(playerId)
	if closest ~= nil then coords = type(coords) == 'number' and GetEntityCoords(GetPlayerPed(coords)) or vector3(coords.x, coords.y, coords.z) end

	for _, xPlayer in pairs(Core.Players) do
		if xPlayer.source ~= playerId then
			if closest ~= nil then
				table.insert(players, {id = xPlayer.source, ped = GetPlayerPed(xPlayer.source)})
			else
				local entity = GetPlayerPed(xPlayer.source)
				local entityCoords = GetEntityCoords(entity)
				if not closest then
					if #(coords - entityCoords) <= distance then
						table.insert(players, {id = xPlayer.source, ped = entity, coords = entityCoords})
					end
				else
					local dist = #(coords - entityCoords)
					if dist <= players.distance or distance then
						players = {id = xPlayer.source, ped = entity, coords = entityCoords, distance = dist}
					end
				end
			end
		end
	end

	return players
end

ESX.OneSync.SpawnVehicle = function(model, coords, heading, cb)
	if type(model) == 'string' then model = GetHashKey(model) end
	CreateThread(function()
		local entity = Citizen.InvokeNative(`CREATE_AUTOMOBILE`, model, coords.x, coords.y, coords.z, heading)
		while not DoesEntityExist(entity) do Wait(20) end
		cb(entity)
	end)
end

ESX.OneSync.SpawnObject = function(model, coords, heading, cb)
	if type(model) == 'string' then model = GetHashKey(model) end
	CreateThread(function()
		CreateObject(model, coords, heading, true, true)
		while not DoesEntityExist(entity) do Wait(20) end
		cb(entity)
	end)
end

ESX.OneSync.SpawnPed = function(model, coords, heading, cb)
	if type(model) == 'string' then model = GetHashKey(model) end
	CreateThread(function()
		-- Set coords as vehicle and heading as seat to instead spawn the ped inside a vehicle
		local entity = type(coords) == 'number' and CreatePedInsideVehicle(coords, 1, heading, true, true)
			or CreatePed(0, model, coords.x, coords.y, coords.z, heading, true, true)
		while not DoesEntityExist(entity) do Wait(20) end
		cb(entity)
	end)
end

ESX.OneSync.GetPlayersInArea = function(playerId, coords, maxDistance)
	return ESX.OneSync.Players(playerId, false, coords, maxDistance)
end

ESX.OneSync.GetClosestPlayer = function(playerId, coords)
	return ESX.OneSync.Players(playerId, true, coords)
end

ESX.OneSync.GetNearbyEntities = function(entities, coords, modelFilter, maxDistance, isPed)
	local nearbyEntities = {}
	coords = type(coords) == 'number' and GetEntityCoords(GetPlayerPed(coords)) or vector3(coords.x, coords.y, coords.z)
	for _, entity in pairs(entities) do
		if not isPed or (isPed and not IsPedAPlayer(entity)) then
			if not modelFilter or modelFilter[GetEntityModel(entity)] then
				local entityCoords = GetEntityCoords(entity)
				if not maxDistance or #(coords - entityCoords) <= maxDistance then
					table.insert(nearbyEntities, {entity=entity, coords=entityCoords})
				end
			end
		end
	end

	return nearbyEntities
end

ESX.OneSync.GetClosestEntity = function(entities, coords, modelFilter, isPed)
	local distance, closestEntity, closestCoords = maxDistance or 100, nil, nil
	coords = type(coords) == 'number' and GetEntityCoords(GetPlayerPed(coords)) or vector3(coords.x, coords.y, coords.z)

	for _, entity in pairs(entities) do
		if not isPed or (isPed and not IsPedAPlayer(entity)) then
			if not modelFilter or modelFilter[GetEntityModel(entity)] then
				local entityCoords = GetEntityCoords(entity)
				local dist = #(coords - entityCoords)
				if dist < distance then
					closestEntity, distance, closestCoords = entity, dist, entityCoords
				end
			end
		end
	end
	return closestEntity, distance, closestCoords
end

ESX.OneSync.GetPedsInArea = function(coords, maxDistance, modelFilter)
	return ESX.OneSync.GetNearbyEntities(GetAllPeds(), coords, modelFilter, maxDistance, true)
end

ESX.OneSync.GetObjectsInArea = function(coords, maxDistance, modelFilter)
	return ESX.OneSync.GetNearbyEntities(GetAllObjects(), coords, modelFilter, maxDistance)
end

ESX.OneSync.GetVehiclesInArea = function(coords, maxDistance, modelFilter)
	return ESX.OneSync.GetNearbyEntities(GetAllVehicles(), coords, modelFilter, maxDistance)
end

ESX.OneSync.GetClosestPed = function(coords, modelFilter)
	return ESX.OneSync.GetClosestEntity(GetAllPeds(), coords, modelFilter, true)
end

ESX.OneSync.GetClosestObject = function(coords, modelFilter)
	return ESX.OneSync.GetClosestEntity(GetAllObjects(), coords, modelFilter)
end

ESX.OneSync.GetClosestVehicle = function(coords, modelFilter)
	return ESX.OneSync.GetClosestEntity(GetAllVehicles(), coords, modelFilter)
end
