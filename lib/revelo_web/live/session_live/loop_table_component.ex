defmodule ReveloWeb.SessionLive.LoopTableComponent do
  @moduledoc false
  use ReveloWeb, :live_component
  use Gettext, backend: ReveloWeb.Gettext

  alias Revelo.Diagrams

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    loops = Diagrams.list_loops!(assigns.session.id)

    loop_count = Enum.count(loops)

    socket =
      socket
      |> assign(assigns)
      |> assign(:loops, loops)
      |> assign(:loop_count, loop_count)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="col-span-12">
      <h2>Total Loops: {@loop_count}</h2>
      <ol class="list-decimal space-y-4 mt-4">
        <li
          :for={loop <- Ash.load!(@loops, influence_relationships: [:src])}
          class="p-4 border rounded"
        >
          <ul class="list-disc list-inside space-y-2 ml-4">
            <li :for={rel <- loop.influence_relationships} class="text-gray-700">
              {rel.src.name}
            </li>
          </ul>
        </li>
      </ol>
    </div>
    """
  end
end
