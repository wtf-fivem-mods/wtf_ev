# wtf_ev

FiveM Electric Vehicle HUD, battery, charging, garage-charging

| WARNING: Work in progress! |
| --- |

This resource was created for demonstration purposes. Some features are basic, like `garagedemo`, and all scripts are client side.

In the future these may be integrated into frameworks and/or include their own server side/persistence logic.

## Requirements

 - [wtf_redis]
    - The `garagedemo/config.lua` offers the ability switch between in-memory (client) persistence and actual persistence using our [wtf_redis] library.
    - The default configuration is to use in-memory, but if you want to test out [wtf_redis], have a Redis server running on the same machine as the host.
    - Changing `Config.Garage.DB = DB.Client` to `Config.Garage.DB = DB.Redis` will switch the persitence method.
    - [wtf_redis] is in early development, currently expects the server to be at `127.0.0.1:6379`. The ability to configure [wtf_redis], and change this, is in the works. 

## wtf_ev

- EV HUD
    - EV vehicles display Whr (watt-hours) energy use
    - This figure is based on "RPMs" and Whr effects battery range
- EV Battery
    - EV vehicles have batteries instead of fuel
    - The battery discharge loosely follows real-life heuristics
        - A HUD is rendered on the minimap showing charge level %
        - Discharging uses a stepping function based on "RPM"
            - High RPMs (e.g. racing) will negatively effect range
            - Low RPMs benefit from less energy use
- EV Charger
    - Featuring the Tesla Supercharger 3D model
        - Via an included custom map: `wtf_tesla_supercharger`
    - Charging uses a quadratic Bezier curve
        - 0-60% takes ~30% of total charge time
        - &gt;61% takes the remaining time to reach full charge
    - Supports custom charging rates via `config.lua`
- Garage Demo
    - Mostly for demonstration purposes
    - Adds the concept of charging while your vehicle is stored in a garage
    - Supports custom charging rates via `config.lua`
        - Example: parking-garages charge faster than parking lots, which are faster than house-garages

## Download & Installation

This resource was developed alongside [wtf_teslax], [wtf_tesla_supercharger]. This resource works without them, but you might be interested in installing them altogether.

### Using Git
```
cd resources
git clone https://github.com/wtf-fivem-mods/wtf_ev [wtf]/wtf_ev/
git clone https://github.com/wtf-fivem-mods/wtf_redis [wtf]/wtf_redis/

git clone https://github.com/wtf-fivem-mods/wtf_teslax [wtf]/wtf_teslax/
git clone https://github.com/wtf-fivem-mods/wtf_tesla_supercharger [wtf]/wtf_tesla_supercharger/
```

### Manually
- Download https://github.com/wtf-fivem-mods/wtf_ev/archive/master.zip
- Create and place in in `[wtf]/wtf_ev` directory

## Installation
- Add this in your `server.cfg`:

```lua
start wtf_ev
-- if you downloaded related resources
start wtf_teslax
start wtf_tesla_supercharger
```

## Debug
- Debug commands available when `Config.Debug = True`
- `/teslax` spawns and places you in the Tesla Model X
- `/fuel 40` will set fuel to specified amount (40 as an example)

## Screenshots

![photo_2019-04-14_00-43-29 (5)](https://user-images.githubusercontent.com/79330/56089919-310eed80-5e4f-11e9-9fd1-fa0eb3027122.jpg)

![photo_2019-04-14_00-43-29 (6)](https://user-images.githubusercontent.com/79330/56089925-3a985580-5e4f-11e9-9ff3-eb9430e0fbaf.jpg)

![photo_2019-04-14_00-43-29 (4)](https://user-images.githubusercontent.com/79330/56089926-3f5d0980-5e4f-11e9-8809-cf90160ba203.jpg)

![photo_2019-04-14_00-43-29 (3)](https://user-images.githubusercontent.com/79330/56089928-41bf6380-5e4f-11e9-95c1-5727de1d4326.jpg)

![photo_2019-04-14_00-43-29 (2)](https://user-images.githubusercontent.com/79330/56089930-4552ea80-5e4f-11e9-8ac3-8dbdf466dc5a.jpg)

![photo_2019-04-14_00-43-29 (1)](https://user-images.githubusercontent.com/79330/56089931-47b54480-5e4f-11e9-9bdf-5183bf6a9ec6.jpg)

[wtf_teslax]: https://github.com/wtf-fivem-mods/wtf_teslax
[wtf_tesla_supercharger]: https://github.com/wtf-fivem-mods/wtf_tesla_supercharger
[wtf_redis]: https://github.com/wtf-fivem-mods/wtf_redis
