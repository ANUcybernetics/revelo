defmodule ReveloWeb.SessionLive.Phase do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Diagrams
  alias Revelo.LLM
  alias Revelo.Sessions.Session

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={@current_user.facilitator?} class="h-full flex flex-col">
      <div class="grid grid-cols-12 w-full grow gap-10">
        <.variable_table
          :if={@live_action in [:prepare, :identify_discuss]}
          class={"#{if(@live_action == :prepare, do: "md:col-span-8", else: "md:col-span-12")} col-span-12"}
          live_action={@live_action}
          session={@session}
          variable_count={assigns[:variable_count] || 10}
          variables={@variables}
          title={
            if @live_action == :prepare,
              do: "Prepare your variables",
              else: if(@show_variables, do: "Variable Votes", else: nil)
          }
        />

        <div
          :if={@live_action in [:prepare, :new_variable]}
          class="flex gap-5 flex-col col-span-12 md:col-span-4"
        >
          <.session_details session={@session} />
          <.session_start session={@session} variables={@variables} />
        </div>

        <.instructions
          :if={@live_action == :identify_work}
          title="Identify relationships"
          class="col-span-8"
        >
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
          :if={@live_action == :identify_work}
          url={"#{ReveloWeb.Endpoint.url()}/qr/sessions/#{@session.id}/identify/work"}
          participant_count={@participant_count}
          complete_url={"/sessions/#{@session.id}/identify/discuss"}
          class="col-span-4"
        />
      </div>

      <div>
        <.back :if={@live_action in [:prepare, :new_variable]} patch={~p"/sessions"}>
          Back to Sessions
        </.back>
        <.back :if={@live_action == :identify} patch={~p"/sessions/#{@session.id}/identify/work"}>
          Back to Voting
        </.back>
        <.back :if={@live_action == :identify} patch={~p"/sessions/#{@session.id}/prepare"}>
          Back to Prepare
        </.back>
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
          patch={~p"/sessions/#{@session.id}/identify/discuss"}
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

    <div :if={!@current_user.facilitator?} class="h-full flex flex-col items-center justify-center">
      <div :if={@live_action == :identify_work} class="flex flex-col items-center gap-4">
        <.variable_voting variables={@variables} user={@current_user} />
        <.button type="submit" form="variable-voting-form" class="w-fit px-24" phx-submit="vote">
          Done
        </.button>
      </div>
      <div :if={@live_action == :identify_discuss} class="flex flex-col items-center gap-4">
        <.variable_confirmation variables={@variables} user={@current_user} />
        <.link patch={"/sessions/#{@session.id}/identify/"}>
          <.button class="w-fit px-24">Back</.button>
        </.link>
      </div>
      <div
        :if={@live_action not in [:identify_work, :identify_discuss]}
        class="flex flex-col items-center gap-4"
      >
        <.task_completed completed={elem(@participant_count, 0)} total={elem(@participant_count, 1)} />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"session_id" => session_id} = params, _url, socket) do
    session = Ash.get!(Session, session_id)
    current_user = Ash.load!(socket.assigns.current_user, facilitator?: [session_id: session_id])

    variables =
      Diagrams.list_variables!(session_id, true, actor: current_user)

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
      |> assign(:variables, variables)
      |> assign(:show_variables, Map.get(params, "show_variables", false))
      |> assign(:modal, modal)
      |> assign(:participant_count, {0, 1})
      |> assign(:page_title, page_title(socket.assigns.live_action))

    {:noreply, socket}
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
      |> push_navigate(to: "/sessions/#{socket.assigns.session.id}/identify/discuss")

    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_variables", %{"count" => count}, socket) do
    %{session: session, current_user: actor, variables: existing_variables} = socket.assigns
    variable_names = Enum.map(existing_variables, & &1.name)
    key_variable = Enum.find(existing_variables, & &1.is_key?)

    case LLM.generate_variables(session.description, key_variable.name, count, variable_names) do
      {:ok, %LLM.VariableList{variables: var_list}} ->
        Enum.each(var_list, fn name ->
          Diagrams.create_variable!(name, session, actor: actor)
        end)

        variables = Diagrams.list_variables!(session.id, true)
        {:noreply, assign(socket, :variables, variables)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to generate variables")}
    end
  end

  @impl true
  def handle_event("toggle_hidden", %{"id" => variable_id}, socket) do
    updated_variable = Diagrams.toggle_variable_visibility!(variable_id)

    {:noreply,
     update(socket, :variables, fn vars ->
       Enum.map(vars, fn v ->
         if v.id == updated_variable.id, do: updated_variable, else: v
       end)
     end)}
  end

  @impl true
  def handle_event("toggle_key", %{"id" => variable_id}, socket) do
    _updated_variable = Diagrams.toggle_key_variable!(variable_id)

    {:noreply,
     update(socket, :variables, fn _vars ->
       Diagrams.list_variables!(socket.assigns.session.id, true)
     end)}
  end

  @impl true
  def handle_event("delete_variable", %{"id" => variable_id}, socket) do
    Diagrams.destroy_variable!(variable_id)

    {:noreply,
     update(socket, :variables, fn vars ->
       Enum.filter(vars, fn v -> v.id != variable_id end)
     end)}
  end

  @impl true
  def handle_info({ReveloWeb.SessionLive.FormComponent, {:saved, session}}, socket) do
    {:noreply, assign(socket, :session, session)}
  end

  @impl true
  def handle_info({ReveloWeb.SessionLive.VariableFormComponent, {:saved_variable, _variable}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:timer_update, total_count}, socket) do
    {:noreply, assign(socket, :time_remaining, total_count)}
  end

  @impl true
  def handle_info({:participant_count, counts}, socket) do
    {:noreply, assign(socket, :participant_count, counts)}
  end

  defp page_title(phase), do: "#{phase |> Atom.to_string() |> String.capitalize()} phase"
end
