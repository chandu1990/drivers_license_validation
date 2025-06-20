
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
      assert DriversLicenseValidation.valid?("IL", "I85107123456")
      assert DriversLicenseValidation.date_of_birth("IL", "I85107123456") != "N/A"
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

    test "WA format and fallback to known DOB" do
      number = "SMITHJ821BC"
      assert DriversLicenseValidation.valid?("WA", number)
      assert DriversLicenseValidation.date_of_birth("WA", number, first_name: "John", last_name: "Smith", known_dob: ~D[1980-01-01]) == ~D[1980-01-01]
    end

    test "NH format with fallback DOB" do
      number = "12ABC12345"
      assert DriversLicenseValidation.valid?("NH", number)
      assert DriversLicenseValidation.date_of_birth("NH", number, known_dob: ~D[1990-06-15]) == ~D[1990-06-15]
    end

    test "CT format with fallback DOB" do
      assert DriversLicenseValidation.valid?("CT", "123456789")
      assert DriversLicenseValidation.date_of_birth("CT", "123456789", known_dob: ~D[1992-03-01]) == ~D[1992-03-01]
    end

    test "MT 14-digit DL with known DOB" do
      assert DriversLicenseValidation.valid?("MT", "12345678901234")
      assert DriversLicenseValidation.date_of_birth("MT", "12345678901234", known_dob: ~D[1978-10-30]) == ~D[1978-10-30]
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

    test "Unknown state code" do
      refute DriversLicenseValidation.valid?("ZZ", "A1234567")
      assert DriversLicenseValidation.date_of_birth("ZZ", "A1234567") == "N/A"
    end

    test "Valid format but no DOB extractor" do
      assert DriversLicenseValidation.valid?("OR", "123456789")
      assert DriversLicenseValidation.date_of_birth("OR", "123456789") == "N/A"
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
