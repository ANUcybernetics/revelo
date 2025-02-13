defmodule ReveloWeb.SessionLive.RelationshipTableComponent do
  @moduledoc false
  use ReveloWeb, :live_component
  use Gettext, backend: ReveloWeb.Gettext

  import ReveloWeb.Component.Button
  import ReveloWeb.Component.Card
  import ReveloWeb.Component.Input
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
     |> assign(:relationship_count, 0)}
  end

  @impl true
  def update(assigns, socket) do
    relationships =
      Diagrams.list_potential_relationships!(assigns.session.id, include_hidden = true)

    IO.inspect(relationships, label: "relations")

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
                    <.button variant="outline" size="sm">Filter</.button>
                  </.dropdown_menu_trigger>
                  <.dropdown_menu_content align="end">
                    <.menu>
                      <.menu_group>
                        <.menu_item>All</.menu_item>
                        <.menu_item>Conflicting</.menu_item>
                        <.menu_item>Active</.menu_item>
                      </.menu_group>
                    </.menu>
                  </.dropdown_menu_content>
                </.dropdown_menu>
              </:actions>
            </.header>
          </.card_header>
          <.scroll_area class="h-20 grow rounded-md">
            <.card_content class="h-full">
              <.table class="text-base">
                <.table_header>
                  <.table_row>
                    <.table_head>Relation</.table_head>
                    <.table_head>Hide</.table_head>
                  </.table_row>
                </.table_header>
                <.table_body phx-update="stream">
                  <.table_row
                    :for={{id, relationship} <- @streams.relationships}
                    id={id}
                    class={if relationship.hidden?, do: "opacity-40"}
                  >
                    <.table_cell>
                      <div class="flex items-center gap-2">
                        <span>{relationship.src.name}</span>
                        <.icon name="hero-minus" class="h-4 w-4" />
                        <div class="flex flex-col items-center gap-1">
                          <.tooltip>
                            <tooltip_trigger>
                              <button class="bg-gray-200 flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200">
                                <div class="relative h-4 w-4 flex items-center justify-center">
                                  <.icon name="hero-arrow-long-up" class="h-4 w-4 transition-all" />
                                  <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-orange-300 text-orange-900 text-[0.6rem] flex items-center justify-center h-3 w-3">
                                    {relationship.reinforcing_votes}
                                  </div>
                                </div>
                                <span class="sr-only">
                                  Reinforcing Votes
                                </span>
                              </button>
                            </tooltip_trigger>
                            <.tooltip_content side="right">
                              Reinforcing Votes
                            </.tooltip_content>
                          </.tooltip>
                          <.tooltip>
                            <tooltip_trigger>
                              <button class="bg-gray-200 flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200">
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
                              <button class="bg-gray-200 flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200">
                                <div class="relative h-4 w-4 flex items-center justify-center">
                                  <.icon name="hero-arrows-up-down" class="h-4 w-4" />
                                  <div class="absolute -top-[0.4rem] -right-[0.4rem] rounded-full bg-blue-200 text-blue-900 text-[0.6rem] flex items-center justify-center h-3 w-3">
                                    {relationship.balancing_votes}
                                  </div>
                                </div>
                                <span class="sr-only">
                                  Balancing Votes
                                </span>
                              </button>
                            </tooltip_trigger>
                            <.tooltip_content side="right">
                              Balancing Votes
                            </.tooltip_content>
                          </.tooltip>
                        </div>
                        <.icon name="hero-arrow-long-right" class="h-4 w-4" />
                        <span>{relationship.dst.name}</span>
                      </div>
                    </.table_cell>
                    <.table_cell>
                      <button
                        phx-click="toggle_hidden"
                        phx-value-id={relationship.id}
                        phx-target={@myself}
                        class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200"
                      >
                        <.icon
                          name={if relationship.hidden?, do: "hero-eye-slash", else: "hero-eye-solid"}
                          class="h-4 w-4 transition-all"
                        />
                      </button>
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
  def handle_event("toggle_hidden", %{"id" => relationship_id}, socket) do
    updated_relationship = Diagrams.toggle_relationship_visibility!(relationship_id)
    {:noreply, stream_insert(socket, :relationships, updated_relationship)}
  end

  def get_phase(:identify_work), do: :identify
  def get_phase(:identify_discuss), do: :identify
  def get_phase(:relate_work), do: :relate
  def get_phase(:relate_discuss), do: :relate
  def get_phase(phase), do: phase
end
