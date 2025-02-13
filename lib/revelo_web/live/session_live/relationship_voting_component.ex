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
    # TODO Remove once hooked up
    Diagrams.enumerate_relationships(assigns.session)

    relationships = Diagrams.list_potential_relationships!(assigns.session.id)
    relationship = Ash.load!(Enum.at(relationships, assigns.start_index), votes: [voter: [:id]])

    current_vote = Enum.find(relationship.votes, &(&1.voter_id == assigns.current_user.id))

    socket =
      socket
      |> assign(assigns)
      |> assign(:relationships, relationships)
      |> assign(:relationship, relationship)
      |> assign(:current_vote, current_vote)

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
            value={@current_vote && Atom.to_string(@current_vote.type)}
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
                As {@relationship.src.name} <b><em>increases</em></b>, {@relationship.dst.name} <b><em>decreases</em></b>.
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
                As {@relationship.src.name} <b><em>increases</em></b>, {@relationship.dst.name} <b><em>increases</em></b>.
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
                between {@relationship.src.name} and {@relationship.dst.name}.
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
        left_disabled={@start_index == 0}
        right_disabled={@start_index >= length(@relationships) - 1}
        target={@myself}
      />
    </div>
    """
  end

  @impl true
  def handle_event("vote", %{"type" => type}, socket) do
    voter = socket.assigns.current_user
    relationship = socket.assigns.relationship
    type = String.to_existing_atom(type)

    Diagrams.relationship_vote!(relationship, type, actor: voter)

    Process.sleep(300)

    relationships = Diagrams.list_potential_relationships!(socket.assigns.session.id)
    next_index = socket.assigns.start_index + 1
    next_relationship = Ash.load!(Enum.at(relationships, next_index), votes: [voter: [:id]])
    next_vote = Enum.find(next_relationship.votes, &(&1.voter_id == voter.id))

    socket =
      socket
      |> assign(:start_index, next_index)
      |> assign(:relationship, next_relationship)
      |> assign(:current_vote, next_vote)

    {:noreply, socket}
  end

  @impl true
  def handle_event("navigate_left", _params, socket) do
    prev_index = max(0, socket.assigns.start_index - 1)

    prev_relationship =
      Ash.load!(Enum.at(socket.assigns.relationships, prev_index), votes: [voter: [:id]])

    prev_vote =
      Enum.find(prev_relationship.votes, &(&1.voter_id == socket.assigns.current_user.id))

    socket =
      socket
      |> assign(:start_index, prev_index)
      |> assign(:relationship, prev_relationship)
      |> assign(:current_vote, prev_vote)

    {:noreply, socket}
  end

  @impl true
  def handle_event("navigate_right", _params, socket) do
    next_index = min(length(socket.assigns.relationships) - 1, socket.assigns.start_index + 1)

    next_relationship =
      Ash.load!(Enum.at(socket.assigns.relationships, next_index), votes: [voter: [:id]])

    next_vote =
      Enum.find(next_relationship.votes, &(&1.voter_id == socket.assigns.current_user.id))

    socket =
      socket
      |> assign(:start_index, next_index)
      |> assign(:relationship, next_relationship)
      |> assign(:current_vote, next_vote)

    {:noreply, socket}
  end
end
