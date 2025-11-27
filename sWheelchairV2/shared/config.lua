Config = {}

----------------------------------------------------------------
-- CORE / FRAMEWORK
----------------------------------------------------------------
-- 'esx' | 'qbcore' | 'qbx'
Config.Framework = 'esx'
Config.FrameworkDebug = true

----------------------------------------------------------------
-- NOTIFICATIONS
----------------------------------------------------------------
-- 'ox_lib' | 'esx' | 'qb' | 'chat' | 'none'
Config.Notify = 'ox_lib'

Config.NotifyTypes = {
    info    = 'info',
    success = 'success',
    warning = 'warning',
    error   = 'error'
}

----------------------------------------------------------------
-- LOCALE
----------------------------------------------------------------
Config.Locale = 'en'

----------------------------------------------------------------
-- WHEELCHAIR SETTINGS
----------------------------------------------------------------
Config.WheelchairModel = 'iak_wheelchair'

-- Jobs allowed to sentence/remove via UI/commands
Config.AllowedJobs = {
    police    = true,
    sheriff   = true,
    ambulance = true
}

-- Default sentence length in minutes if none given
Config.DefaultSentenceMinutes = 10

-- Server cleanup interval for expired sentences
Config.CleanupInterval = 60 * 1000 -- ms

-- Client check interval for fall-out / reseat handling
Config.ClientCheckInterval = 300 -- ms

-- Seat attempts for initial seat / reseat
Config.MaxSeatAttempts = 20
Config.SeatAttemptDelay = 75

-- Reseat safety
Config.MaxReseatAttempts = 3          -- max attempts per window
Config.ReseatWindowMs    = 10 * 1000  -- window in ms
Config.ReseatFailureAction = 'release' -- 'release' | 'ignore'

----------------------------------------------------------------
-- DB SETTINGS
----------------------------------------------------------------
Config.DB = {
    TableName = 'wheelchair_sentences'
}

----------------------------------------------------------------
-- REAPPLY EVENTS
----------------------------------------------------------------
Config.ReapplyEvents = {
    '17mov_CharacterSystem:PlayerSpawned',
    -- 'esx:playerLoaded',
    -- 'QBCore:Client:OnPlayerLoaded',
    -- 'QBX:Client:OnPlayerLoaded',
}

----------------------------------------------------------------
-- ITEM / INVENTORY SETTINGS
----------------------------------------------------------------
Config.Item = {
    Name = 'wheelchair',      -- item name in your inventory
    UseFrameworkItem = true,  -- RegisterUsableItem / CreateUseableItem
    -- Optional: if your inventory emits a custom event when item is used
    CustomInventory = {
        Enabled = false,
        EventName = 'yourInventory:useWheelchair' -- server event
    }
}

-- UI triggers
Config.UI = {
    -- Fallback command to open panel (in addition to item)
    EnableCommandFallback = true,
    CommandName = 'wheelchairui',

    -- Only allow jobs in Config.AllowedJobs to open the UI?
    RestrictToJobs = true
}

----------------------------------------------------------------
-- THEME (mapped to CSS variables via JS)
----------------------------------------------------------------
Config.Theme = {
    bg = '#12181f',
    bg_card = '#161e26',
    bg_card_soft = '#1b242d',
    accent = '#4fe3ff',
    accent_soft = 'rgba(79,227,255,0.14)',
    text = '#e6f5ff',
    text_muted = '#8fa0ad',
    danger = '#ff4f5e',
    success = '#4fff99',
    border = '#233340',
}

