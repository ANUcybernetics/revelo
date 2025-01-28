defmodule ReveloWeb.SessionLive.Prepare do
  @moduledoc false
  use ReveloWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@session.name}
      <:subtitle>Prepare phase</:subtitle>
    </.header>

    <p class="my-4">
      TODO: This is the preparation area where all the session information will be displayed. You'll find details about the session configuration, participants, and other relevant information here.
    </p>

    <.back navigate={~p"/sessions"}>Back to Sessions</.back>
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

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:session, session)
     |> ReveloWeb.Presence.setup_presence_tracking(session, user)}
  end

  @impl true
  def handle_info({ReveloWeb.Presence, event}, socket) do
    {:noreply,
     case event do
       {:join, presence} ->
         stream_insert(socket, :participants, presence)

       {:leave, presence} when presence.metas == [] ->
         stream_delete(socket, :participants, presence)

       {:leave, presence} ->
         stream_insert(socket, :participants, presence)
     end}
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
