ESX = exports['es_extended']:getSharedObject()

local isRobberyActive = false
local collectedPoints = {}

-----------------
---DISCORD LOG---
-----------------
function SendDiscordMessage(title, description)
    local webhookURL = Config.Webhook
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = 3447003, 
            ["footer"] = {
                ["text"] = "HW Scripts | Jewelry Robbery",
                -- ["icon_url"] = "URL_TO_AN_ICON"
            }
        }}
    }

    PerformHttpRequest(webhookURL, function(err, text, headers)
        if err then
            print("^0[^1DEBUG^0] ^5Discord log sent ^2successfully!^0")
        else
            print("^0[^1DEBUG^0] ^5Discord log sent ^2successfully!^0")
        end
    end, 'POST', json.encode(data), {['Content-Type'] = 'application/json'})
end

local function debugPrint(message)
    if Config.Mode == 'debug' then 
        print('^0[^1DEBUG^0] ^5' .. message) 
    end
end

-----------------
--START ROBBERY--
-----------------
RegisterServerEvent('hw_jewelry:startRobbery')
AddEventHandler('hw_jewelry:startRobbery', function()
    local _source = source
    debugPrint("Received 'hw_jewelry:startRobbery' event from player ^3" .. _source)

    if isRobberyActive then
        TriggerClientEvent('esx:showNotification', _source, '~y~A robbery is already in progress.')
        debugPrint("Robbery already in ^3progress^0, notifying player ^3" .. _source)
        return
    end

    local hasRequiredWeapons = false

    for _, requiredItem in ipairs(Config.Weapons) do
        local itemCount = exports.ox_inventory:GetItem(_source, requiredItem, nil, true)
        
        if itemCount and itemCount > 0 then
            hasRequiredWeapons = true
            debugPrint("Player ^3" .. _source .. "^5 has required weapon: ^3" .. requiredItem)
            break 
        end
    end

    if not hasRequiredWeapons then
        TriggerClientEvent('esx:showNotification', _source, "~r~You need the required weapons to start the robbery.")
        debugPrint("Player ^3" .. _source .. " ^5does ^1not ^5have required weapons, sended notify to player.")
        return
    end

    isRobberyActive = true
    local robberyStartTime = os.time()
    collectedPoints[_source] = {}

    TriggerClientEvent('esx:showNotification', _source, "~g~Robbery started, hurry up!")
    TriggerClientEvent('esx:showNotification', _source, "~r~Wait for 15 minutes! ~y~Otherwise you won't receive bonus payout!")
    
    Citizen.SetTimeout(10000, function()
        NotifyPolice()
    end)
    Citizen.SetTimeout(900000, function() 
        TriggerEvent('hw_jewelry:endRobbery', _source)
    end)

    local playerName = GetPlayerName(_source)
    SendDiscordMessage("Robbery Started", "Robbery started by: " .. playerName)
    debugPrint("Robbery ^2started ^5by player ^3" .. _source .. "^5 at ^3" .. os.date("%c", robberyStartTime))
end)

------------------
---ITEM COLLECT---
------------------
RegisterServerEvent('hw_jewelry:collectItem')
AddEventHandler('hw_jewelry:collectItem', function(pointIndex)
    local _source = source
    debugPrint("Received 'hw_jewelry:collectItem' event from player ^3" .. _source .. "^5 for point index ^3" .. pointIndex)

    if not isRobberyActive then
        TriggerClientEvent('esx:showNotification', _source, "~r~There's no active robbery.")
        debugPrint("Player " .. _source .. " attempted to collect item, but there's no active robbery.")
        return
    end

    collectedPoints[_source] = collectedPoints[_source] or {}
    if collectedPoints[_source][pointIndex] then
        TriggerClientEvent('esx:showNotification', _source, "~y~You've already collected from this point.")
        debugPrint("Player " .. _source .. " attempted to collect from already collected point " .. pointIndex)
        return
    end

    collectedPoints[_source][pointIndex] = true
    TriggerClientEvent('hw_jewelry:startMechanicEmote', _source, pointIndex) 

    local xPlayer = ESX.GetPlayerFromId(_source)
    if xPlayer then
        local item = Config.RewardItems[math.random(#Config.RewardItems)]
        local amount = math.random(1, 5)
        Citizen.Wait(5000)
        xPlayer.addInventoryItem(item, amount)
        TriggerClientEvent('esx:showNotification', _source, '~y~You ~g~succesfully ~y~collected item(s).')
        SendDiscordMessage("Reward Collect", "Player " .. _source .. " collected: " .. item .. " x" .. amount .. " from a collection point!")
        debugPrint("Player ^3" .. _source .. "^5 collected reward: ^3" .. item .. " ^3x" .. amount .. "^5 from point ^3" .. pointIndex)
    else
        print("^0[^1DEBUG^0] ^1Error: Player not found while trying to add item to inventory.")
    end
end)

---------------
-----EMOTE-----
---------------
RegisterServerEvent('hw_jewelry:startMechanicEmote')
AddEventHandler('hw_jewelry:startMechanicEmote', function(pointIndex)
    local _source = source
    local playerPed = GetPlayerPed(_source)
    if playerPed then
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)
        Citizen.Wait(5000)
        ClearPedTasks(playerPed)
        TriggerServerEvent('hw_jewelry:rewardItem', pointIndex)
    else
        print("^0[^1DEBUG^0] ^1Error: Player ped not found while trying to start mechanic emote.")
    end
end)


-----------------
---END ROBBERY---
-----------------
RegisterServerEvent('hw_jewelry:endRobbery')
AddEventHandler('hw_jewelry:endRobbery', function(source)
    local _source = source
    debugPrint("Received 'hw_jewelry:endRobbery' event from player " .. _source)

    if not isRobberyActive then 
        debugPrint("No active robbery to end.")
        return 
    end

    local elapsedTime = os.time() - robberyStartTime
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        if elapsedTime >= Config.RobberyDuration[Config.Mode] then 
            xPlayer.addAccountMoney('black_money', Config.Payout)
            TriggerClientEvent('esx:showNotification', _source, "~g~Robbery completed. ~y~You received $" .. Config.Payout .. " in black money.")
            SendDiscordMessage("Final Payout", "Player " .. _source .. " collected " .. Config.Payout .. " as final payout from the robbery")
            debugPrint("Robbery ^3completed successfully ^5for player ^3" .. _source .. "^5. Payout: ^3$" .. Config.Payout)
        else
            TriggerClientEvent('esx:showNotification', _source, "~r~Robbery ended too early, no payout.")
            debugPrint("Robbery ^1ended ^5too early for player ^3" .. _source .. "^5, ^1no ^5payout has been given.")
        end
    else
        print("^0[^1DEBUG^0] ^1Error: Player not found while trying to end robbery.")
    end

    isRobberyActive = false
    collectedPoints = {} 
    SendDiscordMessage("Robbery Ended", "Robbery has been concluded.")
    debugPrint("Robbery ^1ended ^5and data reset.")
end)


----------------
-----Alert------
----------------
function NotifyPolice()
    if Config.Mode == 'test' then
        debugPrint("Police notification ^2skipped ^5in ^3test mode.^5")
        return
    end

    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer.job and table.includes(Config.PoliceJobs, xPlayer.job.name) then
            TriggerClientEvent('esx:showNotification', playerId, '~r~Robbery in progress at the ~y~Jewelry Store!')
            TriggerClientEvent('hw_jewelry:createPoliceBlip', playerId, Config.StartLocation)
        end
    end
end

function table.includes(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

----------------
----COMMAND-----
----------------
RegisterCommand('startrobbery', function(source, args, rawCommand)
    local _source = source
    if Config.Mode == 'test' then
        TriggerEvent('hw_jewelry:startRobbery', _source)
        TriggerClientEvent('esx:showNotification', _source, '~y~You started the robbery as ~g~admin!')
        TriggerClientEvent('esx:showNotification', _source, '~r~Keep in mind test mode is on!')
    else
        TriggerClientEvent('chat:addMessage', _source, { args = { '^1[SYSTEM]', 'You can only start the robbery remotely in test mode.' } })
        TriggerClientEvent('esx:showNotification', _source, '~y~Test mode is ~r~NOT ~y~enabled! Please change mode to ~g~"test"')
        TriggerClientEvent('esx:showNotification', _source, '~y~You can only start the robbery remotely in ~g~test mode.')
    end
end, true)