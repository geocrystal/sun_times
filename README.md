# ☀️ sun_times

[![Crystal CI](https://github.com/geocrystal/sun_times/actions/workflows/crystal.yml/badge.svg)](https://github.com/geocrystal/sun_times/actions/workflows/crystal.yml)
[![GitHub release](https://img.shields.io/github/release/geocrystal/sun_times.svg)](https://github.com/geocrystal/sun_times/releases)
[![License](https://img.shields.io/github/license/geocrystal/sun_times.svg)](https://github.com/geocrystal/geojson/blob/main/LICENSE)

A simple [Crystal](https://crystal-lang.org) library for calculating 🌅 **sunrise** and 🌇 **sunset** given latitude, longitude, and date based on
the [NOAA Solar Calculator](https://gml.noaa.gov/grad/solcalc/) and formulas from
Jean Meeus’ _Astronomical Algorithms (2nd Edition, 1998)_.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     sun_times:
       github: geocrystal/sun_times
   ```

2. Run `shards install`

## Usage

```crystal
require "sun_times"

# Example: Lviv, Ukraine
# SunTime.new(latitude : Float64, longitude : Float64)
sun = SunTimes::SunTime.new(49.8419, 24.0311)
location = Time::Location.load("Europe/Kyiv")
date = Time.local

astronomical_dawn_time = sun.astronomical_dawn(date, location)
nautical_dawn_time = sun.nautical_dawn(date, location)
civil_dawn_time = sun.civil_dawn(date, location)
sunrise_time = sun.sunrise(date, location)
solar_noon_time = sun.solar_noon(date, location)
sunset_time = sun.sunset(date, location)
civil_dusk_time = sun.civil_dusk(date, location)
nautical_dusk_time = sun.nautical_dusk(date, location)
astronomical_dusk_time = sun.astronomical_dusk(date, location)
daylight_length = sun.daylight_length(date, location)

puts "Timezone: #{location}"
puts "Now:      #{date}"
puts
puts "=== Twilight Periods ==="
puts "Astronomical dawn:  #{astronomical_dawn_time}"
puts "Nautical dawn:      #{nautical_dawn_time}"
puts "Civil dawn:         #{civil_dawn_time}"
puts "Sunrise:            #{sunrise_time}"
puts "Solar noon:         #{solar_noon_time}"
puts "Sunset:             #{sunset_time}"
puts "Civil dusk:         #{civil_dusk_time}"
puts "Nautical dusk:      #{nautical_dusk_time}"
puts "Astronomical dusk:  #{astronomical_dusk_time}"
puts ""
puts "=== Daylight ==="
puts "Daylight:      #{daylight_length}"
```

Output:

```
Timezone: Europe/Kyiv
Now:      2025-11-05 12:17:00 +02:00

=== Twilight Periods ===
Astronomical dawn:  2025-11-05 05:29:35 +02:00
Nautical dawn:      2025-11-05 06:07:05 +02:00
Civil dawn:         2025-11-05 06:45:25 +02:00
Sunrise:            2025-11-05 07:19:39 +02:00
Solar noon:         2025-11-05 12:07:27 +02:00
Sunset:             2025-11-05 16:55:16 +02:00
Civil dusk:         2025-11-05 17:29:30 +02:00
Nautical dusk:      2025-11-05 18:07:50 +02:00
Astronomical dusk:  2025-11-05 18:45:20 +02:00

=== Daylight ===
Daylight:      9h 35m 36s
```

### Twilight Periods

The library supports three types of twilight periods:

- **Civil twilight** (sun 6° below horizon): Enough light for most outdoor activities
- **Nautical twilight** (sun 12° below horizon): Horizon is still visible for navigation
- **Astronomical twilight** (sun 18° below horizon): Sky is dark enough for astronomical observations

![image](https://github.com/geocrystal/sun_times/blob/main/samples/twilight_subcategories.png?raw=true)

## Contributing

1. Fork it (<https://github.com/geocrystal/sun_times/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer

## License

This library is distributed under the MIT license. Please see the LICENSE file.
