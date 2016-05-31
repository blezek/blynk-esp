--    ./pseudo-library.py -t 7c56ff04efe24ed5b54428ac1e7380e6 --dump


blynk = {}
blynk.__index = blynk
blynk.commands = { register = 1, login = 2, ping = 6, activate = 7, deactivate = 8, notify = 14, hardware = 20, tweet = 12, email = 13  }
blynk.status = { success = 200, illegal_command = 2, not_registered = 3, not_authenticated = 5, invalid_token = 9 }


function blynk.dump(self,c)
   local t, i, status_value, cmd = ''
   local f
   t, i, status_value = struct.unpack(">BI2I2", c)
   f = t .. " "  .. i .. " " .. status_value
   if t ~= 0 and status_value > 0 then
      t, i, cmd = struct.unpack(">BI2I2c0", c)
      cmd = self:split(cmd)
      f = f .. " '" .. table.concat(cmd, ' ') .. "'"
   end
   local bytes = {}
   table.insert(bytes, string.format("0x%x", t))
   table.insert(bytes, string.format("0x%x", i))
   table.insert(bytes, string.format("0x%x", status_value))
   for i=6,#c do
      table.insert(bytes, string.format("%x", string.byte(c,i)))
   end
   return f, table.concat(bytes, ' ')
end


function blynk.new(token,timer_id, setup)
   local self = setmetatable({}, blynk)
   self.token = token
   self.timer_id = timer_id
   self.message_id = 1
   self.callbacks = {}
   self.message_queue = {}
   if setup ~= nil then setup(self) end
   return self
end

function blynk.connect(self)
   self.conn = net.createConnection(net.TCP, 0 )
   self.conn:on ( "receive", function (s, c)
                     if self.callbacks["receive"] ~= nil then self.callbacks["receive"](s,c) end
                     local t, i, status_value, cmd = ''
                     -- print ( "received from cloud " .. string.len(c) )
                     t, i, status_value = struct.unpack(">BI2I2", c)
                     print ( "type: " .. t .. " id: " .. i .. " status: " .. (status_value or 'nil') )
                     if t ~= 0 and status_value > 0 then
                        t, i, cmd = struct.unpack(">BI2I2c0", c)
                        cmd = self:split(cmd)
                        -- print ( 'unpacked command ' )
                        -- for _, value in pairs(cmd) do
                        --    print ( '\t' .. value )
                        -- end
                        -- print ("> " .. f .. " -- " .. d)
                        local f = self.callbacks[cmd[1]]
                        if f ~= nil then
                           f ( cmd, i )
                        end
                     end
                     local f,d = self:dump(c)
                     print ("> " .. f .. " -- " .. d)
                     
                     if not tmr.state(self.timer_id) then
                        tmr.register(self.timer_id, 10000, tmr.ALARM_AUTO, function()
                                        -- Send a heartbeat
                                        -- print ( "heartbeat" )
                                        self:queue(self:create_message(6, self:mid(), nil),s)
                        end)
                        tmr.start(self.timer_id)
                     end
   end)

   self.conn:on ( "sent", function(s)
                     self:process_queue(s)
   end)

   
   self.conn:on ( "connection", function (s)
                     print ( "Connected to blynk cloud, logging in")
                     self:queue( self:create_message(blynk.commands["login"], self:mid(), self.token), s)
                     if self.callbacks["connection"] ~= nil then self.callbacks["connection"](s) end
   end)
   self.conn:on ( "disconnection", function (s)
                     print ( "disconnected from blynk cloud")
                     if tmr.state(self.timer_id) then
                        -- print ( "stopping timer" )
                        tmr.stop(self.timer_id)
                     end
                     if self.callbacks["disconnection"] ~= nil then
                        self.callbacks["disconnection"]()
                     end
   end)
   self.conn:connect(8442, "blynk-cloud.com")
   return self
end

function blynk.queue(self,message,s)
   table.insert(self.message_queue, message)
   self:process_queue(s)
end

function blynk.process_queue(self, s)
   if s == nil then
      s = self.conn
   end
   if #self.message_queue > 0 then
      s:send(table.remove(self.message_queue,1))
   end
end


function blynk.disconnect(self)
   self.conn:close()
   return self
end

function blynk.split(self,cmd)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( cmd, '\0', from  )
  while delim_from do
    table.insert( result, string.sub( cmd, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( cmd, '\0', from  )
  end
  table.insert( result, string.sub( cmd, from  ) )
  return result
end

function blynk.pack (self,...)
   return table.concat(arg, string.char(0))
end

function blynk.on(self, message, fun)
   self.callbacks[message] = fun
   return self
end

function blynk.mid(self)
   self.message_id = self.message_id+1
   return self.message_id
end

-- create and send
function blynk.send_message ( self, cmd, mid, payload )
   self:queue(self:create_message(cmd,mid,payload))
end

-- a blynk message is 8bit type, 16bit mid, 16bit length, payload and '\0'
function blynk.create_message ( self, cmd, mid, payload )
   -- > is big endian
   -- B char, I2 is 2 bytes
   -- sn is a 2byte length followed by the bytes
   local msg
   if payload ~= nil then
      -- print ( "message is: " .. cmd .. " " .. mid .. " " .. string.len(payload) .. ' ' .. payload)
      msg = struct.pack ( ">BI2I2c0", cmd, mid, string.len(payload), payload)
   else
      -- print ( "message is: " .. cmd .. " " .. mid )
      msg = struct.pack ( ">BI2I2", cmd, mid, 0)
   end
   local f,d = self:dump(msg)
   print ("< " .. f .. " -- " .. d)
   return msg
end

