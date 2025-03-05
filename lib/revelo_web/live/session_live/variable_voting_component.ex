defmodule ReveloWeb.SessionLive.VariableVotingComponent do
  @moduledoc false
  use ReveloWeb, :live_component

  alias Revelo.Diagrams

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(completed?: false)
     |> stream(:variables, [])}
  end

  @impl true
  def update(assigns, socket) do
    variables =
      Diagrams.list_variables!(assigns.session.id, false, actor: assigns.current_user)

    socket =
      socket
      |> assign(assigns)
      |> stream(:variables, variables, reset: true)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl w-md w-svw h-full p-5 pb-2 flex flex-col">
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

        <.scroll_area class="overflow-y-auto h-72 grow shrink w-full">
          <.card_content
            id={"variables-#{@id}"}
            class="p-0"
            phx-update="stream"
            phx-hook-stream="variables"
          >
            <.label
              :for={{id, variable} <- @streams.variables}
              id={id}
              for={!@completed? && "#{variable.id}-checkbox"}
            >
              <div class={[
                "flex items-center py-8 px-6 gap-2",
                !@completed? && "has-[input:checked]:bg-muted",
                @completed? && "justify-between text-sm font-semibold"
              ]}>
                <%= if !@completed? do %>
                  <.checkbox
                    id={"#{variable.id}-checkbox"}
                    value={variable.user_vote}
                    phx-click="vote"
                    phx-value-id={variable.id}
                    phx-target={@myself}
                  />
                <% end %>
                <span>{variable.name}</span>
                <%= if @completed? do %>
                  <%= if variable.user_vote do %>
                    <.badge_vote />
                  <% else %>
                    <.badge_no_vote />
                  <% end %>
                <% end %>
              </div>
            </.label>
          </.card_content>
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
    variable = Ash.get!(Diagrams.Variable, variable_id, load: :user_vote, actor: voter)

    if variable.user_vote do
      Diagrams.VariableVote
      |> Ash.get!(
        variable_id: variable_id,
        voter_id: voter.id
      )
      |> Diagrams.destroy_variable_vote!()
    else
      Diagrams.variable_vote!(variable, actor: voter)
    end

    updated_variable = Ash.load!(variable, :user_vote, actor: voter)

    {:noreply, stream_insert(socket, :variables, updated_variable)}
  end

  @impl true
  def handle_event("done", _params, socket) do
    ReveloWeb.Presence.update_identify_status(
      socket.assigns.session.id,
      socket.assigns.current_user.id,
      true
    )

    # Get variables and reset the stream with sorted variables
    variables =
      socket.assigns.session.id
      |> Diagrams.list_variables!(false,
        actor: socket.assigns.current_user
      )
      |> Enum.sort_by(& &1.user_vote, :desc)

    {:noreply,
     socket
     |> assign(:completed?, true)
     |> stream(:variables, variables, reset: true)}
  end

  @impl true
  def handle_event("back", _params, socket) do
    # Get variables without sorting
    variables =
      Diagrams.list_variables!(socket.assigns.session.id, false, actor: socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:completed?, false)
     |> stream(:variables, variables, reset: true)}
  end
end
