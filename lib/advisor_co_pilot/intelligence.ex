defmodule AdvisorCoPilot.Intelligence do
  @moduledoc """
  Placeholder context for AI/LLM-related functionality.

  This module will host logic that enriches meeting data with insights,
  summaries, and recommendations, while keeping external API failures
  from crashing the system.
  """

  alias AdvisorCoPilot.Meetings.Meeting

  @type summary_result :: {:ok, String.t()} | {:error, term()}
  @type prep_analysis :: %{
          required(:summary) => String.t(),
          required(:talking_points) => [String.t()]
        }

  @spec summarize_meeting(Meeting.t()) :: summary_result
  def summarize_meeting(_meeting) do
    # TODO: Implement LLM integration here.
    # Use `with` and error tuples so external failures don't crash processes.
    {:error, :not_implemented}
  end

  @doc """
  Mocked LLM-style analysis for a set of CRM notes.

  Returns a high-level summary and three talking points that could
  be used to prepare for an upcoming client conversation.
  """
  @spec analyze_prep([map()]) :: {:ok, prep_analysis()} | {:error, term()}
  def analyze_prep(notes) when is_list(notes) do
    # In the future this function will call an external LLM.
    # For now we keep it deterministic and fast, while still
    # exercising the async flow in the LiveView.
    joined_summaries =
      notes
      |> Enum.map(& &1.summary)
      |> Enum.join(" ")

    summary =
      "The client is focused on long-term goals (retirement, education, lifestyle) " <>
        "while remaining attentive to tax efficiency and current market volatility."

    talking_points = [
      "Revisit the portfolio tilt toward short-duration bonds and confirm comfort with current risk.",
      "Walk through an up-to-date tax and allowance checklist ahead of the new tax year.",
      "Reconnect on life goals and any changes since the onboarding conversation in light of recent markets."
    ]

    {:ok,
     %{
       summary: summary <> " Key context from prior meetings: " <> joined_summaries,
       talking_points: talking_points
     }}
  rescue
    exception ->
      {:error, {:analysis_failed, exception}}
  end
end