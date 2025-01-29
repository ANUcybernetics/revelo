defmodule ReveloWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  use ReveloWeb, :verified_routes

  import Phoenix.Component

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_user_create_anon, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      case Revelo.Accounts.register_anonymous_user() do
        {:ok, user} ->
          socket =
            socket
            |> assign(:current_user, user)
            |> assign(:user_token, user.__metadata__.token)

          {:cont, socket}

        {:error, _error} ->
          {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
      end
    end
  end
end
