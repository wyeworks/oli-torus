defmodule OliWeb.OpenAndFreeView do
  use OliWeb, :view

  alias OliWeb.Common.Utils

  def index_path(:admin), do: Routes.admin_open_and_free_path(OliWeb.Endpoint, :index)

  def index_path(:independent_learner),
    do: ~p"/sections"

  def get_path([:admin | rest]),
    do: apply(Routes, :admin_open_and_free_path, [OliWeb.Endpoint | rest])

  def get_path([:independent_learner | rest]),
    do: apply(Routes, :independent_sections_path, [OliWeb.Endpoint | rest])
end
