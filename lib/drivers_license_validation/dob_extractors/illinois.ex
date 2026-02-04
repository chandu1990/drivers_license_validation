defmodule DriversLicenseValidation.DOBExtractors.Illinois do
  require Logger
  alias DriversLicenseValidation.Util

  @doc """
  Extracts DOB from IL license number.
  """
  def extract(license, ctx) do
    case license do
      # Match legacy/alt format: 11 numeric + 1 alpha
      # Example: "12345685098A" (YY = 85, DOY = 098)
      <<prefix::binary-size(6), yy::binary-size(2), doy::binary-size(3), suffix::binary-size(1)>> ->
        if String.match?(prefix, ~r/^\d+$/) and String.match?(suffix, ~r/^[A-Z]$/) do
          # If prefix is numeric and suffix is alpha, it's a valid alt format
          parse_il_date(yy, doy, :alt)
        else
          # Fallback to try standard if structure doesn't match
          try_standard_il(license, ctx)
        end

      # Match standard format: 1 alpha + 11 numeric
      # Example: "I85000000981"
      <<_prefix::binary-size(1), yy::binary-size(2), _mid::binary-size(5), doy::binary-size(3),
        _rest::binary>> ->
        parse_il_date(yy, doy, :standard)

      # If neither format matched, return fallback
      _ ->
        Logger.warn("[DLValidator] IL DOB format not recognized")
        {:error, :parsing_error}
    end
  end

  # Shared function to convert year + day-of-year into Date struct
  defp parse_il_date(yy, doy, _type) do
    case {Integer.parse(doy), Integer.parse(yy)} do
      {{doy_int, _}, {yy_int, _}} ->
        # In Illinois format, DOY > 600 may indicate gender encoding
        adjusted_doy = if doy_int > 600, do: doy_int - 600, else: doy_int

        # Infer full 4-digit year from 2-digit YY
        year = Util.infer_full_year(yy_int)

        # Convert day-of-year to month/day by adding to Jan 1st
        month = div(adjusted_doy, 31) + 1
        day = rem(adjusted_doy, 31) + 1

        # Return valid Date or fallback
        case Date.new(year, month, day) do
          {:ok, date} ->
            {:ok, date}

          _ ->
            Logger.warn("[DLValidator] IL DOB parse failed: invalid date")
            {:error, :invalid_date}
        end

      _ ->
        Logger.warn("[DLValidator] IL DOB parse failed: parse error")
        {:error, :parsing_error}
    end
  end

  # Fallback utility: retry matching with standard format
  defp try_standard_il(
         <<_prefix::binary-size(1), yy::binary-size(2), _mid::binary-size(5), doy::binary-size(3),
           _rest::binary>>,
         _ctx
       ),
       do: parse_il_date(yy, doy, :standard)

  # If license structure doesn't match at all
  defp try_standard_il(_, _), do: {:error, :parsing_error}
end
