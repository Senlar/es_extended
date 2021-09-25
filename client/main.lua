CreateThread(function()
	while not Config.Multichar do
		Wait(0)
		if NetworkIsPlayerActive(PlayerId()) then
			exports.spawnmanager:setAutoSpawn(false)
			DoScreenFadeOut(0)
			TriggerServerEvent('esx:onPlayerJoined')
			break
		end
	end
end)

local PlayerKilledByPlayer = function(killerServerId, killerClientId, deathCause, victimCoords)
	local killerCoords = GetEntityCoords(GetPlayerPed(killerClientId))
	local distance = #(victimCoords - killerCoords)

	local data = {
		victimCoords = {x = ESX.Math.Round(victimCoords.x, 1), y = ESX.Math.Round(victimCoords.y, 1), z = ESX.Math.Round(victimCoords.z, 1)},
		killerCoords = {x = ESX.Math.Round(killerCoords.x, 1), y = ESX.Math.Round(killerCoords.y, 1), z = ESX.Math.Round(killerCoords.z, 1)},

		killedByPlayer = true,
		deathCause = deathCause,
		distance = ESX.Math.Round(distance, 1),

		killerServerId = killerServerId,
		killerClientId = killerClientId
	}

	TriggerEvent('esx:onPlayerDeath', data)
	TriggerServerEvent('esx:onPlayerDeath', data)
end

local PlayerKilled = function(deathCause, victimCoords)
	local data = {
		victimCoords = {x = ESX.Math.Round(victimCoords.x, 1), y = ESX.Math.Round(victimCoords.y, 1), z = ESX.Math.Round(victimCoords.z, 1)},

		killedByPlayer = false,
		deathCause = deathCause
	}
	TriggerEvent('esx:onPlayerDeath', data)
	TriggerServerEvent('esx:onPlayerDeath', data)
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer, isNew, skin)
	ESX.PlayerLoaded = true
	ESX.PlayerData = xPlayer

	FreezeEntityPosition(PlayerPedId(), true)

	if Config.Multichar then
		Wait(3000)
	else
		exports.spawnmanager:spawnPlayer({
			x = ESX.PlayerData.coords.x,
			y = ESX.PlayerData.coords.y,
			z = ESX.PlayerData.coords.z + 0.25,
			heading = ESX.PlayerData.coords.heading,
			model = `mp_m_freemode_01`,
			skipFade = false
		}, function()
			TriggerServerEvent('esx:onPlayerSpawn')
			TriggerEvent('esx:onPlayerSpawn')
			TriggerEvent('playerSpawned') -- compatibility with old scripts
			if isNew then
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadDefaultModel', true)
				else
					TriggerEvent('skinchanger:loadDefaultModel', false)
				end
			elseif skin then TriggerEvent('skinchanger:loadSkin', skin) end
			TriggerEvent('esx:loadingScreenOff')
			ShutdownLoadingScreen()
			ShutdownLoadingScreenNui()
			FreezeEntityPosition(ESX.PlayerData.ped, false)
		end)
	end

	while ESX.PlayerData.ped == nil do Wait(20) end
	-- enable PVP
	if Config.EnablePVP then
		SetCanAttackFriendly(ESX.PlayerData.ped, true, false)
		NetworkSetFriendlyFireOption(true)
	end

	if Config.EnableHud then
		for k,v in ipairs(ESX.PlayerData.accounts) do
			local accountTpl = '<div><img src="img/accounts/' .. v.name .. '.png"/>&nbsp;{{money}}</div>'
			ESX.UI.HUD.RegisterElement('account_' .. v.name, k, 0, accountTpl, {money = ESX.Math.GroupDigits(v.money)})
		end

		local jobTpl = '<div>{{job_label}}{{grade_label}}</div>'

		local gradeLabel = ESX.PlayerData.job.grade_label ~= ESX.PlayerData.job.label and ESX.PlayerData.job.grade_label or ''
		if gradeLabel ~= '' then gradeLabel = ' - '..gradeLabel end

		ESX.UI.HUD.RegisterElement('job', #ESX.PlayerData.accounts, 0, jobTpl, {
			job_label = ESX.PlayerData.job.label,
			grade_label = gradeLabel
		})
	end

	local isDead = false
	local previousCoords = vector3(ESX.PlayerData.coords.x, ESX.PlayerData.coords.y, ESX.PlayerData.coords.z)
	SetInterval(1, 500, function()
		local playerPed = PlayerPedId()
		if ESX.PlayerData.ped ~= playerPed then ESX.SetPlayerData('ped', playerPed) end
		local playerCoords = GetEntityCoords(ESX.PlayerData.ped)

		if not isDead and IsPedFatallyInjured(playerPed) then
			isDead = true

			local killerEntity, deathCause = GetPedSourceOfDeath(playerPed), GetPedCauseOfDeath(playerPed)
			local killerClientId = NetworkGetPlayerIndexFromPed(killerEntity)

			if killerEntity ~= playerPed and killerClientId and NetworkIsPlayerActive(killerClientId) then
				PlayerKilledByPlayer(GetPlayerServerId(killerClientId), killerClientId, deathCause, playerCoords)
			else
				PlayerKilled(deathCause, playerCoords)
			end

		elseif isDead and not IsPedFatallyInjured(playerPed) then
			isDead = false
		end

		if #(playerCoords - previousCoords) > 3 then
			previousCoords = playerCoords
			TriggerServerEvent('esx:updateCoords', {
				x = ESX.Math.Round(playerCoords.x, 1),
				y = ESX.Math.Round(playerCoords.y, 1),
				z = ESX.Math.Round(playerCoords.z, 1),
				heading = ESX.Math.Round(GetEntityHeading(ESX.PlayerData.ped), 1)
			})
		end

	end)
end)

RegisterNetEvent('esx:onPlayerLogout', function()
	ESX.PlayerLoaded = false
	if Config.EnableHud then ESX.UI.HUD.Reset() end
end)

AddEventHandler('esx:onPlayerSpawn', function()
	ESX.SetPlayerData('ped', PlayerPedId())
	ESX.SetPlayerData('dead', false)
end)

AddEventHandler('esx:onPlayerDeath', function()
	ESX.SetPlayerData('ped', PlayerPedId())
	ESX.SetPlayerData('dead', true)
end)

RegisterNetEvent('esx:setAccountMoney', function(account)
	for k,v in ipairs(ESX.PlayerData.accounts) do
		if v.name == account.name then
			ESX.PlayerData.accounts[k] = account
			break
		end
	end
	ESX.SetPlayerData('accounts', ESX.PlayerData.accounts)

	if Config.EnableHud then
		ESX.UI.HUD.UpdateElement('account_' .. account.name, {
			money = ESX.Math.GroupDigits(account.money)
		})
	end
end)

RegisterNetEvent('esx:teleport', function(coords)
	ESX.Game.Teleport(ESX.PlayerData.ped, coords)
end)

RegisterNetEvent('esx:setJob', function(Job)
	if Config.EnableHud then
		local gradeLabel = Job.grade_label ~= Job.label and Job.grade_label or ''
		if gradeLabel ~= '' then gradeLabel = ' - '..gradeLabel end
		ESX.UI.HUD.UpdateElement('job', {
			job_label = Job.label,
			grade_label = gradeLabel
		})
	end
	ESX.SetPlayerData('job', Job)
end)

RegisterNetEvent('esx:spawnVehicle', function(vehicle)
	local model = (type(vehicle) == 'number' and vehicle or GetHashKey(vehicle))

	if IsModelInCdimage(model) then
		local playerCoords, playerHeading = GetEntityCoords(ESX.PlayerData.ped), GetEntityHeading(ESX.PlayerData.ped)

		ESX.Game.SpawnVehicle(model, playerCoords, playerHeading, function(vehicle)
			TaskWarpPedIntoVehicle(ESX.PlayerData.ped, vehicle, -1)
		end)
	else
		TriggerEvent('chat:addMessage', { args = { '^1SYSTEM', 'Invalid vehicle model.' } })
	end
end)

RegisterNetEvent('esx:registerSuggestions', function(registeredCommands)
	for name,command in pairs(registeredCommands) do
		if command.suggestion then
			TriggerEvent('chat:addSuggestion', ('/%s'):format(name), command.suggestion.help, command.suggestion.arguments)
		end
	end
end)

RegisterNetEvent('esx:deleteVehicle', function(radius)
	if radius and tonumber(radius) then
		radius = tonumber(radius) + 0.01
		local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(ESX.PlayerData.ped), radius)

		for k,entity in ipairs(vehicles) do
			local attempt = 0

			while not NetworkHasControlOfEntity(entity) and attempt < 100 and DoesEntityExist(entity) do
				Wait(100)
				NetworkRequestControlOfEntity(entity)
				attempt = attempt + 1
			end

			if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
				ESX.Game.DeleteVehicle(entity)
			end
		end
	else
		local vehicle, attempt = ESX.Game.GetVehicleInDirection(), 0

		if IsPedInAnyVehicle(ESX.PlayerData.ped, true) then
			vehicle = GetVehiclePedIsIn(ESX.PlayerData.ped, false)
		end

		while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
			Wait(100)
			NetworkRequestControlOfEntity(vehicle)
			attempt = attempt + 1
		end

		if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
			ESX.Game.DeleteVehicle(vehicle)
		end
	end
end)

-- Pause menu disables HUD display
if Config.EnableHud then
	CreateThread(function()
		local isPaused = false
		while true do
			Wait(300)

			if IsPauseMenuActive() and not isPaused then
				isPaused = true
				ESX.UI.HUD.SetDisplay(0.0)
			elseif not IsPauseMenuActive() and isPaused then
				isPaused = false
				ESX.UI.HUD.SetDisplay(1.0)
			end
		end
	end)

	AddEventHandler('esx:loadingScreenOff', function()
		ESX.UI.HUD.SetDisplay(1.0)
	end)
end

-- disable wanted level
if not Config.EnableWantedLevel then
	ClearPlayerWantedLevel(PlayerId())
	SetMaxWantedLevel(0)
end