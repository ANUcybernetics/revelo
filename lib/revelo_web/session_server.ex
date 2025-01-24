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

  @game_states [:prepare, :identify, :relate, :analyse]
  @timer_interval :timer.seconds(1)

  # Client API

  def start_link(session) do
    GenServer.start_link(__MODULE__, session, name: via_tuple(session.id))
  end

  def get_state(session_id) do
    GenServer.call(via_tuple(session_id), :get_state)
  end

  def transition_state(session_id, new_state) when new_state in @game_states do
    GenServer.cast(via_tuple(session_id), {:transition, new_state})
  end

  def set_timer(session_id, seconds) do
    GenServer.cast(via_tuple(session_id), {:set_timer, seconds})
  end

  # Server Callbacks

  @impl true
  def init(session) do
    :timer.send_interval(@timer_interval, :tick)

    state = %{
      session: session,
      game_state: :prepare,
      time_left: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:transition, new_state}, state) do
    on_exit(state.game_state, state)
    new_state = on_enter(new_state, state)
    {:noreply, %{state | game_state: new_state}}
  end

  @impl true
  def handle_cast({:set_timer, seconds}, state) do
    {:noreply, %{state | time_left: seconds}}
  end

  @impl true
  def handle_info(:tick, %{time_left: 0} = state), do: {:noreply, state}

  @impl true
  def handle_info(:tick, state) do
    new_state = on_timer(state)
    {:noreply, %{new_state | time_left: new_state.time_left - 1}}
  end

  # Game State Lifecycle Callbacks

  defp on_enter(new_state, state) do
    Phoenix.PubSub.broadcast(
      Revelo.PubSub,
      "session:#{state.session.id}",
      {:state_changed, new_state}
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

    state
  end

  # Private Helpers

  defp via_tuple(session_id) do
    {:via, Registry, {Revelo.SessionRegistry, session_id}}
  end
end
