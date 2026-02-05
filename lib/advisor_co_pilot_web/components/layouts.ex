defmodule AdvisorCoPilotWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AdvisorCoPilotWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col bg-base-200">
      <!-- Global header -->
      <header class="navbar px-4 sm:px-6 lg:px-8 border-b border-base-300 bg-base-100/95 backdrop-blur">
        <div class="flex-1">
          <.link navigate={~p"/"} class="flex items-center gap-2">
            <img src={~p"/images/logo.svg"} width="32" />
            <div class="flex flex-col">
              <span class="text-sm font-semibold tracking-tight">Advisor CoPilot</span>
              <span class="text-[11px] text-base-content/60">
                v{Application.spec(:phoenix, :vsn)}
              </span>
            </div>
          </.link>
        </div>

        <!-- Header menu -->
        <div class="flex-none flex items-center gap-3">
          <nav class="hidden md:flex items-center gap-1 text-sm">
            <.link navigate={~p"/"} class="btn btn-ghost btn-xs">
              Home
            </.link>
            <.link navigate={~p"/meetings/new"} class="btn btn-ghost btn-xs">
              New Meeting
            </.link>
            <.link navigate={~p"/prep/demo-client"} class="btn btn-ghost btn-xs">
              Prep
            </.link>
          </nav>

          <.theme_toggle />
        </div>
      </header>

      <div class="flex-1 flex min-h-0">
        <!-- Sidebar -->
        <aside class="hidden md:flex w-64 flex-col border-r border-base-300 bg-base-100/80">
          <div class="px-4 py-4 border-b border-base-300">
            <p class="text-xs font-semibold uppercase tracking-wide text-base-content/60">
              Navigation
            </p>
          </div>

          <nav class="flex-1 px-3 py-4 space-y-2 text-sm">
            <div>
              <p class="px-2 mb-1 text-[11px] uppercase tracking-wide text-base-content/50">
                Meetings
              </p>
              <ul class="space-y-1">
                <li>
                  <.link navigate={~p"/"} class="btn btn-ghost btn-xs w-full justify-start">
                    Dashboard
                  </.link>
                </li>
                <li>
                  <.link navigate={~p"/meetings/new"} class="btn btn-ghost btn-xs w-full justify-start">
                    New Meeting
                  </.link>
                </li>
              </ul>
            </div>

            <div class="pt-3 border-t border-base-300">
              <p class="px-2 mb-1 text-[11px] uppercase tracking-wide text-base-content/50">
                Workflows
              </p>
              <ul class="space-y-1">
                <li>
                  <.link navigate={~p"/prep/demo-client"} class="btn btn-ghost btn-xs w-full justify-start">
                    Prep
                  </.link>
                </li>
                <li>
                  <span class="btn btn-ghost btn-xs w-full justify-start opacity-60 cursor-default">
                    Live &amp; Post (via meetings)
                  </span>
                </li>
              </ul>
            </div>
          </nav>

          <!-- Footer inside sidebar for larger screens -->
          <footer class="px-4 py-3 border-t border-base-300 text-[11px] text-base-content/60">
            <p>Local prototype – SQLite, Phoenix LiveView.</p>
          </footer>
        </aside>

        <!-- Main content + footer -->
        <main class="flex-1 flex flex-col">
          <div class="flex-1 px-4 py-6 sm:px-6 lg:px-8 overflow-y-auto">
            <div class="mx-auto max-w-6xl space-y-4">
              {render_slot(@inner_block)}
            </div>
          </div>

          <footer class="border-t border-base-300 bg-base-100/90">
            <div class="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 py-3 flex items-center justify-between gap-3 text-[11px] text-base-content/60">
              <span>
                © {Date.utc_today().year} Advisor CoPilot · Internal prototype
              </span>
              <span class="hidden sm:inline">
                Phoenix LiveView · Tailwind + daisyUI · SQLite for dev
              </span>
            </div>
          </footer>
        </main>
      </div>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
