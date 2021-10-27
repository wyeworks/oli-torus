defmodule OliWeb.Communities.CommunityLiveTest do
  use ExUnit.Case
  use OliWeb.ConnCase

  import Phoenix.LiveViewTest
  import Oli.Factory

  alias Oli.Communities.Community

  @liveview_route_preffix "/admin/communities/"
  @form_fields [:name, :description, :key_contact]

  setup do
    community = insert(:community)

    {:ok, [community: community]}
  end

  describe "user cannot access when is not logged in" do
    test "redirects to new session", %{conn: conn, community: %Community{id: id}} do
      expected_path = "/authoring/session/new?request_path=%2Fadmin%2Fcommunities%2F#{id}"

      {:error,
        {
          :redirect,
          %{to: ^expected_path}
        }
      } = live(conn, @liveview_route_preffix <> "#{id}")
    end
  end

  describe "user cannot access when is logged in and is not an admin" do
    setup [:author_conn]

    test "returns forbidden", %{conn: conn, community: %Community{id: id}} do
      conn = get(conn, @liveview_route_preffix <> "#{id}")

      assert response(conn, 403)
    end
  end

  describe "user can access when is logged in as an admin" do
    setup [:admin_conn]

    test "loads correctly with community data", %{conn: conn, community: community} do
      {:ok, view, _html} = live(conn, @liveview_route_preffix <> "#{community.id}")

      assert has_element?(view, "#community-overview")

      community
      |> Map.take(@form_fields)
      |> Enum.each(fn {field, value} ->
        assert view
        |> element("#community_#{field}")
        |> render()
        =~ value
      end)
    end

    test "displays error message when data is invalid", %{conn: conn, community: %Community{id: id}} do
      {:ok, view, _html} = live(conn, @liveview_route_preffix <> "#{id}")

      view
      |> element("form[phx-submit=\"save\"")
      |> render_submit(%{community: %{name: ""}})

      assert view
        |> element("div.alert.alert-danger")
        |> render()
        =~ "Community couldn&#39;t be updated. Please check the errors below."
      assert has_element?(view, "span", "can't be blank")

      refute Community.find(id).name == ""
    end

    test "updates a community correctly when data is valid", %{conn: conn, community: %Community{id: id}} do
      {:ok, view, _html} = live(conn, @liveview_route_preffix <> "#{id}")

      new_attributes =
        build(:community)
        |> Map.from_struct()
        |> Map.take(@form_fields)

      view
      |> element("form[phx-submit=\"save\"")
      |> render_submit(%{community: new_attributes})

      assert view
        |> element("div.alert.alert-info")
        |> render()
        =~ "Community successfully updated."

      updated_community =
        Community.find(id)
        |> Map.from_struct()
        |> Map.take(@form_fields)

      assert new_attributes == updated_community
    end
  end
end
