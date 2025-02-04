defmodule ReveloWeb.SessionLive.Identify do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Diagrams

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col hidden md:block">
      <div class="grid grid-cols-5 w-full grow gap-10">
        <.instructions title="Identify relationships">
          <ol class="list-decimal p-10 space-y-12">
            <li>Scan the QR code with your phone camera.
              Note the key variable shown at the top (this is your main system outcome)</li>
            <li>
              Choose variables that are important parts of your system:
              <ul class="list-disc ml-8">
                <li>They may directly affect your key variable.</li>
                <li>They could relate to other important variables</li>
                <li>They may help tell your system's story</li>
              </ul>
            </li>
            <li>Click 'Done' when finished (we'll discuss your choices next)</li>
          </ol>
        </.instructions>

        <.qr_code_card
          url="https://www.youtube.com/watch?v=dQw4w9WgXcQ"
          participant_count={@participant_count}
          complete_url={"/sessions/#{@session.id}/relate"}
        />
      </div>
    </div>

    <div class="h-full flex flex-col md:hidden items-center justify-center">
      <div :if={@live_action in [:identify]} class="flex flex-col items-center gap-4">
        <.variable_voting variables={@variables} votes={@votes} user_id={@current_user.id} />
        <.button type="submit" form="variable-voting-form" class="w-fit px-24" phx-submit="vote">
          Done
        </.button>
      </div>
      <div :if={@live_action in [:done]} class="flex flex-col items-center gap-4">
        <.variable_confirmation variables={@variables} votes={@votes} user_id={@current_user.id} />
        <.link patch={"/sessions/#{@session.id}/identify/"}>
          <.button class="w-fit px-24">Back</.button>
        </.link>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    user = socket.assigns.current_user
    session = Ash.get!(Revelo.Sessions.Session, params["session_id"], actor: user)
    variables = Diagrams.list_variables!(params["session_id"], true)
    votes = Diagrams.list_variable_votes!(params["session_id"])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{params["session_id"]}")
      # ReveloWeb.Presence.track_participant(session_id, user.id, :waiting)
    end

    socket =
      socket
      |> assign(:participant_count, {0, 1})
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:session, session)
      |> assign(:variables, variables)
      |> assign(:votes, votes)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :identify, _params) do
    assign(socket, :page_title, "Identify Variables")
  end

  defp apply_action(socket, :done, _params) do
    assign(socket, :page_title, "Finished Voting")
  end

  @impl true
  def handle_info({:participant_count, counts}, socket) do
    {:noreply, assign(socket, :participant_count, counts)}
  end

  @impl true
  def handle_event("vote", params, socket) do
    user = socket.assigns.current_user

    variable_ids =
      socket.assigns.variables
      |> Enum.reject(& &1.is_key?)
      |> Enum.map(& &1.id)

    new_votes =
      Enum.reduce(variable_ids, socket.assigns.votes, fn var_id, votes ->
        checkbox_name = "var" <> var_id
        is_checked = Map.get(params, checkbox_name) == "true"

        IO.inspect(is_checked, label: "meme")

        has_vote =
          Enum.any?(votes, fn vote ->
            vote.variable_id == var_id && vote.voter_id == user.id
          end)

        cond do
          is_checked and not has_vote ->
            variable = Enum.find(socket.assigns.variables, &(&1.id == var_id))
            vote = Diagrams.variable_vote!(variable, actor: user)
            [vote | votes]

          not is_checked and has_vote ->
            vote =
              Enum.find(votes, fn vote ->
                vote.variable_id == var_id && vote.voter_id == user.id
              end)

            Diagrams.destroy_variable_vote!(vote, actor: user)
            Enum.reject(votes, &(&1.variable_id == vote.variable_id))

          true ->
            votes
        end
      end)

    socket =
      socket
      |> assign(:votes, new_votes)
      |> push_navigate(to: "/sessions/#{socket.assigns.session.id}/identify/done")

    {:noreply, socket}
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
