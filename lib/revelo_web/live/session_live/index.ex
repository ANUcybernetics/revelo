defmodule ReveloWeb.SessionLive.Index do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Sessions.Session

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Sessions
      <:actions>
        <.link patch={~p"/sessions/new"}>
          <.button>New Session</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="Sessions"
      rows={@streams.sessions}
      row_click={fn {_id, session} -> JS.navigate(~p"/sessions/#{session}") end}
    >
      <:col :let={{_id, session}} label="Id">{session.id}</:col>

      <:action :let={{_id, session}}>
        <div class="sr-only">
          <.link navigate={~p"/sessions/#{session}"}>Show</.link>
        </div>

        <.link patch={~p"/sessions/#{session}/edit"}>Edit</.link>
      </:action>

      <:action :let={{id, session}}>
        <.link
          phx-click={JS.push("delete", value: %{id: session.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="session-modal"
      show
      on_cancel={JS.patch(~p"/sessions")}
    >
      <.live_component
        module={ReveloWeb.SessionLive.FormComponent}
        id={(@session && @session.id) || :new}
        title={@page_title}
        current_user={@current_user}
        action={@live_action}
        session={@session}
        patch={~p"/sessions"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(
       :sessions,
       Ash.read!(Session, actor: socket.assigns[:current_user])
     )
     |> assign_new(:current_user, fn -> nil end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Session")
    |> assign(:session, Ash.get!(Session, id, actor: socket.assigns.current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Session")
    |> assign(:session, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Sessions")
    |> assign(:session, nil)
  end

  @impl true
  def handle_info({ReveloWeb.SessionLive.FormComponent, {:saved, session}}, socket) do
    {:noreply, stream_insert(socket, :sessions, session)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    session = Ash.get!(Session, id, actor: socket.assigns.current_user)
    Ash.destroy!(session, actor: socket.assigns.current_user)

    {:noreply, stream_delete(socket, :sessions, session)}
  end
end
