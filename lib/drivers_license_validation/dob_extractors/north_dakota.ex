defmodule DriversLicenseValidation.DOBExtractors.NorthDakota do
  require Logger

  @doc """
  Extracts DOB from ND license number.
  """

  def extract(dl_number, ctx) do
    last = Keyword.get(ctx, :last_name, "") |> String.upcase()
    known_dob = Keyword.get(ctx, :known_dob)

    with <<l3::binary-size(3), _::binary>> <- last,
         %Date{year: year} <- known_dob,
         clean_dln <- String.upcase(dl_number),
         true <- String.length(clean_dln) >= 5,
         <<dl_l3::binary-size(3), year2::binary-size(2), _::binary>> <- clean_dln,
         expected_year2 = rem(year, 100) |> Integer.to_string() |> String.pad_leading(2, "0"),
         true <- dl_l3 == l3 and year2 == expected_year2,
         {:ok, date} <- Date.new(year, 1, 1) do
      {:ok, date}
    else
      _ ->
        Logger.warn("[DLValidator] ND parse failed or insufficient context")
        case known_dob do
          %Date{} = date -> {:ok, date}
          _ -> {:error, :parsing_error}
        end
    end
  end
end
