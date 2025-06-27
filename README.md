# DriversLicenseValidation

# Driver's License Validation & DOB Extraction for US States

An Elixir library to validate U.S. driver's license formats and extract date-of-birth (DOB) information where applicable. Supports strict validation and gender-aware DOB encoding logic for FL, WI, IL, and others.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `drivers_license_validation` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:drivers_license_validation, "~> 0.1.0"}
  ]
end
```

---

## 🚀 Features

* Format validation for all U.S. states
* DOB extraction for states that encode DOBs
* Gender-aware DOY decoding for FL, WI, IL
* Contextual validation for WA, NH, ND (uses name info)
* Utility helpers for 2-digit year conversion
* CLI support via custom Mix tasks

---

## 📦 Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:drivers_license_validation, github: "your_github/drivers_license_validation"}
  ]
end
```

---

## ✅ Usage Examples

### Validate Format Only:

```elixir
DriversLicenseValidation.valid?("FL", "F850000010600")
# => true
```

### Extract DOB:

```elixir
DriversLicenseValidation.date_of_birth("FL", "F850000010600")
# => ~D[1985-04-16]
```

### Validate Format + DOB Match:

```elixir
DriversLicenseValidation.valid_with_dob?("FL", "F850000010600", ~D[1985-04-16])
# => true
```

### With Context (WA, NH, ND):

```elixir
DriversLicenseValidation.valid_with_dob?("WA", "SMITHJ801BC", ~D[1980-01-03], first_name: "John", last_name: "Smith")
```

---

## 📟 CLI Usage

```elixir
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
```

Run from terminal:

```sh
mix dl.validate FL F850000010600
mix dl.validate FL F850000010600 1985-04-16
```

---

## 🗂️ DOB Supported States

| State | Encodes DOB? | Notes                              |
| ----- | ------------ | ---------------------------------- |
| CT    | ✅            | Month code logic                   |
| FL    | ✅            | YY + DOY with gender encoding      |
| IL    | ✅            | YY + DOY, alt formats supported    |
| MD    | ✅            | Month/Day from 3-digit code        |
| MI    | ✅            | Same as MD                         |
| MT    | ✅            | Full DOB encoded in fixed segments |
| NH    | ✅            | Full match on encoded string       |
| NJ    | ✅            | Month and year encoded             |
| ND    | ✅            | Last name prefix + 2-digit year    |
| WA    | ✅            | Name + encoded chars for date      |
| WI    | ✅            | Same logic as FL                   |

---

## 🔐 Gender Encoding Rules

| Encoding  | Meaning                    |
| --------- | -------------------------- |
| DOY ≤ 500 | Male DOB                   |
| DOY > 500 | Female DOB  (subtract 500) |

---

## 🔧 Format DSL

License formats are defined like:

```elixir
"FL" => [
  [{:alpha, 1}, {:numeric, 12}]
]
```

Pattern Types:

* `{:alpha, 1}` → 1 letter
* `{:numeric, 2}` → 2 digits
* `{:any, 5, 10}` → 5–10 alphanum chars
* `{:literal, "X"}` → exact match

---

## 🧪 Testing Tips

* Use `valid?/2` to validate structure
* Use `valid_with_dob?/3` or `/4` to confirm full match

---

## 📄 License

MIT. See LICENSE file.

---

## 🙌 Contributing

Contributions welcome. Please open issues or PRs with enhancements, bug reports, or state additions.


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/drivers_license_validation>.

