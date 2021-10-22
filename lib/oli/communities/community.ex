defmodule Oli.Communities.Community do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oli.Repo

  schema "communities" do
    field :name, :string
    field :description, :string
    field :key_contact, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(community, attrs \\ %{}) do
    community
    |> cast(attrs, [:name, :description, :key_contact])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def list_communities, do: Repo.all(__MODULE__)

  def create_community(attrs \\ %{}) do
    %__MODULE__{}
    |> __MODULE__.changeset(attrs)
    |> Repo.insert()
  end
end
