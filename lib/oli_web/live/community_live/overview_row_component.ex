defmodule OliWeb.CommunityLive.OverviewRowComponent do
  use Surface.Component

  prop title, :string, required: true
  prop message, :string, default: ""

  slot default, required: true

  def render(assigns) do
    ~F"""
      <div class="row py-5 border-bottom">
        <div class="col-md-4">
          <h4>{@title}</h4>
          <div class="text-muted">{@message}</div>
        </div>
        <div class="col-md-8">
          <#slot />
        </div>
      </div>
    """
  end
end
