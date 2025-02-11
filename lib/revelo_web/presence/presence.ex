defmodule ReveloWeb.Presence do
  @moduledoc false
  use Phoenix.Presence,
    otp_app: :revelo,
    pubsub_server: Revelo.PubSub

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def handle_metas("session_presence:" <> session_id, _diff, presences, state) do
    # Calculate both total and complete counts
    total = Enum.count(presences)

    complete =
      presences
      |> Map.values()
      |> Enum.count(fn %{metas: metas} ->
        Enum.any?(metas, fn %{phase: phase} -> phase in [:identify_discuss, :relate_discuss] end)
      end)

    # Broadcast both counts
    Revelo.SessionServer.set_partipant_count(session_id, {complete, total})

    {:ok, state}
  end

  def list_online_participants(session_id) do
    "session_presence:#{session_id}" |> list() |> Enum.map(fn {_id, presence} -> presence end)
  end

  # these functions expect to be called from a LiveView module
  def track_participant(session_id, user_id, phase) do
    track(self(), "session_presence:#{session_id}", user_id, %{phase: phase})
  end

  def update_status(session_id, user_id, phase) do
    update(self(), "session_presence:#{session_id}", user_id, fn meta ->
      Map.put(meta, :phase, phase)
    end)
  end
end
