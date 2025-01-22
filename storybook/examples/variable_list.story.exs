defmodule Storybook.Examples.VariableList do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.CoreComponents

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
    <.table id="variable-table" rows={@variables}>
      <:col :let={variable} label="Id">
        {variable.id}
      </:col>
      <:col :let={variable} label="Name">
        {variable.name}
      </:col>
      <:col :let={variable} label="Description">
        {variable.description}
      </:col>
      <:col :let={variable} label="Key?">
        {variable.is_key?}
      </:col>
    </.table>
    <.header class="mt-16">
      Variables
      <:subtitle>What's in your system?</:subtitle>
    </.header>
    <.simple_form :let={f} for={%{}} as={:variable} phx-submit={JS.push("save_variable")}>
      <.input field={f[:name]} label="Name" />
      <.input field={f[:description]} label="Description" />
      <.input field={f[:is_key?]} type="checkbox" label="Is Key?" />
      <:actions>
        <.button>Save variable</.button>
      </:actions>
    </.simple_form>
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
