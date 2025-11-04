# sun_times

[![Crystal CI](https://github.com/geocrystal/sun_times/actions/workflows/crystal.yml/badge.svg)](https://github.com/geocrystal/sun_times/actions/workflows/crystal.yml)
[![GitHub release](https://img.shields.io/github/release/geocrystal/sun_times.svg)](https://github.com/geocrystal/sun_times/releases)
[![License](https://img.shields.io/github/license/geocrystal/sun_times.svg)](https://github.com/geocrystal/geojson/blob/main/LICENSE)

A [Crystal](https://crystal-lang.org) library for computing **sunrise** and **sunset** times based on
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

# Example: Paris, France
# SunTime.new(latitude : Float64, longitude : Float64)
sun = SunTimes::SunTime.new(48.87, 2.67)
paris = Time::Location.load("Europe/Paris")
date  = Time.local(2025, 11, 2)

puts "Sunrise: #{sun.sunrise(date, paris)}"
puts "Sunset:  #{sun.sunset(date, paris)}"
```

Output:

```
Sunrise: 2025-11-02 07:37:41 +01:00
Sunset:  2025-11-02 17:27:59 +01:00
```

## Contributing

1. Fork it (<https://github.com/geocrystal/sun_times/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer
