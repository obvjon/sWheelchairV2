local TableName = Config.DB.TableName
local ActiveChairs = {}

----------------------------------------------------------------
-- INTERNAL: DELETE TRACKED CHAIR
----------------------------------------------------------------
local function DeleteTrackedChair(src)
    local netId = ActiveChairs[src]
    if not netId then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    ActiveChairs[src] = nil
end

----------------------------------------------------------------
-- CHAIR REGISTRATION
----------------------------------------------------------------
RegisterNetEvent('sWheelchairV2:RegisterChair', function(netId)
    local src = source
    DeleteTrackedChair(src)
    ActiveChairs[src] = netId
end)

RegisterNetEvent('sWheelchairV2:ClearChair', function()
    local src = source
    DeleteTrackedChair(src)
end)

----------------------------------------------------------------
-- CORE APPLY LOGIC (shared by command & UI)
----------------------------------------------------------------
local function ApplySentence(adminSrc, target, minutes)
    if not GetPlayerName(target) then
        Framework.Notify(adminSrc, _U('invalid_player_id'), 'error')
        return
    end

    if not Framework.IsJobAllowed(adminSrc) then
        Framework.Notify(adminSrc, _U('not_allowed'), 'error')
        return
    end

    minutes = tonumber(minutes) or Config.DefaultSentenceMinutes
    if minutes <= 0 then
        minutes = Config.DefaultSentenceMinutes
    end

    local identifier = Framework.GetIdentifier(target)
    if not identifier then
        Framework.Notify(adminSrc, _U('could_not_identifier'), 'error')
        return
    end

    local now = os.time()
    local releaseTime = now + (minutes * 60)

    MySQL.insert.await(
        ('INSERT INTO %s (identifier, release_time, active) VALUES (?, ?, 1)'):format(TableName),
        {identifier, releaseTime}
    )

    DeleteTrackedChair(target)
    TriggerClientEvent('sWheelchairV2:Apply', target, minutes * 60)

    Framework.Notify(adminSrc, _U('sentence_applied', minutes), 'success')
    Framework.Notify(target, _U('sentence_received'), 'error')
end

----------------------------------------------------------------
-- /wheelchair <id> [minutes]
----------------------------------------------------------------
RegisterCommand('wheelchair', function(src, args)
    if src == 0 then return end
    local target = tonumber(args[1] or '')
    local minutes = tonumber(args[2] or '') or Config.DefaultSentenceMinutes
    if not target then
        Framework.Notify(src, _U('invalid_player_id'), 'error')
        return
    end
    ApplySentence(src, target, minutes)
end)

----------------------------------------------------------------
-- /unwheelchair <id>
----------------------------------------------------------------
RegisterCommand('unwheelchair', function(src, args)
    if src == 0 then return end

    if not Framework.IsJobAllowed(src) then
        Framework.Notify(src, _U('not_allowed'), 'error')
        return
    end

    local target = tonumber(args[1] or '')
    if not target or not GetPlayerName(target) then
        Framework.Notify(src, _U('invalid_player_id'), 'error')
        return
    end

    local identifier = Framework.GetIdentifier(target)
    if not identifier then
        Framework.Notify(src, _U('could_not_identifier'), 'error')
        return
    end

    MySQL.update.await(
        ('UPDATE %s SET active = 0 WHERE identifier = ? AND active = 1'):format(TableName),
        {identifier}
    )

    TriggerClientEvent('sWheelchairV2:Release', target)
    Framework.Notify(src, _U('sentence_removed'), 'success')
    Framework.Notify(target, _U('sentence_released'), 'success')
end)

----------------------------------------------------------------
-- UI APPLY EVENT (item/command panel)
----------------------------------------------------------------
RegisterNetEvent('sWheelchairV2:ApplyFromUI', function(targetId, minutes)
    local src = source
    local target = tonumber(targetId)

    if not target then
        Framework.Notify(src, _U('invalid_player_id'), 'error')
        return
    end

    ApplySentence(src, target, minutes)
end)

----------------------------------------------------------------
-- REAPPLY ON SPAWN
----------------------------------------------------------------
RegisterNetEvent('sWheelchairV2:RequestReapply', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    if not identifier then return end

    local row = MySQL.single.await(
        ('SELECT id, release_time FROM %s WHERE identifier = ? AND active = 1 ORDER BY id DESC LIMIT 1'):format(TableName),
        {identifier}
    )
    if not row then return end

    local now = os.time()
    if now >= row.release_time then
        MySQL.update.await(
            ('UPDATE %s SET active = 0 WHERE id = ?'):format(TableName),
            {row.id}
        )
        DeleteTrackedChair(src)
        return
    end

    local remaining = row.release_time - now
    DeleteTrackedChair(src)
    TriggerClientEvent('sWheelchairV2:Apply', src, remaining)
    Framework.Notify(src, _U('sentence_resumed'), 'warning')
end)

----------------------------------------------------------------
-- ITEM / INVENTORY HOOKS
----------------------------------------------------------------
local function OpenPanelFor(src)
    if Config.UI.RestrictToJobs and not Framework.IsJobAllowed(src) then
        Framework.Notify(src, _U('not_allowed'), 'error')
        return
    end
    TriggerClientEvent('sWheelchairV2:OpenPanel', src)
end

-- Framework usable item
if Config.Item.UseFrameworkItem then
    CreateThread(function()
        if Framework.RegisterUsableItem and Config.Item.Name then
            Framework.RegisterUsableItem(Config.Item.Name, function(src)
                OpenPanelFor(src)
            end)
        end
    end)
end

-- Custom inventory event hook
if Config.Item.CustomInventory
    and Config.Item.CustomInventory.Enabled
    and Config.Item.CustomInventory.EventName
then
    RegisterNetEvent(Config.Item.CustomInventory.EventName, function()
        local src = source
        OpenPanelFor(src)
    end)
end

-- Fallback command for UI
if Config.UI.EnableCommandFallback and Config.UI.CommandName ~= '' then
    RegisterCommand(Config.UI.CommandName, function(src)
        if src == 0 then return end
        OpenPanelFor(src)
    end)
end

----------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    DeleteTrackedChair(src)
end)

CreateThread(function()
    while true do
        local now = os.time()
        MySQL.update.await(
            ('UPDATE %s SET active = 0 WHERE active = 1 AND release_time <= ?'):format(TableName),
            {now}
        )
        Wait(Config.CleanupInterval)
    end
end)
