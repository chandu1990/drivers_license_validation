defmodule DriversLicenseValidation.DOBExtractors do
  require Logger
  @moduledoc false

  @dob_extractors %{
    "FL" => &__MODULE__.florida/2,
    "WI" => &__MODULE__.florida/2,
    "IL" => &__MODULE__.illinois/2,
    "MI" => &__MODULE__.md_mi/2,
    "MD" => &__MODULE__.md_mi/2,
    "NJ" => &__MODULE__.new_jersey/2,
    "WA" => &__MODULE__.washington/2,
    "NH" => &__MODULE__.new_hampshire/2,
    "CT" => &__MODULE__.connecticut/2,
    "MT" => &__MODULE__.montana/2,
    "ND" => &__MODULE__.north_dakota/2
  }

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


  def get(state), do: Map.get(@dob_extractors, String.upcase(state))

  def florida(<<_::binary-size(1), yy::binary-size(2), _mid::binary-size(5), yydoy::binary-size(3), _::binary>>, _ctx) do
    # Extract YY and DOY from license:
    # - YY (2 digits) → birth year
    # - DOY (3 digits) → encoded day-of-year, possibly offset for females (code > 500)
    #
    # Total structure expected: 1 alpha + 12 numeric
    # Pattern (FL/WI): AYYxxxxxYYYzzz
    #                  ^  ^     ^
    #                  |  |     └─ yydoy = last 3 digits (encoded DOY, adjusted for gender)
    #                  |  └─ mid 5 digits
    #                  └─ alpha + YY (2-digit year)

    with {year, _} <- Integer.parse(yy),         # Parse 2-digit year
        {code, _} <- Integer.parse(yydoy),      # Parse last 3-digit DOY code
        {:ok, base} <- Date.new(infer_full_year(year), 1, 1) do # Create Jan 1 of full year

      # Adjust DOY:
      # If code > 500, it's for female → subtract 500 to get real DOY
      day_of_year = if code > 500, do: code - 500, else: code

      # Add (DOY - 1) days to Jan 1 to compute actual date
      Date.add(base, day_of_year - 1)
    else
      _ ->
        # On parse or date construction failure, log warning and return "N/A"
        Logger.warn("[DLValidator] FL/WI DOB parse failed")
        "N/A"
    end
  end

  # Main Illinois DOB extraction dispatcher
  def illinois(license, _ctx) do
    case license do
      # Match legacy/alt format: 11 numeric + 1 alpha
      # Example: "12345685098A" (YY = 85, DOY = 098)
      <<prefix::binary-size(6), yy::binary-size(2), doy::binary-size(3), suffix::binary-size(1)>> ->
        if String.match?(prefix, ~r/^\d+$/) and String.match?(suffix, ~r/^[A-Z]$/) do
          # If prefix is numeric and suffix is alpha, it's a valid alt format
          parse_il_date(yy, doy, :alt)
        else
          # Fallback to try standard if structure doesn’t match
          try_standard_il(license, _ctx)
        end

      # Match standard format: 1 alpha + 11 numeric
      # Example: "I85000000981"
      <<_prefix::binary-size(1), yy::binary-size(2), _mid::binary-size(5), doy::binary-size(3), _rest::binary>> ->
        parse_il_date(yy, doy, :standard)

      # If neither format matched, return fallback
      _ ->
        Logger.warn("[DLValidator] IL DOB format not recognized")
        "N/A"
    end
  end

  # Shared function to convert year + day-of-year into Date struct
  defp parse_il_date(yy, doy, _type) do
    case {Integer.parse(doy), Integer.parse(yy)} do
      {{doy_int, _}, {yy_int, _}} ->
        # In Illinois format, DOY > 600 may indicate gender encoding
        adjusted_doy = if doy_int > 600, do: doy_int - 600, else: doy_int

        # Infer full 4-digit year from 2-digit YY
        year = infer_full_year(yy_int)

        # Convert day-of-year to month/day by adding to Jan 1st
        month = div(adjusted_doy, 31) + 1
        day = rem(adjusted_doy, 31) + 1

        # Return valid Date or fallback
        case Date.new(year, month, day) do
          {:ok, date} -> date
          _ -> Logger.warn("[DLValidator] IL DOB parse failed: invalid date"); "N/A"
        end

      _ ->
        Logger.warn("[DLValidator] IL DOB parse failed: parse error")
        "N/A"
    end
  end

  # Fallback utility: retry matching with standard format
  defp try_standard_il(<<_prefix::binary-size(1), yy::binary-size(2), _mid::binary-size(5), doy::binary-size(3), _rest::binary>>, _ctx),
    do: parse_il_date(yy, doy, :standard)

  # If license structure doesn't match at all
  defp try_standard_il(_, _), do: "N/A"

  def md_mi(<<_::binary-size(10), code::binary-size(3), _::binary>>, _ctx) do
    case DriversLicenseValidation.MdMiDOBDecoder.get_date_components(code) do
      {m, d} ->
        case Date.new(1900, m, d) do  # we don't care about the year.
          {:ok, date} -> date
          _ -> Logger.warn("[DLValidator] MD/MI date creation failed"); "N/A"
        end

      _ ->
        Logger.warn("[DLValidator] MD/MI DOB code not found")
        "N/A"
    end
  end


  def new_jersey(<<_::binary-size(10), mm::binary-size(2), yy::binary-size(2), _::binary>>, _ctx) do
    month = Map.get(@month_aliases, mm)

    with true <- not is_nil(month),
        {y, _} <- Integer.parse(yy),
        year <- infer_full_year(y),
        {:ok, date} <- Date.new(year, month, 1) do
      date
    else
      _ -> Logger.warn("[DLValidator] NJ DOB parse failed"); "N/A"
    end
  end

  def washington(dl_number, ctx) do
    normalized_dln = String.replace(dl_number, "*", " ")

    case extract_wa_dob(normalized_dln, ctx) do
      {:ok, dob} -> dob
      _ ->
        Logger.warn("[DLValidator] WA DOB parse failed, using fallback if available")
        fallback = Keyword.get(ctx, :known_dob)

        case fallback do
          %Date{} = date -> date
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
        _sep::binary-size(1), month_char::binary-size(1), day_char::binary-size(1), _rest::binary>> = dl_number

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

  def new_hampshire(dl_number, ctx) do
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
        Date.new(year, month, day)
      else
        "N/A"
      end
    else
      _ ->
        Logger.warn("[DLValidator] NH parse failed or insufficient context")
        Keyword.get(ctx, :known_dob, "N/A")
    end
  end

  def connecticut(dl_number, ctx) do
    with %Date{year: year, month: month} <- Keyword.get(ctx, :known_dob),
        clean_dln <- String.replace(dl_number, "-", ""),
        true <- String.length(clean_dln) >= 2,
        <<code::binary-size(2), _::binary>> <- clean_dln,
        {encoded_month, _} <- Integer.parse(code) do

      expected_month =
        if rem(year, 2) == 0 do
          # Even year: MM + 12
          month + 12
        else
          # Odd year: MM
          month
        end

      if encoded_month == expected_month do
        case Date.new(year, month, 1) do
          {:ok, date} -> date
          _ -> "N/A"
        end
      else
        "N/A"
      end
    else
      _ ->
        Logger.warn("[DLValidator] CT parse failed or insufficient context")
        Keyword.get(ctx, :known_dob, "N/A")
    end
  end

  def montana(dl_number, ctx) do
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

  def north_dakota(_, ctx) do
    Keyword.get(ctx, :known_dob) || (Logger.warn("[DLValidator] ND needs DOB and name"); "N/A")
  end

  defp infer_full_year(two_digit_year) when is_integer(two_digit_year) do
    current_year = Date.utc_today().year
    current_century = div(current_year, 100) * 100

    # this_year = current century + YY
    # past_year = previous century + YY
    this_year = current_century + two_digit_year
    past_year = current_century - 100 + two_digit_year

    if this_year <= current_year + 20 do
      this_year
    else
      past_year
    end
  end

  # Optional: support binary input
  defp infer_full_year(y) when is_binary(y) do
    case Integer.parse(y) do
      {int, _} -> infer_full_year(int)
      _ -> raise ArgumentError, "invalid year: #{inspect y}"
    end
  end

  defp month_char_to_number(char) do
    %{
      "B" => 1, "S" => 1, "C" => 2, "T" => 2, "D" => 3, "U" => 3,
      "J" => 4, "1" => 4, "K" => 5, "2" => 5, "L" => 6, "3" => 6,
      "M" => 7, "4" => 7, "N" => 8, "5" => 8, "O" => 9, "6" => 9,
      "P" => 10, "7" => 10, "Q" => 11, "8" => 11, "R" => 12, "9" => 12
    }[String.upcase(char)] || 1
  end

  defp day_char_to_number(char) do
    %{
      "A" => 1, "B" => 2, "C" => 3, "D" => 4, "E" => 5, "F" => 6,
      "G" => 7, "H" => 8, "Z" => 9, "S" => 10, "J" => 11, "K" => 12,
      "L" => 13, "M" => 14, "N" => 15, "W" => 16, "P" => 17, "Q" => 18,
      "R" => 19, "0" => 20, "1" => 21, "2" => 22, "3" => 23, "4" => 24,
      "5" => 25, "6" => 26, "7" => 27, "8" => 28, "9" => 29,
      "T" => 20, "U" => 31
    }[String.upcase(char)] || 1
  end
end