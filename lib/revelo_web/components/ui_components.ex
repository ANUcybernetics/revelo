defmodule ReveloWeb.UIComponents do
  @moduledoc """
  Provides Revelo UI building blocks.
  """
  use Phoenix.Component
  use Gettext, backend: ReveloWeb.Gettext

  import ReveloWeb.Component.Badge
  import ReveloWeb.Component.Button
  import ReveloWeb.Component.Card
  import ReveloWeb.Component.Checkbox
  import ReveloWeb.Component.DropdownMenu
  import ReveloWeb.Component.Menu
  import ReveloWeb.Component.Progress
  import ReveloWeb.Component.RadioGroup
  import ReveloWeb.Component.ScrollArea
  import ReveloWeb.Component.Tooltip
  import ReveloWeb.CoreComponents, except: [table: 1, button: 1, input: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Renders the sidebar.

  """

  def sidebar(assigns) do
    ~H"""
    <aside class="fixed inset-y-0 left-0 z-10 w-14 flex-col border-r-[length:var(--border-thickness)]  bg-background flex">
      <nav class="flex flex-col items-center gap-4 px-2 py-5">
        <.dropdown_menu>
          <.dropdown_menu_trigger class={
            Enum.join(
              [
                "cursor-pointer group flex h-9 w-9 shrink-0 items-center justify-center gap-2 rounded-full bg-primary text-lg font-semibold text-primary-foreground ",
                (@current_page == :index && "outline outline-background -outline-offset-4") || ""
              ],
              " "
            )
          }>
            <.icon name="hero-window-mini" class="h-4 w-4 transition-all group-hover:scale-110" />
            <span class="sr-only">Sessions</span>
          </.dropdown_menu_trigger>
          <.dropdown_menu_content side="right">
            <.menu class="w-56">
              <.menu_group>
                <.link navigate="/sessions/new">
                  <.menu_item class="cursor-pointer">
                    <.icon name="hero-plus" class="mr-2 h-4 w-4" />
                    <span>Add Session</span>
                  </.menu_item>
                </.link>
                <.link navigate="/sessions">
                  <.menu_item class="cursor-pointer">
                    <.icon name="hero-eye" class="mr-2 h-4 w-4" />
                    <span>View All Sessions</span>
                  </.menu_item>
                </.link>
              </.menu_group>
            </.menu>
          </.dropdown_menu_content>
        </.dropdown_menu>

        <%= if @session_id do %>
          <.tooltip :for={
            page <- [
              :prepare,
              :identify_work,
              :identify_discuss,
              :relate_work,
              :relate_discuss,
              :analyse
            ]
          }>
            <tooltip_trigger>
              <.link
                href={"/sessions/#{@session_id}/#{String.replace(to_string(page), "_", "/")}"}
                class={
                  Enum.join(
                    [
                      "flex h-9 w-9 items-center justify-center rounded-lg transition-colors  hover:text-foreground ",
                      if(@current_page == page,
                        do: "bg-accent text-foreground border-[length:var(--border-thickness)]",
                        else: "text-muted-foreground"
                      )
                    ],
                    " "
                  )
                }
              >
                <%= if String.split("#{page}", "_") |> Enum.at(1) == "work" do %>
                  <div class="relative">
                    <.icon
                      name={
                        sidebar_icon(String.to_atom(String.split("#{page}", "_") |> List.first()))
                      }
                      class="h-3 w-3 transition-all absolute top-[55%] -translate-y-1/2 left-1/2 -translate-x-1/2"
                    />
                    <.icon name="hero-clipboard" class="h-6 w-6 transition-all " />
                  </div>
                <% else %>
                  <.icon
                    name={sidebar_icon(String.to_atom(String.split("#{page}", "_") |> List.first()))}
                    class="h-4 w-4 transition-all"
                  />
                <% end %>
                <span class="sr-only">
                  {page
                  |> Atom.to_string()
                  |> String.split("_")
                  |> Enum.map(&String.capitalize/1)
                  |> Enum.join(" ")}
                </span>
              </.link>
            </tooltip_trigger>
            <.tooltip_content side="right">
              {page
              |> Atom.to_string()
              |> String.split("_")
              |> Enum.map(&String.capitalize/1)
              |> Enum.join(" ")}
            </.tooltip_content>
          </.tooltip>
        <% end %>
      </nav>
      <nav class="mt-auto flex flex-col items-center gap-4 px-2 cursor-pointer mb-4">
        <.tooltip>
          <.tooltip_trigger>
            <button
              phx-click={JS.dispatch("toggle-high-contrast")}
              class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground"
            >
              <div id="theme-icon-container">
                <.icon name="hero-moon" class="h-4 w-4 transition-all" />
                <.icon name="hero-sun" class="h-4 w-4 transition-all" />
              </div>
              <span class="sr-only">Toggle Contrast</span>
            </button>
          </.tooltip_trigger>
          <.tooltip_content side="right">
            Toggle Contrast
          </.tooltip_content>
        </.tooltip>
        <.dropdown_menu>
          <.dropdown_menu_trigger class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground">
            <.icon name="hero-user-circle-mini" class="h-4 w-4 transition-all group-hover:scale-110" />
            <span class="sr-only">User</span>
          </.dropdown_menu_trigger>
          <.dropdown_menu_content side="right">
            <.menu>
              <.menu_group>
                <.link navigate="/sign-out">
                  <.menu_item class="cursor-pointer">
                    <span>Sign out</span>
                  </.menu_item>
                </.link>
              </.menu_group>
            </.menu>
          </.dropdown_menu_content>
        </.dropdown_menu>
      </nav>
    </aside>
    """
  end

  def sidebar_icon(:prepare), do: "hero-adjustments-horizontal-mini"
  def sidebar_icon(:identify), do: "hero-queue-list-mini"
  def sidebar_icon(:relate), do: "hero-arrows-right-left-mini"
  def sidebar_icon(:analyse), do: "hero-arrow-path-rounded-square-mini"

  @doc """
    Loop length badge

  """

  def badge_length(assigns) do
    ~H"""
    <.badge class="bg-indigo-200 text-indigo-900 hover:bg-indigo-300 w-fit border-none shrink-0 h-fit">
      <.icon name="hero-arrow-path-rounded-square-mini" class="h-4 w-4 mr-1" /> {@length}
    </.badge>
    """
  end

  @doc """
    The vote badges

  """

  def badge_vote(assigns) do
    ~H"""
    <.badge class="bg-emerald-200 text-emerald-900 hover:bg-emerald-300 w-fit border-none shrink-0 h-fit">
      <.icon name="hero-hand-thumb-up-mini" class="h-4 w-4 mr-1" /> Important
    </.badge>
    """
  end

  def badge_no_vote(assigns) do
    ~H"""
    <.badge class="bg-rose-200 text-rose-900 hover:bg-rose-300 w-fit border-none shrink-0 h-fit">
      <.icon name="hero-hand-thumb-down-mini" class="h-4 w-4 mr-1" /> Not Important
    </.badge>
    """
  end

  @doc """
    The feedback badges

  """

  def badge_reinforcing(assigns) do
    ~H"""
    <.badge class="bg-yellow-200 text-yellow-900 hover:bg-yellow-300 w-fit border-none shrink-0 h-fit">
      <.icon name="hero-arrows-pointing-out-mini" class="h-4 w-4 mr-1" /> Reinforcing
    </.badge>
    """
  end

  def badge_balancing(assigns) do
    ~H"""
    <.badge class="bg-fuchsia-200 text-fuchsia-900 hover:bg-fuchsia-300 w-fit border-none shrink-0 h-fit">
      <.icon name="hero-arrows-pointing-in-mini" class="h-4 w-4 mr-1" /> Balancing
    </.badge>
    """
  end

  @doc """
    The task completed page for mobile
  """
  attr :completed, :integer, required: true, doc: "number of participants completed"
  attr :total, :integer, required: true, doc: "total number of participants"

  def task_completed(assigns) do
    ~H"""
    <.card class="max-w-5xl w-md min-w-[80svw] ">
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
    <.card class="max-w-5xl w-md min-w-[80svw]  overflow-hidden">
      <.card_header>
        <.card_title>Which of these are important parts of your system?</.card_title>
      </.card_header>

      <.scroll_area class="h-72">
        <.card_content class="p-0">
          <form phx-submit="vote" id="variable-voting-form">
            <%= for variable <- @variables do %>
              <.label for={"var" <> variable.id}>
                <div class="flex items-center py-4 px-6 gap-2 has-[input:checked]:bg-muted">
                  <.checkbox
                    id={"var" <> variable.id}
                    name={"var" <> variable.id}
                    value={variable.voted?}
                  />
                  {variable.name}
                </div>
              </.label>
            <% end %>
          </form>
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
    <.card class="max-w-5xl w-md min-w-[80svw]  overflow-hidden">
      <.card_header>
        <.card_title>Your Variable Votes</.card_title>
      </.card_header>

      <.scroll_area class="h-72">
        <.card_content class="p-0">
          <%= for variable <-
            @variables
              |> Enum.sort_by(fn variable ->
                if variable.voted? do
                  0 # Voted items go to the top
                else
                  1 # Non-voted items go to the bottom
                end
              end) do %>
            <div class="flex items-center justify-between py-4 px-6 gap-2 text-sm font-semibold">
              <span>{variable.name}</span>
              <%= if variable.voted? do %>
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
    The relationships page for mobile
  """

  def relationship_voting(assigns) do
    ~H"""
    <.card class="max-w-5xl w-md min-w-[80svw]  overflow-hidden">
      <.card_header>
        <.card_title>Pick the most accurate relation</.card_title>
      </.card_header>
      <.card_content class="px-0 pb-0">
        <.radio_group :let={builder} name="relationship" class="gap-0">
          <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-muted">
            <.radio_group_item builder={builder} value="decreases" id="decreases" />
            <.label for="decreases">
              As {@variable1.name} <b><em>increases</em></b>, {@variable2.name} <b><em>decreases</em></b>.
            </.label>
          </div>
          <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-muted">
            <.radio_group_item builder={builder} value="increases" id="increases" />
            <.label for="increases">
              As {@variable1.name} <b><em>increases</em></b>, {@variable2.name} <b><em>increases</em></b>.
            </.label>
          </div>
          <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-muted">
            <.radio_group_item builder={builder} value="none" id="none" />
            <.label for="none">
              There is <b><em>no direct relationship</em></b>
              between {@variable1.name} and {@variable2.name}.
            </.label>
          </div>
        </.radio_group>
      </.card_content>
    </.card>
    """
  end

  @doc """
  Renders a countdown timer component. The component shows a timer with optional
  navigation buttons and progress bar. It can be configured to show left, right,
  or both navigation buttons.
  """
  attr :time_left, :integer, required: true, doc: "remaining time in seconds"
  attr :initial_time, :integer, required: true, doc: "initial time in seconds"

  attr :type, :string,
    default: "none",
    doc: "button type - can be 'left_button', 'both_buttons' or 'none'"

  attr :target, :any, default: nil, doc: "the phx-target for button clicks"
  attr :on_left_click, :any, default: nil, doc: "the phx-click event for the left button"
  attr :on_right_click, :any, default: nil, doc: "the phx-click event for the right button"
  attr :left_disabled, :boolean, default: false, doc: "whether the left button is disabled"
  attr :right_disabled, :boolean, default: false, doc: "whether the right button is disabled"

  def countdown(assigns) do
    ~H"""
    <.card class={
      [
        "max-w-5xl w-md min-w-[80svw]  overflow-hidden",
        if(@time_left == 0, do: "bg-red-600 border-red-200 text-red-200")
      ]
      |> Enum.join(" ")
    }>
      <.card_content class="border-gray-300 p-0 flex justify-between items-center h-full">
        <%= if @type == "left_button" or @type == "both_buttons" do %>
          <ReveloWeb.Component.Button.button
            variant="outline"
            class="h-full border-0 border-r-[1px] rounded-none"
            phx-click={@on_left_click}
            disabled={@left_disabled}
            phx-target={@target}
          >
            <.icon name="hero-arrow-left" class="h-5 w-5" />
          </ReveloWeb.Component.Button.button>
        <% end %>
        <div class="p-6 flex grow justify-center items-center space-x-4 flex-col gap-2">
          <span class="text-2xl">
            <b>
              {Integer.to_string(div(@time_left, 60), 10) |> String.pad_leading(2, "0")}:{Integer.to_string(
                rem(@time_left, 60),
                10
              )
              |> String.pad_leading(2, "0")}
            </b>
            remaining
          </span>
          <.progress class="w-full h-2 !m-0" value={round(@time_left / @initial_time * 100)} />
        </div>
        <%= if @type == "both_buttons" do %>
          <ReveloWeb.Component.Button.button
            variant="outline"
            class="h-full border-0 border-l-[1px] rounded-none"
            phx-target={@target}
            phx-click={@on_right_click}
            disabled={@right_disabled}
          >
            <.icon name="hero-arrow-right" class="h-5 w-5" />
          </ReveloWeb.Component.Button.button>
        <% end %>
      </.card_content>
    </.card>
    """
  end

  @doc """
  Renders a pagination component. The component shows the current page and total pages with optional
  navigation buttons. It can be configured to show left, right, or both navigation buttons.
  """
  attr :current_page, :integer, required: true, doc: "current page number"
  attr :total_pages, :integer, required: true, doc: "total number of pages"

  attr :type, :string,
    default: "none",
    doc: "button type - can be 'left_button', 'both_buttons' or 'none'"

  attr :target, :any, default: nil, doc: "the phx-target for button clicks"
  attr :on_left_click, :any, default: nil, doc: "the phx-click event for the left button"
  attr :on_right_click, :any, default: nil, doc: "the phx-click event for the right button"
  attr :left_disabled, :boolean, default: false, doc: "whether the left button is disabled"
  attr :right_disabled, :boolean, default: false, doc: "whether the right button is disabled"

  def pagination(assigns) do
    ~H"""
    <.card class="max-w-5xl w-md min-w-[80svw] grow overflow-hidden">
      <.card_content class="border-gray-300 p-0 flex justify-between items-center h-full">
        <%= if @type == "left_button" or @type == "both_buttons" do %>
          <ReveloWeb.Component.Button.button
            variant="outline"
            class="h-full border-0 border-r-[1px] rounded-none"
            phx-click={@on_left_click}
            disabled={@left_disabled}
            phx-target={@target}
          >
            <.icon name="hero-arrow-left" class="h-5 w-5" />
          </ReveloWeb.Component.Button.button>
        <% end %>
        <div class="p-6 flex grow justify-center items-center space-x-4 flex-col gap-2">
          <%= if @completed? do %>
            <span class="text-2xl">
              <b>Completed!</b>
            </span>
            <.progress class="w-full h-2 !m-0" value={round(@current_page / @total_pages * 100)} />
          <% else %>
            <span class="text-2xl">
              <b>
                Page {@current_page} of {@total_pages}
              </b>
            </span>
            <.progress class="w-full h-2 !m-0" value={round(@current_page / @total_pages * 100)} />
          <% end %>
        </div>
        <%= if @type == "both_buttons" do %>
          <ReveloWeb.Component.Button.button
            variant="outline"
            class="h-full border-0 border-l-[1px] rounded-none"
            phx-target={@target}
            phx-click={@on_right_click}
            disabled={@right_disabled}
          >
            <.icon name="hero-arrow-right" class="h-5 w-5" />
          </ReveloWeb.Component.Button.button>
        <% end %>
      </.card_content>
    </.card>
    """
  end

  @doc """
    Renders the discussion page for a given feedback loop
  """

  def discussion(assigns) do
    ~H"""
    <.card class="max-w-5xl min-w-xs w-[80svw]">
      <.card_header class="pb-2">
        <.card_title class="flex">
          <div class="w-6 shrink-0">{@loop_id}.</div>
          {@title}
        </.card_title>
        <div class="mx-6 pt-2">
          <.badge_reinforcing :if={@type == "reinforcing"} />
          <.badge_balancing :if={@type == "balancing"} />
        </div>
      </.card_header>
      <.card_content class="mx-6">
        <div class="flex -ml-8 gap-1">
          <div class="text-sky-600 border-sky-600 border-2 border-r-0 rounded-l-lg w-8 my-10 relative">
            <.icon
              name="hero-arrow-long-right-solid"
              class="h-8 w-8 absolute -top-[17px] -right-[6px]"
            />
          </div>
          <div class="flex flex-col mb-2 grow">
            <%= for {relationship, index} <- Enum.with_index(@loop) do %>
              <% variable = Enum.find(@variables, fn v -> v.id == relationship.src end) %>
              <div>
                <.card class="w-full shadow-none relative">
                  <.card_content class="flex justify-center items-center font-bold py-6">
                    <span class="text-center">{variable.name}</span>
                  </.card_content>
                </.card>

                <%= if index < length(@loop) - 1 do %>
                  <div class="text-sky-600 w-full flex justify-center">
                    <.icon name="hero-arrow-long-down-solid" class="h-8 w-8" />
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
        <div class="flex justify-between items-center space-x-4">
          <.card_description>{@description}</.card_description>
        </div>
      </.card_content>
    </.card>
    """
  end

  @doc """
    Renders the loop navigation sidebar for the facilitator
  """
  def loop_nav(assigns) do
    ~H"""
    <aside class="fixed inset-y-0 right-0 z-10 max-w-5xl min-w-xs w-[80svw] flex-col border-l-[length:var(--border-thickness)]  bg-white">
      <h3 class="text-2xl font-semibold leading-none tracking-tight flex p-6">Loops</h3>
      <%= if @selected_loop do %>
        <% matching_loop = Enum.find(@loops, &(&1.id == @selected_loop)) %>
        <div class="absolute top-18 z-20 max-w-5xl min-w-xs w-[80svw] right-full mr-6">
          <.card class="w-full">
            <.card_header class="pb-2">
              <.card_title class="flex">
                <div class="w-6 shrink-0">{matching_loop.id}.</div>
                {matching_loop.title}
              </.card_title>
              <div class="mx-6 pt-2">
                <.badge_reinforcing :if={matching_loop.type == "reinforcing"} />
                <.badge_balancing :if={matching_loop.type == "balancing"} />
              </div>
            </.card_header>
            <.card_content class="mx-6">
              <div class="flex justify-between items-center space-x-4">
                <.card_description>{matching_loop.description}</.card_description>
              </div>
            </.card_content>
          </.card>
        </div>
      <% end %>
      <nav class="flex h-full flex-col">
        <div class="flex-1 overflow-y-auto">
          <%= for loop <- @loops do %>
            <button
              phx-click="select_loop"
              phx-value-id={loop.id}
              phx-click-away="unselect_loop"
              class={
                Enum.join(
                  [
                    "w-full px-6 py-4 text-left border-b-[length:var(--border-thickness)]  hover:bg-gray-50 transition-colors",
                    if(loop.id == @selected_loop, do: "bg-gray-100")
                  ],
                  " "
                )
              }
            >
              <div class="flex items-start">
                <span class="w-6 shrink-0">{loop.id}.</span>
                <span class="flex-1 mr-2">{loop.title}</span>
                <%= if loop.type == "reinforcing" do %>
                  <.badge_reinforcing />
                <% else %>
                  <.badge_balancing />
                <% end %>
              </div>
            </button>
          <% end %>
        </div>
      </nav>
    </aside>
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
      <div
        id={"#{@id}-bg"}
        class="bg-background/70 fixed inset-0 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-primary/10 relative hidden rounded-2xl bg-background p-14 shadow-lg border-[length:var(--border-thickness)] transition"
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

  @doc """
  Renders a modal containing a QR code.
  """
  attr :text, :string, required: true, doc: "the text data to encode in the QR code"
  attr :scale, :string, default: "1", doc: "optional scale factor to apply to the QR code"

  def qr_code(assigns) do
    ~H"""
    <div class={"flex flex-col items-center scale-[#{@scale}]"}>
      <.link href={@text}>
        <img
          class="qr_code"
          src={"data:image/png;base64," <>
            (@text
            |> EQRCode.encode()
            |> EQRCode.png()
            |> Base.encode64())}
        />
      </.link>
    </div>
    """
  end

  @doc """
  Renders a session details card showing title and description with edit functionality.
  """
  attr :session, :map, required: true, doc: "the session containing name and description"
  attr :variable_count, :integer, required: true, doc: "number of variables in diagram"
  attr :class, :string, default: "", doc: "additional class to apply to the card"

  def session_details(assigns) do
    ~H"""
    <.card class={["flex flex-col grow", @class] |> Enum.join(" ")}>
      <.card_header>
        <.header class="flex flex-row justify-between !items-start">
          <.card_title>Your Session</.card_title>
          <:actions>
            <.link patch={"/sessions/#{@session.id}/prepare/edit"}>
              <.button type="button" variant="outline" size="sm" class="!mt-0">
                <.icon name="hero-pencil-square-mini" class="h-4 w-4 mr-2 transition-all" /> Edit
              </.button>
            </.link>
          </:actions>
        </.header>
      </.card_header>
      <.scroll_area class="h-20 grow rounded-md">
        <.card_content>
          <div class="grid gap-4">
            <div>
              <span class="font-bold">Title</span>
              <p>{@session.name}</p>
            </div>
            <div>
              <span class="font-bold">Number of variables</span>
              <p>{@variable_count}</p>
            </div>
            <div>
              <span class="font-bold">Description</span>
              <p class="whitespace-pre-line">{@session.description}</p>
            </div>
          </div>
        </.card_content>
      </.scroll_area>
    </.card>
    """
  end

  @doc """
  Renders a session state card showing variable count and start session button.
  """
  attr :session, :map, required: true, doc: "the session to start"
  attr :variable_count, :integer, required: true, doc: "number of variables in diagram"
  attr :class, :string, default: "", doc: "additional class to apply to the card"

  def session_start(assigns) do
    ~H"""
    <.card class={@class}>
      <.card_header>
        <.card_title>Session State</.card_title>
      </.card_header>
      <.card_content>
        <div class="flex justify-between items-end gap-4">
          <div>
            <div>
              <span class="text-2xl font-semibold leading-none tracking-tight">
                {@variable_count}
              </span>
              <span>variable{if @variable_count != 1, do: "s"}</span>
            </div>
            <span class="text-muted-foreground">30-50 reccomended</span>
          </div>
          <div>
            <.link href={"/sessions/#{@session.id}/identify/work"}>
              <.button>Start Session</.button>
            </.link>
          </div>
        </div>
      </.card_content>
    </.card>
    """
  end

  @doc """
  Renders a set of instructions for users.
  """
  attr :title, :string, required: true, doc: "the title of the instructions"
  attr :class, :string, default: "", doc: "additional class to apply to the card"
  slot :inner_block, required: true

  def instructions(assigns) do
    ~H"""
    <.card class={["flex flex-col text-2xl", @class] |> Enum.join(" ")}>
      <.card_header class="w-full">
        <.header class="flex flex-row justify-between !items-start">
          <.card_title class="grow text-2xl">{@title}</.card_title>
        </.header>
      </.card_header>
      <.card_content>
        <div>
          {render_slot(@inner_block)}
        </div>
      </.card_content>
    </.card>
    """
  end

  @doc """
    Renders a QR code card with participant counter and completion button.
  """
  attr :url, :string, required: true
  attr :completed, :integer, required: true, doc: "number of participants completed"
  attr :total, :integer, required: true, doc: "total number of participants"
  attr :class, :string, default: "", doc: "additional class to apply to the card"

  def qr_code_card(assigns) do
    ~H"""
    <.card class={["shrink h-full flex flex-col text-2xl justify-between", @class] |> Enum.join(" ")}>
      <.card_header class="w-full">
        <.header class="flex flex-row justify-between !items-start">
          <.card_title class="grow text-2xl">Scan QR Code</.card_title>
          <.card_description class="text-lg">
            Scan this code with your phone to join.
          </.card_description>
        </.header>
      </.card_header>
      <.card_content>
        <div class="flex justify-center items-center flex-col border-[length:var(--border-thickness)]  aspect-square rounded-xl w-full p-4">
          <.qr_code text={@url} />
        </div>
      </.card_content>
      <.card_footer class="flex flex-col items-center gap-2">
        <div>
          <span class="font-bold text-4xl">
            {if @total == 0, do: "0%", else: "#{round(@completed / @total * 100)}%"}
          </span>
          <span class="text-gray-600 text-lg">completed</span>
        </div>
        <.progress class="w-full h-2" value={round(@completed / max(@total, 1) * 100)} />
      </.card_footer>
    </.card>
    """
  end
end
