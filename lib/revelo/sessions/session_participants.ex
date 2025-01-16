defmodule Revelo.Sessions.SessionParticipants do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Sessions,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "session_participants"
    repo Revelo.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  relationships do
    belongs_to :session, Revelo.Sessions.Session, primary_key?: true, allow_nil?: false
    belongs_to :participant, Revelo.Accounts.User, primary_key?: true, allow_nil?: false
  end
end
