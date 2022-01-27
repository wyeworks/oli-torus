defmodule OliWeb.EnrollmentsLiveTest do
  use ExUnit.Case
  use OliWeb.ConnCase

  import Phoenix.LiveViewTest
  import Oli.Factory

  defp live_view_index_route(section_slug) do
    Routes.live_path(OliWeb.Endpoint, OliWeb.Sections.EnrollmentsView, section_slug)
  end

  defp create_section(_conn) do
    section = insert(:section, %{type: :enrollable, requires_payment: true})

    [section: section]
  end

  describe "user cannot access when is not logged in" do
    setup [:create_section]

    test "redirects to new session when accessing the index view", %{conn: conn, section: section} do
      redirect_path = "/session/new?request_path=%2Fsections%2F#{section.slug}%2Fenrollments"

      {:error, {:redirect, %{to: ^redirect_path}}} =
        live(conn, live_view_index_route(section.slug))
    end
  end

  describe "index" do
    setup [:admin_conn, :create_section]

    test "loads correctly when there are no enrollments", %{conn: conn, section: section} do
      {:ok, view, _html} = live(conn, live_view_index_route(section.slug))

      assert has_element?(view, "p", "None exist")
    end

    test "loads correctly when there are enrollments payed with nil date", %{
      conn: conn,
      section: section
    } do
      user = insert(:user)
      enrollment = insert(:enrollment, %{section: section, user: user})
      insert(:payment, %{section: section, enrollment: enrollment, application_date: nil})

      {:ok, view, _html} = live(conn, live_view_index_route(section.slug))

      assert view
             |> element("tr:first-child > td:first-child")
             |> render() =~
               "#{user.given_name}"

      assert view
             |> element("tr:first-child > td:last-child")
             |> render() =~
               ""
    end

    test "loads correctly when there are enrollments payed with date - DateTime format", %{
      conn: conn,
      section: section
    } do
      user = insert(:user)
      enrollment = insert(:enrollment, %{section: section, user: user})
      payment = insert(:payment, %{section: section, enrollment: enrollment})

      {:ok, view, _html} = live(conn, live_view_index_route(section.slug))

      assert view
             |> element("tr:first-child > td:first-child")
             |> render() =~
               "#{user.given_name}"

      formatted_date = OliWeb.Common.FormatDateTime.date(payment.application_date, "Etc/UTC")

      assert view
             |> element("tr:first-child > td:last-child")
             |> render() =~
               "#{formatted_date}"
    end

    test "loads correctly when there are enrollments payed with date - NaiveDateTime format", %{
      conn: conn,
      section: section
    } do
      user = insert(:user)
      enrollment = insert(:enrollment, %{section: section, user: user})

      {:ok, application_date} = NaiveDateTime.from_iso8601("2019-05-22 20:30:00Z")

      payment =
        insert(:payment, %{
          section: section,
          enrollment: enrollment,
          application_date: application_date
        })

      {:ok, view, _html} = live(conn, live_view_index_route(section.slug))

      assert view
             |> element("tr:first-child > td:first-child")
             |> render() =~
               "#{user.given_name}"

      formatted_date = OliWeb.Common.FormatDateTime.date(payment.application_date, "Etc/UTC")

      assert view
             |> element("tr:first-child > td:last-child")
             |> render() =~
               "#{formatted_date}"
    end
  end
end
