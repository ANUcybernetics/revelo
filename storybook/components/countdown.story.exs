defmodule Storybook.Examples.Countdown do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import ReveloWeb.UIComponents

  def doc do
    "A timer component for counting down, with or without navigation controls"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid gap-4">
      <.countdown time_left={@time_left} initial_time={@initial_time} type="default" />
      <.countdown time_left={@time_left} initial_time={@initial_time} type="left_button" />
      <.countdown time_left={@time_left} initial_time={@initial_time} type="both_buttons" />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    {:ok, assign(socket, %{time_left: 300, initial_time: 300})}
  end

  @impl true
  def handle_info(:tick, socket) do
    new_time = max(socket.assigns.time_left - 1, 0)
    {:noreply, assign(socket, time_left: new_time)}
  end
end
