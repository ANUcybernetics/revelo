# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ash, :policies, no_filter_static_forbidden_reads?: false

config :ash,
  include_embedded_source_by_default?: false,
  default_page_type: :keyset,
  allow_forbidden_field_for_relationships_by_default?: true,
  show_keysets_for_all_actions?: false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  revelo: [
    args:
      ~w(js/app.js js/storybook.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :instructor_lite, :openai_api_key, System.fetch_env!("OPENAI_API_KEY")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :revelo, Revelo.Mailer, adapter: Swoosh.Adapters.Local

# Configures the endpoint
config :revelo, ReveloWeb.Endpoint,
  url: [host: System.get_env("SYSTEM_IP") || "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ReveloWeb.ErrorHTML, json: ReveloWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Revelo.PubSub,
  live_view: [signing_salt: "fEvquwTM"]

config :revelo, :ash_domains, [Revelo.Accounts, Revelo.Sessions, Revelo.Diagrams]

config :revelo,
  ecto_repos: [Revelo.Repo],
  generators: [timestamp_type: :utc_datetime]

config :spark, :formatter,
  remove_parens?: true,
  "Ash.Domain": [section_order: [:resources, :policies, :authorization, :domain, :execution]],
  "Ash.Resource": [
    section_order: [
      :postgres,
      :resource,
      :code_interface,
      :policies,
      :pub_sub,
      :preparations,
      :changes,
      :validations,
      :multitenancy,
      :calculations,
      :aggregates,
      :authentication,
      :tokens,
      # any section not in this list is left where it is
      # but these sections will always appear in this order in a resource
      :actions,
      :attributes,
      :relationships,
      :identities
    ]
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  revelo: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ],
  storybook: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/storybook.css
      --output=../priv/static/assets/storybook.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
