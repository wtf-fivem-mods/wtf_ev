local storedCars = {}

local function saveStoredCar(ped, garage, vehicle)
    if storedCars[ped] == nil then
        storedCars[ped] = {}
    end
    storedCars[ped][garage.Name] = {
        timeStored = GetEpoch(),
        level = GetVehicleFuelLevel(vehicle),
        plate = GetVehicleNumberPlateText(vehicle),
        modelHash = GetHashKey(GetVehicleDisplayName(vehicle))
    }
end

local function hasAnyCarsStored(ped)
    return storedCars[ped] ~= nil
end

local function hasCarStored(ped, garage)
    if storedCars[ped] == nil then
        return false
    end
    return storedCars[ped][garage.Name] ~= nil
end

local function loadSavedCar(ped, garage)
    if not hasCarStored(ped, garage) then
        return nil
    end
    return storedCars[ped][garage.Name]
end

local function deleteSavedCar(ped, garage)
    if not hasCarStored(ped, garage) then
        return
    end
    storedCars[ped][garage.Name] = nil
end

local function applyCharge(prevLevel, timeStored, maxT)
    local ttc = GetChargeTimeForLevel(prevLevel, maxT)
    local timeCharging = GetEpoch() - timeStored
    local t = (ttc + timeCharging) / maxT
    t = math.max(0, math.min(1, t)) -- clamp to sane values
    local pctCharge = ChargeRateFn(t)
    local level = pctCharge * 100.0
    level = math.max(0.0, math.min(100.0, level)) -- clamp to sane value
    return level / 1.0 -- must be float
end

local function runGarageRetrieval(ped, garage, stop)
    Citizen.Wait(1)
    if not hasCarStored(ped, garage) or IsPedInAnyVehicle(ped) then
        return stop()
    end
    local coords = GetEntityCoords(ped)
    local gcoords = garage.In
    local distance = GetDistanceBetweenCoords(coords, gcoords, true)
    if distance >= Config.GarageMarkerDistance then
        return stop()
    end

    DrawMarker(1, gcoords, 0.0, 0.0, 0.0,
                0, 0.0, 0.0, 3.0, 3.0, 1.0, 0, 0, 255, 100, false, true, 2, false, false, false, false)

    if distance < 3 then
        SetTextComponentFormat('STRING')
        AddTextComponentString('Press ~INPUT_PICKUP~ pull out your car')
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)

        if IsControlJustReleased(0, Keys.E) then
            local data = loadSavedCar(ped, garage)
            RequestModel(data.modelHash)
            while not HasModelLoaded(data.modelHash) do
                Citizen.Wait(0)
            end

            local vehicle = CreateVehicle(data.modelHash, garage.Out, garage.OutHdg, true, false)
            SetVehicleNumberPlateText(data.plate)
            SetVehicleOnGroundProperly(vehicle)
            SetPedIntoVehicle(ped, vehicle, -1)

            local newLevel = applyCharge(data.level, data.timeStored, garage.ChargeRate)
            SetVehicleFuelLevel(vehicle, newLevel)

            SetModelAsNoLongerNeeded(data.modelHash)
            deleteSavedCar(ped, garage)

            return stop()
        end
    end
end

local function runGarageStorage(ped, garage, stop)
    Citizen.Wait(1)
    if not IsPedInAnyEVVehicle(ped) or not IsPedDriving(ped) then
        return stop()
    end
    local coords = GetEntityCoords(ped)
    local gcoords = garage.In
    local distance = GetDistanceBetweenCoords(coords, gcoords, true)
    if distance >= Config.GarageMarkerDistance then
        return stop()
    end
    local r, g, b = 0, 255, 0
    if hasCarStored(ped, garage) then
        r, g, b = 255, 0, 0
    end
    DrawMarker(1, gcoords, 0.0, 0.0, 0.0,
                0, 0.0, 0.0, 3.0, 3.0, 1.0, r, g, b, 100, false, true, 2, false, false, false, false)
    if distance < 3 then
        if hasCarStored(ped, garage) then
            DrawText3Ds(gcoords.x, gcoords.y, gcoords.z + 1.0, "Your garage is ~r~full~w~!")
            return
        end

        SetTextComponentFormat('STRING')
        AddTextComponentString('Press ~INPUT_PICKUP~ store your car')
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)

        DrawText3Ds(gcoords.x, gcoords.y, gcoords.z + 1.0, "Your car will ~g~charge ~w~while stored at this garage.")

        if IsControlJustReleased(0, Keys.E) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            saveStoredCar(ped, garage, vehicle)
            SetEntityAsMissionEntity(vehicle, false, true)
            DeleteVehicle(vehicle)
        end
    end
end

SIThreads:LoopUntilStopped('DEMO_GARAGE_MAIN', function(_) -- we can't stop and we won't stop
    Citizen.Wait(1500)
    local ped = GetPlayerPed(-1)

    -- handle storing of cars
    if IsPedInAnyEVVehicle(ped) and IsPedDriving(ped) then
        local coords = GetEntityCoords(ped)
        for _, garage in ipairs(Config.DemoGarages) do
            local distance = GetDistanceBetweenCoords(coords, garage.In, true)
            if distance <= Config.GarageMarkerDistance then
                SIThreads:LoopUntilStopped(string.format('GARAGE_%s', garage.Name),
                    function(stop) runGarageStorage(ped, garage, stop) end)
            end
        end
    end

    -- handle retrieving of cars
    if hasAnyCarsStored(ped) and not IsPedInAnyVehicle(ped) then
        local coords = GetEntityCoords(ped)
        for _, garage in ipairs(Config.DemoGarages) do
            local distance = GetDistanceBetweenCoords(coords, garage.In, true)
            if distance <= Config.GarageMarkerDistance then
                if hasCarStored(ped, garage) then
                    SIThreads:LoopUntilStopped(string.format('GARAGE_%s', garage.Name),
                        function(stop) runGarageRetrieval(ped, garage, stop) end)
                end
            end
        end
    end
end)

-- Create Blips
if Config.EnableGarageBlips then
    for _, garage in ipairs(Config.DemoGarages) do
        local v = garage.In
        local blip = AddBlipForCoord(v.x, v.y, v.z)

        SetBlipSprite(blip, 267)
        SetBlipScale(blip, 0.9)
        SetBlipColour(blip, 75)
        SetBlipDisplay(blip, 6)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(garage.Name)
        EndTextCommandSetBlipName(blip)
    end
end