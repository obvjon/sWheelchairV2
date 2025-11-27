Framework = Framework or {}

----------------------------------------------------------------
-- FRAMEWORK INIT
----------------------------------------------------------------
local function initFramework()
    local fwType = (Config.Framework or 'esx'):lower()

    if fwType == 'esx' then
        Framework.Type = 'esx'
        Framework.Core = exports['es_extended']:getSharedObject()

    elseif fwType == 'qbcore' then
        Framework.Type = 'qbcore'
        Framework.Core = exports['qb-core']:GetCoreObject()

    elseif fwType == 'qbx' then
        Framework.Type = 'qbx'
        Framework.Core = exports['qbx-core']:GetCoreObject()

    else
        Framework.Type = 'none'
        Framework.Core = nil
    end

    if not Framework.Core and Config.FrameworkDebug then
        print(('[sWheelchairV2] %s'):format(
            _U('debug_framework_fail', tostring(fwType))
        ))
    end
end

initFramework()

----------------------------------------------------------------
-- SERVER SIDE
----------------------------------------------------------------
if IsDuplicityVersion() then
    function Framework.GetPlayer(src)
        if not Framework.Core then return nil end

        if Framework.Type == 'esx' then
            return Framework.Core.GetPlayerFromId(src)
        elseif Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Framework.Core.Functions.GetPlayer(src)
        end
        return nil
    end

    function Framework.GetIdentifier(src)
        local player = Framework.GetPlayer(src)
        if not player then return nil end

        if Framework.Type == 'esx' then
            return player.getIdentifier and player.getIdentifier() or nil
        elseif Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return player.PlayerData and player.PlayerData.citizenid or nil
        end
        return nil
    end

    function Framework.GetJobName(src)
        local player = Framework.GetPlayer(src)
        if not player then return nil end

        if Framework.Type == 'esx' then
            return player.job and player.job.name or nil
        elseif Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return player.PlayerData
                and player.PlayerData.job
                and player.PlayerData.job.name
                or nil
        end
        return nil
    end

    function Framework.IsJobAllowed(src)
        if not Config.AllowedJobs then return true end
        local job = Framework.GetJobName(src)
        if not job then return false end
        return Config.AllowedJobs[job] or false
    end

    function Framework.Notify(src, msg, nType)
        if not msg or Config.Notify == 'none' then return end
        local t = Config.NotifyTypes[nType or 'info'] or 'info'
        local mode = (Config.Notify or 'chat'):lower()

        if mode == 'ox_lib' then
            TriggerClientEvent('ox_lib:notify', src, {
                description = msg,
                type = t
            })
        elseif mode == 'esx' then
            TriggerClientEvent('esx:showNotification', src, msg)
        elseif mode == 'qb' then
            TriggerClientEvent('QBCore:Notify', src, msg, t)
        elseif mode == 'chat' then
            TriggerClientEvent('chat:addMessage', src, {
                color = {255, 255, 255},
                multiline = true,
                args = {'Wheelchair', msg}
            })
        end
    end

    -- unified usable item registration
    function Framework.RegisterUsableItem(itemName, cb)
        if not itemName or not cb then return end
        if not Framework.Core then return end

        if Framework.Type == 'esx' then
            if Framework.Core.RegisterUsableItem then
                Framework.Core.RegisterUsableItem(itemName, function(src)
                    cb(src)
                end)
            end

        elseif Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            if Framework.Core.Functions and Framework.Core.Functions.CreateUseableItem then
                Framework.Core.Functions.CreateUseableItem(itemName, function(src, item)
                    cb(src, item)
                end)
            end
        end
    end

else
----------------------------------------------------------------
-- CLIENT SIDE
----------------------------------------------------------------
    function Framework.NotifyClient(msg, nType)
        if not msg or Config.Notify == 'none' then return end
        local t = Config.NotifyTypes[nType or 'info'] or 'info'
        local mode = (Config.Notify or 'chat'):lower()

        if mode == 'ox_lib' then
            lib.notify({
                description = msg,
                type = t
            })
        elseif mode == 'esx' then
            TriggerEvent('esx:showNotification', msg)
        elseif mode == 'qb' then
            TriggerEvent('QBCore:Notify', msg, t)
        elseif mode == 'chat' then
            TriggerEvent('chat:addMessage', {
                color = {255, 255, 255},
                multiline = true,
                args = {'Wheelchair', msg}
            })
        end
    end
end
