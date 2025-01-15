defmodule Revelo.Secrets do
  @moduledoc false
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Revelo.Accounts.User, _opts) do
    Application.fetch_env(:revelo, :token_signing_secret)
  end
end
