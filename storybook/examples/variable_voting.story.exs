defmodule Storybook.Examples.VariableVoting do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.UIComponents

  def doc do
    "The main variable voting interface (for a participant)"
  end

  defstruct [:id, :name, :is_key?]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       variables: [
         %__MODULE__{id: 1, name: "The One Ring", is_key?: true},
         %__MODULE__{id: 2, name: "Frodo Baggins", is_key?: false},
         %__MODULE__{id: 3, name: "Gandalf the Grey", is_key?: false},
         %__MODULE__{id: 4, name: "Aragorn", is_key?: false},
         %__MODULE__{id: 5, name: "Legolas", is_key?: false},
         %__MODULE__{id: 6, name: "Gimli", is_key?: false},
         %__MODULE__{id: 7, name: "Samwise Gamgee", is_key?: false},
         %__MODULE__{id: 8, name: "Gollum", is_key?: false},
         %__MODULE__{id: 9, name: "Sauron", is_key?: false},
         %__MODULE__{id: 10, name: "Saruman", is_key?: false},
         %__MODULE__{id: 11, name: "Mordor", is_key?: false},
         %__MODULE__{id: 12, name: "The Shire", is_key?: false},
         %__MODULE__{id: 13, name: "Rohan", is_key?: false},
         %__MODULE__{id: 14, name: "Gondor", is_key?: false},
         %__MODULE__{id: 15, name: "Elrond", is_key?: false},
         %__MODULE__{id: 16, name: "Galadriel", is_key?: false},
         %__MODULE__{id: 17, name: "Faramir", is_key?: false},
         %__MODULE__{id: 18, name: "Boromir", is_key?: false},
         %__MODULE__{id: 19, name: "The Balrog", is_key?: false},
         %__MODULE__{id: 20, name: "Ents", is_key?: false},
         %__MODULE__{id: 21, name: "Rivendell", is_key?: false},
         %__MODULE__{id: 22, name: "Isengard", is_key?: false},
         %__MODULE__{id: 23, name: "The Ringwraiths", is_key?: false}
       ]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.variable_voting key_variable={1} variables={@variables} />
    """
  end
end
