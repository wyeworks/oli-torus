defmodule Oli.Repo.Migrations.UpdateSectionsTableOmitStudentsEmailVerification do
  use Ecto.Migration

  def change do
    alter table(:sections) do
      add :omit_students_email_verification, :boolean, default: false, null: false
    end
  end
end
