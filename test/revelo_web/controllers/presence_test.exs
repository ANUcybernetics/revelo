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

    test "presence tracking is triggered when anon user joins via QR code", %{conn: conn} do
      user = user()
      session = session(user)

      conn
      |> visit("/qr/sessions/#{session.id}/identify/work")
      |> assert_path("/sessions/#{session.id}/identify/work")

      participants = Presence.list_online_participants(session.id)
      refute Enum.empty?(participants)
      assert length(participants) == 1
    end

    test "presence tracking is triggered when known user starts the :identify_work", %{conn: conn} do
      user = user()
      session = session(user)

      %{conn: conn} =
        conn
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
  end
end
