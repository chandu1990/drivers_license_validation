defmodule DriversLicenseValidation.DOBExtractors.Florida do
  require Logger
  alias DriversLicenseValidation.Util

  @doc """
  Extracts DOB from FL/WI license numbers using a YY + DOY encoding.
  Supports both 12-digit (FL) and 13-digit (WI) numeric structures.
  """
  @spec extract(String.t(), keyword()) :: {:ok, Date.t()} | {:error, atom()}
  def extract(dl, _ctx) do
    clean = String.replace(dl, "-", "")

    with true <- byte_size(clean) >= 13,
         <<_alpha::binary-size(1), yy::binary-size(2), _mid::binary-size(5), rest::binary>> <- clean,
         yydoy <- String.slice(rest, 0, 3),
         {year, _} <- Integer.parse(yy),
         {code, _} <- Integer.parse(yydoy),
         {:ok, base} <- Date.new(Util.infer_full_year(year), 1, 1) do

      day_of_year = if code > 500, do: code - 500, else: code

      # Add DOY to January 1 to compute real date
      {:ok, Date.add(base, day_of_year - 1)}
    else
      _ ->
        Logger.warning("[DLValidator] FL/WI DOB parse failed")
        {:error, :parsing_error}
    end
  end
end
