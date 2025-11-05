# A minimal Crystal library for computing sunrise and sunset times.
#
# Based on NOAA Solar Calculator formulas:
#   https://gml.noaa.gov/grad/solcalc/
#
# Core equations originate from:
#   Jean Meeus, "Astronomical Algorithms", 2nd Edition (1998)
#
# Accuracy: typically within ±1 minute of NOAA reference data.

module SunTimes
  # Exception raised when sunrise/sunset calculations cannot be performed
  # (e.g., polar night or polar day).
  class CalculationError < Exception
  end

  # Exception raised when invalid input is provided (e.g., invalid Julian Day).
  class InvalidInputError < Exception
  end

  class SunTime
    getter latitude : Float64
    getter longitude : Float64

    # ---------------------------------------------------------------------------
    # Unit conversions
    # ---------------------------------------------------------------------------

    DEG2RAD = Math::PI / 180.0 # Degrees to radians
    RAD2DEG = 180.0 / Math::PI # Radians to degrees

    # ---------------------------------------------------------------------------
    # Astronomical constants (Meeus / NOAA)
    # ---------------------------------------------------------------------------

    JULIAN_EPOCH_J2000        = 2_451_545.0 # Julian Day of J2000.0 epoch (2000-01-01 12:00 TT)
    MEAN_ANOMALY_AT_EPOCH     =    357.5291 # Earth's mean anomaly at J2000.0 (deg)
    DAILY_MOTION              =  0.98564736 # Average orbital motion (deg/day)
    EARTH_PERIHELION_LONG     =    102.9373 # Longitude of Earth's perihelion (deg)
    OBLIQUITY                 = 23.43929111 # Mean axial tilt at J2000.0 (deg)
    SUN_ALTITUDE_RISE_SET     =     -0.8333 # Apparent altitude at sunrise/sunset (deg)
    SUN_ALTITUDE_CIVIL        =        -6.0 # Civil twilight (sun 6° below horizon)
    SUN_ALTITUDE_NAUTICAL     =       -12.0 # Nautical twilight (sun 12° below horizon)
    SUN_ALTITUDE_ASTRONOMICAL =       -18.0 # Astronomical twilight (sun 18° below horizon)
    CORRECTION_ECCENTRICITY   =     0.00534 # Empirical correction for eccentricity
    CORRECTION_OBLIQUITY      =     0.00692 # Empirical correction for obliquity

    # Equation of center coefficients (Meeus 1998)
    EQUATION_CENTER_COEFF_1 = 1.9148 # sin(M)
    EQUATION_CENTER_COEFF_2 = 0.0200 # sin(2M)
    EQUATION_CENTER_COEFF_3 = 0.0003 # sin(3M)

    # ---------------------------------------------------------------------------
    # Julian-day conversion constants (Gregorian calendar)
    # ---------------------------------------------------------------------------

    JULIAN_YEAR_DAYS    =  365.25 # Mean days per Julian year
    JULIAN_MONTH_FACTOR = 30.6001 # Conversion factor for month contribution
    JULIAN_EPOCH_OFFSET =    4716 # Year offset for astronomical epoch
    JULIAN_BASE_OFFSET  =  1524.5 # Aligns JD 0 = 4713 BCE Jan 1 12:00 UT
    JULIAN_MIDNIGHT_FIX =     0.5 # Converts JD from noon to 00:00 UTC

    # ---------------------------------------------------------------------------
    # Epoch conversion constants
    # ---------------------------------------------------------------------------

    JULIAN_UNIX_EPOCH = 2_440_587.5 # JD of Unix epoch (1970-01-01 00:00 UTC)
    SECONDS_PER_DAY   =    86_400.0 # 24 hours × 60 minutes × 60 seconds

    # ---------------------------------------------------------------------------

    # Initializes a SunTime calculator for the given latitude and longitude.
    #
    # Latitude:  degrees north (negative for south)
    # Longitude: degrees east (negative for west)
    #
    # Example:
    # ```
    # SunTimes::SunTime.new(48.87, 2.67)   # Paris
    # SunTimes::SunTime.new({48.87, 2.67}) # Paris
    # ```
    def initialize(@latitude : Float64, @longitude : Float64)
    end

    # :ditto:
    def initialize(coords : Tuple(Float64, Float64))
      @latitude = coords[0]
      @longitude = coords[1]
    end

    # ---------------------------------------------------------------------------
    # PUBLIC API
    # ---------------------------------------------------------------------------

    # Returns the UTC time of sunrise for the given date.
    #
    # Arguments:
    #   date      - Time (date portion is used; time of day ignored)
    #   location  - Optional Time::Location for local conversion
    #
    # Returns:
    #   Time in UTC or converted to the provided location.
    #
    # Raises:
    #   CalculationError if there is no sunrise (polar night or polar day).
    #
    # Example:
    #   sun.sunrise(Time.local(2025, 11, 2))
    # => 2025-11-02 06:37:00 UTC
    def sunrise(date : Time, location : Time::Location? = nil) : Time
      jd_rise = calculate(date, rise: true, altitude: SUN_ALTITUDE_RISE_SET)
      raise CalculationError.new("No sunrise occurs on this date for this location (polar night/day)") if jd_rise.nan?
      from_julian(jd_rise, location)
    end

    # Returns the UTC time of sunset for the given date.
    #
    # Arguments and behavior are identical to `#sunrise`.
    #
    # Raises:
    #   CalculationError if there is no sunset (polar night or polar day).
    def sunset(date : Time, location : Time::Location? = nil) : Time
      jd_set = calculate(date, rise: false, altitude: SUN_ALTITUDE_RISE_SET)
      raise CalculationError.new("No sunset occurs on this date for this location (polar night/day)") if jd_set.nan?
      from_julian(jd_set, location)
    end

    # Returns the UTC or local time of solar noon (Sun's highest point) for the given date.
    #
    # Solar noon corresponds to the moment when the Sun crosses the local meridian.
    # This method uses the same underlying model as sunrise/sunset calculations.
    #
    # Arguments:
    #   date      - Time (only the date portion is used)
    #   location  - Optional Time::Location for local conversion
    #
    # Returns:
    #   Time of local solar noon (UTC by default)
    #
    # Example:
    #   sun.solar_noon(Time.local(2025, 11, 2), paris)
    # => 2025-11-02 12:32:50 +01:00
    def solar_noon(date : Time, location : Time::Location? = nil) : Time
      jd = julian_day(date)

      # Approximate solar noon (local)
      n = jd - JULIAN_EPOCH_J2000 - @longitude / 360.0

      # Solar mean anomaly
      mean_anomaly = normalize_angle(
        MEAN_ANOMALY_AT_EPOCH + DAILY_MOTION * (jd - JULIAN_EPOCH_J2000)
      )

      # Ecliptic longitude of the Sun
      lambda_sun = normalize_angle(
        mean_anomaly +
        (EQUATION_CENTER_COEFF_1 * Math.sin(mean_anomaly * DEG2RAD)) +
        (EQUATION_CENTER_COEFF_2 * Math.sin(2 * mean_anomaly * DEG2RAD)) +
        (EQUATION_CENTER_COEFF_3 * Math.sin(3 * mean_anomaly * DEG2RAD)) +
        EARTH_PERIHELION_LONG + 180.0
      )

      # Compute the Julian Day for local solar noon
      j_transit = JULIAN_EPOCH_J2000 + n +
                  CORRECTION_ECCENTRICITY * Math.sin(mean_anomaly * DEG2RAD) -
                  CORRECTION_OBLIQUITY * Math.sin(2 * lambda_sun * DEG2RAD)

      from_julian(j_transit, location)
    end

    # Returns the duration of daylight (time between sunrise and sunset)
    # for the given date and location.
    #
    # Arguments:
    #   date      - Time (only date portion is used)
    #   location  - Optional Time::Location for local conversion
    #
    # Returns:
    #   Time::Span representing total daylight duration.
    #   Returns zero if there is no sunrise/sunset (polar night or polar day).
    #
    # Example:
    #   sun.daylight_length(Time.local(2025, 11, 2), paris)
    # => 9 hours, 50 minutes (approx)
    def daylight_length(date : Time, location : Time::Location? = nil) : Time::Span
      jd_rise = calculate(date, rise: true, altitude: SUN_ALTITUDE_RISE_SET)
      jd_set = calculate(date, rise: false, altitude: SUN_ALTITUDE_RISE_SET)

      # If there's no sunrise or sunset (polar night/day), return zero
      return Time::Span.zero if jd_rise.nan? || jd_set.nan?

      rise = from_julian(jd_rise, location)
      set = from_julian(jd_set, location)

      set - rise
    end

    # Returns the time of civil dawn (beginning of civil twilight).
    # Civil twilight occurs when the sun is 6° below the horizon.
    # During this period, there is enough light for most outdoor activities.
    #
    # Arguments:
    #   date      - Time (date portion is used; time of day ignored)
    #   location  - Optional Time::Location for local conversion
    #
    # Returns:
    #   Time in UTC or converted to the provided location.
    #
    # Raises:
    #   CalculationError if there is no civil dawn (polar night or polar day).
    def civil_dawn(date : Time, location : Time::Location? = nil) : Time
      jd = calculate(date, rise: true, altitude: SUN_ALTITUDE_CIVIL)
      raise CalculationError.new("No civil dawn occurs on this date for this location") if jd.nan?
      from_julian(jd, location)
    end

    # Returns the time of civil dusk (end of civil twilight).
    # See `#civil_dawn` for details about civil twilight.
    def civil_dusk(date : Time, location : Time::Location? = nil) : Time
      jd = calculate(date, rise: false, altitude: SUN_ALTITUDE_CIVIL)
      raise CalculationError.new("No civil dusk occurs on this date for this location") if jd.nan?
      from_julian(jd, location)
    end

    # Returns the time of nautical dawn (beginning of nautical twilight).
    # Nautical twilight occurs when the sun is 12° below the horizon.
    # During this period, the horizon is still visible for navigation.
    #
    # Arguments:
    #   date      - Time (date portion is used; time of day ignored)
    #   location  - Optional Time::Location for local conversion
    #
    # Returns:
    #   Time in UTC or converted to the provided location.
    #
    # Raises:
    #   CalculationError if there is no nautical dawn (polar night or polar day).
    def nautical_dawn(date : Time, location : Time::Location? = nil) : Time
      jd = calculate(date, rise: true, altitude: SUN_ALTITUDE_NAUTICAL)
      raise CalculationError.new("No nautical dawn occurs on this date for this location") if jd.nan?
      from_julian(jd, location)
    end

    # Returns the time of nautical dusk (end of nautical twilight).
    # See `#nautical_dawn` for details about nautical twilight.
    def nautical_dusk(date : Time, location : Time::Location? = nil) : Time
      jd = calculate(date, rise: false, altitude: SUN_ALTITUDE_NAUTICAL)
      raise CalculationError.new("No nautical dusk occurs on this date for this location") if jd.nan?
      from_julian(jd, location)
    end

    # Returns the time of astronomical dawn (beginning of astronomical twilight).
    # Astronomical twilight occurs when the sun is 18° below the horizon.
    # During this period, the sky is dark enough for astronomical observations.
    #
    # Arguments:
    #   date      - Time (date portion is used; time of day ignored)
    #   location  - Optional Time::Location for local conversion
    #
    # Returns:
    #   Time in UTC or converted to the provided location.
    #
    # Raises:
    #   CalculationError if there is no astronomical dawn (polar night or polar day).
    def astronomical_dawn(date : Time, location : Time::Location? = nil) : Time
      jd = calculate(date, rise: true, altitude: SUN_ALTITUDE_ASTRONOMICAL)
      raise CalculationError.new("No astronomical dawn occurs on this date for this location") if jd.nan?
      from_julian(jd, location)
    end

    # Returns the time of astronomical dusk (end of astronomical twilight).
    # See `#astronomical_dawn` for details about astronomical twilight.
    def astronomical_dusk(date : Time, location : Time::Location? = nil) : Time
      jd = calculate(date, rise: false, altitude: SUN_ALTITUDE_ASTRONOMICAL)
      raise CalculationError.new("No astronomical dusk occurs on this date for this location") if jd.nan?
      from_julian(jd, location)
    end

    # ---------------------------------------------------------------------------
    # INTERNAL CALCULATIONS
    # ---------------------------------------------------------------------------

    # Core astronomical calculation.
    #
    # Computes the Julian Day (JD) of sunrise, sunset, or twilight for the given date.
    #
    # The algorithm follows NOAA's simplified solar position model:
    #   1. Compute Julian Day (JD)
    #   2. Compute mean anomaly (M)
    #   3. Apply Equation of Center (C) to correct for orbital eccentricity
    #   4. Compute ecliptic longitude (lambda_sun)
    #   5. Compute solar declination (declination)
    #   6. Solve for hour angle (H0) at given solar altitude
    #   7. Compute solar transit (J_transit)
    #   8. Add/subtract hour angle to get J_rise / J_set
    #
    # Arguments:
    #   date     - Time (date portion is used)
    #   rise     - true for dawn/sunrise, false for dusk/sunset
    #   altitude - Solar altitude angle in degrees (negative for below horizon)
    #
    # Returns:
    #   Julian Day (JD) value of the event
    private def calculate(date : Time, rise : Bool, altitude : Float64 = SUN_ALTITUDE_RISE_SET) : Float64
      jd = julian_day(date)

      # Approximate solar noon (local)
      n = jd - JULIAN_EPOCH_J2000 - @longitude / 360.0

      # Solar mean anomaly
      mean_anomaly = normalize_angle(MEAN_ANOMALY_AT_EPOCH + DAILY_MOTION * (jd - JULIAN_EPOCH_J2000))

      # Equation of center (orbital eccentricity correction)
      equation_of_center = EQUATION_CENTER_COEFF_1 * Math.sin(mean_anomaly * DEG2RAD) +
                           EQUATION_CENTER_COEFF_2 * Math.sin(2 * mean_anomaly * DEG2RAD) +
                           EQUATION_CENTER_COEFF_3 * Math.sin(3 * mean_anomaly * DEG2RAD)

      # Ecliptic longitude of the Sun (lambda)
      lambda_sun = normalize_angle(mean_anomaly + equation_of_center + EARTH_PERIHELION_LONG + 180.0)

      # Solar declination (delta)
      declination = Math.asin(Math.sin(lambda_sun * DEG2RAD) * Math.sin(OBLIQUITY * DEG2RAD)) * RAD2DEG

      # Hour angle at sunrise/sunset/twilight (using specified altitude)
      h0 = (Math.sin(altitude * DEG2RAD) -
            Math.sin(@latitude * DEG2RAD) * Math.sin(declination * DEG2RAD)) /
           (Math.cos(@latitude * DEG2RAD) * Math.cos(declination * DEG2RAD))
      return Float64::NAN if h0.abs > 1 # Polar day/night: no sunrise/sunset/twilight

      h0 = Math.acos(h0) * RAD2DEG

      # Solar transit (local solar noon)
      j_transit = JULIAN_EPOCH_J2000 + n +
                  CORRECTION_ECCENTRICITY * Math.sin(mean_anomaly * DEG2RAD) -
                  CORRECTION_OBLIQUITY * Math.sin(2 * lambda_sun * DEG2RAD)

      # Sunrise or sunset Julian date
      j_event = rise ? j_transit - h0 / 360.0 : j_transit + h0 / 360.0
      j_event
    end

    # Converts a Gregorian date (year, month, day) to a Julian Day Number (JD)
    # corresponding to midnight UTC (00:00), not noon.
    #
    # Implements the standard USNO/Meeus algorithm.
    private def julian_day(date : Time) : Float64
      date = date + 1.day
      y = date.year
      m = date.month
      d = date.day

      if m <= 2
        y -= 1
        m += 12
      end

      a = (y / 100).floor
      b = 2 - a + (a / 4).floor

      jd = (JULIAN_YEAR_DAYS * (y + JULIAN_EPOCH_OFFSET)).floor +
           (JULIAN_MONTH_FACTOR * (m + 1)).floor +
           d + b - JULIAN_BASE_OFFSET
      jd - JULIAN_MIDNIGHT_FIX
    end

    # Converts a Julian Day (JD) to a Crystal Time instance.
    #
    # Arguments:
    #   jd       - Julian Day (floating-point day count)
    #   location - Optional Time::Location to return local time
    #
    # Raises:
    #   InvalidInputError if jd is NaN or infinite.
    private def from_julian(jd : Float64, location : Time::Location?) : Time
      raise InvalidInputError.new("Invalid Julian Day: NaN") if jd.nan?
      raise InvalidInputError.new("Invalid Julian Day: infinite") if jd.infinite?

      days_since_epoch = jd - JULIAN_UNIX_EPOCH
      seconds = days_since_epoch * SECONDS_PER_DAY
      nanoseconds = (seconds * 1_000_000_000).to_i64
      t = Time.unix_ns(nanoseconds)
      location ? t.in(location) : t
    end

    # Normalizes any angle (degrees) into the 0–360° range.
    private def normalize_angle(a : Float64) : Float64
      ((a % 360) + 360) % 360
    end
  end
end
