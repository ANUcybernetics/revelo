defmodule ReveloWeb.SessionLive.Prepare do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Diagrams
  alias Revelo.Diagrams.Variable
  alias Revelo.LLM
  alias Revelo.Sessions.Session

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col">
      <div class="grid grid-cols-4 w-full grow gap-5">
        <.card class="h-full col-span-3 flex flex-col">
          <.card_header class="w-full">
            <.header class="flex flex-row justify-between !items-start">
              <.card_title class="grow">Prepare your variables</.card_title>
              <:actions>
                <div class="flex flex-row gap-4">
                  <.link patch={~p"/sessions/#{@session.id}/prepare/new_variable"}>
                    <.button type="button" variant="outline" size="sm" class="!mt-0">
                      <.icon name="hero-plus-mini" class="h-4 w-4 mr-2 transition-all" /> Add Variable
                    </.button>
                  </.link>
                  <div class="flex gap-0">
                    <.button
                      type="button"
                      variant="outline"
                      size="sm"
                      class="!mt-0 rounded-none rounded-l-md"
                      phx-click={JS.push("generate_variables")}
                      phx-value-count={@variable_count}
                      id="generate_variables_button"
                    >
                      <.icon name="hero-sparkles" class="h-4 w-4 mr-2 transition-all" />
                      Generate Variables
                    </.button>
                    <.input
                      id="input-basic-inputs-number"
                      name="variable_count"
                      type="number"
                      placeholder="0"
                      min="0"
                      max="20"
                      class="rounded-none rounded-r-md text-xs h-8 border-l-0 w-12 pr-[2px]"
                      phx-hook="UpdateGenerateValue"
                    />
                  </div>
                </div>
              </:actions>
            </.header>
          </.card_header>
          <.scroll_area class="h-20 grow rounded-md">
            <.card_content>
              <.table class="text-base">
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
                        <.variable_actions variable={variable} session={@session} />
                      </.table_cell>
                    </.table_row>
                  <% end %>
                </.table_body>
              </.table>
            </.card_content>
          </.scroll_area>
        </.card>

        <div class="flex gap-5 flex-col">
          <.card class="flex flex-col grow">
            <.card_header>
              <.header class="flex flex-row justify-between !items-start">
                <.card_title>Your Session</.card_title>
                <:actions>
                  <.link patch={~p"/sessions/#{@session.id}/prepare/edit"}>
                    <.button type="button" variant="outline" size="sm" class="!mt-0">
                      <.icon name="hero-pencil-square-mini" class="h-4 w-4 mr-2 transition-all" />
                      Edit
                    </.button>
                  </.link>
                </:actions>
              </.header>
            </.card_header>
            <.scroll_area class="h-20 grow rounded-md">
              <.card_content>
                <div class="grid gap-4">
                  <div>
                    <span class="font-bold">Title</span>
                    <p>{@session.name}</p>
                  </div>
                  <div>
                    <span class="font-bold">Description</span>
                    <p class="whitespace-pre-line">{@session.description}</p>
                  </div>
                </div>
              </.card_content>
            </.scroll_area>
          </.card>
          <.card>
            <.card_header>
              <.card_title>System State</.card_title>
            </.card_header>
            <.card_content>
              <div class="flex justify-between items-end gap-4">
                <div>
                  <div>
                    <span class="text-2xl font-semibold leading-none tracking-tight">
                      {length(@variables)}
                    </span>
                    <span>variable{if length(@variables) != 1, do: "s"}</span>
                  </div>
                  <span class="text-muted-foreground">30-50 reccomended</span>
                </div>
                <div>
                  <.link href={~p"/sessions/#{@session.id}/identify"}>
                    <.button>Start Session</.button>
                  </.link>
                </div>
              </div>
            </.card_content>
          </.card>
        </div>
      </div>

      <.modal
        :if={@live_action in [:new_variable, :edit_variable]}
        id="variable-modal"
        show
        on_cancel={JS.patch(~p"/sessions/#{@session.id}/prepare/")}
      >
        <.live_component
          module={ReveloWeb.SessionLive.VariableFormComponent}
          id={(@session && @session.id) || :edit}
          variable={@variable}
          title={@page_title}
          current_user={@current_user}
          action={@live_action}
          session={@session}
          patch={~p"/sessions/#{@session.id}/prepare/"}
        />
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
    </div>
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

  defp sort_variables(variables) do
    variables
    |> Enum.sort_by(& &1.inserted_at, {:asc, DateTime})
    |> Enum.sort_by(& &1.is_key?, :desc)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, params) do
    session = Ash.get!(Session, params["session_id"])
    variables = Diagrams.list_variables!(params["session_id"], true)

    sorted_variables = sort_variables(variables)

    socket
    |> assign(:page_title, "Edit Session")
    |> assign(:session, session)
    |> assign(:variables, sorted_variables)
    |> assign(:variable_count, 0)
  end

  defp apply_action(socket, :new_variable, params) do
    session = Ash.get!(Session, params["session_id"])
    variables = Diagrams.list_variables!(params["session_id"], true)

    sorted_variables = sort_variables(variables)

    socket
    |> assign(:page_title, "New Variable")
    |> assign(:session, session)
    |> assign(:variables, sorted_variables)
    |> assign(:variable_count, 0)
    |> assign(:variable, nil)
  end

  defp apply_action(socket, :edit_variable, params) do
    session = Ash.get!(Session, params["session_id"])
    variables = Diagrams.list_variables!(params["session_id"], true)
    variable_id = params["variable_id"]
    variable = Enum.find(variables, &(&1.id == variable_id))
    sorted_variables = sort_variables(variables)

    socket
    |> assign(:page_title, "Edit Variable")
    |> assign(:session, session)
    |> assign(:variables, sorted_variables)
    |> assign(:variable_count, 0)
    |> assign(:variable, variable)
  end

  defp apply_action(socket, :prepare, params) do
    session = Ash.get!(Session, params["session_id"])
    variables = Diagrams.list_variables!(params["session_id"], true)
    sorted_variables = sort_variables(variables)

    socket
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(:session, session)
    |> assign(:variables, sorted_variables)
    |> assign(:variable_count, 0)
  end

  @impl true
  def handle_event("generate_variables", %{"count" => count}, socket) do
    description = socket.assigns.session.description
    session = socket.assigns.session
    actor = socket.assigns.current_user
    variables = Diagrams.list_variables!(socket.assigns.session.id, true)
    key_variable = Enum.at(variables, 0)

    case LLM.generate_variables(description, key_variable.name, count) do
      {:ok, %LLM.VariableList{variables: var_list}} ->
        created_variables =
          var_list
          |> Enum.map(fn name ->
            case Ash.create(
                   Variable,
                   %{name: name, is_key?: false, hidden?: false, session: session},
                   actor: actor
                 ) do
              {:ok, variable} -> variable
              {:error, _changeset} -> nil
            end
          end)
          |> Enum.reject(&is_nil/1)

        sorted_variables = sort_variables(socket.assigns.variables ++ created_variables)

        {:noreply, assign(socket, :variables, sorted_variables)}

      {:error} ->
        {:noreply, put_flash(socket, :error, "Failed to generate variables")}
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

  def handle_event("toggle_key", %{"id" => variable_id}, socket) do
    updated_variable = Diagrams.toggle_key_variable!(variable_id)

    if_result =
      if updated_variable.is_key? do
        Enum.map(socket.assigns.variables, fn v ->
          if v.id == updated_variable.id do
            updated_variable
          else
            Diagrams.unset_key_variable!(v.id)
          end
        end)
      else
        Enum.map(socket.assigns.variables, fn v ->
          if v.id == updated_variable.id, do: updated_variable, else: v
        end)
      end

    sorted_variables = sort_variables(if_result)

    {:noreply, assign(socket, :variables, sorted_variables)}
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
  def handle_info({ReveloWeb.SessionLive.VariableFormComponent, {:saved_variable, session}}, socket) do
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
