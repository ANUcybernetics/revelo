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
    {:ok, stream(socket, :variables, [])}
  end

  @impl true
  def update(assigns, socket) do
    variables =
      Diagrams.list_variables!(assigns.session.id, true, actor: assigns.current_user)

    key_variable =
      case Diagrams.get_key_variable(assigns.session.id) do
        {:ok, key} -> key
        {:error, _} -> nil
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:key_variable, key_variable)
      |> stream(:variables, variables, reset: true)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[350px]">
      <.card class="overflow-hidden">
        <.card_header>
          <.card_title>Which of these are important parts of your system?</.card_title>
        </.card_header>

        <.card_content class="border-b-[1px] border-gray-300 pb-2 mx-2 px-4">
          <div class="flex justify-between w-full items-center">
            <span :if={@key_variable}>
              {@key_variable.name}
            </span>
            <.badge_key />
          </div>
        </.card_content>

        <.scroll_area class="h-72">
          <.card_content id={@id} class="p-0" phx-update="stream">
            <%= for {id, variable} <- @streams.variables do %>
              <%= if !variable.is_key? do %>
                <.label id={id} for={"#{id}-checkbox"}>
                  <div class="flex items-center py-4 px-6 gap-2 has-[input:checked]:bg-gray-200">
                    <.checkbox
                      id={"#{id}-checkbox"}
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
        </.scroll_area>
      </.card>
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
    {:noreply, stream_insert(socket, :variables, updated_variable)}
  end
end
