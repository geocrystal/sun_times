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
end
