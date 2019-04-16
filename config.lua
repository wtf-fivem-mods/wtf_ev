Config = {}

Config.Debug = true -- enable debug commands

-- Model names of electric vehicles
Config.VehicleNames = { 'teslax' }

--- EV ENERGY USE

-- How many samples / ticks in between "fuel" level updates
-- The more samples / ticks the wider the average
Config.LevelSamples = 1500

-- Higher value means higher energy / fuel use
-- given a higher RPM average
Config.EnergyUseMult = 0.33

--- SUPERCHARGERS / GARAGES

-- Show supercharger blips on the map
Config.EnableChargerBlips = true

-- Show demo garage blips on the map
Config.EnableGarageBlips = true
Config.GarageMarkerDistance = 100

-- NOTE: ChargeRate = lower the rate the *faster* the charger
-- It's is how much time wit would take to charge from 0-100
Config.SuperchargerChargeRate = 30.0
Config.SuperchargerDrawDistance = 100.0
Config.SuperchargerStations = { -- needs to remain in sync with ymap file
    -- Gas station in Paleto
    vector3(153.4138, 6592.721, 30.8449),
    -- Gas station on freeway east of sandy air strip pump 1 of 2
    vector3(2697.205, 3277.662, 54.24057),
    -- Gas station on freeway east of sandy air strip pump 2 of 2
    vector3(2683.23, 3253.071, 54.24057),
    -- Gas station Great Ocean Highway
    vector3(-2534.736, 2345.22, 32.05991),
    -- Gas station far north end of city
    vector3(645.1025, 280.3252, 102.1716),
    -- Gas station in city just east of marina district
    vector3(-729.0958, -911.1166, 18.01393),
}

-- Demo garages are client only and don't persist,
-- nor do they apply all properties to vehicles stored.
-- It's more of an example of applying charge while stored
-- NOTE: ChargeRate = lower the rate the *faster* the charger
-- It's is how much time wit would take to charge from 0-100
Config.DemoGarages = {
    { Name = 'Vinny\'s House Garage',
        In = vector3(-1997.033, 297.151, 90.76487),
        Out = vector3(-1997.033, 297.151, 90.76487),
        OutHdg = 286.0, ChargeRate = 240.0 },
    { Name = 'Court House Parking Lot',
        In = vector3(270.2041, -344.4858, 43.91984),
        Out = vector3(285.1952, -350.0556, 45.00715),
        OutHdg = 157.0, ChargeRate = 180.0 },
    { Name = 'Pillbox Parking Garage',
        In = vector3(169.9288, -708.3558, 32.12971),
        Out = vector3(167.6183, -721.4551, 32.13189),
        OutHdg = 245.0, ChargeRate = 120.0 },
}