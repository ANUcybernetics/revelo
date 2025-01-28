defmodule Variable do
  @moduledoc false
  defstruct [:id, :name, :is_key?]
end

defmodule Relationship do
  @moduledoc false
  defstruct [:src, :dst]
end

defmodule Storybook.Examples.Discussion do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.Component.Card
  import ReveloWeb.UIComponents

  def doc do
    "The discussion view and questions (for a participant)"
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       loop_id: 1,
       type: "reinforcing",
       variables: [
         %Variable{id: 1, name: "The One Ring", is_key?: true},
         %Variable{id: 2, name: "Frodo Baggins", is_key?: false},
         %Variable{id: 3, name: "Gandalf the Grey", is_key?: false},
         %Variable{id: 4, name: "Aragorn", is_key?: false},
         %Variable{id: 5, name: "Legolas", is_key?: false},
         %Variable{id: 6, name: "Gimli", is_key?: false}
       ],
       loop: [
         %Relationship{src: 1, dst: 2},
         %Relationship{src: 2, dst: 3},
         %Relationship{src: 3, dst: 1}
       ],
       title: "Power enables recruitment, yielding territorial dominance",
       description:
         "In the realm of Middle-earth, Sauron's power surged, causing the assembly of massive Orc armies. With these formidable forces, Sauron extended his military control over territories, solidifying his dominance. As time marched on, Sauron's power, army size, and territorial control continued to reinforce each other, creating an unbreakable cycle of supremacy."
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex gap-8">
      <.discussion
        loop_id={@loop_id}
        type={@type}
        variables={@variables}
        loop={@loop}
        title={@title}
        description={@description}
      />
      <.card class="w-[350px] h-fit">
        <.card_header>
          <.card_title>Discussion Questions</.card_title>
        </.card_header>
        <.card_content>
          <ol class="list-decimal pl-6 space-y-2">
            <li>
              Read through the loop and the story. Does it feel accurate to the actual dynamics? Why or why not?
            </li>
            <li>Do you think this is a virtuous, vicious, or neutral cycle?</li>
            <li>What other dynamics could stop this loop from continuing to grow stronger.</li>
            <li>How might you track whether this loop is occuring?</li>
          </ol>
        </.card_content>
      </.card>
    </div>
    """
  end
end
