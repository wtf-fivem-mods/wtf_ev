local function runHUD(vehicle, stop)
    Citizen.Wait(1)
    if not IsEV(GetVehicleDisplayName(vehicle)) then
        return stop()
    end

    local rpm = GetVehicleCurrentRpm(vehicle)
    local whr = math.ceil(math.max(0, (965 * rpm) - 195))

    DrawRct(UI.x + 0.03, UI.y + 0.932, 0.046,0.03,0,0,0,150)
    DrawTxt(UI.x + 0.53, UI.y + 1.42, 1.0,1.0,0.64, "~w~" .. whr, 255, 255, 255, 255)
    DrawTxt(UI.x + 0.555, UI.y + 1.4315, 1.0,1.0,0.4, "~w~ Whr", 255, 255, 255, 255)
end

-- Vehicle detection thread
SIThreads:LoopUntilStopped('HUD_MAIN', function(_) -- we can't stop and we won't stop
    Citizen.Wait(1000)
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
    if IsEV(GetVehicleDisplayName(vehicle)) then
        SIThreads:LoopUntilStopped('HUD_DRAW', function(stop) runHUD(vehicle, stop) end)
    end
end)