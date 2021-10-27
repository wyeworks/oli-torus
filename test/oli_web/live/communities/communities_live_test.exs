defmodule OliWeb.Communities.CommunitiesLiveTest do
  use ExUnit.Case
  use OliWeb.ConnCase

  import Phoenix.LiveViewTest
  import Oli.Factory

  @liveview_route "/admin/communities"

  describe "user cannot access when is not logged in" do
    test "redirects to new session", %{conn: conn} do
      {:error,
        {:redirect,
        %{to: "/authoring/session/new?request_path=%2Fadmin%2Fcommunities"}}} = live(conn, @liveview_route)
    end
  end

  describe "user cannot access when is logged in and is not an admin" do
    setup [:author_conn]

    test "returns forbidden", %{conn: conn} do
      conn = get(conn, @liveview_route)

      assert response(conn, 403)
    end
  end

  describe "user can access when is logged in as an admin" do
    setup [:admin_conn]

    test "loads correctly when there are no communities", %{conn: conn} do
      {:ok, view, _html} = live(conn, @liveview_route)

      assert has_element?(view, "#communities-table")
      assert has_element?(view, "p", "None exist")
      assert has_element?(view, "a[href=\"#{@liveview_route}/new\"]")
    end

    test "loads the communities correctly", %{conn: conn} do
      c1 = insert(:community)
      c2 = insert(:community)

      {:ok, view, _html} = live(conn, @liveview_route)

      assert has_element?(view, "#communities-table")
      assert has_element?(view, "##{c1.id}")
      assert has_element?(view, "##{c2.id}")
    end

    test "can apply filtering", %{conn: conn} do
      c1 = insert(:community, %{name: "Testing"})
      c2 = insert(:community)

      {:ok, view, _html} = live(conn, @liveview_route)

      view
      |> element("input[phx-blur=\"change_filter\"]")
      |> render_blur(%{value: "testing"})

      view
      |> element("button[phx-click=\"apply_filter\"]")
      |> render_click()

      assert has_element?(view, "##{c1.id}")
      refute has_element?(view, "##{c2.id}")

      view
      |> element("button[phx-click=\"reset_filter\"]")
      |> render_click()

      assert has_element?(view, "##{c1.id}")
      assert has_element?(view, "##{c2.id}")
    end

    test "can apply sorting", %{conn: conn} do
      insert(:community, %{name: "Testing A"})
      insert(:community, %{name: "Testing B"})

      {:ok, view, _html} = live(conn, @liveview_route)

      assert view
        |> element("tr:first-child > td:first-child")
        |> render()
        =~ "Testing A"

      view
      |> element("th[phx-click=\"sort\"]:first-of-type")
      |> render_click(%{sort_by: "name"})

      assert view
        |> element("tr:first-child > td:first-child")
        |> render()
        =~ "Testing B"
    end

    test "can apply paging", %{conn: conn} do
      [first_c | tail] = insert_list(21, :community) |> Enum.sort_by(& &1.name)
      last_c = List.last(tail)

      conn = get(conn, @liveview_route)
      {:ok, view, _html} = live(conn)

      assert has_element?(view, "##{first_c.id}")
      refute has_element?(view, "##{last_c.id}")

      view
      |> element("a[phx-click=\"page_change\"]", "2")
      |> render_click()

      refute has_element?(view, "##{first_c.id}")
      assert has_element?(view, "##{last_c.id}")
    end
  end
end
