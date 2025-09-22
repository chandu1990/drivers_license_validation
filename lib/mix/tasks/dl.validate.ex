defmodule Mix.Tasks.Dl.Validate do
  use Mix.Task
  @shortdoc "Validate a driver's license and optionally check DOB consistency"

  # mix dl.validate FL F850000010600
  # => prints & returns: {:ok, ~D[YYYY-MM-DD]} | {:error, :invalid_format | :invalid_state | :parsing_error | ...}
  def run([state, license]) do
    Mix.Task.run("app.start")

    result =
      case DriversLicenseValidation.valid?(state, license) do
        true -> DriversLicenseValidation.date_of_birth(state, license)
        false -> {:error, :invalid_format}
        {:error, reason} -> {:error, reason}
      end

    IO.inspect(result)
    result
  end
end
