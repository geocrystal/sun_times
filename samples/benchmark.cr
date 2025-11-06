require "../src/sun_times"
require "benchmark"
require "random"

# Benchmark various SunTimes operations with random locations and dates

random = Random.new
iterations = 1_000_000

puts "SunTimes Benchmark"
puts "=" * 50
puts "Using random locations (latitude: -90..90, longitude: -180..180)"
puts "Using random dates (2020-2030)"
puts "Iterations: #{iterations}"
puts "=" * 50
puts

def random_date(random : Random) : Time
  year = random.rand(2020..2030)
  month = random.rand(1..12)
  # Handle different month lengths (simplified - using 28 as max for all months)
  day = random.rand(1..28)
  Time.local(year, month, day)
end

def benchmark_method(name : String, iterations : Int32, random : Random, &block)
  time = Benchmark.measure do
    iterations.times do
      yield
    end
  end

  avg_ms = (time.real / iterations * 1000).round(4)
  ops_per_sec = (iterations / time.real).round(0)
  printf "%-25s %8.4f ms/op  %10s ops/s\n", name, avg_ms, ops_per_sec
end

benchmark_method("sunrise", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.sunrise?(date)
end

benchmark_method("sunset", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.sunset?(date)
end

benchmark_method("solar_noon", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.solar_noon(date)
end

benchmark_method("civil_dawn", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.civil_dawn?(date)
end

benchmark_method("civil_dusk", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.civil_dusk?(date)
end

benchmark_method("nautical_dawn", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.nautical_dawn?(date)
end

benchmark_method("nautical_dusk", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.nautical_dusk?(date)
end

benchmark_method("astronomical_dawn", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.astronomical_dawn?(date)
end

benchmark_method("astronomical_dusk", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.astronomical_dusk?(date)
end

benchmark_method("daylight_length", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.daylight_length(date)
end

benchmark_method("events (all)", iterations, random) do
  lat = random.rand(-90.0..90.0)
  lon = random.rand(-180.0..180.0)
  date = random_date(random)
  sun = SunTimes::SunTime.new(lat, lon)
  sun.events(date)
end

puts
puts "=" * 50
puts "Combined benchmark"
puts "=" * 50
puts

time = Benchmark.measure do
  iterations.times do
    lat = random.rand(-90.0..90.0)
    lon = random.rand(-180.0..180.0)
    date = random_date(random)
    sun = SunTimes::SunTime.new(lat, lon)
    sun.sunrise?(date)
    sun.sunset?(date)
    sun.solar_noon(date)
  end
end

puts "Calculating sunrise, sunset, and solar_noon #{iterations} times:"
puts "  Total time: #{time.real.round(4)}s"
puts "  Average per calculation: #{(time.real / (iterations * 3) * 1000).round(4)}ms"
puts "  Calculations per second: #{(iterations * 3 / time.real).round(0)}"
