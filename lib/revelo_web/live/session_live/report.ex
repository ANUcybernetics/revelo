defmodule ReveloWeb.SessionLive.Report do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Sessions.Session

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={@current_user.facilitator?} class="p-6 h-full flex flex-col h-svh overflow-y-auto">
      <div class="grid grid-cols-12 w-full grow gap-6">
        <div class="col-span-12 flex flex-col items-center justify-center">
          <h2 class="text-2xl font-bold mb-6">Session Report</h2>
          <.button phx-click="generate_report">Generate Report</.button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"session_id" => session_id}, _url, socket) do
    session = Ash.get!(Session, session_id)
    current_user = Ash.load!(socket.assigns.current_user, facilitator?: [session_id: session_id])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session.id}")
    end

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:session, session)
      |> assign(:page_title, "Session Report")

    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_report", _params, socket) do
    # This will be implemented later
    {:noreply, put_flash(socket, :info, "Report generation initiated")}
  end
end
