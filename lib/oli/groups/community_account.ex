defmodule Oli.Groups.CommunityAccount do
  use Ecto.Schema
  import Ecto.Changeset

  schema "community_accounts" do
    belongs_to :community, Oli.Groups.Community
    belongs_to :author, Oli.Accounts.Author
    belongs_to :user, Oli.Accounts.User
    field :is_admin, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(community, attrs \\ %{}) do
    community
    |> cast(attrs, [:community_id, :author_id, :user_id, :is_admin])
    |> validate_required([:community_id])
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:author_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:community_id, :author_id], name: :index_community_author)
    |> unique_constraint([:community_id, :user_id], name: :index_community_user)
  end
end
