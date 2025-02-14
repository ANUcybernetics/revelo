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
     |> assign(:current_filter, :all)}
  end

  @impl true
  def update(assigns, socket) do
    relationships =
      case socket.assigns[:current_filter] || :all do
        :all -> Diagrams.list_potential_relationships!(assigns.session.id)
        :conflicting -> Diagrams.list_conflicting_relationships!(socket.assigns.session.id)
      end

    socket =
      socket
      |> assign(assigns)
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
              <:actions>
                <.dropdown_menu>
                  <.dropdown_menu_trigger>
                    <.button variant="outline" size="sm">
                      <b class="mr-1">Filter:</b> {String.capitalize(to_string(@current_filter))}
                    </.button>
                  </.dropdown_menu_trigger>
                  <.dropdown_menu_content align="end">
                    <.menu>
                      <.menu_group>
                        <.menu_item phx-click="set_filter" phx-value-filter="all" phx-target={@myself}>
                          All
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
                <.table_body phx-update="stream">
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
                                  "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground",
                                  cond do
                                    relationship.type_override == :direct ||
                                        (relationship.type_override == nil &&
                                           relationship.type == :direct) ->
                                      "bg-orange-300"

                                    true ->
                                      "hover:bg-gray-200"
                                  end
                                ]}
                              >
                                <div class="relative h-4 w-4 flex items-center justify-center">
                                  <.icon name="hero-arrow-long-up" class="h-4 w-4 transition-all" />
                                  <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-orange-300 text-orange-900 text-[0.6rem] flex items-center justify-center h-3 w-3">
                                    {relationship.direct_votes}
                                  </div>
                                </div>
                                <span class="sr-only">
                                  Direct Votes
                                </span>
                              </button>
                            </tooltip_trigger>
                            <.tooltip_content side="right">
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
                                  "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground",
                                  cond do
                                    relationship.type_override == :no_relationship ||
                                        (relationship.type_override == nil &&
                                           relationship.type == :no_relationship) ->
                                      "bg-gray-300"

                                    true ->
                                      "hover:bg-gray-200"
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
                            <.tooltip_content side="right">
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
                                  "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground",
                                  cond do
                                    relationship.type_override == :inverse ||
                                        (relationship.type_override == nil &&
                                           relationship.type == :inverse) ->
                                      "bg-blue-300"

                                    true ->
                                      "hover:bg-gray-200"
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
                            <.tooltip_content side="right">
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

    new_override = if relationship.type_override == type, do: nil, else: type
    updated_relationship = Diagrams.override_relationship_type!(relationship, new_override)

    {:noreply, stream_insert(socket, :relationships, updated_relationship)}
  end

  @impl true
  def handle_event("set_filter", %{"filter" => filter}, socket) do
    filter_atom = String.to_existing_atom(filter)

    relationships =
      case filter_atom do
        :all -> Diagrams.list_potential_relationships!(socket.assigns.session.id)
        :conflicting -> Diagrams.list_conflicting_relationships!(socket.assigns.session.id)
      end

    {:noreply,
     socket
     |> assign(:current_filter, filter_atom)
     |> stream(:relationships, relationships, reset: true)}
  end

  def get_phase(:identify_work), do: :identify
  def get_phase(:identify_discuss), do: :identify
  def get_phase(:relate_work), do: :relate
  def get_phase(:relate_discuss), do: :relate
  def get_phase(phase), do: phase
end
