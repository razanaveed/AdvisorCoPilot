defmodule AdvisorCoPilotWeb.MeetingLive do
  use AdvisorCoPilotWeb, :live_view

  alias AdvisorCoPilot.Meetings
  alias AdvisorCoPilot.Meetings.Meeting

  @impl true
  def mount(_params, _session, socket) do
    changeset =
      Meetings.change_meeting(%Meeting{
        status: "prep"
      })

    {:ok,
     socket
     |> assign(:page_title, "New Meeting")
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"meeting" => params}, socket) do
    changeset =
      %Meeting{}
      |> Meeting.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"meeting" => params}, socket) do
    case Meetings.create_meeting(params) do
      {:ok, meeting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Meeting created.")
         |> push_navigate(to: ~p"/meetings/#{meeting.id}/live")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl space-y-6 px-4 py-8">
      <.header>
        New Meeting
        <:subtitle>
          Create a client meeting that you can prep and run live with real-time capture.
        </:subtitle>
      </.header>

      <section class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body space-y-6">
          <.simple_form
            for={@changeset}
            id="meeting-form"
            phx-submit="save"
            phx-change="validate"
            :let={f}
          >
            <.input field={f[:client_name]} label="Client name" />
            <.input field={f[:client_id]} label="Client ID" />
            <.input
              field={f[:status]}
              type="select"
              label="Status"
              options={[{"Prep", "prep"}, {"Live", "live"}, {"Completed", "completed"}]}
            />

            <:actions>
              <.button class="btn-primary">
                Save &amp; Go Live
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </section>
    </div>
    """
  end
end

