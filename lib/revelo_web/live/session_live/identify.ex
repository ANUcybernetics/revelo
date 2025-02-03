defmodule ReveloWeb.SessionLive.Identify do
  @moduledoc false
  use ReveloWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col">
      <div class="grid grid-cols-5 w-full grow gap-5">
        <.card class="h-full col-span-3 flex flex-col text-4xl">
          <.card_header class="w-full">
            <.header class="flex flex-row justify-between !items-start">
              <.card_title class="grow text-4xl">Identify relationships</.card_title>
            </.header>
          </.card_header>
          <.card_content>
            <ol class="list-decimal p-5 space-y-12">
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
          </.card_content>
        </.card>

        <.card class="h-full col-span-2 flex flex-col text-2xl justify-between">
          <.card_header class="w-full">
            <.header class="flex flex-row justify-between !items-start">
              <.card_title class="grow text-4xl">Scan QR Code</.card_title>
              <.card_description class="text-xl mt-4">
                Scan this code with your phone to join the session
              </.card_description>
            </.header>
          </.card_header>
          <.card_content>
            <div class="flex justify-center items-center flex-col border aspect-square rounded-xl w-full">
              <.qr_code text="https://www.youtube.com/watch?v=dQw4w9WgXcQ" />
            </div>
          </.card_content>
          <.card_footer class="flex flex-col items-center gap-2">
            <div>
              <span class="font-bold text-4xl">{elem(@participant_count, 0)}</span>
              <span class="text-gray-600">completed</span>
            </div>
            <.progress
              class="w-full h-2"
              value={round(elem(@participant_count, 0) / max(elem(@participant_count, 1), 1) * 100)}
            />
            <.button class="w-full mt-4">All Done</.button>
          </.card_footer>
        </.card>
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
     |> assign(:participant_count, {0, 0})
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:session, session)}
  end

  @impl true
  def handle_info({:participant_count, counts}, socket) do
    {:noreply, assign(socket, :participant_count, counts)}
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
