defmodule Storybook.Examples.VariableList do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.Component.Button
  import ReveloWeb.Component.Checkbox
  import ReveloWeb.Component.Form
  import ReveloWeb.Component.Input
  import ReveloWeb.Component.Label
  import ReveloWeb.Component.Table
  import ReveloWeb.UIComponents

  # import ReveloWeb.CoreComponents
  alias Phoenix.LiveView.JS

  def doc do
    "The main variable list interface (for a facilitator)"
  end

  defstruct [:id, :name, :is_key?]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       current_id: 1,
       variables: [
         %__MODULE__{id: 1, name: "Stuff", is_key?: true},
         %__MODULE__{id: 2, name: "Things", is_key?: false}
       ]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
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
          <.table_row>
            <.table_cell>{variable.name}</.table_cell>
            <.table_cell>
              <%= if variable.is_key? do %>
                <.badge_key>
                  Key Variable
                </.badge_key>
              <% end %>
            </.table_cell>
            <.table_cell>
              <.variable_actions is_key={variable.is_key?} id={variable.id} />
            </.table_cell>
          </.table_row>
        <% end %>
      </.table_body>
    </.table>
    <ReveloWeb.CoreComponents.header class="mt-16">
      Variables
      <:subtitle>What's in your system?</:subtitle>
    </ReveloWeb.CoreComponents.header>
    <.form :let={f} for={%{}} as={:variable} phx-submit={JS.push("save_variable")} class="space-y-6">
      <.form_item>
        <.form_label>Name</.form_label>
        <.input field={f[:name]} type="text" required />
      </.form_item>
      <.form_item>
        <div class="flex items-center space-x-2">
          <.checkbox id="key" field={f[:is_key?]} />
          <.label for="key">Is Key?</.label>
        </div>
      </.form_item>
      <.button type="submit">Save variable</.button>
    </.form>
    """
  end

  @impl true
  def handle_event("save_variable", %{"variable" => params}, socket) do
    variable = %__MODULE__{
      name: params["name"],
      is_key?: params["is_key?"] == "true",
      id: socket.assigns.current_id + 1
    }

    {:noreply,
     socket
     |> update(:variables, &(&1 ++ [variable]))
     |> update(:current_id, &(&1 + 1))}
  end

  @impl true
  def handle_event("delete_variable", %{"id" => id}, socket) do
    id = String.to_integer(id)

    updated_variables =
      Enum.reject(socket.assigns.variables, fn variable ->
        variable.id == id
      end)

    {:noreply, assign(socket, :variables, updated_variables)}
  end
end
