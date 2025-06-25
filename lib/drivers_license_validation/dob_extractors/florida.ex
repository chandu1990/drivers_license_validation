defmodule DriversLicenseValidation.DOBExtractors.Florida do
  require Logger
  alias DriversLicenseValidation.Util

  @doc """
  Extracts DOB from FL/WI license number using YY + DOY pattern.
  """

  def extract(
        <<_::binary-size(1), yy::binary-size(2), _mid::binary-size(5), yydoy::binary-size(3),
          _::binary>>,
        _ctx
      ) do
    # Extract YY and DOY from license:
    # - YY (2 digits) → birth year
    # - DOY (3 digits) → encoded day-of-year, possibly offset for females (code > 500)
    #
    # Total structure expected: 1 alpha + 12 numeric
    # Pattern (FL/WI): AYYxxxxxYYYzzz
    #                  ^  ^     ^
    #                  |  |     └─ yydoy = last 3 digits (encoded DOY, adjusted for gender)
    #                  |  └─ mid 5 digits
    #                  └─ alpha + YY (2-digit year)

    # Parse 2-digit year
    with {year, _} <- Integer.parse(yy),
         # Parse last 3-digit DOY code
         {code, _} <- Integer.parse(yydoy),
         # Create Jan 1 of full year
         {:ok, base} <- Date.new(Util.infer_full_year(year), 1, 1) do
      # Adjust DOY:
      # If code > 500, it's for female → subtract 500 to get real DOY
      day_of_year = if code > 500, do: code - 500, else: code

      # Add (DOY - 1) days to Jan 1 to compute actual date
      Date.add(base, day_of_year - 1)
    else
      _ ->
        # On parse or date construction failure, log warning and return "N/A"
        Logger.warn("[DLValidator] FL/WI DOB parse failed")
        "N/A"
    end
  end
end
