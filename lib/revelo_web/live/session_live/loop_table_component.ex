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
    variables = Diagrams.list_variables!(assigns.session.id, false)
    relationships = Diagrams.list_actual_relationships!(assigns.session.id)
    loop_count = Enum.count(loops)

    socket =
      socket
      |> assign(assigns)
      |> assign(:loops, loops)
      |> assign(:variables, variables)
      |> assign(:relationships, relationships)
      |> assign(:loop_count, loop_count)
      |> assign_new(:selected_loop, fn -> nil end)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_loop", %{"id" => id}, socket) do
    selected_loop = if socket.assigns.selected_loop == id, do: nil, else: id
    socket = assign(socket, :selected_loop, selected_loop)
    {:noreply, socket}
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
    <.card_header :if={@participant_view?} class="py-2">
      <.card_title class="flex py-6">
        <div class="shrink-0 flex justify-end w-6 mr-1">{loop_index}.</div>
        {matching_loop.title}
      </.card_title>
      <%!-- <div class="mx-6">
        <.badge_reinforcing :if={Atom.to_string(matching_loop.type) == "reinforcing"} />
        <.badge_balancing :if={Atom.to_string(matching_loop.type) == "balancing"} />
      </div> --%>
    </.card_header>
    <.card_content class="mx-6">
      <div class="flex justify-between flex-col gap-2">
        <.card_description>
          {matching_loop.story}
        </.card_description>
        <div :if={@participant_view?}>
          <div class="flex -ml-8 gap-1 mt-4">
            <div class={
            "#{if matching_loop.influence_relationships |> List.last() |> Map.get(:type) == :direct, do: "text-orange-500 !border-orange-500", else: "text-blue-500 !border-blue-500"} border-[0.17rem] border-r-0 rounded-l-lg w-8 my-10 relative"
          }>
              <.icon
                name="hero-arrow-long-right-solid"
                class="h-8 w-8 absolute -top-[1.07rem] -right-[0.4rem]"
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
                          if(relationship.src.is_voi?, do: "pt-7 pb-5", else: "py-6")
                        ],
                        " "
                      )
                    }>
                      <div class="absolute top-1 left-1">
                        <.badge_key :if={relationship.src.is_voi?} />
                      </div>
                      <span class="text-center">{relationship.src.name}</span>
                    </.card_content>
                  </.card>

                  <%= if index < length(matching_loop.influence_relationships) - 1 do %>
                    <div class={
                      "#{if relationship.type == :direct, do: "text-orange-500", else: "text-blue-500"} w-full flex justify-center"
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
      <aside class="flex fixed inset-y-0 right-0 z-10 w-[350px] flex-col border-l bg-background h-full">
        {render_slot(@inner_block)}
      </aside>
    <% else %>
      <.card class="max-w-5xl w-md min-w-[80svw] h-20 grow flex flex-col overflow-y-auto">
        <%= if @selected_loop do %>
          <.loop_card selected_loop={@selected_loop} loops={@loops} participant_view?={true}>
          </.loop_card>
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
    <div class={[
      "flex flex-col gap-4 grow h-full",
      !@current_user.facilitator? && "p-5 pb-2"
    ]}>

      <%= if @current_user.facilitator? do %>
        <div
          id="plot-loops"
          phx-hook="PlotLoops"
          phx-update="ignore"
          class="h-full w-[calc(100%-350px)]"
          data-elements={
            Jason.encode!(
              Enum.concat(
                Enum.map(@variables, fn var ->
                  %{group: "nodes", data: %{id: var.id, label: var.name, isKey: var.is_voi?}}
                end),
                Enum.map(@relationships, fn rel ->
                  %{
                    group: "edges",
                    data: %{
                      source: rel.src_id,
                      target: rel.dst_id,
                      relation: Atom.to_string(rel.type),
                      id: rel.id
                    }
                  }
                end)
              )
            )
          }
          data-selected-loop={@selected_loop}
          data-loops={
            Jason.encode!(
              Enum.map(@loops, fn loop ->
                %{
                  id: loop.id,
                  title: loop.title,
                  story: loop.story,
                  type: loop.type,
                  influence_relationships:
                    Enum.map(loop.influence_relationships, fn rel ->
                      %{
                        id: rel.id,
                        src: %{
                          id: rel.src_id,
                          name: rel.src.name,
                          is_voi?: rel.src.is_voi?
                        },
                        dst: %{
                          id: rel.dst_id,
                          name: rel.dst.name,
                          is_voi?: rel.dst.is_voi?
                        },
                        type: rel.type
                      }
                    end)
                }
              end)
            )
          }
        >
        </div>
      <% end %>
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

        <nav class="flex flex-col h-2 grow">
          <div class="h-full overflow-y-auto">
            <%= for {loop, index} <- Enum.with_index(@loops) do %>
              <button
                phx-click="toggle_loop"
                phx-target={@myself}
                phx-value-id={loop.id}
                class="w-full px-6 py-4 text-left border-t hover:bg-muted transition-colors"
              >
                <div class="flex items-start">
                  <span class="w-6 shrink-0">{index + 1}.</span>
                  <span class="flex-1 mr-2">
                  {loop.title} [{Enum.count(loop.influence_relationships)}]
                  </span>
                </div>
                <%!-- <div class="ml-6 mt-3">
                  <.badge_reinforcing :if={Atom.to_string(loop.type) == "reinforcing"} />
                  <.badge_balancing :if={Atom.to_string(loop.type) == "balancing"} />
                </div> --%>
              </button>
              <%= if loop.id == @selected_loop do %>
                <.loop_card selected_loop={@selected_loop} loops={@loops} participant_view?={false} />
              <% end %>
            <% end %>
          </div>
        </nav>
      </.loop_wrapper>
      <%= if !@current_user.facilitator? do %>
        <.button
          type="button"
          variant="outline"
          phx-click="unselect_loop"
          phx-target={@myself}
          disabled={is_nil(@selected_loop)}
        >
          Back
        </.button>
      <% end %>
    </div>
    """
  end
end
