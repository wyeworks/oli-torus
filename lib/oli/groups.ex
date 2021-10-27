defmodule Oli.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false
  alias Oli.Repo

  alias Oli.Groups.Community

  @doc """
  Returns the list of communities.

  ## Examples

      iex> list_communities()
      [%Community{}, ...]

  """
  def list_communities, do: Repo.all(Community)

  @doc """
  Creates a community.

  ## Examples

      iex> create_community(%{field: new_value})
      {:ok, %Community{}}

      iex> create_community(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_community(attrs \\ %{}) do
    %Community{}
    |> Community.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Finds a community by id.

  ## Examples

      iex> find(1)
      %Community{}
      iex> find(123)
      nil
  """
  def find(id), do: Repo.get(__MODULE__, id)

  @doc """
  Updates a community.

  ## Examples

      iex> update(community, %{name: new_value})
      {:ok, %Community{}}
      iex> update(community, %{name: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def update(%__MODULE__{} = community, attrs) do
    community
    |> changeset(attrs)
    |> Repo.update()
  end
end
