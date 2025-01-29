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
  import ReveloWeb.Component.RadioGroup
  import ReveloWeb.Component.ScrollArea
  import ReveloWeb.Component.Tooltip
  import ReveloWeb.CoreComponents

  alias Phoenix.LiveView.JS

  @doc """
  Renders the sidebar.

  """

  def sidebar(assigns) do
    ~H"""
    <aside class="fixed inset-y-0 left-0 z-10 w-14 flex-col border-r bg-white flex">
      <nav class="flex flex-col items-center gap-4 px-2 py-5">
        <.dropdown_menu>
          <.dropdown_menu_trigger class={
            Enum.join(
              [
                "cursor-pointer group flex h-9 w-9 shrink-0 items-center justify-center gap-2 rounded-full bg-primary text-lg font-semibold text-primary-foreground ",
                if(@current_page == "Elixir.ReveloWeb.SessionLive.Index",
                  do: "outline outline-white -outline-offset-4"
                )
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

        <%= if Map.get(assigns, :session) do %>
          <%= for {page, {icon}, label, path} <- [
          {"Elixir.ReveloWeb.SessionLive.Prepare", {"hero-adjustments-horizontal-mini"}, "Prepare", "/sessions/#{@session.id}/prepare"},
          {"identify", {"hero-queue-list-mini"}, "Identify", "/sessions/#{@session.id}/identify"},
          {"relate", {"hero-arrows-right-left-mini"}, "Relate", "/sessions/#{@session.id}/relate"},
          {"analyse", {"hero-arrow-path-rounded-square-mini"}, "Analyse", "/sessions/#{@session.id}/analyse"}
            ] do %>
            <.tooltip>
              <tooltip_trigger>
                <.link
                  href={path}
                  class={
                    Enum.join(
                      [
                        "flex h-9 w-9 items-center justify-center rounded-lg transition-colors  hover:text-foreground ",
                        if(@current_page == page,
                          do: "bg-accent text-foreground",
                          else: "text-muted-foreground"
                        )
                      ],
                      " "
                    )
                  }
                >
                  <.icon name={icon} class="h-4 w-4 transition-all group-hover:scale-110" />
                  <span class="sr-only">{label}</span>
                </.link>
              </tooltip_trigger>
              <.tooltip_content side="right">{label}</.tooltip_content>
            </.tooltip>
          <% end %>
        <% end %>
      </nav>
      <nav class="mt-auto flex flex-col items-center gap-4 px-2">
        <.tooltip>
          <tooltip_trigger>
            <.link
              href="#"
              class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground py-8"
            >
              <.icon
                name="hero-user-circle-mini"
                class="h-4 w-4 transition-all group-hover:scale-110"
              />
              <span class="sr-only">User</span>
            </.link>
          </tooltip_trigger>
          <.tooltip_content side="right">User</.tooltip_content>
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
    <.badge class="bg-sky-200 text-sky-950 hover:bg-sky-300 w-fit">
      <.icon name="hero-key-mini" class="h-4 w-4 mr-1" /> Key Variable
    </.badge>
    """
  end

  @doc """
    The vote badges

  """

  def badge_vote(assigns) do
    ~H"""
    <.badge class="bg-emerald-200 text-emerald-900 hover:bg-emerald-300 w-fit">
      <.icon name="hero-hand-thumb-up-mini" class="h-4 w-4 mr-1" /> Important
    </.badge>
    """
  end

  def badge_no_vote(assigns) do
    ~H"""
    <.badge class="bg-rose-200 text-rose-900 hover:bg-rose-300 w-fit">
      <.icon name="hero-hand-thumb-down-mini" class="h-4 w-4 mr-1" /> Not Important
    </.badge>
    """
  end

  @doc """
    The feedback badges

  """

  def badge_reinforcing(assigns) do
    ~H"""
    <.badge class="bg-yellow-200 text-yellow-900 hover:bg-yellow-300 w-fit">
      <.icon name="hero-arrows-pointing-out-mini" class="h-4 w-4 mr-1" /> Reinforcing
    </.badge>
    """
  end

  def badge_balancing(assigns) do
    ~H"""
    <.badge class="bg-fuchsia-200 text-fuchsia-900 hover:bg-fuchsia-300 w-fit">
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
          <button class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200">
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
          <button class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200">
            <.icon
              name={if @variable.is_key?, do: "hero-key-solid", else: "hero-key"}
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
            class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200"
            phx-click="toggle_hidden"
            phx-value-id={@variable.id}
          >
            <.icon
              name={if @variable.hidden, do: "hero-eye-slash", else: "hero-eye-solid"}
              class="h-4 w-4 transition-all"
            />
            <span class="sr-only">
              {if @variable.hidden, do: "Hide", else: "Show"}
            </span>
          </button>
        </tooltip_trigger>
        <.tooltip_content side="top">
          {if @variable.hidden, do: "Show", else: "Hide"}
        </.tooltip_content>
      </.tooltip>
      <.tooltip>
        <tooltip_trigger>
          <button
            class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground hover:bg-gray-200"
            phx-click="delete_variable"
            phx-value-id={@variable.id}
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
    The relationships page for mobile
  """

  def relationship_voting(assigns) do
    ~H"""
    <.card class="w-[350px] overflow-hidden">
      <.card_header>
        <.card_title>Pick the most accurate relation</.card_title>
      </.card_header>
      <.card_content class="px-0 pb-0">
        <.radio_group :let={builder} name="relationship" class="gap-0">
          <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-gray-200">
            <.radio_group_item builder={builder} value="decreases" id="decreases" />
            <.label for="decreases">
              As {@variable1.name} <b><em>increases</em></b>, {@variable2.name} <b><em>decreases</em></b>.
            </.label>
          </div>
          <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-gray-200">
            <.radio_group_item builder={builder} value="increases" id="increases" />
            <.label for="increases">
              As {@variable1.name} <b><em>increases</em></b>, {@variable2.name} <b><em>increases</em></b>.
            </.label>
          </div>
          <div class="px-6 py-3 flex items-center space-x-2 has-[input:checked]:bg-gray-200">
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
    Renders a countdown timer component.
  """

  def countdown(assigns) do
    ~H"""
    <.card class="w-[350px] overflow-hidden">
      <.card_content class="border-gray-300 p-0 flex justify-between items-center h-full">
        <%= if @type == "left_button" or @type == "both_buttons" do %>
          <ReveloWeb.Component.Button.button
            variant="outline"
            class="h-full border-0 border-r-[1px] rounded-none"
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
    <.card class="w-[350px]">
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
                  <.card_content class={
                    Enum.join(
                      [
                        "flex justify-center items-center font-bold",
                        if(variable.is_key?, do: "pt-7 pb-5", else: "py-6")
                      ],
                      " "
                    )
                  }>
                    <div class="absolute top-1 left-1">
                      <.badge_key :if={variable.is_key?} />
                    </div>
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
    <aside class="fixed inset-y-0 right-0 z-10 w-[350px] flex-col border-l bg-white">
      <h3 class="text-2xl font-semibold leading-none tracking-tight flex p-6">Loops</h3>
      <%= if @selected_loop do %>
        <% matching_loop = Enum.find(@loops, &(&1.id == @selected_loop)) %>
        <div class="absolute top-18 z-20 w-[350px] right-full mr-6">
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
                    "w-full px-6 py-4 text-left border-b hover:bg-gray-50 transition-colors",
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
          <div class="w-full max-w-3xl p-4 py-8">
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
