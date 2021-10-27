defmodule OliWeb.CommunityLive.New do
  use Surface.LiveView, layout: {OliWeb.LayoutView, "live.html"}

  alias Oli.Groups
  alias Oli.Groups.Community
  alias OliWeb.Common.{Breadcrumb, FormContainerComponent}
  alias OliWeb.Communities.Form
  alias OliWeb.CommunityLive.Index
  alias OliWeb.Router.Helpers, as: Routes

  data(title, :string, default: "New Community")
  data(community, :changeset, default: Community.changeset(%Community{}))
  data(breadcrumbs, :list)

  def breadcrumb() do
    Index.breadcrumb() ++
      [
        Breadcrumb.new(%{
          full_title: "New",
          link: Routes.live_path(OliWeb.Endpoint, __MODULE__)
        })
      ]
  end

  def mount(_, _, socket) do
    {:ok,
     assign(socket,
       breadcrumbs: breadcrumb()
     )}
  end

  def render(assigns) do
    ~F"""
      <FormContainer title={@title}>
        <Form changeset={@community} display_labels={false}/>
      </FormContainer>
    """
  end

  def handle_event("save", %{"community" => params}, socket) do
    case Groups.create_community(params) do
      {:ok, _community} ->
        socket = put_flash(socket, :info, "Community succesfully created.")
        {:noreply, assign(socket, community: Community.changeset(%Community{}))}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket =
          put_flash(
            socket,
            :error,
            "Community couldn't be created. Please check the errors below."
          )

        {:noreply, assign(socket, community: changeset)}
    end
  end
end
