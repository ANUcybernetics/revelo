defmodule Storybook.Examples.VariableVoting do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.UIComponents

  def doc do
    "The main variable voting interface (for a participant)"
  end

  defstruct [:id, :name, :voted?]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       variables: [
         %__MODULE__{id: "1", name: "The One Ring", voted?: false},
         %__MODULE__{id: "2", name: "Frodo Baggins", voted?: false},
         %__MODULE__{id: "3", name: "Gandalf the Grey", voted?: true},
         %__MODULE__{id: "4", name: "Aragorn", voted?: false},
         %__MODULE__{id: "5", name: "Legolas", voted?: false},
         %__MODULE__{id: "6", name: "Gimli", voted?: true},
         %__MODULE__{id: "7", name: "Samwise Gamgee", voted?: false},
         %__MODULE__{id: "8", name: "Gollum", voted?: false}
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
