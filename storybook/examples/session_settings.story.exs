defmodule Storybook.Examples.SessionSettings do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.Component.Card
  import ReveloWeb.Component.Form
  import ReveloWeb.Component.Textarea
  import ReveloWeb.CoreComponents

  defstruct [:id, :title, :description]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       current_id: 1,
       settings: %__MODULE__{
         id: 1,
         title: "Lord of the Rings",
         description:
           "The Shire is a peaceful agricultural region inhabited by hobbits, protected by rangers and natural boundaries. A magical ring of immense power has been kept there secretly for 60 years by Bilbo Baggins, then inherited by Frodo. The ring's original creator, Sauron, has regained strength and is actively searching for it, while his forces grow in neighboring regions. Local leadership and external allies (Gandalf) have identified this as an immediate threat to regional stability."
       }
     )}
  end

  def doc do
    "The main view with an editable system settings modal"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.card>
      <.card_header class="flex flex-row justify-between">
        <.card_title>System Settings</.card_title>
        <ReveloWeb.Component.Button.button
          phx-click={show_modal("session-modal")}
          type="button"
          variant="outline"
          size="sm"
          class="!mt-0"
        >
          <.icon name="hero-pencil-square-mini" class="h-4 w-4 mr-2 transition-all" /> Edit
        </ReveloWeb.Component.Button.button>
      </.card_header>
      <.card_content>
        <p><b>Title:</b> {@settings.title}
          <br /><br />
          {@settings.description}</p>
      </.card_content>
    </.card>

    <.modal id="session-modal">
      <div>
        <form phx-submit="save_settings" class="space-y-6">
          <div class="form_item">
            <.form_label>Title</.form_label>
            <ReveloWeb.Component.Input.input
              type="text"
              name="title"
              value={@settings.title}
              required
            />
            <.form_description>
              This is the title of your project.
            </.form_description>
          </div>

          <div class="form_item">
            <.form_label>Description/Context</.form_label>
            <.textarea name="description" value={@settings.description} />
            <.form_description>
              This is your project description.
            </.form_description>
          </div>

          <.button phx-click={hide_modal("session-modal")}>
            Save
          </.button>
        </form>
      </div>
    </.modal>
    """
  end

  @impl true
  def handle_event("save_settings", %{"title" => title, "description" => description}, socket) do
    updated_settings = %__MODULE__{
      id: socket.assigns.settings.id,
      title: title,
      description: description
    }

    {:noreply, assign(socket, settings: updated_settings)}
  end
end
