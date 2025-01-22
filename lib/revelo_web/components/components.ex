defmodule ReveloWeb.Components do
  @moduledoc """
  This is NOT the auto-generated Phoenix CoreComponents file.

  This module contains custom SaladUI component implementations specifically for the Revelo interface.
  """
  use Phoenix.Component
  use Gettext, backend: ReveloWeb.Gettext

  import SaladUI.Button

  # alias Phoenix.HTML.FormField
  # alias Phoenix.LiveView.JS

  def my_button(assigns) do
    ~H"""
    <.button>Revelo Button</.button>
    """
  end
end
