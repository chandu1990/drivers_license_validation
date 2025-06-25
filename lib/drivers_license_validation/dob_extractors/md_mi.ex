defmodule DriversLicenseValidation.DOBExtractors.MdMi do
  require Logger
  alias DriversLicenseValidation.Util

  @doc """
    Extracts DOB from MD/MI license number.
  """

  def extract(<<_::binary-size(10), code::binary-size(3), _::binary>>, _ctx) do
    case DriversLicenseValidation.MdMiDOBDecoder.get_date_components(code) do
      {m, d} ->
        # we don't care about the year.
        case Date.new(1900, m, d) do
          {:ok, date} ->
            date

          _ ->
            Logger.warn("[DLValidator] MD/MI date creation failed")
            "N/A"
        end

      _ ->
        Logger.warn("[DLValidator] MD/MI DOB code not found")
        "N/A"
    end
  end
end
