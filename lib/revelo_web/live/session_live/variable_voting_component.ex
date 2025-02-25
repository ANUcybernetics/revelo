defmodule ReveloWeb.SessionLive.VariableVotingComponent do
  @moduledoc false
  use ReveloWeb, :live_component

  import ReveloWeb.Component.Card
  import ReveloWeb.Component.Checkbox
  import ReveloWeb.Component.Label
  import ReveloWeb.Component.ScrollArea
  import ReveloWeb.UIComponents

  alias Revelo.Diagrams

  @impl true
  def mount(socket) do
    {:ok, assign(socket, completed?: false, variables: [])}
  end

  @impl true
  def update(assigns, socket) do
    variables =
      Diagrams.list_variables!(assigns.session.id, false, actor: assigns.current_user)

    voi =
      case Diagrams.get_voi(assigns.session.id) do
        {:ok, key} -> key
        {:error, _} -> nil
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:voi, voi)
      |> assign(:variables, variables)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl w-md min-w-[80svw] h-full p-5 pb-2 flex flex-col">
      <.card class="overflow-hidden grow flex flex-col">
        <.card_header>
          <.card_title>
            <%= if @completed? do %>
              Your Variable Votes
            <% else %>
              Which of these are important parts of your system?
            <% end %>
          </.card_title>
        </.card_header>

        <.card_content class="border-b-[1px] border-gray-300 pb-2 mx-2 px-4">
          <div class="flex justify-between w-full items-center">
            <span :if={@voi}>
              {@voi.name}
            </span>
            <.badge_key />
          </div>
        </.card_content>

        <.scroll_area class="overflow-y-auto h-72 grow shrink">
          <%= if @completed? do %>
            <.card_content id={"summary-#{@id}"} class="p-0">
              <%= for variable <- Enum.sort_by(@variables, & &1.voted?, :desc) do %>
                <%= if !variable.is_voi? do %>
                  <div class="flex items-center justify-between py-8 px-6 gap-2 text-sm font-semibold">
                    <span>{variable.name}</span>
                    <%= if variable.voted? do %>
                      <.badge_vote />
                    <% else %>
                      <.badge_no_vote />
                    <% end %>
                  </div>
                <% end %>
              <% end %>
            </.card_content>
          <% else %>
            <.card_content id={"voting-#{@id}"} class="p-0">
              <%= for variable <- @variables do %>
                <%= if !variable.is_voi? do %>
                  <.label id={variable.id} for={"#{variable.id}-checkbox"}>
                    <div class="flex items-center py-8 px-6 gap-2 has-[input:checked]:bg-muted">
                      <.checkbox
                        id={"#{variable.id}-checkbox"}
                        value={variable.voted?}
                        phx-click="vote"
                        phx-value-id={variable.id}
                        phx-target={@myself}
                      />
                      {variable.name}
                    </div>
                  </.label>
                <% end %>
              <% end %>
            </.card_content>
          <% end %>
        </.scroll_area>
      </.card>
      <div class="mt-4 flex justify-center w-full">
        <%= if @completed? do %>
          <.button class="w-fit px-24" phx-click="back" phx-target={@myself}>
            Back
          </.button>
        <% else %>
          <.button class="w-fit px-24" phx-click="done" phx-target={@myself}>
            Done
          </.button>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("vote", %{"id" => variable_id}, socket) do
    voter = socket.assigns.current_user
    variable = Ash.get!(Diagrams.Variable, variable_id, load: :voted?, actor: voter)

    if variable.voted? do
      Diagrams.VariableVote
      |> Ash.get!(
        variable_id: variable_id,
        voter_id: voter.id
      )
      |> Diagrams.destroy_variable_vote!()
    else
      Diagrams.variable_vote!(variable, actor: voter)
    end

    updated_variable = Ash.load!(variable, :voted?, actor: voter)

    variables =
      Enum.map(socket.assigns.variables, fn var ->
        if var.id == updated_variable.id, do: updated_variable, else: var
      end)

    {:noreply, assign(socket, :variables, variables)}
  end

  @impl true
  def handle_event("done", _params, socket) do
    ReveloWeb.Presence.update_status(
      socket.assigns.session.id,
      socket.assigns.current_user.id,
      true
    )

    {:noreply, assign(socket, :completed?, true)}
  end

  @impl true
  def handle_event("back", _params, socket) do
    {:noreply, assign(socket, :completed?, false)}
  end
end
