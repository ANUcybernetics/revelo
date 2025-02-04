defmodule ReveloWeb.SessionLive.Prepare do
  @moduledoc false
  use ReveloWeb, :live_view

  alias Revelo.Diagrams
  alias Revelo.LLM
  alias Revelo.Sessions.Session

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col">
      <div class="grid grid-cols-12 w-full grow gap-10">
        <.variable_table
          class="md:col-span-8 col-span-12"
          session={@session}
          variable_count={@variable_count}
          variables={@variables}
        />

        <div class="flex gap-5 flex-col col-span-12 md:col-span-4">
          <.session_details session={@session} />
          <.session_start session={@session} variables={@variables} />
        </div>
      </div>

      <.modal
        :if={@live_action in [:new_variable, :edit_variable]}
        id="variable-modal"
        show
        on_cancel={JS.patch(~p"/sessions/#{@session.id}/prepare/")}
      >
        <.live_component
          module={ReveloWeb.SessionLive.VariableFormComponent}
          id={(@session && @session.id) || :edit}
          variable={@variable}
          title={@page_title}
          current_user={@current_user}
          action={@live_action}
          session={@session}
          patch={~p"/sessions/#{@session.id}/prepare/"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:edit]}
        id="session-modal"
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

      <.back navigate={~p"/sessions"}>Back to Sessions</.back>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(
       :sessions,
       Ash.read!(Session, actor: socket.assigns[:current_user])
     )
     |> assign_new(:current_user, fn -> nil end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    session = Ash.get!(Session, params["session_id"])
    variables = Diagrams.list_variables!(params["session_id"], true)

    socket =
      socket
      |> assign(:session, session)
      |> assign(:variables, variables)
      |> assign(:variable_count, 0)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    assign(socket, :page_title, "Edit Session")
  end

  defp apply_action(socket, :new_variable, _params) do
    socket
    |> assign(:page_title, "New Variable")
    |> assign(:variable, nil)
  end

  defp apply_action(socket, :edit_variable, params) do
    variable = Enum.find(socket.assigns.variables, &(&1.id == params["variable_id"]))

    socket
    |> assign(:page_title, "Edit Variable")
    |> assign(:variable, variable)
  end

  defp apply_action(socket, :prepare, _params) do
    assign(socket, :page_title, page_title(socket.assigns.live_action))
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
    updated_variable = Diagrams.toggle_key_variable!(variable_id)

    if updated_variable.is_key? do
      socket.assigns.variables
      |> Enum.filter(&(&1.id != updated_variable.id))
      |> Enum.filter(& &1.is_key?)
      |> Enum.each(fn var ->
        Diagrams.unset_key_variable!(var.id)
      end)
    end

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
    {:noreply, stream_insert(socket, :sessions, session)}
  end

  @impl true
  def handle_info({ReveloWeb.SessionLive.VariableFormComponent, {:saved_variable, session}}, socket) do
    {:noreply, stream_insert(socket, :sessions, session)}
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
