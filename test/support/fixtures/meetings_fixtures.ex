defmodule AdvisorCoPilot.MeetingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AdvisorCoPilot.Meetings` context.
  """

  @doc """
  Generate a meeting.
  """
  def meeting_fixture(attrs \\ %{}) do
    {:ok, meeting} =
      attrs
      |> Enum.into(%{
        client_id: "some client_id",
        client_name: "some client_name",
        status: "prep",
        transcript: "some transcript"
      })
      |> AdvisorCoPilot.Meetings.create_meeting()

    meeting
  end
end
