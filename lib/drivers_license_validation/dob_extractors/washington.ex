defmodule DriversLicenseValidation.DOBExtractors.Washington do
  require Logger
  alias DriversLicenseValidation.Util

  @doc """
  Extracts DOB from WA license number.
  """

  def extract(dl_number, ctx) do
    normalized_dln = String.replace(dl_number, "*", " ")

    case extract_wa_dob(normalized_dln, ctx) do
      {:ok, dob} ->
        dob

      _ ->
        Logger.warn("[DLValidator] WA DOB parse failed, using fallback if available")
        fallback = Keyword.get(ctx, :known_dob)

        case fallback do
          %Date{} = date ->
            date

          other ->
            Logger.warn("[DLValidator] Fallback value is not a Date: #{inspect(other)}")
            "N/A"
        end
    end
  end

  defp extract_wa_dob(dl_number, ctx) do
    if String.length(dl_number) < 12 do
      :error
    else
      <<lname_seg::binary-size(5), finitial::binary-size(1), year_code::binary-size(2),
        _sep::binary-size(1), month_char::binary-size(1), day_char::binary-size(1),
        _rest::binary>> = dl_number

      last = String.upcase(Keyword.get(ctx, :last_name, ""))
      first = String.upcase(Keyword.get(ctx, :first_name, ""))

      if String.starts_with?(last, lname_seg) and String.starts_with?(first, finitial) do
        with {y, _} <- Integer.parse(year_code),
             month when is_integer(month) <- month_char_to_number(month_char),
             day when is_integer(day) <- day_char_to_number(day_char),
             {:ok, date} <- Date.new(1900 + (100 - y), month, day) do
          {:ok, date}
        else
          _ -> :error
        end
      else
        :error
      end
    end
  end

  defp month_char_to_number(char) do
    %{
      "B" => 1,
      "S" => 1,
      "C" => 2,
      "T" => 2,
      "D" => 3,
      "U" => 3,
      "J" => 4,
      "1" => 4,
      "K" => 5,
      "2" => 5,
      "L" => 6,
      "3" => 6,
      "M" => 7,
      "4" => 7,
      "N" => 8,
      "5" => 8,
      "O" => 9,
      "6" => 9,
      "P" => 10,
      "7" => 10,
      "Q" => 11,
      "8" => 11,
      "R" => 12,
      "9" => 12
    }[String.upcase(char)] || 1
  end

  defp day_char_to_number(char) do
    %{
      "A" => 1,
      "B" => 2,
      "C" => 3,
      "D" => 4,
      "E" => 5,
      "F" => 6,
      "G" => 7,
      "H" => 8,
      "Z" => 9,
      "S" => 10,
      "J" => 11,
      "K" => 12,
      "L" => 13,
      "M" => 14,
      "N" => 15,
      "W" => 16,
      "P" => 17,
      "Q" => 18,
      "R" => 19,
      "0" => 20,
      "1" => 21,
      "2" => 22,
      "3" => 23,
      "4" => 24,
      "5" => 25,
      "6" => 26,
      "7" => 27,
      "8" => 28,
      "9" => 29,
      "T" => 20,
      "U" => 31
    }[String.upcase(char)] || 1
  end
end
