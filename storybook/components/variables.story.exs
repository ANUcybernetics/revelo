defmodule Revelo.Storybook.Variables do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &ReveloWeb.Components.my_button/1
  def render_source, do: :function

  def template do
    """
    <div class="-mt-16">
      <.my_button/>
    </div>
    """
  end

  def attributes, do: []
  def slots, do: []
  def variations, do: []
end
