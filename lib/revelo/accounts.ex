defmodule Revelo.Accounts do
  @moduledoc false
  use Ash.Domain,
    otp_app: :revelo

  resources do
    resource Revelo.Accounts.Token

    resource Revelo.Accounts.User do
      define :register_anonymous_user
    end
  end
end
