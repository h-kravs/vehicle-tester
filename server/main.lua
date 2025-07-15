--[[
    Vehicle Tester for FiveM
    Free resource.
    https://github.com/h-kravs/vehiclestest
    License: MIT
]]--

local VehicleServer = {}

function VehicleServer.GetVehicleList()
    local vehicleData = LoadResourceFile(GetCurrentResourceName(), 'data/vehicles.json')
    if not vehicleData then
        print("^1[Vehicle Tester Server]^7 Error: Could not load vehicles.json")
    end
    
    local success, vehicles = pcall(json.decode, vehicleData)
    if not success or not vehicles or type(vehicles) ~= 'table' then
        print("^1[Vehicle Tester Server]^7 Error: Invalid vehicles.json format")
        return {}
    end
    
    return vehicles
end


exports('GetVehicleList', function()
    return VehicleServer.GetVehicleList()
end)