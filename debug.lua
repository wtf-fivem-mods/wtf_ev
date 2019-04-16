if Config.Debug then
    --- Set fuel in chat
    -- /fuel <0.100>
    RegisterCommand('fuel', function(_, args, _)
        local level = args[1]
        local vehicle = GetPlayersLastVehicle()
        if vehicle then
            SetVehicleFuelLevel(vehicle, level / 1.0) -- needs to be float
        end
    end)

    --- Spawns teslax for testing
    -- Requires wtf_teslax resource to be installed and started
    RegisterCommand('teslax', function()
        local modelHash = GetHashKey('teslax')
        RequestModel(modelHash)
        Citizen.CreateThread(function()
            local t = 0
            while not HasModelLoaded(modelHash) do
                Citizen.Wait(100)
                t = t + 100
                if t > 5000 then
                    SetNotificationTextEntry("STRING")
                    AddTextComponentSubstringPlayerName("/teslax failed. The resource must be installed and started.")
                    DrawNotification(false, false)
                    break
                end
            end
            local ped = GetPlayerPed(-1)
            local vehicle = CreateVehicle(modelHash, GetEntityCoords(ped), GetEntityHeading(ped), 1, 0)
            SetVehicleOnGroundProperly(vehicle)
            SetPedIntoVehicle(ped, vehicle, -1)
            SetModelAsNoLongerNeeded(modelHash)
        end)
    end)
end