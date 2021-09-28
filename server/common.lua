ESX = {}
Core = {}
Core.Players = {}
Core.UsableItemsCallbacks = {}
Core.ServerCallbacks = {}
Core.TimeoutCount = -1
Core.CancelledTimeouts = {}
Core.Jobs = {}
Core.RegisteredCommands = {}

AddEventHandler('esx:getSharedObject', function(cb)
	cb(ESX)
end)

exports('getSharedObject', function()
	return ESX
end)

Core.LoadJobs = function()
	exports.oxmysql:execute('SELECT * FROM jobs', {}, function(jobs)
		for _, v in pairs(jobs) do
			Core.Jobs[v.name] = v
			Core.Jobs[v.name].grades = {}
		end

		exports.oxmysql:execute('SELECT * FROM job_grades', {}, function(grades)
			for _, v in pairs(grades) do
				if Core.Jobs[v.job_name] then
					Core.Jobs[v.job_name].grades[v.grade] = v
				else
					print(('[^3WARNING^7] Ignoring job grades for ^5"%s"^0 due to missing job'):format(v.job_name))
				end
			end

			for _, v in pairs(Core.Jobs) do
				if ESX.Table.SizeOf(v.grades) == 0 then
					Core.Jobs[v.name] = nil
					print(('[^3WARNING^7] Ignoring job ^5"%s"^0due to no job grades found'):format(v.name))
				end
			end
			print('[^2INFO^7] ESX ^5Legacy^0 initialized')
		end)
	end)
end

RegisterServerEvent('esx:clientLog', function(msg)
	if Config.EnableDebug then
		print(('[^2TRACE^7] %s^7'):format(msg))
	end
end)

RegisterServerEvent('esx:triggerServerCallback', function(name, requestId, ...)
	local source = source

	Core.TriggerServerCallback(name, requestId, source, function(...)
		TriggerClientEvent('esx:serverCallback', source, requestId, ...)
	end, ...)
end)

SetInterval(1, Config.PaycheckInterval, function()
	for _, xPlayer in pairs(Core.Players) do
		local job     = xPlayer.job.grade_name
		local salary  = xPlayer.job.grade_salary
		if salary > 0 then
			if job == 'unemployed' then -- unemployed
				xPlayer.addAccountMoney('bank', salary)
				TriggerClientEvent('esx:showAdvancedNotification', xPlayer.source, _U('bank'), _U('received_paycheck'), _U('received_help', salary), 'CHAR_BANK_MAZE', 9)
			elseif Config.EnableSocietyPayouts then -- possibly a society
				TriggerEvent('esx_society:getSociety', xPlayer.job.name, function (society)
					if society ~= nil then -- verified society
						TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function (account)
							if account.money >= salary then -- does the society money to pay its employees?
								xPlayer.addAccountMoney('bank', salary)
								account.removeMoney(salary)

								TriggerClientEvent('esx:showAdvancedNotification', xPlayer.source, _U('bank'), _U('received_paycheck'), _U('received_salary', salary), 'CHAR_BANK_MAZE', 9)
							else
								TriggerClientEvent('esx:showAdvancedNotification', xPlayer.source, _U('bank'), '', _U('company_nomoney'), 'CHAR_BANK_MAZE', 1)
							end
						end)
					else -- not a society
						xPlayer.addAccountMoney('bank', salary)
						TriggerClientEvent('esx:showAdvancedNotification', xPlayer.source, _U('bank'), _U('received_paycheck'), _U('received_salary', salary), 'CHAR_BANK_MAZE', 9)
					end
				end)
			else -- generic job
				xPlayer.addAccountMoney('bank', salary)
				TriggerClientEvent('esx:showAdvancedNotification', xPlayer.source, _U('bank'), _U('received_paycheck'), _U('received_salary', salary), 'CHAR_BANK_MAZE', 9)
			end
		end
	end
end)

Core.LoadJobs()