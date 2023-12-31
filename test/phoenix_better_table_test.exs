defmodule PhoenixBetterTableTest do
  defmodule TestEndpoint do
    use Phoenix.Endpoint, otp_app: :phoenix_better_table

    defoverridable config: 1, config: 2

    def config(:live_view), do: [signing_salt: "112345678212345678312345678412"]
    def config(:secret_key_base), do: String.duplicate("57689", 50)
    def config(which), do: super(which)
    def config(which, default), do: super(which, default)
  end

  @endpoint PhoenixBetterTableTest.TestEndpoint

  use ExUnit.Case, async: true

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest
  import LiveIsolatedComponent
  import PhoenixBetterTable.Support.TableHelpers, only: [assert_table_matches: 2]

  setup do
    start_supervised!(PhoenixBetterTableTest.TestEndpoint)
    :ok
  end

  test "errors when meta.headers is empty" do
    assert_raise ArgumentError, fn ->
      live_isolated_component(PhoenixBetterTable, %{
        meta: %{headers: []},
        rows: [%{name: "John", age: 30}, %{name: "Jane", age: 25}]
      })
    end
  end

  test "renders basic table with headers" do
    {:ok, _view, html} =
      live_isolated_component(PhoenixBetterTable, %{
        meta: %{headers: [%{id: :name}, %{id: :age}]},
        rows: [%{name: "John", age: 30}, %{name: "Jane", age: 25}]
      })

    assert_table_matches(html, """
    name   age
    John   30
    Jane   25
    """)
  end

  test "renders a label for a header, if supplied" do
    {:ok, _view, html} =
      live_isolated_component(PhoenixBetterTable, %{
        meta: %{headers: [%{id: :name, label: "Real Name"}, %{id: :age}]},
        rows: [%{name: "John", age: 30}, %{name: "Jane", age: 25}]
      })

    assert_table_matches(html, """
    Real Name    age
    John         30
    Jane         25
    """)
  end

  test "disables sorting if header sort is false" do
    {:ok, _view, html} =
      live_isolated_component(PhoenixBetterTable, %{
        meta: %{headers: [%{id: :name, sort: false}, %{id: :age, sort: false}]},
        rows: [%{name: "John", age: 30}, %{name: "Jane", age: 25}]
      })

    assert [] == Floki.parse_document!(html) |> Floki.find("a[phx-click='sort']")
  end

  test "for a single column, sorts table ascending, then descending, then back to ascending" do
    {:ok, view, _html} =
      live_isolated_component(PhoenixBetterTable, %{
        meta: %{headers: [%{id: :name}, %{id: :age, sort: false}]},
        rows: [%{name: "John", age: 30}, %{name: "Jane", age: 25}]
      })

    # Sort ascending
    html = view |> element("a[phx-click='sort']") |> render_click()

    assert_table_matches(html, """
    name         age
    Jane         25
    John         30
    """)

    # Sort descending
    html = view |> element("a[phx-click='sort']") |> render_click()

    assert_table_matches(html, """
    name         age
    John         30
    Jane         25
    """)

    # Sort ascending again
    html = view |> element("a[phx-click='sort']") |> render_click()

    assert_table_matches(html, """
    name         age
    Jane         25
    John         30
    """)
  end

  test "reprocesses rows if assign is changed" do
    {:ok, view, _html} =
      live_isolated_component(PhoenixBetterTable, %{
        meta: %{headers: [%{id: :name}, %{id: :age, sort: false}]},
        rows: [%{name: "John", age: 30}, %{name: "Jane", age: 25}]
      })

    view |> element("a[phx-click='sort']") |> render_click()

    live_assign(view, :rows, [
      %{name: "John", age: 30},
      %{name: "Jane", age: 25},
      %{name: "Bob", age: 40}
    ])

    html = render(view)

    assert_table_matches(html, """
    name         age
    Bob          40
    Jane         25
    John         30
    """)
  end

  test "renders cell using a function component, if :render is supplied for a column" do
    {:ok, _view, html} =
      live_isolated_component(PhoenixBetterTable, %{
        meta: %{
          headers: [
            %{
              id: :name,
              render: fn assigns ->
                ~H"""
                <%= String.reverse(@value) %>
                """
              end
            }
          ]
        },
        rows: [%{name: "John"}, %{name: "Jane"}]
      })

    assert_table_matches(html, """
    name
    nhoJ
    enaJ
    """)
  end
end
