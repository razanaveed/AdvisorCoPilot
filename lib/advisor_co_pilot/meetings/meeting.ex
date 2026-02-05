defmodule AdvisorCoPilot.Meetings.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(prep live completed)

  schema "meetings" do
    field :client_name, :string
    field :client_id, :string
    field :status, :string
    field :transcript, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meeting, attrs) do
    meeting
    |> cast(attrs, [:client_name, :client_id, :status, :transcript])
    |> validate_required([:client_name, :client_id, :status])
    |> validate_inclusion(:status, @statuses)
  end
end
