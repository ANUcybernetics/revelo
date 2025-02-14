defmodule Revelo.SessionServer do
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
  # @phases [:prepare, :identify_work, :identify_discuss, :relate_work, :relate_discuss, :analyse]

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
      phase: :prepare,
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
  def handle_call({:transition_to, direction}, from, state) when direction in [:next, :previous] do
    current_phase = state.phase

    new_phase =
      case direction do
        :next ->
          case current_phase do
            :prepare -> :identify_work
            :identify_work -> :identify_discuss
            :identify_discuss -> :relate_work
            :relate_work -> :relate_discuss
            :relate_discuss -> :analyse
            _ -> current_phase
          end

        :previous ->
          case current_phase do
            :identify_work -> :prepare
            :identify_discuss -> :identify_work
            :relate_work -> :identify_discuss
            :relate_discuss -> :relate_work
            :analyse -> :relate_discuss
            _ -> current_phase
          end
      end

    handle_call({:transition_to, new_phase}, from, state)
  end

  @impl true
  def handle_call({:transition_to, new_phase}, _from, state) do
    # this is the "state transition" control logic (could refactor into an `apply_transition/2`
    # function, but maybe not worth it for now)
    state =
      case new_phase do
        :identify_work ->
          schedule_tick()
          %{state | phase: new_phase, timer: 60}

        :relate_work ->
          schedule_tick()

          Revelo.Sessions.Session
          |> Ash.get!(state.session_id)
          |> Revelo.Diagrams.enumerate_relationships!()

          %{state | phase: new_phase, timer: 60}

        :analyse ->
          Revelo.Diagrams.rescan_loops!(state.session_id)
          %{state | phase: new_phase, timer: 0}

        _ ->
          %{state | phase: new_phase, timer: 0}
      end

    broadcast_transition(state.session_id, new_phase)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:participant_count, counts}, _from, state) do
    broadcast_participant_count(state.session_id, counts)
    # this function used to have the "auto advance phase when everyone's done logic in it
    # but I think that having the facilitator manually advance the phase is a better UX
    # so now this doesn't do much - just fans the broadcast out to all listening clients via pubsub
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    case {state.phase, state.timer} do
      {phase, 0} when phase in [:identify_work, :relate_work] ->
        {:noreply, %{state | phase: :analyse}}

      {phase, timer} when phase in [:identify_work, :relate_work] ->
        broadcast_tick(state.session_id, timer)
        schedule_tick()
        {:noreply, %{state | timer: timer - @timer_interval_sec}}

      _ ->
        {:noreply, %{state | timer: 0}}
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

  defp broadcast_participant_count(session_id, counts) do
    Phoenix.PubSub.broadcast(
      Revelo.PubSub,
      "session:#{session_id}",
      {:participant_count, counts}
    )
  end

  defp broadcast_tick(session_id, timer) do
    Phoenix.PubSub.broadcast(
      Revelo.PubSub,
      "session:#{session_id}",
      {:tick, timer}
    )
  end
end
