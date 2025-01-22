defmodule Storybook.Components.CoreComponents.Button do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &ReveloWeb.Components.my_button/1
  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          type: "button",
          class: "bg-emerald-400 hover:bg-emerald-500 text-emerald-800"
        },
        slots: [
          "Click me buddy!"
        ]
      },
      %Variation{
        id: :disabled,
        attributes: %{
          type: "button",
          disabled: true
        },
        slots: [
          "Click me!"
        ]
      }
    ]
  end
end
