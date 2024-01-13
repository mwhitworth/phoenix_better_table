defmodule PhoenixBetterTable.Support.TableHelpers do
  @moduledoc false

  alias __MODULE__, as: TableHelpers

  defmacro assert_table_matches(actual, expected) do
    quote location: :keep do
      actual_table = TableHelpers.parse_actual_table(unquote(actual))
      expected_table = TableHelpers.parse_expected_table(unquote(expected))
      assert actual_table == expected_table
    end
  end

  def parse_actual_table(content) do
    [table] = Floki.parse_document!(content) |> Floki.find("table")

    table
    |> Floki.find("tr")
    |> Enum.map(&parse_table_row/1)
    |> Enum.reject(fn row -> Enum.all?(row, &(&1 == "")) end)
  end

  def parse_table_row(row) do
    Floki.find(row, "th, td") |> Enum.map(&(Floki.text(&1, deep: false) |> String.trim()))
  end

  def parse_expected_table(content) do
    content
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.split(&1, ~r/\s\s+/))
  end
end
