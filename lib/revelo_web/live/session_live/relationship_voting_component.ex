defmodule ReveloWeb.SessionLive.RelationshipVotingComponent do
  @moduledoc false
  use ReveloWeb, :live_component

  import ReveloWeb.Component.Card
  import ReveloWeb.Component.Label
  import ReveloWeb.Component.RadioGroup

  alias Revelo.Diagrams

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    # note, this is a zipper
    relationships =
      assigns.session.id
      |> Diagrams.list_potential_relationships!()
      |> ZipperList.from_list()

    socket =
      socket
      |> assign(assigns)
      |> assign(:relationships, relationships)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[350px] flex flex-col items-center gap-4">
      <.card class="overflow-hidden">
        <.card_header>
          <.card_title>Pick the most accurate relation</.card_title>
        </.card_header>
        <.card_content class="px-0 pb-0">
          <.radio_group
            :let={builder}
            name="relationship"
            class="gap-0 mb-6"
            value={@relationships.cursor.type}
          >
            <div class="p-6 flex items-center space-x-2 has-[input:checked]:bg-gray-200">
              <.radio_group_item
                builder={builder}
                value="balancing"
                id="balancing"
                phx-click="vote"
                phx-value-type="balancing"
                phx-target={@myself}
              />
              <.label for="balancing">
                As {@relationships.cursor.src.name} <b><em>increases</em></b>, {@relationships.cursor.dst.name} <b><em>decreases</em></b>.
              </.label>
            </div>
            <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-gray-200">
              <.radio_group_item
                builder={builder}
                value="reinforcing"
                id="reinforcing"
                phx-click="vote"
                phx-value-type="reinforcing"
                phx-target={@myself}
              />
              <.label for="reinforcing">
                As {@relationships.cursor.src.name} <b><em>increases</em></b>, {@relationships.cursor.dst.name} <b><em>increases</em></b>.
              </.label>
            </div>
            <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-gray-200">
              <.radio_group_item
                builder={builder}
                value="no_relationship"
                id="no_relationship"
                phx-click="vote"
                phx-value-type="no_relationship"
                phx-target={@myself}
              />
              <.label for="no_relationship">
                There is <b><em>no direct relationship</em></b>
                between {@relationships.cursor.src.name} and {@relationships.cursor.dst.name}.
              </.label>
            </div>
          </.radio_group>
        </.card_content>
      </.card>
      <.countdown
        type="both_buttons"
        time_left={40}
        initial_time={60}
        on_left_click="navigate_left"
        on_right_click="navigate_right"
        left_disabled={ZipperList.beginning?(@relationships)}
        right_disabled={ZipperList.end?(@relationships)}
        target={@myself}
      />
    </div>
    """
  end

  @impl true
  def handle_event("vote", %{"type" => type}, socket) do
    voter = socket.assigns.current_user
    relationship = socket.assigns.relationships.cursor
    type = String.to_existing_atom(type)

    Diagrams.relationship_vote!(relationship, type, actor: voter)

    Process.sleep(300)

    relationships =
      socket.assigns.relationships
      |> ZipperList.replace(Ash.load!(relationship, :voted?))
      |> ZipperList.right()

    {:noreply, assign(socket, :relationships, relationships)}
  end

  @impl true
  def handle_event("navigate_left", _params, socket) do
    {:noreply, update(socket, :relationships, &ZipperList.left/1)}
  end

  @impl true
  def handle_event("navigate_right", _params, socket) do
    {:noreply, update(socket, :relationships, &ZipperList.right/1)}
  end
end
