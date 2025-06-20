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

  def get(state), do: Map.get(@dob_extractors, String.upcase(state))

  def florida(<<_::binary-size(1), yy::binary-size(2), _mid::binary-size(5), yydoy::binary-size(3), _::binary>>, _ctx) do
    with {year, _} <- Integer.parse(yy),
        {code, _} <- Integer.parse(yydoy),
        {:ok, base} <- Date.new(1900 + year, 1, 1)
    do
      day_of_year = if code > 500, do: code - 500, else: code
      Date.add(base, day_of_year - 1)
    else
      _ -> Logger.warn("[DLValidator] FL/WI DOB parse failed")
          "N/A"
    end
  end

  def illinois(<<_::binary-size(7), doy::binary-size(3), _::binary>>, _ctx) do
    with {d, _} <- Integer.parse(doy),
         month <- div(d, 31),
         day <- rem(d, 31),
         {:ok, date} <- Date.new(1900 + rem(d, 100), month + 1, day + 1) do
      date
    else
      _ -> Logger.warn("[DLValidator] IL DOB parse failed"); "N/A"
    end
  end

  def md_mi(<<_::binary-size(10), code::binary-size(3), _::binary>>, _ctx) do
    dob_map = %{"002" => {1, 1}, "007" => {1, 2}, "822" => {1, 31}, "086" => {2, 1}, "156" => {2, 29}}
    case Map.get(dob_map, code) do
      {m, d} -> Date.new!(1900, m, d)
      _ -> Logger.warn("[DLValidator] MD/MI DOB code not found"); "N/A"
    end
  end

  def new_jersey(<<_::binary-size(10), mm::binary-size(2), yy::binary-size(2), _::binary>>, _ctx) do
    with {m, _} <- Integer.parse(mm),
        {y, _} <- Integer.parse(yy),
        year <- infer_full_year(y),
        {:ok, date} <- Date.new(year, m, 1) do
      date
    else
      _ -> Logger.warn("[DLValidator] NJ DOB parse failed"); "N/A"
    end
  end

  def washington(_, ctx) do
    Keyword.get(ctx, :known_dob) || (Logger.warn("[DLValidator] WA requires known DOB and names"); "N/A")
  end

  def new_hampshire(_, ctx) do
    Keyword.get(ctx, :known_dob) || (Logger.warn("[DLValidator] NH requires full name and DOB"); "N/A")
  end

  def connecticut(_, ctx) do
    Keyword.get(ctx, :known_dob) || (Logger.warn("[DLValidator] CT requires year parity for encoding"); "N/A")
  end

  def montana(_, ctx) do
    Keyword.get(ctx, :known_dob) || (Logger.warn("[DLValidator] MT needs DOB"); "N/A")
  end

  def north_dakota(_, ctx) do
    Keyword.get(ctx, :known_dob) || (Logger.warn("[DLValidator] ND needs DOB and name"); "N/A")
  end

  def infer_full_year(two_digit_year) do
    current_year = Date.utc_today().year
    current_century = div(current_year, 100) * 100

    past_year = current_century - 100 + two_digit_year
    this_year = current_century + two_digit_year

    # if we're in 2024, yy = 99 → prefer 1999, yy = 25 → prefer 2025
    cond do
      this_year <= current_year + 20 -> this_year
      true -> past_year
    end
  end
end