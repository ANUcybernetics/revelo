defmodule ReveloWeb.UIComponents do
  @moduledoc """
  Provides Revelo UI building blocks.
  """
  use Phoenix.Component
  use Gettext, backend: ReveloWeb.Gettext

  import ReveloWeb.Component.Badge
  import ReveloWeb.Component.Card
  import ReveloWeb.Component.Checkbox
  import ReveloWeb.Component.DropdownMenu
  import ReveloWeb.Component.Menu
  import ReveloWeb.Component.Progress
  import ReveloWeb.Component.ScrollArea
  import ReveloWeb.Component.Tooltip
  import ReveloWeb.CoreComponents

  alias Phoenix.LiveView.JS

  @doc """
  Renders the sidebar.

  """

  def sidebar(assigns) do
    ~H"""
    <aside class="fixed inset-y-0 left-0 z-10 hidden w-14 flex-col border-r bg-white sm:flex">
      <nav class="flex flex-col items-center gap-4 px-2 sm:py-5">
        <.dropdown_menu>
          <.dropdown_menu_trigger class="cursor-pointer group flex h-9 w-9 shrink-0 items-center justify-center gap-2 rounded-full bg-primary text-lg font-semibold text-primary-foreground md:h-8 md:w-8 md:text-base">
            <.icon name="hero-window-mini" class="h-4 w-4 transition-all group-hover:scale-110" />
            <span class="sr-only">Sessions</span>
          </.dropdown_menu_trigger>

          <.dropdown_menu_content side="right">
            <.menu class="w-56">
              <.menu_group>
                <.menu_item>
                  <.icon name="hero-plus" class="mr-2 h-4 w-4" />
                  <span>Add Session</span>
                </.menu_item>
                <.menu_item>
                  <.icon name="hero-eye" class="mr-2 h-4 w-4" />
                  <span>View All Sessions</span>
                </.menu_item>
              </.menu_group>
            </.menu>
          </.dropdown_menu_content>
        </.dropdown_menu>

        <.tooltip>
          <tooltip_trigger>
            <.link
              href="#"
              class={
                if @current_page == "prepare",
                  do:
                    "flex h-9 w-9 items-center justify-center rounded-lg bg-accent text-accent-foreground transition-colors hover:text-foreground md:h-8 md:w-8",
                  else:
                    "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
              }
            >
              <.icon
                name="hero-adjustments-horizontal-mini"
                class="h-4 w-4 transition-all group-hover:scale-110"
              />
              <span class="sr-only">
                Prepare
              </span>
            </.link>
          </tooltip_trigger>
          <.tooltip_content side="right">
            Prepare
          </.tooltip_content>
        </.tooltip>
        <.tooltip>
          <tooltip_trigger>
            <.link
              href="#"
              class={
                if @current_page == "identify",
                  do:
                    "flex h-9 w-9 items-center justify-center rounded-lg bg-accent text-accent-foreground transition-colors hover:text-foreground md:h-8 md:w-8",
                  else:
                    "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
              }
            >
              <.icon name="hero-queue-list-mini" class="h-4 w-4 transition-all group-hover:scale-110" />
              <span class="sr-only">
                Identify
              </span>
            </.link>
          </tooltip_trigger>
          <.tooltip_content side="right">
            Identify
          </.tooltip_content>
        </.tooltip>
        <.tooltip>
          <tooltip_trigger>
            <.link
              href="#"
              class={
                if @current_page == "relate",
                  do:
                    "flex h-9 w-9 items-center justify-center rounded-lg bg-accent text-accent-foreground transition-colors hover:text-foreground md:h-8 md:w-8",
                  else:
                    "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
              }
            >
              <.icon
                name="hero-arrows-right-left-mini"
                class="h-4 w-4 transition-all group-hover:scale-110"
              />
              <span class="sr-only">
                Relate
              </span>
            </.link>
          </tooltip_trigger>
          <.tooltip_content side="right">
            Relate
          </.tooltip_content>
        </.tooltip>
        <.tooltip>
          <tooltip_trigger>
            <.link
              href="#"
              class={
                if @current_page == "analyse",
                  do:
                    "flex h-9 w-9 items-center justify-center rounded-lg bg-accent text-accent-foreground transition-colors hover:text-foreground md:h-8 md:w-8",
                  else:
                    "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
              }
            >
              <.icon
                name="hero-arrow-path-rounded-square-mini"
                class="h-4 w-4 transition-all group-hover:scale-110"
              />
              <span class="sr-only">
                Analyse
              </span>
            </.link>
          </tooltip_trigger>
          <.tooltip_content side="right">
            Analyse
          </.tooltip_content>
        </.tooltip>
      </nav>
      <nav class="mt-auto flex flex-col items-center gap-4 px-2 sm:py-5">
        <.tooltip>
          <tooltip_trigger>
            <.link
              href="#"
              class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
            >
              <.icon
                name="hero-user-circle-mini"
                class="h-4 w-4 transition-all group-hover:scale-110"
              />
              <span class="sr-only">
                User
              </span>
            </.link>
          </tooltip_trigger>
          <.tooltip_content side="right">
            User
          </.tooltip_content>
        </.tooltip>
      </nav>
    </aside>
    """
  end

  @doc """
    The key variable badge

  """

  def badge_key(assigns) do
    ~H"""
    <.badge class="bg-sky-200 text-sky-950 hover:bg-sky-300">
      <.icon name="hero-key-mini" class="h-4 w-4 mr-1" /> Key Variable
    </.badge>
    """
  end

  @doc """
    The vote badges

  """

  def badge_vote(assigns) do
    ~H"""
    <.badge class="bg-emerald-200 text-emerald-900 hover:bg-emerald-300">
      <.icon name="hero-hand-thumb-up-mini" class="h-4 w-4 mr-1" /> Important
    </.badge>
    """
  end

  def badge_no_vote(assigns) do
    ~H"""
    <.badge class="bg-rose-200 text-rose-900 hover:bg-rose-300">
      <.icon name="hero-hand-thumb-down-mini" class="h-4 w-4 mr-1" /> Not Important
    </.badge>
    """
  end

  @doc """
    The feedback badges

  """

  def badge_reinforcing(assigns) do
    ~H"""
    <.badge class="bg-yellow-200 text-yellow-900 hover:bg-yellow-300">
      <.icon name="hero-arrows-pointing-out-mini" class="h-4 w-4 mr-1" /> Reinforcing
    </.badge>
    """
  end

  def badge_balancing(assigns) do
    ~H"""
    <.badge class="bg-fuchsia-200 text-fuchsia-900 hover:bg-fuchsia-300">
      <.icon name="hero-arrows-pointing-in-mini" class="h-4 w-4 mr-1" /> Balancing
    </.badge>
    """
  end

  @doc """
    The variable table action pane

  """

  def variable_actions(assigns) do
    ~H"""
    <div class="flex gap-2">
      <.tooltip>
        <tooltip_trigger>
          <button class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200 md:h-8 md:w-8">
            <.icon name="hero-pencil-square" class="h-4 w-4 transition-all" />
            <span class="sr-only">
              Edit
            </span>
          </button>
        </tooltip_trigger>
        <.tooltip_content side="top">
          Edit
        </.tooltip_content>
      </.tooltip>
      <.tooltip>
        <tooltip_trigger>
          <button class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200 md:h-8 md:w-8">
            <.icon
              name={if @is_key, do: "hero-key-solid", else: "hero-key"}
              class="h-4 w-4 transition-all"
            />
            <span class="sr-only">
              Make Key
            </span>
          </button>
        </tooltip_trigger>
        <.tooltip_content side="top">
          Make Key
        </.tooltip_content>
      </.tooltip>
      <.tooltip>
        <tooltip_trigger>
          <button
            class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200 md:h-8 md:w-8"
            phx-click="delete_variable"
            phx-value-id={@id}
          >
            <.icon name="hero-trash" class="h-4 w-4 transition-all" />
            <span class="sr-only">
              Delete
            </span>
          </button>
        </tooltip_trigger>
        <.tooltip_content side="top">
          Delete
        </.tooltip_content>
      </.tooltip>
    </div>
    """
  end

  @doc """
    The task completed page for mobile
  """

  def task_completed(assigns) do
    ~H"""
    <.card class="w-[350px]">
      <.card_header>
        <.card_title>Task Completed!</.card_title>
        <.card_description>Look at the main screen for next steps</.card_description>
      </.card_header>
      <.card_content>
        <div class="flex justify-between items-center space-x-4 flex-col text-gray-600">
          <.icon name="hero-tv-solid" class="h-32 w-32" />
        </div>
      </.card_content>
      <.card_footer class="flex flex-col items-center gap-2">
        <div>
          <span class="font-bold text-3xl">{@completed}/{@total}</span>
          <span>completed</span>
        </div>
        <.progress class="w-full h-2" value={round(@completed / @total * 100)} />
      </.card_footer>
    </.card>
    """
  end

  @doc """
    The variable voting page for mobile
  """

  def variable_voting(assigns) do
    ~H"""
    <.card class="w-[350px] overflow-hidden">
      <.card_header>
        <.card_title>Which of these are important parts of your system?</.card_title>
      </.card_header>

      <.card_content class="border-b-[1px] border-gray-300 pb-2 mx-2 px-4">
        <div class="flex justify-between w-full">
          <span>
            {Enum.at(@variables, @key_variable).name}
          </span>
          <.badge_key />
        </div>
      </.card_content>

      <.scroll_area class="h-72">
        <.card_content class="p-0">
          <%= for variable <- Enum.reject(@variables, fn v -> v.id == Enum.at(@variables, @key_variable).id end) do %>
            <.label for={"var" <> Integer.to_string(variable.id)}>
              <div class="flex items-center py-4 px-6 gap-2 has-[input:checked]:bg-gray-200">
                <.checkbox id={"var" <> Integer.to_string(variable.id)} />
                {variable.name}
              </div>
            </.label>
          <% end %>
        </.card_content>
      </.scroll_area>
    </.card>
    """
  end

  @doc """
    The variable confirmation page for mobile
  """

  def variable_confirmation(assigns) do
    ~H"""
    <.card class="w-[350px] overflow-hidden">
      <.card_header>
        <.card_title>Your Variable Votes</.card_title>
      </.card_header>

      <.card_content class="border-b-[1px] border-gray-300 pb-2 mx-2 px-4">
        <div class="flex justify-between w-full">
          <span>
            {Enum.find(@variables, fn variable -> variable.is_key? end).name}
          </span>
          <.badge_key />
        </div>
      </.card_content>

      <.scroll_area class="h-72">
        <.card_content class="p-0">
          <%= for variable <-
              Enum.reject(@variables, fn variable -> variable.is_key? end)
              |> Enum.sort_by(fn variable ->
                if Enum.find(@votes, fn vote -> vote.id == variable.id and vote.voter_id == @user_id end) do
                  0 # Voted items go to the top
                else
                  1 # Non-voted items go to the bottom
                end
              end) do %>
            <div class="flex items-center justify-between py-4 px-6 gap-2">
              <span>{variable.name}</span>
              <%= if Enum.find(@votes, fn vote ->
                  vote.id == variable.id and vote.voter_id == @user_id
                end) do %>
                <.badge_vote />
              <% else %>
                <.badge_no_vote />
              <% end %>
            </div>
          <% end %>
        </.card_content>
      </.scroll_area>
    </.card>
    """
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
