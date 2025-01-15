defmodule Revelo.Diagrams.RelationshipVote do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "relationship_votes"
    repo Revelo.Repo
  end

  attributes do
    uuid_primary_key :relationship_id
    uuid_primary_key :voter_id
    timestamps()
  end

  relationships do
    belongs_to :relationship, Revelo.Diagrams.Relationship do
      allow_nil? false
      primary_key? true
      attribute_writable? true
    end

    belongs_to :voter, Revelo.Accounts.User do
      allow_nil? false
      primary_key? true
      attribute_writable? true
    end
  end

  identities do
    identity :unique_vote, [:relationship_id, :voter_id]
  end
end
