defmodule AdvisorCoPilotWeb.LiveMeetingLive do
  use AdvisorCoPilotWeb, :live_view

  alias AdvisorCoPilot.Meetings
  alias AdvisorCoPilot.Meetings.Meeting

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    meeting = Meetings.get_meeting!(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(AdvisorCoPilot.PubSub, transcript_topic(meeting.id))
    end

    {:ok,
     socket
     |> assign(:meeting, meeting)
     |> assign(:page_title, "Live Meeting")
     |> stream(:transcript, [])}
  end

  @impl true
  def handle_event("start_meeting", _params, %{assigns: %{meeting: meeting}} = socket) do
    case Meetings.start_meeting(meeting) do
      {:ok, updated} ->
        {:noreply, assign(socket, :meeting, updated)}

      {:error, _changeset} ->
        # In a real app, surface validation errors to the UI.
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("complete_meeting", _params, %{assigns: %{meeting: meeting}} = socket) do
    case Meetings.complete_meeting(meeting) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:meeting, updated)
         |> push_navigate(to: ~p"/meetings/#{updated.id}/post")}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("simulate_speech", _params, %{assigns: %{meeting: %Meeting{id: id}}} = socket) do
    Phoenix.PubSub.broadcast(
      AdvisorCoPilot.PubSub,
      "meetings:simulate_speech",
      {:simulate_speech, id}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:transcript_line, line}, socket) do
    {:noreply, stream_insert(socket, :transcript, line)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl space-y-6 px-4 py-8">
      <.header>
        Live Meeting
        <:subtitle>
          Capture a real-time transcript and automatically tag important client statements.
        </:subtitle>
        <:actions>
          <div class="flex gap-3 items-center">
            <span class="badge badge-outline">
              Status:
              <span class="ml-1 font-semibold capitalize">
                {@meeting.status}
              </span>
            </span>
            <.button
              phx-click="start_meeting"
              disabled={@meeting.status == "live"}
              class="btn-primary"
            >
              Start Meeting
            </.button>
            <.button
              phx-click="complete_meeting"
              disabled={@meeting.status != "live"}
              class="btn btn-soft btn-outline"
            >
              Complete &amp; Recap
            </.button>
          </div>
        </:actions>
      </.header>

      <section class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body space-y-4">
          <div class="flex items-center justify-between gap-4">
            <div>
              <h2 class="text-base font-semibold">Transcript</h2>
              <p class="text-sm text-base-content/70">
                Simulated client speech is streamed into this transcript in real time.
              </p>
            </div>
            <.button
              phx-click="simulate_speech"
              disabled={@meeting.status != "live"}
              class="btn btn-soft"
            >
              Simulate Speech
            </.button>
          </div>

          <div class="mt-2 max-h-96 overflow-y-auto border border-base-200 rounded-lg">
            <ul id="transcript" phx-update="stream" class="divide-y divide-base-200">
              <li
                :for={{dom_id, line} <- @streams.transcript}
                id={dom_id}
                class="px-4 py-3 flex items-start gap-3"
              >
                <span
                  :if={line.tag}
                  class={[
                    "badge badge-sm mt-0.5",
                    tag_badge_class(line.tag)
                  ]}
                >
                  {line.tag}
                </span>
                <p class="text-sm leading-relaxed">
                  {line.content}
                </p>
              </li>
            </ul>
          </div>
        </div>
      </section>
    </div>
    """
  end

  defp transcript_topic(meeting_id), do: "meetings:#{meeting_id}:transcript"

  defp tag_badge_class("Financial Goal"), do: "badge-success badge-soft"
  defp tag_badge_class("Risk Concern"), do: "badge-warning badge-soft"
  defp tag_badge_class("Cash Flow"), do: "badge-info badge-soft"
  defp tag_badge_class(_other), do: "badge-neutral badge-soft"
end

