require "../src/sun_times"

# Test locations with known reference data from NOAA Solar Calculator
# https://gml.noaa.gov/grad/solcalc/

def check_accuracy(
  name : String,
  lat : Float64,
  lon : Float64,
  date : Time,
  location : Time::Location,
  ref_sunrise : Time,
  ref_sunset : Time,
  ref_solar_noon : Time,
)
  sun = SunTimes::SunTime.new(lat, lon)

  sunrise = sun.sunrise(date, location)
  sunset = sun.sunset(date, location)
  noon = sun.solar_noon(date, location)

  sunrise_diff = (sunrise - ref_sunrise).abs
  sunset_diff = (sunset - ref_sunset).abs
  noon_diff = (noon - ref_solar_noon).abs

  puts "Location: #{name}"
  puts "Date: #{date.to_s("%Y-%m-%d")}"
  puts "Timezone: #{location}"
  puts
  puts "Calculated sunrise:    #{sunrise.to_s("%H:%M:%S")}"
  puts "Reference sunrise:     #{ref_sunrise.to_s("%H:%M:%S")}"
  puts "Difference:            #{sunrise_diff.total_seconds.to_i} seconds"
  puts
  puts "Calculated sunset:     #{sunset.to_s("%H:%M:%S")}"
  puts "Reference sunset:      #{ref_sunset.to_s("%H:%M:%S")}"
  puts "Difference:            #{sunset_diff.total_seconds.to_i} seconds"
  puts
  puts "Calculated solar noon: #{noon.to_s("%H:%M:%S")}"
  puts "Reference solar noon:  #{ref_solar_noon.to_s("%H:%M:%S")}"
  puts "Difference:            #{noon_diff.total_seconds.to_i} seconds"
  puts "=" * 80
  puts
end

# https://gml.noaa.gov/grad/solcalc/

# Test Cases for November 5, 2025

# 1. New York, USA
nyc = Time::Location.load("America/New_York")
date = Time.local(2025, 11, 5, location: nyc)
check_accuracy(
  "New York, USA",
  40.72, -74.02,
  date,
  nyc,
  Time.local(2025, 11, 5, 6, 31, 0, location: nyc),
  Time.local(2025, 11, 5, 16, 47, 0, location: nyc),
  Time.local(2025, 11, 5, 11, 39, 37, location: nyc)
)

# 2. London, UK
london = Time::Location.load("Europe/London")
date = Time.local(2025, 11, 5, location: london)
check_accuracy(
  "London, UK",
  51.5, -0.13,
  date,
  london,
  Time.local(2025, 11, 5, 7, 1, 0, location: london),
  Time.local(2025, 11, 5, 16, 26, 0, location: london),
  Time.local(2025, 11, 5, 11, 44, 3, location: london)
)

# 3. Tokyo, Japan
tokyo = Time::Location.load("Asia/Tokyo")
date = Time.local(2025, 11, 5, location: tokyo)
check_accuracy(
  "Tokyo, Japan",
  35.7, 139.77,
  date,
  tokyo,
  Time.local(2025, 11, 5, 6, 7, 0, location: tokyo),
  Time.local(2025, 11, 5, 16, 42, 0, location: tokyo),
  Time.local(2025, 11, 5, 11, 24, 27, location: tokyo)
)

# 4. Sydney, Australia
sydney = Time::Location.load("Australia/Sydney")
date = Time.local(2025, 11, 5, location: sydney)
check_accuracy(
  "Sydney, Australia",
  -33.87, 151.22,
  date,
  sydney,
  Time.local(2025, 11, 5, 5, 51, 0, location: sydney),
  Time.local(2025, 11, 5, 19, 27, 0, location: sydney),
  Time.local(2025, 11, 5, 12, 38, 39, location: sydney)
)

# 5. Lviv, Ukraine
lviv = Time::Location.load("Europe/Kiev")
date = Time.local(2025, 11, 21, location: lviv)
check_accuracy(
  "Lviv, Ukraine",
  49.8419, 24.0311,
  date,
  lviv,
  Time.local(2025, 11, 21, 7, 46, 0, location: lviv),
  Time.local(2025, 11, 21, 16, 33, 0, location: lviv),
  Time.local(2025, 11, 21, 12, 9, 38, location: lviv)
)
