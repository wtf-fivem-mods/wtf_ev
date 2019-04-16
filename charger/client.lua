-- using stt_prop_stunt_bowling_pin model as superchargers
local superchargerHash = 1467552538

local function chargingLoop(ped, vehicle, vcoords, cscoords)
    local level = GetVehicleFuelLevel(vehicle)

    if level >= 100.0 then
        SIThreads:LoopForDuration('SS_EV_TEXT_ALREADY_CHARGED', 3000, function()
            Citizen.Wait(1)
            DrawText3Ds(cscoords.x, cscoords.y, cscoords.z + 1.0, "Vehicle already charged!")
        end)
        return
    end

    ClearPedTasksImmediately(ped)

    FreezeEntityPosition(ped, true)
    FreezeEntityPosition(vehicle, false)
    SetVehicleEngineOn(vehicle, false, false, false)

    -- put any weapon away
    if GetSelectedPedWeapon(ped) ~= -1569615261 then
        SetCurrentPedWeapon(ped, -1569615261, true)
        Citizen.Wait(1000)
    end

    LoadAnimDict("timetable@gardener@filling_can")
    TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 1.0, 2, -1, 49, 0, 0, 0, 0)

    local ttc = GetChargeTimeForLevel(level, Config.SuperchargerChargeRate)
    local chargeStartTime = GetEpoch()
    local chargeWait = NewInlineWait()
    Citizen.Wait(1000) -- wait a little to starting charge

    while true do
        Citizen.Wait(1)
        chargeWait.Tick()

        DisableCtrlActions()

        -- add charge
        chargeWait.Wait(100, function()
            local timeCharging = GetEpoch() - chargeStartTime
            local t = (ttc + timeCharging) / Config.SuperchargerChargeRate
            t = math.max(0, math.min(1, t)) -- clamp to sane values
            local pctCharge = ChargeRateFn(t)
            level = pctCharge * 100.0
            level = math.max(0.0, math.min(100.0, level)) -- clamp to sane value
            SetVehicleFuelLevel(vehicle, level / 1.0) -- must be float
        end)

        if level == 100 then
            ClearPedTasksImmediately(ped)
            FreezeEntityPosition(ped, false)
            FreezeEntityPosition(vehicle, false)
            break
        end

        DrawText3Ds(cscoords.x, cscoords.y, cscoords.z + 1.0, "Press ~g~G ~w~to stop charging your vehicle.")
        local r, g, b = GetGreenToRedRGB(level/100.0)
        DrawText3Ds(vcoords.x, vcoords.y, vcoords.z + 1.5, string.format('%.2f', level) .. "%", r, g, b)

        if IsControlJustReleased(0, Keys.G) then
            LoadAnimDict("reaction@male_stand@small_intro@forward")
            TaskPlayAnim(GetPlayerPed(-1), "reaction@male_stand@small_intro@forward",
                "react_forward_small_intro_a", 1.0, 2, -1, 49, 0, 0, 0, 0)
            Citizen.Wait(2500)
            ClearPedTasksImmediately(ped)
            FreezeEntityPosition(ped, false)
            FreezeEntityPosition(vehicle, false)
            break
        end
    end

    return
end

local function runChargingStation(ped, cscoords, stop)
    Citizen.Wait(1)

    if not IsPedInAnyEVVehicle(ped) and not IsPlayersLastVehicleEV() then
        return stop()
    end

    local coords = GetEntityCoords(ped)
    local distance = GetDistanceBetweenCoords(coords, cscoords, true)
    if distance > Config.SuperchargerDrawDistance then
        return stop()
    end

    DrawMarker(1, cscoords, 0.0, 0.0, 0.0,
                0, 0.0, 0.0, 3.0, 3.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)

    if distance > 3 then
        return -- continue looping
    end

    -- show exit vehicle message if in car at charging station
    if IsPedInAnyEVVehicle(ped) then
        SetTextComponentFormat('STRING')
        AddTextComponentString('Exit vehicle to charge')
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
        return -- continue looping
    end

    local vehicle = GetPlayersLastVehicle()
    local vcoords = GetEntityCoords(vehicle)
    local vdistance = GetDistanceBetweenCoords(coords, vcoords, true)
    if vdistance < 3 then
        SetTextComponentFormat('STRING')
        AddTextComponentString('Press ~INPUT_PICKUP~ to start charging')
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)

        if IsControlJustReleased(0, Keys.E) then
            chargingLoop(ped, vehicle, vcoords, cscoords)
        end
    else
        SetTextComponentFormat('STRING')
        AddTextComponentString('Your car is too far away from the charger')
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
    end
end

-- Looping thread: Detect when near supercharger
SIThreads:LoopUntilStopped('CHARGER_MAIN', function(_) -- we can't stop and we won't stop
    Citizen.Wait(1500)

    local ped = GetPlayerPed(-1)
    local coords = GetEntityCoords(ped)

    local charger = GetClosestObjectOfType(coords, Config.SuperchargerDrawDistance, superchargerHash, false, false)
    if charger == nil or charger == 0 then
        return
    end

    local cscoords = GetEntityCoords(charger)
    if IsPedInAnyEVVehicle(ped) or IsPlayersLastVehicleEV() then
        SIThreads:LoopUntilStopped(string.format('CHARGER_%s', tostring(cscoords)),
            function(stop) runChargingStation(ped, cscoords, stop) end)
    end
end)

-- Create Blips
if Config.EnableChargerBlips then
    for _, v in ipairs(Config.SuperchargerStations) do
        local blip = AddBlipForCoord(v.x, v.y, v.z)

        SetBlipSprite(blip, 354)
        SetBlipScale(blip, 1.5)
        SetBlipColour(blip, 75)
        SetBlipDisplay(blip, 6)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Supercharger")
        EndTextCommandSetBlipName(blip)
    end
end