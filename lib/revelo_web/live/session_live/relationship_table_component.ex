defmodule ReveloWeb.SessionLive.RelationshipTableComponent do
  @moduledoc false
  use ReveloWeb, :live_component
  use Gettext, backend: ReveloWeb.Gettext

  import ReveloWeb.Component.Button
  import ReveloWeb.Component.Card
  import ReveloWeb.Component.ScrollArea
  import ReveloWeb.Component.Table
  import ReveloWeb.Component.Tooltip
  import ReveloWeb.CoreComponents
  import ReveloWeb.CoreComponents, except: [table: 1, button: 1, input: 1]

  alias Revelo.Diagrams

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> stream(:relationships, [])
     |> assign(:relationship_count, 0)
     |> assign(:current_filter, :active)}
  end

  @impl true
  def update(assigns, socket) do
    relationships =
      case socket.assigns[:current_filter] || :all do
        :all -> Diagrams.list_potential_relationships!(assigns.session.id)
        :conflicting -> Diagrams.list_conflicting_relationships!(assigns.session.id)
        :active -> Diagrams.list_actual_relationships!(assigns.session.id)
      end

    Revelo.Diagrams.rescan_loops!(assigns.session.id)
    loops = Diagrams.list_loops!(assigns.session.id)
    loop_count = Enum.count(loops)

    socket =
      socket
      |> assign(assigns)
      |> assign(:loops, loops)
      |> assign(:loop_count, loop_count)
      |> stream(:relationships, relationships, reset: true)

    {:ok, socket}
  end

  @doc """
  Renders the relationship table.
  """
  attr :session, :map, required: true, doc: "the session containing the relationships"
  attr :live_action, :atom, required: true, doc: "current live action"
  attr :class, :string, default: "", doc: "additional class to apply to the card"
  attr :title, :string, default: "Potential Relationships", doc: "optional title for the table"

  def render(assigns) do
    ~H"""
    <div class={["h-full w-full", @class] |> Enum.join(" ")}>
      <.card class="h-full">
        <div class="flex flex-col h-full">
          <.card_header class="w-full flex-none">
            <.header class="flex flex-row justify-between !items-start">
              <.card_title class="grow">{@title}</.card_title>
              <.card_description class="mt-1">Total Loops: {@loop_count}</.card_description>
              <:actions>
                <div class="flex gap-2">
                  <div class="relative w-60 h-8">
                    <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                      <.icon name="hero-magnifying-glass" class="h-4 w-4 text-gray-500" />
                    </div>
                    <.input
                      id="relationship-search"
                      type="text"
                      phx-keyup="search"
                      phx-target={@myself}
                      class="h-8 pl-10 pr-4 py-2 w-full text-xs bg-white rounded-md border border-gray-300 focus:ring-blue-500 focus:border-blue-500"
                      placeholder="Search relationships..."
                    />
                  </div>
                  <.button
                    variant="outline"
                    size="sm"
                    class="inline-block"
                    phx-click="refresh"
                    phx-target={@myself}
                  >
                    <.icon name="hero-arrow-path" class="h-4 w-4" />
                  </.button>
                  <.dropdown_menu>
                    <.dropdown_menu_trigger>
                      <.button variant="outline" size="sm">
                        <b class="mr-1">Filter:</b> {String.capitalize(to_string(@current_filter))}
                      </.button>
                    </.dropdown_menu_trigger>
                    <.dropdown_menu_content align="end">
                      <.menu>
                        <.menu_group>
                          <.menu_item
                            phx-click="set_filter"
                            phx-value-filter="all"
                            phx-target={@myself}
                          >
                            All
                          </.menu_item>
                          <.menu_item
                            phx-click="set_filter"
                            phx-value-filter="active"
                            phx-target={@myself}
                          >
                            Active
                          </.menu_item>
                          <.menu_item
                            phx-click="set_filter"
                            phx-value-filter="conflicting"
                            phx-target={@myself}
                          >
                            Conflicting
                          </.menu_item>
                        </.menu_group>
                      </.menu>
                    </.dropdown_menu_content>
                  </.dropdown_menu>
                </div>
              </:actions>
            </.header>
          </.card_header>
          <.scroll_area class="h-20 grow rounded-md">
            <.card_content class="h-full overflow-x-auto">
              <.table class="text-base">
                <.table_header>
                  <.table_row>
                    <.table_head>Relation</.table_head>
                  </.table_row>
                </.table_header>
                <.table_body phx-update="stream" id="relationship_table">
                  <.table_row :for={{id, relationship} <- @streams.relationships} id={id}>
                    <.table_cell>
                      <div class="flex items-center gap-2 items-start">
                        <span class="flex-[1_1_25%] text-right">{relationship.src.name}</span>
                        <.icon name="hero-minus" class="h-4 w-4" />
                        <div class="flex items-center gap-1">
                          <.tooltip>
                            <tooltip_trigger>
                              <button
                                phx-click="toggle_override"
                                phx-value-src_id={relationship.src_id}
                                phx-value-dst_id={relationship.dst_id}
                                phx-value-type="direct"
                                phx-target={@myself}
                                class={[
                                  "flex h-9 w-9 items-center justify-center rounded-lg transition-colors ",
                                  cond do
                                    relationship.type_override == :direct ||
                                        (relationship.type_override == nil &&
                                           relationship.type == :direct) ->
                                      "bg-orange-300 text-orange-900"

                                    true ->
                                      "text-muted-foreground hover:bg-muted hover:text-foreground"
                                  end
                                ]}
                              >
                                <div class="relative h-4 w-4 flex items-center justify-center">
                                  <div
                                    class="h-4 w-4 transition-all"
                                    style="mask: url('/images/direct.svg') no-repeat; -webkit-mask: url('/images/direct.svg') no-repeat; background-color: currentColor;"
                                  />
                                  <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-orange-200 text-orange-900 text-[0.6rem] flex items-center justify-center h-3 w-3">
                                    {relationship.direct_votes}
                                  </div>
                                </div>
                                <span class="sr-only">
                                  Direct Votes
                                </span>
                              </button>
                            </tooltip_trigger>
                            <.tooltip_content side="top">
                              Direct Votes
                            </.tooltip_content>
                          </.tooltip>
                          <.tooltip>
                            <tooltip_trigger>
                              <button
                                phx-click="toggle_override"
                                phx-value-src_id={relationship.src_id}
                                phx-value-dst_id={relationship.dst_id}
                                phx-value-type="no_relationship"
                                phx-target={@myself}
                                class={[
                                  "flex h-9 w-9 items-center justify-center rounded-lg transition-colors ",
                                  cond do
                                    relationship.type_override == :no_relationship ||
                                        (relationship.type_override == nil &&
                                           relationship.type == :no_relationship) ->
                                      "bg-gray-300 text-gray-700"

                                    true ->
                                      "text-muted-foreground hover:bg-muted hover:text-foreground"
                                  end
                                ]}
                              >
                                <div class="relative h-4 w-4 flex items-center justify-center">
                                  <.icon name="hero-no-symbol" class="h-4 w-4" />
                                  <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-gray-300 text-gray-700 text-[0.6rem] flex items-center justify-center h-3 w-3">
                                    {relationship.no_relationship_votes}
                                  </div>
                                </div>
                                <span class="sr-only">
                                  No Relationship Votes
                                </span>
                              </button>
                            </tooltip_trigger>
                            <.tooltip_content side="top">
                              No Relationship Votes
                            </.tooltip_content>
                          </.tooltip>
                          <.tooltip>
                            <tooltip_trigger>
                              <button
                                phx-click="toggle_override"
                                phx-value-src_id={relationship.src_id}
                                phx-value-dst_id={relationship.dst_id}
                                phx-value-type="inverse"
                                phx-target={@myself}
                                class={[
                                  "flex h-9 w-9 items-center justify-center rounded-lg transition-colors",
                                  cond do
                                    relationship.type_override == :inverse ||
                                        (relationship.type_override == nil &&
                                           relationship.type == :inverse) ->
                                      "bg-blue-300 text-blue-900"

                                    true ->
                                      "text-muted-foreground hover:bg-muted hover:text-foreground"
                                  end
                                ]}
                              >
                                <div class="relative h-4 w-4 flex items-center justify-center">
                                  <.icon name="hero-arrows-up-down" class="h-4 w-4" />
                                  <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-blue-200 text-blue-900 text-[0.6rem] flex items-center justify-center h-3 w-3">
                                    {relationship.inverse_votes}
                                  </div>
                                </div>
                                <span class="sr-only">
                                  Inverse Votes
                                </span>
                              </button>
                            </tooltip_trigger>
                            <.tooltip_content side="top">
                              Inverse Votes
                            </.tooltip_content>
                          </.tooltip>
                        </div>
                        <.icon name="hero-arrow-long-right" class="h-4 w-4" />
                        <span class="flex-[1_1_25%]">{relationship.dst.name}</span>
                      </div>
                    </.table_cell>
                  </.table_row>
                </.table_body>
              </.table>
            </.card_content>
          </.scroll_area>
        </div>
      </.card>
    </div>
    """
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

    Revelo.Diagrams.rescan_loops!(socket.assigns.session.id)
    loops = Diagrams.list_loops!(socket.assigns.session.id)
    loop_count = Enum.count(loops)

    {:noreply,
     socket
     |> assign(:loops, loops)
     |> assign(:loop_count, loop_count)
     |> stream_insert(:relationships, updated_relationship)}
  end

  @impl true
  def handle_event("set_filter", %{"filter" => filter}, socket) do
    filter_atom = String.to_existing_atom(filter)

    relationships =
      case filter_atom do
        :all -> Diagrams.list_potential_relationships!(socket.assigns.session.id)
        :conflicting -> Diagrams.list_conflicting_relationships!(socket.assigns.session.id)
        :active -> Diagrams.list_actual_relationships!(socket.assigns.session.id)
      end

    {:noreply,
     socket
     |> assign(:current_filter, filter_atom)
     |> stream(:relationships, relationships, reset: true)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    relationships =
      case socket.assigns.current_filter do
        :all -> Diagrams.list_potential_relationships!(socket.assigns.session.id)
        :conflicting -> Diagrams.list_conflicting_relationships!(socket.assigns.session.id)
        :active -> Diagrams.list_actual_relationships!(socket.assigns.session.id)
      end

    {:noreply, stream(socket, :relationships, relationships, reset: true)}
  end

  @impl true
  def handle_event("search", %{"value" => search_term}, socket) do
    search_term = search_term |> String.trim() |> String.downcase()

    # Retrieve the full list based on current filter
    all_relationships =
      case socket.assigns.current_filter do
        :all -> Diagrams.list_potential_relationships!(socket.assigns.session.id)
        :conflicting -> Diagrams.list_conflicting_relationships!(socket.assigns.session.id)
        :active -> Diagrams.list_actual_relationships!(socket.assigns.session.id)
      end

    # If search term is empty, show all relationships for the current filter
    filtered_relationships =
      if search_term == "" do
        all_relationships
      else
        # Filter relationships by source or destination names containing the search term
        Enum.filter(all_relationships, fn relationship ->
          src_name = String.downcase(relationship.src.name)
          dst_name = String.downcase(relationship.dst.name)

          String.contains?(src_name, search_term) || String.contains?(dst_name, search_term)
        end)
      end

    {:noreply, stream(socket, :relationships, filtered_relationships, reset: true)}
  end

  def get_phase(:identify_work), do: :identify
  def get_phase(:identify_discuss), do: :identify
  def get_phase(:relate_work), do: :relate
  def get_phase(:relate_discuss), do: :relate
  def get_phase(phase), do: phase
end
