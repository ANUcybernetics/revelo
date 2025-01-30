defmodule ReveloWeb.UserFlowTest do
  use ReveloWeb.ConnCase

  import ReveloTest.Generators

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

      static = log_in_user(conn, Ash.CiString.value(user.email), password)

      assert static.conn.assigns.current_user.id == user.id
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

      static =
        conn
        |> log_in_user(Ash.CiString.value(user.email), password)
        |> Map.get(:conn)
        |> visit("/qr/sessions/#{session.id}/identify")
        |> assert_path("/sessions/#{session.id}/identify")

      assert static.conn.assigns.current_user.id == user.id
    end

    test "does happen with no logged-in user", %{conn: conn} do
      session = session()

      static =
        conn
        |> visit("/qr/sessions/#{session.id}/identify")
        |> assert_path("/sessions/#{session.id}/identify")

      user = Ash.load!(static.conn.assigns.current_user, :anonymous?)
      assert user.anonymous?
    end
  end
end
