# ☀️ sun_times

[![Crystal CI](https://github.com/geocrystal/sun_times/actions/workflows/crystal.yml/badge.svg)](https://github.com/geocrystal/sun_times/actions/workflows/crystal.yml)
[![GitHub release](https://img.shields.io/github/release/geocrystal/sun_times.svg)](https://github.com/geocrystal/sun_times/releases)
[![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://geocrystal.github.io/sun_times/)
[![License](https://img.shields.io/github/license/geocrystal/sun_times.svg)](https://github.com/geocrystal/sun_times/blob/main/LICENSE)

A simple [Crystal](https://crystal-lang.org) library for calculating 🌅 **sunrise** and 🌇 **sunset** given latitude, longitude, and date based on
the [NOAA Solar Calculator](https://gml.noaa.gov/grad/solcalc/) and formulas from
Jean Meeus' _Astronomical Algorithms (2nd Edition, 1998)_.

## 📊 Accuracy

The library's astronomical constants and algorithms follow authoritative sources (NOAA, JPL, Meeus) and were verified manually against the NOAA Solar Calculator (<https://gml.noaa.gov/grad/solcalc/>).

Verification

- A validation script (`samples/accuracy_check.cr`) compares calculated sunrise, sunset and solar noon against NOAA's apparent times for several locations.
- The comparison was performed manually by running the script and checking the NOAA site for reference values.

Results

- Calculated times are within the margin of error and are effectively identical to NOAA's apparent times. Differences are typically under 1 minute.
- Tested locations include New York, London, Tokyo and Sydney. Example: New York on 2025-11-05 matched NOAA apparent sunrise/sunset closely (06:31 / 16:47 local).

## 📦 Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     sun_times:
       github: geocrystal/sun_times
   ```

2. Run `shards install`

## 💻 Usage

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
Now:      2025-11-05 14:05:23 +02:00

=== Twilight Periods ===
Astronomical dawn:  2025-11-05 05:30:09 +02:00
Nautical dawn:      2025-11-05 06:07:40 +02:00
Civil dawn:         2025-11-05 06:46:02 +02:00
Sunrise:            2025-11-05 07:20:19 +02:00
Solar noon:         2025-11-05 12:07:24 +02:00
Sunset:             2025-11-05 16:54:29 +02:00
Civil dusk:         2025-11-05 17:28:46 +02:00
Nautical dusk:      2025-11-05 18:07:08 +02:00
Astronomical dusk:  2025-11-05 18:44:39 +02:00

=== Daylight ===
Daylight:      9h 34m 9s
```

![readme](https://github.com/geocrystal/sun_times/blob/main/samples/readme.png?raw=true)

You can also get all solar events as a NamedTuple using the `events` method, which is useful for serialization (e.g., JSON): 📋

```crystal
require "json"
require "sun_times"

sun = SunTimes::SunTime.new(49.8419, 24.0311)
location = Time::Location.load("Europe/Kyiv")
date = Time.local

sun.events(date, location).to_json
```

Output

```json
{
  "astronomical_dawn":"2025-11-05T05:30:09+02:00",
  "nautical_dawn":"2025-11-05T06:07:40+02:00",
  "civil_dawn":"2025-11-05T06:46:02+02:00",
  "sunrise":"2025-11-05T07:20:19+02:00",
  "solar_noon":"2025-11-05T12:07:24+02:00",
  "sunset":"2025-11-05T16:54:29+02:00",
  "civil_dusk":"2025-11-05T17:28:46+02:00",
  "nautical_dusk":"2025-11-05T18:07:08+02:00",
  "astronomical_dusk":"2025-11-05T18:44:39+02:00"
}
```

### 🌆 Twilight Periods

The library supports three types of twilight periods:

- **Civil twilight** 🌅 (sun 6° below horizon): Enough light for most outdoor activities
- **Nautical twilight** ⚓ (sun 12° below horizon): Horizon is still visible for navigation
- **Astronomical twilight** 🔭 (sun 18° below horizon): Sky is dark enough for astronomical observations

![image](https://github.com/geocrystal/sun_times/blob/main/samples/twilight_subcategories.png?raw=true)

## 🚀 Performance

The library is fast as the speed of light! ⚡ Individual calculations are sub-microsecond, and the `events` method that computes all solar events is still under 4 microseconds per call.

Benchmark results were obtained on Intel(R) Core(TM) i7-8550U (8) @ 4.00 GHz.

You can run the benchmark with:

```bash
crystal run --release samples/benchmark.cr
```

## 🤝 Contributing

1. Fork it (<https://github.com/geocrystal/sun_times/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## 👥 Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer

## 📄 License

This library is distributed under the MIT license. Please see the LICENSE file.
