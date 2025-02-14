defmodule ReveloWeb.SessionLive.VariableFormComponent do
  @moduledoc false
  use ReveloWeb, :live_component

  alias Revelo.Diagrams.Variable

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="mb-6">
        {@title}
      </.header>

      <.form
        :let={f}
        for={@form}
        id="session-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="w-full space-y-6"
      >
        <.form_item>
          <.form_label error={not Enum.empty?(f[:name].errors)}>Variable Name</.form_label>
          <.input field={@form[:name]} type="text" phx-debounce="500" required />
          <%= if f.source.type == :create do %>
            <.input type="hidden" field={@form[:is_voi?]} value="false" />
            <.input type="hidden" field={@form[:hidden?]} value="false" />
          <% end %>
          <.form_message field={f[:name]} />
        </.form_item>

        <.button type="submit" phx-disable-with="Saving...">
          {if f.source.type == :create, do: "Create", else: "Update"} Variable
        </.button>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"variable" => variable_params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, variable_params))}
  end

  # def handle_event("save", %{"session" => session_params}, socket) do
  #   case AshPhoenix.Form.submit(socket.assigns.form, params: session_params) do
  #     {:ok, session} ->
  #       notify_parent({:saved, session})

  #       socket =
  #         socket
  #         |> put_flash(:info, "Session #{socket.assigns.form.source.type}d successfully")
  #         |> push_patch(to: socket.assigns.patch)

  #       {:noreply, socket}

  #     {:error, form} ->
  #       {:noreply, assign(socket, form: form)}
  #   end
  # end

  def handle_event("save", %{"variable" => params}, socket) do
    form_params = Map.put(params, "session", socket.assigns.session)

    case AshPhoenix.Form.submit(socket.assigns.form, params: form_params) do
      {:ok, variable} ->
        notify_parent({:saved_variable, variable})

        socket =
          socket
          |> put_flash(:info, "Variable created successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save variable: #{inspect(changeset.errors)}")}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{variable: variable}} = socket) do
    form =
      if variable == :new do
        AshPhoenix.Form.for_create(
          Variable,
          :create,
          as: "variable",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_update(
          variable,
          :rename,
          as: "variable",
          actor: socket.assigns.current_user,
          params: %{name: variable.name}
        )
      end

    assign(socket, form: to_form(form))
  end
end
