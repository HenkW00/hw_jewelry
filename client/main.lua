ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

-------------------
---START ROBBERY---
-------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distToStart = GetDistanceBetweenCoords(playerCoords, Config.StartLocation.x, Config.StartLocation.y, Config.StartLocation.z, true)

        if distToStart < 10 then
            DrawMarker(1, Config.StartLocation.x, Config.StartLocation.y, Config.StartLocation.z - 1.0, 0, 0, 0, 0, 0, 0, 2.0, 2.0, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
            if distToStart < 2 then
                ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to start the robbery")
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('hw_jewelry:startRobbery')
                end
            end
        end        

        for index, point in ipairs(Config.RobPoints) do
            local distToPoint = GetDistanceBetweenCoords(playerCoords, point.x, point.y, point.z, true)
            if distToPoint < 1.0 then
                DrawText3D(point.x, point.y, point.z, "~r~Press E to collect")
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('hw_jewelry:collectItem', index)
                end
            end
        end
    end
end)

-----------------
---START EMOTE---
-----------------
RegisterNetEvent('hw_jewelry:startMechanicEmote')
AddEventHandler('hw_jewelry:startMechanicEmote', function()
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)
    Citizen.Wait(5000)
    ClearPedTasks(playerPed)
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-----------------
---POLICE BLIP---
-----------------
RegisterNetEvent('hw_jewelry:createPoliceBlip')
AddEventHandler('hw_jewelry:createPoliceBlip', function(location)
    local blip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Robbery')
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip, false)
    Citizen.SetTimeout(30000, function() 
        RemoveBlip(blip)
    end)
end)
