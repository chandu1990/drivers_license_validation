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
          {:ok, date} -> {:ok, date}
          _ ->
            Logger.warning("[DLValidator] MD/MI date creation failed")
            {:error, :invalid_date}
        end

      _ ->
        Logger.warning("[DLValidator] MD/MI DOB code not found")
        {:error, :parsing_error}
    end
  end
end
