defmodule ReveloWeb.QRController do
  use ReveloWeb, :controller

  def handle_qr(conn, %{"session_id" => session_id, "phase" => phase}) when phase in ["identify", "relate"] do
    # Add a small delay to discourage rapid scanning (TODO more robust
    # rate-limiting solution probably needed in future)
    if Application.get_env(:revelo, :env) == :prod do
      Process.sleep(500)
    end

    user =
      case conn.assigns do
        %{current_user: %{id: _}} -> conn.assigns.current_user
        _ -> Revelo.Accounts.register_anonymous_user!(authorize?: false)
      end

    user = Ash.load!(user, :anonymous?)

    case Ash.get(Revelo.Sessions.Session, session_id) do
      {:ok, session} ->
        # alternately, could check if they're not already a user... not sure which is
        # semantically better for our UX
        if user.anonymous?, do: Revelo.Sessions.add_participant(session, user)

        conn
        |> AshAuthentication.Plug.Helpers.store_in_session(user)
        |> redirect(to: String.replace_prefix(conn.request_path, "/qr", ""))

      {:error, _error} ->
        conn
        |> put_flash(:error, "Session not found")
        |> redirect(to: ~p"/")
    end
  end

  def handle_qr(conn, %{"phase" => phase}) do
    conn
    |> put_flash(:error, "Unknown session phase: #{phase}")
    |> redirect(to: ~p"/")
  end
end
