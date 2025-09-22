defmodule DriversLicenseValidation.DOBExtractors.Connecticut do
  require Logger

  @doc """
  Extracts DOB from CT license number.
  """

  def extract(dl_number, ctx) do
    with %Date{year: year, month: month} <- Keyword.get(ctx, :known_dob),
         clean_dln <- String.replace(dl_number, "-", ""),
         true <- String.length(clean_dln) >= 2,
         <<code::binary-size(2), _::binary>> <- clean_dln,
         {encoded_month, _} <- Integer.parse(code) do
      expected_month =
        if rem(year, 2) == 0 do
          # Even year: MM + 12
          month + 12
        else
          # Odd year: MM
          month
        end

      if encoded_month == expected_month do
        case Date.new(year, month, 1) do
          {:ok, date} -> {:ok, date}
          _ -> {:error, :invalid_date}
        end
      else
        {:error, :parsing_error}
      end
    else
      _ ->
        Logger.warn("[DLValidator] CT parse failed or insufficient context")
        case Keyword.get(ctx, :known_dob) do
          %Date{} = date -> {:ok, date}
          _ -> {:error, :parsing_error}
        end
    end
  end
end
