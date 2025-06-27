defmodule Mix.Tasks.Dl.Validate do
  use Mix.Task

  @shortdoc "Validate a driver's license and optionally DOB"
  def run([state, license]) do
    Mix.Task.run("app.start")
    IO.puts("Format valid?: #{DriversLicenseValidation.valid?(state, license)}")
    IO.puts("DOB extracted: #{DriversLicenseValidation.date_of_birth(state, license)}")
  end

  def run([state, license, dob]) do
    Mix.Task.run("app.start")
    {:ok, date} = Date.from_iso8601(dob)
    IO.puts("Valid with DOB?: #{DriversLicenseValidation.valid_with_dob?(state, license, date)}")
  end
end