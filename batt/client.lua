local function runFuelMonitor(stop)
    local totalRPM = 0
    local lastEpoch = GetEpoch()
    local vehicle = GetPlayersLastVehicle()
    local inlineWait = NewInlineWait()

    while true do
        Citizen.Wait(1)
        inlineWait.Tick()

        if not IsPedInAnyEVVehicle() or not IsPedDriving() then
            return stop() -- stop thread
        end

        -- draw hud
        local level = GetVehicleFuelLevel(vehicle)
        local r, g, b = GetGreenToRedRGB(level/100.0)
        DrawTxt(UI.x + 0.53, UI.y + 1.394, 1.0,1.0,0.50, string.format('%.1f %%', level), r, g, b, 255)

        -- track avg rpm, uses an n-samples avg
        local rpm = GetVehicleCurrentRpm(vehicle)
        totalRPM = totalRPM + rpm

        -- update "fuel" level
        inlineWait.Wait(Config.LevelSamples, function()
            local now = GetEpoch()
            local nsecs = now - lastEpoch
            lastEpoch = now
            if level > 0 then
                local avgrpm = totalRPM / Config.LevelSamples
                totalRPM = 0
                local avgEnergy
                if avgrpm <= 0.25 then avgEnergy = 0.08 -- don't penalize idle
                elseif avgrpm <= 0.35 then avgEnergy = avgrpm * 0.40
                elseif avgrpm <= 0.55 then avgEnergy = avgrpm * 0.45
                elseif avgrpm <= 0.70 then avgEnergy = avgrpm * 0.50
                elseif avgrpm <= 0.80 then avgEnergy = avgrpm * 0.75
                else avgEnergy = avgrpm end
                level = level - (Config.EnergyUseMult * nsecs * avgEnergy)
                level = math.max(0.0, math.min(100.0, level))
                SetVehicleFuelLevel(vehicle, level)
            end
        end)
    end
end

SIThreads:LoopUntilStopped('BATT_MAIN', function(_) -- we can't stop and we won't stop
    Citizen.Wait(1000)
    if IsPedInAnyEVVehicle() and IsPedDriving() then
        SIThreads:LoopUntilStopped('FUEL_MONITOR', function(stop) runFuelMonitor(stop) end)
    end
end)