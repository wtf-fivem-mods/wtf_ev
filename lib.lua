--- Global UI Offset
UI = { x =  -0.001, y = -0.001 }

--- Keycode Table
Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169,
    ["F9"] = 56, ["F10"] = 57, ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165,
    ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, ["TAB"] = 37,
    ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39,
    ["]"] = 40, ["ENTER"] = 18, ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74,
    ["K"] = 311, ["L"] = 182, ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29,
    ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81, ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22,
    ["RIGHTCTRL"] = 70, ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178, ["LEFT"] = 174,
    ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173, ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107,
    ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

---
--- RESOURCE SPECIFIC
---

--- Quadratic Bezier function
-- Used to calculate non-linear charge rate
local function newQuad(p0, p1, p2, p3)
    return function(t)
        local u = 1 -t
        local tt = t * t
        local uu = u * u
        local uuu = uu * u
        local ttt = tt * t
        local v = uuu * p0
        v = v + 3 * uu * t * p1
        v = v + 3 * u * tt * p2
        v = v + ttt * p3
        return v
    end
end

--- Charge rate curve
-- Favors 0-60% charge in 30% total time
-- Last 40% charge takes 70% total time
ChargeRateFn = newQuad(0.00, 0.85, 1.00, 1.00)

--- Return charge time required to get to given level
-- Used to calculate where along the curve we start when
-- fueling from non 0 charge
function GetChargeTimeForLevel(level, maxT)
    if level >= 100.0 then
        return maxT
    elseif level <= 0.0 then
        return 0.0
    end
    for i = 1.0, maxT do
        local t = i / maxT
        local levelAt = ChargeRateFn(t) * 100.0
        if levelAt >= level then
            return i
        end
    end
    return 0.0
end

--- Convenience function returning if ped current vehicle is an EV
-- ped arg is optional
function IsPedInAnyEVVehicle(ped)
    ped = ped or GetPlayerPed(-1)
    return IsPedInAnyVehicle(ped) and IsEV(GetPedVehicleName(ped))
end

--- Convenience function returining if ped's last vehicle was an EV
function IsPlayersLastVehicleEV()
    return IsEV(GetVehicleDisplayName(GetPlayersLastVehicle()))
end

--- Convenience function returning if vehicle model name is an EV
function IsEV(name)
    for _, evName in ipairs(Config.VehicleNames) do
        if name == evName then
            return true
        end
    end
    return false
end

---
--- API HELPERS
---

--- Returns whether given ped is driving current vehicle
-- ped is optional
function IsPedDriving(ped)
    ped = ped or GetPlayerPed(-1)
    return ped == GetPedInVehicleSeat(GetVehiclePedIsIn(ped, false), -1)
end

--- Get name of vehicle ped is using
-- ped arg is optional
function GetPedVehicleName(ped)
    ped = ped or GetPlayerPed(-1)
    return GetVehicleDisplayName(
            GetVehiclePedIsUsing(ped))
end

--- Return display name for given vehicle
function GetVehicleDisplayName(veh)
    return GetDisplayNameFromVehicleModel(
            GetEntityModel(veh))
end

--- Native convenience function to get epoch
-- Time in seconds
function GetEpoch()
    return Citizen.InvokeNative(0x9a73240b49945c76)
end

--- Loads anim dictionary, waiting until loaded
function LoadAnimDict(dict)
	while(not HasAnimDictLoaded(dict)) do
		Citizen.Wait(1)
		RequestAnimDict(dict)
	end
end

--- Disables control actions
function DisableCtrlActions()
    DisableControlAction(0, 0, true) -- Changing view (V)
    DisableControlAction(0, 22, true) -- Jumping (SPACE)
    DisableControlAction(0, 23, true) -- Entering vehicle (F)
    DisableControlAction(0, 24, true) -- Punching/Attacking
    DisableControlAction(0, 29, true) -- Pointing (B)
    DisableControlAction(0, 30, true) -- Moving sideways (A/D)
    DisableControlAction(0, 31, true) -- Moving back & forth (W/S)
    DisableControlAction(0, 37, true) -- Weapon wheel
    DisableControlAction(0, 44, true) -- Taking Cover (Q)
    DisableControlAction(0, 56, true) -- F9
    DisableControlAction(0, 82, true) -- Mask menu (,)
    DisableControlAction(0, 140, true) -- Hitting your vehicle (R)
    DisableControlAction(0, 166, true) -- F5
    DisableControlAction(0, 167, true) -- F6
    DisableControlAction(0, 168, true) -- F7
    DisableControlAction(0, 170, true) -- F3
    DisableControlAction(0, 288, true) -- F1
    DisableControlAction(0, 289, true) -- F2
    DisableControlAction(1, 323, true) -- Handsup (X)
end

---
--- INTERNAL FRAMEWORK
---

--- An inline wait utility used to perform operations at givem modulation
function NewInlineWait()
    local self = { tc = 0 }
    return {
        Tick = function() self.tc = self.tc + 1 end,
        Wait = function(n, fn) if self.tc % n == 0 then fn() end end,
    }
end

--- SIThreads provides a set of thread creation functions
-- SI = single instance, threads are "memoized" and can only
-- have a single instance running.
-- They're designed to run in game loops and provide declaritive
-- expression and more efficient use of resources
SIThreads = { active_threads = { } }

--- Creates a looping thread and stop callback (to parent and child)
-- Thread will run looped until stop fn is called, by either parent
-- or child.
function SIThreads:LoopUntilStopped(key, fn)
    if self.active_threads[key] ~= nil then
        return self.active_threads[key]
    end
    local stop = function() self.active_threads[key] = nil end
    self.active_threads[key] = stop
    Citizen.CreateThread(function()
        while self.active_threads[key] ~= nil do
            fn(stop)
        end
    end)
    return stop
end

--- Creates a looping thread that will last until given duration
-- Thread will run looped until duration expires
function SIThreads:LoopForDuration(key, msecs, fn)
    if self.active_threads[key] ~= nil then
        return
    end
    self.active_threads[key] = true
    Citizen.CreateThread(function()
        while self.active_threads[key] do
            fn()
        end
    end)
    Citizen.CreateThread(function()
        Wait(msecs)
        self.active_threads[key] = nil
    end)
end

--- Creates thread that runs after given duration
-- Given fn is ran after given duration, does not loop
function SIThreads:SetTimeout(key, msecs, fn)
    if self.active_threads[key] ~= nil then
        return
    end
    self.active_threads[key] = true
    Citizen.CreateThread(function()
        Wait(msecs)
        fn()
        self.active_threads[key] = nil
    end)
end

---
--- DRAWING
---

--- Given a number 1..0, returns color ranging from green to red
-- Returns multiple values: r, g, b -- 0..255 per channel
function GetGreenToRedRGB(p)
    local m = (p % 0.5) / 0.5
    if p <= 0.0 then
        return 255, 0, 0
    elseif p >= 1.00 then
        return 0, 255, 0
    end
    if p < 0.50 then return 255, math.ceil(m * 255), 0
    elseif p == 0.50 then return 255, 255, 0
    elseif p > 0.50 then return math.ceil(255 - (m * 255)), 255, 0
    else return 0, 255, 0
    end
end

--- Draws centered rectangle
function DrawRct(x,y,width,height,r,g,b,a)
	DrawRect(x + width/2, y + height/2, width, height, r, g, b, a)
end

--- Draws text
function DrawTxt(x, y, width, height, scale, text, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end

--- Draws Text in 3D space
function DrawText3Ds(x, y, z, text, r, g, b)
    r = r or 255
    g = g or 255
    b = b or 255
    local _,_x,_y=World3dToScreen2d(x,y,z)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(r, g, b, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end