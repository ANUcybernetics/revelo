defmodule ReveloWeb.SessionLive.Index do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Sessions.Session

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full p-6">
      <.card class="h-full flex flex-col">
        <.card_header>
          <.header>
            <.card_title>Your Sessions</.card_title>
            <:actions>
              <.link patch={~p"/sessions/new"}>
                <.button>New Session</.button>
              </.link>
            </:actions>
          </.header>
        </.card_header>
        <.card_content class="h-2 grow">
        <.table>
          <.table_header>
            <.table_row>
              <.table_head>Name</.table_head>
              <.table_head>Phase</.table_head>
              <.table_head class="text-right">Action</.table_head>
            </.table_row>
          </.table_header>
          <.table_body>
          <.table_row :for={{id, session} <- @streams.sessions} id={id} phx-click="navigate_to_phase" phx-value-id={session.id} class="cursor-pointer">
            <.table_cell class="font-medium"><%= session.name %></.table_cell>
              <.table_cell>
                <% phase = Revelo.SessionServer.get_phase(session.id) %>
                <div class="flex items-center gap-2">
                  <.icon
                    name={
                      case phase do
                        :prepare -> "hero-adjustments-horizontal-mini"
                        :identify_work -> "hero-queue-list-mini"
                        :identify_discuss -> "hero-queue-list-mini"
                        :relate_work -> "hero-arrows-right-left-mini"
                        :relate_discuss -> "hero-arrows-right-left-mini"
                        :analyse -> "hero-arrow-path-rounded-square-mini"
                      end
                    }
                    class="h-4 w-4"
                  />
                  {case phase do
                    :prepare -> "Prepare"
                    :identify_work -> "Identify Work"
                    :identify_discuss -> "Identify Discuss"
                    :relate_work -> "Relate Work"
                    :relate_discuss -> "Relate Discuss"
                    :analyse -> "Analyse"
                  end}
                </div>
              </.table_cell>
              <.table_cell class="text-right">
                <.link
                  phx-click={JS.push("delete", value: %{id: session.id}) |> hide("##{id}")}
                  data-confirm="Are you sure?"
                >
                  Delete
                </.link>
              </.table_cell>
            </.table_row>
          </.table_body>
        </.table>
        </.card_content>
      </.card>
    </div>

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

  @impl true
  def handle_event("navigate_to_phase", %{"id" => id}, socket) do
    session = Ash.get!(Session, id, actor: socket.assigns.current_user)
    phase = Revelo.SessionServer.get_phase(session.id)

    {:noreply,
     case phase do
       :prepare ->
         push_navigate(socket, to: ~p"/sessions/#{session.id}/prepare")

       :identify_work ->
         push_navigate(socket, to: ~p"/sessions/#{session.id}/identify/work")

       :identify_discuss ->
         push_navigate(socket, to: ~p"/sessions/#{session.id}/identify/discuss")

       :relate_work ->
         push_navigate(socket, to: ~p"/sessions/#{session.id}/relate/work")

       :relate_discuss ->
         push_navigate(socket, to: ~p"/sessions/#{session.id}/relate/discuss")

       :analyse ->
         push_navigate(socket, to: ~p"/sessions/#{session.id}/analyse")
     end}
  end
end
