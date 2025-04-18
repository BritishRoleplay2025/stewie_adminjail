local QBCore = exports['qb-core']:GetCoreObject()
local jailedPlayers = {}

QBCore.Functions.CreateCallback('admin:checkLicense', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local identifiers = GetPlayerIdentifiers(source)
    
    for _, id in ipairs(identifiers) do
        if string.find(id, "license:") then
            cb(id)
            return
        end
    end
    cb(nil)
end)

RegisterNetEvent('admin:sendToJail')
AddEventHandler('admin:sendToJail', function(playerId, jailTime)
    local src = source
    local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, {
            title = 'Player Not Found',
            description = 'The player with ID ' .. playerId .. ' is not online.',
            type = 'error'
        })
        return
    end

    local playerIdNum = tonumber(playerId)

    -- Save and clear inventory
    if not Player.PlayerData.metadata['jailitems'] then
        Player.Functions.SetMetaData('jailitems', Player.PlayerData.items)
        Player.Functions.AddMoney('cash', 500, 'jail money')
        Wait(2000)
        Player.Functions.ClearInventory()
    end

    -- Store jail time and player info
    jailedPlayers[playerIdNum] = {
        playerId = playerIdNum,
        jailTime = jailTime,
        startTime = os.time(),
        name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    }

    -- Send player to jail
    TriggerClientEvent('admin:jailPlayer:client', playerIdNum, Config.Locations.jail, jailTime)
    
    -- Notifications
    TriggerClientEvent('QBCore:Notify', src, {
        title = 'Player Jailed',
        description = 'Player ' .. playerId .. ' has been jailed for ' .. jailTime .. ' minutes.',
        type = 'success'
    })
    
    TriggerClientEvent('QBCore:Notify', playerIdNum, {
        title = 'Jailed',
        description = 'You have been jailed for ' .. jailTime .. ' minutes.',
        type = 'error'
    })
end)

RegisterNetEvent('admin:releaseFromJail')
AddEventHandler('admin:releaseFromJail', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Restore inventory
    if Player.PlayerData.metadata['jailitems'] then
        for _, v in pairs(Player.PlayerData.metadata['jailitems']) do
            Player.Functions.AddItem(v.name, v.amount, false, v.info)
        end
        Player.Functions.SetMetaData('jailitems', {})
        
        lib.notify({
            id = 'items_returned',
            title = 'Items Returned',
            description = 'Your confiscated items have been returned.',
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
    end

    -- Clear jail status
    if jailedPlayers[src] then
        jailedPlayers[src] = nil
    end

    -- Release player
    TriggerClientEvent('admin:unjailPlayer:client', src, Config.Locations.release)
    lib.notify({
        id = 'jail_release',
        title = 'Released',
        description = 'You have been released from jail',
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
end)


RegisterNetEvent('admin:showJailedPlayers')
AddEventHandler('admin:showJailedPlayers', function(jailedList)
    local options = {}
    
    if #jailedList == 0 then
        lib.notify({
            title = 'Admin Jail',
            description = 'No players currently in jail',
            type = 'info'
        })
        return
    end
    
    for _, player in ipairs(jailedList) do
        table.insert(options, {
            title = player.name,
            description = string.format('ID: %s | Time Left: %d minutes', player.id, player.time),
            icon = 'user'
        })
    end
    
    lib.registerContext({
        id = 'jailed_players_menu',
        title = 'Jailed Players',
        options = options
    })
    
    lib.showContext('jailed_players_menu')
end)


QBCore.Functions.CreateCallback('admin:getAllJailedPlayerNames', function(source, cb)
    local jailedList = {}
    
    for id, data in pairs(jailedPlayers) do
        table.insert(jailedList, {
            playerId = id,
            name = data.name,
            jailTime = data.jailTime
        })
    end
    
    cb(jailedList)
end)


RegisterNetEvent('admin:adjustJailTime')
AddEventHandler('admin:adjustJailTime', function(playerId, adjustmentMinutes)
    local src = source
    local targetPlayer = tonumber(playerId)
    
    if jailedPlayers[targetPlayer] then
        -- Update the jail time in the server's record
        jailedPlayers[targetPlayer].jailTime = jailedPlayers[targetPlayer].jailTime + adjustmentMinutes
        
        -- Ensure time doesn't go negative
        if jailedPlayers[targetPlayer].jailTime < 0 then
            jailedPlayers[targetPlayer].jailTime = 0
        end
        
        -- Notify admin
        TriggerClientEvent('QBCore:Notify', src, {
            title = 'Jail Time Modified',
            description = string.format('Adjusted time by %d minutes', adjustmentMinutes),
            type = 'success'
        })
        
        -- Notify jailed player and update their timer
        TriggerClientEvent('admin:adjustJailTime:client', targetPlayer, adjustmentMinutes)
        TriggerClientEvent('QBCore:Notify', targetPlayer, {
            title = 'Jail Time Modified',
            description = string.format('Your jail time has been adjusted by %d minutes', adjustmentMinutes),
            type = adjustmentMinutes > 0 and 'error' or 'success'
        })
    end
end)

