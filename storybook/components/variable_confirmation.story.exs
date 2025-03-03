defmodule Variable do
  @moduledoc false
  defstruct [:id, :name]
end

defmodule Vote do
  @moduledoc false
  defstruct [:voter_id, :id]
end

defmodule Storybook.Examples.VariableConfirmation do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.UIComponents

  def doc do
    "The variable voting confirmation interface (for a participant)"
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       user_id: 1,
       variables: [
         %Variable{id: 1, name: "The One Ring"},
         %Variable{id: 2, name: "Frodo Baggins"},
         %Variable{id: 3, name: "Gandalf the Grey"},
         %Variable{id: 4, name: "Aragorn"},
         %Variable{id: 5, name: "Legolas"},
         %Variable{id: 6, name: "Gimli"},
         %Variable{id: 7, name: "Samwise Gamgee"},
         %Variable{id: 8, name: "Gollum"},
         %Variable{id: 9, name: "Sauron"},
         %Variable{id: 10, name: "Saruman"},
         %Variable{id: 11, name: "Mordor"},
         %Variable{id: 12, name: "The Shire"},
         %Variable{id: 13, name: "Rohan"},
         %Variable{id: 14, name: "Gondor"},
         %Variable{id: 15, name: "Elrond"},
         %Variable{id: 16, name: "Galadriel"},
         %Variable{id: 17, name: "Faramir"},
         %Variable{id: 18, name: "Boromir"},
         %Variable{id: 19, name: "The Balrog"},
         %Variable{id: 20, name: "Ents"},
         %Variable{id: 21, name: "Rivendell"},
         %Variable{id: 22, name: "Isengard"},
         %Variable{id: 23, name: "The Ringwraiths"}
       ],
       votes: [
         %Vote{voter_id: 1, id: 2},
         %Vote{voter_id: 1, id: 4},
         %Vote{voter_id: 1, id: 6},
         %Vote{voter_id: 1, id: 8},
         %Vote{voter_id: 1, id: 10},
         %Vote{voter_id: 2, id: 3},
         %Vote{voter_id: 3, id: 5},
         %Vote{voter_id: 4, id: 7},
         %Vote{voter_id: 5, id: 9},
         %Vote{voter_id: 6, id: 11},
         %Vote{voter_id: 7, id: 12},
         %Vote{voter_id: 8, id: 13},
         %Vote{voter_id: 9, id: 14},
         %Vote{voter_id: 10, id: 15},
         %Vote{voter_id: 1, id: 2},
         %Vote{voter_id: 3, id: 6},
         %Vote{voter_id: 4, id: 8},
         %Vote{voter_id: 5, id: 9},
         %Vote{voter_id: 7, id: 12}
       ]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.variable_confirmation variables={@variables} votes={@votes} user_id={@user_id} />
    """
  end
end
