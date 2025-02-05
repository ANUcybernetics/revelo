defmodule ReveloWeb.SessionLive.Identify do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Diagrams

  @impl true
  def render(assigns) do
    ~H"""
    <div
      :if={@current_user |> Ash.load!(:anonymous?) |> Map.get(:anonymous?) == false}
      class="h-full flex flex-col"
    >
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
          url={"#{ReveloWeb.Endpoint.url()}/qr/sessions/#{@session.id}/relate"}
          participant_count={@participant_count}
          complete_url={"/sessions/#{@session.id}/relate"}
        />
      </div>
    </div>
    <div
      :if={@current_user |> Ash.load!(:anonymous?) |> Map.get(:anonymous?) == true}
      class="h-full flex flex-col items-center justify-center"
    >
      <div :if={@live_action in [:identify]} class="flex flex-col items-center gap-4">
        <.variable_voting variables={@variables} user={@current_user} />
        <.button type="submit" form="variable-voting-form" class="w-fit px-24" phx-submit="vote">
          Done
        </.button>
      </div>
      <div :if={@live_action in [:done]} class="flex flex-col items-center gap-4">
        <.variable_confirmation variables={@variables} user={@current_user} />
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
    variables = Diagrams.list_variables!(params["session_id"], true, actor: user)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{params["session_id"]}")
      ReveloWeb.Presence.track_participant(params["session_id"], user.id, :waiting)
    end

    socket =
      socket
      |> assign(:participant_count, {0, 1})
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:session, session)
      |> assign(:variables, variables)

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

    Enum.each(variable_ids, fn var_id ->
      checkbox_name = "var" <> var_id
      is_checked = Map.get(params, checkbox_name) == "true"

      variable = Enum.find(socket.assigns.variables, &(&1.id == var_id))
      has_vote = variable.voted?

      cond do
        is_checked and not has_vote ->
          Diagrams.variable_vote!(variable, actor: user)

        not is_checked and has_vote ->
          vote =
            Enum.find(
              Diagrams.list_variable_votes!(socket.assigns.session.id),
              &(&1.variable.id == var_id)
            )

          Diagrams.destroy_variable_vote!(vote, actor: user)

        true ->
          :ok
      end
    end)

    updated_variables = Diagrams.list_variables!(socket.assigns.session.id, true, actor: user)

    socket =
      socket
      |> assign(:variables, updated_variables)
      |> push_navigate(to: "/sessions/#{socket.assigns.session.id}/identify/done")

    {:noreply, socket}
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
