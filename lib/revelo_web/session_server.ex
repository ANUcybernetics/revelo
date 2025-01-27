defmodule ReveloWeb.SessionServer do
  @moduledoc """
  Central Session GenServer responsible for maintaining state of Revelo
  workshop sessions.

  Tracks participant presence, voting status, and facilitation controls during
  interactive workshop sessions. Uses Phoenix.Presence for real-time participant
  tracking and synchronization across distributed nodes.

  Manages:
  - Active participant list and status
  - Voting and feedback collection
  - Facilitation controls and workshop flow
  """
  use GenServer

  @phases [:prepare, :identify, :relate, :analyse]
  @timer_interval :timer.seconds(1)

  # Client API

  def start_link(session) do
    GenServer.start_link(__MODULE__, session, name: via_tuple(session.id))
  end

  def get_state(session_id) do
    GenServer.call(via_tuple(session_id), :get_state)
  end

  def transition_state(session_id, new_phase) when new_phase in @phases do
    GenServer.cast(via_tuple(session_id), {:transition, new_phase})
  end

  def set_timer(session_id, seconds) do
    GenServer.cast(via_tuple(session_id), {:set_timer, seconds})
  end

  # Server Callbacks

  @impl true
  def init(session) do
    schedule_tick()

    state = %{
      session: session,
      phase: :prepare,
      time_left: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:transition, new_phase}, state) do
    on_exit(state.phase, state)
    new_phase = on_enter(new_phase, state)
    {:noreply, %{state | phase: new_phase}}
  end

  @impl true
  def handle_cast({:set_timer, seconds}, state) do
    {:noreply, %{state | time_left: seconds}}
  end

  @impl true
  def handle_info(:tick, %{time_left: 0} = state) do
    schedule_tick()
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    on_timer(state)
    schedule_tick()
    {:noreply, Map.update!(state, :time_left, &(&1 - 1))}
  end

  # Game State Lifecycle Callbacks

  defp on_enter(new_phase, state) do
    Phoenix.PubSub.broadcast(
      Revelo.PubSub,
      "session:#{state.session.id}",
      {:state_changed, new_phase}
    )

    state
  end

  defp on_exit(_old_state, state) do
    Phoenix.PubSub.broadcast(Revelo.PubSub, "session:#{state.session.id}", :state_exiting)
    state
  end

  defp on_timer(state) do
    Phoenix.PubSub.broadcast(
      Revelo.PubSub,
      "session:#{state.session.id}",
      {:timer_update, state.time_left}
    )

    :ok
  end

  # Private Helpers

  defp schedule_tick do
    Process.send_after(self(), :tick, @timer_interval)
  end

  defp via_tuple(session_id) do
    {:via, Registry, {Revelo.SessionRegistry, session_id}}
  end
end
