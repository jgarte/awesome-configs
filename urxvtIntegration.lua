--Improve integration between awesome and the RXVT-unicode terminal (urxvt)
--Author: Emmanuel Lepage Vallee <elv1313@gmail.com>

local setmetatable = setmetatable
local loadstring = loadstring
local io = io
local ipairs = ipairs
local table = table
local print = print
local type = type
local next = next
local util = require("awful.util")
local capi = { screen = screen,
               mouse = mouse,
               timer = timer}

module("urxvtIntegration")

local data = {}

local function cumulCpu(pid)
  local result = 0
  if data["pid_"..pid] ~= nil then
    for i, v in next, data["pid_"..pid] do
      result = result + v.pcpu
    end
    --print("add: "..result)
    return result
  else
    return 0
  end
end

local function cumulMem(pid)
  local result = 0
  if data["pid_"..pid] ~= nil then
    for i, v in next, data["pid_"..pid] do
      result = result + v.pmem
    end
    return result
  else
    return 0
  end
end

function getTabTitle(pid,id) 
  local f = io.popen('dbus-send --session --print-reply --dest=org.schmorp.urxvt --type="method_call" /pid/12/1 org.schmorp.urxvt.getTitle | tail -n1 | grep -E "[a-zA-Z0-9 ]*" -o | tail -n1')
  local title = f:read("*all")
  f:close()
  return title
end

function addTab(pid)
  print('dbus-send --type=method_call --dest=org.schmorp.urxvt /pid/12/control org.schmorp.urxvt.addTab')
  util.spawn('dbus-send --type=method_call --dest=org.schmorp.urxvt /pid/12/control org.schmorp.urxvt.addTab')
  --io.popen('dbus-send --type=method_call --dest=org.schmorp.urxvt /pid/12/control org.schmorp.urxvt.addTab')
end

function register(widget, pid, type, intervale) --TYPE=cpup or memp
  local mytimer = capi.timer({ timeout = intervale })
  mytimer:add_signal("timeout", function ()
    if type == "pcpu" then
      widget:add_value(cumulCpu(pid))
    else
      widget.text = "[mem:"..cumulMem(pid).."%]"
    end
  end)
  mytimer:start()
end

function new(screen, args) 
  local script = io.open(util.getdir("config") .."/Scripts/urxvtStat.sh",'r')
  local toExec = script:read("*all")
  local mytimer = capi.timer({ timeout = 3 })
  mytimer:add_signal("timeout", function ()
    local hook = io.popen(toExec)
    if hook ~= nil then
      local psResult = hook:read("*all")
      --print(psResult)
      hook:close()
      local afunction = loadstring(psResult)
      local termList = nil
      if afunction ~= nil then
        termList = afunction()
        data = termList
      else
        print("A function failed")
      end
      
      --cumulCpu(31619)
    end    
  end)
  mytimer:start()
  return
end


setmetatable(_M, { __call = function(_, ...) return new(...) end })