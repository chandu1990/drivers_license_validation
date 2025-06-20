defmodule DriversLicenseValidation do
  require Logger
  alias DriversLicenseValidation.{Formats, State, DOBExtractors}

  @spec valid?(String.t(), String.t()) :: boolean()
  def valid?(state, license) do
    abbr = State.normalize(state)

    case Formats.get(abbr) do
      nil -> false
      patterns -> Enum.any?(patterns, fn pattern -> match_pattern?(String.upcase(license), pattern) end)
    end
  end

  @spec date_of_birth(String.t(), String.t(), keyword()) :: Date.t() | String.t()
  def date_of_birth(state, license, ctx \\ []) do
    if valid?(state, license) do
      case DOBExtractors.get(state) do
        nil -> "N/A"
        extractor -> extractor.(license, ctx)
      end
    else
      "N/A"
    end
  end

  defp match_pattern?(license, pattern), do: match_segment(license, pattern)

  defp match_segment(<<>>, []), do: true
  defp match_segment(_, []), do: false
  defp match_segment("", _), do: false

  defp match_segment(license, [{:alpha, n} | rest]) do
    with true <- byte_size(license) >= n,
         <<seg::binary-size(n), rest_license::binary>> <- license,
         true <- only_alpha?(seg) do
      match_segment(rest_license, rest)
    else
      _ -> false
    end
  end

  defp match_segment(license, [{:numeric, n} | rest]) do
    with true <- byte_size(license) >= n,
         <<seg::binary-size(n), rest_license::binary>> <- license,
         true <- only_numeric?(seg) do
      match_segment(rest_license, rest)
    else
      _ -> false
    end
  end

  defp match_segment(license, [{:alpha, min, max} | rest]) do
    match_variable_length(license, min, max, &only_alpha?/1, rest)
  end

  defp match_segment(license, [{:numeric, min, max} | rest]) do
    match_variable_length(license, min, max, &only_numeric?/1, rest)
  end

  defp match_segment(license, [{:any, min, max} | rest]) do
    match_variable_length(license, min, max, &only_alphanum?/1, rest)
  end

  defp match_segment(license, [{:literal, lit} | rest]) do
    if String.starts_with?(license, lit) do
      match_segment(String.slice(license, String.length(lit)..-1), rest)
    else
      false
    end
  end

  defp match_segment(_, _), do: false

  defp match_variable_length(license, min, max, validator, rest) do
    Enum.any?(min..max, fn len ->
      byte_size(license) >= len and
        validator.(String.slice(license, 0, len)) and
        match_segment(String.slice(license, len..-1), rest)
    end)
  end

  defp only_alpha?(string), do: String.match?(string, ~r/^[A-Z]+$/)
  defp only_numeric?(string), do: String.match?(string, ~r/^\d+$/)
  defp only_alphanum?(string), do: String.match?(string, ~r/^[A-Z0-9]+$/)
end
