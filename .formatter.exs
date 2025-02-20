[
  import_deps: [
    :ash_authentication,
    :ash_authentication_phoenix,
    :ecto,
    :ecto_sql,
    :phoenix,
    :ash,
    :ash_postgres
  ],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter, Spark.Formatter, Styler],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs",
    "storybook/**/*.exs"
  ]
]
