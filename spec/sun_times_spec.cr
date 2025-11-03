require "./spec_helper"

describe SunTimes::SunTime do
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
end
