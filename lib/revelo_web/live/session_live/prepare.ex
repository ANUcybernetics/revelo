defmodule ReveloWeb.SessionLive.Prepare do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Diagrams
  alias Revelo.Diagrams.Variable
  alias Revelo.Sessions.Session

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-3 w-full h-full gap-5">
      <.card class="h-full col-span-2">
        <.card_header class="flex flex-row justify-between">
          <.card_title>Prepare your variables</.card_title>
          <div class="flex gap-2">
            <.button
              phx-click={show_modal("variable-modal")}
              type="button"
              variant="outline"
              size="sm"
              class="!mt-0"
            >
              <.icon name="hero-plus-mini" class="h-4 w-4 mr-2 transition-all" /> Add Variable
            </.button>
            <div class="flex gap-0">
              <.button
                type="button"
                variant="outline"
                size="sm"
                class="!mt-0  rounded-none rounded-l-md"
              >
                <.icon name="hero-sparkles" class="h-4 w-4 mr-2 transition-all" /> Generate Variables
              </.button>
              <.input
                id="input-basic-inputs-number"
                label="Number input"
                type="number"
                placeholder="0"
                min="0"
                max="20"
                class="rounded-none rounded-r-md text-xs h-8 border-l-0 w-12 pr-[2px]"
              />
            </div>
          </div>
        </.card_header>
        <.card_content>
          <.table>
            <.table_header>
              <.table_row>
                <.table_head>Name</.table_head>
                <.table_head>Type</.table_head>
                <.table_head>Actions</.table_head>
              </.table_row>
            </.table_header>
            <.table_body>
              <%= for variable <- @variables do %>
                <.table_row class={if variable.hidden?, do: "opacity-40"}>
                  <.table_cell>{variable.name}</.table_cell>
                  <.table_cell>
                    <%= if variable.is_key? do %>
                      <.badge_key>
                        Key Variable
                      </.badge_key>
                    <% end %>
                  </.table_cell>
                  <.table_cell>
                    <.variable_actions variable={variable} />
                  </.table_cell>
                </.table_row>
              <% end %>
            </.table_body>
          </.table>
        </.card_content>
      </.card>

      <.card>
        <.card_header>
          <.header class="flex flex-row justify-between">
            <.card_title>Your Session</.card_title>
            <:actions>
              <.link patch={~p"/sessions/#{@session.id}/prepare/edit"}>
                <.button type="button" variant="outline" size="sm" class="!mt-0">
                  <.icon name="hero-pencil-square-mini" class="h-4 w-4 mr-2 transition-all" /> Edit
                </.button>
              </.link>
            </:actions>
          </.header>
        </.card_header>
        <.card_content>
          <p><b>Title:</b> {@session.name}
            <br /><br />
            {@session.description}</p>
        </.card_content>
      </.card>
    </div>

    <.modal id="variable-modal">
      <div>
        <.form
          :let={f}
          for={%{}}
          as={:variable}
          phx-submit={JS.push("save_variable")}
          class="space-y-6"
        >
          <div class="form_item">
            <.form_label>Add Variable</.form_label>
            <.input field={f[:name]} type="text" required />
          </div>

          <div class="form_item">
            <div class="flex items-center space-x-2">
              <.checkbox id="key" field={f[:is_key?]} />
              <.label for="key">Is Key?</.label>
            </div>
          </div>

          <.button type="submit" phx-click={hide_modal("variable-modal")}>
            Save
          </.button>
        </.form>
      </div>
    </.modal>

    <.modal
      :if={@live_action in [:edit]}
      id="session-modal"
      show
      on_cancel={JS.patch(~p"/sessions/#{@session.id}/prepare/")}
    >
      <.live_component
        module={ReveloWeb.SessionLive.FormComponent}
        id={(@session && @session.id) || :edit}
        title={@page_title}
        current_user={@current_user}
        action={@live_action}
        session={@session}
        patch={~p"/sessions/#{@session.id}/prepare/"}
      />
    </.modal>

    <.back navigate={~p"/sessions"}>Back to Sessions</.back>
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

  defp apply_action(socket, :edit, params) do
    session = Ash.get!(Session, params["session_id"])
    variables = Diagrams.list_variables!(params["session_id"], true)

    socket
    |> assign(:page_title, "Edit Session")
    |> assign(:session, session)
    |> assign(:variables, variables)
  end

  defp apply_action(socket, :prepare, params) do
    session = Ash.get!(Session, params["session_id"])
    variables = Diagrams.list_variables!(params["session_id"], true)

    socket
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(:session, session)
    |> assign(:variables, variables)
  end

  # @impl true
  # def handle_params(%{"session_id" => session_id}, _, socket) do
  #   user = socket.assigns.current_user
  #   session = Ash.get!(Session, session_id)
  #   variables = Diagrams.list_variables!(session_id, true)
  #   dbg()

  #   if connected?(socket) do
  #     Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session_id}")
  #     ReveloWeb.Presence.track_participant(session_id, user.id, :waiting)
  #   end

  #   {:noreply,
  #    socket
  #    |> assign(:page_title, page_title(socket.assigns.live_action))
  #    |> assign(:time_remaining, session)
  #    |> assign(:variables, variables)
  #    |> assign(:session, session)}
  # end

  @impl true
  def handle_event("save_variable", %{"variable" => params}, socket) do
    session = socket.assigns.session
    actor = socket.assigns.current_user

    case Ash.create(
           Variable,
           %{
             name: params["name"],
             is_key?: params["is_key?"] == "true",
             hidden?: false,
             session: session
           },
           actor: actor
         ) do
      {:ok, variable} ->
        {:noreply, update(socket, :variables, &(&1 ++ [variable]))}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save variable: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("toggle_hidden", %{"id" => variable_id}, socket) do
    updated_variable = Diagrams.toggle_variable_visibility!(variable_id)

    {:noreply,
     update(socket, :variables, fn vars ->
       Enum.map(vars, fn v ->
         if v.id == updated_variable.id, do: updated_variable, else: v
       end)
     end)}
  end

  @impl true
  def handle_event("toggle_key", %{"id" => variable_id}, socket) do
    updated_variable = Diagrams.toggle_key_variable!(variable_id)

    {:noreply,
     update(socket, :variables, fn vars ->
       Enum.map(vars, fn v ->
         if v.id == updated_variable.id, do: updated_variable, else: v
       end)
     end)}
  end

  @impl true
  def handle_event("delete_variable", %{"id" => variable_id}, socket) do
    Diagrams.destroy_variable!(variable_id)

    {:noreply,
     update(socket, :variables, fn vars ->
       Enum.filter(vars, fn v -> v.id != variable_id end)
     end)}
  end

  @impl true
  def handle_info({ReveloWeb.SessionLive.FormComponent, {:saved, session}}, socket) do
    {:noreply, stream_insert(socket, :sessions, session)}
  end

  @impl true
  def handle_info({:timer_update, total_count}, socket) do
    {:noreply, assign(socket, :time_remaining, total_count)}
  end

  @impl true
  def handle_info({:participant_count, total_count}, socket) do
    {:noreply, assign(socket, :participant_count, total_count)}
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
