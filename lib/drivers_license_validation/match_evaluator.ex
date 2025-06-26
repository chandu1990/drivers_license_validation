defmodule DriversLicenseValidation.MatchEvaluator do
  @moduledoc """
  Utility module to evaluate if the date of birth extracted from a driver's license
  matches a known DOB. Supports all DOB-encoded states.
  """

  @dob_states ~w(
    CT FL WI IL MD MI MT NH NJ ND WA
  )

  @spec dob_encoded_state?(String.t()) :: boolean()
  def dob_encoded_state?(state), do: String.upcase(state) in @dob_states

  @spec match?(String.t(), String.t(), Date.t()) :: boolean()
  def match?(state, license, %Date{} = known_dob, ctx \\ []) do
    DriversLicenseValidation.date_of_birth(state, license, Keyword.merge(ctx, known_dob: known_dob)) == known_dob
  end
end
