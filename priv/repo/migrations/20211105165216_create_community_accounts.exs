defmodule Oli.Repo.Migrations.CreateCommunityAccounts do
  use Ecto.Migration

  def change do
    create table(:community_accounts) do
      add :community_id, references(:communities)
      add :author_id, references(:authors)
      add :user_id, references(:users)
      add :is_admin, :boolean, default: false, null: false

      timestamps(type: :timestamptz)
    end

    create unique_index(:community_accounts, [:community_id, :author_id], name: :index_community_author)
    create unique_index(:community_accounts, [:community_id, :user_id], name: :index_community_user)
  end
end
