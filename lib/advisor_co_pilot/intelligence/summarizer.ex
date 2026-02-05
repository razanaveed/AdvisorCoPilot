defmodule AdvisorCoPilot.Intelligence.Summarizer do
  @moduledoc """
  Builds a structured, JSON-friendly recap for a completed meeting.

  This module is intentionally deterministic and fast for now – it does not
  yet call an external LLM, but it mirrors the shape we expect from one:

      %{
        summary: String.t(),
        tasks: [%{title: String.t(), owner: String.t(), deadline: String.t() | nil}],
        email_draft: String.t()
      }

  The `deadline` field is rendered as an ISO 8601 date string (YYYY-MM-DD)
  so it can be safely encoded to JSON and stored or sent to other systems.
  """

  @type task :: %{
          required(:title) => String.t(),
          required(:owner) => String.t(),
          # ISO 8601 date string, e.g. "2026-02-05"
          required(:deadline) => String.t() | nil
        }

  @type recap :: %{
          required(:summary) => String.t(),
          required(:tasks) => [task()],
          required(:email_draft) => String.t()
        }

  @type recap_result :: {:ok, recap()} | {:error, term()}

  @doc """
  Generates a structured recap for the given full transcript.

  In a future phase this function will delegate to an LLM and then
  normalise its output into the expected JSON shape. For now we
  synthesise a recap that is still useful for demos and tests.
  """
  @spec generate_recap(String.t()) :: recap_result()
  def generate_recap(transcript) when is_binary(transcript) do
    today = Date.utc_today()

    cleaned_transcript =
      transcript
      |> String.trim()
      |> String.replace(~r/\s+/, " ")

    summary =
      if cleaned_transcript == "" do
        "No transcript has been captured yet for this meeting. Once you run a live meeting, a concise recap will appear here."
      else
        "The conversation focused on long-term planning, risk comfort, and cash flow clarity. " <>
          "Key themes include retirement goals, education costs, and staying invested through volatility."
      end

    tasks =
      build_default_tasks(today)
      |> maybe_tag_empty_transcript(cleaned_transcript)

    email_draft =
      build_email_draft(cleaned_transcript, summary, tasks, today)

    {:ok,
     %{
       summary: summary,
       tasks: tasks,
       email_draft: email_draft
     }}
  rescue
    exception ->
      {:error, {:recap_failed, exception}}
  end

  defp build_default_tasks(today) do
    [
      %{
        title: "Share updated financial plan and confirm comfort with risk level",
        owner: "Advisor",
        deadline: relative_to_iso_date("in 1 week", today)
      },
      %{
        title: "Provide documents for school fees and major upcoming expenses",
        owner: "Client",
        deadline: relative_to_iso_date("in 2 weeks", today)
      },
      %{
        title: "Schedule follow-up to review cash flow and tax opportunities",
        owner: "Advisor",
        deadline: relative_to_iso_date("in 1 month", today)
      }
    ]
  end

  defp maybe_tag_empty_transcript(tasks, ""), do: Enum.map(tasks, &Map.put(&1, :deadline, nil))
  defp maybe_tag_empty_transcript(tasks, _transcript), do: tasks

  defp build_email_draft("", _summary, _tasks, _today) do
    """
    Hi [Client],

    Once we've run your next live meeting, this space will contain a ready-to-send recap email with key decisions and next steps.

    Best regards,
    [Advisor]
    """
    |> String.trim_trailing()
  end

  defp build_email_draft(transcript, summary, tasks, _today) do
    preview =
      transcript
      |> String.slice(0, 220)
      |> String.trim()

    bullets =
      tasks
      |> Enum.map(fn %{title: title, owner: owner, deadline: deadline} ->
        deadline_part =
          case deadline do
            nil -> ""
            date -> " (target: #{date})"
          end

        "- #{title} – #{owner}#{deadline_part}"
      end)
      |> Enum.join("\n")

    """
    Hi [Client],

    Thank you again for taking the time to speak today. Here's a brief recap of our conversation:

    #{summary}

    Key actions we agreed:
    #{bullets}

    For reference, a short excerpt from our discussion:
    \"#{preview}...\"

    If anything above doesn't look right, please let me know and we can adjust.

    Best regards,
    [Advisor]
    """
    |> String.trim_trailing()
  end

  @doc """
  Converts a relative date expression such as "in 2 weeks" into
  an ISO 8601 date string (YYYY-MM-DD) based on the given `today`.

  Supported expressions:

    * "today"
    * "tomorrow"
    * "in N days"
    * "in N weeks"
    * "next week"
    * "in N months" (approximate, 30 days per month)

  Returns `nil` when the relative expression cannot be parsed.
  """
  @spec relative_to_iso_date(String.t(), Date.t() | nil) :: String.t() | nil
  def relative_to_iso_date(text, today \\ Date.utc_today())

  def relative_to_iso_date(text, today) when is_binary(text) and is_struct(today, Date) do
    text
    |> parse_relative_date(today)
    |> case do
      {:ok, date} -> Date.to_iso8601(date)
      :error -> nil
    end
  end

  @doc """
  Parses a relative date expression into a `Date.t()`.

  This is a lower-level helper that `relative_to_iso_date/2` uses.
  """
  @spec parse_relative_date(String.t(), Date.t()) :: {:ok, Date.t()} | :error
  def parse_relative_date(text, %Date{} = today) when is_binary(text) do
    downcased = String.downcase(String.trim(text))

    cond do
      downcased in ["today"] ->
        {:ok, today}

      downcased in ["tomorrow"] ->
        {:ok, Date.add(today, 1)}

      downcased in ["next week"] ->
        {:ok, Date.add(today, 7)}

      Regex.match?(~r/^in\s+\d+\s+day(s)?$/, downcased) ->
        capture_numeric_offset(downcased, today, 1)

      Regex.match?(~r/^in\s+\d+\s+week(s)?$/, downcased) ->
        capture_numeric_offset(downcased, today, 7)

      Regex.match?(~r/^in\s+\d+\s+month(s)?$/, downcased) ->
        # For now we approximate a month as 30 days, which is good enough
        # for friendly AI-style relative dates.
        capture_numeric_offset(downcased, today, 30)

      true ->
        :error
    end
  end

  defp capture_numeric_offset(text, today, factor) do
    case Regex.run(~r/in\s+(\d+)\s+\w+/, text) do
      [_, number] ->
        offset_in_days = String.to_integer(number) * factor
        {:ok, Date.add(today, offset_in_days)}

      _ ->
        :error
    end
  end

  @doc """
  Minimal helper for parsing AI-style dates.

  This mirrors the "money" logic for LLM output:

      iex> parse_ai_date("in 2 weeks")
      #Date<2026-02-19>

      iex> parse_ai_date("2026-02-19")
      {:ok, ~D[2026-02-19]}
  """
  @spec parse_ai_date(String.t()) :: Date.t() | {:ok, Date.t()} | :error
  def parse_ai_date("in 2 weeks"), do: Date.utc_today() |> Date.add(14)
  def parse_ai_date(other), do: Date.from_iso8601(other)
end

