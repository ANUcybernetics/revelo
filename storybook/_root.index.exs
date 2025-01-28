defmodule Storybook.Root do
  @moduledoc false
  use PhoenixStorybook.Index

  def folders do
    [
      Components: [
        icon: "far fa-rectangle-list",
        items: [
          "side_nav",
          "session_settings",
          "variable_list",
          "variable_voting",
          "variable_confirmation",
          "relationship_voting",
          "countdown",
          "task_completed",
          "discussion"
        ]
      ]
    ]
  end
end
