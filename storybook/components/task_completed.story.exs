defmodule Storybook.Examples.TaskCompleted do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.UIComponents

  def doc do
    "The mobile view after a task has been completed"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.task_completed completed={20} total={25} />
    """
  end
end
