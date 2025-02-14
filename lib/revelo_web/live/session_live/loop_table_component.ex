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
  def handle_event("generate_stories", _params, socket) do
    loops =
      Enum.map(socket.assigns.loops, fn loop ->
        Diagrams.generate_loop_story!(loop)
      end)

    {:noreply, assign(socket, :loops, loops)}
  end

  def loop_card(assigns) do
    ~H"""
    <% matching_loop = Enum.find(@loops, &(&1.id == @selected_loop)) %>
    <% loop_index = Enum.find_index(@loops, &(&1.id == @selected_loop)) + 1 %>
    <.card_header class="pb-2">
      <.card_title class="flex">
        <div class="w-6 shrink-0">{loop_index}.</div>
        {matching_loop.title}
      </.card_title>
      <div class="mx-6 pt-2">
        <.badge_reinforcing :if={Atom.to_string(matching_loop.type) == "reinforcing"} />
        <.badge_balancing :if={Atom.to_string(matching_loop.type) == "balancing"} />
      </div>
    </.card_header>
    <.card_content class="mx-6">
      <div class="flex justify-between flex-col gap-2">
        <.card_description>
          {matching_loop.story}
        </.card_description>
        <div :if={@show_diagram}>
          <div class="flex -ml-8 gap-1">
            <div class={
            "#{if matching_loop.influence_relationships |> List.last() |> Map.get(:type) == :direct, do: "text-blue-500 !border-blue-500", else: "text-orange-500 !border-orange-500"} border-2 border-r-0 rounded-l-lg w-8 my-10 relative"
          }>
              <.icon
                name="hero-arrow-long-right-solid"
                class="h-8 w-8 absolute -top-[15px] -right-[6px]"
              />
            </div>
            <div class="flex flex-col mb-2 grow">
              <%= for {relationship, index} <- Enum.with_index(matching_loop.influence_relationships) do %>
                <div>
                  <.card class="w-full shadow-none relative">
                    <.card_content class={
                      Enum.join(
                        [
                          "flex justify-center items-center font-bold",
                          if(relationship.src.is_key?, do: "pt-7 pb-5", else: "py-6")
                        ],
                        " "
                      )
                    }>
                      <div class="absolute top-1 left-1">
                        <.badge_key :if={relationship.src.is_key?} />
                      </div>
                      <span class="text-center">{relationship.src.name}</span>
                    </.card_content>
                  </.card>

                  <%= if index < length(matching_loop.influence_relationships) - 1 do %>
                    <div class={
                      "#{if relationship.type == :direct, do: "text-blue-500", else: "text-orange-500"} w-full flex justify-center"
                    }>
                      <.icon name="hero-arrow-long-down-solid" class="h-8 w-8" />
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </.card_content>
    """
  end

  def loop_wrapper(assigns) do
    ~H"""
    <%= if @facilitator? do %>
      <aside class="fixed inset-y-0 right-0 z-10 w-[350px] flex-col border-l bg-white">
        {render_slot(@inner_block)}
      </aside>
    <% else %>
      <.card class="w-[350px]">
        <%= if @selected_loop do %>
          <.loop_card selected_loop={@selected_loop} loops={@loops} show_diagram={true}></.loop_card>
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </.card>
    <% end %>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <.loop_wrapper
        facilitator?={@current_user.facilitator?}
        selected_loop={@selected_loop}
        loops={@loops}
      >
        <div class="flex justify-between items-center p-6">
          <h3 class="text-2xl font-semibold leading-none tracking-tight flex">
            Loops ({@loop_count})
          </h3>
          <.button
            :if={@current_user.facilitator?}
            type="button"
            variant="outline"
            size="sm"
            phx-click="generate_stories"
            phx-target={@myself}
            id="generate_stories_button"
          >
            <.icon name="hero-sparkles" class="h-4 w-4 mr-2 transition-all" /> Generate
          </.button>
        </div>
        <%= if @selected_loop do %>
          <div class="absolute top-18 z-20 w-[350px] right-full mr-6">
            <.card class="w-full">
              <.loop_card selected_loop={@selected_loop} loops={@loops} show_diagram={false} />
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
                    {loop.title}
                  </span>
                  <.badge_reinforcing :if={loop.type == "reinforcing"} />
                  <.badge_balancing :if={loop.type == "balancing"} />
                </div>
              </button>
            <% end %>
          </div>
        </nav>
      </.loop_wrapper>
      <%= if !@current_user.facilitator? do %>
        <.countdown
          type="left_button"
          time_left={40}
          initial_time={60}
          on_left_click="unselect_loop"
          target={@myself}
          left_disabled={is_nil(@selected_loop)}
        />
      <% end %>
    </div>
    """
  end
end
