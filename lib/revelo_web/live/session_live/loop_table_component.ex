defmodule ReveloWeb.SessionLive.LoopTableComponent do
  @moduledoc false
  use ReveloWeb, :live_component
  use Gettext, backend: ReveloWeb.Gettext

  import ReveloWeb.Component.DropdownMenu
  import ReveloWeb.Component.Tooltip

  alias Revelo.Diagrams
  alias Revelo.Diagrams.Relationship

  @impl true
  def mount(socket) do
    {:ok, stream(socket, :loops, [])}
  end

  @impl true
  def update(assigns, socket) do
    # Handle the specific case of a relationship update
    if Map.has_key?(assigns, :relationship) do
      updated_relationship = assigns.relationship

      # Ensure we have a session_id
      session_id = socket.assigns.session.id

      # Fetch fresh data - add these lines
      variables = socket.assigns.variables
      relationships = Diagrams.list_actual_relationships!(session_id)

      loops = Diagrams.list_loops!(session_id)
      loop_count = Enum.count(loops)

      loops_json = create_loops_json(loops)
      elements_json = create_elements_json(variables, relationships)

      {:ok,
       socket
       |> assign(:loops, loops)
       |> assign(:loop_count, loop_count)
       |> assign(:loops_json, loops_json)
       |> assign(:elements_json, elements_json)
       |> assign(:relationships, relationships)
       |> assign(:selected_edge, updated_relationship)
       |> stream(:loops, loops, reset: true)}
    else
      # Regular update
      loops = Diagrams.list_loops!(assigns.session.id)
      variables = Diagrams.list_variables!(assigns.session.id, false)
      relationships = Diagrams.list_actual_relationships!(assigns.session.id)
      loop_count = Enum.count(loops)

      loops_json = create_loops_json(loops)
      elements_json = create_elements_json(variables, relationships)

      socket =
        socket
        |> assign(assigns)
        |> assign(:variables, variables)
        |> assign(:relationships, relationships)
        |> assign(:loop_count, loop_count)
        |> assign(:selected_edge, nil)
        |> assign(:loops_json, loops_json)
        |> assign(:elements_json, elements_json)
        |> stream(:loops, loops, reset: true)

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("generate_stories", _params, socket) do
    # Get loops from Diagrams first
    loops = Diagrams.list_loops!(socket.assigns.session.id)

    tasks =
      Enum.map(loops, fn loop ->
        Task.async(fn -> Diagrams.generate_loop_story!(loop) end)
      end)

    loops = Task.await_many(tasks)
    loops_json = create_loops_json(loops)

    {:noreply,
     socket
     |> assign(:loops_json, loops_json)
     |> stream(:loops, loops, reset: true)}
  end

  @impl true
  def handle_event("edge_clicked", %{"id" => id}, socket) do
    relationship =
      Ash.get!(Relationship, id, load: [:type, :src, :dst, :direct_votes, :inverse_votes, :no_relationship_votes])

    {:noreply, assign(socket, :selected_edge, relationship)}
  end

  # Add a function to close the edge details
  @impl true
  def handle_event("close_edge_details", _params, socket) do
    {:noreply, assign(socket, :selected_edge, nil)}
  end

  @impl true
  def handle_event("regenerate_loop_diagram", _params, socket) do
    # Send the updated data to the client
    {:noreply,
     push_event(socket, "update_loop_diagram", %{
       loops: socket.assigns.loops_json,
       elements: socket.assigns.elements_json
     })}
  end


  defp create_loops_json(loops) when is_list(loops) do
    Jason.encode!(
      Enum.map(loops, fn loop ->
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
                  name: rel.src.name
                },
                dst: %{
                  id: rel.dst_id,
                  name: rel.dst.name
                },
                type: rel.type
              }
            end)
        }
      end)
    )
  end

  defp create_elements_json(variables, relationships) do
    Jason.encode!(
      Enum.concat(
        Enum.map(variables, fn var ->
          %{group: "nodes", data: %{id: var.id, label: var.name}}
        end),
        Enum.map(relationships, fn rel ->
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
  end

  def edge_details(assigns) do
    ~H"""
    <.modal id="edge-details-modal" show on_cancel={JS.push("close_edge_details", target: @myself)}>
      <div class="space-y-4">
        <div>
          <p class="text-sm text-gray-500 mb-2">Relationship</p>
          <div class="flex justify-center items-center mt-1 w-full">
            <.live_component
              module={ReveloWeb.SessionLive.RelationshipItemComponent}
              id={"relationship-item-" <> @relationship.id}
              relationship={@relationship}
            />
          </div>
        </div>
      </div>
    </.modal>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 grow h-full col-span-12">
      <div
        id="plot-loops"
        phx-hook="PlotLoops"
        phx-update="ignore"
        data-target={@myself}
        class="h-svh"
        style="width: calc(100% - 400px);"
        data-elements={@elements_json}
        data-loops={@loops_json}
      >
        <div class="absolute top-5 left-5 z-20 pointer-events-auto">
          <.dropdown_menu>
            <.dropdown_menu_trigger>
              <.button
                variant="outline"
                size="sm"
                class="bg-background hover:bg-muted transition-colors shadow-md"
              >
                View
              </.button>
            </.dropdown_menu_trigger>
            <.dropdown_menu_content>
              <.menu class="w-36">
                <.menu_group>
                  <.menu_item id="reset-positions-button" class="cursor-pointer">
                    <.icon name="hero-arrow-path" class="h-4 w-4 mr-2" />
                    <span class="text-xs">Reset Positions</span>
                  </.menu_item>
                </.menu_group>
              </.menu>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
      </div>

      <%= if @selected_edge do %>
        <.edge_details relationship={@selected_edge} myself={@myself} />
      <% end %>

      <aside
        class="flex fixed inset-y-0 right-0 z-10 w-[400px] flex-col border-l-[length:var(--border-thickness)] bg-background h-full"
        id="sidebar-container"
      >
        <div
          id="resizable-handle"
          phx-hook="ResizableSidebar"
          phx-update="ignore"
          class="resize-handle absolute inset-y-0 left-0 w-2 cursor-ew-resize hover:bg-primary/10 active:bg-primary/20 z-20"
        >
        </div>
        <div class="flex justify-between items-center p-6 gap-2">
          <h3 class="text-2xl font-semibold leading-none tracking-tight flex">
            Loops ({@loop_count})
          </h3>
          <.button
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
          <div class="h-full overflow-y-auto" id="loop-table-component" phx-hook="LoopToggler">
            <ol id="loops-list" phx-update="stream" class="list-decimal">
              <%= for {dom_id, loop} <- @streams.loops do %>
                <div id={dom_id} data-loop-id={loop.id}>
                  <button
                    phx-click={JS.dispatch("toggle-loop", detail: %{loop_id: loop.id})}
                    class="w-full px-6 py-4 text-left border-t-[length:var(--border-thickness)] hover:bg-muted transition-colors"
                  >
                    <li class="relative ml-4">
                      <div class="flex items-start">
                        <div class="flex mr-2 justify-between gap-2 w-full">
                          <div>{loop.title}</div>
                          <div class="mt-1">
                            <.badge_length length={Enum.count(loop.influence_relationships)} />
                          </div>
                        </div>
                      </div>
                    </li>
                  </button>
                  <div id={"loop-detail-facilitator-#{loop.id}"} class="hidden">
                    <.card_content class="mx-6">
                      <div class="flex justify-between flex-col gap-2">
                        <.card_description>
                          {loop.story}
                        </.card_description>
                      </div>
                    </.card_content>
                  </div>
                </div>
              <% end %>
            </ol>
          </div>
        </nav>
      </aside>
    </div>
    """
  end
end
