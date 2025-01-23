defmodule Revelo.Sessions do
  @moduledoc false
  use Ash.Domain,
    otp_app: :revelo

  resources do
    resource Revelo.Sessions.Session do
      define :create, args: [:name]
      define :list
      define :add_participants, args: [:participants]
    end

    resource Revelo.Sessions.ContextDoc
    resource Revelo.Sessions.SessionParticipants
  end
end
