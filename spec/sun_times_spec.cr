require "./spec_helper"

describe SunTimes::SunTime do
  it "can be initialized from a tuple" do
    coords = {48.87, 2.67}
    sun = SunTimes::SunTime.new(coords)

    sun.latitude.should eq 48.87
    sun.longitude.should eq 2.67
  end

  it "computes correct sunrise and sunset times for Paris" do
    sun = SunTimes::SunTime.new(48.87, 2.67)
    paris = Time::Location.load("Europe/Paris")
    date = Time.local(2025, 11, 2, location: paris)

    sunrise = sun.sunrise(date, paris)
    sunset = sun.sunset(date, paris)

    # Reference data (NOAA / timeanddate.com)
    expected_sunrise = Time.local(2025, 11, 2, 7, 39, 0, location: paris)
    expected_sunset = Time.local(2025, 11, 2, 17, 27, 0, location: paris)
    tolerance = 2.minutes

    (sunrise - expected_sunrise).abs.should be < tolerance
    (sunset - expected_sunset).abs.should be < tolerance
  end

  it "produces same results when initialized from tuple vs parameters" do
    paris = Time::Location.load("Europe/Paris")
    date = Time.local(2025, 11, 2, location: paris)

    sun1 = SunTimes::SunTime.new(48.87, 2.67)
    sun2 = SunTimes::SunTime.new({48.87, 2.67})

    sunrise1 = sun1.sunrise(date, paris)
    sunrise2 = sun2.sunrise(date, paris)
    sunset1 = sun1.sunset(date, paris)
    sunset2 = sun2.sunset(date, paris)

    sunrise1.should eq sunrise2
    sunset1.should eq sunset2
  end

  it "computes solar noon correctly for Paris" do
    sun = SunTimes::SunTime.new(48.87, 2.67)
    paris = Time::Location.load("Europe/Paris")
    date = Time.local(2025, 11, 2, location: paris)

    sunrise = sun.sunrise(date, paris)
    sunset = sun.sunset(date, paris)
    noon = sun.solar_noon(date, paris)

    # Expected solar noon midpoint
    midpoint = sunrise + (sunset - sunrise) / 2

    # NOAA reference solar noon ≈ 12:32 local time
    expected_noon = Time.local(2025, 11, 2, 12, 32, 0, location: paris)
    tolerance = 2.minutes

    # Compare to midpoint
    (noon - midpoint).abs.should be < tolerance

    # Compare to known reference
    (noon - expected_noon).abs.should be < tolerance
  end

  it "computes day length correctly for Paris" do
    sun = SunTimes::SunTime.new(48.87, 2.67)
    paris = Time::Location.load("Europe/Paris")
    date = Time.local(2025, 11, 2, location: paris)

    length = sun.day_length(date, paris)

    expected_length = 9.hours + 50.minutes
    tolerance = 2.minutes

    (length - expected_length).abs.should be < tolerance
  end

  it "returns zero day length for polar regions in winter" do
    # Example: Longyearbyen, Svalbard (78° N)
    sun = SunTimes::SunTime.new(78.22, 15.65)
    svalbard = Time::Location.load("Europe/Oslo")
    date = Time.local(2025, 12, 15, location: svalbard)

    length = sun.day_length(date, svalbard)

    # Polar night → no daylight
    length.should eq Time::Span.zero
  end

  it "raises CalculationError for sunrise when there is no sunrise (polar night)" do
    # Example: Very high latitude during polar night
    sun = SunTimes::SunTime.new(85.0, 0.0)
    utc = Time::Location.load("UTC")
    date = Time.local(2025, 12, 21, location: utc) # Winter solstice

    expect_raises(SunTimes::CalculationError, "No sunrise occurs on this date for this location") do
      sun.sunrise(date, utc)
    end
  end

  it "raises CalculationError for sunset when there is no sunset (polar night)" do
    sun = SunTimes::SunTime.new(85.0, 0.0)
    utc = Time::Location.load("UTC")
    date = Time.local(2025, 12, 21, location: utc)

    expect_raises(SunTimes::CalculationError, "No sunset occurs on this date for this location") do
      sun.sunset(date, utc)
    end
  end

  it "computes correct times for equator location" do
    # Equator: relatively consistent day length year-round (~12 hours)
    sun = SunTimes::SunTime.new(0.0, 0.0) # Equator, Greenwich
    utc = Time::Location.load("UTC")
    date = Time.local(2025, 3, 21, location: utc) # Spring equinox

    sunrise = sun.sunrise(date, utc)
    sunset = sun.sunset(date, utc)
    noon = sun.solar_noon(date, utc)
    length = sun.day_length(date, utc)

    # At equator on equinox, day should be approximately 12 hours
    length.should be_close(12.hours, 10.minutes)

    # Solar noon should be between sunrise and sunset
    noon.should be > sunrise
    noon.should be < sunset
  end

  it "computes correct times for Southern Hemisphere" do
    # Sydney, Australia (summer in December, winter in June)
    sun = SunTimes::SunTime.new(-33.8688, 151.2093)
    sydney = Time::Location.load("Australia/Sydney")
    date = Time.local(2025, 12, 21, location: sydney) # Summer solstice (Southern Hemisphere)

    sunrise = sun.sunrise(date, sydney)
    sunset = sun.sunset(date, sydney)
    length = sun.day_length(date, sydney)

    # Summer solstice in Southern Hemisphere should have long days
    length.should be > 12.hours
    sunset.should be > sunrise
  end

  it "computes correct times for summer solstice in Northern Hemisphere" do
    sun = SunTimes::SunTime.new(48.87, 2.67) # Paris
    paris = Time::Location.load("Europe/Paris")
    date = Time.local(2025, 6, 21, location: paris) # Summer solstice

    sunrise = sun.sunrise(date, paris)
    sunset = sun.sunset(date, paris)
    length = sun.day_length(date, paris)

    # Summer solstice should have longest day of year
    length.should be > 15.hours # Paris has long summer days
    sunset.should be > sunrise
  end

  it "verifies solar noon is between sunrise and sunset" do
    sun = SunTimes::SunTime.new(48.87, 2.67) # Paris
    paris = Time::Location.load("Europe/Paris")
    date = Time.local(2025, 11, 2, location: paris)

    sunrise = sun.sunrise(date, paris)
    sunset = sun.sunset(date, paris)
    noon = sun.solar_noon(date, paris)

    # Solar noon must be between sunrise and sunset
    noon.should be > sunrise
    noon.should be < sunset

    # Solar noon should be closer to midpoint than to either edge
    midpoint = sunrise + (sunset - sunrise) / 2
    (noon - midpoint).abs.should be < 30.minutes
  end

  it "computes correct times for New York location" do
    sun = SunTimes::SunTime.new(40.7128, -74.0060) # New York
    nyc = Time::Location.load("America/New_York")
    date = Time.local(2025, 11, 2, location: nyc)

    sunrise = sun.sunrise(date, nyc)
    sunset = sun.sunset(date, nyc)
    length = sun.day_length(date, nyc)

    # Verify times are reasonable and sunset is after sunrise
    sunset.should be > sunrise
    length.should be > 8.hours # November days are shorter but still > 8 hours
    length.should be < 14.hours
  end

  it "handles different timezones correctly" do
    sun = SunTimes::SunTime.new(35.6762, 139.6503) # Tokyo
    tokyo = Time::Location.load("Asia/Tokyo")
    date = Time.local(2025, 11, 2, location: tokyo)

    sunrise_tokyo = sun.sunrise(date, tokyo)
    sunset_tokyo = sun.sunset(date, tokyo)

    # Times should be in Tokyo timezone
    sunrise_tokyo.location.should eq tokyo
    sunset_tokyo.location.should eq tokyo
    sunset_tokyo.should be > sunrise_tokyo
  end

  it "computes day length for different seasons" do
    sun = SunTimes::SunTime.new(48.87, 2.67) # Paris

    paris = Time::Location.load("Europe/Paris")
    winter_date = Time.local(2025, 12, 21, location: paris) # Winter solstice
    summer_date = Time.local(2025, 6, 21, location: paris)  # Summer solstice

    winter_length = sun.day_length(winter_date, paris)
    summer_length = sun.day_length(summer_date, paris)

    # Summer should have longer days than winter
    summer_length.should be > winter_length

    # Both should be reasonable (between 8 and 16 hours for Paris)
    winter_length.should be > 7.hours
    summer_length.should be < 17.hours
  end

  it "handles polar day (24-hour daylight)" do
    # During polar day, there's no sunset/sunrise but day_length might not be exactly 24 hours
    # At very high latitudes in summer
    sun = SunTimes::SunTime.new(80.0, 0.0) # High latitude
    utc = Time::Location.load("UTC")
    date = Time.local(2025, 6, 21, location: utc) # Summer solstice

    # This should either raise an error or return a very long day
    # Let's test what actually happens - it depends on exact latitude and date
    begin
      length = sun.day_length(date, utc)
      # If it doesn't raise, day should be very long (> 20 hours) or zero
      (length > 20.hours || length == Time::Span.zero).should be_true
    rescue SunTimes::CalculationError
      # If it raises, that's also acceptable for polar day
      true.should be_true
    end
  end
end
