defmodule ReveloWeb.SessionLive.Prepare do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Diagrams.Variable

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-3 w-full h-full gap-5">
      <.card class="h-full col-span-2">
        <.card_header class="flex flex-row justify-between">
          <.card_title>Prepare your variables</.card_title>
          <.button
            phx-click={show_modal("variable-modal")}
            type="button"
            variant="outline"
            size="sm"
            class="!mt-0"
          >
            <.icon name="hero-plus-mini" class="h-4 w-4 mr-2 transition-all" /> Add Variable
          </.button>
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
        <.card_header class="flex flex-row justify-between">
          <.card_title>Settings</.card_title>
          <.button
            phx-click={show_modal("session-modal")}
            type="button"
            variant="outline"
            size="sm"
            class="!mt-0"
          >
            <.icon name="hero-pencil-square-mini" class="h-4 w-4 mr-2 transition-all" /> Edit
          </.button>
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

    <.modal id="session-modal">
      <div>
        <form phx-submit="save_settings" class="space-y-6">
          <div class="form_item">
            <.form_label>Title</.form_label>
            <.input type="text" name="title" value={@session.name} required />
            <.form_description>
              This is the title of your project.
            </.form_description>
          </div>

          <div class="form_item">
            <.form_label>Description/Context</.form_label>
            <.textarea name="description" value={@session.description} />
            <.form_description>
              This is your project description.
            </.form_description>
          </div>

          <.button phx-click={hide_modal("session-modal")}>
            Save
          </.button>
        </form>
      </div>
    </.modal>

    <.back navigate={~p"/sessions"}>Back to Sessions</.back>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"session_id" => session_id}, _, socket) do
    user = socket.assigns.current_user
    session = Ash.get!(Revelo.Sessions.Session, session_id, actor: user)
    variables = Ash.read!(Revelo.Diagrams.Variable, actor: user)

    if connected?(socket) do
      ReveloWeb.Presence.track_participant(session.id, user.id)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:session, session)
     |> assign(:variables, variables)
     |> assign(:session, session)}
  end

  @impl true
  def handle_event("save_variable", %{"variable" => params}, socket) do
    session = socket.assigns.session
    actor = socket.assigns.current_user

    case Ash.create(
           Revelo.Diagrams.Variable,
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
    case Ash.get!(Revelo.Diagrams.Variable, variable_id) do
      %Revelo.Diagrams.Variable{hidden?: hidden?} = variable ->
        updated_variable =
          if hidden?,
            do: Revelo.Diagrams.unhide_variable!(variable),
            else: Revelo.Diagrams.hide_variable!(variable)

        {:noreply,
         update(socket, :variables, fn vars ->
           Enum.map(vars, fn v ->
             if v.id == updated_variable.id, do: updated_variable, else: v
           end)
         end)}
    end
  end

  @impl true
  def handle_event("toggle_key", %{"id" => variable_id}, socket) do
    case Ash.get!(Revelo.Diagrams.Variable, variable_id) do
      %Revelo.Diagrams.Variable{is_key?: is_key?} = variable ->
        updated_variable =
          if is_key?,
            do: Revelo.Diagrams.unset_key_variable!(variable),
            else: Revelo.Diagrams.set_key_variable!(variable)

        {:noreply,
         update(socket, :variables, fn vars ->
           Enum.map(vars, fn v ->
             if v.id == updated_variable.id, do: updated_variable, else: v
           end)
         end)}
    end
  end

  @impl true
  def handle_info({ReveloWeb.Presence, event}, socket) do
    {:noreply,
     case event do
       {:join, presence} ->
         stream_insert(socket, :participants, presence)

       {:leave, presence} when presence.metas == [] ->
         stream_delete(socket, :participants, presence)

       {:leave, presence} ->
         stream_insert(socket, :participants, presence)
     end}
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
