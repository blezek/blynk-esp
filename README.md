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

