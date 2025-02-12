defmodule Revelo.SessionServerTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  alias Revelo.SessionServer

  setup do
    user = user()
    session = session(user)
    {:ok, pid} = SessionServer.start_link(session.id)
    {:ok, pid: pid, session: session}
  end

  test "initial state is set correctly", %{session: session} do
    state = SessionServer.get_state(session.id)
    assert state.session_id == session.id
    assert state.phase == :prepare
    assert state.timer == 0
  end

  test "relates phase has timer countdown", %{session: session} do
    Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session.id}")

    # Move to relate phase
    SessionServer.transition_to(session.id, :identify_work)
    assert_receive {:transition, :identify_work}

    state = SessionServer.get_state(session.id)
    assert state.timer == 60

    Process.sleep(2000)
    assert_receive {:timer, 60}
    assert_receive {:timer, 59}
  end
end
