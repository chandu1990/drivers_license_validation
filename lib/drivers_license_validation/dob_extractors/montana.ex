defmodule DriversLicenseValidation.DOBExtractors.Montana do
  require Logger
  alias DriversLicenseValidation.Util

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
        {:ok, date} -> date
        _ -> "N/A"
      end
    else
      _ ->
        Logger.warn("[DLValidator] MT parse failed or insufficient context")
        Keyword.get(ctx, :known_dob, "N/A")
    end
  end
end
