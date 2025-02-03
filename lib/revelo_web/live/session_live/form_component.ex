defmodule ReveloWeb.SessionLive.FormComponent do
  @moduledoc false
  use ReveloWeb, :live_component

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
        <%= if @form.source.type == :create do %>
          <.form_item>
            <.form_label error={not Enum.empty?(f[:name].errors)}>Name</.form_label>
            <.input field={@form[:name]} type="text" phx-debounce="500" required />
            <.form_message field={f[:name]} />
          </.form_item>

          <.form_item>
            <.form_label error={not Enum.empty?(f[:description].errors)}>Description</.form_label>
            <.textarea
              name={f[:description].name}
              value={f[:description].value}
              placeholder="Session description"
              class="min-h-[200px]"
            />
            <.form_message field={f[:description]} />
          </.form_item>
        <% end %>

        <%= if @form.source.type == :update do %>
          <.form_item>
            <.form_label error={not Enum.empty?(f[:name].errors)}>Name</.form_label>
            <.input field={@form[:name]} type="text" phx-debounce="500" required />
            <.form_message field={f[:name]} />
          </.form_item>

          <.form_item>
            <.form_label error={not Enum.empty?(f[:description].errors)}>Description</.form_label>
            <.textarea
              name={f[:description].name}
              value={f[:description].value}
              placeholder="Session description"
              class="min-h-[200px]"
            />
            <.form_message field={f[:description]} />
          </.form_item>
        <% end %>

        <.button type="submit" phx-disable-with="Saving...">Save Session</.button>
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
  def handle_event("validate", %{"session" => session_params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, session_params))}
  end

  def handle_event("save", %{"session" => session_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: session_params) do
      {:ok, session} ->
        notify_parent({:saved, session})

        socket =
          socket
          |> put_flash(:info, "Session #{socket.assigns.form.source.type}d successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{session: session}} = socket) do
    form =
      if session do
        AshPhoenix.Form.for_update(session, :update,
          as: "session",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(Revelo.Sessions.Session, :create,
          as: "session",
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end
end
