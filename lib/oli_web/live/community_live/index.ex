defmodule OliWeb.CommunityLive.Index do
  use Surface.LiveView, layout: {OliWeb.LayoutView, "live.html"}
  use OliWeb.Common.SortableTable.TableHandlers

  alias Oli.Groups
  alias OliWeb.Admin.AdminView
  alias OliWeb.Common.{Breadcrumb, Filter, Listing}
  alias OliWeb.CommunityLive.{New, TableModel}
  alias OliWeb.Router.Helpers, as: Routes
  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox, Field, Label}
  alias Surface.Components.Link

  data(title, :string, default: "Communities")
  data(breadcrumbs, :any)

  data(field_filter, :any, default: %{"status" => "active"})
  data(filter, :string, default: "")
  data(total_count, :integer, default: 0)
  data(offset, :integer, default: 0)
  data(limit, :integer, default: 20)
  data(sort, :string, default: "sort")
  data(page_change, :string, default: "page_change")
  data(show_bottom_paging, :boolean, default: false)
  data(additional_table_class, :string, default: "")

  @table_filter_fn &__MODULE__.filter_rows/3
  @table_push_patch_path &__MODULE__.live_path/2

  def filter_rows(socket, filter, field_filter) do
    field_filter =
      Enum.reduce(field_filter, %{}, fn {field, value}, acc ->
        Map.put(acc, field, String.split(value, ","))
      end)

    filter_str = String.downcase(filter)
    status_list = field_filter["status"]

    Enum.filter(socket.assigns.communities, fn c ->
      String.contains?(String.downcase(c.name), filter_str) and
        Enum.member?(status_list, Atom.to_string(c.status))
    end)
  end

  def live_path(socket, params) do
    Routes.live_path(socket, __MODULE__, params)
  end

  def breadcrumb() do
    AdminView.breadcrumb() ++
      [
        Breadcrumb.new(%{
          full_title: "Communities",
          link: Routes.live_path(OliWeb.Endpoint, __MODULE__)
        })
      ]
  end

  def mount(_, _, socket) do
    communities = Groups.list_communities()
    {:ok, table_model} = TableModel.new(communities)

    {:ok,
     assign(socket,
       breadcrumbs: breadcrumb(),
       communities: communities,
       table_model: table_model,
       total_count: length(communities)
     )}
  end

  def render(assigns) do
    ~F"""
      <div class="d-flex p-3 justify-content-between">
        <Filter
          change="change_filter"
          reset="reset_filter"
          apply="apply_filter"
          filter={@filter}/>

        <Link class="btn btn-primary" to={Routes.live_path(@socket, New)}>
          Create Community
        </Link>
      </div>
      <div id="community-filters" class="p-3">
        <Form for={:field_filter} change="apply_field_filter">
          <Field name={:status} class="form-group">
            <Checkbox value={Map.get(@field_filter, "status", "active")} checked_value="active" unchecked_value="active,deleted" class="form-check-input"/>
            <Label class="form-check-label" text="Show only active communities"/>
          </Field>
        </Form>
      </div>

      <div id="communities-table" class="p-4">
        <Listing
          filter={@filter}
          table_model={@table_model}
          total_count={@total_count}
          offset={@offset}
          limit={@limit}
          sort={@sort}
          page_change={@page_change}
          show_bottom_paging={@show_bottom_paging}
          additional_table_class={@additional_table_class}/>
      </div>
    """
  end
end
