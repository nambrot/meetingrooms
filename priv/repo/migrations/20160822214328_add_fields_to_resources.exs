defmodule PhoenixGuardian.Repo.Migrations.AddFieldsToResources do
  use Ecto.Migration

  def change do
    alter table(:resources) do
      add :user_id, references(:users)
    end
  end
end
