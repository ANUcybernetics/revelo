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
    # these shenanigans are to ensure that the relationships are rotated and each participant
    # starts at a different, evenly-spaced location in the full list of potential relationships
    participants = ReveloWeb.Presence.list_online_participants(assigns.session.id)

    relationships =
      Diagrams.list_potential_relationships!(assigns.session.id, actor: assigns.current_user)

    # TODO Breaks if no relationships

    rotate_amount =
      case participants do
        [] ->
          0

        _ ->
          participants
          |> Enum.find_index(fn {id, _, _} -> id == assigns.current_user.id end)
          |> Kernel.*(length(participants))
          |> div(length(relationships))
      end

    relationships_zipper =
      relationships |> rotate(rotate_amount) |> ZipperList.from_list()

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:relationships, fn -> relationships_zipper end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl min-w-xs w-[80svw] flex flex-col items-center gap-4">
      <.card class="overflow-hidden w-full">
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
            <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-gray-200">
              <.radio_group_item
                builder={builder}
                value="inverse"
                id="inverse"
                checked={@relationships.cursor.voted? && @relationships.cursor.type == :inverse}
                phx-click="vote"
                phx-value-type="inverse"
                phx-target={@myself}
              />
              <.label for="inverse">
                As {@relationships.cursor.src.name} <b><em>increases</em></b>, {@relationships.cursor.dst.name} <b><em>decreases</em></b>.
              </.label>
            </div>
            <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-gray-200">
              <.radio_group_item
                builder={builder}
                value="direct"
                id="direct"
                checked={@relationships.cursor.voted? && @relationships.cursor.type == :direct}
                phx-click="vote"
                phx-value-type="direct"
                phx-target={@myself}
              />
              <.label for="direct">
                As {@relationships.cursor.src.name} <b><em>increases</em></b>, {@relationships.cursor.dst.name} <b><em>increases</em></b>.
              </.label>
            </div>
            <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-gray-200">
              <.radio_group_item
                builder={builder}
                value="no_relationship"
                id="no_relationship"
                checked={
                  @relationships.cursor.voted? && @relationships.cursor.type == :no_relationship
                }
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
        time_left={@time_left}
        initial_time={60}
        on_left_click="navigate_left"
        on_right_click="navigate_right"
        left_disabled={ZipperList.beginning?(@relationships)}
        right_disabled={length(@relationships.right) == 0}
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
      |> ZipperList.replace(Ash.load!(relationship, [:voted?, :type], actor: voter))
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

  defp rotate(list, n) when n >= 0 do
    {left, right} = Enum.split(list, rem(n, length(list)))
    right ++ left
  end
end
