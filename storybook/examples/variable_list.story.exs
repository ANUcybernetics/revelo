defmodule Storybook.Examples.VariableList do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Button
  import SaladUI.Form

  # import ReveloWeb.CoreComponents
  import SaladUI.Input
  import SaladUI.Table

  alias Phoenix.LiveView.JS

  def doc do
    "The main variable list interface (for a facilitator)"
  end

  defstruct [:id, :name, :description, :is_key?]

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
      <.table_caption>Variables</.table_caption>
      <.table_header>
        <.table_row>
          <.table_head>Id</.table_head>
          <.table_head>Name</.table_head>
          <.table_head>Description</.table_head>
          <.table_head>Key?</.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <%= for variable <- @variables do %>
          <.table_row>
            <.table_cell class="font-medium">{variable.id}</.table_cell>
            <.table_cell>{variable.name}</.table_cell>
            <.table_cell>{variable.description}</.table_cell>
            <.table_cell>{variable.is_key?}</.table_cell>
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
        <.form_label>Description</.form_label>
        <.input field={f[:description]} type="text" />
      </.form_item>
      <.form_item>
        <.form_label>Is Key?</.form_label>
        <.input field={f[:is_key?]} type="checkbox" />
      </.form_item>
      <.button type="submit">Save variable</.button>
    </.form>
    """
  end

  @impl true
  def handle_event("save_variable", %{"variable" => params}, socket) do
    variable = %__MODULE__{
      name: params["name"],
      description: params["description"],
      is_key?: params["is_key?"] == "true",
      id: socket.assigns.current_id + 1
    }

    {:noreply,
     socket
     |> update(:variables, &(&1 ++ [variable]))
     |> update(:current_id, &(&1 + 1))}
  end
end
