defmodule OliWeb.WorkspaceController do
  use OliWeb, :controller
  alias Oli.Authoring.Course.Project
  alias Oli.Repo
  alias Oli.Accounts

  def projects(%{:assigns => %{:current_author => current_author}} = conn, params) do
    current_author = Repo.preload(current_author, [:projects])
    projects = current_author.projects
      |> Enum.map(fn project ->
        Map.put(project, :author_count, Accounts.project_author_count(project)) end)
    params = %{
      title: "Projects",
      active: :projects,
      changeset: Project.changeset(%Project{
        title: params["project_title"] || ""
      }),
      author: current_author,
      projects: projects
    }
    render %{conn | assigns: (Map.merge(conn.assigns, params) |> Map.put(:page_title, "Projects - "))}, "projects.html"
  end

  def account(conn, _params) do
    institutions = Accounts.list_institutions() |> Enum.filter(fn i -> i.author_id == conn.assigns.current_author.id end)
    render conn, "account.html", title: "Account", active: :account, institutions: institutions, page_title: "Account - "
  end
end
