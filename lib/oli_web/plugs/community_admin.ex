defmodule Oli.Plugs.CommunityAdmin do
  alias Oli.Accounts
  alias OliWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    if Accounts.is_admin?(conn.assigns.current_author) or
         Plug.Conn.get_session(conn, :is_community_admin) do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:info, "You are not allowed to access communities")
      |> Phoenix.Controller.redirect(
        to: Routes.live_path(OliWeb.Endpoint, OliWeb.Projects.ProjectsLive)
      )
      |> Plug.Conn.halt()
    end
  end
end
