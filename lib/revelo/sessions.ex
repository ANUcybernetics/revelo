defmodule Revelo.Sessions do
  @moduledoc false
  use Ash.Domain,
    otp_app: :revelo

  resources do
    resource Revelo.Sessions.Session
    resource Revelo.Sessions.ContextDoc
    resource Revelo.Sessions.SessionParticipants
  end
end
