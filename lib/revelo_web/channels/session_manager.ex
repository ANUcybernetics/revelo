defmodule ReveloWeb.SessionManager do
  @moduledoc """
  Central Session Manager GenServer responsible for maintaining state of Revelo
  workshop sessions.

  Tracks participant presence, voting status, and facilitation controls during
  interactive workshop sessions. Uses Phoenix.Presence for real-time participant
  tracking and synchronization across distributed nodes.

  Manages:
  - Active participant list and status
  - Voting and feedback collection
  - Facilitation controls and workshop flow
  """
  use Phoenix.Presence,
    otp_app: :revelo,
    pubsub_server: Revelo.PubSub

  def init(_opts) do
    {:ok, %{}}
  end

  def fetch(_topic, presences) do
    for {key, %{metas: [meta | metas]}} <- presences, into: %{} do
      {key, %{metas: [meta | metas], id: meta.id, user: %{name: meta.id}}}
    end
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {user_id, presence} <- joins do
      user_data = %{id: user_id, user: presence.user, metas: Map.fetch!(presences, user_id)}
      msg = {__MODULE__, {:join, user_data}}
      Phoenix.PubSub.local_broadcast(Revelo.PubSub, "proxy:#{topic}", msg)
    end

    for {user_id, presence} <- leaves do
      metas =
        case Map.fetch(presences, user_id) do
          {:ok, presence_metas} -> presence_metas
          :error -> []
        end

      user_data = %{id: user_id, user: presence.user, metas: metas}
      msg = {__MODULE__, {:leave, user_data}}
      Phoenix.PubSub.local_broadcast(Revelo.PubSub, "proxy:#{topic}", msg)
    end

    {:ok, state}
  end
end
