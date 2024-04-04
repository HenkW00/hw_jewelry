ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

local isRobbing = false
local startTime = 0
local robberyDuration = Config.Time * 60000

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
            if distToStart < 2 and not isRobbing then
                ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to start the robbery")
                if IsControlJustReleased(0, 38) then 
                    ESX.TriggerServerCallback('hw_jewelry:checkPoliceCount', function(canRob)
                        if canRob then
                            isRobbing = true
                            startTime = GetGameTimer()
                            TriggerServerEvent('hw_jewelry:startRobbery')
                        else
                            ESX.ShowNotification("Not enough police online to start the robbery.")
                        end
                    end)
                end
            end
        end        

        if isRobbing then
            local currentTime = GetGameTimer()
            local elapsedTime = currentTime - startTime
            if elapsedTime < robberyDuration then
                local remainingTime = math.floor((robberyDuration - elapsedTime) / 1000)
                local mins = math.floor(remainingTime / 60)
                local secs = remainingTime % 60
                DrawHUDText(string.format("~r~Time left: %02d:%02d", mins, secs), 0.5, 0.05)
            else
                isRobbing = false
                ESX.ShowNotification("Robbery completed")
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
----DRAW TEXT----
-----------------
function DrawHUDText(text, x, y)
    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end


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

-----------------
----DRAW TEXT----
-----------------
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
    AddTextComponentString('Jewelry Robbery In Progress')
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip, false)
    Citizen.SetTimeout(90000, function() 
        RemoveBlip(blip)
    end)
end)

