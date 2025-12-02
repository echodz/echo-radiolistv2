fx_version  "cerulean"
use_experimental_fxv2_oal   "yes"
lua54       "yes"
game        "gta5"

name        "echo-radiolist"
version     "0.0.1"
repository  "https://github.com/echodz/echo-radiolistv2"
description "echo Radio List / x-radiolist : List of players in each radio channels to be used with PMA-VOICE"

ui_page "web/index.html"

files {
    "web/index.html"
}

shared_scripts {
    "shared/*.lua"
}

server_script {
    "module/**/server.lua",
    "server/*.lua"
}

client_script {
    "module/**/client.lua",
    "client/*.lua"
}

