defmodule AdvisorCoPilotWeb.PostMeetingLive do
  use AdvisorCoPilotWeb, :live_view

  alias AdvisorCoPilot.Intelligence.Summarizer
  alias AdvisorCoPilot.Meetings
  alias AdvisorCoPilot.Meetings.Meeting

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    meeting = Meetings.get_meeting!(id)

    socket =
      socket
      |> assign(:meeting, meeting)
      |> assign(:page_title, "Post-Meeting")
      |> assign(:recap_summary, nil)
      |> assign(:recap_tasks, [])
      |> assign(:email_draft, "")
      |> assign(:generating_recap, false)
      |> assign(:synced_to_crm, false)
      |> generate_recap()

    {:ok, socket}
  end

  @impl true
  def handle_event("generate_recap", _params, socket) do
    {:noreply,
     socket
     |> assign(:generating_recap, true)
     |> generate_recap()}
  end

  @impl true
  def handle_event("sync_crm", _params, socket) do
    socket =
      socket
      |> assign(:synced_to_crm, true)
      |> put_flash(:info, "Recap synced to CRM (mock).")

    {:noreply, socket}
  end

  defp generate_recap(%{assigns: %{meeting: %Meeting{} = meeting}} = socket) do
    # Always reload the meeting so we see the latest transcript
    meeting = Meetings.get_meeting!(meeting.id)
    transcript = meeting.transcript || ""

    case Summarizer.generate_recap(transcript) do
      {:ok, %{summary: summary, tasks: tasks, email_draft: email_draft}} ->
        socket
        |> assign(:meeting, meeting)
        |> assign(:recap_summary, summary)
        |> assign(:recap_tasks, tasks)
        |> assign(:email_draft, email_draft)
        |> assign(:generating_recap, false)

      {:error, _reason} ->
        socket
        |> assign(:generating_recap, false)
        |> put_flash(:error, "We couldn't generate a recap just now. Please try again.")
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl space-y-6 px-4 py-8">
      <.header>
        Post-Meeting
        <:subtitle>
          Review an AI-style recap, action items, and a ready-to-send client email.
        </:subtitle>
        <:actions>
          <div class="flex items-center gap-3">
            <.button
              phx-click="generate_recap"
              disabled={@generating_recap}
              class="btn btn-primary"
            >
              <span :if={!@generating_recap}>Generate Recap</span>
              <span :if={@generating_recap} class="inline-flex items-center gap-2">
                <.icon name="hero-arrow-path" class="size-4 motion-safe:animate-spin" />
                Generating…
              </span>
            </.button>
            <.link
              navigate={~p"/meetings/new"}
              class="btn btn-soft"
            >
              New Meeting
            </.link>
          </div>
        </:actions>
      </.header>

      <section class="grid gap-6 md:grid-cols-3">
        <div class="md:col-span-2 space-y-4">
          <section class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body space-y-3">
              <header class="flex items-center justify-between gap-4">
                <div>
                  <h2 class="text-base font-semibold">Summary</h2>
                  <p class="text-sm text-base-content/70">
                    High-level overview of the discussion and client priorities.
                  </p>
                </div>
                <div :if={@generating_recap} class="flex items-center gap-1 text-xs text-base-content/70">
                  <.icon name="hero-arrow-path" class="size-4 motion-safe:animate-spin" />
                  Generating…
                </div>
              </header>

              <p :if={@recap_summary} class="text-sm leading-relaxed">
                {@recap_summary}
              </p>

              <p :if={!@recap_summary && !@generating_recap} class="text-sm text-base-content/70">
                Click <span class="font-semibold">Generate Recap</span> to create a concise post-meeting summary.
              </p>
            </div>
          </section>

          <section class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body space-y-3">
              <header class="flex items-center justify-between gap-4">
                <div>
                  <h2 class="text-base font-semibold">Action Items</h2>
                  <p class="text-sm text-base-content/70">
                    Tasks with clear owners and target dates.
                  </p>
                </div>
              </header>

              <ul
                :if={@recap_tasks != []}
                class="space-y-3 text-sm leading-relaxed"
              >
                <li
                  :for={task <- @recap_tasks}
                  class="flex flex-col gap-1 rounded-lg bg-base-200/60 px-3 py-2"
                >
                  <span class="font-medium">{task.title}</span>
                  <div class="flex flex-wrap gap-2 text-xs text-base-content/70">
                    <span class="badge badge-outline badge-sm">
                      Owner: {task.owner}
                    </span>
                    <span :if={task.deadline} class="badge badge-soft badge-sm">
                      Due: {task.deadline}
                    </span>
                    <span :if={!task.deadline} class="badge badge-ghost badge-sm">
                      No target date
                    </span>
                  </div>
                </li>
              </ul>

              <p :if={@recap_tasks == []} class="text-sm text-base-content/70">
                Once a recap is generated, action items will appear here.
              </p>
            </div>
          </section>
        </div>

        <aside class="space-y-4">
          <section class="card bg-base-100 shadow-sm border border-base-200 h-full">
            <div class="card-body space-y-3">
              <header class="flex items-center justify-between gap-4">
                <div>
                  <h2 class="text-base font-semibold">Client Email</h2>
                  <p class="text-sm text-base-content/70">
                    A draft you can paste into your email tool.
                  </p>
                </div>
              </header>

              <div class="flex gap-2">
                <.button
                  phx-hook="CopyToClipboard"
                  data-target-id="post-meeting-email-draft"
                  class="btn btn-xs btn-outline"
                >
                  Copy Email
                </.button>
                <.button
                  phx-click="sync_crm"
                  disabled={@synced_to_crm}
                  class="btn btn-xs btn-outline"
                >
                  <span :if={!@synced_to_crm}>Sync to CRM (mock)</span>
                  <span :if={@synced_to_crm}>Synced</span>
                </.button>
              </div>

              <textarea
                id="post-meeting-email-draft"
                class="textarea textarea-bordered w-full mt-2 min-h-56 text-sm leading-relaxed font-mono"
                readonly
              >{@email_draft}</textarea>
            </div>
          </section>
        </aside>
      </section>
    </div>
    """
  end
end

