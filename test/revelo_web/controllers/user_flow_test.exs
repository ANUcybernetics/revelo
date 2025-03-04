defmodule ReveloWeb.UserFlowTest do
  use ReveloWeb.ConnCase

  import ReveloTest.Generators

  setup do
    # TODO this will start a new registry for each test, which will fail
    start_supervised({Registry, keys: :unique, name: Revelo.SessionRegistry})
    :ok
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
      |> click_link("Start Mapping Now")
      |> assert_path("/sessions/")
      |> click_link("New Session")
    end
  end

  describe "Identify page actions" do
    test "anon user sees participant content on identify page", %{conn: conn} do
      user = user()
      session = session(user)

      Revelo.SessionServer.transition_to(session.id, :identify_work)

      conn
      |> visit("/qr/sessions/#{session.id}/identify/work")
      |> assert_path("/sessions/#{session.id}/identify/work")
      |> assert_has("div", text: "Which of these are important parts of your system?")
    end

    test "anon user can vote for variables", %{conn: conn} do
      user = user()
      session = session(user)
      var1 = variable(user: user, session: session, name: "Test Variable 1")
      var2 = variable(user: user, session: session, name: "Test Variable 2")

      Revelo.SessionServer.transition_to(session.id, :identify_work)

      conn
      |> visit("/qr/sessions/#{session.id}/identify/work")
      |> assert_path("/sessions/#{session.id}/identify/work")
      |> check("Test Variable 1")
      |> click_button("Done")
      |> assert_has("span", text: var1.name)
      |> assert_has("div.inline-flex.bg-emerald-200", text: "Important", exact: true)
      |> assert_has("span", text: var2.name)
      |> assert_has("div.inline-flex.bg-rose-200", text: "Not Important", exact: true)
    end

    test "facilitator sees facilitator content on identify page", %{conn: conn} do
      password = "657]545asdflh"
      user = user_with_password(password)
      session = session(user)

      browsing_session =
        conn
        |> log_in_user(Ash.CiString.value(user.email), password)
        |> Map.get(:conn)
        |> visit("/qr/sessions/#{session.id}/identify/work")
        |> assert_path("/sessions/#{session.id}/identify/work")
        |> assert_has("h3", text: "Identify variables")

      assert browsing_session.conn.assigns.current_user.id == user.id
    end
  end

  describe "QR-code anon-user-creation" do
    test "doesn't happen if non-anon user is already logged in", %{conn: conn} do
      password = "657]545asdflh"
      user = user_with_password(password)
      session = session(user)

      browsing_session =
        conn
        |> log_in_user(Ash.CiString.value(user.email), password)
        |> Map.get(:conn)
        |> visit("/qr/sessions/#{session.id}/identify/work")
        |> assert_path("/sessions/#{session.id}/identify/work")

      assert browsing_session.conn.assigns.current_user.id == user.id
    end

    @tag skip: "needs to be updated to have a facilitator send a transition message"
    test "does happen with no logged-in user", %{conn: conn} do
      password = "657]545asdflh"
      facilitator = user_with_password(password)
      session = session(facilitator)

      # log in facilitator
      facilitator_session = log_in_user(conn, facilitator.email, password)

      # visit with facilitator
      visit(facilitator_session.conn, "/sessions/#{session.id}/identify/work")

      browsing_session =
        conn
        |> visit("/qr/sessions/#{session.id}/identify/work")
        |> assert_path("/sessions/#{session.id}/identify/work")

      user = Ash.load!(browsing_session.conn.assigns.current_user, :anonymous?)
      assert user.anonymous?
    end

    test "anon user stays logged in as they navigate around", %{conn: conn} do
      creator = user()
      session = session(creator)

      browsing_session = visit(conn, "/qr/sessions/#{session.id}/identify/work")
      user = browsing_session.conn.assigns.current_user

      browsing_session = visit(browsing_session.conn, "/")
      # check the previously-created anon user is still current user
      assert browsing_session.conn.assigns.current_user.id == user.id
    end
  end

  describe "Facilitator end-to-end flow" do
    test "facilitator can create a session and add variables", %{conn: conn} do
      password = "657]545asdflh"
      user = user_with_password(password)

      facilitator_session =
        conn
        |> log_in_user(Ash.CiString.value(user.email), password)
        |> click_link("Start Mapping Now")
        |> assert_has("h3", text: "Your Sessions")
        |> click_link("New Session")
        |> assert_has("h1", text: "New Session")
        |> fill_in("Name", with: "Test Session")
        |> fill_in("Description", with: "This is a test session.")
        |> click_button("Save Session")
        |> assert_has("td", text: "Test Session")

      sessions =
        Revelo.Sessions.Session
        |> Ash.Query.new()
        |> Ash.read!()

      session = Enum.find(sessions, &(&1.name == "Test Session"))

      facilitator_session =
        facilitator_session.conn
        |> visit("/sessions/#{session.id}/prepare")
        |> assert_has("h3", text: "Prepare your variables")
        |> click_link("Add Variable")
        |> fill_in("Variable Name", with: "Test Variable 1")
        |> click_button("Create Variable")
        |> click_link("Add Variable")
        |> fill_in("Variable Name", with: "Test Variable 2")
        |> click_button("Create Variable")
        |> click_link("Add Variable")
        |> fill_in("Variable Name", with: "Test Variable 3")
        |> click_button("Create Variable")
        |> click_link("Next Phase")
        |> assert_has("h3", text: "Identify variables")

      anon_session =
        conn
        |> visit("/qr/sessions/#{session.id}/identify/work")
        |> assert_has("h3", text: "Which of these are important parts of your system?")
        |> assert_has("div", text: "Test Variable 1")
        |> assert_has("div", text: "Test Variable 2")
        # can't check variable 1, because it's the VoI
        |> check("Test Variable 2")
        |> check("Test Variable 3")
        |> click_button("Done")
        |> assert_has("div", text: "Important")

      facilitator_session =
        facilitator_session.conn
        |> visit("/sessions/#{session.id}/identify/work")
        |> click_link("Next Phase")
        |> assert_has("h3", text: "Variable Votes")
        |> assert_has("td", text: "1")

      anon_session =
        anon_session.conn
        |> visit("/sessions/#{session.id}/identify/discuss")
        |> assert_has("h3", text: "Task Completed!")

      facilitator_session =
        facilitator_session.conn
        |> visit("/sessions/#{session.id}/identify/discuss")
        |> click_link("Next Phase")
        |> assert_has("h3", text: "Identify relationships")

      _anon_session =
        anon_session.conn
        |> visit("/sessions/#{session.id}/relate/work")
        |> assert_has("h3", text: "Increasing the")

      # TODO This fails sometimes with a disconnect error?
      _facilitator_session =
        facilitator_session.conn
        |> visit("/sessions/#{session.id}/relate/work")
        |> click_link("Next Phase")
        |> assert_has("h3", text: "Relationship Votes")
    end
  end
end
