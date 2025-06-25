defmodule DriversLicenseValidationTest do
  use ExUnit.Case, async: true
  alias DriversLicenseValidation

  # -- CALIFORNIA (CA) --
  describe "CA - California" do
    test "valid: 1 alpha + 7 numeric" do
      assert DriversLicenseValidation.valid?("CA", "A1234567")
    end

    test "invalid: too short/too long" do
      refute DriversLicenseValidation.valid?("CA", "A123456")  # too short
      refute DriversLicenseValidation.valid?("CA", "A12345678")  # too long
    end
  end

  # -- FLORIDA (FL) --
  describe "FL - Florida" do
    test "valid: 1 alpha + 12 numeric with DOB" do
      number = "F850000010600"
      assert DriversLicenseValidation.valid?("FL", number)
      assert DriversLicenseValidation.date_of_birth("FL", number) == ~D[1985-04-16]
    end

    test "invalid: wrong length or malformed" do
      refute DriversLicenseValidation.valid?("FL", "F123")
      assert DriversLicenseValidation.date_of_birth("FL", "F123") == "N/A"
    end
  end

  # -- WISCONSIN (WI) --
  describe "WI - Wisconsin" do
    test "valid: FL-style format" do
      number = "W8500000106000"
      assert DriversLicenseValidation.valid?("WI", number)
      assert DriversLicenseValidation.date_of_birth("WI", number) == ~D[1985-04-16]
    end

    test "edge: alternate valid format" do
      assert DriversLicenseValidation.valid?("WI", "W9910712345678")
    end
  end

  # -- ILLINOIS (IL) --
  describe "IL - Illinois" do
    test "valid: 1 alpha + 11 numeric" do
      license = "I85000000981"
      assert DriversLicenseValidation.valid?("IL", license)
      assert DriversLicenseValidation.date_of_birth("IL", license) == ~D[1985-04-06]
    end

    test "valid: alt format 11 numeric + 1 alpha" do
      license = "12345685098A"
      assert DriversLicenseValidation.valid?("IL", license)
      assert DriversLicenseValidation.date_of_birth("IL", license) == ~D[1985-04-06]
    end

    test "invalid formats and state" do
      refute DriversLicenseValidation.valid?("IL", "12345678901")  # missing alpha
      refute DriversLicenseValidation.valid?("IL", "185000000981") # non-alpha prefix
      refute DriversLicenseValidation.valid?("IL", "I85000981")    # too short
      refute DriversLicenseValidation.valid?("IL", "12345685098")  # missing suffix
      refute DriversLicenseValidation.valid?("IL", "ABC12385098A") # bad numeric part
      refute DriversLicenseValidation.valid?("IL", "123456850981") # final char not alpha
      refute DriversLicenseValidation.valid?("ZZ", "I85000000981") # invalid state

      assert DriversLicenseValidation.date_of_birth("IL", "185000000981") == "N/A"
      assert DriversLicenseValidation.date_of_birth("IL", "I85000981") == "N/A"
      assert DriversLicenseValidation.date_of_birth("IL", "12345685098") == "N/A"
      assert DriversLicenseValidation.date_of_birth("IL", "ABC12385098A") == "N/A"
      assert DriversLicenseValidation.date_of_birth("IL", "123456850981") == "N/A"
      assert DriversLicenseValidation.date_of_birth("ZZ", "I85000000981") == "N/A"
    end
  end

  # -- MARYLAND & MICHIGAN --
  describe "MD/MI - Maryland & Michigan" do
    test "valid with mapped DOB" do
      assert DriversLicenseValidation.valid?("MD", "M123456789002")
      assert DriversLicenseValidation.valid?("MI", "M123456789002")
      assert DriversLicenseValidation.date_of_birth("MD", "M123456789002") == ~D[1900-01-01]
    end
  end

  # -- NEW JERSEY (NJ) --
  describe "NJ - New Jersey" do
    test "valid: standard encoded DOB" do
      number = "A12345678908510"
      assert DriversLicenseValidation.valid?("NJ", number)
      assert DriversLicenseValidation.date_of_birth("NJ", number) == ~D[1951-08-01]
    end

    test "valid: future DOB example" do
      number = "A12345678905250"
      assert DriversLicenseValidation.valid?("NJ", number)
      assert DriversLicenseValidation.date_of_birth("NJ", number) == ~D[2025-05-01]
    end
  end

  # -- WASHINGTON (WA) --
  describe "WA - Washington" do
    test "valid with correct context and DOB" do
      number = "SMITHJ821BC"
      dob = ~D[1980-01-01]
      assert DriversLicenseValidation.valid?("WA", number)
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "John", last_name: "Smith", known_dob: dob) == dob
    end

    test "fallback on failure to parse" do
      number = "FAKEJ821ZZ"
      fallback = ~D[1975-06-15]

      log = ExUnit.CaptureLog.capture_log(fn ->
        assert DriversLicenseValidation.date_of_birth("WA", number, known_dob: fallback) == fallback
      end)

      assert log =~ "[DLValidator] WA DOB parse failed"
    end

    test "valid: lowercase name context" do
      number = "SMITHJ821BC"
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "john", last_name: "smith", known_dob: ~D[1980-01-01]) == ~D[1980-01-01]
    end

    test "invalid: mismatched name fallback" do
      number = "SMITHJ821BC"
      fallback = ~D[1980-01-01]
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "Alice", last_name: "Brown", known_dob: fallback) == fallback
    end

    test "edge: valid with 'T' as month" do
      number = "SMITHJ821CT"
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "John", last_name: "Smith", known_dob: ~D[1980-02-01]) == ~D[1980-02-01]
    end

    test "edge: long DL format" do
      number = "JONESM821ZT"
      assert DriversLicenseValidation.valid?("WA", number)
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "Matt", last_name: "Jones", known_dob: ~D[1995-05-05]) == ~D[1995-05-05]
    end
  end

  # -- NEW HAMPSHIRE (NH) --
  describe "NH - New Hampshire" do
    test "valid: encoded name and DOB" do
      number = "12ABC12345"
      dob = ~D[1990-06-15]
      assert DriversLicenseValidation.valid?("NH", number)
      assert DriversLicenseValidation.date_of_birth("NH", number, first_name: "John", last_name: "Smith", known_dob: dob) == dob
    end

    test "invalid: wrong last name initial fallback" do
      number = "06ZHJ85091"
      dob = ~D[1985-06-09]
      assert DriversLicenseValidation.valid?("NH", number)
      assert DriversLicenseValidation.date_of_birth("NH", number, first_name: "John", last_name: "Smith", known_dob: dob) == dob
    end
  end

  # -- CONNECTICUT (CT) --
  describe "CT - Connecticut" do
    test "valid with fallback DOB" do
      dln = "151234567"
      dob = ~D[1992-03-01]
      assert DriversLicenseValidation.valid?("CT", dln)
      assert DriversLicenseValidation.date_of_birth("CT", dln, known_dob: dob) == dob
    end
  end

  # -- MONTANA (MT) --
  describe "MT - Montana" do
    test "valid: 13-digit encoded DOB" do
      dln = "0300199241090"
      dob = ~D[1992-03-09]
      assert DriversLicenseValidation.valid?("MT", dln)
      assert DriversLicenseValidation.date_of_birth("MT", dln, known_dob: dob) == dob
    end

    test "valid: multiple accepted formats (fallback DOB only)" do
      formats = [
        {"ABC1234567890", ~D[1990-01-01]},
        {"A12345678", ~D[1985-07-15]},
        {"123456789", ~D[2000-12-31]}
      ]

      Enum.each(formats, fn {dln, dob} ->
        assert DriversLicenseValidation.valid?("MT", dln)
        assert DriversLicenseValidation.date_of_birth("MT", dln, known_dob: dob) == dob
      end)
    end

    test "invalid: incorrect DOB encoding, fallback to known" do
      dln = "0400199241090"  # wrong month
      dob = ~D[1992-03-09]
      assert DriversLicenseValidation.valid?("MT", dln)
      assert DriversLicenseValidation.date_of_birth("MT", dln, known_dob: dob) == dob
    end
  end

  # -- NORTH DAKOTA (ND) --
  describe "ND - North Dakota" do
    test "valid: known DOB fallback" do
      dln = "ABC123456"
      dob = ~D[1982-07-04]
      assert DriversLicenseValidation.valid?("ND", dln)
      assert DriversLicenseValidation.date_of_birth("ND", dln, known_dob: dob) == dob
    end

    test "valid: encoded last name and birth year" do
      dln = "JOH951234"
      dob = ~D[1995-11-23]
      assert DriversLicenseValidation.valid?("ND", dln)
      assert DriversLicenseValidation.date_of_birth("ND", dln, first_name: "Emily", last_name: "Johnson", known_dob: dob) == ~D[1995-01-01]
    end

    test "invalid: mismatched last name prefix" do
      dln = "SMI951234"
      dob = ~D[1995-11-23]
      assert DriversLicenseValidation.valid?("ND", dln)
      assert DriversLicenseValidation.date_of_birth("ND", dln, first_name: "Emily", last_name: "Johnson", known_dob: dob) == dob
    end
  end

  # -- UNKNOWN/GENERIC CASES --
  describe "generic or unknown state behaviors" do
    test "unknown state code" do
      refute DriversLicenseValidation.valid?("ZZ", "A1234567")
      assert DriversLicenseValidation.date_of_birth("ZZ", "A1234567") == "N/A"
    end

    test "valid format but no DOB extractor" do
      assert DriversLicenseValidation.valid?("OR", "123456789")
      assert DriversLicenseValidation.date_of_birth("OR", "123456789") == "N/A"
    end
  end
end
