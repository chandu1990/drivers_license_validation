defmodule DriversLicenseValidation.DOBExtractors.MdMi do
  require Logger

  @doc """
    Extracts DOB from MD/MI license number.
  """

  def extract(<<_::binary-size(10), code::binary-size(3), _::binary>>, ctx) do
    case DriversLicenseValidation.MdMiDOBDecoder.get_date_components(code) do
      {m, d} ->
        year =
          case Keyword.get(ctx, :known_dob) do
            %Date{year: y} -> y
            _ -> 1900  # we don't care about year.
          end

        case Date.new(year, m, d) do
          {:ok, date} -> date
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
