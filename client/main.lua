--[[
    Vehicle Tester for FiveM
    Free Resource - Open Source.
    https://github.com/h-kravs/vehiclestest
    License: MIT
]]--

local VehicleTester = {}
local State = {
    isUIOpen = false,
    currentVehicleIndex = 1,
    spawnedVehicle = nil,
    originalCoords = nil,
    cameraUnlocked = false,
    isThirdPerson = true,
    isDriveTestActive = false,
    driveTestVehicle = nil,
    driveTestStartTime = 0,
    vehicles = {},
    isResourceStopping = false
}

local Threads = {
    keyDetection = nil,
    driveTestTimer = nil
}

function VehicleTester.LoadVehicleData()
    local vehicleData = LoadResourceFile(GetCurrentResourceName(), 'data/vehicles.json')
    if not vehicleData then
        print("^1[Vehicle Tester]^7 Error: Could not load vehicles.json")
        return false
    end
    
    local success, vehicles = pcall(json.decode, vehicleData)
    if not success or not vehicles or type(vehicles) ~= 'table' then
        print("^1[Vehicle Tester]^7 Error: Invalid vehicles.json format")
        return false
    end
    
    State.vehicles = vehicles
    if Config.Debug then
        print("^2[Vehicle Tester]^7 Loaded " .. #State.vehicles .. " vehicles")
    end
    return true
end

function VehicleTester.ValidateVehicleIndex(index)
    return index and type(index) == 'number' and index >= 1 and index <= #State.vehicles
end

function VehicleTester.CleanupVehicle(vehicle)
    if vehicle and DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
        return true
    end
    return false
end

function VehicleTester.CleanupAll()
    State.isResourceStopping = true
    
    if Threads.keyDetection then
        Threads.keyDetection = nil
    end
    
    if Threads.driveTestTimer then
        Threads.driveTestTimer = nil
    end
    
    VehicleTester.CleanupVehicle(State.spawnedVehicle)
    VehicleTester.CleanupVehicle(State.driveTestVehicle)
    
    if State.originalCoords then
        VehicleTester.RestoreOriginalPosition()
    end
    
    if State.isUIOpen then
        SetNuiFocus(false, false)
    end
    
    State.spawnedVehicle = nil
    State.driveTestVehicle = nil
    State.isUIOpen = false
    State.isDriveTestActive = false
end

function VehicleTester.GetPreviewCoords()
    return Config.PreviewLocation
end

function VehicleTester.SpawnVehicle(index)
    if not VehicleTester.ValidateVehicleIndex(index) then
        print("^1[Vehicle Tester]^7 Error: Invalid vehicle index " .. tostring(index))
        return false
    end

    VehicleTester.CleanupVehicle(State.spawnedVehicle)
    State.spawnedVehicle = nil

    local model = State.vehicles[index]
    if not model then 
        print("^1[Vehicle Tester]^7 Error: Vehicle model not found at index " .. index)
        return false
    end

    local hash = GetHashKey(model)
    RequestModel(hash)

    local attempts = 0
    while not HasModelLoaded(hash) and attempts < Config.Animation.maxLoadAttempts and not State.isResourceStopping do 
        Wait(Config.Animation.loadWaitTime)
        attempts = attempts + 1
    end

    if not HasModelLoaded(hash) then
        print("^1[Vehicle Tester]^7 Error: Could not load model " .. model)
        return false
    end

    local playerPed = PlayerPedId()
    local coords = VehicleTester.GetPreviewCoords()

    State.spawnedVehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w, false, true)

    if not DoesEntityExist(State.spawnedVehicle) then
        print("^1[Vehicle Tester]^7 Error: Could not create vehicle " .. model)
        SetModelAsNoLongerNeeded(hash)
        return false
    end

    if not State.originalCoords then
        State.originalCoords = GetEntityCoords(playerPed)
    end

    SetEntityCoords(playerPed, coords.x, coords.y, coords.z + 2.0, false, false, false, true)
    Wait(100)

    TaskWarpPedIntoVehicle(playerPed, State.spawnedVehicle, -1)
    SetVehicleDoorsLocked(State.spawnedVehicle, 4)
    SetVehicleUndriveable(State.spawnedVehicle, true)
    SetEntityInvincible(State.spawnedVehicle, true)
    SetEntityCollision(State.spawnedVehicle, false, false)
    FreezeEntityPosition(State.spawnedVehicle, true)

    local viewMode = State.isThirdPerson and 2 or 1
    SetFollowVehicleCamViewMode(viewMode)

    SetModelAsNoLongerNeeded(hash)

    if Config.Debug then
        print("^2[Vehicle Tester]^7 Vehicle spawned: " .. model .. " (" .. index .. "/" .. #State.vehicles .. ")")
    end
    
    return true
end

function VehicleTester.RestoreOriginalPosition()
    if State.originalCoords then
        local playerPed = PlayerPedId()
        SetEntityCoords(playerPed, State.originalCoords.x, State.originalCoords.y, State.originalCoords.z, false, false, false, true)
    end
end

function VehicleTester.StartDriveTest()
    if not State.spawnedVehicle or not DoesEntityExist(State.spawnedVehicle) then
        print("^1[Vehicle Tester]^7 No vehicle available for drive test")
        return false
    end
    
    if State.isDriveTestActive then
        print("^3[Vehicle Tester]^7 Drive test already active")
        return false
    end
    
    State.isDriveTestActive = true
    State.driveTestStartTime = GetGameTimer()
    
    SetNuiFocus(false, false)
    
    local currentModel = State.vehicles[State.currentVehicleIndex]
    local currentHash = GetHashKey(currentModel)
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    State.driveTestVehicle = CreateVehicle(currentHash, playerCoords.x, playerCoords.y, playerCoords.z, GetEntityHeading(playerPed), false, true)
    
    if not DoesEntityExist(State.driveTestVehicle) then
        print("^1[Vehicle Tester]^7 Error: Could not create drive test vehicle")
        State.isDriveTestActive = false
        return false
    end

    SetVehicleDoorsLocked(State.driveTestVehicle, 1)
    SetVehicleUndriveable(State.driveTestVehicle, false)
    SetEntityInvincible(State.driveTestVehicle, false)
    SetEntityCollision(State.driveTestVehicle, true, true)
    FreezeEntityPosition(State.driveTestVehicle, false)
    
    VehicleTester.CleanupVehicle(State.spawnedVehicle)
    State.spawnedVehicle = nil
    
    TaskWarpPedIntoVehicle(playerPed, State.driveTestVehicle, -1)
    SetFollowVehicleCamViewMode(2)
    
    -- Show timer in the UI
    SendNUIMessage({
        type = "startDriveTestTimer",
        duration = Config.DriveTestDuration
    })
    
    VehicleTester.StartDriveTestTimer()
    
    if Config.Debug then
        print("^2[Vehicle Tester]^7 Drive test started - " .. Config.DriveTestDuration .. " seconds")
    end
    
    return true
end

function VehicleTester.EndDriveTest()
    if not State.isDriveTestActive then 
        return false
    end
    
    State.isDriveTestActive = false
    
    if Threads.driveTestTimer then
        Threads.driveTestTimer = nil
    end
    
    VehicleTester.CleanupVehicle(State.driveTestVehicle)
    State.driveTestVehicle = nil
    
    VehicleTester.RestoreOriginalPosition()
    VehicleTester.SpawnVehicle(State.currentVehicleIndex)
    
    SetNuiFocus(true, true)
    
    -- Hide timer and restore normal UI
    SendNUIMessage({
        type = "endDriveTestTimer"
    })
    
    SendNUIMessage({
        type = "toggleUI",
        show = true,
        vehicle = State.vehicles[State.currentVehicleIndex] or "",
        index = State.currentVehicleIndex,
        total = #State.vehicles
    })
    
    if Config.Debug then
        print("^2[Vehicle Tester]^7 Drive test ended - UI restored")
    end
    
    return true
end

function VehicleTester.StartDriveTestTimer()
    if Threads.driveTestTimer then
        return
    end
    
    Threads.driveTestTimer = true
    Citizen.CreateThread(function()
        local startTime = GetGameTimer()
        
        while Threads.driveTestTimer and State.isDriveTestActive and not State.isResourceStopping do
            Wait(1000)
            
            local currentTime = GetGameTimer()
            local elapsedTime = (currentTime - startTime) / 1000
            local remainingTime = Config.DriveTestDuration - elapsedTime
            
            if remainingTime <= 0 then
                if Config.Debug then
                    print("^2[Vehicle Tester]^7 Drive test auto-ended")
                end
                VehicleTester.EndDriveTest()
                break
            else
                -- Send timer update to the UI
                SendNUIMessage({
                    type = "updateTimer",
                    remainingTime = math.max(0, math.floor(remainingTime))
                })
            end
        end
        
        Threads.driveTestTimer = nil
    end)
end

function VehicleTester.ToggleUI()
    State.isUIOpen = not State.isUIOpen
    SetNuiFocus(State.isUIOpen, State.isUIOpen)

    if State.isUIOpen then
        State.currentVehicleIndex = 1
        if VehicleTester.SpawnVehicle(State.currentVehicleIndex) then
            SendNUIMessage({
                type = "toggleUI",
                show = State.isUIOpen,
                vehicle = State.vehicles[State.currentVehicleIndex] or "",
                index = State.currentVehicleIndex,
                total = #State.vehicles,
            })
        else
            State.isUIOpen = false
            SetNuiFocus(false, false)
        end
    else
        VehicleTester.CleanupVehicle(State.spawnedVehicle)
        State.spawnedVehicle = nil
        VehicleTester.RestoreOriginalPosition()
        SendNUIMessage({
            type = "toggleUI",
            show = false,
        })
    end
end

function VehicleTester.FindVehicle(searchTerm)
    if not searchTerm or searchTerm == "" then
        print("^3[Vehicle Tester]^7 Usage: /" .. Config.Commands.findVehicle .. " [name]")
        return false
    end

    local lowerSearchTerm = string.lower(searchTerm)
    for i, car in ipairs(State.vehicles) do
        if string.find(string.lower(car), lowerSearchTerm) then
            print("^2[Vehicle Tester]^7 Found: " .. car .. " (Index: " .. i .. ")")
            if State.isUIOpen then
                State.currentVehicleIndex = i
                if VehicleTester.SpawnVehicle(State.currentVehicleIndex) then
                    SendNUIMessage({
                        type = "updateVehicle",
                        vehicle = State.vehicles[State.currentVehicleIndex] or "",
                        index = State.currentVehicleIndex,
                        total = #State.vehicles,
                    })
                end
            end
            return true
        end
    end
    
    print("^1[Vehicle Tester]^7 No vehicle found with: " .. searchTerm)
    return false
end

function VehicleTester.SetCameraMode(mode)
    local cameraMode = tonumber(mode)
    if not cameraMode or cameraMode < Config.CameraModes.min or cameraMode > Config.CameraModes.max then
        print("^3[Vehicle Tester]^7 Camera modes: " .. Config.CameraModes.min .. "-" .. Config.CameraModes.max)
        return false
    end

    if not State.spawnedVehicle or not DoesEntityExist(State.spawnedVehicle) then
        print("^3[Vehicle Tester]^7 No vehicle spawned. Open UI first with " .. Config.KeyMappings.toggleUI.key)
        return false
    end

    SetFollowVehicleCamViewMode(cameraMode)
    print("^2[Vehicle Tester]^7 Camera mode changed to: " .. cameraMode)
    return true
end

function VehicleTester.RotateVehicle(degrees)
    if not State.spawnedVehicle or not DoesEntityExist(State.spawnedVehicle) then
        print("^3[Vehicle Tester]^7 No vehicle spawned. Open UI first with " .. Config.KeyMappings.toggleUI.key)
        return false
    end
    
    local rotation = tonumber(degrees) or Config.DefaultRotation
    local heading = GetEntityHeading(State.spawnedVehicle)
    
    SetEntityHeading(State.spawnedVehicle, heading + rotation)
    print("^2[Vehicle Tester]^7 Vehicle rotated " .. rotation .. " degrees")
    return true
end

function VehicleTester.StartKeyDetectionThread()
    if Threads.keyDetection then
        return
    end
    
    Threads.keyDetection = true
    Citizen.CreateThread(function()
        while Threads.keyDetection and not State.isResourceStopping do
            Wait(0)
            
            if State.isUIOpen and State.spawnedVehicle and DoesEntityExist(State.spawnedVehicle) and State.cameraUnlocked then
                if IsControlJustPressed(0, 29) then -- B key
                    State.cameraUnlocked = false
                    SetNuiFocus(true, true)
                    if Config.Debug then
                        print("^2[Vehicle Tester]^7 Camera locked - UI active")
                    end
                end
            end
        end
        
        Threads.keyDetection = nil
    end)
end

RegisterCommand(Config.Commands.toggleUI, function()
    VehicleTester.ToggleUI()
end, false)

RegisterKeyMapping(Config.Commands.toggleUI, Config.KeyMappings.toggleUI.description, "keyboard", Config.KeyMappings.toggleUI.key)

RegisterCommand(Config.Commands.findVehicle, function(source, args)
    if #args > 0 then
        VehicleTester.FindVehicle(args[1])
    else
        print("^3[Vehicle Tester]^7 Usage: /" .. Config.Commands.findVehicle .. " [name]")
    end
end, false)

RegisterCommand(Config.Commands.camera, function(source, args)
    if #args > 0 then
        VehicleTester.SetCameraMode(args[1])
    else
        VehicleTester.SetCameraMode(Config.CameraModes.default)
    end
end, false)

RegisterCommand(Config.Commands.rotate, function(source, args)
    if #args > 0 then
        VehicleTester.RotateVehicle(args[1])
    else
        VehicleTester.RotateVehicle(Config.DefaultRotation)
    end
end, false)

RegisterCommand(Config.Commands.endDriveTest, function()
    if State.isDriveTestActive then
        print("^2[Vehicle Tester]^7 Ending drive test manually...")
        VehicleTester.EndDriveTest()
    else
        print("^3[Vehicle Tester]^7 No drive test active")
    end
end, false)

RegisterNUICallback("nextVehicle", function(data, cb)
    if State.currentVehicleIndex < #State.vehicles then
        State.currentVehicleIndex = State.currentVehicleIndex + 1
    else
        State.currentVehicleIndex = 1
    end
    
    if VehicleTester.SpawnVehicle(State.currentVehicleIndex) then
        SendNUIMessage({
            type = "updateVehicle",
            vehicle = State.vehicles[State.currentVehicleIndex] or "",
            index = State.currentVehicleIndex,
            total = #State.vehicles,
        })
    end
    cb("ok")
end)

RegisterNUICallback("prevVehicle", function(data, cb)
    if State.currentVehicleIndex > 1 then
        State.currentVehicleIndex = State.currentVehicleIndex - 1
    else
        State.currentVehicleIndex = #State.vehicles
    end
    
    if VehicleTester.SpawnVehicle(State.currentVehicleIndex) then
        SendNUIMessage({
            type = "updateVehicle",
            vehicle = State.vehicles[State.currentVehicleIndex] or "",
            index = State.currentVehicleIndex,
            total = #State.vehicles,
        })
    end
    cb("ok")
end)

RegisterNUICallback("setVehicleIndex", function(data, cb)
    local idx = tonumber(data.index)
    if VehicleTester.ValidateVehicleIndex(idx) then
        State.currentVehicleIndex = idx
        if VehicleTester.SpawnVehicle(State.currentVehicleIndex) then
            SendNUIMessage({
                type = "updateVehicle",
                vehicle = State.vehicles[State.currentVehicleIndex] or "",
                index = State.currentVehicleIndex,
                total = #State.vehicles,
            })
        end
    end
    cb("ok")
end)

RegisterNUICallback("closeUI", function(data, cb)
    State.isUIOpen = false
    SetNuiFocus(false, false)
    VehicleTester.CleanupVehicle(State.spawnedVehicle)
    State.spawnedVehicle = nil
    VehicleTester.RestoreOriginalPosition()
    SendNUIMessage({
        type = "toggleUI",
        show = false,
    })
    cb("ok")
end)

RegisterNUICallback("searchVehicle", function(data, cb)
    VehicleTester.FindVehicle(data.searchTerm)
    cb("ok")
end)

RegisterNUICallback('cameraCommand', function(data, cb)
    local command = data.command
    
    if command == 'unlockCamera' then
        State.cameraUnlocked = true
        SetNuiFocus(false, false)
        if Config.Debug then
            print("^2[Vehicle Tester]^7 Camera unlocked - Free view mode")
        end
    elseif command == 'toggleView' then
        State.isThirdPerson = not State.isThirdPerson
        local viewMode = State.isThirdPerson and 2 or 1
        SetFollowVehicleCamViewMode(viewMode)
        if Config.Debug then
            print("^2[Vehicle Tester]^7 View: " .. (State.isThirdPerson and "Third person" or "First person"))
        end
    elseif command == 'startDriveTest' then
        VehicleTester.StartDriveTest()
    end
    
    cb('ok')
end)

RegisterNUICallback('startDriveTest', function(data, cb)
    VehicleTester.StartDriveTest()
    cb('ok')
end)

RegisterNUICallback('endDriveTest', function(data, cb)
    VehicleTester.EndDriveTest()
    cb('ok')
end)

RegisterNUICallback('hideUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        VehicleTester.CleanupAll()
    end
end)

Citizen.CreateThread(function()
    while not VehicleTester.LoadVehicleData() and not State.isResourceStopping do
        Wait(1000)
    end
    
    if not State.isResourceStopping then
        VehicleTester.StartKeyDetectionThread()
        
        Wait(1000)
        print("^2[Vehicle Tester]^7 Resource loaded. Press " .. Config.KeyMappings.toggleUI.key .. " to open vehicle interface.")
        
        if Config.Debug then
            print("^3[Vehicle Tester]^7 Resource: " .. GetCurrentResourceName())
            print("^3[Vehicle Tester]^7 Total vehicles: " .. #State.vehicles)
            print("^3[Vehicle Tester]^7 Preview location: " .. tostring(Config.PreviewLocation))
        end
    end
end)