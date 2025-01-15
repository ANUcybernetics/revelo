defmodule Revelo.Diagrams.LoopVote do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "loop_votes"
    repo Revelo.Repo
  end

  attributes do
    uuid_v7_primary_key :loop_id
    uuid_v7_primary_key :voter_id
    timestamps()
  end

  relationships do
    belongs_to :loop, Revelo.Diagrams.Loop do
      attribute_type :uuid_v7
      allow_nil? false
      primary_key? true
      attribute_writable? true
    end

    belongs_to :voter, Revelo.Accounts.User do
      attribute_type :uuid_v7
      allow_nil? false
      primary_key? true
      attribute_writable? true
    end
  end

  identities do
    identity :unique_vote, [:loop_id, :voter_id]
  end
end
