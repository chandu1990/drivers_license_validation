defmodule Mix.Tasks.Dl.Validate do
  use Mix.Task
  @shortdoc "Validate a driver's license and optionally check DOB consistency"

  # mix dl.validate FL F850000010600
  # => prints & returns: {:ok, ~D[YYYY-MM-DD]} | {:error, :invalid_format | :invalid_state | :parsing_error | ...}
  def run([state, license]) do
    Mix.Task.run("app.start")

    result =
      case DriversLicenseValidation.valid?(state, license) do
        true  -> DriversLicenseValidation.date_of_birth(state, license)
        false -> {:error, :invalid_format}
        {:error, reason} -> {:error, reason}
      end

    IO.inspect(result)
    result
  end

  # mix dl.validate FL F850000010600 1985-04-16
  # => prints & returns: {:ok, true} | {:error, :dob_mismatch | :invalid_format | :invalid_state | :invalid_dob | ...}
  def run([state, license, dob_iso]) do
    Mix.Task.run("app.start")

    result =
      case DriversLicenseValidation.valid?(state, license) do
        true ->
          case Date.from_iso8601(dob_iso) do
            {:ok, date} ->
              case DriversLicenseValidation.valid_with_dob?(state, license, date) do
                true -> {:ok, true}
                false -> {:error, :dob_mismatch}
                {:error, reason} -> {:error, reason}
              end

            {:error, _} ->
              {:error, :invalid_dob}
          end

        false ->
          {:error, :invalid_format}

        {:error, reason} ->
          {:error, reason}
      end

    IO.inspect(result)
    result
  end
end
