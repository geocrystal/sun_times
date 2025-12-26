require "json"
require "../src/sun_times"

# https://gml.noaa.gov/grad/solcalc/

def format_time(t : Time?) : String
  t ? t.to_s : "N/A"
end

def format_time_span(span : Time::Span)
  String.build do |s|
    s << "#{span.days}d " if span.days > 0
    s << "#{span.hours}h " if span.hours > 0
    s << "#{span.minutes}m " if span.minutes > 0
    s << "#{span.seconds}s"
  end
end

latitude = 49.8419
longitude = 24.0311
sun = SunTimes::SunTime.new(latitude, longitude) # Lviv
location = Time::Location.load("Europe/Kyiv")
date = Time.local
# date = Time.local(2025, 6, 21, 0, 0, 0, location: location) # Summer Solstice
# date = Time.local(2025, 12, 21, 0, 0, 0, location: location) # Winter Solstice

astronomical_dawn_time = sun.astronomical_dawn?(date, location)
nautical_dawn_time = sun.nautical_dawn?(date, location)
civil_dawn_time = sun.civil_dawn?(date, location)
sunrise_time = sun.sunrise?(date, location)
solar_noon_time = sun.solar_noon(date, location)
sunset_time = sun.sunset?(date, location)
civil_dusk_time = sun.civil_dusk?(date, location)
nautical_dusk_time = sun.nautical_dusk?(date, location)
astronomical_dusk_time = sun.astronomical_dusk?(date, location)
daylight_length = sun.daylight_length(date, location)

puts "Location: #{latitude}, #{longitude}"
puts "Timezone: #{location}"
puts "Now:      #{date}"
puts
puts "=== Twilight Periods ==="
puts "🔭 Astronomical dawn:  #{format_time(astronomical_dawn_time)}"
puts "⚓ Nautical dawn:      #{format_time(nautical_dawn_time)}"
puts "🌅 Civil dawn:         #{format_time(civil_dawn_time)}"
puts "🌞 Sunrise:            #{format_time(sunrise_time)}"
puts "☀️ Solar noon:         #{format_time(solar_noon_time)}"
puts "🌇 Sunset:             #{format_time(sunset_time)}"
puts "🌆 Civil dusk:         #{format_time(civil_dusk_time)}"
puts "🧭 Nautical dusk:      #{format_time(nautical_dusk_time)}"
puts "🌌 Astronomical dusk:  #{format_time(astronomical_dusk_time)}"
puts ""
puts "=== Daylight ==="
puts "Daylight:      #{format_time_span(daylight_length)}"

if sunset_time && date.in?(sunrise_time..sunset_time)
  daylight_left = sunset_time - date
  puts "Daylight left: #{format_time_span(daylight_left)}"
end

puts
puts sun.events(date, location).to_json
