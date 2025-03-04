defmodule ReveloWeb.Router do
  use ReveloWeb, :router
  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers
  import PhoenixStorybook.Router

  alias AshAuthentication.Phoenix.Overrides.Default

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ReveloWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/" do
    storybook_assets()
  end

  # TODO could scope this to "/sessions and remove that from the live routes
  scope "/sessions", ReveloWeb do
    pipe_through :browser

    ash_authentication_live_session :authenticated_routes,
      on_mount: {ReveloWeb.LiveUserAuth, :live_user_required} do
      live "/", SessionLive.Index, :index
      live "/new", SessionLive.Index, :new
      live "/:id/edit", SessionLive.Index, :edit

      live "/:id", SessionLive.Show, :show
      live "/:id/show/edit", SessionLive.Show, :edit
    end

    # these are the sessions used during a session, and as such have the "create anon user if not presetnt" on mount
    ash_authentication_live_session :session_routes,
      on_mount: {ReveloWeb.LiveUserAuth, :live_user_required} do
      live "/:session_id/prepare", SessionLive.Phase, :prepare
      live "/:session_id/prepare/edit", SessionLive.Phase, :edit
      live "/:session_id/identify/work", SessionLive.Phase, :identify_work
      live "/:session_id/identify/discuss", SessionLive.Phase, :identify_discuss
      live "/:session_id/relate/work", SessionLive.Phase, :relate_work
      live "/:session_id/relate/discuss", SessionLive.Phase, :relate_discuss
      live "/:session_id/analyse", SessionLive.Phase, :analyse

      live "/:session_id/prepare/variables/:variable_id", SessionLive.Phase, :prepare
      live "/:session_id/identify/variables/:variable_id", SessionLive.Phase, :identify_discuss

      live "/:session_id/report", SessionLive.Report, :report
    end
  end

  scope "/qr", ReveloWeb do
    pipe_through :browser
    get "/sessions/:session_id/:phase/work", QRController, :handle_qr
  end

  scope "/", ReveloWeb do
    pipe_through :browser

    get "/", PageController, :home
    auth_routes AuthController, Revelo.Accounts.User, path: "/auth"
    sign_out_route AuthController
    live_storybook("/storybook", backend_module: ReveloWeb.Storybook)

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{ReveloWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    ReveloWeb.AuthOverrides,
                    Default
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [ReveloWeb.AuthOverrides, Default]
  end

  # Other scopes may use custom stacks.
  # scope "/api", ReveloWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:revelo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ReveloWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
