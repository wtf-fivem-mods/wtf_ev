local client = { storedCars = {} }
DB = { Client = client }

function client:hasAnyCarsStored(ped)
    return self.storedCars[ped] ~= nil
end

function client:hasCarStored(ped, garage)
    if self.storedCars[ped] == nil then
        return false
    end
    return self.storedCars[ped][garage.Name] ~= nil
end

function client:saveStoredCar(ped, garage, vehicle)
    if self.storedCars[ped] == nil then
        self.storedCars[ped] = {}
    end
    self.storedCars[ped][garage.Name] = {
        timeStored = GetEpoch(),
        level = GetVehicleFuelLevel(vehicle),
        plate = GetVehicleNumberPlateText(vehicle),
        modelHash = GetHashKey(GetVehicleDisplayName(vehicle))
    }
end

function client:loadSavedCar(ped, garage)
    if not self:hasCarStored(ped, garage) then
        return nil
    end
    return self.storedCars[ped][garage.Name]
end

function client:deleteSavedCar(ped, garage)
    if not self:hasCarStored(ped, garage) then
        return
    end
    self.storedCars[ped][garage.Name] = nil
end