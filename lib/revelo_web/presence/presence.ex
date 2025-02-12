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
    {complete, total} =
      presences
      |> Enum.flat_map(fn {_id, metas} -> metas end)
      |> Enum.reduce({0, 0}, fn
        %{completed?: true}, {complete_acc, total_acc} ->
          {complete_acc + 1, total_acc + 1}

        %{completed?: false}, {complete_acc, total_acc} ->
          {complete_acc, total_acc + 1}
      end)

    # Broadcast both counts
    Revelo.SessionServer.set_partipant_count(session_id, {complete, total})

    {:ok, state}
  end

  def list_online_participants(session_id) do
    "session_presence:#{session_id}"
    |> list()
    |> Enum.map(fn {id, %{metas: metas}} ->
      completed_count = Enum.count(metas, & &1.completed?)
      {id, completed_count, length(metas)}
    end)
  end

  # these functions expect to be called from a LiveView module
  def track_participant(pid \\ self(), session_id, user_id) do
    track(pid, "session_presence:#{session_id}", user_id, %{completed?: false})
  end

  def update_status(pid \\ self(), session_id, user_id, completed?) do
    update(pid, "session_presence:#{session_id}", user_id, fn %{metas: metas} ->
      %{
        metas:
          Enum.map(metas, fn meta ->
            Map.put(meta, :completed?, completed?)
          end)
      }
    end)
  end
end
