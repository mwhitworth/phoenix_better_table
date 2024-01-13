defmodule PhoenixBetterTable do
  @moduledoc """
  A table component whose contents can be sorted by clicking on each header.

  ## Assigns

  * `:meta` - a map containing a `:headers` key:
      * `headers:` - a list of maps, each representing a header in the table:
          * `:id` - the column's id, which will be used as the key for rendering and sorting
          * `:label` - the column's label (optional)
          * `:sort` - either a boolean indicating whether the column is sortable (optional, default true), or a compare/2 function that returns true if the first argument precedes or is in the same place as the second one.
          * `:render` - an optional component that renders cells in the column
  * `:rows` - a list of maps, each representing a row in the table
  * `:sort` - a tuple containing the column id and the sort order (`:asc` or `:desc`) (optional)
  * `:class` - a string containing additional classes to be added to the table (optional)
  """

  use Phoenix.LiveComponent

  import Phoenix.LiveView.TagEngine, only: [component: 3]

  @impl true
  def handle_event(
        "sort",
        %{"header" => header_id},
        %{assigns: %{rows: rows, meta: meta}} = socket
      ) do
    sort_column = String.to_existing_atom(header_id)

    socket =
      update(socket, :sort, fn
        nil -> {sort_column, :asc}
        {^sort_column, :asc} -> {sort_column, :desc}
        {^sort_column, :desc} -> {sort_column, :asc}
        _ -> {sort_column, :asc}
      end)

    {:noreply, assign(socket, :processed_rows, update_rows(rows, socket.assigns.sort, meta))}
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{meta: %{headers: []}}, _socket) do
    raise ArgumentError, "meta.headers must not be empty"
  end

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign_new(:sort, fn -> nil end)
    |> assign_new(:class, fn -> "" end)
    |> then(
      &assign(
        &1,
        :processed_rows,
        update_rows(assigns.rows || socket.assigns.rows, &1.assigns.sort, &1.assigns.meta)
      )
    )
    |> then(&{:ok, &1})
  end

  #

  defp update_rows(rows, nil, _meta) do
    rows
  end

  defp update_rows(rows, {column, order}, %{headers: headers}) do
    sorter = column_sorter(order, Enum.find(headers, &(&1.id == column)))
    Enum.sort_by(rows, &Map.get(&1, column), sorter)
  end

  #

  defp column_sorter(order, %{sort: sort}) when is_function(sort) do
    if order == :asc, do: sort, else: &sort.(&2, &1)
  end

  defp column_sorter(order, %{sort: module}) when is_atom(module) do
    {order, module}
  end

  defp column_sorter(order, _), do: if(order == :asc, do: &<=/2, else: &>=/2)

  defp sort_arrow(nil, _column), do: "—"
  defp sort_arrow({column, order}, column) when order == :asc, do: "▲"
  defp sort_arrow({column, order}, column) when order == :desc, do: "▼"
  defp sort_arrow(_, _), do: "—"
end
