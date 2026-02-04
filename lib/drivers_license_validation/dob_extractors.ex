defmodule DriversLicenseValidation.DOBExtractors do
  @moduledoc """
  Dispatches DOB extraction to state-specific extractors.
  """

  alias DriversLicenseValidation.DOBExtractors.{
    Florida,
    Illinois,
    MdMi,
    NewJersey,
    Washington,
    NewHampshire,
    Connecticut,
    Montana,
    NorthDakota
  }

  @dob_extractors %{
    "FL" => &Florida.extract/2,
    "WI" => &Florida.extract/2,
    "IL" => &Illinois.extract/2,
    "MI" => &MdMi.extract/2,
    "MD" => &MdMi.extract/2,
    "NJ" => &NewJersey.extract/2,
    "WA" => &Washington.extract/2,
    "NH" => &NewHampshire.extract/2,
    "CT" => &Connecticut.extract/2,
    "MT" => &Montana.extract/2,
    "ND" => &NorthDakota.extract/2
  }

  def get(state), do: Map.get(@dob_extractors, String.upcase(state))
end
