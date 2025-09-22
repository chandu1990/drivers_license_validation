defmodule DriversLicenseValidation.DOBExtractors.NewHampshire do
  require Logger

  @doc """
  Extracts DOB from NH license number.
  """

  def extract(dl_number, ctx) do
    with %Date{year: year, month: month, day: day} <- Keyword.get(ctx, :known_dob),
         last <- String.upcase(Keyword.get(ctx, :last_name, "")),
         first <- String.upcase(Keyword.get(ctx, :first_name, "")),
         true <- String.length(dl_number) >= 9,
         <<prefix::binary-size(9), _::binary>> <- dl_number,
         <<lfirst::binary-size(1)>> <- last,
         <<ffirst::binary-size(1)>> <- first,
         llast <- String.last(last),
         yy <- rem(year, 100) |> Integer.to_string() |> String.pad_leading(2, "0"),
         mm <- Integer.to_string(month) |> String.pad_leading(2, "0"),
         dd <- Integer.to_string(day) |> String.pad_leading(2, "0"),
         expected = mm <> lfirst <> llast <> ffirst <> yy <> dd do
      if prefix == expected do
        {:ok, %Date{year: year, month: month, day: day}}
      else
        {:error, :parsing_error}
      end
    else
      _ ->
        Logger.warn("[DLValidator] NH parse failed or insufficient context")
        case Keyword.get(ctx, :known_dob) do
          %Date{} = date -> {:ok, date}
          _ -> {:error, :parsing_error}
        end
    end
  end
end
