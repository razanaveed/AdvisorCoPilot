defmodule AdvisorCoPilot.Repo.Migrations.CreateMeetings do
  use Ecto.Migration

  def change do
    create table(:meetings) do
      add :client_name, :string
      add :client_id, :string
      add :status, :string
      add :transcript, :text

      timestamps(type: :utc_datetime)
    end
  end
end
