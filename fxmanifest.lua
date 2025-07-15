fx_version 'cerulean'
game 'gta5'

author 'Kravs'
description 'Advanced vehicle testing and preview system with web interface'
version '2.0.0'

shared_scripts {
    'config/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'data/vehicles.json'
}
