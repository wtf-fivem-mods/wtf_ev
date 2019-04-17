local DB = Config.Garage.DB

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

local function loopFullGarage(ped, garage, stop)
    Citizen.Wait(1)
    local coords = GetEntityCoords(ped)
    local gcoords = garage.In
    local distance = GetDistanceBetweenCoords(coords, gcoords, true)
    if distance >= Config.GarageMarkerDistance then
        return stop()
    end

    local isDriving = IsPedDriving(ped)
    if isDriving and not IsPedInAnyEVVehicle(ped) then
        return stop()
    end

    local r, g, b = 0, 0, 255
    if isDriving then
        r, g, b = 255, 0, 0
    end

    DrawMarker(1, gcoords, 0.0, 0.0, 0.0,
                0, 0.0, 0.0, 3.0, 3.0, 1.0, r, g, b, 100, false, true, 2, false, false, false, false)

    if distance < 3 then
        if isDriving then
            DrawText3Ds(gcoords.x, gcoords.y, gcoords.z + 1.0, "Your garage is ~r~full~w~!")
            return
        end

        SetTextComponentFormat('STRING')
        AddTextComponentString('Press ~INPUT_PICKUP~ pull out your car')
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)

        if IsControlJustReleased(0, Keys.E) then
            local data = DB:loadSavedCar(ped, garage)
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
            DB:deleteSavedCar(ped, garage)

            return stop()
        end
    end
end

local function loopAvailableGarage(ped, garage, stop)
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
    DrawMarker(1, gcoords, 0.0, 0.0, 0.0,
                0, 0.0, 0.0, 3.0, 3.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)
    if distance < 3 then
        SetTextComponentFormat('STRING')
        AddTextComponentString('Press ~INPUT_PICKUP~ store your car')
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)

        DrawText3Ds(gcoords.x, gcoords.y, gcoords.z + 1.0, "Your car will ~g~charge ~w~while stored at this garage.")

        if IsControlJustReleased(0, Keys.E) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            DB:saveStoredCar(ped, garage, vehicle)
            SetEntityAsMissionEntity(vehicle, false, true)
            DeleteVehicle(vehicle)
        end
    end
end

SIThreads:LoopUntilStopped('DEMO_GARAGE_MAIN', function(_) -- we can't stop and we won't stop
    Citizen.Wait(1500)
    local ped = GetPlayerPed(-1)

    local coords = GetEntityCoords(ped)
    for _, garage in ipairs(Config.DemoGarages) do
        local distance = GetDistanceBetweenCoords(coords, garage.In, true)
        if distance <= Config.GarageMarkerDistance then
            local isDriving = IsPedDriving(ped)
            local inEv = IsPedInAnyEVVehicle(ped)
            if DB:hasCarStored(ped, garage) and (not isDriving or isDriving and inEv) then
                SIThreads:LoopUntilStopped(string.format('GARAGE_%s', garage.Name),
                    function(stop) loopFullGarage(ped, garage, stop) end)
            elseif isDriving and inEv then
                SIThreads:LoopUntilStopped(string.format('GARAGE_%s', garage.Name),
                    function(stop) loopAvailableGarage(ped, garage, stop) end)
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