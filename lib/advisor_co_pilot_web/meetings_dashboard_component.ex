defmodule AdvisorCoPilotWeb.MeetingsDashboardComponent do
  use AdvisorCoPilotWeb, :live_component

  alias AdvisorCoPilot.Meetings
  @impl true
  def update(assigns, socket) do
    meetings = Meetings.list_meetings()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:meetings, meetings)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    meeting = Meetings.get_meeting!(id)
    {:ok, _} = Meetings.delete_meeting(meeting)

    {:noreply, assign(socket, :meetings, Meetings.list_meetings())}
  end

  defp status_badge_class("prep"), do: "badge-info badge-soft"
  defp status_badge_class("live"), do: "badge-success badge-soft"
  defp status_badge_class("completed"), do: "badge-neutral badge-soft"
  defp status_badge_class(_), do: "badge-ghost"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="table table-zebra">
        <thead>
          <tr>
            <th class="w-10">ID</th>
            <th>Client</th>
            <th class="hidden sm:table-cell">Client ID</th>
            <th>Status</th>
            <th class="hidden sm:table-cell">Last Updated</th>
            <th class="w-40 text-right">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={meeting <- @meetings}>
            <td class="text-xs text-base-content/70">
              {meeting.id}
            </td>
            <td class="font-medium">
              {meeting.client_name}
            </td>
            <td class="hidden sm:table-cell text-xs text-base-content/70">
              {meeting.client_id}
            </td>
            <td>
              <span class={["badge badge-sm capitalize", status_badge_class(meeting.status)]}>
                {meeting.status}
              </span>
            </td>
            <td class="hidden sm:table-cell text-xs text-base-content/60">
              {meeting.updated_at && Calendar.strftime(meeting.updated_at, "%d %b %Y %H:%M")}
            </td>
            <td class="text-right">
              <div class="inline-flex gap-2">
                <.link
                  navigate={~p"/prep/#{meeting.client_id}"}
                  class="btn btn-xs btn-outline"
                >
                  Prep
                </.link>
                <.link
                  navigate={~p"/meetings/#{meeting.id}/live"}
                  class="btn btn-xs btn-outline"
                >
                  Live
                </.link>
                <.link
                  navigate={~p"/meetings/#{meeting.id}/post"}
                  class="btn btn-xs btn-outline"
                >
                  Post
                </.link>
                <button
                  type="button"
                  phx-click="delete"
                  phx-target={@myself}
                  phx-value-id={meeting.id}
                  class="btn btn-xs btn-ghost text-error"
                >
                  Delete
                </button>
              </div>
            </td>
          </tr>
          <tr :if={@meetings == []}>
            <td colspan="6" class="py-8 text-center text-sm text-base-content/60">
              No meetings yet. Use "New Meeting" to create one.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end

