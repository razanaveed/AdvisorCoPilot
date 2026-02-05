defmodule AdvisorCoPilot.Meetings do
  @moduledoc """
  The Meetings context.
  """

  import Ecto.Query, warn: false
  alias AdvisorCoPilot.Repo

  alias AdvisorCoPilot.Meetings.Meeting

  @type crm_note :: %{
          required(:id) => integer(),
          required(:occurred_at) => NaiveDateTime.t(),
          required(:summary) => String.t()
        }

  @doc """
  Returns the list of meetings.

  ## Examples

      iex> list_meetings()
      [%Meeting{}, ...]

  """
  def list_meetings do
    Repo.all(Meeting)
  end

  @doc """
  Appends a line of transcript text to a meeting, storing it in the database.

  This keeps the `transcript` field as a simple newline-separated log
  that can later be summarised by the intelligence layer.

  Accepts either a `%Meeting{}` struct or a meeting ID.
  """
  @spec append_transcript_line(Meeting.t() | integer() | binary(), String.t()) ::
          {:ok, Meeting.t()} | {:error, term()}
  def append_transcript_line(%Meeting{} = meeting, line) when is_binary(line) do
    existing =
      meeting.transcript
      |> case do
        nil -> ""
        other -> other
      end

    new_transcript =
      [existing, String.trim(line)]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n")

    update_meeting(meeting, %{transcript: new_transcript})
  end

  def append_transcript_line(id, line) when (is_integer(id) or is_binary(id)) and is_binary(line) do
    case Repo.get(Meeting, id) do
      nil ->
        {:error, :not_found}

      %Meeting{} = meeting ->
        append_transcript_line(meeting, line)
    end
  end

  @doc """
  Returns three mock CRM meeting notes for the given client.

  This is a stand-in for a future CRM integration and is safe to
  call in LiveViews without hitting the database or external APIs.
  """
  @spec get_mock_crm_data(term()) :: [crm_note()]
  def get_mock_crm_data(_client_id) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    [
      %{
        id: 1,
        occurred_at: NaiveDateTime.add(now, -7 * 24 * 60 * 60, :second),
        summary: "Quarterly portfolio review – discussed shifting 10% into short-duration bonds due to rate uncertainty."
      },
      %{
        id: 2,
        occurred_at: NaiveDateTime.add(now, -30 * 24 * 60 * 60, :second),
        summary: "Tax planning session – explored using ISA allowances and capital gains harvesting before year end."
      },
      %{
        id: 3,
        occurred_at: NaiveDateTime.add(now, -90 * 24 * 60 * 60, :second),
        summary: "Initial onboarding – captured goals around retirement at 60, school fees, and maintaining lifestyle."
      }
    ]
  end

  @doc """
  Gets a single meeting.

  Raises `Ecto.NoResultsError` if the Meeting does not exist.

  ## Examples

      iex> get_meeting!(123)
      %Meeting{}

      iex> get_meeting!(456)
      ** (Ecto.NoResultsError)

  """
  def get_meeting!(id), do: Repo.get!(Meeting, id)

  @doc """
  Creates a meeting.

  ## Examples

      iex> create_meeting(%{field: value})
      {:ok, %Meeting{}}

      iex> create_meeting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_meeting(attrs) do
    %Meeting{}
    |> Meeting.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a meeting.

  ## Examples

      iex> update_meeting(meeting, %{field: new_value})
      {:ok, %Meeting{}}

      iex> update_meeting(meeting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_meeting(%Meeting{} = meeting, attrs) do
    meeting
    |> Meeting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a meeting.

  ## Examples

      iex> delete_meeting(meeting)
      {:ok, %Meeting{}}

      iex> delete_meeting(meeting)
      {:error, %Ecto.Changeset{}}

  """
  def delete_meeting(%Meeting{} = meeting) do
    Repo.delete(meeting)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking meeting changes.

  ## Examples

      iex> change_meeting(meeting)
      %Ecto.Changeset{data: %Meeting{}}

  """
  def change_meeting(%Meeting{} = meeting, attrs \\ %{}) do
    Meeting.changeset(meeting, attrs)
  end

  @doc """
  Marks a meeting as live.

  This is used by the Live Meeting view when the advisor starts
  a real-time conversation with the client.
  """
  @spec start_meeting(Meeting.t()) :: {:ok, Meeting.t()} | {:error, Ecto.Changeset.t()}
  def start_meeting(%Meeting{} = meeting) do
    update_meeting(meeting, %{status: "live"})
  end

  @doc """
  Marks a meeting as completed.

  This is used when the advisor finishes the live meeting and moves
  into the post-meeting recap workflow.
  """
  @spec complete_meeting(Meeting.t()) :: {:ok, Meeting.t()} | {:error, Ecto.Changeset.t()}
  def complete_meeting(%Meeting{} = meeting) do
    update_meeting(meeting, %{status: "completed"})
  end
end
