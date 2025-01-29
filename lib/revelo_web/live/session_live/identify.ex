defmodule ReveloWeb.SessionLive.Identify do
  @moduledoc false
  use ReveloWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Identify: {@session.name}
      <:subtitle>{@session.description}</:subtitle>
    </.header>

    <p class="mt-6">
      {@participant_count} participant(s)
    </p>
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
      ReveloWeb.Presence.track_participant(session_id, user.id)
    end

    {:noreply,
     socket
     |> assign(:participant_count, 1)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:session, session)}
  end

  @impl true
  def handle_info({:participant_count, total_count}, socket) do
    {:noreply, assign(socket, :participant_count, total_count)}
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
