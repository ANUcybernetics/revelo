defmodule ReveloWeb.Presence do
  @moduledoc false
  use Phoenix.Presence,
    otp_app: :revelo,
    pubsub_server: Revelo.PubSub

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def handle_metas("session_presence:" <> session_id, _diff, presences, state) do
    {complete, total} =
      case Revelo.SessionServer.get_phase(session_id) do
        :relate_work ->
          relationships_count = length(Revelo.Diagrams.list_potential_relationships!(session_id))
          users_count = Enum.count(presences)
          total_potential_relationships = relationships_count * users_count

          completed_votes =
            presences
            |> Enum.flat_map(fn {_id, metas} -> metas end)
            |> Enum.reduce(0, fn meta, acc ->
              acc + (meta[:relate_completed?] || 0)
            end)

          {completed_votes, total_potential_relationships}

        _ ->
          # Default behavior for other phases (like identify)
          presences
          |> Enum.flat_map(fn {_id, metas} -> metas end)
          |> Enum.reduce({0, 0}, fn
            %{identify_completed?: true}, {complete_acc, total_acc} ->
              {complete_acc + 1, total_acc + 1}

            %{identify_completed?: false}, {complete_acc, total_acc} ->
              {complete_acc, total_acc + 1}
          end)
      end

    # Broadcast both counts
    Revelo.SessionServer.set_progress(session_id, {complete, total})

    {:ok, state}
  end

  def list_online_participants(session_id) do
    "session_presence:#{session_id}"
    |> list()
    |> Enum.map(fn {id, %{metas: metas}} ->
      completed_count = Enum.count(metas, & &1.identify_completed?)
      {id, completed_count, length(metas)}
    end)
  end

  # these functions expect to be called from a LiveView module
  def track_participant(session_id, user_id) do
    track(self(), "session_presence:#{session_id}", user_id, %{
      identify_completed?: false,
      relate_completed?: 0
    })
  end

  def update_identify_status(session_id, user_id, identify_completed?) do
    update(self(), "session_presence:#{session_id}", user_id, fn meta ->
      Map.put(meta, :identify_completed?, identify_completed?)
    end)
  end

  def update_relate_status(session_id, user_id, relate_completed?) do
    update(self(), "session_presence:#{session_id}", user_id, fn meta ->
      Map.put(meta, :relate_completed?, relate_completed?)
    end)
  end
end
