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
          :if={@live_action in [:prepare, :identify_discuss, :edit]}
          module={ReveloWeb.SessionLive.VariableTableComponent}
          id="variable-table"
          class={"#{if(@live_action in [:prepare, :edit], do: "md:col-span-8", else: "md:col-span-12")} col-span-12"}
          current_user={@current_user}
          live_action={@live_action}
          session={@session}
          title={
            if @live_action in [:prepare, :edit], do: "Prepare your variables", else: "Variable Votes"
          }
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
          :if={@live_action in [:prepare, :edit]}
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
            <li>Scan the QR code with your phone camera.</li>
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
              For each relationship shown, select which best describes the effect:
              <ul class="list-disc ml-8">
                <li>
                  <b>"to increase"</b>
                  - the first variable increasing causes the second variable to increase
                </li>
                <li>
                  <b>"to decrease"</b>
                  - the first variable increasing causes the second variable to decrease
                </li>
                <li>
                  <b>"no direct effect"</b> - the first variable does not directly affect the second
                </li>
              </ul>
            </li>
            <li>
              Use the arrow buttons at the bottom to navigate to the next page. Don't worry about completing every page - focus on getting through what you can. Tips for choosing:
              <ul class="list-disc ml-8">
                <li>Think about the direct cause and effect</li>
                <li>If you are unsure, choose 'no direct effect'</li>
              </ul>
            </li>
          </ol>
        </.instructions>

        <.qr_code_card
          :if={@live_action == :identify_work}
          url={"#{ReveloWeb.Endpoint.url()}/qr/sessions/#{@session.id}/identify/work"}
          completed={elem(@progress, 0)}
          total={elem(@progress, 1)}
          class="col-span-12 lg:col-span-4"
        />

        <.qr_code_card
          :if={@live_action == :relate_work}
          url={"#{ReveloWeb.Endpoint.url()}/qr/sessions/#{@session.id}/relate/work"}
          completed={elem(@progress, 0)}
          total={elem(@progress, 1)}
          class="col-span-12 lg:col-span-4"
        />
      </div>

      <div :if={@current_user.facilitator?} class="flex justify-between mt-4">
        <div>
          <.link
            :if={@live_action not in [:prepare, :edit]}
            href={phase_to_path(previous_phase(@live_action), @session.id)}
          >
            <.button variant="outline">Previous Phase</.button>
          </.link>
        </div>
        <div>
          <.link href={phase_to_path(next_phase(@live_action), @session.id)}>
            <.button>Next Phase</.button>
          </.link>
        </div>
      </div>

      <.modal
        :if={@modal}
        id="variable-modal"
        show
        on_cancel={
          JS.patch(
            if @live_action == :identify_discuss,
              do: "#{ReveloWeb.Endpoint.url()}/sessions/#{@session.id}/identify/discuss",
              else: "#{ReveloWeb.Endpoint.url()}/sessions/#{@session.id}/prepare"
          )
        }
      >
        <.live_component
          module={ReveloWeb.SessionLive.VariableFormComponent}
          id="variable-modal-component"
          variable={@modal}
          current_user={@current_user}
          action={@live_action}
          session={@session}
          patch={phase_to_path(@live_action, @session.id)}
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
      :if={@live_action in [:identify_work, :relate_work, :analyse]}
      id="help-modal"
      phx-mounted={show_modal("help-modal")}
      phx-remove={hide_modal("help-modal")}
      data-cancel={JS.exec(JS.add_class("!hidden", to: "#help-modal"), "phx-remove")}
      class="relative z-50 !hidden"
    >
      <div
        id="help-modal-bg"
        class="bg-background/70 fixed inset-0 transition-opacity"
        aria-hidden="true"
        phx-click={toggle_help_modal()}
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby="help-modal-title"
        aria-describedby="help-modal-description"
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 py-8">
            <.focus_wrap
              id="help-modal-container"
              phx-window-keydown={toggle_help_modal()}
              phx-key="escape"
              phx-click-away={toggle_help_modal()}
              class="shadow-primary/10 relative hidden rounded-2xl bg-background p-14 shadow-lg border-[length:var(--border-thickness)] transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={toggle_help_modal()}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id="help-modal-content">
                <div :if={@live_action == :identify_work} class="space-y-4">
                  <h3 class="text-lg font-medium">Identifying Variables</h3>
                  <p>Choose which variables you think are important parts of this system:</p>
                  <ul class="list-disc ml-6 space-y-2">
                    <li>Tap a box to select that variable</li>
                    <li>Tap again to unselect</li>
                    <li>
                      Choose variables that directly affect the main outcome or tell the system's story
                    </li>
                    <li>Click "Done" when you've selected all your choices</li>
                  </ul>
                  <div class="flex items-center justify-center">
                    <img src="/images/variable.gif" />
                  </div>
                </div>

                <div :if={@live_action == :relate_work} class="space-y-4">
                  <h3 class="text-lg font-medium">Identifying Relationships</h3>
                  <p>For each pair of variables, select how they directly relate:</p>
                  <ul class="list-disc ml-6 space-y-2">
                    <li>Choose increase/decrease if there's a clear direct relationship</li>
                    <li>
                      Select "no direct effect" if you're unsure or the relationship is indirect
                    </li>
                    <li>Use Previous/Next buttons to review your choices</li>
                    <li>Don't worry if you can't complete all pairs</li>
                  </ul>
                </div>

                <div :if={@live_action == :analyse} class="space-y-4">
                  <h3 class="text-lg font-medium">Analyzing Feedback Loops</h3>
                  <p>This is where we see how everything connects!</p>
                  <ul class="list-disc ml-6 space-y-2">
                    <li>Each box shows a feedback loop found in your system</li>
                    <li>
                      Select a loop to read its story and discuss:
                      <ul class="list-disc pl-8">
                        <li>Does this match what happens in the real world?</li>
                        <li>
                          Is this a self-reinforcing cycle that keeps growing, or does it balance itself out?
                        </li>
                        <li>What factors might limit or prevent this loop from continuing?</li>
                        <li>How could you measure or observe this loop in action?</li>
                      </ul>
                    </li>
                  </ul>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>

    <div
      :if={!@current_user.facilitator? and @live_action not in [:analyse]}
      class="h-full flex flex-col items-center justify-center"
    >
      <div :if={@live_action in [:identify_work]} class="flex flex-col items-center gap-4 grow">
        <.live_component
          module={ReveloWeb.SessionLive.VariableVotingComponent}
          id="variable-voting"
          live_action={@live_action}
          current_user={@current_user}
          session={@session}
        />
      </div>
      <div :if={@live_action in [:relate_work]} class="flex flex-col items-center gap-4 grow">
        <.live_component
          module={ReveloWeb.SessionLive.RelationshipVotingComponent}
          id="relationship-voting"
          live_action={@live_action}
          current_user={@current_user}
          session={@session}
          start_index={0}
        />
      </div>
      <div
        :if={@live_action not in [:identify_work, :relate_work, :analyse]}
        class="flex flex-col items-center gap-4"
      >
        <.task_completed completed={elem(@progress, 1)} total={elem(@progress, 1)} />
      </div>
      <div
        :if={!@current_user.facilitator? and @live_action in [:identify_work, :relate_work]}
        class="flex justify-end items-start w-full pr-4 mb-2"
      >
        <button
          class="p-2"
          phx-click={
            JS.toggle_class("!hidden",
              to: "#help-modal",
              time: 200
            )
          }
        >
          <.icon name="hero-question-mark-circle-solid" class="w-8 h-8" />
        </button>
      </div>
    </div>

    <div
      :if={@live_action in [:analyse]}
      class={
        if @current_user.facilitator?,
          do: "h-full flex items-center justify-center",
          else: "h-full flex flex-col items-center justify-center"
      }
    >
      <.live_component
        module={ReveloWeb.SessionLive.LoopTableComponent}
        id="loop-table"
        current_user={@current_user}
        live_action={@live_action}
        session={@session}
      />
      <div
        :if={!@current_user.facilitator? and @live_action in [:analyse]}
        class="flex justify-end items-start w-full pr-4 mb-2"
      >
        <button
          class="p-2"
          phx-click={
            JS.toggle_class("!hidden",
              to: "#help-modal",
              time: 200
            )
          }
        >
          <.icon name="hero-question-mark-circle-solid" class="w-8 h-8" />
        </button>
      </div>
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
      |> assign(:progress, {0, 1})
      |> assign_new(:variable_count, fn -> 0 end)
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:timer, 0)

    current_phase = Revelo.SessionServer.get_phase(session.id)

    # Set phase and redirect non-facilitator to the current phase
    if current_user.facilitator? do
      if socket.assigns.live_action != current_phase do
        Revelo.SessionServer.transition_to(session_id, socket.assigns.live_action)
      end

      {:noreply, socket}
    else
      socket =
        if socket.assigns.live_action == current_phase do
          socket
        else
          path = phase_to_path(current_phase, socket.assigns.session.id)
          push_patch(socket, to: path)
        end

      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({ReveloWeb.SessionLive.FormComponent, {:saved, session}}, socket) do
    {:noreply, assign(socket, :session, session)}
  end

  @impl true
  def handle_info({ReveloWeb.SessionLive.VariableFormComponent, {:saved_variable, variable}}, socket) do
    send_update(ReveloWeb.SessionLive.VariableTableComponent,
      id: "variable-table",
      new_variable: Ash.reload!(variable)
    )

    {:noreply, assign(socket, :variable_count, socket.assigns.variable_count + 1)}
  end

  @impl true
  def handle_info({:tick, timer}, socket) do
    {:noreply, assign(socket, :timer, timer - 1)}
  end

  @impl true
  def handle_info({:transition, phase}, socket) do
    if socket.assigns.current_user.facilitator? do
      {:noreply, socket}
    else
      path = phase_to_path(phase, socket.assigns.session.id)
      {:noreply, push_patch(socket, to: path)}
    end
  end

  @impl true
  def handle_info({:progress, counts}, socket) do
    {:noreply, assign(socket, :progress, counts)}
  end

  @impl true
  def handle_info({:increment_variable_count, amount}, socket) do
    {:noreply, assign(socket, :variable_count, socket.assigns.variable_count + amount)}
  end

  @impl true
  def handle_info(:decrement_variable_count, socket) do
    {:noreply, assign(socket, :variable_count, socket.assigns.variable_count - 1)}
  end

  defp phase_to_path(phase, session_id) do
    case phase do
      :identify_work -> ~p"/sessions/#{session_id}/identify/work"
      :identify_discuss -> ~p"/sessions/#{session_id}/identify/discuss"
      :relate_work -> ~p"/sessions/#{session_id}/relate/work"
      :relate_discuss -> ~p"/sessions/#{session_id}/relate/discuss"
      :prepare -> ~p"/sessions/#{session_id}/prepare"
      :analyse -> ~p"/sessions/#{session_id}/analyse"
      :edit -> ~p"/sessions/#{session_id}/prepare/edit"
    end
  end

  defp next_phase(phase) do
    case phase do
      :prepare -> :identify_work
      :identify_work -> :identify_discuss
      :identify_discuss -> :relate_work
      :relate_work -> :relate_discuss
      :relate_discuss -> :analyse
      :analyse -> :analyse
      :edit -> :identify_work
    end
  end

  defp previous_phase(phase) do
    case phase do
      :prepare -> :prepare
      :identify_work -> :prepare
      :identify_discuss -> :identify_work
      :relate_work -> :identify_discuss
      :relate_discuss -> :relate_work
      :analyse -> :relate_discuss
      :edit -> :prepare
    end
  end

  def toggle_help_modal(js \\ %JS{}) do
    JS.toggle_class(js, "!hidden", to: "#help-modal")
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
