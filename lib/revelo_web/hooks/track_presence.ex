defmodule ReveloWeb.Hooks.TrackPresence do
  @moduledoc false
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    case {socket.assigns[:session], socket.assigns[:current_user]} do
      {nil, _} ->
        {:halt, socket |> put_flash(:error, "Session not found") |> push_navigate(to: "/")}

      {_, nil} ->
        {:halt, socket |> put_flash(:error, "User not authenticated") |> push_navigate(to: "/")}

      {session, current_user} ->
        if connected?(socket) do
          ReveloWeb.Presence.track_participant(session, current_user)
          ReveloWeb.Presence.subscribe(session)
        end

        socket =
          socket
          |> stream(:participants, [])
          |> stream(:participants, ReveloWeb.Presence.list_online_participants(session))

        {:cont, socket}
    end
  end

  def handle_presence_update(socket, {:join, presence}) do
    stream_insert(socket, :participants, presence)
  end

  def handle_presence_update(socket, {:leave, presence}) do
    if presence.metas == [] do
      stream_delete(socket, :participants, presence)
    else
      stream_insert(socket, :participants, presence)
    end
  end
end
