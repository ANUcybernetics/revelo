defmodule ReveloWeb.UserFlowTest do
  use ReveloWeb.ConnCase

  import ReveloTest.Generators

  def create_session_with_user(conn) do
    password = "657]545asdflh"
    user = user_with_password(password)

    conn
    |> visit("/sign-in/")
    |> fill_in("#user-password-sign-in-with-password_email", "Email", with: Ash.CiString.value(user.email))
    |> fill_in("#user-password-sign-in-with-password_password", "Password", with: password)
    |> submit()
  end

  describe "real (non-anonymous) users can do stuff" do
    test "can create a new session", %{conn: conn} do
      conn
      |> create_session_with_user()
      |> assert_has("h1", text: "Revelo")
      |> click_link("Sessions")
      |> click_link("New Session")
    end
  end
end
