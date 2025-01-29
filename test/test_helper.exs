ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Revelo.Repo, :manual)
Application.put_env(:phoenix_test, :base_url, ReveloWeb.Endpoint.url())
