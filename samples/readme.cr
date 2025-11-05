require "../src/sun_times"

# https://gml.noaa.gov/grad/solcalc/

def format_time_span(span : Time::Span)
  String.build do |s|
    s << "#{span.days}d " if span.days > 0
    s << "#{span.hours}h " if span.hours > 0
    s << "#{span.minutes}m " if span.minutes > 0
    s << "#{span.seconds}s"
  end
end

sun = SunTimes::SunTime.new(49.8419, 24.0311) # Lviv
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
puts "Daylight:      #{format_time_span(daylight_length)}"

if date < sunset_time
  daylight_left = sunset_time - date
  puts "Daylight left: #{format_time_span(daylight_left)}"
end
