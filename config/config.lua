--[[
    Vehicle Tester for FiveM
    Free resource - Open Source.
    https://github.com/h-kravs/vehiclestest
    License: MIT
]]--

Config = {}

Config.PreviewLocation = vector4(1048.22, 3245.24, 37.84, 98.81)

Config.DriveTestDuration = 60

Config.Commands = {
    toggleUI = "toggle_vehicle_ui",
    findVehicle = "findvehicle", 
    camera = "camera",
    rotate = "rotate",
    endDriveTest = "enddrivetest"
}

Config.KeyMappings = {
    toggleUI = {
        key = "N",
        description = "Open/Close Vehicle Tester UI"
    }
}

Config.CameraModes = {
    min = 1,
    max = 4,
    default = 2
}

Config.DefaultRotation = 45

Config.Animation = {
    requestTimeout = 1000,
    maxLoadAttempts = 100,
    loadWaitTime = 10
}

Config.Debug = false