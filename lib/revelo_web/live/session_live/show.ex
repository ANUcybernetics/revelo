defmodule ReveloWeb.SessionLive.Show do
  @moduledoc false
  use ReveloWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Session {@session.id}
      <:subtitle>This is a session record from your database.</:subtitle>

      <:actions>
        <.link patch={~p"/sessions/#{@session}/show/edit"} phx-click={JS.push_focus()}>
          <.button>Edit session</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Id">{@session.id}</:item>
    </.list>

    <.back patch={~p"/sessions"}>Back to Sessions</.back>

    <.modal
      :if={@live_action == :edit}
      id="session-modal"
      show
      on_cancel={JS.patch(~p"/sessions/#{@session}")}
    >
      <.live_component
        module={ReveloWeb.SessionLive.FormComponent}
        id={@session.id}
        title={@page_title}
        action={@live_action}
        current_user={@current_user}
        session={@session}
        patch={~p"/sessions/#{@session}"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(
       :session,
       Ash.get!(Revelo.Sessions.Session, id, actor: socket.assigns.current_user)
     )}
  end

  defp page_title(:show), do: "Show Session"
  defp page_title(:edit), do: "Edit Session"
end
