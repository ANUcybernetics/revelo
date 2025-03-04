defmodule ReveloWeb.SessionLive.LoopTableComponent do
  @moduledoc false
  use ReveloWeb, :live_component
  use Gettext, backend: ReveloWeb.Gettext

  import ReveloWeb.Component.Tooltip

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
      |> assign(:selected_edge, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("generate_stories", _params, socket) do
    tasks =
      Enum.map(socket.assigns.loops, fn loop ->
        Task.async(fn -> Diagrams.generate_loop_story!(loop) end)
      end)

    loops = Task.await_many(tasks)

    {:noreply, assign(socket, :loops, loops)}
  end

  @impl true
  def handle_event("edge_clicked", %{"id" => id}, socket) do
    # Find the relationship with the given ID
    relationship = Enum.find(socket.assigns.relationships, &(&1.id == id))
    {:noreply, assign(socket, :selected_edge, relationship)}
  end

  # Add a function to close the edge details
  @impl true
  def handle_event("close_edge_details", _params, socket) do
    {:noreply, assign(socket, :selected_edge, nil)}
  end

  @impl true
  def handle_event("toggle_override", %{"src_id" => src_id, "dst_id" => dst_id, "type" => type}, socket) do
    type = String.to_existing_atom(type)

    relationship = Ash.get!(Revelo.Diagrams.Relationship, src_id: src_id, dst_id: dst_id)

    new_override =
      cond do
        relationship.type_override == type -> nil
        relationship.type == type -> nil
        true -> type
      end

    updated_relationship = Diagrams.override_relationship_type!(relationship, new_override)

    # Re-fetch relationships to get updated state
    relationships = Diagrams.list_actual_relationships!(socket.assigns.session.id)

    # Update the selected edge with the updated relationship
    selected_edge = updated_relationship

    # Rescan loops after relationship update
    Revelo.Diagrams.rescan_loops!(socket.assigns.session.id)
    loops = Diagrams.list_loops!(socket.assigns.session.id)
    loop_count = Enum.count(loops)

    {:noreply,
     socket
     |> assign(:loops, loops)
     |> assign(:loop_count, loop_count)
     |> assign(:relationships, relationships)
     |> assign(:selected_edge, selected_edge)}
  end

  @impl true
  def handle_event("regenerate_loop_diagram", _params, socket) do
    # Rebuild the JSON data for loops and elements
    loops_json = create_loops_json(socket.assigns.loops)
    elements_json = create_elements_json(socket.assigns.variables, socket.assigns.relationships)

    # Send the updated data to the client
    {:noreply,
     push_event(socket, "update_loop_diagram", %{
       loops: loops_json,
       elements: elements_json
     })}
  end

  defp create_loops_json(loops) do
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
          <p class="text-sm text-gray-500">Relationship</p>
          <div class="flex justify-center items-center gap-2 mt-1 w-full">
            <span class="font-medium">{@relationship.src.name}</span>
            <.icon name="hero-arrow-long-right" class="h-4 w-4" />
            <span class="font-medium">{@relationship.dst.name}</span>
          </div>
        </div>

        <div>
          <p class="text-sm text-gray-500 mb-2">Current Type</p>
          <div class="flex items-center gap-3 justify-center">
            <.tooltip>
              <tooltip_trigger>
                <button
                  phx-click="toggle_override"
                  phx-value-src_id={@relationship.src_id}
                  phx-value-dst_id={@relationship.dst_id}
                  phx-value-type="direct"
                  phx-target={@myself}
                  class={[
                    "flex h-11 w-11 items-center justify-center rounded-lg transition-colors",
                    cond do
                      @relationship.type_override == :direct ||
                          (@relationship.type_override == nil &&
                             @relationship.type == :direct) ->
                        "bg-direct text-direct-foreground  border-[length:var(--border-thickness)] !border-inverse-foreground/50"

                      true ->
                        "text-muted-foreground hover:bg-muted hover:text-foreground"
                    end
                  ]}
                >
                  <div class="relative h-5 w-5 flex items-center justify-center">
                    <div
                      class="h-5 w-5 transition-all"
                      style="mask: url('/images/direct.svg') no-repeat; -webkit-mask: url('/images/direct.svg') no-repeat; background-color: currentColor;"
                    />
                    <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-direct-light text-direct-foreground text-[0.7rem] flex items-center justify-center h-4 w-4">
                      {@relationship.direct_votes}
                    </div>
                  </div>
                  <span class="sr-only">
                    Direct Votes
                  </span>
                </button>
              </tooltip_trigger>
              <.tooltip_content side="top">
                Direct Relationship
              </.tooltip_content>
            </.tooltip>

            <.tooltip>
              <tooltip_trigger>
                <button
                  phx-click="toggle_override"
                  phx-value-src_id={@relationship.src_id}
                  phx-value-dst_id={@relationship.dst_id}
                  phx-value-type="no_relationship"
                  phx-target={@myself}
                  class={[
                    "flex h-11 w-11 items-center justify-center rounded-lg transition-colors ",
                    cond do
                      @relationship.type_override == :no_relationship ||
                          (@relationship.type_override == nil &&
                             @relationship.type == :no_relationship) ->
                        "bg-gray-300 text-gray-700 border-[length:var(--border-thickness)] !border-gray-700/50"

                      true ->
                        "text-muted-foreground hover:bg-muted hover:text-foreground"
                    end
                  ]}
                >
                  <div class="relative h-5 w-5 flex items-center justify-center">
                    <.icon name="hero-no-symbol" class="h-5 w-5" />
                    <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-gray-300 text-gray-700 text-[0.7rem] flex items-center justify-center h-4 w-4">
                      {@relationship.no_relationship_votes}
                    </div>
                  </div>
                  <span class="sr-only">
                    No Relationship Votes
                  </span>
                </button>
              </tooltip_trigger>
              <.tooltip_content side="top">
                No Relationship
              </.tooltip_content>
            </.tooltip>

            <.tooltip>
              <tooltip_trigger>
                <button
                  phx-click="toggle_override"
                  phx-value-src_id={@relationship.src_id}
                  phx-value-dst_id={@relationship.dst_id}
                  phx-value-type="inverse"
                  phx-target={@myself}
                  class={[
                    "flex h-11 w-11 items-center justify-center rounded-lg transition-colors",
                    cond do
                      @relationship.type_override == :inverse ||
                          (@relationship.type_override == nil &&
                             @relationship.type == :inverse) ->
                        "bg-inverse text-inverse-foreground  border-[length:var(--border-thickness)] !border-inverse-foreground/50"

                      true ->
                        "text-muted-foreground hover:bg-muted hover:text-foreground"
                    end
                  ]}
                >
                  <div class="relative h-5 w-5 flex items-center justify-center">
                    <.icon name="hero-arrows-up-down" class="h-5 w-5" />
                    <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-inverse-light text-inverse-foreground text-[0.7rem] flex items-center justify-center h-4 w-4">
                      {@relationship.inverse_votes}
                    </div>
                  </div>
                  <span class="sr-only">
                    Inverse Votes
                  </span>
                </button>
              </tooltip_trigger>
              <.tooltip_content side="top">
                Inverse Relationship
              </.tooltip_content>
            </.tooltip>
          </div>
        </div>
      </div>
    </.modal>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="loop-table-component"
      phx-hook="LoopToggler"
      class="flex flex-col gap-4 grow h-full col-span-12"
    >
      <div
        id="plot-loops"
        phx-hook="PlotLoops"
        phx-update="ignore"
        data-target={@myself}
        class="h-full"
        style="width: calc(100% - 400px);"
        data-elements={create_elements_json(@variables, @relationships)}
        data-loops={create_loops_json(@loops)}
      >
      </div>

      <%= if @selected_edge do %>
        <.edge_details relationship={@selected_edge} myself={@myself} />
      <% end %>

      <aside
        id="resizable-sidebar"
        phx-hook="ResizableSidebar"
        phx-update="ignore"
        class="flex fixed inset-y-0 right-0 z-10 w-[400px] flex-col border-l-[length:var(--border-thickness)] bg-background h-full"
      >
        <div class="resize-handle absolute inset-y-0 left-0 w-2 cursor-ew-resize hover:bg-primary/10 active:bg-primary/20 z-20">
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
          <div class="h-full overflow-y-auto">
            <%= for {loop, index} <- Enum.with_index(@loops) do %>
              <button
                phx-click={JS.dispatch("toggle-loop", detail: %{loop_id: loop.id})}
                class="w-full px-6 py-4 text-left border-t-[length:var(--border-thickness)] hover:bg-muted transition-colors"
                data-loop-id={loop.id}
              >
                <div class="flex items-start">
                  <span class="w-6 shrink-0">{index + 1}.</span>
                  <div class="flex mr-2 justify-between gap-2 w-full">
                    <div>{loop.title}</div>
                    <div class="mt-1">
                      <.badge_length length={Enum.count(loop.influence_relationships)} />
                    </div>
                  </div>
                </div>
              </button>
              <div id={"loop-detail-facilitator-#{loop.id}"} class="hidden">
                <% matching_loop = Enum.find(@loops, &(&1.id == loop.id)) %>
                <.card_content class="mx-6">
                  <div class="flex justify-between flex-col gap-2">
                    <.card_description>
                      {matching_loop.story}
                    </.card_description>
                  </div>
                </.card_content>
              </div>
            <% end %>
          </div>
        </nav>
      </aside>
    </div>
    """
  end
end
