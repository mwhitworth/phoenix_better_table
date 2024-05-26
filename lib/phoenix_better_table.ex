defmodule PhoenixBetterTable do
  @moduledoc """
  A table component whose contents can be sorted by clicking on each header.

  ## Assigns

  * `:meta` - a map containing a `:headers` key:
      * `headers:` - a list of maps, each representing a header in the table:
          * `:id` - the column's id, which will be used as the key for rendering and sorting
          * `:label` - the column's label (optional)
          * `:filter` - a boolean indicating whether the column is filterable (optional, default true), or a 1-arity function that returns text to be filtered (default `to_string/1`)
          * `:sort` - either a boolean indicating whether the column is sortable (optional, default true), or a compare/2 function that returns true if the first argument precedes or is in the same place as the second one.
          * `:render` - an optional component that renders cells in the column
  * `:rows` - a list of maps, each representing a row in the table
  * `:sort` - a tuple containing the column id and the sort order (`:asc` or `:desc`) (optional)
  * `:class` - a string containing additional classes to be added to the table (optional)
  * `:body_class` - a string containing additional classes to be added to the table body (optional)
  * `:header_class` - a string containing additional classes to be added to the table header (optional)

  ## Slots

  * `:filter_control` - an optional slot that takes a single argument, a tuple of `{active?, id, myself}`. The interactive element should
  set `phx-click="filter_toggle"`, `phx-value-header={id}`, and `phx-target={myself}` for the event to be routed correctly.
  """

  use Phoenix.LiveComponent

  @impl true
  def handle_event(
        "sort",
        %{"header" => header_id},
        socket
      ) do
    sort_column = String.to_existing_atom(header_id)

    socket =
      update(socket, :sort, fn
        nil -> {sort_column, :asc}
        {^sort_column, :asc} -> {sort_column, :desc}
        {^sort_column, :desc} -> {sort_column, :asc}
        _ -> {sort_column, :asc}
      end)

    {:noreply, process_rows(socket)}
  end

  def handle_event(
        "filter_toggle",
        %{"header" => header_id},
        socket
      ) do
    filter_column = String.to_existing_atom(header_id)

    socket =
      update(socket, :filter, fn
        %{^filter_column => _} -> Map.delete(socket.assigns.filter, filter_column)
        _ -> Map.put(socket.assigns.filter, filter_column, "")
      end)

    {:noreply, process_rows(socket)}
  end

  def handle_event(
        "filter_change",
        %{"header" => header_id, "value" => value},
        socket
      ) do
    filter_column = String.to_existing_atom(header_id)

    socket =
      update(socket, :filter, fn
        state -> Map.put(state, filter_column, value)
      end)

    {:noreply, process_rows(socket)}
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
    |> assign_new(:engine_module, fn -> engine_module() end)
    |> assign_new(:sort, fn -> nil end)
    |> assign_new(:filter, fn -> %{} end)
    |> assign_new(:filter_control, fn -> nil end)
    |> assign_new(:class, fn -> "" end)
    |> assign_new(:body_class, fn -> "" end)
    |> assign_new(:header_class, fn -> "" end)
    |> process_rows()
    |> then(&{:ok, &1})
  end

  #

  defp process_rows(%{assigns: %{rows: rows}} = socket) when is_list(rows) do
    assign(socket, :processed_rows, rows |> filter_rows(socket) |> sort_rows(socket))
  end

  defp filter_rows(rows, %{assigns: %{filter: nil}}) do
    rows
  end

  defp filter_rows(rows, %{assigns: %{filter: filter, meta: %{headers: headers}}}) do
    processed_filters =
      Enum.map(filter, fn {column, value} ->
        {column, value |> String.trim() |> String.downcase()}
      end)

    Enum.filter(rows, fn row ->
      Enum.all?(processed_filters, fn {column, value} ->
        filter_func = column_filter(Enum.find(headers, &(&1.id == column)))

        String.contains?(
          Map.get(row, column) |> filter_func.() |> String.downcase(),
          value
        )
      end)
    end)
  end

  defp sort_rows(rows, %{assigns: %{sort: {column, order}, meta: %{headers: headers}}}) do
    sorter = column_sorter(order, Enum.find(headers, &(&1.id == column)))
    Enum.sort_by(rows, &Map.get(&1, column), sorter)
  end

  defp sort_rows(rows, _socket) do
    rows
  end

  #

  defp column_sorter(order, %{sort: sort}) when is_function(sort) do
    if order == :asc, do: sort, else: &sort.(&2, &1)
  end

  defp column_sorter(order, %{sort: module}) when is_atom(module) do
    {order, module}
  end

  defp column_sorter(order, _), do: if(order == :asc, do: &<=/2, else: &>=/2)

  defp column_filter(%{filter: filter}) when is_function(filter, 1) do
    filter
  end

  defp column_filter(_), do: &to_string/1

  defp sort_arrow(nil, _column), do: "—"
  defp sort_arrow({column, order}, column) when order == :asc, do: "▲"
  defp sort_arrow({column, order}, column) when order == :desc, do: "▼"
  defp sort_arrow(_, _), do: "—"

  attr(:active?, :boolean, required: true)
  attr(:rest, :global)

  defp filter_control(assigns) do
    ~H"""
      <a style={if @active?, do: "color: #000000", else: "color: #808080"}  href="#" {@rest}>
        ⫧
      </a>
    """
  end

  defp engine_module do
    if Kernel.function_exported?(Phoenix.LiveView.TagEngine, :component, 3) do
      # After LiveView 0.18.18
      Phoenix.LiveView.TagEngine
    else
      Phoenix.LiveView.HTMLEngine
    end
  end
end
