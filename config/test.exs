import Config

config :ash, disable_async?: true

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used

config :phoenix_test, :endpoint, ReveloWeb.Endpoint
config :phoenix_test, otp_app: :revelo, playwright: [cli: "assets/node_modules/playwright/cli.js"]

# In test we don't send emails
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :revelo, Revelo.Mailer, adapter: Swoosh.Adapters.Test

config :revelo, Revelo.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "revelo_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

config :revelo, ReveloWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "xySmeWgkT9J2tZXefzLQgsBmKBtMiE8kv2sTFp+ugo/LB0yQvnm8WmC308xCXjI6",
  server: false

config :revelo, ReveloWeb.Endpoint, server: true
config :revelo, token_signing_secret: "c2SpUivcNcq6oxn2VUfSIFKn6pZpHwpu"

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
