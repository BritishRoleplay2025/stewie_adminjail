local QBCore = exports['qb-core']:GetCoreObject()
local isJailed = false
local jailTimerActive = false
local currentJailTime = 0
local jailZone = nil



RegisterCommand(Config.Command, function()
    QBCore.Functions.TriggerCallback('admin:checkLicense', function(license)
        local isAuthorized = false
        
        for _, adminLicense in ipairs(Config.AdminLicenses) do
            if license == adminLicense then
                isAuthorized = true
                break
            end
        end
        
        if isAuthorized then
            lib.registerContext({
                id = 'main_menu',
                title = 'Admin Jail Menu',
                options = {
                    {
                        title = 'Send Player To Admin Jail',
                        description = 'Send a player to the admin jail',
                        icon = 'handcuffs',
                        onSelect = function()
                            local input = lib.inputDialog('Admin Jail', {
                                {type = 'number', label = 'Player ID', description = 'Enter player server ID', required = true},
                                {type = 'number', label = 'Time (minutes)', description = 'Enter jail time', required = true}
                            })
                            
                            if input then
                                local targetId = tonumber(input[1])
                                local jailTime = tonumber(input[2])
                                TriggerServerEvent('admin:sendToJail', targetId, jailTime)
                            end
                        end
                    },
                    {
                        title = 'Currently In Admin Jail',
                        description = 'See who is currently in admin jail',
                        icon = 'list',
                        onSelect = function()
                            QBCore.Functions.TriggerCallback('admin:getAllJailedPlayerNames', function(jailedList)
                                if #jailedList == 0 then
                                    QBCore.Functions.Notify('No players are currently jailed', 'error')
                                    return
                                end
                                
                                local options = {}
                                for _, player in ipairs(jailedList) do
                                    table.insert(options, {
                                        title = player.name,
                                        description = 'Time: ' .. player.jailTime .. ' minutes',
                                        icon = 'user',
                                        arrow = true,
                                        onSelect = function()
                                            lib.registerContext({
                                                id = 'player_management',
                                                title = player.name .. ' Management',
                                                menu = 'jailed_players_list',
                                                options = {
                                                    {
                                                        title = 'Release Player',
                                                        description = 'Release from admin jail',
                                                        icon = 'unlock',
                                                        onSelect = function()
                                                            local alert = lib.alertDialog({
                                                                header = 'Confirm Release',
                                                                content = 'Are you sure you want to release ' .. player.name .. ' from jail?',
                                                                centered = true,
                                                                cancel = true,
                                                                labels = {
                                                                    confirm = 'Yes, Release',
                                                                    cancel = 'No, Keep Jailed'
                                                                }
                                                            })
                                                            
                                                            if alert == 'confirm' then
                                                                TriggerServerEvent('admin:releaseFromJail', player.playerId)
                                                                lib.notify({
                                                                    title = 'Player Released',
                                                                    description = player.name .. ' has been released from jail',
                                                                    type = 'success'
                                                                })
                                                            end
                                                        end
                                                    },
                                                    {
                                                        title = 'Modify Time',
                                                        description = 'Adjust jail time',
                                                        icon = 'clock',
                                                        onSelect = function()
                                                            local input = lib.inputDialog('Modify Jail Time', {
                                                                {type = 'number', label = 'Time Adjustment', description = 'Use + or - minutes', required = true}
                                                            })
                                                            if input then
                                                                TriggerServerEvent('admin:adjustJailTime', player.playerId, tonumber(input[1]))
                                                            end
                                                        end
                                                    }
                                                }
                                            })
                                            lib.showContext('player_management')
                                        end
                                    })
                                end
                                
                                lib.registerContext({
                                    id = 'jailed_players_list',
                                    title = 'Jailed Players',
                                    menu = 'main_menu',
                                    options = options
                                })
                                
                                lib.showContext('jailed_players_list')
                            end)
                        end
                    }
                }
            })
            
            lib.showContext('main_menu')
        else
            lib.notify({
                title = 'Access Denied',
                description = 'You are not authorized to use this command',
                type = 'error'
            })
        end
    end)
end)




function startJailTimer(time)
    if jailTimerActive then return end
    
    currentJailTime = time * 60
    jailTimerActive = true
    local lastUpdate = GetGameTimer()

    lib.showTextUI("Time Left: Initializing...", {
        position = "bottom-center",
        icon = 'fa-solid fa-clock',
        style = {
            backgroundColor = 'rgba(0, 0, 0, 0.75)',
            color = 'white',
            padding = '10px',
            borderRadius = '5px'
        }
    })

    CreateThread(function()
        while currentJailTime > 0 and isJailed do
            Wait(0)
            local now = GetGameTimer()
            if now - lastUpdate >= 1000 then
                currentJailTime = currentJailTime - 1
                lastUpdate = now

                local minutes = math.floor(currentJailTime / 60)
                local seconds = currentJailTime % 60
                local timeText = string.format("Time Left: %02d min %02d sec", minutes, seconds)

                lib.hideTextUI()
                lib.showTextUI(timeText, {
                    position = "bottom-center",
                    icon = 'fa-solid fa-clock',
                    style = {
                        backgroundColor = 'rgba(0, 0, 0, 0.75)',
                        color = 'white',
                        padding = '10px',
                        borderRadius = '5px'
                    }
                })
            end
        end

        lib.hideTextUI()
        jailTimerActive = false
        TriggerServerEvent('admin:releaseFromJail')
    end)
end


local function StartZoneCheck()
    CreateThread(function()
        while isJailed do
            local playerPos = GetEntityCoords(PlayerPedId())
            if jailZone and not jailZone:isPointInside(playerPos) then
                SetEntityCoords(PlayerPedId(), Config.Locations.teleportBack.x, Config.Locations.teleportBack.y, Config.Locations.teleportBack.z)
                currentJailTime = currentJailTime + (Config.EscapeAttempt.penalty * 60)
                
                lib.notify({
                    id = 'escape_attempt',
                    title = 'Escape Attempt',
                    description = Config.EscapeAttempt.message,
                    showDuration = false,
                    position = 'top',
                    style = {
                        backgroundColor = '#141517',
                        color = '#C1C2C5',
                        ['.description'] = {
                            color = '#909296'
                        }
                    },
                    icon = 'ban',
                    iconColor = '#C53030'
                })
                
                local minutes = math.floor(currentJailTime / 60)
                local seconds = currentJailTime % 60
                local timeText = string.format("Jail Time Left: %02d min %02d sec", minutes, seconds)
                
                lib.hideTextUI()
                lib.showTextUI(timeText, {
                    position = "bottom-center",
                    icon = 'fa-solid fa-clock',
                    style = {
                        backgroundColor = 'rgba(0, 0, 0, 0.75)',
                        color = 'white',
                        padding = '10px',
                        borderRadius = '5px'
                    }
                })
            end
            Wait(1000)
        end
        if jailZone then
            jailZone:destroy()
            jailZone = nil
        end
    end)
end



RegisterNetEvent('admin:jailPlayer:client')
AddEventHandler('admin:jailPlayer:client', function(coords, time)
    local playerPed = PlayerPedId()
    isJailed = true
    
    StartMapZoomEffect(coords, function()
        jailZone = PolyZone:Create(Config.JailZone.points, {
            name = "admin_jail",
            minZ = 10.0,
            maxZ = 30.0,
            debugPoly = Config.JailZone.debugPoly
        })
        
        CreateThread(function()
            while isJailed do
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 257, true)
                DisableControlAction(0, 263, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 24, true)
                Wait(0)
            end
        end)
        
        StartZoneCheck()
        startJailTimer(time)
    end)
end)

function StartMapZoomEffect(coords, cb)
    DoScreenFadeOut(2000)
    Wait(2000)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, coords.x, coords.y, coords.z + 1000.0)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 3000, true, true)

    DoScreenFadeIn(2000)

    local duration = 8000  -- Increased from 5000 to 8000
    local startTime = GetGameTimer()
    local startZ = coords.z + 1000.0
    local endZ = coords.z + 2.0

    while GetGameTimer() - startTime < duration do
        local now = GetGameTimer()
        local progress = (now - startTime) / duration
        local easedProgress = 1 - math.pow(1 - progress, 4) -- Changed from 3 to 4 for smoother deceleration
        local currentZ = startZ + (endZ - startZ) * easedProgress
        SetCamCoord(cam, coords.x, coords.y, currentZ)
        Wait(0)
    end

    DoScreenFadeOut(2000)
    Wait(2000)

    RenderScriptCams(false, true, 3000, true, true)
    DestroyCam(cam, false)
    cam = nil

    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    FreezeEntityPosition(ped, false)
    DoScreenFadeIn(2000)

    if cb then cb() end
end

RegisterNetEvent('admin:unjailPlayer:client')
AddEventHandler('admin:unjailPlayer:client', function()
    local playerPed = PlayerPedId()
    isJailed = false
    
    DoScreenFadeOut(500)
    Wait(600)
    SetEntityCoords(playerPed, Config.Locations.release.x, Config.Locations.release.y, Config.Locations.release.z)
    FreezeEntityPosition(playerPed, true)
    Wait(100)
    FreezeEntityPosition(playerPed, false)
    DoScreenFadeIn(500)
    
    lib.hideTextUI()
end)


RegisterNetEvent('admin:viewJailedPlayers')
AddEventHandler('admin:viewJailedPlayers', function()
    if #jailedPlayers == 0 then
        QBCore.Functions.Notify('No players are currently jailed.', 'error')
    else
        QBCore.Functions.TriggerCallback('admin:getAllJailedPlayerNames', function(playerNames)
            local options = {}
            
            for index, player in ipairs(jailedPlayers) do
                local playerName = playerNames[tostring(player.playerId)] or "Unknown"
                local displayName = playerName .. " (ID: " .. player.playerId .. ")"
                
                table.insert(options, {
                    title = displayName,
                    description = 'Time: ' .. player.jailTime .. ' minutes',
                    icon = 'fa-solid fa-lock',
                    arrow = true,
                    onSelect = function()
                        lib.registerContext({
                            id = 'jailed_player_actions_' .. player.playerId,
                            title = displayName,
                            menu = 'jailed_players_menu',
                            options = {
                                {
                                    title = 'Unjail Player',
                                    description = 'Release this player from jail',
                                    icon = 'fa-solid fa-unlock',
                                    onSelect = function()
                                        local confirm = lib.alertDialog({
                                            header = 'Confirm Unjail',
                                            content = 'Are you sure you want to release ' .. displayName .. ' from jail?',
                                            centered = true,
                                            cancel = true
                                        })
                                        
                                        if confirm == 'confirm' then
                                            TriggerServerEvent('admin:unjailPlayer', player.playerId)
                                            table.remove(jailedPlayers, index)
                                            
                                            lib.notify({
                                                title = 'Player Unjailed',
                                                description = playerName .. ' has been released from jail.',
                                                type = 'success'
                                            })
                                        end
                                    end
                                }
                            }
                        })
                        
                        lib.showContext('jailed_player_actions_' .. player.playerId)
                    end
                })
            end
            
            lib.registerContext({
                id = 'jailed_players_menu',
                title = 'Jailed Players',
                options = options
            })
            
            lib.showContext('jailed_players_menu')
        end, jailedPlayers)
    end
end)




RegisterNetEvent('admin:adjustJailTime:client')
AddEventHandler('admin:adjustJailTime:client', function(adjustmentMinutes)
    if not isJailed then return end
    
    -- Convert minutes to seconds and add to current time
    currentJailTime = currentJailTime + (adjustmentMinutes * 60)
    
    -- Ensure time doesn't go negative
    if currentJailTime < 0 then
        currentJailTime = 0
    end
    
    -- Update UI immediately
    local minutes = math.floor(currentJailTime / 60)
    local seconds = currentJailTime % 60
    local timeText = string.format("Time Left: %02d min %02d sec", minutes, seconds)
    
    lib.hideTextUI()
    lib.showTextUI(timeText, {
        position = "bottom-center",
        icon = 'fa-solid fa-clock',
        style = {
            backgroundColor = 'rgba(0, 0, 0, 0.75)',
            color = 'white',
            padding = '10px',
            borderRadius = '5px'
        }
    })
end)