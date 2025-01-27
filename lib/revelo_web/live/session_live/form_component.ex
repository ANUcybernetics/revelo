defmodule ReveloWeb.SessionLive.FormComponent do
  @moduledoc false
  use ReveloWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage session records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="session-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= if @form.source.type == :create do %>
          <.input field={@form[:name]} type="text" label="Name" /><.input
            field={@form[:description]}
            type="text"
            label="Description"
          />
        <% end %>
        <%= if @form.source.type == :update do %>
        <% end %>

        <:actions>
          <.button phx-disable-with="Saving...">Save Session</.button>
        </:actions>
      </.simple_form>
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
