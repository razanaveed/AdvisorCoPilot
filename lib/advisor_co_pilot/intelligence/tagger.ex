defmodule AdvisorCoPilot.Intelligence.Tagger do
  @moduledoc """
  Tags incoming transcript lines with simple, keyword-based labels.

  This GenServer subscribes to simulated speech events and broadcasts
  tagged transcript lines over PubSub so LiveViews can stream them.
  """

  use GenServer

  alias AdvisorCoPilot.Meetings

  @pubsub AdvisorCoPilot.PubSub
  @simulate_topic "meetings:simulate_speech"

  ## Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  ## Server callbacks

  @impl true
  def init(state) do
    Phoenix.PubSub.subscribe(@pubsub, @simulate_topic)
    {:ok, state}
  end

  @impl true
  def handle_info({:simulate_speech, meeting_id}, state) do
    sentence = random_sentence()
    tag = tag_sentence(sentence)

    line = %{
      id: Ecto.UUID.generate(),
      meeting_id: meeting_id,
      content: sentence,
      tag: tag,
      inserted_at: DateTime.utc_now()
    }

    # Persist the raw transcript so it can be summarised later.
    # We ignore errors here to keep the tagging pipeline resilient.
    _ = Meetings.append_transcript_line(meeting_id, sentence)

    Phoenix.PubSub.broadcast(
      @pubsub,
      "meetings:#{meeting_id}:transcript",
      {:transcript_line, line}
    )

    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  ## Tagging logic

  defp random_sentence do
    Enum.random([
      "I want to retire by 60 with enough income to maintain my lifestyle.",
      "I'm worried about market volatility and how much risk I'm taking.",
      "We need to plan for school fees over the next 10 years.",
      "I care more about preserving capital than chasing high returns.",
      "Can we increase our monthly contributions to the investment plan?",
      "I'm not sure how rising interest rates will impact my portfolio.",
      "I would like to leave something for my children as an inheritance."
    ])
  end

  defp tag_sentence(sentence) do
    downcased = String.downcase(sentence)

    cond do
      String.contains?(downcased, ["retire", "retirement", "school fees", "inheritance", "plan"]) ->
        "Financial Goal"

      String.contains?(downcased, ["worried", "risk", "volatility", "preserving capital"]) ->
        "Risk Concern"

      String.contains?(downcased, ["contributions", "income", "interest rates"]) ->
        "Cash Flow"

      true ->
        "General"
    end
  end
end

