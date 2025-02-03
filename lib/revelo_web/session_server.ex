defmodule ReveloWeb.SessionServer do
  @moduledoc """
  Central Session GenServer responsible for maintaining state of Revelo
  workshop sessions.

  The orchestration of the session is a co-ordinated dance between this module, the
  ReveloWeb.Presence module, and the Phoenix.PubSub system.

  Each session will have a single SessioServer process running (managed via a Registry)
  and is the canonical source of the current phase & timeout info for the given session.
  """
  use GenServer

  @timer_interval_sec 1

  # Client API

  def start_link(session_id) do
    GenServer.start_link(__MODULE__, session_id, name: via_tuple(session_id))
  end

  def get_state(session_id) do
    get_session(session_id)
    GenServer.call(via_tuple(session_id), :get_state)
  end

  def get_phase(session_id) do
    get_session(session_id)
    GenServer.call(via_tuple(session_id), :get_phase)
  end

  def set_partipant_count(session_id, {complete, total}) do
    get_session(session_id)
    GenServer.call(via_tuple(session_id), {:participant_count, {complete, total}})
  end

  def transition_to(session_id, phase) do
    get_session(session_id)
    GenServer.call(via_tuple(session_id), {:transition_to, phase})
  end

  defp get_session(session_id) do
    case GenServer.whereis(via_tuple(session_id)) do
      nil ->
        case Revelo.SessionSupervisor.start_session(session_id) do
          {:ok, _pid} ->
            :ok

          {:error, {:already_started, _pid}} ->
            :ok

          {:error, reason} ->
            raise "Failed to start session: #{inspect(reason)}"
        end

      _pid ->
        :ok
    end
  end

  # Server Callbacks

  @impl true
  def init(session_id) do
    state = %{
      session_id: session_id,
      # start in :identify, because it's the start of the real thing
      phase: :identify,
      timer: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:get_phase, _from, state) do
    {:reply, state.phase, state}
  end

  @impl true
  def handle_call({:transition_to, phase}, _from, state) do
    broadcast_transition(state.session_id, phase)
    {:reply, :ok, %{state | phase: phase}}
  end

  @impl true
  def handle_call({:participant_count, {complete, total}}, _from, state) do
    case {complete, state.phase} do
      # if complete == total, we're done and let's move on
      {^total, :identify} ->
        broadcast_transition(state.session_id, :relate)

        schedule_tick()
        {:reply, :ok, %{state | phase: :relate, timer: 60}}

      {^total, :relate} ->
        broadcast_transition(state.session_id, :analyse)
        {:reply, :ok, %{state | phase: :analyse}}

      {_, phase} when phase in [:identify, :relate] ->
        Phoenix.PubSub.broadcast(
          Revelo.PubSub,
          "session:#{state.session_id}",
          {:participant_count, {complete, total}}
        )

        {:reply, :ok, state}

      _ ->
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_info(:tick, state) do
    case {state.phase, state.timer} do
      {:relate, 0} ->
        broadcast_transition(state.session_id, :analyse)
        {:noreply, %{state | phase: :analyse}}

      {:relate, timer} ->
        Phoenix.PubSub.broadcast(
          Revelo.PubSub,
          "session:#{state.session_id}",
          {:timer, timer}
        )

        schedule_tick()
        {:noreply, %{state | timer: timer - @timer_interval_sec}}

      _ ->
        {:noreply, state}
    end
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, :timer.seconds(@timer_interval_sec))
  end

  defp via_tuple(session_id) do
    {:via, Registry, {Revelo.SessionRegistry, session_id}}
  end

  defp broadcast_transition(session_id, phase) do
    Phoenix.PubSub.broadcast(
      Revelo.PubSub,
      "session:#{session_id}",
      {:transition, phase}
    )
  end
end
