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
      |> assign(:selected_loop, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_loop", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_loop, id)}
  end

  @impl true
  def handle_event("unselect_loop", _params, socket) do
    {:noreply, assign(socket, :selected_loop, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <aside class="fixed inset-y-0 right-0 z-10 w-[350px] flex-col border-l bg-white">
      <h3 class="text-2xl font-semibold leading-none tracking-tight flex p-6">
        Loops ({@loop_count})
      </h3>

      <%= if @selected_loop do %>
        <% matching_loop = Enum.find(@loops, &(&1.id == @selected_loop)) %>
        <% loop_index = Enum.find_index(@loops, &(&1.id == @selected_loop)) + 1 %>
        <div class="absolute top-18 z-20 w-[350px] right-full mr-6">
          <.card class="w-full">
            <.card_header class="pb-2">
              <.card_title class="flex">
                <div class="w-6 shrink-0">{loop_index}.</div>
                {matching_loop.title}
              </.card_title>
              <div class="mx-6 pt-2">
                <.badge_reinforcing :if={matching_loop.type == "reinforcing"} />
                <.badge_balancing :if={matching_loop.type == "balancing"} />
              </div>
            </.card_header>
            <.card_content class="mx-6">
              <div class="flex justify-between items-center space-x-4">
                <.card_description>
                  <%= for _rel <- matching_loop.influence_relationships do %>
                    <div>{matching_loop.story}</div>
                  <% end %>
                </.card_description>
              </div>
            </.card_content>
          </.card>
        </div>
      <% end %>

      <nav class="flex h-full flex-col">
        <div class="flex-1 overflow-y-auto">
          <%= for {loop, index} <- Enum.with_index(Ash.load!(@loops, influence_relationships: [:src])) do %>
            <button
              phx-click="select_loop"
              phx-target={@myself}
              phx-value-id={loop.id}
              phx-click-away="unselect_loop"
              class={
                Enum.join(
                  [
                    "w-full px-6 py-4 text-left border-b hover:bg-gray-50 transition-colors",
                    if(loop.id == @selected_loop, do: "bg-gray-100")
                  ],
                  " "
                )
              }
            >
              <div class="flex items-start">
                <span class="w-6 shrink-0">{index + 1}.</span>
                <span class="flex-1 mr-2">
                  <%= for rel <- loop.influence_relationships do %>
                    <div>{rel.src.name}</div>
                  <% end %>
                </span>
                <.badge_reinforcing :if={loop.type == "reinforcing"} />
                <.badge_balancing :if={loop.type == "balancing"} />
              </div>
            </button>
          <% end %>
        </div>
      </nav>
    </aside>
    """
  end
end
