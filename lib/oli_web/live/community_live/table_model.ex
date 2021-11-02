defmodule OliWeb.CommunityLive.TableModel do
  use Surface.LiveComponent

  alias OliWeb.Common.Table.{ColumnSpec, SortableTableModel}
  alias Surface.Components.Link
  alias OliWeb.Router.Helpers, as: Routes

  def new(communities) do
    SortableTableModel.new(
      rows: communities,
      column_specs: [
        %ColumnSpec{
          name: :name,
          label: "Name"
        },
        %ColumnSpec{
          name: :description,
          label: "Description"
        },
        %ColumnSpec{
          name: :key_contact,
          label: "Key Contact"
        },
        %ColumnSpec{
          name: :inserted_at,
          label: "Created",
          render_fn: &SortableTableModel.render_date_column/3
        },
        %ColumnSpec{
          name: :actions,
          label: "Actions",
          render_fn: &__MODULE__.custom_render/3
        }
      ],
      event_suffix: "",
      id_field: [:id]
    )
  end

  def custom_render(assigns, community, %ColumnSpec{name: :actions}) do
    ~F"""
      <Link
        label="Overview"
        to={Routes.live_path(OliWeb.Endpoint, OliWeb.CommunityLive.Show, community.id)}
        class="btn btn-sm btn-primary"/>
    """
  end
end
