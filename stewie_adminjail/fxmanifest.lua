fx_version 'cerulean'
game 'gta5'

name 'stewie_adminjail'
author 'Stewie'
description 'Admin Jail'

shared_scripts {
    '@ox_lib/init.lua',
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

lua54 'yes'

dependencies {
    'ox_lib',
    'PolyZone'
}

server_scripts {
    'server/server.lua'
}