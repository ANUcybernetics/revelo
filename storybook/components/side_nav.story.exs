defmodule Storybook.Examples.SideNav do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.UIComponents

  def doc do
    "The navigation menu for the facilitator"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scale-[1] h-[500px]">
      <.sidebar current_page={:prepare} />
    </div>
    """
  end
end
