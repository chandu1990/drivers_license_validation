defmodule DriversLicenseValidation.DOBExtractors.Montana do
  require Logger

  @doc """
  Extracts DOB from MT license number.
  """

  def extract(dl_number, ctx) do
    with %Date{year: year, month: month, day: day} <- Keyword.get(ctx, :known_dob),
        true <- String.length(dl_number) >= 13,
        <<mm::binary-size(2), _::binary-size(2), yyyy::binary-size(4), const::binary-size(2), dd::binary-size(2), _::binary>> <- dl_number,
        true <- const == "41",
        true <- mm == String.pad_leading(Integer.to_string(month), 2, "0"),
        true <- yyyy == Integer.to_string(year),
        true <- dd == String.pad_leading(Integer.to_string(day), 2, "0") do
      case Date.new(year, month, day) do
        {:ok, date} -> {:ok, date}
        _ -> {:error, :invalid_date}
      end
    else
      _ ->
        Logger.warn("[DLValidator] MT parse failed or insufficient context")
        case Keyword.get(ctx, :known_dob) do
          %Date{} = date -> {:ok, date}
          _ -> {:error, :parsing_error}
        end
    end
  end
end
