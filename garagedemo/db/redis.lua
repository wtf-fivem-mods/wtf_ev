local redis = { }
DB = DB or {}
DB.Redis = redis

function redis.key(...)
    local args = {...}
    local s = args[1]
    for i=2, #args do
        s = s .. ':' .. args[i]
    end
    return "garagedemo:"..s
end

function redis:hasAnyCarsStored(ped)
    local res = Redis.scan(0, 'MATCH', self.key(ped,'*'))
    return #res > 1 and #res[2] > 0
end

function redis:hasCarStored(ped, garage)
    return 1 == Redis.exists(self.key(ped, garage.Name))
end

function redis:saveStoredCar(ped, garage, vehicle)
    Redis.set(self.key(ped, garage.Name), json.encode({
        timeStored = GetEpoch(),
        level = GetVehicleFuelLevel(vehicle),
        plate = GetVehicleNumberPlateText(vehicle),
        modelHash = GetHashKey(GetVehicleDisplayName(vehicle))
    }))
end

function redis:loadSavedCar(ped, garage)
    if not self:hasCarStored(ped, garage) then
        return nil
    end
    return json.decode(Redis.get(self.key(ped, garage.Name)))
end

function redis:deleteSavedCar(ped, garage)
    Redis.del(self.key(ped, garage.Name))
end