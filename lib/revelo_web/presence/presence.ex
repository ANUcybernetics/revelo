defmodule ReveloWeb.Presence do
  @moduledoc false
  use Phoenix.Presence,
    otp_app: :revelo,
    pubsub_server: Revelo.PubSub

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def handle_metas("session_presence:" <> session_id, _diff, presences, state) do
    # Calculate total number of connected clients
    total_count = Enum.count(presences)

    # Broadcast only the count
    msg = {:participant_count, total_count}
    Phoenix.PubSub.local_broadcast(Revelo.PubSub, "session:#{session_id}", msg)

    {:ok, state}
  end

  def list_online_participants(session_id) do
    "session_presence:#{session_id}" |> list() |> Enum.map(fn {_id, presence} -> presence end)
  end

  # TODO perhaps we should track (and update) the user's phase as well
  def track_participant(session_id, user_id) do
    track(self(), "session_presence:#{session_id}", user_id, %{session_id: session_id})
  end
end
