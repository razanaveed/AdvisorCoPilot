defmodule AdvisorCoPilot.MeetingsTest do
  use AdvisorCoPilot.DataCase

  alias AdvisorCoPilot.Meetings

  describe "meetings" do
    alias AdvisorCoPilot.Meetings.Meeting

    import AdvisorCoPilot.MeetingsFixtures

    @invalid_attrs %{status: nil, client_name: nil, client_id: nil, transcript: nil}

    test "list_meetings/0 returns all meetings" do
      meeting = meeting_fixture()
      assert Meetings.list_meetings() == [meeting]
    end

    test "get_meeting!/1 returns the meeting with given id" do
      meeting = meeting_fixture()
      assert Meetings.get_meeting!(meeting.id) == meeting
    end

    test "create_meeting/1 with valid data creates a meeting" do
      valid_attrs = %{
        status: "prep",
        client_name: "some client_name",
        client_id: "some client_id",
        transcript: "some transcript"
      }

      assert {:ok, %Meeting{} = meeting} = Meetings.create_meeting(valid_attrs)
      assert meeting.status == "prep"
      assert meeting.client_name == "some client_name"
      assert meeting.client_id == "some client_id"
      assert meeting.transcript == "some transcript"
    end

    test "create_meeting/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Meetings.create_meeting(@invalid_attrs)
    end

    test "update_meeting/2 with valid data updates the meeting" do
      meeting = meeting_fixture()
      update_attrs = %{
        status: "completed",
        client_name: "some updated client_name",
        client_id: "some updated client_id",
        transcript: "some updated transcript"
      }

      assert {:ok, %Meeting{} = meeting} = Meetings.update_meeting(meeting, update_attrs)
      assert meeting.status == "completed"
      assert meeting.client_name == "some updated client_name"
      assert meeting.client_id == "some updated client_id"
      assert meeting.transcript == "some updated transcript"
    end

    test "update_meeting/2 with invalid data returns error changeset" do
      meeting = meeting_fixture()
      assert {:error, %Ecto.Changeset{}} = Meetings.update_meeting(meeting, @invalid_attrs)
      assert meeting == Meetings.get_meeting!(meeting.id)
    end

    test "delete_meeting/1 deletes the meeting" do
      meeting = meeting_fixture()
      assert {:ok, %Meeting{}} = Meetings.delete_meeting(meeting)
      assert_raise Ecto.NoResultsError, fn -> Meetings.get_meeting!(meeting.id) end
    end

    test "change_meeting/1 returns a meeting changeset" do
      meeting = meeting_fixture()
      assert %Ecto.Changeset{} = Meetings.change_meeting(meeting)
    end
  end
end
