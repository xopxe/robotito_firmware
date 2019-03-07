wn=require'wifi_net'
wn.init({mode='ap'})

ws = require'webserver'
ws.init()

ws.ws_register('/', print)