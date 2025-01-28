defmodule Storybook.Examples.LoopNav do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.UIComponents

  def doc do
    "The loop navigation menu for the facilitator"
  end

  defstruct [:id, :title, :type, :description]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       selected_loop: nil,
       loops: [
         %__MODULE__{
           id: 1,
           title: "Power enables recruitment",
           type: "reinforcing",
           description:
             "In the realm of Middle-earth, Sauron's power surged, causing the assembly of massive Orc armies. With these formidable forces, Sauron extended his military control over territories, solidifying his dominance. As time marched on, Sauron's power, army size, and territorial control continued to reinforce each other, creating an unbreakable cycle of supremacy."
         },
         %__MODULE__{
           id: 2,
           title: "Strategic fortifications expand military reach",
           type: "balancing",
           description:
             "In the heart of Middle-earth, strategic fortifications rise like sentinels. These strongholds expand Sauron's reach by balancing defense with resource gathering, creating stability that counters threats predictably while maintaining control."
         }
       ]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scale-[1] h-[500px] rounded border border-t-[30px] border-zinc-500">
      <div class="absolute -top-5 left-2 flex gap-2">
        <div class="rounded-full w-2 h-2 bg-zinc-300"></div>
        <div class="rounded-full w-2 h-2 bg-zinc-300"></div>
        <div class="rounded-full w-2 h-2 bg-zinc-300"></div>
      </div>
      <.loop_nav loops={@loops} selected_loop={@selected_loop} />
    </div>
    """
  end

  @impl true
  def handle_event("select_loop", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:noreply, assign(socket, :selected_loop, id)}
  end

  @impl true
  def handle_event("unselect_loop", %{"id" => _id}, socket) do
    {:noreply, assign(socket, :selected_loop, nil)}
  end
end
