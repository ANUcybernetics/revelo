defmodule Revelo.Diagrams.RelationshipVote do
  @moduledoc false
  use Ash.Resource,
    otp_app: :revelo,
    domain: Revelo.Diagrams,
    data_layer: AshSqlite.DataLayer

  alias Revelo.Diagrams.Relationship

  sqlite do
    table "relationship_votes"
    repo Revelo.Repo
  end

  actions do
    defaults [:read]

    create :create do
      argument :relationship, :struct do
        constraints instance_of: Relationship
        allow_nil? false
      end

      change relate_actor(:voter)
      change manage_relationship(:relationship, type: :append)
    end
  end

  attributes do
    timestamps()
  end

  relationships do
    belongs_to :relationship, Revelo.Diagrams.Relationship do
      allow_nil? false
      primary_key? true
    end

    belongs_to :voter, Revelo.Accounts.User do
      allow_nil? false
      primary_key? true
    end
  end

  identities do
    identity :unique_vote, [:relationship_id, :voter_id]
  end
end
