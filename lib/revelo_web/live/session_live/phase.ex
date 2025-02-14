defmodule ReveloWeb.SessionLive.Phase do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Sessions.Session

  @impl true
  def render(assigns) do
    ~H"""
    <div
      :if={@current_user.facilitator? and @live_action not in [:analyse]}
      class="p-6 h-full flex flex-col h-svh overflow-y-auto"
    >
      <div class="grid grid-cols-12 w-full grow gap-6">
        <.live_component
          :if={@live_action in [:prepare, :identify_discuss]}
          module={ReveloWeb.SessionLive.VariableTableComponent}
          id="variable-table"
          class={"#{if(@live_action == :prepare, do: "md:col-span-8", else: "md:col-span-12")} col-span-12"}
          current_user={@current_user}
          live_action={@live_action}
          session={@session}
          title={if @live_action == :prepare, do: "Prepare your variables", else: "Variable Votes"}
        />

        <.live_component
          :if={@live_action in [:relate_discuss]}
          module={ReveloWeb.SessionLive.RelationshipTableComponent}
          id="relationship-table"
          class="col-span-12"
          current_user={@current_user}
          live_action={@live_action}
          session={@session}
          title="Relationship Votes"
        />

        <div
          :if={@live_action in [:prepare, :new_variable]}
          class="flex gap-5 flex-col col-span-12 md:col-span-4"
        >
          <.session_details session={@session} variable_count={@variable_count} />
        </div>

        <.instructions
          :if={@live_action == :identify_work}
          title="Identify variables"
          class="col-span-12 lg:col-span-8"
        >
          <ol class="list-decimal px-6 space-y-6">
            <li>Scan the QR code with your phone camera.
              Note the variable of interest shown at the top (this is your main system outcome)</li>
            <li>
              Choose variables that are important parts of your system:
              <ul class="list-disc ml-8">
                <li>They may directly affect your variable of interest.</li>
                <li>They could relate to other important variables</li>
                <li>They may help tell your system's story</li>
              </ul>
            </li>
            <li>Click 'Done' when finished (we'll discuss your choices next)</li>
          </ol>
        </.instructions>

        <.instructions
          :if={@live_action == :relate_work}
          title="Identify relationships"
          class="col-span-12 lg:col-span-8"
        >
          <ol class="list-decimal px-6 space-y-6">
            <li>
              Look at each pair of variables and select which best describes the relationship:
              <ul class="list-disc ml-8">
                <li>As A increases, B increases (direct relationship)</li>
                <li>As A increases, B decreases (inverse relationship)</li>
                <li>A does not directly relate to B</li>
              </ul>
            </li>
            <li>
              Complete as many pairs as you can in 5 minutes.
            </li>
            <li>
              Your answer will automatically advance to the next pair. Use the Previous and Next buttons to review or change your answers. Tips for choosing:
              <ul class="list-disc ml-8">
                <li>Think about direct cause and effect</li>
                <li>Ignore indirect relationships through other variables</li>
              </ul>
            </li>
          </ol>
        </.instructions>

        <.qr_code_card
          :if={@live_action == :identify_work}
          url={"#{ReveloWeb.Endpoint.url()}/qr/sessions/#{@session.id}/identify/work"}
          completed={elem(@participant_count, 0)}
          total={elem(@participant_count, 1)}
          class="col-span-12 lg:col-span-4"
        />

        <.qr_code_card
          :if={@live_action == :relate_work}
          url={"#{ReveloWeb.Endpoint.url()}/qr/sessions/#{@session.id}/relate/work"}
          completed={elem(@participant_count, 0)}
          total={elem(@participant_count, 1)}
          class="col-span-12 lg:col-span-4"
        />
      </div>

      <div :if={@current_user.facilitator?} class="flex justify-between mt-4">
        <.button phx-click="phase_transition" phx-value-direction="previous">
          Previous Phase
        </.button>
        <.button phx-click="phase_transition" phx-value-direction="next">
          Next Phase
        </.button>
      </div>

      <.modal
        :if={@modal}
        id="variable-modal"
        show
        on_cancel={JS.patch(~p"/sessions/#{@session.id}/prepare")}
      >
        <.live_component
          module={ReveloWeb.SessionLive.VariableFormComponent}
          id="variable-modal-component"
          variable={@modal}
          title={@page_title}
          current_user={@current_user}
          action={@live_action}
          session={@session}
          patch={~p"/sessions/#{@session.id}/prepare"}
        />
      </.modal>

      <.modal
        :if={@live_action == :edit}
        id="edit-session-modal"
        show
        on_cancel={JS.patch(~p"/sessions/#{@session.id}/prepare/")}
      >
        <.live_component
          module={ReveloWeb.SessionLive.FormComponent}
          id={(@session && @session.id) || :edit}
          title={@page_title}
          current_user={@current_user}
          action={@live_action}
          session={@session}
          patch={~p"/sessions/#{@session.id}/prepare/"}
        />
      </.modal>
    </div>

    <div
      :if={!@current_user.facilitator? and @live_action not in [:analyse]}
      class="h-full flex flex-col items-center justify-center"
    >
      <div
        :if={@live_action in [:identify_work, :identify_discuss]}
        class="flex flex-col items-center gap-4"
      >
        <.live_component
          module={ReveloWeb.SessionLive.VariableVotingComponent}
          id="variable-voting"
          live_action={@live_action}
          current_user={@current_user}
          session={@session}
        />
      </div>
      <div :if={@live_action in [:relate_work]} class="flex flex-col items-center gap-4">
        <.live_component
          module={ReveloWeb.SessionLive.RelationshipVotingComponent}
          id="relationship-voting"
          live_action={@live_action}
          current_user={@current_user}
          session={@session}
          start_index={0}
          time_left={40}
        />
      </div>
      <div
        :if={@live_action not in [:identify_work, :identify_discuss, :relate_work, :analyse]}
        class="flex flex-col items-center gap-4"
      >
        <.task_completed completed={elem(@participant_count, 1)} total={elem(@participant_count, 1)} />
      </div>
    </div>

    <div :if={@live_action in [:analyse]} class="h-full flex flex-col items-center justify-center">
      <.live_component
        module={ReveloWeb.SessionLive.LoopTableComponent}
        id="loop-table"
        class="col-span-12"
        current_user={@current_user}
        live_action={@live_action}
        session={@session}
      />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("phase_transition", %{"direction" => direction}, socket) do
    session_id = socket.assigns.session.id
    Revelo.SessionServer.transition_to(session_id, String.to_existing_atom(direction))
    # TODO the facilitator could push patch immediately if they wanted
    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"session_id" => session_id} = params, _url, socket) do
    session = Ash.get!(Session, session_id)
    current_user = Ash.load!(socket.assigns.current_user, facilitator?: [session_id: session_id])

    # only track non-facilitator participants for "completion" tracking
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Revelo.PubSub, "session:#{session.id}")

      if not current_user.facilitator? do
        ReveloWeb.Presence.track_participant(session.id, current_user.id)
      end
    end

    modal =
      case params do
        %{"variable_id" => "new"} -> :new
        %{"variable_id" => variable_id} -> Ash.get!(Revelo.Diagrams.Variable, variable_id)
        _ -> false
      end

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:session, session)
      |> assign(:modal, modal)
      # :participant_count is a {completed, total} tuple
      |> assign(:participant_count, {0, 1})
      |> assign(:variable_count, 0)
      |> assign(:page_title, page_title(socket.assigns.live_action))

    {:noreply, socket}
  end

  @impl true
  def handle_info({ReveloWeb.SessionLive.FormComponent, {:saved, session}}, socket) do
    {:noreply, assign(socket, :session, session)}
  end

  @impl true
  def handle_info({ReveloWeb.SessionLive.VariableFormComponent, {:saved_variable, variable}}, socket) do
    if socket.assigns.variable_count == 0 and not variable.is_voi? do
      Revelo.Diagrams.toggle_voi!(variable)
    end

    send_update(ReveloWeb.SessionLive.VariableTableComponent,
      id: "variable-table",
      new_variable: Ash.reload!(variable)
    )

    {:noreply, assign(socket, :variable_count, socket.assigns.variable_count + 1)}
  end

  @impl true
  def handle_info({:tick, timer}, socket) do
    {:noreply, assign(socket, :timer, timer)}
  end

  @impl true
  def handle_info({:transition, phase}, socket) do
    path =
      case phase do
        :identify_work -> ~p"/sessions/#{socket.assigns.session.id}/identify/work"
        :identify_discuss -> ~p"/sessions/#{socket.assigns.session.id}/identify/discuss"
        :relate_work -> ~p"/sessions/#{socket.assigns.session.id}/relate/work"
        :relate_discuss -> ~p"/sessions/#{socket.assigns.session.id}/relate/discuss"
        :prepare -> ~p"/sessions/#{socket.assigns.session.id}/prepare"
        :analyse -> ~p"/sessions/#{socket.assigns.session.id}/analyse"
      end

    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def handle_info({:participant_count, counts}, socket) do
    {:noreply, assign(socket, :participant_count, counts)}
  end

  @impl true
  def handle_info({:increment_variable_count, amount}, socket) do
    {:noreply, assign(socket, :variable_count, socket.assigns.variable_count + amount)}
  end

  @impl true
  def handle_info(:decrement_variable_count, socket) do
    {:noreply, assign(socket, :variable_count, socket.assigns.variable_count - 1)}
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
