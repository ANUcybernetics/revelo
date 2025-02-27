defmodule ReveloWeb.PresenceTest do
  use ReveloWeb.ConnCase

  import ReveloTest.Generators

  alias ReveloWeb.Presence

  setup do
    # TODO this will start a new registry for each test, which will fail
    start_supervised({Registry, keys: :unique, name: Revelo.SessionRegistry})
    :ok
  end

  # helper function to deal with the CI string
  def log_in_user(conn, %Ash.CiString{} = email, password), do: log_in_user(conn, Ash.CiString.value(email), password)

  def log_in_user(conn, email, password) do
    conn
    |> visit("/sign-in/")
    |> fill_in("#user-password-sign-in-with-password_email", "Email", with: email)
    |> fill_in("#user-password-sign-in-with-password_password", "Password", with: password)
    |> submit()
  end

  describe "presence tracking" do
    test "is not triggered for facilitators", %{conn: conn} do
      password = "657]545asdflh"
      user = user_with_password(password)
      session = session(user)

      browsing_session = log_in_user(conn, user.email, password)

      browsing_session.conn
      |> visit("/sessions/#{session.id}/identify/work")
      |> assert_path("/sessions/#{session.id}/identify/work")

      assert Presence.list_online_participants(session.id) == []
    end

    @tag skip: "needs to be updated to have a facilitator send a transition message"
    test "presence tracking is triggered when anon user joins via QR code", %{conn: conn} do
      password = "657]545asdflh"
      facilitator = user_with_password(password)
      session = session(facilitator)

      # log in facilitator
      facilitator_session = log_in_user(conn, facilitator.email, password)

      # visit with facilitator
      visit(facilitator_session.conn, "/sessions/#{session.id}/identify/work")

      # visit with anonymous user
      conn
      |> visit("/qr/sessions/#{session.id}/identify/work")
      |> assert_path("/sessions/#{session.id}/identify/work")

      participants = Presence.list_online_participants(session.id)
      refute Enum.empty?(participants)
      assert length(participants) == 1
    end

    @tag skip: "needs to be updated to have a facilitator send a transition message"
    test "presence tracking is triggered when known user starts the :identify_work", %{conn: conn} do
      user = user()
      session = session(user)

      # Have the facilitator visit first
      facilitator = user_with_password("testpassword123")
      Revelo.Sessions.add_participant!(session, facilitator, true)
      facilitator_session = log_in_user(conn, facilitator.email, "testpassword123")

      # Visit with facilitator
      visit(facilitator_session.conn, "/sessions/#{session.id}/identify/work")

      # Then have a participant join
      %{conn: conn} =
        build_conn()
        |> visit("/qr/sessions/#{session.id}/identify/work")
        |> assert_path("/sessions/#{session.id}/identify/work")

      # Get user_id from the browsing session
      user_id = conn.assigns.current_user.id

      participants = Presence.list_online_participants(session.id)
      assert length(participants) == 1
      # Participant starts with completed? == false
      assert [{^user_id, 0, 1}] = participants
    end

    test "participant state is updated when they click done in :identify_work", %{conn: conn} do
      user = user()
      session = session(user)

      Revelo.SessionServer.transition_to(session.id, :identify_work)

      %{conn: conn} =
        conn
        |> visit("/qr/sessions/#{session.id}/identify/work")
        |> click_button("Done")

      # Get user_id from the browsing session
      user_id = conn.assigns.current_user.id

      participants = Presence.list_online_participants(session.id)
      assert length(participants) == 1
      # Participant starts with completed? == false
      assert [{^user_id, 1, 1}] = participants
    end

    test "tracker reflects completion status for individual participants", %{conn: conn} do
      user = user()
      session = session(user)

      Revelo.SessionServer.transition_to(session.id, :identify_work)

      # First anon user joins
      %{conn: %{assigns: %{current_user: _first_user}}} =
        conn
        |> visit("/qr/sessions/#{session.id}/identify/work")
        |> click_button("Done")

      # Second anon user joins
      %{conn: %{assigns: %{current_user: _second_user}}} =
        build_conn()
        |> visit("/qr/sessions/#{session.id}/identify/work")
        |> click_button("Done")

      # Third anon user joins but doesn't click done
      %{conn: %{assigns: %{current_user: _third_user}}} =
        visit(build_conn(), "/qr/sessions/#{session.id}/identify/work")

      participants = Presence.list_online_participants(session.id)
      assert length(participants) == 3

      # Get count of completed participants
      completed_count =
        Enum.count(participants, fn {_id, completed, _total} -> completed == 1 end)

      assert completed_count == 2
    end

    test "count reports participants only (not facilitator)", %{conn: conn} do
      password = "657]545asdflh"
      facilitator = user_with_password(password)
      session = session(facilitator)

      # log in facilitator
      facilitator_session = log_in_user(conn, facilitator.email, password)

      # visit with facilitator
      visit(facilitator_session.conn, "/sessions/#{session.id}/identify/work")

      # visit with two anonymous users
      conn
      |> visit("/qr/sessions/#{session.id}/identify/work")
      |> assert_path("/sessions/#{session.id}/identify/work")

      build_conn()
      |> visit("/qr/sessions/#{session.id}/identify/work")
      |> assert_path("/sessions/#{session.id}/identify/work")

      participants = Presence.list_online_participants(session.id)
      assert length(participants) == 2
    end

    test "all users receive updated progress when a user joins", %{conn: conn} do
      user = user()
      session = session(user)
      Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session.id}")
      Revelo.SessionServer.transition_to(session.id, :identify_work)

      # First user joins
      conn
      |> visit("/qr/sessions/#{session.id}/identify/work")
      |> assert_path("/sessions/#{session.id}/identify/work")

      assert_receive {:progress, {0, 1}}

      # Second user joins and clicks done
      build_conn()
      |> visit("/qr/sessions/#{session.id}/identify/work")
      |> click_button("Done")

      assert_receive {:progress, {1, 2}}

      :ok = Phoenix.PubSub.unsubscribe(Revelo.PubSub, "session:#{session.id}")
    end
  end
end
