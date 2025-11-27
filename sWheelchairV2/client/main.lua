local isLocked          = false
local wheelchairEntity  = nil
local releaseTimeMs     = 0

local lastReseatTimes   = {}
local panelOpen         = false

----------------------------------------------------------------
-- NOTIFY
----------------------------------------------------------------
local function Notify(msg, nType)
    Framework.NotifyClient(msg, nType)
end

----------------------------------------------------------------
-- RESEAT SAFETY
----------------------------------------------------------------
local function TrackReseatAttempt()
    local now = GetGameTimer()
    table.insert(lastReseatTimes, now)

    local window = Config.ReseatWindowMs or (10 * 1000)
    local cutoff = now - window
    local count = 0
    local filtered = {}

    for _, t in ipairs(lastReseatTimes) do
        if t >= cutoff then
            count = count + 1
            filtered[#filtered + 1] = t
        end
    end

    lastReseatTimes = filtered
    return count
end

local function ResetReseatHistory()
    lastReseatTimes = {}
end

----------------------------------------------------------------
-- FORCE SEAT
----------------------------------------------------------------
local function ForcePlayerIntoSeat(ped, veh)
    local maxAttempts = Config.MaxSeatAttempts or 20
    local delay = Config.SeatAttemptDelay or 75

    for i = 1, maxAttempts do
        TaskWarpPedIntoVehicle(ped, veh, -1)
        Wait(delay)
        if GetVehiclePedIsIn(ped, false) == veh then
            return true
        end
    end
    return false
end

----------------------------------------------------------------
-- SPAWN WHEELCHAIR
----------------------------------------------------------------
local function SpawnWheelchairForPed(ped)
    local modelName = Config.WheelchairModel or 'iak_wheelchair'
    local model = GetHashKey(modelName)

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, -0.5)
    local veh = CreateVehicle(
        model,
        pos.x, pos.y, pos.z,
        GetEntityHeading(ped),
        true, true
    )

    SetVehicleOnGroundProperly(veh)
    SetEntityAsMissionEntity(veh, true, true)

    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleUndriveable(veh, false)
    SetVehicleDoorsLocked(veh, 1)
    SetVehicleDoorsLockedForAllPlayers(veh, false)

    local netId = VehToNet(veh)
    TriggerServerEvent('sWheelchairV2:RegisterChair', netId)

    return veh
end

----------------------------------------------------------------
-- PUT PLAYER IN WHEELCHAIR
----------------------------------------------------------------
local function PutPlayerInWheelchair(initial)
    local ped = PlayerPedId()

    if wheelchairEntity and DoesEntityExist(wheelchairEntity) then
        DeleteVehicle(wheelchairEntity)
        wheelchairEntity = nil
    end

    wheelchairEntity = SpawnWheelchairForPed(ped)
    if not wheelchairEntity or not DoesEntityExist(wheelchairEntity) then
        return false
    end

    if not ForcePlayerIntoSeat(ped, wheelchairEntity) then
        DeleteVehicle(wheelchairEntity)
        wheelchairEntity = nil
        return false
    end

    SetPedCanBeDraggedOut(ped, false)
    isLocked = true
    ResetReseatHistory()

    -- disable exit controls
    CreateThread(function()
        while isLocked do
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 23, true)
            Wait(5)
        end
    end)

    -- reseat / safety
    if initial then
        CreateThread(function()
            local checkInterval = Config.ClientCheckInterval or 300
            local reseatFailureAction = (Config.ReseatFailureAction or 'release'):lower()
            local maxReseat = Config.MaxReseatAttempts or 3

            while isLocked do
                Wait(checkInterval)

                if not wheelchairEntity or not DoesEntityExist(wheelchairEntity) then
                    goto continue
                end

                local ped = PlayerPedId()
                local currentVeh = GetVehiclePedIsIn(ped, false)

                if currentVeh ~= wheelchairEntity then
                    local attemptsInWindow = TrackReseatAttempt()

                    if attemptsInWindow > maxReseat then
                        if reseatFailureAction == 'release' then
                            Notify(_U('reseat_fail_release'), 'warning')
                            TriggerServerEvent('sWheelchairV2:ClearChair')
                            isLocked = false
                            TaskLeaveVehicle(ped, wheelchairEntity, 0)

                            SetTimeout(500, function()
                                if wheelchairEntity and DoesEntityExist(wheelchairEntity) then
                                    DeleteVehicle(wheelchairEntity)
                                end
                                wheelchairEntity = nil
                            end)
                        end
                        break
                    end

                    TriggerServerEvent('sWheelchairV2:ClearChair')

                    DeleteVehicle(wheelchairEntity)
                    wheelchairEntity = nil

                    Wait(200)

                    wheelchairEntity = SpawnWheelchairForPed(ped)

                    if wheelchairEntity and DoesEntityExist(wheelchairEntity) then
                        SetPedCanRagdoll(ped, false)
                        if not ForcePlayerIntoSeat(ped, wheelchairEntity) then
                            SetPedCanRagdoll(ped, true)
                            if reseatFailureAction == 'release' then
                                Notify(_U('reseat_fail_release'), 'warning')
                                TriggerServerEvent('sWheelchairV2:ClearChair')
                                isLocked = false
                                break
                            else
                                break
                            end
                        end
                        Wait(600)
                        SetPedCanRagdoll(ped, true)
                    end
                end

                ::continue::
            end
        end)
    end

    return true
end

----------------------------------------------------------------
-- RELEASE
----------------------------------------------------------------
local function ReleasePlayer()
    isLocked = false
    ResetReseatHistory()

    local ped = PlayerPedId()

    if wheelchairEntity and DoesEntityExist(wheelchairEntity) then
        TriggerServerEvent('sWheelchairV2:ClearChair')
        TaskLeaveVehicle(ped, wheelchairEntity, 0)

        SetTimeout(500, function()
            if wheelchairEntity and DoesEntityExist(wheelchairEntity) then
                DeleteVehicle(wheelchairEntity)
            end
            wheelchairEntity = nil
        end)
    end
end

----------------------------------------------------------------
-- NETWORK EVENTS
----------------------------------------------------------------
RegisterNetEvent('sWheelchairV2:Apply', function(duration)
    if not duration or duration <= 0 then return end

    CreateThread(function()
        if not PutPlayerInWheelchair(true) then
            return
        end

        releaseTimeMs = GetGameTimer() + (duration * 1000)

        while isLocked do
            if GetGameTimer() >= releaseTimeMs then
                ReleasePlayer()
                break
            end
            Wait(250)
        end
    end)
end)

RegisterNetEvent('sWheelchairV2:Release', function()
    ReleasePlayer()
end)

-- reapply events
if Config.ReapplyEvents and #Config.ReapplyEvents > 0 then
    for _, ev in ipairs(Config.ReapplyEvents) do
        RegisterNetEvent(ev)
        AddEventHandler(ev, function(...)
            TriggerServerEvent('sWheelchairV2:RequestReapply')
        end)
    end
end

----------------------------------------------------------------
-- UI PANEL (NUI)
----------------------------------------------------------------
RegisterNetEvent('sWheelchairV2:OpenPanel', function()
    if panelOpen then return end
    panelOpen = true

    local labels = {
        Title      = _U('ui_title'),
        Subtitle   = _U('ui_subtitle'),
        IdLabel    = _U('ui_id_label'),
        IdHint     = _U('ui_id_hint'),
        TimeLabel  = _U('ui_time_label'),
        TimeHint   = _U('ui_time_hint'),
        Apply      = _U('ui_apply_button'),
        Close      = _U('ui_close_button'),
    }

    SendNUIMessage({
        action = 'open',
        payload = {
            labels = labels,
            theme  = Config.Theme or {}
        }
    })

    SetNuiFocus(true, true)
end)

local function ClosePanel()
    if not panelOpen then return end
    panelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('submitSentence', function(data, cb)
    local targetId = tonumber(data.targetId)
    local minutes  = tonumber(data.minutes)

    if not targetId or not minutes or minutes <= 0 then
        Notify(_U('invalid_player_id'), 'error')
        cb({})
        return
    end

    TriggerServerEvent('sWheelchairV2:ApplyFromUI', targetId, minutes)
    cb({})
end)

RegisterNUICallback('close', function(data, cb)
    ClosePanel()
    cb({})
end)

-- escape key / resource cleanup
RegisterNUICallback('escape', function(_, cb)
    ClosePanel()
    cb({})
end)

AddEventHandler('onClientResourceStop', function(res)
    if res == GetCurrentResourceName() then
        if wheelchairEntity and DoesEntityExist(wheelchairEntity) then
            DeleteVehicle(wheelchairEntity)
        end
        wheelchairEntity = nil
        SetNuiFocus(false, false)
    end
end)
