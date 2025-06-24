
defmodule DriversLicenseValidationTest do
  use ExUnit.Case, async: true
  alias DriversLicenseValidation

  describe "valid license samples for all states" do
    test "CA format: 1 alpha + 7 numeric" do
      assert DriversLicenseValidation.valid?("CA", "A1234567")
      refute DriversLicenseValidation.valid?("CA", "A12345678")  # too long
    end

    test "FL format: 1 alpha + 12 numeric" do
      number = "F850000010600"
      assert DriversLicenseValidation.valid?("FL", number)
      assert DriversLicenseValidation.date_of_birth("FL", number) == ~D[1985-04-16]
    end

    test "WI format: same as FL" do
      number = "W8500000106000"
      assert DriversLicenseValidation.valid?("WI", number)
      assert DriversLicenseValidation.date_of_birth("WI", number) == ~D[1985-04-16]
    end

    test "IL format: 1 alpha + 11 numeric" do
      license = "I85000000981"   # YY = 85, DOY = 098 = April 6
      assert DriversLicenseValidation.valid?("IL", license)
      assert DriversLicenseValidation.date_of_birth("IL", license) == ~D[1985-04-06]
    end

    test "IL format: 11 numeric + 1 alpha (alt format)" do
      license = "12345685098A"   # YY = 85, DOY = 098 = April 6
      assert DriversLicenseValidation.valid?("IL", license)
      assert DriversLicenseValidation.date_of_birth("IL", license) == ~D[1985-04-06]
    end

    test "MD/MI format with mapped code" do
      assert DriversLicenseValidation.valid?("MD", "M123456789002")
      assert DriversLicenseValidation.date_of_birth("MD", "M123456789002") == ~D[1900-01-01]
      assert DriversLicenseValidation.valid?("MI", "M123456789002")
    end

    test "NJ encoded YYMM" do
      number = "A12345678908510"
      assert DriversLicenseValidation.valid?("NJ", number)
      assert DriversLicenseValidation.date_of_birth("NJ", number) == ~D[1951-08-01]
    end

    test "NJ future DOB example" do
      number = "A12345678905250"
      assert DriversLicenseValidation.valid?("NJ", number)
      assert DriversLicenseValidation.date_of_birth("NJ", number) == ~D[2025-05-01]
    end

    test "WA DL with valid encoded name and DOB" do
      number = "SMITHJ821BC"
      dob = ~D[1980-01-01]
      assert DriversLicenseValidation.valid?("WA", number)
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "John", last_name: "Smith", known_dob: dob) == dob
    end

    test "WA DL fallback when decoding fails" do
      number = "FAKEJ821ZZ"
      fallback = ~D[1975-06-15]

      log =
        ExUnit.CaptureLog.capture_log(fn ->
          assert DriversLicenseValidation.date_of_birth("WA", number, known_dob: fallback) == fallback
        end)

      assert log =~ "[DLValidator] WA DOB parse failed"
    end

    test "WA format and fallback to known DOB" do
      number = "SMITHJ821BC"
      assert DriversLicenseValidation.valid?("WA", number)
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "John", last_name: "Smith", known_dob: ~D[1980-01-01]) == ~D[1980-01-01]
    end

    test "WA DL with month character 'T' (February)" do
      number = "SMITHJ821CT"
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "John", last_name: "Smith", known_dob: ~D[1980-02-01]) == ~D[1980-02-01]
    end

    test "WA DL with lowercase context names" do
      number = "SMITHJ821BC"
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "john", last_name: "smith", known_dob: ~D[1980-01-01]) == ~D[1980-01-01]
    end

    test "WA DL with mismatched name" do
      number = "SMITHJ821BC"
      fallback = ~D[1980-01-01]

      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "Alice", last_name: "Brown", known_dob: fallback) == fallback
    end

    test "NH DL with correctly encoded name and DOB" do
      number = "12ABC12345"
      dob = ~D[1990-06-15]
      assert DriversLicenseValidation.valid?("NH", number)
      assert DriversLicenseValidation.date_of_birth("NH", number, first_name: "John", last_name: "Smith", known_dob: dob) == dob
    end

    test "CT format with fallback DOB" do
      dln = "151234567"
      dob = ~D[1992-03-01]

      assert DriversLicenseValidation.valid?("CT", dln)
      assert DriversLicenseValidation.date_of_birth("CT", dln, known_dob: dob) == dob
    end

    test "MT DL with encoded DOB in 13-digit numeric format" do
      dob = ~D[1992-03-09]
      dln = "0300199241090"  # MM(03), filler(00), YYYY(1992), "41", DD(09), +1 digit
      assert DriversLicenseValidation.valid?("MT", dln)
      assert DriversLicenseValidation.date_of_birth("MT", dln, known_dob: dob) == dob
    end

    test "MT DL with 3 alpha + 10 numeric (format-only, no DOB decoding)" do
      dln = "ABC1234567890"
      dob = ~D[1990-01-01]
      assert DriversLicenseValidation.valid?("MT", dln)
      assert DriversLicenseValidation.date_of_birth("MT", dln, known_dob: dob) == dob
    end

    test "MT DL with 1 alpha + 8 numeric (format-only, no DOB decoding)" do
      dln = "A12345678"
      dob = ~D[1985-07-15]
      assert DriversLicenseValidation.valid?("MT", dln)
      assert DriversLicenseValidation.date_of_birth("MT", dln, known_dob: dob) == dob
    end

    test "MT DL with 9 numeric (format-only, no DOB decoding)" do
      dln = "123456789"
      dob = ~D[2000-12-31]
      assert DriversLicenseValidation.valid?("MT", dln)
      assert DriversLicenseValidation.date_of_birth("MT", dln, known_dob: dob) == dob
    end

    test "ND with 3 alpha + 6 digits and known DOB" do
      assert DriversLicenseValidation.valid?("ND", "ABC123456")
      assert DriversLicenseValidation.date_of_birth("ND", "ABC123456", known_dob: ~D[1982-07-04]) == ~D[1982-07-04]
    end
  end

  describe "invalid license cases" do
    test "CA too short" do
      refute DriversLicenseValidation.valid?("CA", "A123456")  # too short
    end

    test "FL with incorrect length" do
      refute DriversLicenseValidation.valid?("FL", "F123")  # too short
      assert DriversLicenseValidation.date_of_birth("FL", "F123") == "N/A"
    end

    test "IL with missing prefix" do
      refute DriversLicenseValidation.valid?("IL", "12345678901")
    end

    test "IL - standard format: wrong prefix (non-alpha)" do
      # starts with a digit, should start with a letter
      license = "185000000981"
      refute DriversLicenseValidation.valid?("IL", license)
      assert DriversLicenseValidation.date_of_birth("IL", license) == "N/A"
    end

    test "IL - standard format: too short" do
      license = "I85000981"  # only 9 chars instead of 12
      refute DriversLicenseValidation.valid?("IL", license)
      assert DriversLicenseValidation.date_of_birth("IL", license) == "N/A"
    end

    test "IL - alt format: missing suffix" do
      license = "12345685098"  # missing final alpha character
      refute DriversLicenseValidation.valid?("IL", license)
      assert DriversLicenseValidation.date_of_birth("IL", license) == "N/A"
    end

    test "IL - alt format: invalid prefix (contains letters)" do
      license = "ABC12385098A"  # first 6 not fully numeric
      refute DriversLicenseValidation.valid?("IL", license)
      assert DriversLicenseValidation.date_of_birth("IL", license) == "N/A"
    end

    test "IL - alt format: suffix is not alpha" do
      license = "123456850981"  # final char should be A-Z
      refute DriversLicenseValidation.valid?("IL", license)
      assert DriversLicenseValidation.date_of_birth("IL", license) == "N/A"
    end

    test "IL - valid-looking number but invalid state" do
      license = "I85000000981"
      refute DriversLicenseValidation.valid?("ZZ", license)
      assert DriversLicenseValidation.date_of_birth("ZZ", license) == "N/A"
    end

    test "NH DL with wrong last name initial" do
      number = "06ZHJ85091"  # Ends in '1' instead of 'X'
      dob = ~D[1985-06-09]
      fallback = dob
      assert DriversLicenseValidation.valid?("NH", number)
      assert DriversLicenseValidation.date_of_birth("NH", number, first_name: "John", last_name: "Smith", known_dob: fallback) == fallback
    end

    test "Unknown state code" do
      refute DriversLicenseValidation.valid?("ZZ", "A1234567")
      assert DriversLicenseValidation.date_of_birth("ZZ", "A1234567") == "N/A"
    end

    test "Valid format but no DOB extractor" do
      assert DriversLicenseValidation.valid?("OR", "123456789")
      assert DriversLicenseValidation.date_of_birth("OR", "123456789") == "N/A"
    end

    test "MT DL with incorrect DOB encoding (fails DOB match)" do
      # Intentionally wrong: month should be 03 for DOB, but DLN says 04
      dln = "0400199241090"  # Wrong MM = "04" instead of "03"
      dob = ~D[1992-03-09]
      assert DriversLicenseValidation.valid?("MT", dln)
      assert DriversLicenseValidation.date_of_birth("MT", dln, known_dob: dob) == dob
    end
  end

  describe "edge formats" do
    test "valid WI DL using FL pattern" do
      assert DriversLicenseValidation.valid?("WI", "W9910712345678")
    end

    test "long WA DL with fallback" do
      number = "JONESM821ZT"
      assert DriversLicenseValidation.valid?("WA", number)
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "Matt", last_name: "Jones", known_dob: ~D[1995-05-05]) == ~D[1995-05-05]
    end
  end
end
