defmodule DriversLicenseValidation.Util do
  def infer_full_year(two_digit_year) when is_integer(two_digit_year) do
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
  def infer_full_year(y) when is_binary(y) do
    case Integer.parse(y) do
      {int, _} -> infer_full_year(int)
      _ -> raise ArgumentError, "invalid year: #{inspect(y)}"
    end
  end
end
