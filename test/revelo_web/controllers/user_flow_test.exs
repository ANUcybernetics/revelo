defmodule ReveloWeb.UserFlowTest do
  use ReveloWeb.ConnCase

  import ReveloTest.Generators

  setup do
    _registry_pid = start_supervised({Registry, keys: :unique, name: Revelo.SessionRegistry})
    session = session()
    {:ok, pid} = ReveloWeb.SessionServer.start_link(session.id)
    {:ok, pid: pid, session: session}
  end

  def log_in_user(conn, email, password) do
    conn
    |> visit("/sign-in/")
    |> fill_in("#user-password-sign-in-with-password_email", "Email", with: email)
    |> fill_in("#user-password-sign-in-with-password_password", "Password", with: password)
    |> submit()
  end

  describe "real (non-anonymous) users can do stuff" do
    test "known user can log in", %{conn: conn} do
      password = "657]545asdflh"
      user = user_with_password(password)

      browsing_session = log_in_user(conn, Ash.CiString.value(user.email), password)

      assert browsing_session.conn.assigns.current_user.id == user.id
    end

    test "can create a new session", %{conn: conn} do
      password = "657]545asdflh"
      user = user_with_password(password)

      conn
      |> log_in_user(Ash.CiString.value(user.email), password)
      |> assert_has("h1", text: "Revelo")
      |> click_link("Sessions")
      |> assert_path("/sessions/")
      |> click_link("New Session")
    end
  end

  describe "QR-code anon-user-creation" do
    test "doesn't happen if non-anon user is already logged in", %{conn: conn} do
      password = "657]545asdflh"
      user = user_with_password(password)
      session = session()

      browsing_session =
        conn
        |> log_in_user(Ash.CiString.value(user.email), password)
        |> Map.get(:conn)
        |> visit("/qr/sessions/#{session.id}/identify")
        |> assert_path("/sessions/#{session.id}/identify")

      assert browsing_session.conn.assigns.current_user.id == user.id
    end

    test "does happen with no logged-in user", %{conn: conn, session: session} do
      browsing_session =
        conn
        |> visit("/qr/sessions/#{session.id}/identify")
        |> assert_path("/sessions/#{session.id}/identify")

      user = Ash.load!(browsing_session.conn.assigns.current_user, :anonymous?)
      assert user.anonymous?
    end

    test "anon user stays logged in as they navigate around", %{conn: conn} do
      session = session()

      browsing_session = visit(conn, "/qr/sessions/#{session.id}/identify")
      user = browsing_session.conn.assigns.current_user

      browsing_session = visit(browsing_session.conn, "/")
      # check the previously-created anon user is still current user
      assert browsing_session.conn.assigns.current_user.id == user.id
    end
  end
end
