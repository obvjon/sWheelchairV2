Locales = Locales or {}

Locales['en'] = {
    -- core messages
    not_allowed           = 'You are not allowed to use this.',
    invalid_player_id     = 'Invalid player ID.',
    could_not_identifier  = 'Could not resolve player identifier.',
    sentence_applied      = 'Player placed in wheelchair for %s minutes.',
    sentence_received     = 'You have been placed in a wheelchair.',
    sentence_removed      = 'Wheelchair removed from player.',
    sentence_released     = 'You have been released from the wheelchair.',
    sentence_resumed      = 'Your wheelchair sentence has resumed.',
    no_active_sentence    = 'No active wheelchair sentence found.',
    debug_framework_fail  = 'sWheelchairV2: Failed to initialize framework (%s).',
    reseat_fail_release   = 'Safety: wheelchair sentence ended early due to repeated reseat failures.',

    -- UI strings
    ui_title              = 'Wheelchair',
    ui_subtitle           = 'Temporary mobility restriction',
    ui_id_label           = 'Player ID',
    ui_id_hint            = 'Enter in-game server ID.',
    ui_time_label         = 'Time (minutes)',
    ui_time_hint          = 'How long to keep them in the wheelchair.',
    ui_apply_button       = 'Apply Sentence',
    ui_close_button       = 'Close',
}

function _U(key, ...)
    local lang = Config.Locale or 'en'
    local dict = Locales[lang] or Locales['en'] or {}
    local str = dict[key] or key

    if select('#', ...) > 0 then
        return string.format(str, ...)
    end

    return str
end
