defmodule ReveloWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use ReveloWeb, :controller
      use ReveloWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Phoenix.Controller
      import Phoenix.LiveView.Router

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: ReveloWeb.Layouts]

      use Gettext, backend: ReveloWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {ReveloWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: ReveloWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML

      # UI Components
      import ReveloWeb.Component.Button
      import ReveloWeb.Component.Card
      import ReveloWeb.Component.Checkbox
      import ReveloWeb.Component.DropdownMenu
      import ReveloWeb.Component.Form
      import ReveloWeb.Component.Input
      import ReveloWeb.Component.Label
      import ReveloWeb.Component.Menu
      import ReveloWeb.Component.Progress
      import ReveloWeb.Component.ScrollArea
      import ReveloWeb.Component.Table
      import ReveloWeb.Component.Textarea
      import ReveloWeb.Component.Tooltip
      import ReveloWeb.Components.Tabs
      import ReveloWeb.CoreComponents, except: [modal: 1, button: 1, input: 1, table: 1, label: 1]
      import ReveloWeb.UIComponents

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ReveloWeb.Endpoint,
        router: ReveloWeb.Router,
        statics: ReveloWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
