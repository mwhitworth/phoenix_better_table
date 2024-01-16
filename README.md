# PhoenixBetterTable

PhoenixBetterTable is a Phoenix Live Component that presents a filterable and sortable table component given table metadata and rows.

## Why?

It is designed to fill the space between `<table>` and fully featured data tables backed by Ecto, such as those in [flop_phoenix](https://hex.pm/packages/flop_phoenix).

## Features

- (optionally) sortable columns
- (optionally) filterable columns
- custom render functions for each column

## Usage

```elixir
<.live_component
    id="123"
    module={PhoenixBetterTable}
    rows={[%{string: "Hello", number: 123}, %{string: "World", number: 456}]}
    meta={%{headers: [%{id: :string, display_name: "String column", sort: false}, %{id: :number}]}} />
```

produces a table with two columns ("Hello" and "World"), one sortable column ("World), and filtering by column contents:

<img align="center" src="./static/phoenix-better-table.gif" alt="PhoenixBetterTable example">

## Installation

The package can be installed by adding `phoenix_better_table` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_better_table, "~> 0.4.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/phoenix_better_table>.
