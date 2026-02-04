defmodule DriversLicenseValidationTest do
  use ExUnit.Case, async: true
  alias DriversLicenseValidation

  # -- CALIFORNIA (CA) --
  describe "CA - California" do
    test "valid: 1 alpha + 7 numeric" do
      assert DriversLicenseValidation.valid_with_dob?("CA", "A1234567", ~D[1985-01-01])
    end

    test "invalid: too short/too long" do
      refute DriversLicenseValidation.valid_with_dob?("CA", "A123456", ~D[1985-01-01])
      refute DriversLicenseValidation.valid_with_dob?("CA", "A12345678", ~D[1985-01-01])
    end
  end

  # -- FLORIDA (FL) --
  describe "FL - Florida" do
    test "valid: 1 alpha + 12 numeric with DOB" do
      number = "F850000010600"
      assert DriversLicenseValidation.valid_with_dob?("FL", number, ~D[1985-04-16])
    end

    test "invalid: wrong length or malformed" do
      refute DriversLicenseValidation.valid_with_dob?("FL", "F123", ~D[1985-04-16])
    end
  end

  # -- WISCONSIN (WI) --
  describe "WI - Wisconsin" do
    test "valid: FL-style format" do
      number = "W8500000106000"
      assert DriversLicenseValidation.valid_with_dob?("WI", number, ~D[1985-04-16])
    end

    test "edge: alternate valid format" do
      assert DriversLicenseValidation.valid_with_dob?("WI", "W9910789678001", ~D[1999-06-27])
    end
  end

  # -- ILLINOIS (IL) --
  describe "IL - Illinois" do
    test "valid: 1 alpha + 11 numeric" do
      license = "I85000000981"
      assert DriversLicenseValidation.valid_with_dob?("IL", license, ~D[1985-04-06])
    end

    test "valid: alt format 11 numeric + 1 alpha" do
      license = "12345685098A"
      assert DriversLicenseValidation.valid_with_dob?("IL", license, ~D[1985-04-06])
    end

    test "invalid formats and state" do
      invalids = [
        {"IL", "12345678901"},
        {"IL", "185000000981"},
        {"IL", "I85000981"},
        {"IL", "12345685098"},
        {"IL", "ABC12385098A"},
        {"IL", "123456850981"},
        {"ZZ", "I85000000981"}
      ]

      Enum.each(invalids, fn {state, dl} ->
        refute DriversLicenseValidation.valid_with_dob?(state, dl, ~D[1985-04-06])
      end)
    end
  end

  # -- MARYLAND & MICHIGAN --
  describe "MD/MI - Maryland & Michigan" do
    test "valid with mapped DOB" do
      number = "M123456789002"
      assert DriversLicenseValidation.valid_with_dob?("MD", number, ~D[1900-01-01])
      assert DriversLicenseValidation.valid_with_dob?("MI", number, ~D[1900-01-01])
    end
  end

  # -- NEW JERSEY (NJ) --
  describe "NJ - New Jersey" do
    test "valid: standard encoded DOB" do
      number = "A12345678908510"
      assert DriversLicenseValidation.valid_with_dob?("NJ", number, ~D[1951-08-01])
    end

    test "valid: future DOB example" do
      number = "A12345678905250"
      assert DriversLicenseValidation.valid_with_dob?("NJ", number, ~D[2025-05-01])
    end
  end

  # -- WASHINGTON (WA) --
  describe "WA - Washington" do
    test "valid with correct context and DOB" do
      number = "SMITHJ801BC1"
      dob = ~D[1980-01-03]

      assert DriversLicenseValidation.valid_with_dob?("WA", number, dob, first_name: "John", last_name: "Smith")
    end

    test "invalid: mismatched name fallback" do
      number = "SMITHJ821BC"
      mismatched_dob = ~D[1980-02-01]
      assert DriversLicenseValidation.date_of_birth("WA", number,
         first_name: "Alice",
         last_name: "Brown",
         known_dob: mismatched_dob
       ) == {:error, :parsing_error}

      # But:
      refute DriversLicenseValidation.valid_with_dob?("WA", number, mismatched_dob)
    end
  end

  # -- NEW HAMPSHIRE (NH) --
  describe "NH - New Hampshire" do
    test "valid: encoded name and DOB" do
      number = "12ABC12345"
      dob = ~D[1990-06-15]
      assert DriversLicenseValidation.valid_with_dob?("NH", number, dob)
    end
  end

  # -- CONNECTICUT (CT) --
  describe "CT - Connecticut" do
    test "valid with fallback DOB" do
      dln = "151234567"
      dob = ~D[1992-03-01]
      assert DriversLicenseValidation.valid_with_dob?("CT", dln, dob)
    end
  end

  # -- MONTANA (MT) --
  describe "MT - Montana" do
    test "valid: 13-digit encoded DOB" do
      dln = "0300199241090"
      dob = ~D[1992-03-09]
      assert DriversLicenseValidation.valid_with_dob?("MT", dln, dob)
    end
  end

  # -- NORTH DAKOTA (ND) --
  describe "ND - North Dakota" do
    test "valid: encoded last name and birth year" do
      dln = "JOH951234"
      dob = ~D[1995-11-23]
      assert DriversLicenseValidation.valid_with_dob?("ND", dln, dob)
    end
  end

  # -- UNKNOWN/GENERIC CASES --
  describe "generic or unknown state behaviors" do
    test "unknown state code" do
      refute DriversLicenseValidation.valid_with_dob?("ZZ", "A1234567", ~D[1985-01-01])
    end

    test "valid format but no DOB extractor" do
      assert DriversLicenseValidation.valid_with_dob?("OR", "123456789", ~D[1985-01-01])
    end
  end

  # -- DATE OF BIRTH FUNCTION TESTS --
  describe "date_of_birth function returns tuples" do
    test "returns {:error, :invalid_state} for unknown state" do
      assert DriversLicenseValidation.date_of_birth("ZZ", "A1234567") == {:error, :invalid_state}
    end

    test "returns {:ok, date} for valid FL extraction" do
      number = "F850000010600"
      assert {:ok, ~D[1985-04-16]} = DriversLicenseValidation.date_of_birth("FL", number)
    end

    test "returns {:error, :parsing_error} for invalid input" do
      assert {:error, :parsing_error} = DriversLicenseValidation.date_of_birth("FL", "invalid")
    end
  end
end
