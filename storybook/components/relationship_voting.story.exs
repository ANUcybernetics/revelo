defmodule Storybook.Examples.RelationshipVoting do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.UIComponents

  def doc do
    "The main relationship selection interface (for a participant)"
  end

  defstruct [:id, :name, :is_voi?]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       variable1: %__MODULE__{id: 2, name: "The size of assembled Orc armies", is_voi?: false},
       variable2: %__MODULE__{id: 3, name: "Sauron's Power Over Middle-earth", is_voi?: false}
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.relationship_voting variable1={@variable1} variable2={@variable2} />
    """
  end
end
