defmodule DriversLicenseValidation.DOBExtractors.NewJersey do
  require Logger
  alias DriversLicenseValidation.Util

  @doc """
    Extracts DOB from NJ license number.
  """

  @month_aliases %{
    "01" => 1,  "51" => 1,
    "02" => 2,  "52" => 2,
    "03" => 3,  "53" => 3,
    "04" => 4,  "54" => 4,
    "05" => 5,  "55" => 5,
    "06" => 6,  "56" => 6,
    "07" => 7,  "57" => 7,
    "08" => 8,  "58" => 8,
    "09" => 9,  "59" => 9,
    "10" => 10, "60" => 10,
    "11" => 11, "61" => 11,
    "12" => 12, "62" => 12
  }

  def extract(<<_::binary-size(10), mm::binary-size(2), yy::binary-size(2), _::binary>>, _ctx) do
    month = Map.get(@month_aliases, mm)

    with true <- not is_nil(month),
         {y, _} <- Integer.parse(yy),
         year <- Util.infer_full_year(y),
         {:ok, date} <- Date.new(year, month, 1) do
      date
    else
      _ ->
        Logger.warn("[DLValidator] NJ DOB parse failed")
        "N/A"
    end
  end
end
