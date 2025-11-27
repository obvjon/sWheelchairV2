fx_version 'cerulean'
game 'gta5'

author 'Sansui'
description 'sWheelchairV2 – framework-agnostic wheelchair sentencing with item-based UI'
version '2.1.0'

lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/style.css'
}

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/config.lua',
    'shared/locales.lua',
    'shared/bridge.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}
