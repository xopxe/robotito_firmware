local ahsm = require 'ahsm'
local omni = require('omni')
local laser = require 'laser_ring'

local e_dist = {
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {},
    [5] = {},
    [6] = {}
  }
  
for i, e in ipairs(e_dist) do
    local pi = math.pi
	e.dirx = math.cos(pi/6 + (i-1)*pi/3)
    e.diry = math.sin(pi/6 + (i-1)*pi/3)
    e.maxdist = 0
end



--VARIABLES

local range = function(num)
    return (num > 0 and num < 100)
end

local s_far

local angle
local t_ms = 100 -- period of distance measurements
local dtheta = (math.pi/3)/30 -- partition of pi/3
local w = 1000*dtheta/t_ms -- rad/s
--[[
t_ms ms ____ dtheta rad
1000 ms ____ w = 1000*dtheta/t_ms rad
]]--
local find_sense

--CALLBACKS

local callback_search = function(d1,d2,d3,d4,d5,d6)
    local argmax = function(t)
        local index = 0
        local max = 0
        for i = 1,6 do
            if (range(t[i]) and t[i] > max) then
                index = i
                max = t[i]
            end
        end	
        return index
    end
    
    norm_d = laser.norm_d
    print(norm_d[1],norm_d[2],norm_d[3],norm_d[4],norm_d[5],norm_d[6])
    angle = angle + dtheta
    if (angle < math.pi/3) then
        print('callback')
        for i = 1,6 do
            if(range(norm_d[i]) and norm_d[i] > e_dist[i].maxdist) then
                e_dist[i].maxdist = norm_d[i]
            end
        end
    else
        --print('callback else')
        omni.drive(0,0,0)
        local d = {}
        for i = 1,6 do
            d[i] = e_dist[i].maxdist
        end
        s_far = argmax(d)
        if (s_far == 0) then --every sensor is out of range
            print('ksearch')
            robot.hsm.queue_event(e_ksearch) --keep state
        else
            print('back')
            robot.hsm.queue_event(e_back) --change state
        end
    end
end -- callback_search

local callback_back = function(d1,d2,d3,d4,d5,d6)
    norm_d = laser.norm_d
    angle = angle + dtheta
    if (angle < math.pi/3) then
        local actual = norm_d[s_far]
        local max = e_dist[s_far].maxdist
        local th_dist = 10
        if (actual < max + th_dist and actual > max - th_dist) then
            robot.hsm.queue_event(e_position) --change state
        end
    else
        e_dist[s_far].maxdist = norm_d[s_far]
        robot.hsm.queue_event(e_bsearch) --change state
    end
end


local callback_position = function(d1,d2,d3,d4,d5,d6)
    norm_d = laser.norm_d
    local actual = norm_d[s_far]
    local previous = e_dist[s_far].maxdist
    if (not find_min) then
        find_min = true
        if (actual > previous) then
            omni.drive(0,0,w)
        end
    else
        if (actual > previous) then
            omni.drive(0,0,0)
            robot.hsm.queue_event(e_forward)
        end
    end
end

local callback_forward = function(d1,d2,d3,d4,d5,d6)
    norm_d = laser.norm_d
    local actual = norm_d[s_far]
    local previous = e_dist[s_far].maxdist
    if (actual > previous) then
        robot.hsm.queue_event(e_repos) --change state
    else if (actual == 0) then
        robot.hsm.queue_event(e_search)
    end
    end
    e_dist[s_far].maxdist = actual

end

--EVENTS

local e_ksearch = { _name = "KEEP_SEARCH" }
local e_back = { _name = "GO_BACK" }
local e_bsearch = { _name = "BACK_SEARCH" }
local e_position = { _name = "GO_POSITION" }
local e_forward = { _name = "GO_FORWARD" }
local e_repos = { _name = "RE_POSITION" }
local e_search = { _name = "SEARCH_AGAIN" }


--STATES

local s_search = ahsm.state{
    entry = function()
        angle = 0
        for i,e in ipairs(e_dist) do
            e.maxdist = 0
        end
        omni.drive(0,0,w)
        laser.cb.append(callback_search)
        laser.enable(true)
        omni.enable(true)
    end,
    exit = function()
        laser.enable(false)
        laser.cb.remove(callback_search)
    end
}

local s_back = ahsm.state{
    entry = function()
        angle = 0
        omni.drive(0,0,-w)
        laser.cb.append(callback_back)
        laser.enable(true)
    end,
    exit = function()
        omni.drive(0,0,0)
        laser.enable(false)
        laser.cb.remove(callback_back)
    end
}

local s_position = ahsm.state{
    entry = function()
        find_min = false
        omni.drive(0,0,-w)
        laser.cb.append(callback_position)
        laser.enable(true)
    end,
    exit = function()
        omni.drive(0,0,0)
        laser.enable(false)
        laser.cb.remove(callback_position)
    end
}

local s_forward = ahsm.state{
    entry = function()
        local dirx = e_dist[s_far].dirx
        local diry = e_dist[s_far].diry
        omni.drive(dirx*v,diry*v,0)
        laser.cb.append(callback_forward)
        laser.enable(true)
    end,
    exit = function()
        omni.drive(0,0,0)
        laser.enable(false)
        laser.cb.remove(callback_forward)
    end
}

--TRANSITIONS

local t_ksearch = ahsm.transition {
    src = s_search, tgt = s_search,
    events = {e_ksearch}
}

local t_back = ahsm.transition {
    src = s_search, tgt = s_back,
    events = {e_back}
}

local t_bsearch = ahsm.transition {
    src = s_back, tgt = s_search,
    events = {e_bsearch}
}

local t_pos = ahsm.transition {
    src = s_back, tgt = s_position,
    events = {e_position}
}

local t_forw = ahsm.transition {
    src = s_position, tgt = s_forward,
    events = {e_forward}
}

local t_repos = ahsm.transition {
    src = s_forward, tgt = s_position,
    events = {e_repos}
}

local t_search = ahsm.transition {
    src = s_forward, tgt = s_search,
    events = {e_search}
}



local distance = ahsm.state {
    states = { SEARCH = s_search, BACK = s_back, POSITION = s_position, FORWARD = s_forward},
    transitions = {
        keep_search = t_ksearch,
        switch_back = t_back,
        switch_bsearch = t_bsearch,
        switch_pos = t_pos,
        switch_forw = t_forw,
        switch_repos = t_repos,
        switch_search = t_search,
    },
    events = {
        e_ksearch,
        e_back,
        e_bsearch,
        e_position,
        e_forward,
        e_repos,
        e_search,
    },
    initial = s_search,
    entry = function()
        robot.laser_ring.enable(true)
    end
}

return distance