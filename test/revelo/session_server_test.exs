defmodule ReveloWeb.SessionServerTest do
  use Revelo.DataCase

  import ReveloTest.Generators

  alias ReveloWeb.SessionServer

  setup do
    session = session()
    {:ok, pid} = SessionServer.start_link(session)
    {:ok, pid: pid, session: session}
  end

  test "initial state is set correctly", %{pid: pid, session: session} do
    state = GenServer.call(pid, :get_state)
    assert state.session == session
    assert state.phase == :prepare
    assert state.time_left == 0
  end

  test "set_timer updates the time_left", %{pid: pid, session: session} do
    SessionServer.set_timer(session.id, 10)
    state = GenServer.call(pid, :get_state)
    assert state.time_left == 10
  end

  test "timer ticks decrease time_left", %{pid: pid, session: session} do
    SessionServer.set_timer(session.id, 2)
    # Wait for 2 seconds to allow the timer to tick
    :timer.sleep(2500)
    state = GenServer.call(pid, :get_state)
    assert state.time_left == 0
  end

  test "pubsub broadcasts on state transition", %{session: session} do
    Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session.id}")

    SessionServer.transition_state(session.id, :identify)
    assert_receive {:state_changed, :identify}
  end

  test "pubsub broadcasts on timer update", %{session: session} do
    Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session.id}")

    SessionServer.set_timer(session.id, 2)
    # Wait for 1 second to allow the timer to tick
    :timer.sleep(1000)
    assert_receive {:timer_update, 2}
    :timer.sleep(1000)
    assert_receive {:timer_update, 1}
  end
end
