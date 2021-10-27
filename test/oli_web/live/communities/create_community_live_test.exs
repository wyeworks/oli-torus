defmodule OliWeb.Communities.CreateCommunityLiveTest do
  use ExUnit.Case
  use OliWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Oli.Communities.Community

  @liveview_route Routes.live_path(OliWeb.Endpoint, OliWeb.Communities.CreateCommunityLive)

  describe "user cannot access when is not logged in" do
    test "redirects to new session", %{conn: conn} do
      {:error,
        {:redirect,
        %{to: "/authoring/session/new?request_path=%2Fadmin%2Fcommunities%2Fnew"}}} = live(conn, @liveview_route)
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

    test "loads correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, @liveview_route)

      assert has_element?(view, "h5", "New Community")
      assert has_element?(view, "form[phx-submit=\"save\"")
    end

    test "displays error message when data is invalid", %{conn: conn} do
      {:ok, view, _html} = live(conn, @liveview_route)

      view
      |> element("form[phx-submit=\"save\"")
      |> render_submit(%{community: %{name: ""}})

      assert view
        |> element("div.alert.alert-danger")
        |> render()
        =~ "Community couldn&#39;t be created. Please check the errors below."
      assert has_element?(view, "span", "can't be blank")

      assert [] = Community.list_communities()
    end

    test "creates a community correctly when data is valid", %{conn: conn} do
      {:ok, view, _html} = live(conn, @liveview_route)

      view
      |> element("form[phx-submit=\"save\"")
      |> render_submit(%{community: %{
        name: "Testing name",
        description: "Testing description",
        key_contact: "Testing key contact"}})

      assert view
        |> element("div.alert.alert-info")
        |> render()
        =~ "Community succesfully created."

      assert [%Community{
        name: "Testing name",
        description: "Testing description",
        key_contact: "Testing key contact"} | _tail]
          = Community.list_communities()
    end
  end
end
