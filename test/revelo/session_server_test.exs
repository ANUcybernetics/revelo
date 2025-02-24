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
end
