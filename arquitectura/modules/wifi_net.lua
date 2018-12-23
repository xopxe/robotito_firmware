--- WiFi network system. 
-- @module wifi_net
-- @alias M
local M = {}

local udp_tx, udp_rx

--- Current network status
-- One of `'offline'`, `'associating'`, `'setting up'` or `'online'`.
local wifi_status = 'offline'

--- Starts the network.
-- @param conf a configuration table, with keys:  
--* mode `'sta'` for client or `'ap'` for AP modes.  
--* ssid string with network name (min length 7?)  
--* passwd password to use
--* channel number 0..11, defaults to 0 (auto).
-- @return string with the ip adress.
local start_network = function (conf)
  local my_ip
  if conf.mode == 'sta' then 
    M.wifi_status = 'associating'
    print("Associating to " .. conf.ssid)
    net.wf.setup(net.wf.mode.STA, conf.ssid, conf.passwd)
    net.wf.start()
    while not net.connected() do
      print("connecting...")
      tmr.sleep(1)
    end
    print("Associated.")
  elseif conf.mode == 'ap' then
    M.wifi_status = 'setting up'
    net.wf.setup(
      net.wf.mode.AP, 
      conf.ssid, 
      conf.passwd, 
      net.wf.powersave.NONE, --net.wf.powersave.MODEM
      conf.channel or 0, 
      false
    )
    net.wf.start()
  end

  tmr.sleep(1)
  local net_stat = net.stat( true )
  for _, iface in pairs(net_stat) do
    print ('found interface', iface.interface, iface.ip)
    if iface.interface == 'wf' then
      my_ip = iface.ip
      break
    end
  end
  print("IP Address: ", tostring(my_ip))

  wifi_status = 'online'

  return my_ip
end

local start_rc = function (my_ip, conf)
  local socket = require ('socket')

  udp_tx = socket.udp()
  udp_tx:setpeername(conf.broadcast or '255.255.255.255', conf.udp_announce_port)
  udp_rx = socket.udp()
  udp_rx:setsockname(my_ip, conf.udp_port)
  udp_rx:settimeout(conf.receive_timeout)

  local id = (robot or {}).id or '?'
  local announcement_base = 'ROBOTITO '..tostring(id)..' '
  ..my_ip..' '..conf.udp_port..' '..os.resetreason()

  if conf.announce_interval>0 then 
    M.thr_announcement = thread.start(function()
        while true do
          local announcement=announcement_base..' '..os.gettime()
          --print('announcing', announcement)
          udp_tx:send(announcement)
          thread.sleep(conf.announce_interval)
        end
      end, nil, nil, nil, 'announcer')
  end

  M.thr_receiver = thread.start(function()
      while true do
        local data, ip, port = udp_rx:receivefrom()
        M.cb.call(data, ip, port)
      end
    end, nil, nil, nil, 'receiver')
end

--- Broadcasts a message.
-- @param msg a string.
M.broadcast = function (msg)
  if udp_tx then
    udp_tx:send(msg)
  end
end

--- The callback module for messages arrival.
-- This is a callback list attached to the socket, see @{cb_list}.
-- @usage local wifi_net = require 'wifi_net'
--wifi_net.cb.append( function (msg, ip, port) print(ip..':'..port, msg) end )
-- @param msg a string with the message
-- @param ip the IP address of the sender
-- @param port the port of the sender
M.cb = require'cb_list'.get_list()

--- Initialize network.
-- The system reads the configuration parameters from the config table, and if
-- the table or some parameter is ommitted it will get it from 
-- nvs.read('wifi', parameter). The parameters are:  
--* `'mode'`: either 'ap' or 'sta', defaults ot 'none' (disabled)  
--* `'ssid'`: the wireless network ssid  
--* `'passwd'`: the wireless network password  
--* `'channel'`: defaults to 0 (auto)  
--* `'udp_port'`: listening port, defaults to 2018   
--* `'broadcast'`: target address for the announcements (defaults to)
--'255,255,255,255'  
--* `'udp_announce_port'`: announcement port, defaults to 2018  
--* `'udp_announce_interval'`: time between announcements (in s),
-- -1 mean disabled. Defaults to 10.  
--* `'receive_timeout'`: timeout for udp reads (in sec). Defaults to -1
-- (disabled).  
-- @param conf configuration table
M.init = function (conf)
  conf = conf or {}
  --local iface_config = {}
  conf.mode = conf.mode or nvs.read("wifi","mode", "none") or "none"
  conf.ssid = conf.ssid or 
    nvs.read("wifi","ssid", "robotito"..((robot or {}).id or '')) 
    or "robotito"..((robot or {}).id or '')
  conf.passwd = conf.passwd or nvs.read("wifi","passwd", "robotito") 
    or "robotito"
  conf.channel = conf.channel or nvs.read("wifi","channel", 0) or 0

  print ('wifi mode:'..conf.mode
    ,'ssid:'..conf.ssid
    ,'passwd:'..conf.passwd)

  --local rc_config = {}
  conf.udp_port = conf.udp_port or 
    nvs.read("wifi","udp_port", 2018) or 2018
  conf.udp_announce_port = conf.udp_announce_port or 
    nvs.read("wifi","udp_announce_port", 2018) or 2018
  conf.broadcast = conf.broadcast or 
    nvs.read("wifi","broadcast", '255.255.255.255') or '255.255.255.255'
  conf.announce_interval = conf.announce_interval or 
    nvs.read("wifi","announce_interval", 10) or 10
  conf.receive_timeout = conf.receive_timeout or 
    nvs.read("wifi","receive_timeout", -1) or -1

  print('listen port:'..conf.udp_port
    ,'timeout:'..tostring(conf.receive_timeout))
  print('announce port:'..tostring(conf.udp_announce_port)
    ,'bcast:'..conf.broadcast
    ,'interval:'..tostring(conf.announce_interval))

  if conf.mode ~= "none" then
    try(
      function() 
        local my_ip = start_network(conf) --(iface_config)
        start_rc(my_ip, conf) --rc_config)
      end,
      print, 
      function() 
        print("Network:", wifi_status)
        print("Announcer:", 
          (M.thr_announcement and thread.status(M.thr_announcement)))
        print("Receiver:", 
          (M.thr_receiver and thread.status(M.thr_receiver)))
        if wifi_status ~= 'online' then 
          wifi_status = 'offline' 
        end
      end
    )
  end
end

return M