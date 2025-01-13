defmodule Revelo.Repo do
  use Ecto.Repo,
    otp_app: :revelo,
    adapter: Ecto.Adapters.SQLite3
end
