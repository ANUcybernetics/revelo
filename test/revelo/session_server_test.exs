defmodule ReveloWeb.SessionServerTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  alias ReveloWeb.SessionServer

  setup do
    session = session()
    {:ok, pid} = SessionServer.start_link(session.id)
    {:ok, pid: pid, session: session}
  end

  test "initial state is set correctly", %{session: session} do
    state = SessionServer.get_state(session.id)
    assert state.session_id == session.id
    assert state.phase == :identify
    assert state.timer == 0
  end

  test "tracks participant progress and transitions phase", %{session: session} do
    Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session.id}")

    # Move to identify phase
    SessionServer.set_partipant_count(session.id, 3, 3)
    assert_receive {:transition, :relate}
    assert SessionServer.get_phase(session.id) == :relate

    # Move to analyse phase
    SessionServer.set_partipant_count(session.id, 3, 3)
    assert_receive {:transition, :analyse}
    assert SessionServer.get_phase(session.id) == :analyse
  end

  test "relates phase has timer countdown", %{session: session} do
    Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session.id}")

    # Move to relate phase
    SessionServer.set_partipant_count(session.id, 3, 3)
    assert_receive {:transition, :relate}
    state = SessionServer.get_state(session.id)
    assert state.timer == 60

    Process.sleep(2000)
    assert_receive {:timer, 60}
    assert_receive {:timer, 59}
  end
end
