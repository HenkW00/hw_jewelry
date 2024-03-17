ESX = exports['es_extended']:getSharedObject()

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

    PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode(data), {['Content-Type'] = 'application/json'})
end


local isRobberyActive = false
local robberyStartTime = nil
local collectedPoints = {}

RegisterServerEvent('hw_jewelry:startRobbery')
AddEventHandler('hw_jewelry:startRobbery', function()
    local _source = source
    if isRobberyActive then
        TriggerClientEvent('esx:showNotification', _source, 'A robbery is already in progress.')
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

    local playerId = source
    local identifier = ESX.GetPlayerFromId(playerId).identifier
    SendDiscordMessage("Robbery Started", "Robbery started by: " .. identifier)
end)

RegisterServerEvent('hw_jewelry:collectItem')
AddEventHandler('hw_jewelry:collectItem', function(pointIndex)
    local _source = source

    if not isRobberyActive then
        TriggerClientEvent('esx:showNotification', _source, "There's no active robbery.")
        return
    end

    if collectedPoints[_source] and collectedPoints[_source][pointIndex] then
        TriggerClientEvent('esx:showNotification', _source, "You've already collected from this point.")
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
end)

RegisterServerEvent('hw_jewelry:endRobbery')
AddEventHandler('hw_jewelry:endRobbery', function(source)
    if not isRobberyActive then return end 

    local _source = source
    local elapsedTime = os.time() - robberyStartTime
    local xPlayer = ESX.GetPlayerFromId(_source)

    if elapsedTime >= 900 then 
        xPlayer.addAccountMoney('black_money', Config.Payout)
        TriggerClientEvent('esx:showNotification', _source, "Robbery completed. You received $" .. Config.Payout .. " in black money.")
        SendDiscordMessage("Final Payout", "Player " .. _source .. " collected " .. Config.Payout .. " as final payout from the robbery")
    else
        TriggerClientEvent('esx:showNotification', _source, "Robbery ended too early, no payout.")
    end

 
    isRobberyActive = false
    robberyStartTime = nil
    collectedPoints = {} 
    SendDiscordMessage("Robbery Ended", "Robbery has been concluded.")
end)

function NotifyPolice()
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
