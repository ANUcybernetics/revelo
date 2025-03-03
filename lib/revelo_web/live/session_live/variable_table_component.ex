defmodule ReveloWeb.SessionLive.VariableTableComponent do
  @moduledoc false
  use ReveloWeb, :live_component
  use Gettext, backend: ReveloWeb.Gettext

  import ReveloWeb.Component.Button
  import ReveloWeb.Component.Card
  import ReveloWeb.Component.Input
  import ReveloWeb.Component.ScrollArea
  import ReveloWeb.Component.Table
  import ReveloWeb.Component.Tooltip
  import ReveloWeb.CoreComponents
  import ReveloWeb.CoreComponents, except: [table: 1, button: 1, input: 1]

  alias Revelo.Diagrams
  alias Revelo.LLM.VariableList

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> stream(:variables, [])
     |> assign(:variable_count, 0)
     |> assign(:included_count, 0)}
  end

  # recieve message from parent LiveView about a new variable
  @impl true
  def update(%{new_variable: variable}, socket) do
    # Insert the new variable into the stream
    variable = Ash.load!(variable, [:vote_tally, :voted?])
    {:ok, stream_insert(socket, :variables, variable)}
  end

  @impl true
  def update(assigns, socket) do
    variables = Diagrams.list_variables!(assigns.session.id, true)

    variable_count = Enum.count(variables)
    included_count = Enum.count(variables, fn variable -> not variable.hidden? end)

    send(self(), {:increment_variable_count, variable_count})

    socket =
      socket
      |> assign(assigns)
      |> stream(:variables, variables, reset: true)
      |> assign(:variable_count, variable_count)
      |> assign(:included_count, included_count)

    {:ok, socket}
  end

  @doc """
  Renders the variable table.
  """
  attr :session, :map, required: true, doc: "the session containing the variables"
  attr :live_action, :atom, required: true, doc: "current live action"
  attr :variable_count, :integer, required: true, doc: "the number of variables to generate"
  attr :class, :string, default: "", doc: "additional class to apply to the card"
  attr :title, :string, default: "Prepare your variables", doc: "optional title for the table"

  def render(assigns) do
    ~H"""
    <div class={["h-full w-full", @class] |> Enum.join(" ")}>
      <.card class="h-full">
        <div class="flex flex-col h-full">
          <.card_header class="w-full flex-none">
            <.header class="flex flex-row justify-between !items-start">
              <.card_title class="grow">{@title}</.card_title>
              <.card_description :if={get_phase(@live_action) == :identify} class="mt-1">
                Variables Included: {@included_count}
              </.card_description>
              <:actions>
                <div class="flex flex-row gap-2 shrink flex-wrap items-end justify-end">
                  <.link patch={"/sessions/#{@session.id}/#{get_phase(@live_action)}/variables/new"}>
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
                      phx-click="generate_variables"
                      phx-target={@myself}
                      phx-value-count={5}
                      id="generate_variables_button"
                    >
                      <.icon name="hero-sparkles" class="h-4 w-4 mr-2 transition-all" />
                      Generate Variables
                    </.button>
                    <.input
                      id="input-basic-inputs-number"
                      name="variable_count"
                      type="number"
                      placeholder="5"
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
            <.card_content class="h-full">
              <.table class="text-base">
                <.table_header>
                  <.table_row>
                    <.table_head>Name</.table_head>
                    <.table_head>Votes</.table_head>
                    <.table_head>Actions</.table_head>
                  </.table_row>
                </.table_header>
                <.table_body phx-update="stream" id="variable_table">
                  <.table_row
                    :for={{id, variable} <- @streams.variables}
                    id={id}
                    class={if variable.hidden?, do: "opacity-40"}
                  >
                    <.table_cell>{variable.name}</.table_cell>
                    <.table_cell class="pl-8">
                      {variable.vote_tally}
                    </.table_cell>
                    <.table_cell>
                      <.variable_actions
                        variable={variable}
                        session={@session}
                        live_action={@live_action}
                        myself={@myself}
                      />
                    </.table_cell>
                  </.table_row>
                </.table_body>
              </.table>
            </.card_content>
          </.scroll_area>
        </div>
      </.card>
    </div>
    """
  end

  @doc """
    The variable table action pane

  """

  def variable_actions(assigns) do
    ~H"""
    <div class="flex gap-2">
      <.tooltip>
        <tooltip_trigger>
          <.link patch={"/sessions/#{@session.id}/#{get_phase(@live_action)}/variables/#{@variable.id}"}>
            <button class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-muted">
              <.icon name="hero-pencil-square" class="h-4 w-4 transition-all" />
              <span class="sr-only">
                Edit
              </span>
            </button>
          </.link>
        </tooltip_trigger>
        <.tooltip_content side="top">
          Edit
        </.tooltip_content>
      </.tooltip>
      <.tooltip>
        <tooltip_trigger>
          <button
            class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-muted"
            phx-click="toggle_hidden"
            phx-value-id={@variable.id}
            phx-target={@myself}
          >
            <.icon
              name={if @variable.hidden?, do: "hero-eye-slash", else: "hero-eye-solid"}
              class="h-4 w-4 transition-all"
            />
            <span class="sr-only">
              {if @variable.hidden?, do: "Hide", else: "Show"}
            </span>
          </button>
        </tooltip_trigger>
        <.tooltip_content side="top">
          {if @variable.hidden?, do: "Show", else: "Hide"}
        </.tooltip_content>
      </.tooltip>
      <.tooltip>
        <tooltip_trigger>
          <button
            class={[
              "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-muted",
              @variable.vote_tally != 0 && "opacity-40"
            ]}
            phx-click="delete_variable"
            phx-value-id={@variable.id}
            phx-target={@myself}
            disabled={@variable.vote_tally != 0}
          >
            <.icon name="hero-trash" class="h-4 w-4 transition-all" />
            <span class="sr-only">
              Delete
            </span>
          </button>
        </tooltip_trigger>
        <.tooltip_content side="top">
          {if @variable.vote_tally == 0, do: "Delete", else: "Disabled - Has votes"}
        </.tooltip_content>
      </.tooltip>
    </div>
    """
  end

  # def handle_event("vote", %{"id" => var_id}, socket) do
  #   variable = Enum.find(socket.assigns.variables, &(&1.id == var_id))

  #   if variable.voted? do
  #     vote =
  #       Enum.find(
  #         Diagrams.list_variable_votes!(socket.assigns.session.id),
  #         &(&1.variable.id == var_id)
  #       )

  #     Diagrams.destroy_variable_vote!(vote)
  #   else
  #     Diagrams.variable_vote!(variable)
  #   end

  #   variables = Diagrams.list_variables!(socket.assigns.session.id, true)
  #   {:noreply, stream(socket, :variables, variables)}
  # end

  @impl true
  def handle_event("toggle_hidden", %{"id" => variable_id}, socket) do
    updated_variable = Diagrams.toggle_variable_visibility!(variable_id)

    included_count =
      if updated_variable.hidden?,
        do: socket.assigns.included_count - 1,
        else: socket.assigns.included_count + 1

    socket = assign(socket, :included_count, included_count)
    {:noreply, stream_insert(socket, :variables, updated_variable)}
  end

  @impl true
  def handle_event("delete_variable", %{"id" => variable_id}, socket) do
    destroyed_variable = Diagrams.destroy_variable!(variable_id, return_destroyed?: true)

    included_count =
      if destroyed_variable.hidden?,
        do: socket.assigns.included_count,
        else: socket.assigns.included_count - 1

    send(self(), :decrement_variable_count)
    socket = assign(socket, :included_count, included_count)
    {:noreply, stream_delete(socket, :variables, destroyed_variable)}
  end

  @impl true
  def handle_event("generate_variables", %{"count" => count}, socket) do
    %{session: session, current_user: actor} = socket.assigns

    existing_variables = Diagrams.list_variables!(session.id, true)
    variable_names = Enum.map(existing_variables, & &1.name)

    case Revelo.LLM.generate_variables(
           session.description,
           count,
           variable_names
         ) do
      {:ok, %VariableList{variables: var_list}} ->
        new_variables =
          Enum.map(var_list, fn name ->
            Diagrams.create_variable!(name, session, actor: actor)
          end)

        variables = existing_variables ++ new_variables
        included_count = socket.assigns.included_count + length(new_variables)
        send(self(), {:increment_variable_count, length(new_variables)})

        {:noreply,
         socket |> stream(:variables, variables) |> assign(:included_count, included_count)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to generate variables")}
    end
  end

  def get_phase(:identify_work), do: :identify
  def get_phase(:identify_discuss), do: :identify
  def get_phase(:relate_work), do: :relate
  def get_phase(:relate_discuss), do: :relate
  def get_phase(phase), do: phase
end
