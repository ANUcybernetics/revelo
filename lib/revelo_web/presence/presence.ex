defmodule ReveloWeb.Presence do
  @moduledoc false
  use Phoenix.Presence,
    otp_app: :revelo,
    pubsub_server: Revelo.PubSub

  def init(_opts), do: {:ok, %{}}

  def fetch(_topic, presences) do
    for {user_id, %{metas: [meta | metas]}} <- presences, into: %{} do
      {user_id, %{metas: [meta | metas], id: user_id, user: %{id: user_id}}}
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

  def list_online_participants(session) do
    "session:#{session.id}" |> list() |> Enum.map(fn {_id, presence} -> presence end)
  end

  def track_participant(session, user) do
    track(self(), "session:#{session.id}", user.id, %{id: user.id})
  end

  def subscribe(session) do
    Phoenix.PubSub.subscribe(Revelo.PubSub, "proxy:session:#{session.id}")
  end
end
