defmodule DriversLicenseValidation.Formats do
  @moduledoc false

  @formats %{

    "AL" => [
      [{:numeric, 1,8}]
    ],
    "AK" => [
      [{:numeric, 1,7}]
    ],
    "AZ" => [
      [{:alpha, 1}, {:numeric, 8}],
      [{:numeric, 9}]
    ],
    "AR" => [
      [{:numeric, 4,9}]
    ],
    "CA" => [
      [{:alpha, 1}, {:numeric, 7}]
    ],
    "CO" => [
      [{:numeric, 9}],
      [{:alpha, 1}, {:numeric, 3}],
      [{:alpha, 2}, {:numeric, 2}]
    ],
    "CT" => [
      [{:numeric, 9}]
    ],
    "DE" => [
      [{:numeric, 1,7}]
    ],
    "DC" => [
      [{:numeric, 7}],
      [{:numeric, 9}]
    ],
    "FL" => [
      [{:alpha, 1}, {:numeric, 12}]
    ],
    "GA" => [
      [{:numeric, 7,9}]
    ],
    "HI" => [
      [{:alpha, 1}, {:numeric, 8}],
      [{:numeric, 9}]
    ],
    "ID" => [
      [{:alpha, 2}, {:numeric, 6}],
      [{:numeric, 9}]
    ],
    "IL" => [
      [{:alpha, 1}, {:numeric, 11}]
    ],
    "IN" => [
      [{:alpha, 1}, {:numeric, 9}],
      [{:numeric, 9,10}]
    ],
    "IA" => [
      [{:numeric, 9}],
      [{:alpha, 3}, {:numeric, 2}]
    ],
    "KS" => [
      [{:alpha, 1}, {:numeric, 1}],
      [{:alpha, 1}, {:numeric, 8}],
      [{:numeric, 9}]
    ],
    "KY" => [
      [{:alpha, 1}, {:numeric, 8}],
      [{:alpha, 1}, {:numeric, 9}],
      [{:numeric, 9}]
    ],
    "LA" => [
      [{:numeric, 1,9}]
    ],
    "ME" => [
      [{:numeric, 7}],
      [{:alpha, 7}, {:numeric, 1}],
      [{:numeric, 8}]
    ],
    "MD" => [
      [{:alpha, 1}, {:numeric, 12}]
    ],
    "MA" => [
      [{:alpha, 1}, {:numeric, 8}],
      [{:numeric, 9}]
    ],
    "MI" => [
      [{:alpha, 1}, {:numeric, 10}],
      [{:alpha, 1}, {:numeric, 12}]
    ],
    "MN" => [
      [{:alpha, 1}, {:numeric, 12}]
    ],
    "MS" => [
      [{:numeric, 9}]
    ],
    "MO" => [
      [{:alpha, 3}, {:numeric, 1}],
      [{:alpha, 1}, {:numeric, 5}],
      [{:alpha, 1}, {:numeric, 6}],
      [{:alpha, 8}, {:numeric, 2}],
      [{:alpha, 9}, {:numeric, 1}],
      [{:numeric, 9}]
    ],
    "MT" => [
      [{:alpha, 3}, {:numeric, 10}],
      [{:alpha, 1}, {:numeric, 8}],
      [{:numeric, 9}],
      [{:numeric, 13,14}]
    ],
    "NE" => [
      [{:alpha, 1}, {:numeric, 6}]
    ],
    "NV" => [
      [{:numeric, 9,10}],
      [{:numeric, 12}],
      [{:numeric, 8}]
    ],
    "NH" => [
      [{:numeric, 2}, {:alpha, 3}, {:numeric, 5}]
    ],
    "NJ" => [
      [{:alpha, 1}, {:numeric, 14}]
    ],
    "NM" => [
      [{:numeric, 8,9}]
    ],
    "NY" => [
      [{:alpha, 1}, {:numeric, 7}],
      [{:alpha, 1}, {:numeric, 18}],
      [{:numeric, 8,9}],
      [{:numeric, 16}],
      [{:alpha, 8}, {:numeric, 0}]
    ],
    "NC" => [
      [{:numeric, 1,12}]
    ],
    "ND" => [
      [{:alpha, 3}, {:numeric, 6}],
      [{:numeric, 9}]
    ],
    "OH" => [
      [{:alpha, 1}, {:numeric, 4}],
      [{:alpha, 2}, {:numeric, 3}],
      [{:numeric, 8}]
    ],
    "OK" => [
      [{:alpha, 1}, {:numeric, 9}],
      [{:numeric, 9}]
    ],
    "OR" => [
      [{:numeric, 1,9}]
    ],
    "PA" => [
      [{:numeric, 8}]
    ],
    "RI" => [
      [{:numeric, 7}],
      [{:alpha, 1}, {:numeric, 6}]
    ],
    "SC" => [
      [{:numeric, 5,11}]
    ],
    "SD" => [
      [{:numeric, 6,10}],
      [{:numeric, 12}]
    ],
    "TN" => [
      [{:numeric, 7,9}]
    ],
    "TX" => [
      [{:numeric, 7,8}]
    ],
    "UT" => [
      [{:numeric, 4,10}]
    ],
    "VT" => [
      [{:numeric, 8}],
      [{:numeric, 7}]
    ],
    "VA" => [
      [{:alpha, 1}, {:numeric, 8}],
      [{:numeric, 9}]
    ],
    "WA" => [
      [{:alpha, 1, 7}, {:any, 5, 11}]
    ],
    "WV" => [
      [{:numeric, 7}],
      [{:alpha, 1}, {:numeric, 2}]
    ],
    "WI" => [
      [{:alpha, 1}, {:numeric, 13}]
    ],
    "WY" => [
      [{:numeric, 9,10}]
    ],
  }


  def get(state), do: Map.get(@formats, String.upcase(state))
end
