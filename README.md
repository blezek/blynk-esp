# Blynk for ESP8266 NodeMCU library

[Blynk](http://blynk.cc) is a iOS and Android app to control embedded devices such as the [ESP8266](http://esp8266.net/).  [NodeMCU](http://www.nodemcu.com/index_en.html) is a firmware and development kit implementing a Lua programming environment that executes directly on the ESP8266 without needed an embedded processor such as the Raspberry Pi or Arduino.

This repository implements the Blynk protocol in Lua using the NodeMCU libraries.

## Building Firmware

The Blynk library depends on the following modules:

- `file` implements a filesystem needed to store the `blynk.lua` library file
- `gpio` to interact with the ESP8266 pins
- `net` to communicate with the Blynk servers
- `pwd` pulse width modulation to set the LED intensity
- `struct` to compose and parse Blynk messages
- `tmr` to send periodic heartbeat messages to the Blynk server

The necessary [firmware can be built](http://nodemcu.readthedocs.io/en/dev/en/build/) using the fantastic cloud build service at http://nodemcu-build.com/.  The source must be from the `dev` branch to use the `struct` module.

Once built, use [ESPTool](https://github.com/themadinventor/esptool) to flash the firmware.

## Running under Lua

Edit the `init.lua` to set WiFi Access Point, password and [Blynk token](http://docs.blynk.cc/#getting-started-getting-started-with-the-blynk-app-4-auth-token).

```lua
-- These are not real values, replace with your own!
token = "your token here"
wifi_password = "SuperSecret"
wifi_access_point = "ThisSpaceForRent"
```

Download the Blynk app ( [Android](http://j.mp/blynk_Android) or [iOS](http://j.mp/blynk_iOS)), load the sample Blynk app, touch the QR icon and point the camera to the code below or visit http://tinyurl.com/jkpse8h.

![QR](Blynk-esp-qr.png)

## Using the library

### Create a Blynk object

```lua
b = blynk.new ( token, timer, callback )
```

`blynk.new` takes the following arguments

- `token` a [Blynk token](http://docs.blynk.cc/#getting-started-getting-started-with-the-blynk-app-4-auth-token)
- `timer` the timer (0-6) to use for the Blynk heartbeat
- `callback` a function taking the newly created Blynk object for initial configuration

### Configure callbacks

The `callback` argument to `blynk.new` should be used to make the Blynk object respond to different Blynk events.  The callback is invoked as:

```lua
-- b is the newly created Blynk Lua object
callback (b )
```

The following Blynk events are supported:

| Callback | Argument(s) | Description |
|----------|-----------|-------------|
| `vw`         |  `{"vw", pin, value }`         |  The Blynk server sets `pin` to `value`. `pin` is a text string. `value` is a text string with range set by the Blynk app.           |
|  `vr`        |  `{"vr", pin}, message_id`          |  The Blynk app is requesting a read of the virtual pin `pin`.  The Lua code should respond by creating a message with the value of the virtual pin `pin` and return.  For example: `b:send_message(blynk.commands["hardware"], message_id, b:pack('vw', '5', tostring(value)))`            |
|   `aw`       |  `{"aw", pin, value}`         |  Analog pin write.            |
|   `ar`       |  `{"aw", pin}, message_id`         |  Analog pin write.            |
|   `dw`       |  `{"aw", pin, value}`         |  Digital pin write.            |
|   `dr`       |  `{"aw", pin}, message_id`         |  Digital pin write.            |
| `pw` | `{"pw", <pin>, <mode>, <pin>, <mode>, ...}` | Instructs the ESP to set pin modes for each `<pin>` and `<mode>` combination.  |

The following Blynk Lua events are supported:

| Callback | Argument(s) | Description |
|----------|-----------|-------------|
| `receive` | `socket, command` | Called when the ESP receives a command from the server.  The `socket` is the connection receiving the command, and `command` is the raw set of bytes form the Blynk server.  See `blynk.dump` for details. |
| `connection` | `socket` | Called when the ESP connects to the Blynk server (blynk-cloud.com by default). |
| `disconnection` | | Called when the ESP is disconnected from the Blynk server |

Callbacks are set using the `on` method.

```lua
   b:on ( 'vr', function(cmd, original_mid)
             local mid = b:mid()
             local pin = cmd[2]
             print ( "read virtual pin " .. pin)
             local value = gpio.read(read_pins[pin])
             print ( "virtual pin " .. pin .. " value " .. value .. ' message id ' .. mid)
             b:send_message(blynk.commands["hardware"], original_mid, b:pack('vw', '5', tostring(value)))
   end)
```
`blynk.commands` is a lookup table for useful Blynk protocol responses.  See `init.lua` for more examples.

### Pin modes

- `in` INPUT mode
- `out` OUTPUT mode
- `pu` INPUT pull up mode
- `pd` INPUT pull down mode

### Sending commands

```lua
-- Cause a notification to be sent
b:send_message(blynk.commands["notify"], b:mid(), "you pushed a button")
```

### Methods

| Method | Description |
|----|----|
| `connect()` | Connect to the Blynk server.  Configures a heartbeat every 5 seconds. |
| `on (event, function)` | Configures a callback `function` on the `event`.  `event` is a text string, e.g. `"wr"`, etc.|
| `pack(...)` | Creates a null (`\0`) separated list suitable for sending to the Blynk server|
| `dump(command)` | Returns a formatted representation of the command from the Blynk server.  The first return value is a string describing the command human readable form, the second return value is a hex dump.  Useful for debugging.  `local f,d = self:dump(msg); print ("< " .. f .. " -- " .. d)`|
| `queue(message, socket)` | Queues a `message`.  The `socket` command is optional and defaults to `self.conn`. |
| `create_message (command, message_id, payload)` | Creates a proper Blynk formatted message given `command`, `message_id` and `payload`.  `command` should be one of `blynk.commands`, `message_id` should be a new message id generated by `self:mid()` or given in a callback, and `payload` is created using the `self:pack(...)` command. |
| `send_message(command,message_id, payload)` | Creates the message using `create_message` and sends using `queue`|

