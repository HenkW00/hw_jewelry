ESX = exports['es_extended']:getSharedObject()

local isRobberyActive = false
local collectedPoints = {}

function SendDiscordMessage(title, description)
    local webhookURL = Config.Webhook
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = 3447003, 
            ["footer"] = {
                ["text"] = "Robbery Event Log",
                -- ["icon_url"] = "URL_TO_AN_ICON"
            }
        }}
    }

    PerformHttpRequest(webhookURL, function(err, text, headers)
        if err then
            print("^0[^1DEBUG^0] ^5Succesfully sended log to discord!")
        else
            print("^0[^1DEBUG^0] Discord message sent successfully!")
        end
    end, 'POST', json.encode(data), {['Content-Type'] = 'application/json'})
end

local function debugPrint(message)
    if Config.Mode == 'debug' then 
        print('^0[^1DEBUG^0] ^5' .. message) 
    end
end

RegisterServerEvent('hw_jewelry:startRobbery')
AddEventHandler('hw_jewelry:startRobbery', function()
    local _source = source
    debugPrint("Received 'hw_jewelry:startRobbery' event from player " .. _source)

    if isRobberyActive then
        TriggerClientEvent('esx:showNotification', _source, 'A robbery is already in progress.')
        debugPrint("Robbery already in progress, notifying player " .. _source)
        return
    end

    local hasRequiredWeapons = false

    for _, requiredItem in ipairs(Config.Weapons) do
        local itemCount = exports.ox_inventory:GetItem(_source, requiredItem, nil, true)
        
        if itemCount and itemCount > 0 then
            hasRequiredWeapons = true
            debugPrint("Player " .. _source .. " has required weapon: " .. requiredItem)
            break 
        end
    end

    if not hasRequiredWeapons then
        TriggerClientEvent('esx:showNotification', _source, "You need the required weapons to start the robbery.")
        debugPrint("Player " .. _source .. " does not have required weapons, notifying.")
        return
    end

    isRobberyActive = true
    robberyStartTime = os.time()
    collectedPoints[_source] = {}

    TriggerClientEvent('esx:showNotification', _source, "Robbery started, hurry up!")
    TriggerClientEvent('esx:showNotification', _source, "Wait for 15 minutes! Otherwise u wont receive bonus payout!")
    
    Citizen.SetTimeout(10000, function()
        NotifyPolice()
    end)
    Citizen.SetTimeout(900000, function() 
        TriggerEvent('hw_jewelry:endRobbery', _source)
    end)

    SendDiscordMessage("Robbery Started", "Robbery started by: " .. GetPlayerIdentifiers(_source)[1])
    debugPrint("Robbery started by player " .. _source .. " at " .. os.date("%c", robberyStartTime))
end)

RegisterServerEvent('hw_jewelry:collectItem')
AddEventHandler('hw_jewelry:collectItem', function(pointIndex)
    local _source = source
    debugPrint("Received 'hw_jewelry:collectItem' event from player " .. _source .. " for point index " .. pointIndex)

    if not isRobberyActive then
        TriggerClientEvent('esx:showNotification', _source, "There's no active robbery.")
        debugPrint("Player " .. _source .. " attempted to collect item, but there's no active robbery.")
        return
    end

    if collectedPoints[_source] and collectedPoints[_source][pointIndex] then
        TriggerClientEvent('esx:showNotification', _source, "You've already collected from this point.")
        debugPrint("Player " .. _source .. " attempted to collect from already collected point " .. pointIndex)
        return
    end

    collectedPoints[_source][pointIndex] = true
    TriggerClientEvent('hw_jewelry:startMechanicEmote', _source, pointIndex) 

    local playerId = source
    local identifier = ESX.GetPlayerFromId(playerId).identifier
end)

RegisterServerEvent('hw_jewelry:rewardItem')
AddEventHandler('hw_jewelry:rewardItem', function(pointIndex)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local item = Config.RewardItems[math.random(#Config.RewardItems)]
    local amount = math.random(1, 5)
    xPlayer.addInventoryItem(item, amount)
    SendDiscordMessage("Reward Collect", "Player " .. _source .. " collected: " .. item .. " x" .. amount .. " from a collection point!")
    debugPrint("Player " .. _source .. " collected reward: " .. item .. " x" .. amount .. " from point " .. pointIndex)
end)

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

    if elapsedTime >= 900 then 
        xPlayer.addAccountMoney('black_money', Config.Payout)
        TriggerClientEvent('esx:showNotification', _source, "Robbery completed. You received $" .. Config.Payout .. " in black money.")
        SendDiscordMessage("Final Payout", "Player " .. _source .. " collected " .. Config.Payout .. " as final payout from the robbery")
        debugPrint("Robbery completed successfully for player " .. _source .. ". Payout: $" .. Config.Payout)
    else
        TriggerClientEvent('esx:showNotification', _source, "Robbery ended too early, no payout.")
        debugPrint("Robbery ended too early for player " .. _source .. ", no payout.")
    end

    isRobberyActive = false
    robberyStartTime = nil
    collectedPoints = {} 
    SendDiscordMessage("Robbery Ended", "Robbery has been concluded.")
    debugPrint("Robbery ended and data reset.")
end)

function NotifyPolice()
    if Config.Mode == 'test' then
        debugPrint("Police notification skipped in test mode.")
        return
    end

    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer.job and table.includes(Config.PoliceJobs, xPlayer.job.name) then
            TriggerClientEvent('esx:showNotification', playerId, 'Robbery in progress at the Jewelry Store!')
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

RegisterCommand('startrobbery', function(source, args, rawCommand)
    local _source = source
    if Config.Mode == 'test' then
        TriggerEvent('hw_jewelry:startRobbery', _source)
        TriggerClientEvent('esx:showNotification', _source, 'You started the robbery as admin!')
        TriggerClientEvent('esx:showNotification', _source, 'Keep in mind test mode is on!')
    else
        TriggerClientEvent('chat:addMessage', _source, { args = { '^1[SYSTEM]', 'You can only start the robbery remotely in test mode.' } })
    end
end, true)
