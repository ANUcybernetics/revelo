defmodule ReveloWeb.SessionLive.Identify do
  @moduledoc false
  use ReveloWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col">
      <div class="grid grid-cols-5 w-full grow gap-10">
        <.instructions title="Identify relationships">
          <ol class="list-decimal p-10 space-y-12">
            <li>Scan the QR code with your phone camera.
              Note the key variable shown at the top (this is your main system outcome)</li>
            <li>
              Choose variables that are important parts of your system:
              <ul class="list-disc ml-8">
                <li>They may directly affect your key variable.</li>
                <li>They could relate to other important variables</li>
                <li>They may help tell your system's story</li>
              </ul>
            </li>
            <li>Click 'Done' when finished (we'll discuss your choices next)</li>
          </ol>
        </.instructions>

        <.qr_code_card
          url="https://www.youtube.com/watch?v=dQw4w9WgXcQ"
          participant_count={@participant_count}
          complete_url={"/sessions/#{@session.id}/relate"}
        />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"session_id" => session_id}, _, socket) do
    user = socket.assigns.current_user
    session = Ash.get!(Revelo.Sessions.Session, session_id, actor: user)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session_id}")
      # ReveloWeb.Presence.track_participant(session_id, user.id, :waiting)
    end

    {:noreply,
     socket
     |> assign(:participant_count, {0, 1})
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:session, session)}
  end

  @impl true
  def handle_info({:participant_count, counts}, socket) do
    {:noreply, assign(socket, :participant_count, counts)}
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
