defmodule AdvisorCoPilotWeb.PrepLive do
  use AdvisorCoPilotWeb, :live_view

  alias AdvisorCoPilot.Intelligence
  alias AdvisorCoPilot.Meetings

  @impl true
  def mount(%{"client_id" => client_id} = _params, _session, socket) do
    crm_notes = Meetings.get_mock_crm_data(client_id)

    socket =
      socket
      |> assign(:page_title, "Prep")
      |> assign(:client_id, client_id)
      |> assign(:crm_notes, crm_notes)
      |> assign(:analyzing, false)
      |> assign(:analysis_summary, nil)
      |> assign(:analysis_talking_points, [])

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    # Fallback when no client_id is provided – useful in early development.
    mount(%{"client_id" => "demo-client"}, %{}, socket)
  end

  @impl true
  def handle_event("analyze", _params, socket) do
    notes = socket.assigns.crm_notes

    parent = self()

    Task.Supervisor.async_nolink(AdvisorCoPilot.Intelligence.TaskSupervisor, fn ->
      result = Intelligence.analyze_prep(notes)
      send(parent, {:prep_analysis_completed, result})
    end)

    {:noreply, assign(socket, :analyzing, true)}
  end

  @impl true
  def handle_info({:prep_analysis_completed, {:ok, %{summary: summary, talking_points: points}}}, socket) do
    socket =
      socket
      |> assign(:analyzing, false)
      |> assign(:analysis_summary, summary)
      |> assign(:analysis_talking_points, points)

    {:noreply, socket}
  end

  def handle_info({:prep_analysis_completed, {:error, _reason}}, socket) do
    # Keep things resilient – don't crash the LiveView if analysis fails.
    socket =
      socket
      |> assign(:analyzing, false)
      |> put_flash(:error, "We couldn't complete the analysis. Please try again.")

    {:noreply, socket}
  end

  # If the underlying task dies (timeout, external API failure, etc.),
  # we simply surface a soft error and let the user try again.
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    socket =
      socket
      |> assign(:analyzing, false)
      |> put_flash(:error, "Analysis took too long. Please try again.")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl space-y-6 px-4 py-8">
      <.header>
        Prep
        <:subtitle>
          Get briefed on the client and generate talking points before your next meeting.
        </:subtitle>
        <:actions>
          <.button phx-click="analyze" disabled={@analyzing} class="btn btn-primary">
            <span :if={!@analyzing}>Analyze</span>
            <span :if={@analyzing} class="inline-flex items-center gap-2">
              <.icon name="hero-arrow-path" class="size-4 motion-safe:animate-spin" />
              Analysing...
            </span>
          </.button>
        </:actions>
      </.header>

      <div class="grid gap-6 md:grid-cols-2">
        <div class="space-y-4">
          <.briefing notes={@crm_notes} />
        </div>

        <div class="space-y-4">
          <section class="card bg-base-100 shadow-sm border border-base-200 min-h-40">
            <div class="card-body space-y-3">
              <header class="flex items-center justify-between gap-4">
                <div>
                  <h2 class="text-base font-semibold">Summary</h2>
                  <p class="text-sm text-base-content/70">
                    Generated from recent CRM notes (mocked LLM).
                  </p>
                </div>
                <div :if={@analyzing} class="flex items-center gap-1 text-xs text-base-content/70">
                  <.icon name="hero-arrow-path" class="size-4 motion-safe:animate-spin" />
                  Analysing…
                </div>
              </header>

              <p :if={@analysis_summary} class="text-sm leading-relaxed">
                {@analysis_summary}
              </p>

              <p :if={!@analysis_summary && !@analyzing} class="text-sm text-base-content/70">
                Click <span class="font-semibold">Analyze</span> to generate a concise briefing.
              </p>
            </div>
          </section>

          <section class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body space-y-3">
              <header>
                <h2 class="text-base font-semibold">Talking Points</h2>
                <p class="text-sm text-base-content/70">
                  Three focused items to cover in your next conversation.
                </p>
              </header>

              <ol
                :if={@analysis_talking_points != []}
                class="list-decimal list-inside space-y-2 text-sm leading-relaxed"
              >
                <li :for={point <- @analysis_talking_points}>{point}</li>
              </ol>

              <p :if={@analysis_talking_points == []} class="text-sm text-base-content/70">
                Talking points will appear here after you run an analysis.
              </p>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end
end

