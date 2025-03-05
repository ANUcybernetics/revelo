defmodule ReveloWeb.SessionLive.LoopParticipantComponent do
  @moduledoc false
  use ReveloWeb, :live_component
  use Gettext, backend: ReveloWeb.Gettext

  alias Revelo.Diagrams

  @impl true
  def mount(socket) do
    {:ok, stream(socket, :loops, [])}
  end

  @impl true
  def update(assigns, socket) do
    loops = Diagrams.list_loops!(assigns.session.id)
    loop_count = Enum.count(loops)

    socket =
      socket
      |> assign(assigns)
      |> assign(:loop_count, loop_count)
      |> stream(:loops, loops, reset: true)

    {:ok, socket}
  end

  def loop_graph(assigns) do
    ~H"""
    <div class="flex -ml-8 gap-1 mt-4">
      <div class={
        "#{if @loop.influence_relationships |> List.last() |> Map.get(:type) == :direct, do: "text-direct !border-direct", else: "text-inverse !border-inverse"} border-[0.17rem] border-r-0 rounded-l-lg w-8 my-10 relative"
      }>
        <.icon
          name="hero-arrow-long-right-solid"
          class="h-8 w-8 absolute -top-[1.07rem] -right-[0.4rem]"
        />
      </div>
      <div class="flex flex-col mb-2 grow">
        <%= for {relationship, index} <- Enum.with_index(@loop.influence_relationships) do %>
          <div>
            <.card class="w-full shadow-none relative">
              <.card_content class="flex justify-center items-center font-bold py-6">
                <span class="text-center">{relationship.src.name}</span>
              </.card_content>
            </.card>

            <%= if index < length(@loop.influence_relationships) - 1 do %>
              <div class={
                "#{if relationship.type == :direct, do: "text-direct", else: "text-inverse"} w-full flex justify-center"
              }>
                <.icon name="hero-arrow-long-down-solid" class="h-8 w-8" />
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="loop-table-component"
      phx-hook="LoopToggler"
      class="flex flex-col gap-4 grow h-full p-5 pb-2"
    >
      <.card class="max-w-5xl w-md min-w-[80svw] h-20 grow flex flex-col overflow-y-auto">
        <div id="loop-list" class="flex flex-col overflow-y-auto grow">
          <div class="flex justify-between items-center p-6 gap-2" id="loop-header">
            <h3 class="text-2xl font-semibold leading-none tracking-tight flex">
              Loops ({@loop_count})
            </h3>
          </div>

          <nav class="flex flex-col grow">
            <ol id="loops-list" phx-update="stream" class="list-decimal h-full overflow-y-auto">
              <%= for {id, loop} <- @streams.loops do %>
                <button
                  id={id}
                  phx-click={JS.dispatch("toggle-loop", detail: %{loop_id: loop.id})}
                  class="w-full pr-6 py-4 text-left border-t-[length:var(--border-thickness)] hover:bg-muted transition-colors"
                  data-loop-id={loop.id}
                >
                  <li class="relative ml-10">
                    <div class="flex items-start pl-2">
                      <div class="flex mr-2 justify-between gap-2 w-full">
                        <div>{loop.title}</div>
                        <div class="mt-1">
                          <.badge_length length={Enum.count(loop.influence_relationships)} />
                        </div>
                      </div>
                    </div>
                  </li>
                </button>
                <div id={"loop-detail-#{loop.id}"} class="hidden h-full">
                  <.card_header class="py-2 mx-6">
                    <.card_title class="flex py-6">
                      {loop.title}
                    </.card_title>
                  </.card_header>
                  <.card_content class="mx-6">
                    <div class="flex justify-between flex-col gap-2">
                      <.card_description>
                        {loop.story}
                      </.card_description>
                      <div>
                        <.loop_graph loop={loop} />
                      </div>
                    </div>
                  </.card_content>
                </div>
              <% end %>
            </ol>
          </nav>
        </div>
      </.card>
      <.button
        type="button"
        variant="outline"
        phx-click={JS.dispatch("unselect-loop")}
        id="back-button"
        class="hidden"
      >
        Back
      </.button>
    </div>
    """
  end
end
