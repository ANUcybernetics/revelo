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
    test "can create a new session", %{conn: conn} do
      password = "657]545asdflh"
      user = user_with_password(password)

      conn
      |> log_in_user(Ash.CiString.value(user.email), password)
      |> assert_has("h1", text: "Revelo")
      |> click_link("Sessions")
      |> click_link("New Session")
    end
  end

  describe "QR-code anon-user-creation" do
    test "can log in", %{conn: conn} do
      password = "657]545asdflh"
      user = user_with_password(password)

      static = log_in_user(conn, Ash.CiString.value(user.email), password)

      assert static.conn.assigns.current_user.id == user.id
    end
  end
end
