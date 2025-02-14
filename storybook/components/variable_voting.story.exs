defmodule Storybook.Examples.VariableVoting do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.UIComponents

  def doc do
    "The main variable voting interface (for a participant)"
  end

  defstruct [:id, :name, :is_voi?, :voted?]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       variables: [
         %__MODULE__{id: "1", name: "The One Ring", is_voi?: true, voted?: false},
         %__MODULE__{id: "2", name: "Frodo Baggins", is_voi?: false, voted?: false},
         %__MODULE__{id: "3", name: "Gandalf the Grey", is_voi?: false, voted?: true},
         %__MODULE__{id: "4", name: "Aragorn", is_voi?: false, voted?: false},
         %__MODULE__{id: "5", name: "Legolas", is_voi?: false, voted?: false},
         %__MODULE__{id: "6", name: "Gimli", is_voi?: false, voted?: true},
         %__MODULE__{id: "7", name: "Samwise Gamgee", is_voi?: false, voted?: false},
         %__MODULE__{id: "8", name: "Gollum", is_voi?: false, voted?: false}
       ]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.variable_voting variables={@variables} />
    """
  end
end
