--- WiFi network system. 
-- @module wifi_net
-- @alias M
local M = {}

local udp_tx, udp_rx
local gettime, resetreason = os.gettime, os.resetreason

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

  local announcement_base = 'ROBOTITO '..my_ip..' '..conf.udp_port
  ..' '..resetreason()

  if conf.announce_interval>0 then 
    M.thr_announcement = thread.start(function()
        while true do
          local announcement=announcement_base..' '..gettime()
          print('announcing', announcement)
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
  udp_tx:send(msg)
end

--- The callback module messages arrival.
-- This is a callback list attached to the socket, see @{cb_list}.
M.cb = require'cb_list'.get_list()

--- Initialize network.
-- The system uses nvs.read('wifi', parameter) to initialize, where 
-- parameters are:  
--* `'mode'`: either 'ap' or 'sta', defaults ot 'ap'  
--* `'ssid'`  
--* `'passwd'`  
--* `'channel'`: defaults to 0 (auto)  
--* `'udp_port'`: listening port, defaults to 2018   
--* `'udp_announce_port'`: announcement port, defaults to 2018  
--* `'broadcast'`: target address for the announcements (defaults to)
--'255,255,255,255'  
--* `'udp_announce_interval'`: time between announcements (in sec),
-- -1 means disabled. Defaults to 10.  
--* `'receive_timeout'`: timeout for udp reads (in sec). Defaults to -1
-- (disabled).  
M.init = function ()
  local iface_config = {}
  iface_config.mode = nvs.read("wifi","mode", "ap") or "ap"
  iface_config.ssid = nvs.read("wifi","ssid")
  iface_config.passwd = nvs.read("wifi","passwd")
  iface_config.channel = nvs.read("wifi","channel", 0) or 0

  uart.write(uart.CONSOLE,'wifi mode:'..iface_config.mode
    ..' ssid:'..iface_config.ssid
    ..' passwd:'..iface_config.passwd..'\r\n')

  local rc_config = {}
  rc_config.udp_port = nvs.read("wifi","udp_port", 2018) or 2018
  rc_config.udp_announce_port = nvs.read("wifi","udp_announce_port", 2018) 
  or 2018
  rc_config.broadcast = nvs.read("wifi","broadcast", '255.255.255.255') 
  or '255.255.255.255'
  rc_config.announce_interval = nvs.read("wifi","announce_interval", 10) or 10
  rc_config.receive_timeout = nvs.read("wifi","receive_timeout", -1) or -1

  uart.write(uart.CONSOLE, 'listen port:'..rc_config.udp_port
    ..' timeout:'..tostring(rc_config.receive_timeout)..'\r\n')
  uart.write(uart.CONSOLE, 'announce port:'
    ..tostring(rc_config.udp_announce_port)..' bcast:'..rc_config.broadcast
    ..' interval:'..tostring(rc_config.announce_interval)..'\r\n')

  try(
    function() 
      local my_ip = start_network(iface_config)
      start_rc(my_ip, rc_config)
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

return M