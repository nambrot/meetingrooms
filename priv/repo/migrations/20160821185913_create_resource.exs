defmodule PhoenixGuardian.Repo.Migrations.CreateResource do
  use Ecto.Migration

  def change do
    create table(:resources) do
      add :gid, :string
      add :summary, :string
      add :description, :string

      timestamps
    end

  end
end
